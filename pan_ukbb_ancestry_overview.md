# Pan UK ancestry: Assigning individuals to ancestry/population groups in UKBB

## Summary
Reference panels:
	- 1000 Genomes Project [https://www.internationalgenome.org/]
	- Human Genome Diversity Project (HGDP) [https://www.hagsc.org/hgdp/]

Ancestry groups:
	- [AFR] African
	- [AMR] American (which in these studies is the ancestry shared by many Hispanic/Latino groups) (admixed american ancestry)
	- [CSA] Central/South Asian 
	- [EAS] East Asian
	- [EUR] European 
	- [MID] Middle Eastern

Assignment:
	- assigned each individual into the ancestry groups that he/she was most similar to
	- dropped those individuals who did not have a confident ancestry assignment
	- **does not rely on any other information, including self-reported race, ethnicity, or ancestry**
	- conducted our studies in all of the populations that had large enough numbers of individuals to learn about the genetic underpinnings of some traits, with individuals from each population analyzed together.

## Ancestry assignment methods

### Overview
combined reference data from the 1000 Genomes Project and Human Genome Diversity Panel (HGDP)
combined these reference datasets into continental ancestries according to their corresponding meta-data

Continent 									 | AFR  |  AMR |  CSA  |  EAS |   EUR  |  MID | OCE | other
-------------------------------------------- | ---- | ---- | ----- | ---- | ------ | ---- | --- | -----
Count     								     | 9226 | 1152 | 11124 | 2918 | 459874 | 1667 |  2  | 2414
Unrel                                        | 8576 | 1144 | 10200 | 2832 |        | 1611 |     | 
Outliers removed (total)                     | 6806 | 998  | 9109  | 2783 | 426936 | 1624 |     | 
Outliers removed (unrelated)                 | 6259 | 991  | 8286  | 2701 | 362558 | 1568 |     | 
Outliers removed (related, kin pairs > 0.05) | 547  | 7    | 823   | 82   | 64378  | 56   |     | 

1. Assign continental ancestries.
2. Prune ancestry outliers within continental groups.

### PCA

1. PCA on unrelated individuals from the 1000 Genomes + HGDP combined reference dataset
2. Used the PC loadings from the reference dataset to project UK Biobank individuals into the same PC space
3. Trained a random forest classifier given continental ancestry meta-data based on top 6 PCs from the reference training data.
4. Applied this random forest to the projected UK Biobank PCA data and assigned initial ancestries that were subsequently refined if the random forest probability was >50%.
	- **individuals with a probability < 50% for any given ancestry group were dropped from further analysis**
5. Refined initial ancestry assignments by pruning outliers within each continental assignment
	- reran PCA among UK Biobank individuals within each assigned continental ancestry group (i.e. excluding reference panel data)
	- calculated the total distance from population centroids across 10 PCs
	- Using the PC scores, we computed centroid distances across 3-5 centroids spanning these PCs depending on the degree of heterogeneity within each continental ancestry
	- For each individual and for each ellipse across 10 PCs, subtract the population PC mean from the individual's PC, square this value, and divide by the variance of the PC.
	- identified ancestry outliers based by plotting histograms of centroid distances and removing those individuals from the extreme high end of the distribution.

### Code

https://github.com/atgu/ukbb_pan_ancestry/blob/master/super_pop_pca.py
Inputs:
	- reference dataset in plink format (bim/bed/fam)
	- genetic data in hail format (matrix table)
	- sample annotations for genetic data if not present in hail mt

Steps:
	1. Load reference data
		- in: bim/bed/fam
		- out: hail MT
	2. Load genetic data
		- in: hail MT, sample annotations
		- out: hail MT
	3. Intersect reference data with genetic data
		- filter to variants within both datasets
		- in: ref MT, UKBB MT
		- out: ref MT, UKBB MT filtered to shared variants
	4. Compute PCA in reference data
		- in: ref MT (shared var)
		- out: PC loadings
	5. Project UKBB individuals into PCA space
		- in: PC loadings, UKBB MT (shared var)
		- out: PC scores for UKBB indiv.
	6. Compute PCA in each UKBB population (unrelateds), Project reference individuals and relateds into PCA space
		1. Filter UKBB to individuals in continental population
        2. Run PC-relate on these individuals
        2.5 Filter to pruned set of individuals
        3. Filter UKBB population to unrelated individuals
        4. Run PCA on UKBB unrelateds within population
        5. Project relateds

https://github.com/atgu/ukbb_pan_ancestry/blob/master/assign_pops.py

















