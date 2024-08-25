hifiasmDir=""

threads=24
qScore=7
length=1000


hifi=""
HiC1=""
HiC2=""
ONT=""


### trim and filter ONT
conda activate NanoPack
zcat $ONT                                       \
    | NanoFilt --headcrop 200 --tailcrop 200    \
    | NanoFilt -l $length -q $qScore            \
    | gzip > $(basename $fastq .fastq.gz)~q${qScore}L${length}.fastq.gz
conda deactivate

ONT="$(basename $fastq .fastq.gz)~q${qScore}L${length}.fastq.gz"


### trim hic
conda activate trim_galore
trim_galore --output_dir ./trimmed $HiC1
trim_galore --output_dir ./trimmed $HiC2
conda deactivate

HiC1="trimmed/$(basename $HiC1 .fastq.gz).fq.gz"
HiC2="trimmed/$(basename $HiC2 .fastq.gz).fq.gz"


### asssemble
hifiasmDir/hifiasm  \
    -t $threads     \
    --ul $ONT       \
    --h1 $HiC1      \
    --h2 $HiC1      \
    $hifi
