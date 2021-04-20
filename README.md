# PanPipes
Test sets and pipeline scripts for pan-genomic graph construction and analysis

![PanPipes Logo](/pics/logo.png)

## Overview

<br><img src="/pics/workFlow.png" width=450 align=left><br>

Founder assemblies are aligned on a per chromosome basis.  Alignments are converted to graph data objects and merged into a whole-genome graph.  All variants segregating in founders are identified and described in a modified variant call format (VCF).  Short-read data from recombinant individuals is aligned to the genome graph and genotypes are inferred based on branch-specific read support.  These genotypes are added to the VCF file and conventional genetic analysis can be used to associate pangenomic loci with phenotypes.  Associated loci can be directly examined for major gene-altering variation by returning to chromosome alignments on which the graph is based.


## Construction

## Read mapping

## Variant calling and genotyping



