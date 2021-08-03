#!/usr/bin/python3

import re
from collections import defaultdict
from sys import argv
from random import randint

script, gaf_in = argv

dup_dict = defaultdict(lambda: {'aligns':[]})

with open(gaf_in) as f:
    for line in f:
        splitline = line.strip().split('\t')
        readname = splitline[0]
        dup_dict[readname]['aligns'].append(line.strip())

for key in dup_dict.keys():
    count = len(dup_dict[key]['aligns'])
    if count == 1:
        print(dup_dict[key]['aligns'][0])
    else:
        chosenread = randint(0,count-1)
        print(dup_dict[key]['aligns'][chosenread])

