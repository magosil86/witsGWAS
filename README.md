![witsgwas_banner2](https://cloud.githubusercontent.com/assets/8364031/9582190/13b1e182-5004-11e5-9336-8c030414e4bc.png)

## Background

witsGWAS is a simple human GWAS analysis workflow built at the [Sydney Brenner Institute](http://www.wits.ac.za/academic/research/sbimb/20747/wits_bioinformatics.html) for data quality control (QC) and basic association testing. It takes away the need for having to enter individual commands at the unix prompt and rather organizes GWAS tasks sequentially (facilitated via [nextflow](http://www.nextflow.io/) for submission to a distributed PBS Torque cluster.

We are currently developing this pipeline -- previous versions used Ruffus and Rubra. The original version is still available. The new version is not yet complete.

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
 * emmax association testing

### Dockerized Pipeline

The pipeline has been 'dockerized', simplifying its use. See the
Dockerized section on the [WitsGWAS
Wiki](https://github.com/magosil86/witsGWAS/wiki) for more
information.


Temporary instructions

0. Install nextflow

    wget -qO- get.nextflow.io | bash

   This creates a nextlow executable. Copy it somewhere on your PATH, e.g.

    sudo mv nextflow /usr/local/bin




1. Get the scripts

```
    git clone https://github.com/magosil86/witsGWAS.git
    cd witsGWAS
    git checkout -b Release2Devel
    git branch --set-upstream-to=origin/Release2Devel Release2Devel
    git pull
```
   

2. Download the sample data files from

   https://drive.google.com/open?id=0B21RXx6fpsgPaW1UTjdibGpaZVk

   The default place for it to go is dockerized/gwasdata/plink/

   But you can put them somewhere else and edit the gwas.nf


3. To run the pipeline without Docker:

   Put the scripts in witsGWAS on your path

   Either copy the scripts to something like /usr/local/bin or use a hammer

```
    echo export PATH=`pwd`/scripts:${PATH} >> ~/.bashrc
    source ~/.bashrc
```

   The following dependancies must be met


   * All the scripts mentioned above must be on the path
   * R  (Rscript)
   * plink (version 1.9)
   * all for the moment

```
    wget https://www.cog-genomics.org/static/bin/plink160516/plink_linux_x86_64.zip
    unzip plink_linux_x86_64.zip 
    sudo mv plink /usr/local/bin
    /bin/rm -r toy* LICENSE plink_linux_x86_64.zip 
```

4. To run without Docker


    nextflow run gwas.nf


5. To run with Docker

   * Get the image

    docker pull shazeza/h3agwas

6. To run with PBS and/or Docker -- see the config directory for examples

This is such a big image because R is used for pictures and R is very big.
We should reimplement with gnuplot which is about 10% the size

   * Run it


    * nextflow run gwas.nf -with-docker shazeza/h3agwas





Using nextflow, the pipeline can be run in several ways, reasonably transparently. 

  * natively on a computer that has nextflow and required dependancies installed. 
  * through a job submission system like PBS. The nextflow script runs on the head node, and nextflow submits the individual jobs for you (submitting multiple jobs in parallel where appropriate).
  * using Docker
  * through a job submission system like PBS, with Docker containers on the worker nodes.


### Authors

Lerato E. Magosi, Scott Hazelhurst, Rob Clucas and the WITS Bioinformatics team

### License
witsGWAS is offered under the MIT license. See LICENSE.txt.

### Download
[witsGWAS-0.3.a](https://github.com/magosil86/witsGWAS/releases)

### References
Anderson, C. et al. Data quality control in genetic case-control association studies. Nature Protocols. 5, 1564-1573, 2010

Sloggett, Clare; Wakefield, Matthew; Philip, Gayle; Pope, Bernard (2014): 
Rubra - flexible distributed pipelines. figshare. http://dx.doi.org/10.6084/m9.figshare.895626
