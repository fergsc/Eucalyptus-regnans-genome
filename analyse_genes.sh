genesDir=""
taxScope="Viridiplantae"
threads=12

# temp directories - put them somewhere fast.
scratch=""
temp=""


### Ortho group genes
conda activate orthofinder
orthofinder -a $((threads/2)) -t $threads -f $genesDir -M msa
conda deactivate

### EggNog - Annotarte geens for KEGG, COG, GO, etc
conda activate eggnog

for faa in $genesDir/faa
do
    emapper.py                   \
        -m diamond               \
        -i $faa                  \
        --itype CDS              \
        --cpu $threads           \
        --tax_scope $taxScope    \
        -o $(basename $faa .faa) \
        --scratch_dir $scratch   \
        --temp_dir $temp
done
conda deactivate
