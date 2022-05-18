# PanPipes
![PanPipes Logo](/pics/logo.png)

PanPipes is an end-to-end pipeline for pan-genomic graph construction and genetic analysis.  Multiple components of the pipeline may have specific utility outside of PanPipes and so have been broken into three application groups:

* For manipulating xmfas: xmfa_tools [https://github.com/USDA-ARS-GBRU/xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools "xmfa_tools")
* For genotyping directly from a graph: gfa_var_genotyper [https://github.com/USDA-ARS-GBRU/gfa_var_genotyper](https://github.com/USDA-ARS-GBRU/gfa_var_genotyper "gfa_var_genotyper")
* For imputation optimized for skim-seq data and realistic plant populations: brute_impute [https://github.com/USDA-ARS-GBRU/super_imputer](https://github.com/USDA-ARS-GBRU/brute_impute "brute imputer")


The PanPipes repository provides documentation detailing the end-to-end combined usage of our tools in a pan-genomic context. A PanPipes docker image is available ([coming soon](https://github.com/USDA-ARS-GBRU/PanPipes/docker/dockerfile "PanPipes docker image")) to provide all required software for running PanPipes. Required external software packages (in addition to GBRU repos above) are listed below, if you prefer to install manually.

* vg: [https://github.com/vgteam/vg](https://github.com/vgteam/vg "vg")

Additional tools support upstream and downstream aspects of PanPipes, but are not strictly necessary.

* mauve: [https://darlinglab.org/mauve/mauve.html](https://darlinglab.org/mauve/mauve.html "mauve")
* tassel: [https://tassel.bitbucket.io/](https://tassel.bitbucket.io/ "tassel")

## Overview

<img src="/pics/workFlow.png" width=450>

Founder assemblies are aligned on a per chromosome basis.  Alignments are converted to graph data objects and merged into a whole-genome graph.  All variants segregating in founders are identified and described in a modified variant call format (VCF).  Short-reads from recombinant individuals are aligned to the genome graph and genotypes are inferred based on branch-specific read support.  These genotypes are added to the VCF file and conventional genetic analysis can be used to associate pangenomic loci with phenotypes.  Associated loci can be directly examined for major gene-altering variation by returning to chromosome alignments on which the graph is based.

## Construction

All downstream processing is based on genome-scale multi-sequence alignments that are converted into graph objects in [GFA format](https://github.com/GFA-spec/GFA-spec/blob/master/GFA1.md).  The sequences used to build the alignments must be represented as paths in the gfa.  Software, such as [pggb](https://github.com/pangenome/pggb), is a recent method to generate such graphs.  In our hands, we have noticed that pggb often generates unwarranted cycles that violate the positional homology paradigm followed in PanPipes (see above).  Our current preferred methods is to rely on a multi-threaded implementation of the progressiveMauve algorithm, see [GPA](https://academic.oup.com/bioinformatics/article/35/14/i71/5529231).  

Using resultant xmfas, we convert alignments to graphs using [xmfa_tools](https://github.com/brianabernathy/xmfa_tools).  In brief, large collinear blocks in the alignment are converted via 'vg construct' and the blocks are connected by adjusting segment numbers to reflect the relationship between large-scale rearrangments.  

We have observed [futile gap openings](https://github.com/koadman/mauve/issues/2) in progressiveMauve alignments.  Such artifacts create false variants and confuse read mapping.  They are easy to detect and remove and are eliminated by default in [xmfa_tools](https://github.com/brianabernathy/xmfa_tools). Similiarly, futile border gaps in true indels - another common artifact - are generally of little consequence as a proportion of the total indel, although, if mechanistic understanding is the objective, these subsampled regions should be realigned.

To acknowledge the concept of a linear reference, xmfas can be sorted relative to the member sequences using [xmfa_tools](https://github.com/brianabernathy/xmfa_tools).  This sort occurs in a hierarchical fashion defined by the user.  In effect, the primary sequence, as chosen, will be perfectly collinear with the segment ordering of the graph.  This sort is not required; the re-ordering is a conceptual convenience if you desire your graph to be in roughly the same configuration as a community reference or other specific sequence, but it is highly recommended.

In organims with more than one homology group of chromosomes, such as most eukaryotes, chromosomes should be aligned independently.  If large inter-chromosomal translocations exist across samples - as discovered by nucmer/dotplot - then relevant chromosomes should be pooled and aligned together.  After independant alignment, careful attention must be paid to naming when chromsomes are combined into a full genome graph.  [xmfa_tools](https://github.com/brianabernathy/xmfa_tools) handles much of the naming details but consult documentation if naming seems to be an issue.

## Variant calling

After GFA creation using [xmfa_tools](https://github.com/brianabernathy/xmfa_tools) or any graph building pipeline,  we use [variantsFromGFA.pl](https://github.com/USDA-ARS-GBRU/PanPipes/blob/main/scripts/variantsFromGFA.pl) to describe variation encoded in the graph.  The script steps through each path in the graph and builds an index of focal segments that branch into two or more segments.  Only the forward branching is retained, such that internal variants of an inversion are treated as homologous to the aligned position in the forward strand.  This behavior is distinct from tools such as vg call.  The exit from an inversion creates a special case in that it must go from reverse to forward orientation.  These events are annotated by labelling the position with a '-' suffix to reflect inversion status.  Though this prevents redundant positions, the '-' may break a tool designed to accept vcf format.  If you encounter errors, we recommend you manually remove the variant since it should, in effect, be represented by its reciprocal end variant.  Additionally, we break from vcf convention and encode insertions and deletions as '-' for the non-indel state.  This behavior is much more in keeping with the graph approach but will also break some downstream tools. 

## Short-read alignment

We have explored many read aligners and found vg giraffe to be the only aligner that scales to large, divergent plant genomes.  Giraffe index creation for graphs constructed as above requires careful attention be paid to defining homology groups (i.e. chromosomes) and founder samples based on path names.  See https://github.com/vgteam/vg/issues/3361.

Most graph aligners should produce a GAM file.  This file can be used to produce coverage per node (and position) across the graph.  We highly recommend that this be done using 'vg pack' piped directly to [pack_table_to_seg_cov.pl](https://github.com/brianabernathy/gfa_var_genotyper/blob/main/pack_table_to_seg_cov.pl) in order to reduce static memory footprint.  These file can be used for assorted useful diagnositics.  For genotyping done below, the edge table produced with an additional flag to vg pack is required.  

## Genotyping

Currently, panPipes does not support calling variants based on aligned reads.  In effect, the multiple sequence alignments are expected to retain all variant information that a researcher might be interested in.  This should always be true in the case of a biparental mapping population with assembled parents.  Cases in which numerous diverse assemblies are used to build the graph should also contain most of a sample's relevent variation.  In these cases, we suggest between 7 and 18 assemblies.  While more is not theoretically a problem, SNPs begin to fragment the graph with only diminishing returns on novel gene content. 

Once coverage information is generated, variants defined above can be called based on fairly simplistic thresholding logic: because all variants are present in the graph, coverage across the link between focal and variant nodes indicate genotype. The calling is implemented in [gfa_var_genotyper.pl](https://github.com/brianabernathy/gfa_var_genotyper/blob/main/gfa_var_genotyper.pl) and uses the vcf from the [variantsFromGFA.pl](https://github.com/USDA-ARS-GBRU/PanPipes/blob/main/scripts/variantsFromGFA.pl) described above.
