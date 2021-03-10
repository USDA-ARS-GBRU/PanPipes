#!/bin/bash

# job standard output will go to the file slurm-%j.out (where %j is the job ID)

#SBATCH -A gbru_fy21_salmonella
#SBATCH --time=24:00:00  # walltime limit (HH:MM:SS)
#SBATCH -n 48 
#SBATCH --partition=atlas    # standard node(s)
#SBATCH --job-name="salm_pggb"

#PGGB info:
:' 
org.label-schema.build-arch: amd64
org.label-schema.build-date: Friday_26_February_2021_13:40:2_CST
org.label-schema.schema-version: 1.0
org.label-schema.usage.singularity.deffile.bootstrap: docker
org.label-schema.usage.singularity.deffile.from: ghcr.io/pangenome/pggb:latest
org.label-schema.usage.singularity.version: 3.7.1
module load singularity/3.5.2
'

linesfile=/project/gbru_fy21_salmonella/pg_graph/rarefaction/lines/5ChromRepsKmedoids.txt
workingdir=./
genomesDir=/project/gbru_fy21_salmonella/data/refChromFixedOrigen/
pggb_img=/project/gbru_fy21_salmonella/software/pggb.simg
fastafile=${workingdir}/salmonella_5lines.fa

#create fasta
touch $fastafile
while read l; do
       cat ${genomesDir}/${l}_OriginSet.fasta >> $fastafile
done < $linesfile

#build pggb graph

singularity exec $pggb_img pggb -i $fastafile -s 100000 -p 80 -n 10 -t 48 -o $workingdir
