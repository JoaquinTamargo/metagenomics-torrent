## Help message 

if  [ "$#" -ne 1 ];
then
	echo "USAGE: dependencies-installation.sh <OS>"
	echo ""
	echo "OS   -- Operative System. Linux or Mac are the only parameters allowed."
	echo ""
	echo "ERROR: In order to install the dependencies, you must specify whether your Operative System (OS) is Linux or Mac. No further installation have taken place"
	echo ""
	exit 1
fi

## Reading parameters and remembering the need of Conda environment setup.

OS=$1

echo ""
echo -e "\033[1mInstallation in progress for ${OS} OS.\033[0m"
echo "REMEMBER: CONDA MUST BE INSTALLED. If not, check: https://docs.conda.io/projects/conda/en/latest/user-guide/install/index.html"
echo ""

## Installation process

## QIIME2 (2020.8) INSTALLATION AND ENVIRONMENT CREATION

if [ ${OS} == Mac ]
then

	conda update conda
	conda install wget
	wget https://data.qiime2.org/distro/core/qiime2-2020.8-py36-osx-conda.yml
	conda env create -n qiime2-2020.8 --file qiime2-2020.8-py36-osx-conda.yml
	
	# OPTIONAL CLEANUP
	rm qiime2-2020.8-py36-osx-conda.yml

	
	brew install fastqc

elif [ ${OS} == "Linux" ]
then 
	conda update conda
	conda install wget
	wget https://data.qiime2.org/distro/core/qiime2-2020.8-py36-linux-conda.yml
	conda env create -n qiime2-2020.8 --file qiime2-2020.8-py36-linux-conda.yml
	
	# OPTIONAL CLEANUP
	rm qiime2-2020.8-py36-linux-conda.yml
	
	sudo apt-get update -y
	sudo apt-get install fastqc
else
	echo "No valid OS. Please check that you have written Linux or Mac."
	exit 1
fi

## Activating QIIME2 environment

source activate qiime2-2020.8

## FASTQC installation

if [ ${OS} == "Mac" ]
then
	echo ""
	echo "Checking whether Brew is already installed. If not, it will be installed"
	echo ""

	which brew > brewcheck
	WCOUNT=$(wc -w brewcheck | awk '{print $1}')
	rm -r brewcheck
	
	if [$WCOUNT -eq 0]
	then
		echo "Brew is not installed. Proceeding with installation."
		/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	else
		echo "Brew is already installed!"
	fi
	
	brew install fastqc

elif [ ${OS} == "Linux" ]
then 
	conda update conda
	conda install wget
	wget https://data.qiime2.org/distro/core/qiime2-2020.8-py36-linux-conda.yml
	conda env create -n qiime2-2020.8 --file qiime2-2020.8-py36-linux-conda.yml
	
	# OPTIONAL CLEANUP
	rm qiime2-2020.8-py36-linux-conda.yml
	
	sudo apt-get update -y
	sudo apt-get install fastqc
fi	

## MultiQC (summarise fastqc reports) and Cutadapt (find and removes
## adapter sequences used in high-throughput sequencing) installation

pip install multiqc

pip install cutadapt

## Installing BBMap (v. 38.87). BBMap is a short read aligner, and
## contains other bioinformatic tools.

mkdir software
wget https://sourceforge.net/projects/bbmap/files/BBMap_38.87.tar.gz/download -O software/BBMap_38.87.tar.gz
tar -xvf software/BBMap_38.87.tar.gz -C software
rm software/BBMap_38.87.tar.gz 
