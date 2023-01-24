<p xmlns:dct="http://purl.org/dc/terms/">
<a rel="license" href="http://creativecommons.org/publicdomain/mark/1.0/">
<img src="http://i.creativecommons.org/p/mark/1.0/88x31.png"
     style="border-style: none;" alt="Public Domain Mark" />
</a>
<br />
This work is free of known copyright restrictions.
</p>

# PanPipes
![PanPipes Logo](/images/logo.png)

See recent [pre-print on bioRxiv](https://www.biorxiv.org/content/10.1101/2022.06.10.495676v1)! 

PanPipes is an end-to-end pipeline for pan-genomic graph construction and genetic analysis.  Multiple components of the pipeline may have specific utility outside of PanPipes and so have been broken into three application groups: [xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools "xmfa_tools"), [gfa_var_genotyper](https://github.com/USDA-ARS-GBRU/gfa_var_genotyper "gfa_var_genotyper"), and [brute_impute](https://github.com/USDA-ARS-GBRU/brute_impute "brute impute").  See Required Software below. 

## Required Software

* For manipulating xmfas: xmfa_tools [https://github.com/USDA-ARS-GBRU/xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools "xmfa_tools")
* For genotyping directly from a graph: gfa_var_genotyper [https://github.com/USDA-ARS-GBRU/gfa_var_genotyper](https://github.com/USDA-ARS-GBRU/gfa_var_genotyper "gfa_var_genotyper")
* For imputation optimized for skim-seq data and realistic plant populations: brute_impute [https://github.com/USDA-ARS-GBRU/brute_impute](https://github.com/USDA-ARS-GBRU/brute_impute "brute impute")


The PanPipes repository provides documentation detailing the end-to-end combined usage of our tools in a pan-genomic context. A PanPipes singularity image is available ([coming soon](https://github.com/USDA-ARS-GBRU/PanPipes/singularity/PanPipes.singularity "PanPipes singularity image")) to provide all required software for running PanPipes. Required external software packages (in addition to GBRU repos above) are listed below, if you prefer to install manually.

* vg: [https://github.com/vgteam/vg](https://github.com/vgteam/vg "vg")
* tassel: [https://tassel.bitbucket.io/](https://tassel.bitbucket.io/ "tassel")

Additional tools support upstream aspects of PanPipes, but are not strictly necessary.

* mauve: [https://darlinglab.org/mauve/mauve.html](https://darlinglab.org/mauve/mauve.html "mauve")


## Demos

Test data and scripts are provided to demonstrate workflows for various types of PanPipes analyses. The test data is simplified to reduce size and computational resources required. For simplicity, the provided demo scripts also process MSA chromosomes and align samples sequentially. When working with larger data sets, particularly on an HPC, it is recommended to parallelize MSA/graph construction and sample alignment to increase processing speed. However, the demos are designed to run on a modern laptop, see specific analysis sections below for processing requirments and time details.

To run any of the PanPipes demos below, the [required software](#required-software) must be installed. Also, the variables defined at the top of scripts in the `/demos/analysis_type/scripts` directory must be modified to reflect your environment and desired processing parameters. At minimum, the paths to the [required software](#required-software) must be set properly.

The demos below were tested using the most recent [xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools "xmfa_tools"), [gfa_var_genotyper](https://github.com/USDA-ARS-GBRU/gfa_var_genotyper "gfa_var_genotyper"), and [brute_impute](https://github.com/USDA-ARS-GBRU/brute_impute "brute impute"). Additional software versions tested were vg v1.42.0, TASSEL v5.0 and progressiveMauve build 2015-02-13.

### Skim-Based Genotyping and Imputation

The [demos/skim_seq](https://github.com/USDA-ARS-GBRU/PanPipes/tree/main/demos/skim_seq) directory contains 3 graph references, 2 chromosomes each. 2 parent and 4 RIL sample paired reads are also included. End-to-end processing (MSA and graph construction, graph indexing, read alignment, genotyping and imputation) took ~5 minutes to complete on an Intel Xeon Gold 2.4GHz cpu using 4 threads and 2GB memory. The relatively low computational resource requirements should allow the demo to run on a modern laptop.

### more demos coming soon


## Overview

<img src="/images/workFlow.png" width=450>

Founder assemblies are aligned on a per chromosome basis.  Alignments are converted to graph data objects and merged into a whole-genome graph.  All variants segregating in founders are identified and described in a modified variant call format (VCF).  Short-reads from recombinant individuals are aligned to the genome graph and genotypes are inferred based on branch-specific read support.  These genotypes are added to the VCF file and conventional genetic analysis can be used to associate pangenomic loci with phenotypes.  Associated loci can be directly examined for major gene-altering variation by returning to chromosome alignments on which the graph is based.

## Graph Construction

All downstream processing is based on genome-scale multi-sequence alignments that are converted into graph objects in [GFA format](https://github.com/GFA-spec/GFA-spec/blob/master/GFA1.md).  The sequences used to build the alignments must be represented as paths in the GFA.  Our original method of alignment was based on a multi-threaded implementation of the progressiveMauve algorithm, see [GPA](https://academic.oup.com/bioinformatics/article/35/14/i71/5529231).  Treatment of resultant alignment files - XMFAs - and conversion to GFAs is detailed directly below.  Other software, such as [pggb](https://github.com/pangenome/pggb), can generate such graphs directly.  In our hands, we have noticed that pggb often generates unwarranted cycles that violate the positional homology paradigm followed in PanPipes (see above).  In our hands, the best method to generate such GFAs directly is [Minigraph-Cactus](https://github.com/ComparativeGenomicsToolkit/cactus/blob/master/doc/pangenome.md).  Though the resultant GFAs can still contain cycles, these are generally rare and limited to local tandem duplication.  In addition, Mingraph-Cactus is highly scalable. Still, the availability of an excelllent [viewer](https://darlinglab.org/mauve/user-guide/viewer.html) for XMFAs makes the choice of alignment strategy difficult.  For alignments of less than 5 genomes within the same species, we continue to recommend the mauve/XMFA approach, but are actively working on GFA to XMFA conversions that will shift the balance to exclusive use of Minigraph-Cactus.

When using progressiveMauve/GPA, we convert alignments to graphs using [xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools).  In brief, large collinear blocks in the alignment are converted via 'vg construct' and the blocks are connected by adjusting segment numbers to reflect the relationship between large-scale rearrangments.  

We have observed [futile gap openings](https://github.com/koadman/mauve/issues/2) in progressiveMauve alignments.  Such artifacts create false variants and confuse read mapping.  They are easy to detect and remove and are eliminated by default in [xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools). Similiarly, futile border gaps in true indels - another common artifact - are generally of little consequence as a proportion of the total indel, although, if mechanistic understanding is the objective, these subsampled regions should be realigned.

To acknowledge the concept of a linear reference, xmfas can be sorted relative to the member sequences using [xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools).  This sort occurs in a hierarchical fashion defined by the user.  In effect, the primary sequence, as chosen, will be perfectly collinear with the segment ordering of the graph.  This sort is not required; the re-ordering is a conceptual convenience if you desire your graph to be in roughly the same configuration as a community reference or other specific sequence, but it is highly recommended.

In organisms with more than one homology group of chromosomes, such as most eukaryotes, chromosomes should be aligned independently.  If large inter-chromosomal translocations exist across samples - as discovered by nucmer/dotplot - then relevant chromosomes should be pooled and aligned together.  After independant alignment, careful attention must be paid to naming when chromsomes are combined into a full genome graph.  [xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools) handles much of the naming details but consult documentation if naming seems to be an issue.

## Graph Variants

After GFA creation using [xmfa_tools](https://github.com/USDA-ARS-GBRU/xmfa_tools) or another graph building pipeline, we use [gfa_variants.pl](https://github.com/USDA-ARS-GBRU/gfa_var_genotyper/blob/main/gfa_variants.pl) to describe variation encoded in the graph.  The script steps through each path in the graph and builds an index of focal segments that branch into two or more segments.  Only the forward branching is retained, such that internal variants of an inversion are treated as homologous to the aligned position in the forward strand.  This behavior is distinct from tools such as vg call.  The exit from an inversion creates a special case in that it must go from reverse to forward orientation.  These events are annotated by labelling the position with a '-' prefix to reflect inversion status.  Though this prevents redundant positions, the '-' may break a tool designed to accept vcf format.  If you encounter errors, we recommend you manually remove the variant since it should, in effect, be represented by its reciprocal end variant.  Additionally, we break from vcf convention and encode insertions and deletions as '-' for the non-indel state.  This behavior is much more in keeping with the graph approach but will also break some downstream tools. 

## Short-read Alignment

We have explored many read aligners and found vg giraffe to be the only aligner that scales to large, divergent plant genomes.  Giraffe index creation for graphs constructed as above requires careful attention be paid to defining homology groups (i.e. chromosomes) and founder samples based on path names.  See https://github.com/vgteam/vg/issues/3361. The creation of giraffe indexes required for alignment is discussed in more detail at [gfa_var_genotyper](https://github.com/brianabernathy/gfa_var_genotyper).

Most graph aligners should produce a GAM file which can be used to produce coverage per node (and position) across the graph. These file can be used for assorted useful diagnositics.  For genotyping done below, the pack edge table produced with an additional flag to vg pack is required.  

## Genotyping

Currently, panPipes does not support calling variants based on aligned reads.  In effect, the multiple sequence alignments are expected to retain all variant information that a researcher might be interested in.  This should always be true in the case of a biparental mapping population with assembled parents.  Cases in which numerous diverse assemblies are used to build the graph should also contain most of a sample's relevent variation.  In these cases, we suggest between 7 and 18 assemblies.  While more is not theoretically a problem, SNPs begin to fragment the graph with only diminishing returns on novel gene content.  (Users may want to add small new variants evident from aligning high-coverage, short-read data of a divergent line, such as in GWAS.  In such cases, the vg documentation describes how to call such variants and update the graph to reflect these new nodes.  Currently, downstream steps of PanPipes would not be stable in such cases due to possible node reassignments, and one should proceed with vg's native genotyper.)

Once coverage information is generated, variants defined above can be called based on fairly simplistic thresholding logic: because all variants are present in the graph, coverage across the link between focal and variant nodes indicate genotype. The calling is implemented in [gfa_var_genotyper.pl](https://github.com/USDA-ARS-GBRU/gfa_var_genotyper/blob/main/gfa_var_genotyper.pl) and uses the vcf from the [gfa_variants.pl](https://github.com/USDA-ARS-GBRU/gfa_var_genotyper/blob/main/gfa_variants.pl) described above. See the [gfa_var_genotyper](https://github.com/USDA-ARS-GBRU/gfa_var_genotyper) repository for more information.

## Imputation

Imputation is performed using [brute_impute](https://github.com/USDA-ARS-GBRU/brute_impute). [TASSEL](https://tassel.bitbucket.io/) is required to provide basic functionality. However, in our experience, TASSEL struggles to properly impute skim-seq genotyping. brute_impute includes several scripts to provide additional filtering, format conversion, imputation, assessment and error checking. Our testing has shown brute_impute is able to impute more regions at a lower error-rate than TASSEL.
