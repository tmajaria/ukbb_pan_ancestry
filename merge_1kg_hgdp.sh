#!/bin/bash
KGDIR=/Users/tmajaria/Documents/projects/general_data/reference/

docker run --rm -ti -v=$KGDIR:/mnt/data/ tmajarian/bcf_vcf_tools:0.1 /bin/bash

## Combine 1KG and HGDP using plink
# 1KG: ftp://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/
# http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr21.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz
# http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/release/20130502/ALL.chr21.phase3_shapeit2_mvncall_integrated_v5a.20130502.genotypes.vcf.gz.tbi

# HGDP: ftp://ngs.sanger.ac.uk/production/hgdp/hgdp_wgs.20190516/
# ftp://ngs.sanger.ac.uk/production/hgdp/hgdp_wgs.20190516/hgdp_wgs.20190516.full.chr21.vcf.gz
# ftp://ngs.sanger.ac.uk/production/hgdp/hgdp_wgs.20190516/hgdp_wgs.20190516.full.chr21.vcf.gz.tbi

# Step 1 - First merge: plink --file fA --merge-list allfiles.txt --make-bed --out mynewdata

# Step 2 - Flip SNPs: plink --file fA --flip mynewdata.missnp --make-bed --out mynewdata2

# Step 3 - New merge: plink --bfile mynewdata2 --merge-list allfiles.txt --make-bed --out mynewdata3

cd /mnt/data/1kg

#Extracting snps found in the HGDP to the 1000G files
# this ?works?: "After filtering, kept 9621 out of a possible 1105538 Sites"
kg_vcfs=`ls *.genotypes.vcf.gz`
for vi in "${kg_vcfs[@]}"
do 
ovi=${vi%.*.*}
# vcftools --gzvcf $vi --snps /mnt/data/hgdp/snplist.txt --recode --out ${ovi}_extracted
vcftools --gzvcf $vi --positions /mnt/data/hgdp/snppos.txt --recode --out ${ovi}_extracted
done

# combine into single vcf
bcftools concat -o 1000g.vcf.gz -Oz *.recode.vcf

# convert to plink
plink --vcf 1000g.vcf.gz --make-bed --out 1000G_hg19

#Updating fam file
allfam = pd.read_csv("integrated_call_samples_v2.20130502.ALL.ped", header = None, skiprows = 1, sep = "\t")
oldfam = pd.read_csv("1000Ghg19.fam", header = None, sep = " ")
updatedfam = pd.merge(oldfam, allfam, how = "inner", left_on = 1, right_on = 1)
updatedfam.iloc[:,[6,1,7,8,9,5]].to_csv("1000Ghg19.fam", sep = " ", header = False, index = False)
os.remove("1000g.vcf.gz")