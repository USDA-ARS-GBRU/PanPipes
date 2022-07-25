#!/bin/bash

GRAPH_DIR='../graph'
VG='/path/to/vg'
THREADS=4
OUT_PREFIX='genome'

if [[ ! -f $GRAPH_DIR ]]
then
	mkdir -p $GRAPH_DIR
fi


$VG gbwt --progress --num-threads $THREADS -M -SL -CL -HL -TL --path-regex "(.*)\.(.*)" --path-fields "_SC" -G ${GRAPH_DIR}/${OUT_PREFIX}.gfa --gbz-format -g ${GRAPH_DIR}/${OUT_PREFIX}.gbz 1> ${GRAPH_DIR}/${OUT_PREFIX}.vg.gbwt.stdout 2> ${GRAPH_DIR}/${OUT_PREFIX}.vg.gbwt.stderr

$VG snarls -T --threads $THREADS ${GRAPH_DIR}/${OUT_PREFIX}.gbz 1> ${GRAPH_DIR}/${OUT_PREFIX}.snarls 2> ${GRAPH_DIR}/${OUT_PREFIX}.vg.snarls.stderr

$VG index --progress --threads $THREADS ${GRAPH_DIR}/${OUT_PREFIX}.gbz -s ${GRAPH_DIR}/${OUT_PREFIX}.snarls -j ${GRAPH_DIR}/${OUT_PREFIX}.dist 1> ${GRAPH_DIR}/${OUT_PREFIX}.vg.index.stdout 2> ${GRAPH_DIR}/${OUT_PREFIX}.vg.index.stderr

$VG minimizer --progress --threads $THREADS --distance-index ${GRAPH_DIR}/${OUT_PREFIX}.dist ${GRAPH_DIR}/${OUT_PREFIX}.gbz -o ${GRAPH_DIR}/${OUT_PREFIX}.min 1> ${GRAPH_DIR}/${OUT_PREFIX}.vg.minimizer.stdout 2> ${GRAPH_DIR}/${OUT_PREFIX}.vg.minimizer.stderr
