#!/bin/bash

#SBATCH --job-name="sim_linear_graph_map_performance"

#SBATCH -p mem768

#SBATCH -N 1

#SBATCH -n 38
#SBATCH --mem=500G

#SBATCH -t 2-00:00:00

#SBATCH --mail-user=xwwang@uga.edu

#SBATCH --mail-type=BEGIN,END,FAIL

#SBATCH -o "%x.%j.o"

#SBATCH -e "%x.%j.e"
#SBATCH -A gbru_arachis
##SBATCH -A proj-gbru_synth_arachis_tetra

## scavenger-mem
## SBATCH -p mem
## scavenger-mem
## atlas

nthreadxw=38

#############dir prepare
mbase=/lustre/project/gbru/gbru_arachis/pan_genome
scriptdir=$mbase/scripts/scripts_graphgenome
outdir=$mbase/mauvePro_Out/Optimized/Sw31SfMsp4kcoln/simILlike10k
if [ ! -d $outdir ]; then
	mkdir $outdir
fi
cd $outdir


####################################################################
#usage: V2
# 1. Give the prefix of reference seq for mapping: refseq
# 2. Give the prefix of seq for simluated read and self-mapping
# 3. Set the reads number -N for simulating, default here 10k
# 4. Genome graph in .gfa 
# Report file (mapping.report) will be auto-generated for BWA mapping, BWA self-ref mapping, GraphAligner mapping in tabular plain text
# Report content including: ref, reads, input reads, mapped reads #, fully-mapped reads #, uniquely mapped reads

# in slurm computing cluster, the summary of GraphAlinger mapping will be automatically reported into the .mapping.report file.
# ---author---: Xuewen Wang
# version: 2021 April, version 2

####################################################################
#### Step 1 simulate the paired-end reads

 # the reference other than the sequence for simulating reads
 refdir="/lustre/project/gbru/gbru_arachis/gene.conv/reference" #dir of ref seq
 refseq="arahy.Tifrunner.gnm2.chrAall" # arahy.Tifrunner.gnm2.chrAall.fa  
 refname="tiffrunner genome"  #allias, any name
 echo $refseq.fa $refname  >refseq_reads.info
 cp $refdir/$refseq.fa ./$refseq.fa
 
 
 # the reference for simulated reads
 simfromref="araca.K10017.gnm1.chr02"  #araca.K10017.gnm1.chr02.fa
 cp $refdir/${simfromref}.fa ./${simfromref}.fa
 echo "simulated reads from araca.K10017.gnm1.chr02" >>refseq_reads.info
 
 #10k reads
 simtool=/lustre/project/gbru/gbru_arachis/xuewen.wang/wgsim  # tool link: https://github.com/lh3/wgsim
 $simtool/wgsim  -1 150 -2 150 -N 5000  -r 0 -R 0 -X 0 ${simfromref}.fa r1.fq r2.fq
 sample="simCakch02"  #read sample name

#################################################################### 
#### Step 2.1 mapping and full length, BWA
module load samtools/1.10
module load bwa/0.7.17

#mapping
 bwa index ${refseq}.fa
 time bwa mem -P -S ${refseq}.fa r1.fq r2.fq -t $nthreadxw -o refseq.sam  # mapping in single read mode, ignore pairing and mate 
   samtools view -o outbam.bam refseq.sam
   samtools sort -T ./tmp.aln.sorted -t $nthreadxw -o ${refseq}_${sample}.sorted.bam outbam.bam
   rm refseq.sam outbam.bam
  
#Report mapping statistical information as required
 reportfile="refseq.BWA.GraphAligner.mapping.report"
 echo "########################" >$reportfile
 echo "Mapping report for BWA vs GraphAligner" >>$reportfile
 echo "Simulated reads are from  $simfromref" >>$reportfile
 
 echo >>$reportfile
 printf "Reads were mapped to\t$refseq\n" >>$reportfile
 printf "Mapper:\tBWA mem\n" >>$reportfile
 
 samtools stats ${refseq}_${sample}.sorted.bam |grep "SN" >${refseq}_${sample}.sorted.bam.BWA.stats
 inread=`cat ${refseq}_${sample}.sorted.bam.BWA.stats| grep -E "SN\s+raw total sequences:"|cut -f3` #  988452
 mpread=`cat ${refseq}_${sample}.sorted.bam.BWA.stats| grep -E "SN\s+reads mapped:"|cut -f3` 
 printf "Raw reads:\t$inread\n" >>$reportfile
 printf "Mapped reads:\t$mpread\n" >>$reportfile 

#split
 splitCT=`samtools view -f 2048 ${refseq}_${sample}.sorted.bam |cut -f1 | sort | uniq|wc -l`
 #printf "Split reads:\t$splitCT\n" >> $reportfile

#mapped and not split reads 
 mpnotsplit=$((mpread-splitCT))
 printf "Mapped and not split reads:\t$mpnotsplit\n" >>$reportfile
 
#### Step 2.2 full-length uniquely mapped and not split reads, BWA
 #filter out low mapping quality, get uniq mapped reads 
 # MQ=`samtools view -q 50 -F 2048 ${refseq}_${sample}.sorted.bam |cut -f1 | sort | uniq|wc -l`
MQ=`cut -f1 ${refseq}_${sample}.sorted.MQ50.sam | wc -l`
 printf "Mapped, not split and quality MQ50 filtered reads:\t$MQ\n" >>$reportfile
 echo "
   BWA stats: refseq.BWA.stats
   BWA mapping report file: $reportfile"


####################################################################
#### Step 3.1 mapping and full length, GraphAligner
tool=/lustre/project/gbru/gbru_arachis/xuewen.wang/graghaligner/bin  #version1.0.12
# /lustre/project/gbru/gbru_arachis/xuewen.wang/graghaligner1.0.13/graghaligner/bin  #1.0.13
export PATH=$tool:$PATH
vgtool=/lustre/project/gbru/gbru_arachis/xuewen.wang/vg1.30
## GraphAligner

inf="graph.Allchr.coln.hg.gfa"
#prefix of graph
graph=${inf/.gfa/}
cp ../$inf ./

 time  $tool/GraphAligner -g $graph.gfa -f r1.fq -f r2.fq -t $nthreadxw --seeds-mum-count -1  --bandwidth 32 -a $graph.$sample.global.gam  --try-all-seeds --global-alignment
#the mapping information is in the log file

#filter graph alignment .gam
 identity=0.9
 $vgtool/vg filter -f -u -r $identity $graph.$sample.global.gam > $graph.$sample.global.gam.flt${identity}.gam 
 $vgtool/vg stats -a $graph.$sample.global.gam.flt${identity}.gam >$graph.$sample.global.gam.flt${identity}.gam.vg.stats

#### Step 3.2 mapping and full-length uniquely mapped reads, GraphAligner
 echo >>$reportfile
 echo "########################" >>$reportfile
 echo "GraphAlinger mapping results: please see the mapping log file"
 cp $scriptdir/${SLURM_JOB_NAME}.${SLURM_JOB_ID}.o ./
 logfile=${SLURM_JOB_NAME}.${SLURM_JOB_ID}.o
 grep "Input reads" $logfile|awk '{print $1" "$2"\t"$3}' >>$reportfile #Input reads:    1000000
 grep "Alignments" $logfile |awk '{print $1"\t"$2}' >>$reportfile
 grep "End-to-end alignments" $logfile |awk '{print $1" "$2"\t"$3}' >>$reportfile

 grep "Total alignments" $graph.$sample.global.gam.flt${identity}.gam.vg.stats|awk '{print "Mapped reads identity >= 0.9\t"$3}' >>$reportfile

####################################################################
#### step 4 read mapped back to self reference where it is generated from
refseq=$simfromref
#mapping
 bwa index ${refseq}.fa
 # -M            mark shorter split hits as secondary
 time bwa mem -P -S ${refseq}.fa r1.fq r2.fq -t $nthreadxw -o ${refseq}_${sample}.sam 
   samtools view -o ${refseq}_${sample}.bam ${refseq}_${sample}.sam
   samtools sort -T ./tmp.aln.sorted -t $nthreadxw -o ${refseq}_${sample}.sorted.bam ${refseq}_${sample}.bam
   rm ${refseq}_${sample}.sam ${refseq}_${sample}.bam
   
 
#Report mapping statistical information as required
 echo >>$reportfile
 echo "########################" >>$reportfile
 echo "Reads were mapped back to the reference where they are simulated from" >>$reportfile
 echo "Simulated reads are from  $simfromref" >>$reportfile
 printf "Reads were mapped to\t$refseq\n" >>$reportfile
 printf "Mapper:\tBWA mem\n" >>$reportfile
 
 
 samtools stats ${refseq}_${sample}.sorted.bam |grep "SN" >${refseq}_${sample}.sorted.bam.BWA.stats
 inread=`cat ${refseq}_${sample}.sorted.bam.BWA.stats| grep -E "SN\s+raw total sequences:"|cut -f3` #  988452
 mpread=`cat ${refseq}_${sample}.sorted.bam.BWA.stats| grep -E "SN\s+reads mapped:"|cut -f3` 
 printf "Raw reads:\t$inread\n" >>$reportfile
 printf "Mapped reads:\t$mpread\n" >>$reportfile
 
#split
 splitCT=`samtools view -f 2048 ${refseq}_${sample}.sorted.bam |cut -f1 | sort | uniq|wc -l`
 #printf "Split reads:\t$splitCT\n" >> $reportfile

#mapped and not split reads
 mpnotsplit=$((mpread-splitCT))
 printf "Mapped and not split reads:\t$mpnotsplit\n" >>$reportfile
 
# mapped, not split and mapping quality MQ filtered 
 #MQ=`samtools view -q 50 -F 2048 ${refseq}_${sample}.sorted.bam |cut -f1 | sort | uniq|wc -l`
 MQ=`cut -f1 ${refseq}_${sample}.sorted.MQ50.sam | wc -l`
 printf "Mapped, not split and quality MQ50 filtered reads:\t$MQ\n" >>$reportfile
 echo "
