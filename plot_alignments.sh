# first create files containing seqName \t seqLength
bioawk -c fastx -v OFS="\t" '{print $name, length($seq)}' hap1.fasta > hap1.genome
bioawk -c fastx -v OFS="\t" '{print $name, length($seq)}' hap2.fasta > hap2.genome

# now plot
plotsr                      \
    --sr syri.out           \
    --genomes genomes.txt   \
    -o hap1-hap2_plot.png
