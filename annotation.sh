genome="/path to genome/genome.fasta"
cpus=XX

### annotate repeats and TEs
mkdir repeats repeats/EDTA
cd repeats/EDTA
EDTA.pl --genome $genome --anno 1 --threads $cpus
cd ../
RepeatMasker -pa $cpus -s -lib EDTA/$(basename $genome).mod.EDTA.TElib.fa -dir repeatMask -e ncbi $genome

cd ../
sed -e '1,3d' repeats/$(basename $genome).out | awk -v OFS='\t' '{print $5, $6-1, $7}' | sort -k1,1 -k2,2 -V > $(basename $genome).bed

### soft mask repeats
bedtools maskfasta -soft -fi $genome -bed ${label}.bed -fo ${label}-softMasked.fasta


### BRAKER# - annotate for genes
genome="$(pwd/${label}-softMasked.fasta)"
trainingData="" # fasta of proteins
threads=12
workingDir="./"

perl "/path/BRAKER_3.0.6/scripts/braker.pl          \
    --genome=$genome                                \
    --species="braker3~$(basename $genome .fasta)   \
    --prot_seq=$trainingData                        \
    --useexisting                                   \
    --threads $threads                              \
    --workingdir=$workingDir                        \
    --AUGUSTUS_BIN_PATH="/path/BRAKER_3.0.6/bin     \
    --AUGUSTUS_SCRIPTS_PATH="/path/BRAKER_3.0.6/bin \
    --BAMTOOLS_PATH="/path/BRAKER_3.0.6/bin         \
    --GENEMARK_PATH="/path/gmes_linux_64-2020_01    \
    --SAMTOOLS_PATH=/path/samtools                  \
    --PROTHINT_PATH="/path/ProtHint-2.6.0/bin       \
    --DIAMOND_PATH="/path/diamond-2.1.8/bin         \
    --BLAST_PATH=/path/blast/bin                    \
    --PYTHON3_PATH="/path/BRAKER_3.0.6/bin          \
    --CDBTOOLS_PATH="/path/cdbfasta                 \
    --TSEBRA_PATH="/path/TSEBRA-1.1.2/bin           \
    --AUGUSTUS_CONFIG_PATH="/path/BRAKER_3.0.6/config
