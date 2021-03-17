#!/bin/bash

## Huge thanks to Tomas Gonzalez Zarzar for the tutorial & github repository
# Convert HGDP genotypes to plink format
# Adapted from https://github.com/tomszar/HGDP_1000G_Merge/blob/master/Code/HGDPtoPlink.sh
# Genotypes from HGDP are natively in transposed format compared to plink-native files
# 	- That is the columns are samples and rows are variants

# env vars
DATADIR=/Users/tmajaria/Documents/projects/biobanks/general_data/reference/hgdp/
plink=/Users/tmajaria/Documents/src/plink/plink_mac_20190617/plink

# Go to data directory
cd $DATADIR

# Use these if working on Linux system
dos2unix HGDP_FinalReport_Forward.txt
dos2unix HGDP_Map.txt
dos2unix HGDP_SampleInformation.txt

# interim for tfam, list of sample IDs
head -1 HGDP_FinalReport_Forward.txt > HGDP_header.txt

# Add samples to tfam file with no sex info
awk '{for (i=1;i<=NF;i++) print "0",$i,"0","0"}' HGDP_header.txt > hgdp_nosex.tfam

# add genotypes to what will become ped file (unsorted)
sed '1d' HGDP_FinalReport_Forward.txt > HGDP_Data_NoHeader.txt

# sort genotypes by rsid
sort -k 1b,1 HGDP_Data_NoHeader.txt > HGDP_Data_Sorted.txt

# sort map file in same way (by rsid)
sort -k 1b,1 HGDP_Map.txt > HGDP_Map_Sorted.txt

# add variant info to genotype data
join -j 1 HGDP_Map_Sorted.txt HGDP_Data_Sorted.txt > HGDP_compound.txt
 
# convert plain text genotype & variant data to plink tped format
awk '{if ($2=="M") $2="MT";printf("%s %s 0 %s ",$2,$1,$3);
    for (i=4;i<=NF;i++)
        printf("%s %s ",substr($i,1,1),substr($i,2,1));
    printf("\n")}' HGDP_compound.txt > hgdp.tped
 
# add sex info
sed '1d' HGDP_SampleInformation.txt > temp.txt
sed '$d' temp.txt > SampleInfo_noheader.txt
awk '{printf("HGDP%05d ",$1);
    if ($6=="m") print "1";
    else if ($6=="f") print "2";
    else print "0";}' SampleInfo_noheader.txt > Sample_sex.txt
awk 'BEGIN {
	while ((getline < "Sample_sex.txt") > 0)
		f2array[$1] = $2}
	{if (f2array[$2])
		print $1, $2, $3, $4, f2array[$2], "0"
	else
		print $2 "not listed in file2" > "unmatched"
	}' hgdp_nosex.tfam > hgdp.tfam
 
# convert to binary
$plink --tfile hgdp --out hgdp --make-bed --missing-genotype - --output-missing-genotype 0
 
#convert back to ped to liftover
$plink --bfile hgdp --recode --out hgdp

#Removing big files except originals
rm HGDP_compound.txt HGDP_Data_NoHeader.txt HGDP_Data_Sorted.txt hgdp.tfam hgdp.tped hgdp.bim hgdp.bed hgdp.fam

## Liftover HGDP from hg18 to hg19
python3 /Users/tmajaria/Documents/projects/biobanks/mgb/code/ukbb_pan_ancestry/liftOverPlink.py \
	-m hgdp.map \
	-o lifted \
	-c /Users/tmajaria/Documents/projects/general_data/reference/hg18ToHg19.over.chain.gz \
	-e /Users/tmajaria/Documents/src/liftOver

# Find variants for which liftover failed
python3 /Users/tmajaria/Documents/projects/biobanks/mgb/code/ukbb_pan_ancestry/rmBadLifts.py \
	--map lifted.map \
	--out good_lifted.map \
	--log bad_lifted.dat

# Get failed variants in correct format
awk '{print $2}' good_lifted.map | tail -n +1 -q > snplist.txt

# Remove failed variants from lifted over dataset and conver to plink binary
# This should result in 1043 individuals with 644117
$plink --file hgdp --recode --out lifted --extract snplist.txt
$plink --file --ped lifted.ped --map good_lifted.map --make-bed --out hgdp_hg19
