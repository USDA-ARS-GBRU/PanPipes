#!/bin/bash

READS_DIR='../reads'
GRAPH_DIR='../graph'
ALIGN_DIR='../alignments'
VG='/path/to/vg'
THREADS=4
MIN_MQ=60
GRAPH_PREFIX='genome'


if [[ ! -f $ALIGN_DIR ]]
then
	mkdir -p $ALIGN_DIR
fi


# For simplicity, the test data samples are processed sequentially.
# To increase processing speed, with larger data sets in particular,
# samples may be processed in parallel as separate jobs.

for SAMPLE in parent1_sample parent2_sample ril1_sample ril2_sample ril3_sample ril4_sample
do

	$VG giraffe --threads $THREADS --progress -Z ${GRAPH_DIR}/${GRAPH_PREFIX}.gbz -d ${GRAPH_DIR}/${GRAPH_PREFIX}.dist -m ${GRAPH_DIR}/${GRAPH_PREFIX}.min -f ${READS_DIR}/${SAMPLE}.r1.fq.gz -f ${READS_DIR}/${SAMPLE}.r2.fq.gz 1> ${ALIGN_DIR}/${SAMPLE}.gam 2> ${ALIGN_DIR}/${SAMPLE}.vg.giraffe.stderr

	# MQ filtering is optional, but recommended
	$VG filter --threads $THREADS --min-mapq $MIN_MQ ${ALIGN_DIR}/${SAMPLE}.gam 1> ${ALIGN_DIR}/${SAMPLE}.mq${MIN_MQ}.gam 2> ${ALIGN_DIR}/${SAMPLE}.vg.filter.stderr

	$VG pack --threads $THREADS -x ${GRAPH_DIR}/${GRAPH_PREFIX}.xg -g ${ALIGN_DIR}/${SAMPLE}.mq${MIN_MQ}.gam -D 2> ${ALIGN_DIR}/${SAMPLE}.vg.pack.stderr | gzip > ${ALIGN_DIR}/${SAMPLE}.mq${MIN_MQ}.pack.edge.table.gz

done
