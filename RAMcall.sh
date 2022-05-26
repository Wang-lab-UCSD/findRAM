#!/bin/bash

#Contact: Lina Zheng <liz227@ucsd.edu>

#Package dependency:
#Python3.8.12 with conda setup, the miniconda3 could be easily download from https://docs.conda.io/en/latest/miniconda.html

CMD=`echo $0 | sed -e 's/^.*\///'`
echo $CMD
DESCR="Description: Run findRAM to identify the modular patterns of 3D genome from histone modifications."
echo $DESCR

USAGE="USAGE:
	$CMD -I <input(.narrowpeaks bed)> -O <output dir> -P <findRAM path> -C <conda installed path> -g <genome> [-s <spanvalue> -d <minPeak> -m <marginalerror>]"

OPTIONS="OPTIONS:
	-I input histone marks narrow peaks file (absolute path)
	-O output directory (absolute path)
	-P directory where findRAM package located (absolute path)
	-C directory where conda installed (absolute path, eg: /.local/share/miniconda3/)
	-g genome version, choose from hg19, hg38, mm10
	-s span value, choose from 0.025, 0.05, 0.1. Optional. Default=0.025.
	-d minimum height for a captured peak, choose from 0-1. Optional. Default=0.1.
	-m marginal error to add to each side of boundary, choose from 0,1,2,3. Optional.Default=0 "

if [ "$1" = "--help" ]; then
	echo -e "$DESCR\n\n$USAGE\n$OPTIONS" >&1
	exit 0
fi

while getopts "I:O:P:C:g:sdm" opt
do
	case $opt in 
		I) input=$OPTARG;;
		O) wkdir=$OPTARG;;
		P) sourcedir=$OPTARG;;
		C) condadir=$OPTARG;;
		g) genome=$OPTARG;;
		s) span=$OPTARG;;
		d) depth=$OPTARG;;
		m) marginerror=$OPTARG;;
	esac
done

span=${span:-0.025}
depth=${depth:-0.1}
marginerror=${marginerror:-0}

###output your processing options
echo "Input file is: "$input
echo "Output directory is: "$wkdir
echo "findRAM path is: "$sourcedir
echo "Conda installed path is: "$condadir
echo "Genome version is: "$genome
echo "span value: "$span
echo "minPeak height: "$depth
echo "MarginalError: "$marginerror


###preliminary check
if [[ -f "$input" && -s "$input" ]];then
	echo "input data is ready to process"
else
	echo -e "Input data is missing, please check" >&2
	exit 1
fi

if [ -d "$wkdir" ];then
	echo "output directory is ready"
else
	mkdir $wkdir
fi



###step0. check conda environment
source $condadir/etc/profile.d/conda.sh
source activate $sourcedir/findRAM.env/

###step1. calculated density
echo "Start to calculate the peaks density profile!"

if [[ "$genome" == "hg19" || "$genome" == "hg38" ]]; then
	bash $sourcedir/scripts/human.density.sh $input $wkdir $sourcedir/sliding.window/sliding.window.res.250kb.flanking.500kb.files.`basename $genome` $sourcedir/scripts/
else
	bash $sourcedir/scripts/mouse.density.sh $input $wkdir $sourcedir/sliding.window/sliding.window.res.250kb.flanking.500kb.files.`basename $genome` $sourcedir/scripts/

fi


###step2. Modules identification
echo "Start to identify Modules"

if [[ "$genome" == "hg19" || "$genome" == "hg38" ]]; then
	bash $sourcedir/scripts/human.module.sh $wkdir/density/ $wkdir $sourcedir/scripts/ $span $depth $marginerror $sourcedir/chromo.size/`basename $genome`.chrom.sizes.txt
else
	bash $sourcedir/scripts/mouse.module.sh $wkdir/density/ $wkdir $sourcedir/scripts/ $span $depth $marginerror $sourcedir/chromo.size/`basename $genome`.chrom.sizes.txt

fi

echo "RAM modules have been completed!"


conda deactivate
