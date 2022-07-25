#!/bin/bash

REFS_DIR='../refs'
MSA_DIR='../msa'
GRAPH_DIR='../graph'
PROG_MAUVE='/path/to/progressiveMauve'
VG='/path/to/vg'
XMFA_TOOLS='/path/to/xmfa_tools/xmfa_tools.pl'
# sort by ref1, then parent1, then parent2
# see xmfa_tools.pl -p to view xmfa seq ids and names
SORT_ORDER='3 1 2'
SEED_WEIGHT=27
THREADS=4
OUT_PREFIX='genome'
VG_FILES=''

if [[ ! -f $MSA_DIR ]]
then
	mkdir -p $MSA_DIR
fi

if [[ ! -f $GRAPH_DIR ]]
then
	mkdir -p $GRAPH_DIR
fi


# For simplicity, the test data chromosomes are processed sequentially.
# To increase processing speed, with larger data sets in particular,
# chromosomes may be processed in parallel as separate jobs.

for CHR in 01 02
do

	$PROG_MAUVE --seed-weight=$SEED_WEIGHT --output=${MSA_DIR}/chr${CHR}.mauve.xmfa ${REFS_DIR}/parent1.chr${CHR}.fa ${REFS_DIR}/parent2.chr${CHR}.fa ${REFS_DIR}/ref1.chr${CHR}.fa 1> ${MSA_DIR}/chr${CHR}.mauve.stdout 2> ${MSA_DIR}/chr${CHR}.mauve.stderr

	$XMFA_TOOLS -x ${MSA_DIR}/chr${CHR}.mauve.xmfa --xmfaout ${MSA_DIR}/chr${CHR}.mauve.xmfa_tools.xmfa -s --order $SORT_ORDER -g ${GRAPH_DIR}/chr${CHR}.mauve.xmfa_tools.gfa -v $VG -t $THREADS --catgfapaths 1> ${MSA_DIR}/chr${CHR}.xmfa_tools.stdout 2> ${MSA_DIR}/chr${CHR}.xmfa_tools.stderr

	$VG convert -t $THREADS -g ${GRAPH_DIR}/chr${CHR}.mauve.xmfa_tools.gfa -v 1> ${GRAPH_DIR}/chr${CHR}.vg 2> ${GRAPH_DIR}/chr${CHR}.convert.stderr

    VG_FILES="${VG_FILES} ${GRAPH_DIR}/chr${CHR}.vg"

done

$VG combine $VG_FILES 1> ${GRAPH_DIR}/${OUT_PREFIX}.vg 2> ${GRAPH_DIR}/${OUT_PREFIX}.combine.stderr

$VG convert -t $THREADS -f ${GRAPH_DIR}/${OUT_PREFIX}.vg 1> ${GRAPH_DIR}/${OUT_PREFIX}.gfa 2> ${GRAPH_DIR}/${OUT_PREFIX}.convert.gfa.stderr

$VG convert -t $THREADS -x ${GRAPH_DIR}/${OUT_PREFIX}.vg 1> ${GRAPH_DIR}/${OUT_PREFIX}.xg 2> ${GRAPH_DIR}/${OUT_PREFIX}.convert.xg.stderr
