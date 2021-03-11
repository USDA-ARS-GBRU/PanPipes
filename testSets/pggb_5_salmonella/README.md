## A PGGB-derived variation graph built from 5 salmonella reference genomes 

The 5 salmonella reference chromosomes used in this directory were obtained from NCBI (see tree description below), and chosen to maximize diversity between individuals.  PGGB (https://github.com/pangenome/pggb) was used to create all outputs.
```
.
+-- alignments
|   +-- PAF file: the PAF output of the PGGB run
|   +-- MAF file: the MAF output of the PGGB run
+-- graphs: contains the two output graphs (all others removed for simplicity)
|   +-- seqwish graph: the seqwish (unsmoothed) pggb output GFA
|   +-- smooth graph: the smoothxg output from PGGB: a smooth, partial ordered graph
+-- logs
|   +-- .log file: stdout from pggb run
|   +-- yml file: contains the parameters used to run PGGB
|   +-- og file: the ogdi output
+-- salmonella_5lines.fa: a multifasta file containing the 5 salmonella reference chromosomes
+-- salmonella_5_lines.txt: the 5 NCBI accessions chosen (maximized for diversity with MASH + k-medoids)
```
