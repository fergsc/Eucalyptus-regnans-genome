# sample setup
LABEL="hap1"
READS1=""
READS2=""
CONTIGS="XXX.fasta"
FAIDX="XXX.fasta.fai"
threads=12
ENZYME="GATC,GANTC,TTAA,CTNAG"

# tool locations
BWA=""
SAMTOOLS=""
FILTER=""
COMBINER=""
STATS=""
PICARD=""
YAHS=""
JUICER=""
JUICERTOOLS=""


### Arima Genomics mapping pipeline

# setup directories
RAW_DIR='raw-bams'
FILT_DIR='filtered-bams'
TMP_DIR='tmpFiles'
PAIR_DIR='paired-bams'
MAPQ_FILTER=20

mkdir $LABEL~Arima
cd $LABEL~Arima
cp $CONTIGS $READS1 $READS2 $LABEL~Arima
reads1File=$(basename $READS1)
reads2File=$(basename $READS2)
contigsFile=$(basename $CONTIGS)

# run Arima
echo "### Step 0: Check output directories exist & create them as needed"
[ -d $RAW_DIR ] || mkdir -p $RAW_DIR
[ -d $FILT_DIR ] || mkdir -p $FILT_DIR
[ -d $TMP_DIR ] || mkdir -p $TMP_DIR
[ -d $PAIR_DIR ] || mkdir -p $PAIR_DIR

$BWA index $contigsFile

echo "### Step 1.A: FASTQ to BAM (1st)"
$BWA mem -t threads ${contigsFile} ${reads1File} > tmp.sam
$SAMTOOLS view -@ threads -Sb tmp.sam > ${RAW_DIR}/R1.bam

echo "### Step 1.B: FASTQ to BAM (2nd)"
$BWA mem -t threads ${contigsFile} ${reads2File} > tmp.sam
$SAMTOOLS view -@ threads -Sb tmp.sam > ${RAW_DIR}/R2.bam

echo "### Step 2.A: Filter 5' end (1st)"
$SAMTOOLS view -h ${RAW_DIR}/R1.bam | perl $FILTER > tmp.sam
$SAMTOOLS view -Sb tmp.sam > ${FILT_DIR}/R1.bam
echo "### Step 2.B: Filter 5' end (2nd)"
$SAMTOOLS view -h ${RAW_DIR}/R2.bam | perl $FILTER > tmp.sam
$SAMTOOLS view -Sb tmp.sam > ${FILT_DIR}/R2.bam

echo "### Step 3A: Pair reads & mapping quality filter"
perl $COMBINER ${FILT_DIR}/R1.bam ${FILT_DIR}/R2.bam $SAMTOOLS $MAPQ_FILTER | $SAMTOOLS view -bS -t $FAIDX | $SAMTOOLS sort -@ threads -m 12G -o ${TMP_DIR}/${LABEL}.bam
echo "### Step 3.B: Add read group"
java -Xmx64G -Djava.io.tmpdir=temp/ -jar $PICARD AddOrReplaceReadGroups INPUT=${TMP_DIR}/${LABEL}.bam OUTPUT=${PAIR_DIR}/${LABEL}.bam ID=${LABEL}-hic LB=${LABEL}-hic SM=${LABEL} PL=ILLUMINA PU=none

echo "### Step 4: Mark duplicates"
java -Xmx64G -XX:-UseGCOverheadLimit -Djava.io.tmpdir=temp/ -jar $PICARD \
    MarkDuplicates INPUT=${PAIR_DIR}/${LABEL}.bam OUTPUT=${LABEL}.bam \
    METRICS_FILE=metrics.txt TMP_DIR=${TMP_DIR} \
    ASSUME_SORTED=TRUE VALIDATION_STRINGENCY=LENIENT REMOVE_DUPLICATES=TRUE
$SAMTOOLS index ${LABEL}.bam
perl $STATS ${LABEL}.bam > ${LABEL}.bam.stats
echo "Finished Mapping Pipeline through Duplicate Removal"

rm $reads1File $reads2File $contigsFile.*


### YaHS - generate a Hi-C contact map
BAM="$LABEL~Arima/${LABEL}.ba"

mkdir -p $LABEL~YaHS
cp $BAM $CONTIGS $FAIDX $LABEL~YaHS
cd $LABEL~YaHS

YAHS --no-contig-ec -e $ENZYME --no-mem-check -o $LABEL $(basename $CONTIGS) $(basename $BAM)
$JUICER pre ${LABEL}.bin ${LABEL}_scaffolds_final.agp $(basename $CONTIGS).fai | sort -k2,2d -k6,6d -T ./ --parallel=${threads} -S32G | awk 'NF' > alignments_sorted.txt.part
mv alignments_sorted.txt.part alignments_sorted.txt

bioawk -c fastx '{print $name, length($seq)}' ${LABEL}_scaffolds_final.fa > ${LABEL}_scaffolds_final.chrom.sizes
java -jar -Xmx32G ${JUICERTOOLS} pre alignments_sorted.txt out.hic.part ${LABEL}_scaffolds_final.chrom.sizes
mv out.hic.part out.hic


### manual curation with juicebox
$JUICER pre -a -o out_JBAT ${LABEL}.bin ${LABEL}_scaffolds_final.agp $(basename $CONTIGS).fai > out_JBAT.log 2>&1

(java -jar -Xmx32G $JUICERTOOLS pre out_JBAT.txt out_JBAT.hic.part <(cat out_JBAT.log  | grep PRE_C_SIZE | awk '{print $2" "$3}'))
mv out_JBAT.hic.part out_JBAT.hic

# Use juice box to visualise and check scaffolding
# When done save modified assembly (if changes were made)
#     https://github.com/aidenlab/Juicebox
#     https://www.youtube.com/@AidenLab/videos


### YaHS - complete genome

mkdir -p $LABEL~complete
cd $LABEL~complete

$JUICER post -o out_JBAT out_JBAT.review.assembly out_JBAT.liftover.agp $CONTIGS
