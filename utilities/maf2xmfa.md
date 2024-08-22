# maf2xmfa tool
This tool will convert an maf file of a single sequence/chromosome (produced from cactus-hal2maf from a minigraph-cactus
chromosome sub-problem) and output a mauve-viewer and Geneious compatible xmfa.

## Required
Minigraph-Cactus, docker install is easiest: quay.io/ucsc_cgl/cat:latest

Biopython via pip:
```pip install biopython```

Mauve viewer: https://darlinglab.org/mauve/user-guide/viewer.html

## Usage
`maf2xmfa.py [-h] -i INPUT_MAF -o OUTPUT_XMFA [-v] [-g]`<br>
*maf2xmfa: a tool for converting maf to xmfa.*<br>
*optional arguments:*<br>
  *-h, --help*<br>Output of these arguments.

  *-i INPUT_MAF, --input INPUT_MAF*<br>Path to input multiple alignment formatted file.

  *-o OUTPUT_XMFA, --output OUTPUT_XMFA*<br>Path to output xmfa file.

  *-b BLACKLIST, --blacklist BLACKLIST*<br>Comma-separated names to be omitted from xmfa.

  *-v, --verbose*<br>Output progress to the terminal.

  *-d, --degap*<br>De-gap sequences produced from loops after being moved to singleton blocks (Default de-gaps)

## Running for example yeast dataset
For testing this pipeline, we recommend using the Yeast dataset supplied with minigraph-cactus: https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/examples/yeastPangenome.txt

Construct the pangenome graph with minigraph-cactus:
```bash
wget https://raw.githubusercontent.com/ComparativeGenomicsToolkit/cactus/master/examples/yeastPangenome.txt
cactus-pangenome ./js yeastPangenome.txt --reference S288C --outDir yeast-pg --outName yeast-pg --vcf --giraffe
```
From yeast-pg/chrom-alignments, convert the chromosome alignment for chrI from HAL to MAF using the hal2maf tool supplied with cactus.
```bash
cactus-hal2maf --chunkSize 1000000 --refGenome S288C ./js yeast-pg/chrom-alignments/chrI.hal yeast-pg/chrom-alignments/chrI.maf
```
Convert the chromosome alignment from MAF into an XMFA
```bash
python maf2xmfa.py -i yeast-pg/chrom-alignments/chrI.maf -o yeast-pg/chrom-alignments/chrI.xmfa
```
