# Metagenomics torrent 🚧 (UNDER DEVELOPMENT) 🚧


Author: Joaquín Tamargo Azpilicueta (joatamazp@alum.us.es)

Metagenomics torrent is a straight-forward QIIME pipeline for 16S metabarcoding analysis sequenced from Ion Torrent platform. Note that this pipeline has been developed by an amateur contributor that may have not taken into account all vicissitudes that can come up. Rather, this pipeline was designed in order to easily process fastq files obtained from an Ion Torrent sequencing platform. 

1. [Dependencies](#dependencies)
2. [Installation and setting up the working environment](#setup)
3. [How does it work?](#how)

## Dependencies

**Requirements:** 

<a name="dependencies"></a>

* This pipeline is only available in Linux and Mac OS. If you are working on a Windows machine, you will need a virtual machine such as Virtual box (see how to proceed at https://www.virtualbox.org/). Then you may install Ubuntu in it (https://ubuntu.com/download/desktop). There are plenty of tutorials in YouTube that may come in handy while installing both. 

* Data processing is heavy and so are the packages used for that purpose. Thus, at least 15 GB of free space are required in order to have plenty of space to work with.

* CONDA must be installed. You can find how to at https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html

**Needed applications:**

There is a script that can make things easy for the installation of the required packages: 'dependencies-installation.sh'. Just get into *metagenomics-torrent*  installation directory and type in 'bash scripts/dependencies-installation.sh <Linux/Mac>' and it will:

* Install and create a QIIME2 environment acordingly to the operative system you have.

* Install **FastQC**, **MultiQC**, **Cutadapt** and **BBMap**. There is online documentation available for each of these packages. Note that these packages might be not up-to-date. Please, manually check if versions of these packages are obsolete.

## Installation and setting up the working environment

<a name="setup"></a>

Installation of the script itself is not neccesary.

Before going through how to work with metagenomics-torrent, let me tell you this pipeline is novice-friendly. Trust me, I'm a novice. 

1. You must create a file wherever you need the results to be. Let's imagine you have different rock samples, and you would like to have the file at the Desktop. You must then open a terminal and go to Desktop. Once there, create a file named, for example, "rocks_analysis".
2. In that file, create two files: one named "sample_info" and other named "results". In "sample_info", create a file named "sequences"
3. Copy your fastq (or fastq.gz) samples into "sequences" file (rock_analysis/sample_info/sequences/).
4. Copy the metadata.txt at "sample_info" file (please do check it is spelt exactly like that). Change it acordingly to your samples.
5. Copy the parameter_file.txt in "rocks_analysis". That parameter file stores the location of the sequences, the metadata.txt location and the directory where you want your results to be (in our example: rock_analysis/results). Check the location and copy it behind the corresponding parameter. **IMPORTANT:** let a space between the colons and the directory.
6. Go to the file where you have cloned metagenomics-torrent. In the scripts file, you can find a script to install all the packages needed (dependencies-installation.sh). The other script, *'sequences-processing.sh'*, is the pipeline file.
7. If you haven't done this before, install all packages by writing "bash dependencies-installation.sh <(Mac/Linux)> (do not include < > symbols).
8. Write 'bash sequences-processing.sh path/to/parameter/files"
9. It will for sure take a while. Coffee time! ☕️

## How does it work?

<a name="how"></a>
