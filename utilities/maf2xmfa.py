#!/usr/bin/env python3

from Bio import AlignIO, SeqIO
import argparse
import os
import logging
import textwrap
import io
import time
from shutil import copyfileobj

def prepareSequenceInfo(seqRec):
    if seqRec.annotations['strand'] == 1:
        return seqRec.annotations['start'] + 1, seqRec.annotations['start'] + seqRec.annotations['size'], '+'
    else:
        return seqRec.annotations['srcSize'] - seqRec.annotations['start'] - seqRec.annotations['size'] + 1, seqRec.annotations['srcSize'] - seqRec.annotations['start'], '-'


# Set up logger
logging.basicConfig(level=logging.ERROR)
logger = logging.getLogger()

parser = argparse.ArgumentParser(description='maf2xmfa: a tool for converting maf to xmfa.')
parser.add_argument('-i', '--input', dest='input_maf', type=str, help='Input MAF file', required=True)
parser.add_argument('-o', '--output', dest='output_xmfa', type=str, help='Output XMFA file', required=True)
parser.add_argument('-b', '--blacklist', dest='blacklist', type=str, help='Comma-separated names to be omitted from xmfa.', default='Anc0,_MINIGRAPH_')
parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='Verbose mode', default=False)
parser.add_argument('-d', '--degap', dest='degap', action='store_false', help='De-gap sequences produced from loops after being moved to singleton blocks', default=True)
args = parser.parse_args()

if args.verbose:
    logger.setLevel(logging.INFO)

if not os.path.exists(args.input_maf):
    logger.error(f"Couldn't find input MAF '{args.input_maf}'")
    exit()

collection = {}
blackList = set(args.blacklist.split(','))
unaligned_positions = {}

# Collect alignment information and create name list and populate the unaligned positions
alignments = AlignIO.parse(args.input_maf, 'maf')
logger.info(f"Alignments loaded from '{args.input_maf}'")
tempFile = f"temp.{time.time()}"
with open(tempFile, 'wb') as output_file, io.BufferedWriter(output_file) as buffered_output:
    for alignment in alignments:
        names = {(a.id, a.annotations['srcSize']) for a in alignment if a.id.split('.')[0] not in blackList}
        uncollectedNames = [name for name in names if name[0] not in collection]
        for name in uncollectedNames:
            collection[name[0]] = len(collection) + 1
            unaligned_positions[name[0]] = [(1, name[1])]
        # Write test validates whether any sequences were in an LCB, or all were blacklisted/missing
        written = False
        # If a sequence has already been reported in a block, the looped sequences should be added to a new block alone
        extraAlignments = []
        output_string = f""
        names = {name[0] for name in names}

        for collectionName in collection:
            if collectionName in names:
                written = True
                row = [a for a in alignment if a.id == collectionName]
                values = prepareSequenceInfo(row[0])
                for i, rangePair in enumerate(unaligned_positions[collectionName]):
                    # Split the rangePair which includes this subset
                    if values[0] == rangePair[0] and values[1] < rangePair[1]:
                        unaligned_positions[collectionName][i] = values[1]+1,rangePair[1]
                        break
                    elif values[0] > rangePair[0] and values[1] == rangePair[1]:
                        unaligned_positions[collectionName][i] = rangePair[0],values[0]-1
                        break
                    elif values[0] > rangePair[0] and values[1] < rangePair[1]:
                        unaligned_positions[collectionName][i] = rangePair[0], values[0] - 1
                        unaligned_positions[collectionName].insert(i + 1, (values[1] + 1, rangePair[1]))
                        break
                    elif values[0] == rangePair[0] and values[1] == rangePair[1]:
                        del unaligned_positions[collectionName][i]
                        break
                output_string += f"> {collection[collectionName]}:{values[0]}-{values[1]} {values[2]} {collectionName}\n{textwrap.fill(str(row[0].seq), break_long_words=True, break_on_hyphens=False, width=80)}\n"

                if len(row) > 1:
                    extraAlignments.extend(row[1:])
        # Only write the footer if an LCB needs to be written
        if written:
            output_string += '=\n'
        if len(extraAlignments) > 0:
            for extraEntry in extraAlignments:
                values = prepareSequenceInfo(extraEntry)
                for i, rangePair in enumerate(unaligned_positions[extraEntry.id]):
                    # Split the rangePair which includes this subset
                    if values[0] == rangePair[0] and values[1] < rangePair[1]:
                        unaligned_positions[extraEntry.id][i] = values[1]+1, rangePair[1]
                        break
                    elif values[0] > rangePair[0] and values[1] == rangePair[1]:
                        unaligned_positions[extraEntry.id][i] = rangePair[0], values[0]-1
                        break
                    elif values[0] > rangePair[0] and values[1] < rangePair[1]:
                        unaligned_positions[extraEntry.id][i] = rangePair[0], values[0]-1
                        unaligned_positions[extraEntry.id].insert(i+1, (values[1]+1, rangePair[1]))
                        break
                    elif values[0] == rangePair[0] and values[1] == rangePair[1]:
                        del unaligned_positions[extraEntry.id][i]
                        break
                if args.degap:
                    output_string += f"> {collection[extraEntry.id]}:{values[0]}-{values[1]} {values[2]} {extraEntry.id}\n{textwrap.fill(str(extraEntry.seq.replace('-', '')), break_long_words=True, break_on_hyphens=False, width=80)}\n=\n"
                else:
                    output_string += f"> {collection[extraEntry.id]}:{values[0]}-{values[1]} {values[2]} {extraEntry.id}\n{textwrap.fill(str(extraEntry.seq), break_long_words=True, break_on_hyphens=False, width=80)}\n=\n"
        if len(output_string) > 0:
            buffered_output.write(output_string.encode('utf-8'))
    output_string = f""
    for sequence in unaligned_positions:
        if len(unaligned_positions[sequence])>0:
            for rangePair in unaligned_positions[sequence]:
                output_string += f"> {collection[sequence]}:{rangePair[0]}-{rangePair[1]} + {sequence}\n{textwrap.fill(str('N' * (rangePair[1] - rangePair[0] + 1)), break_long_words=True, break_on_hyphens=False, width=80)}\n=\n"
    buffered_output.write(output_string.encode('utf-8'))

logger.info(f"XMFA blocks written to intermediate file '{tempFile}'")

with open(tempFile, 'rb') as tempFileContent, open(args.output_xmfa, 'wb') as output_file:
    # Write dummy block and Mauve file headers
    output_string = f""
    for index, collectionName in enumerate(collection):
        output_string += f"> {collection[collectionName]}:0-0 + {collectionName}\n-\n"
    output_string += "=\n"
    output_file.write(output_string.encode('utf-8'))
    logger.info(f"XMFA headers written to '{args.output_xmfa}'")

    copyfileobj(tempFileContent, output_file)
    logger.info(f"Intermediate file written to '{args.output_xmfa}'.")

os.remove(tempFile)
logger.info(f"Intermediate file '{tempFile}' deleted. Exiting.")
