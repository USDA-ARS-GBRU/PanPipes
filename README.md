# PanPipes
![PanPipes Logo](/pics/logo.png)

Test sets and pipeline scripts for pan-genomic graph construction and analysis

## Construction

## Read mapping

## Variant calling and genotyping


## Graph Viewing

## Tool: gfa_parser
### Function: characterize the common and specific node of pangenome graph 

Usage:

`perl gfa_parser.pl -g gfa_graph_file  [-s short_path_name_T|F] -o [gfa_graph_file.csv ofr bandage]`

help file:  gfa_parser_readme.pdf

## Comparison of performance between genome graph and linear reference 
  sim_linear_graph_map_performance.sh

  Function: simulated reads, mapping with BWA or GraphAlinger, mapping performace (mapped reads, mapping ratio, unique mapping,split mapping)
