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
        adict = {'text':line.strip(),
                'matches':splitline[9]}
        dup_dict[readname]['aligns'].append(adict)

for key in dup_dict.keys():
    l = dup_dict[key]['aligns']
    if len(l) == 1:
        print(l[0]['text'])
    else:
        maxind = max(range(len(l)), key=lambda i: l[i]['matches'])
        print(l[maxind]['text'])




