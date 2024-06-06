#!/usr/bin/env python3

from Bio import AlignIO, SeqIO
import argparse
import os
import logging
import textwrap
import io

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
parser.add_argument('-g', '--gappy', dest='gappy', action='store_true', help='Include gappy blocks', default=False)
parser.add_argument('-f', '--fill', dest='fill', type=str, help='Cactus-style seqfile for filling unaligned segments. Otherwise filled with Ns', default='')
parser.add_argument('-v', '--verbose', dest='verbose', action='store_true', help='Verbose mode', default=False)
args = parser.parse_args()

if args.verbose:
    logger.setLevel(logging.INFO)

if not os.path.exists(args.input_maf):
    logger.error(f"Couldn't find input MAF '{args.input_maf}'")
    exit()

collection = {}
blackList = {'Anc0', '_MINIGRAPH_'}
unaligned_positions = {}

# Collect alignment information and create name list and populate the unaligned positions
alignments = AlignIO.parse(args.input_maf, 'maf')
for alignment in alignments:
    for seqRecord in alignment:
        name = seqRecord.id
        if name not in collection.keys() and name.split('.')[0] not in blackList:
            collection[name] = len(collection) + 1
            unaligned_positions[name] = [(1,seqRecord.annotations['srcSize'])]
logger.info(f"Alignment names collected from '{args.input_maf}'")

# Define the dictionary of unaligned bases in each sequence
alignments = AlignIO.parse(args.input_maf, 'maf')

with open(args.output_xmfa, 'wb') as output_file, io.BufferedWriter(output_file) as buffered_output:
    # Write dummy block and Mauve file headers
    #output_string = "#FormatVersion Mauve1\n"
    output_string = f""
    second_string = ""
    for index, collectionName in enumerate(collection):
    #    output_string += f"#Sequence{index+1}Entry {collectionName}\n"
        second_string += f"> {collection[collectionName]}:0-0 + {collectionName}\n-\n"
    second_string += "=\n"
    output_string += second_string
    buffered_output.write(output_string.encode('utf-8'))

    logger.info(f"XMFA headers written to '{args.output_xmfa}'")

    alignments = AlignIO.parse(args.input_maf, 'maf')
    for alignment in alignments:
        names = {a.id for a in alignment if a.id.split('.')[0] not in blackList}
        # Write test validates whether any sequences were in an LCB, or all were blacklisted/missing
        written = False
        # If a sequence has already been reported in a block, the looped sequences should be added to a new block alone
        extraAlignments = []
        output_string = ""

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
            elif args.gappy:
                written = True
                # write a blank row
                output_string += f"> {collection[collectionName]}:0-0 + {collectionName}\n{textwrap.fill('-' * len(alignment[0]), break_long_words=True, break_on_hyphens=False, width=80)}\n"

        # Only write the footer if an LCB needs to be written
        if written:
            output_string += '=\n'

        if len(extraAlignments) > 0:
            for extraEntry in extraAlignments:
                values = prepareSequenceInfo(extraEntry)
                for i, rangePair in enumerate(unaligned_positions[extraEntry.id]):
                    # Split the rangePair which includes this subset
                    if values[0] == rangePair[0] and values[1] < rangePair[1]:
                        unaligned_positions[extraEntry.id][i] = values[1]+1,rangePair[1]
                        break
                    elif values[0] > rangePair[0] and values[1] == rangePair[1]:
                        unaligned_positions[extraEntry.id][i] = rangePair[0],values[0]-1
                        break
                    elif values[0] > rangePair[0] and values[1] < rangePair[1]:
                        unaligned_positions[extraEntry.id][i] = rangePair[0],values[0]-1
                        unaligned_positions[extraEntry.id].insert(i+1, (values[1]+1, rangePair[1]))
                        break
                    elif values[0] == rangePair[0] and values[1] == rangePair[1]:
                        del unaligned_positions[extraEntry.id][i]
                        break
                output_string += f"> {collection[extraEntry.id]}:{values[0]}-{values[1]} {values[2]} {extraEntry.id}\n{textwrap.fill(str(extraEntry.seq), break_long_words=True, break_on_hyphens=False, width=80)}\n=\n"

        if len(output_string) > 0:
            buffered_output.write(output_string.encode('utf-8'))
    # Create dummy blocks on the end of the file for all missing data
    output_string = f""
    if args.fill:
        if not os.path.exists(args.fill):
            logger.error(f"Seqfil '{args.fill}' not found, defaulting to N-filling")
            args.fill = False

    if args.fill:
        fillPaths = {}
        with open(args.fill, 'r') as fillFile:
            for fillLine in fillFile:
                fillLineSplit = fillLine.strip().split('\t')
                fillPaths[fillLineSplit[0]] = SeqIO.index(fillLineSplit[1], "fasta")
        for sequence in unaligned_positions:
            if len(unaligned_positions[sequence])>0:
                for rangePair in unaligned_positions[sequence]:
                    output_string += f"> {collection[sequence]}:{rangePair[0]}-{rangePair[1]} + {sequence}\n{textwrap.fill(str(fillPaths[sequence.split('.')[0]][sequence.split('.')[1]][rangePair[0]-1:rangePair[1]].seq), break_long_words=True, break_on_hyphens=False, width=80)}\n=\n"

    else:
        for sequence in unaligned_positions:
            if len(unaligned_positions[sequence])>0:
                for rangePair in unaligned_positions[sequence]:
                    output_string += f"> {collection[sequence]}:{rangePair[0]}-{rangePair[1]} + {sequence}\n{textwrap.fill(str('N' * (rangePair[1] - rangePair[0] + 1)), break_long_words=True, break_on_hyphens=False, width=80)}\n=\n"

    buffered_output.write(output_string.encode('utf-8'))
    logger.info(f"File written to '{args.output_xmfa}', exiting.")
