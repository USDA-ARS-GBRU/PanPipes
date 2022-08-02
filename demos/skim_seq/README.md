## skim-seq demo

Please note the variables containing paths to required software (`VARIABLE='/path/to/...'`) need to be set in all sub-component scripts according to the locations of relevant software on your system. Aside from these modifications, the demo can be run as-is.

- `run.all.sh`: Runs all sub-components of the PanPipes skim-seq demo. Each sub-component is briefly described below.

- `msa.construct.graph.sh`:  Sequentially align chromosomes, create chromosome graphs and finally combine these graphs into a genome graph.

- `index.graph.sh`: Create the genome graph index required for read alignment with `vg giraffe`. Pay close attention to the `--path-regex` and `--path-fields` parameters. All chromosome fasta headers used to construct the MSAs and graphs need to match this pattern. Generally, it is best to properly format the chromosome fasta headers first. See the [demos/skim_seq/refs](https://github.com/USDA-ARS-GBRU/PanPipes/tree/main/demos/skim_seq/refs) directory for examples.

- `align.reads.sh`: Align short reads to the genome graph with `vg giraffe` and create edge coverage tables for variant calling.  Note, the filter step is quite stringent (MIN_MQ=60).  If implementing with your own data, we highly recommend that you evaluate pre and post-filtered alignments, which are both retained and named according to the selected filter.

- `genotype.samples.sh`: Call alleles for each supplied edge coverage table and produce a non-standard VCF file. See [Graph Variants](#graph_variants) on the main page. Also note that `vcf_nodes_to_linear_coords.pl` converts long and/or complex variant alleles to 'AAAAAAAAAA', 'CCCCCCCCCC', etc...

- `impute.sample.sh`:  Convert allele calls to A/C (parent1/parent2) format, impute missing data, and correct miscalls based on inferred parent haplotypes. Many of the steps in this sub-component require careful parameterization that depend on the input and the biology of the system. For example, `tassel.ld.filter.pl` and `window_impute.pl` are very dependent on windowing values that should be fully understood to obtain optimal results. Consult the individual [brute_impute](https://github.com/USDA-ARS-GBRU/brute_impute) script help menus (`-h` or `--help` option) or [brute_impute](https://github.com/USDA-ARS-GBRU/brute_impute) repository for more details. You should also have a rough idea of your population's minimum variants per recombination bin.
