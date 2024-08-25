genome1=""
genome2=""
label=""
threads=4

# nucmer parameters
L=40
B=500
C=200
minSimilarity=80
minLength=200

# MUMmer tools
NUCMER=""
FILTER=""
SHOWCOORDS=""
FILTER=""
SHOWSNPS=""

# SyRI
SYRI=""

$NUCMER --maxmatch -l $L -b $B -c $C -p $label $genome1 $genome2 
$FILTER -m -i $minSimilarity -l $minLength $label.delta            > ${label}_m_i${minSimilarity}_l${minLength}.delta
$SHOWCOORDS -THrd ${label}_m_i${minSimilarity}_l${minLength}.delta > ${label}_m_i${minSimilarity}_l${minLength}.coords


### SyRI
$SYRI                   \
    -c $coords          \
    -r $genome1         \
    -q $genome2         \
    -d $delta           \
    --nc $threads       \
    -s SHOWSNPS
