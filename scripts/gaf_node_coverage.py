#!/usr/bin/python

"""
gaf_node_coverage.py:
Script that takes in a GFA and a GAF (alignment) file and outputs node coverages
over a given path. This script will print out the nodes in the path in order,
and give the # of reads that covered the node along with the names of those reads
and the length of that node.

Best used to inspect simulated reads aligned back to a graph.

USAGE:
python gaf_node_coverage.py GAF_file.gaf GFA_graph.gfa Path_name
"""

__author__ = "Brian Nadon"


import re
from sys import argv
from collections import defaultdict

def get_path_and_nodelen(gfa_file):
    with open(gfa_file) as f:
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
                line = line.strip().split()
                seq = line[2]
                nodelen = len(seq)
                nodelen_d[int(line[1])] = nodelen
    return (pathlist,nodelen_d)

"""
def get_percent_node_cov(nodelen,read_path,start,end):
    if len(read_path) <=1:
        nl = nodelen[read_path[0]]
        cov = (end+1) - (start+1)
        pc_cov = cov / nl
        return pc_cov
    else:
        first_node = read_path[0]
        first_len = nodelen[first_node]
        last_node = read_path[-1]
        last_len = nodelen[last_node]
        first_pc_cov = (first_len-start)/first_len
        last_pc_cov = (end+1)/last_len
        return (first_pc_cov,last_pc_cov)
"""


def get_node_cov(gaf_file,pathlist,nodelen_d):
    with open(gaf_file) as f:
        node_cov_d = defaultdict(lambda: {'coverage': 0,'reads': [],
                                'length':0})
        for line in f:
            try:
                line = line.strip().split()
                path_s = int(line[7])
                path_e = int(line[8])
                read = line[0]
                read_path = line[5]
                read_path = re.split('\D+',read_path)
                read_path = filter(None, read_path)
                read_path = [int(x) for x in read_path]
            except ValueError:
                continue
            for i,n in enumerate(read_path):
                if n in pathlist:
                    node_cov_d[n]['coverage'] += 1
                    node_cov_d[n]['reads'].append(read)

    node_cov_l = []
    for n in sorted(list(pathlist)):
        node_cov_l.append({'node':n,'reads':node_cov_d[n]['reads'],
                            'coverage':node_cov_d[n]['coverage'],
                            'length':nodelen_d[n]})
    return node_cov_l

def print_node_cov_table(node_cov_l):
    header = ['node','length','coverage','reads']
    print('\t'.join(header))
    for node in node_cov_l:
        line = [str(node['node']),str(node['length']),str(node['coverage']),
                str(node['reads'])]
        print('\t'.join(line))

if __name__=="__main__":
    script, gaf, gfa, path = argv
    pathlist,nodelen = get_path_and_nodelen(gfa)
    node_cov = get_node_cov(gaf,pathlist,nodelen)
    print_node_cov_table(node_cov)
