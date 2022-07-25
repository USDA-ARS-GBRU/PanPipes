#!/bin/bash

BRUTE_IMPUTE_DIR="/path/to/brute_impute_dir"
TASSEL_DIR="${HOME}/path/to/tassel_dir"
THREADS=4
XMX='2g'
MINR='0.8'
IMPUTE_DIR='../imputation'
TAXAS="${IMPUTE_DIR}/taxas.txt"
PEDIGREES="${IMPUTE_DIR}/pedigrees.txt"
OUT_PREFIX="${IMPUTE_DIR}/genome.parent1"
VCF='../genotyping/genome.sample.variants.parent1.linear.coords.vcf'
MIN_COUNT=1
MIN_FREQ='0.2'
MAX_FREQ='0.8'
PARENTA='parent1'
PARENTC='parent2'


if [[ ! -f $IMPUTE_DIR ]]
then
	mkdir -p $IMPUTE_DIR
fi


# sort vcf
${TASSEL_DIR}/run_pipeline.pl -Xmx${XMX} -SortGenotypeFilePlugin -inputFile $VCF -outputFile ${OUT_PREFIX}.sort.vcf -fileType VCF 1> ${OUT_PREFIX}.sort.stdout 2> ${OUT_PREFIX}.sort.stderr

# convert vcf to hapmap
${TASSEL_DIR}/run_pipeline.pl -Xmx${XMX} -vcf ${OUT_PREFIX}.sort.vcf -export ${OUT_PREFIX}.sort.hmp.txt -exportType Hapmap 1> ${OUT_PREFIX}.vcf.to.hmp.stdout 2> ${OUT_PREFIX}.vcf.to.hmp.stderr

# filter hyper-variable regions
${BRUTE_IMPUTE_DIR}/hyper_variable_region_filter.pl --hmp ${OUT_PREFIX}.sort.hmp.txt 1> ${OUT_PREFIX}.sort.hypervar.hmp.txt 2> ${OUT_PREFIX}.hyper_variable_region_filter.stderr

# minor allele frequency (MAF) filter
# sample parameters shown, adjust as appropriate
${TASSEL_DIR}/run_pipeline.pl -Xmx${XMX} -fork1 -h ${OUT_PREFIX}.sort.hmp.txt -includeTaxaInFile $TAXAS -filterAlign -filterAlignMinCount $MIN_COUNT -filterAlignMinFreq $MIN_FREQ -filterAlignMaxFreq $MAX_FREQ -export ${OUT_PREFIX}.sort.hypervar.maf.hmp.txt,${OUT_PREFIX}.sort.hypervar.maf.json.gz -exportType Hapmap -runfork1 -printMemoryUsage 1> ${OUT_PREFIX}.maf.stdout 2> ${OUT_PREFIX}.maf.stderr

# convert hapmap to vcf
${TASSEL_DIR}/run_pipeline.pl -Xmx${XMX} -h ${OUT_PREFIX}.sort.hypervar.maf.hmp.txt -export ${OUT_PREFIX}.sort.hypervar.maf.vcf -exportType VCF 1> ${OUT_PREFIX}.hmp.to.vcf.stdout 2> ${OUT_PREFIX}.hmp.to.vcf.stderr

# convert vcf to acm format
${BRUTE_IMPUTE_DIR}/vcf_to_acm.pl -v ${OUT_PREFIX}.sort.hypervar.maf.vcf -a $PARENTA -c $PARENTC 1> ${OUT_PREFIX}.sort.hypervar.maf.acm.vcf 2> ${OUT_PREFIX}.vcf_to_acm.stderr

# convert acm-formatted vcf to hapmap
${TASSEL_DIR}/run_pipeline.pl -Xmx${XMX} -vcf ${OUT_PREFIX}.sort.hypervar.maf.acm.vcf -export ${OUT_PREFIX}.sort.hypervar.maf.acm.hmp.txt -exportType Hapmap 1> ${OUT_PREFIX}.vcf.to.hmp.stdout 2> ${OUT_PREFIX}.vcf.to.hmp.stderr

# filter variants in low linkage disequilibrium (LD)
${BRUTE_IMPUTE_DIR}/tassel_ld_filter.pl --hapmap ${OUT_PREFIX}.sort.hypervar.maf.acm.hmp.txt -a $PARENTA -c $PARENTC --tassel $TASSEL_DIR 1> ${OUT_PREFIX}.sort.hypervar.maf.acm.ld.hmp.txt 2> ${OUT_PREFIX}.tassel_ld_filter.counts

# impute (removes first and last few variants from each chromosome)
${BRUTE_IMPUTE_DIR}/window_impute.pl --hmp ${OUT_PREFIX}.sort.hypervar.maf.acm.ld.hmp.txt 1> ${OUT_PREFIX}.window_impute.hmp.txt 2> ${OUT_PREFIX}.window_impute.stderr

# add missing variants removed by imputation (when appropriate)
${BRUTE_IMPUTE_DIR}/add_missing_imputed_records.pl -o ${OUT_PREFIX}.sort.hypervar.maf.acm.ld.hmp.txt -i ${OUT_PREFIX}.window_impute.hmp.txt 1> ${OUT_PREFIX}.window_impute.add_missing.hmp.txt 2> ${OUT_PREFIX}.window_impute.added.records

# compare pre and post-imputation hapmaps
${BRUTE_IMPUTE_DIR}/imputed_hapmap_comp.pl -o ${OUT_PREFIX}.sort.hypervar.maf.acm.ld.hmp.txt -i ${OUT_PREFIX}.window_impute.add_missing.hmp.txt 1> ${OUT_PREFIX}.window_impute.add_missing.mismatch.geno.freq 2> ${OUT_PREFIX}.window_impute.add_missing.mismatch.genos

# count variants with Ns for all population genotypes
${BRUTE_IMPUTE_DIR}/hapmap_all_n_vars_count.pl --hmp ${OUT_PREFIX}.window_impute.add_missing.hmp.txt 1> ${OUT_PREFIX}.window_impute.add_missing.hmp.all.n.var.count 2> ${OUT_PREFIX}.hapmap_all_n_vars_count.stderr
