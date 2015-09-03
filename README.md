![witsgwas_banner2](https://cloud.githubusercontent.com/assets/8364031/9582190/13b1e182-5004-11e5-9336-8c030414e4bc.png)

## Background

witsGWAS is a simple human GWAS analysis workflow built at the [Sydney Brenner Institute](http://www.wits.ac.za/academic/research/sbimb/20747/wits_bioinformatics.html) for data quality control (QC) and basic association testing. It takes away the need for having to enter individual commands at the unix prompt and rather organizes GWAS tasks sequentially (facilitated via [Ruffus](http://www.ruffus.org.uk/)) for submission to a distributed PBS Torque cluster (managed via [Rubra](https://github.com/bjpop/rubra)).  witsGWAS monitors (using flag files) the progress of jobs/tasks submitted to the cluster on behalf of the user, courteously waiting for one job to finish before sending another one

## Documentation 

Installation, Examples and tutorials for witsGWAS can be accessed at the [witsGWAS_wiki](https://github.com/magosil86/witsGWAS/wiki)

## Features

**QC of Affymetrix array data** (SNP6 raw .CEL files)

  * genotype calling
  * converting birdseed calls to PLINK format

**Sample and SNP QC of PLINK Binaries**

Sample QC tasks checking:

 *  discordant sex information
 *  calculating missingness
 *  heterozygosity scores
 *  relatedness
 *  divergent ancestry 

SNP QC tasks checking:

 * minor allele frequencies
 * SNP missingness
 * differential missingness
 * Hardy Weinberg Equilibrium deviations

**Association testing**

 * Basic PLINK association tests, producing manhattan and qqplots
 * CMH association test - Association analysis, accounting for clusters
 * permutation testing
 * logistic regression

### Authors:

Lerato E. Magosi, Scott Hazelhurst and the WITS Bioinformatics team

### License
witsGWAS is offered under the MIT license. See LICENSE.txt.
