# Build WitsGWAS pipeline as a Docker image 
#
# This script just builds a container with the dependancies which are needed
# to run the WitsGWAS pipeline.
#
# The configuration files for the specific pipeline can be modified in the host
# which runs the Docker container and loaded as a volume, as can the data which
# is needed for the processing. This design was chosen to keep the witsgwas
# Docker container small while still allowing the flexibility the pipeline
# provides.
#
# VERSION   : 1.0.0

# Use Ubuntu as the base image - this is probably the most user-friendly
FROM ubuntu:latest 
MAINTAINER Rob Clucas <robjclucas@gmailcom>

# Set properties of the image
LABEL Description = "Docker image for WitsGWAS image" \
                    Vendor="Bionet" Version="1.0.0"

# This defines the directory to while are the depedancy executables will be
# linked, creates it and then adds it to the path
ENV GWAS_ROOT /opt/bioinf/gwas
ENV GWAS_BIN  $GWAS_ROOT/bin
RUN mkdir -p $GWAS_BIN
ENV PATH=$GWAS_BIN:$PATH

# Define environment variables
ENV ADMIX_LINK    \
  https://www.genetics.ucla.edu/software/admixture/binaries/admixture_linux-1.3.0.tar.gz
ENV AFFYM_LINK    \
http://media.affymetrix.com/Download/updates/apt-1.18.0-x86_64-intel-linux.zip
ENV EIEGN_LINK    \
  https://github.com/DReichLab/EIG.git
ENV EMMAX_LINK    \
  http://csg.sph.umich.edu/kang/emmax/download/emmax-beta-07Mar2010.tar.gz
ENV PLINK_107_LINK \
  http://pngu.mgh.harvard.edu/~purcell/plink/dist/plink-1.07-x86_64.zip
ENV PLINK_LINK    \
  https://www.cog-genomics.org/static/bin/plink160315/plink_linux_x86_64.zip
ENV RUBRA_LINK    \
  https://github.com/bjpop/rubra.git 
ENV STOOL_LINK    \
  https://bootsrap.pypa.io/ez_setup.py
ENV WITS_GWAS_LINK \
  https://robclucas@bitbucket.org/robclucas/witsgwas.git

# Start by updating Ubuntu 
RUN apt-get update 

# Install all dependancies for WithGWAS
RUN apt-get install -y      \
  build-essential           \
  git                       \
  perl                      \
  python-pyudev             \
  python-pip                \
  python-pyfiglet           \
  figlet                    \
  r-base                    \
  wget                      

# Install setuptools for python
RUN wget $STOOL_LINK -O - | python

# Install Plaink 1.07 -- this is tricky because plink1.9 has the same name 
# so rather than creating a link we will just add the dir to the path and make 
# a link to plink 1.9 
RUN       mkdir -p /build/plink_1.07
WORKDIR   /build/plink_1.07
RUN       wget $PLINK_107_LINK
RUN       unzip *.zip
RUN       ln -sf /build/plink_1.07/plink-1.07-x86_64/plink /usr/bin/plink1

# Install Plink 1.9
RUN       mkdir -p /build/plink
WORKDIR   /build/plink
RUN       wget $PLINK_LINK
RUN       unzip plink_linux_x86_64.zip
RUN       ln -sf /build/plink/plink  $GWAS_BIN/plink

# Install admixture
RUN       mkdir /build/admixture
WORKDIR   /build/admixture
RUN       wget $ADMIX_LINK
RUN       tar -xvf admixture_linux-1.3.0.tar.gz
RUN       ln -sf /build/admixture/admixture_linux-1.3.0/admixture \
          $GWAS_BIN/admixture

# Install Emmax
RUN       mkdir /build/emmax
WORKDIR   /build/emmax
RUN       wget $EMMAX_LINK
RUN       tar -xvf emmax-beta-07Mar2010.tar.gz
RUN       ln -sf /build/emmax/emmax-beta-07Mar2010/emmax $GWAS_BIN/emmax

# Install Eiegensoft
RUN       mkdir /build/eiegensoft
WORKDIR   /build/eiegensoft
RUN       git clone $EIEGN_LINK 
RUN       ln -sf /build/eiegensoft/EIG/bin/eiegenstrat $GWAS_BIN/eiegenstrat

# Install Rubra (which installs Rufus)
RUN       mkdir /build/rubra
WORKDIR   /build/rubra
RUN       git clone $RUBRA_LINK 
WORKDIR   /build/rubra/rubra
RUN       python setup.py install

# Install Affymetrix power tools -- this link may need to be edited
RUN       mkdir /build/affymetrix
WORKDIR   /build/affymetrix
RUN       wget $AFFYM_LINK
RUN       unzip apt-1.18.0-x86_64-intel-linux.zip
RUN       mv /build/affymetrix/apt-1.18.0-x86_64-intel-linux  \
          /build/affymetrix/apt
RUN       cp /build/affymetrix/apt/bin/* $GWAS_BIN

# Get the wits gwas repository
RUN       mkdir /witsgwas
WORKDIR   /witsgwas
RUN       git clone $WITS_GWAS_LINK

# Go back to the root directory
WORKDIR   /
