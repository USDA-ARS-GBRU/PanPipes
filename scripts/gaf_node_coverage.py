#!/usr/bin/python

"""
gaf_node_coverage.py:
Script that takes in a GFA and a GAF (alignment) file and outputs node coverages
over a given path. This script will print out the nodes in the path in order,
and give the # of reads that covered the node along with the names of those reads
and the length of that node.

USAGE:
python gaf_node_coverage.py GAF_file.gaf GFA_graph.gfa Path_name
"""

__author__ = "Brian Nadon"


import re
from sys import argv
#import pandas as pd
from collections import defaultdict

script, gaf, gfa, path = argv

with open(gfa) as f:
    pathlist = set()
    nodelen_d = {}
    for line in f:
        if re.match('^P\t' + path,line):
            line = line.strip().split('\t')
            nodelist = line[2]
            nodelist = re.split('\D+',nodelist)
            nodelist = filter(None,nodelist)
            nodelist = [int(x) for x in nodelist]
            pathlist.update(nodelist)
        elif re.match('^S',line):
            line = line.strip().split('\t')
            seq = line[2]
            nodelen = len(seq)
            nodelen_d[int(line[1])] = nodelen


with open(gaf) as f:
    node_cov_d = defaultdict(lambda: {'coverage': 0,'reads': []})
    for line in f:
        line = line.strip().split('\t')
        read = line[0]
        read_path = line[5]
        read_path = re.split('\D+',read_path)
        read_path = filter(None, read_path)
        read_path = [int(x) for x in read_path]
        for n in read_path:
            if n in pathlist:
                node_cov_d[n]['coverage'] += 1
                node_cov_d[n]['reads'].append(read)
                node_cov_d[n]['length'] = nodelen_d[n]


node_cov_l = []
for n in sorted(list(pathlist)):
    if n in node_cov_d:
        node_cov_l.append({'node':n,'reads':node_cov_d[n]['reads'],
                'coverage':node_cov_d[n]['coverage'],
                'length':node_cov_d[n]['length']})
    else:
        node_cov_l.append({'node':n,'reads':'NA',
            'coverage':0,'length':0})


header = ['node','length','coverage','reads']
print('\t'.join(header))
for node in node_cov_l:
    line = [str(node['node']),str(node['length']),str(node['coverage']),
            str(node['reads'])]
    print('\t'.join(line))



