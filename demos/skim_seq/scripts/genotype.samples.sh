#!/bin/bash

GENO_DIR='../genotyping'
GRAPH_DIR='../graph'
ALIGN_DIR='../alignments'
GFA_VAR_GENO_DIR="/path/to/gfa_var_genotyper_dir"
THREADS=4
GRAPH_PREFIX='genome'
REF_GENO='parent1'


if [[ ! -f $GENO_DIR ]]
then
	mkdir -p $GENO_DIR
fi


${GFA_VAR_GENO_DIR}/gfa_variants.pl -d '\.chr' -p 'chr' -g ${GRAPH_DIR}/${GRAPH_PREFIX}.gfa 1> ${GRAPH_DIR}/${GRAPH_PREFIX}.variants.vcf 2> ${GRAPH_DIR}/${GRAPH_PREFIX}.gfa_variants.stderr

ls ${ALIGN_DIR}/*pack.edge.table.gz > ${GENO_DIR}/${GRAPH_PREFIX}.packlist

${GFA_VAR_GENO_DIR}/gfa_var_genotyper.pl -v ${GRAPH_DIR}/${GRAPH_PREFIX}.variants.vcf --packlist ${GENO_DIR}/${GRAPH_PREFIX}.packlist --rm_inv_head --ploidy 1 --low_cov --min_tot_cov 1 > ${GENO_DIR}/${GRAPH_PREFIX}.sample.variants.vcf 2> ${GENO_DIR}/${GRAPH_PREFIX}.gfa_var_genotyper.stderr

${GFA_VAR_GENO_DIR}/gfa_nodes_to_linear_coords.pl -g ${GRAPH_DIR}/${GRAPH_PREFIX}.gfa 2> ${GRAPH_DIR}/${GRAPH_PREFIX}.gfa_nodes_to_linear_coords.stderr | gzip > ${GRAPH_DIR}/${GRAPH_PREFIX}.nodes_to_linear_coords.txt.gz

${GFA_VAR_GENO_DIR}/vcf_nodes_to_linear_coords.pl -d '\.chr' -p 'chr' -c ${GRAPH_DIR}/${GRAPH_PREFIX}.nodes_to_linear_coords.txt.gz -v ${GENO_DIR}/${GRAPH_PREFIX}.sample.variants.vcf -g $REF_GENO > ${GENO_DIR}/${GRAPH_PREFIX}.sample.variants.${REF_GENO}.linear.coords.vcf 2> ${GENO_DIR}/${GRAPH_PREFIX}.vcf_nodes_to_linear_coords.stderr
