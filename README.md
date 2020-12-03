# Metagenomics torrent 🚧 (UNDER DEVELOPMENT) 🚧


Author: Joaquín Tamargo Azpilicueta (joatamazp@alum.us.es)

Metagenomics torrent is a straight-forward QIIME pipeline for 16S metabarcoding analysis sequenced from Ion Torrent platform. Note that this pipeline has been developed by an amateur contributor that may have not taken into account all vicissitudes that can come up. Rather, this pipeline was designed in order to easily process fastq files obtained from an Ion Torrent sequencing platform. 

## Dependencies

**Requirements:** 

* This pipeline is only available in Linux and Mac OS. If you are working on a Windows machine, you will need a virtual machine such as Virtual box (see how to proceed at https://www.virtualbox.org/). Then you may install Ubuntu in it (https://ubuntu.com/download/desktop). There are plenty of tutorials in YouTube that may come in handy while installing both. 

* Data processing is heavy and so are the packages used for that purpose. Thus, at least 15 GB of free space are required in order to have plenty of space to work with.

* CONDA must be installed. You can find how to at https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html

**Needed applications:**

There is a script that can make things easy for the installation of the required packages: 'dependencies-installation.sh'. Just get into *metagenomics-torrent*  installation directory and type in 'bash scripts/dependencies-installation.sh <Linux/Mac>' and it will:

* Install and create a QIIME2 environment acordingly to the operative system you have.

* Install **FastQC**, **MultiQC**, **Cutadapt** and **BBMap**. There is online documentation available for each of these packages. Note that these packages might be not up-to-date. Please, manually check if versions of these packages are obsolete.

##
