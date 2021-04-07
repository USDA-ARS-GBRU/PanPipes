"""
identify_misaligned_sim_reads.py: 
A script to go through SAM files produced by either 
BWA or GraphAligner -> vg surject with simulated reads,
and determine which reads have been aligned to the wrong
position based on their name.

USAGE:
python identify_misaligned_sim_reads.py input_sam.sam read_length(def:150) wiggle_length(def:5) > out.sam

read_length is the read length of your simulated reads (NOT insert size), default 150; wiggle_length is how
much room around the start coordinates you will allow as "valid", default 5 bp

SAM files must be generated from input FASTQs made from 
wgsim.

Looks for the read name to determine insert boundaries,
then checks if the alignment start is within
+/- 5bp of either the start of the insert or 
(end of insert - read length). Assumes all SAM
alignments are given as coordinates in the forward
direction. 

Outputs the lines that are misaligned to std out.
"""
__author__      = "Brian Nadon"

import re
from sys import argv

def find_misaligns(infile,read_len=150,wiggle=5,boundarypattern="(?<=_)\d+"):
    with open(infile) as f:
        for line in f:
            if re.search("^\@\w\w",line):
                continue
            boundaries=re.findall(boundarypattern,line)
            start_boundary=int(boundaries[0])
            end_boundary=int(boundaries[1])
            secondary_start=end_boundary-read_len
            
            align_pos = int(line.strip().split('\t')[3])
            
            valid_starts = (list(range(start_boundary-wiggle,start_boundary+(wiggle+1))) + 
                            list(range(secondary_start-wiggle,secondary_start+(wiggle+1))))
            
            if align_pos not in valid_starts:
                print(line)
                
if __name__=="__main__":
    script, infile, read_len, wiggle = argv
    find_misaligns(infile,int(read_len),int(wiggle))
        
        
