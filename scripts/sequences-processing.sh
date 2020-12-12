################################################################
##                                                            ##
##                   METAGENOMICS TORRENT                     ##
##                                                            ##
## Author: Joaquín Tamargo Azpilicueta (joatamazp@alum.us.es) ##
##                      December, 2020                        ##
##                                                            ##
################################################################

echo ""
echo "Welcome to metagenomics-torrent sequence proccesing, a straight-forward pipeline for Ion Torrent 16S sequencing metabarcoding analysis."
echo ""

echo "======================" 
echo "| Reading parameters |"
echo "======================"
echo ""

PARAMS=$1

SAMDIR=$(grep samples_directory $PARAMS | awk '{ print $2 }')
echo "Sample directory is: ${SAMDIR}"

RESDIR=$(grep results_directory $PARAMS | awk '{ print $2 }')
echo "Results will be stored at: ${RESDIR}"

METADATADIR=$(grep metadata_directory $PARAMS | awk '{ print $2 }')
echo "Metadata file (double check that it is written as metadata.txt) is stored at ${METADATADIR}"

echo ""
echo "===============================" 
echo "| Quality control & filtering |"
echo "==============================="
echo ""

cd ${RESDIR}
mkdir fastqc_report

cd ${SAMDIR}
fastqc * -o $RESDIR/fastqc_report -t 8

multiqc $RESDIR/fastqc_report/*.zip -o $RESDIR/fastqc_report

echo ""
echo "Quality control done. Check results at ${RESDIR}."
echo ""


echo ""
echo "===================================" 
echo "| Importing Ion Torrent sequences |"
echo "==================================="
echo ""
echo "Samples (located at ${SAMDIR}) are being imported to ${RESDIR} as artifacts (.qza)." 
echo ""

cd ${RESDIR}
mkdir Demux

qiime tools import \
--type 'SampleData[SequencesWithQuality]' \
--input-path ${METADATADIR}/se-33-manifest \
--input-format SingleEndFastqManifestPhred33V2 \
--output-path ${RESDIR}/Demux/single_end_demux.qza

qiime demux summarize \
  --i-data ${RESDIR}/Demux/single_end_demux.qza \
  --o-visualization ${RESDIR}/Demux/single_end_demux.qzv
  
echo "A visualization of the generated quality control is opening."

qiime tools view  ${RESDIR}/Demux/single_end_demux.qzv

echo ""
echo "==================" 
echo "| Denoising data |"
echo "=================="
echo ""

cd ${RESDIR}
mkdir Denoised

## Denoising

echo "Denoising is taking place. This may take a while..."
echo ""

qiime dada2 denoise-single \
  --i-demultiplexed-seqs ${RESDIR}/Demux/single_end_demux.qza \
  --p-trunc-len 250 \
  --o-representative-sequences ${RESDIR}/Denoised/rep-seqs-dada2.qza \
  --o-table ${RESDIR}/Denoised/table-dada2.qza \
  --o-denoising-stats ${RESDIR}/Denoised/denoising-stats.qza \
  --p-max-ee 2 \
  --p-trunc-q  2 \
  --verbose
 
## Feature table and summary 
 
 echo ""
 echo "Feature table and summary are being generated"
 echo ""
 
qiime feature-table summarize \
  --i-table ${RESDIR}/Denoised/table-dada2.qza \
  --o-visualization ${RESDIR}/Denoised/table.qzv \
  --m-sample-metadata-file ${METADATADIR}/metadata.txt

qiime feature-table tabulate-seqs \
  --i-data ${RESDIR}/Denoised/rep-seqs-dada2.qza \
  --o-visualization  ${RESDIR}/Denoised/table.qzv
  
echo ""
echo "======================" 
echo "| Diversity analysis |"
echo "======================"
echo ""
echo "Phylogenetic diversity is being calculated."
echo ""
cd ${RESDIR}
mkdir Phylogenetic-diversity

qiime alignment mafft \
  --i-sequences ${RESDIR}/Denoised/rep-seqs-dada2.qza \
  --o-alignment ${RESDIR}/Phylogenetic-diversity/aligned-rep-seqs.qza

qiime alignment mask \
  --i-alignment ${RESDIR}/Phylogenetic-diversity/aligned-rep-seqs.qza \
  --o-masked-alignment ${RESDIR}/Phylogenetic-diversity/masked-aligned-rep-seqs.qza

qiime phylogeny fasttree \
  --i-alignment ${RESDIR}/Phylogenetic-diversity/masked-aligned-rep-seqs.qza \
  --o-tree ${RESDIR}/Phylogenetic-diversity/unrooted-tree.qza

qiime phylogeny midpoint-root \
  --i-tree ${RESDIR}/Phylogenetic-diversity/unrooted-tree.qza \
  --o-rooted-tree ${RESDIR}/Phylogenetic-diversity/rooted-tree.qza

echo -e "\e[5m================================================="
echo -e "\e[1m| Alpha and beta diversity are being calculated. |"
echo -e "\e[5m=================================================\e[25m"
echo ""

## Alpha beta diversity

working_dir=Alpha-Beta-diversity
input_dir=Phylogenetic-diversity
input_dir_table=Denoised-paired

echo "metadata.txt is at ${METADATADIR} and it contains important pieces of information about the samples"
echo ""

cd ${RESDIR}
mkdir Alpha-Beta-diversity

qiime diversity core-metrics-phylogenetic \
  --i-phylogeny ${RESDIR}/Phylogenetic-diversity/rooted-tree.qza \
  --i-table ${RESDIR}/Denoised/table-dada2.qza \
  --p-sampling-depth 500 \
  --m-metadata-file ${METADATADIR}/metadata.txt \
  --output-dir ${RESDIR}/Alpha-Beta-diversity/core-metrics-results

## Alpha group significance 


echo ""
echo -e "\e[1mAlpha diversity is being calculated."
echo ""

qiime diversity alpha-group-significance \
  --i-alpha-diversity ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file ${METADATADIR}/metadata.txt \
  --o-visualization ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity ${RESDIR}/Alpha-Beta-diversity/evenness_vector.qza \
  --m-metadata-file ${METADATADIR}/metadata.txt \
  --o-visualization ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/evenness-group-significance.qzv

## Beta group significance 

echo ""
echo -e "\e[1mBeta diversity is being calculated."
echo ""

qiime diversity beta-group-significance \
  --i-distance-matrix ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file ${METADATADIR}/metadata.txt \
  --m-metadata-column Description \
  --o-visualization ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/unweighted-unifrac-description-significance.qzv \
  --p-pairwise
  
## Alpha rarefaction analysis 

echo ""
echo "======================" 
echo "| Alpha rarefaction  |"
echo "======================"
echo ""

cd ${RESDIR}
mkdir Alpha-rarefaction

qiime diversity alpha-rarefaction \
  --i-table ${RESDIR}/Denoised/table-dada2.qza \
  --i-phylogeny ${RESDIR}/Phylogenetic-diversity/rooted-tree.qza \
  --p-max-depth 500 \
  --m-metadata-file ${METADATADIR}/metadata.txt \
  --o-visualization ${RESDIR}/Alpha-rarefaction/alpha-rarefaction.qzv

echo "Alpha rarefaction visualization is opening in a new window."

qiime tools view  ${RESDIR}/Alpha-rarefaction/alpha-rarefaction.qzv

echo ""
echo "======================" 
echo "| TAXONOMY ANALYSIS  |"
echo "======================"
echo ""

echo "SILVA 16S database was chosen for the analysis, as it is an up-to-date (SILVA v.138, the newest version on 3rd or December, 2020), reliable open source database recommended by many microbiologist experts. The file that is going to be used for the alignment is stored at the Results directory that you have provided in the parameters file (${RESDIR})"
echo ""

echo "SILVA trained on Naive-Bayes distribution is being downloaded from QIIME resources database."
echo ""
echo -e "\a Naive Bayes classifier trained on ${bold}SILVA 138 99%${normal} from 515F/806R region of sequences"
echo ""

cd ${RESDIR}
mkdir SILVA-classifier 
wget -O ./SILVA-classifier/classifier.qza "https://data.qiime2.org/2020.8/common/silva-138-99-515-806-nb-classifier.qza"

cd ${RESDIR}
mkdir Taxonomic-analysis

qiime feature-classifier classify-sklearn \
  --i-classifier ${RESDIR}/SILVA-classifier/classifier.qza \
  --i-reads  ${RESDIR}/Denoised/rep-seqs-dada2.qza \
  --o-classification ${RESDIR}/Taxonomic-analysis/taxonomy.qza \
  --verbose

echo ""
echo "Classification of the reads by taxon using SILVA classifier has finished. Visualisation is on the way!"
echo ""

qiime metadata tabulate \
  --m-input-file ${RESDIR}/Taxonomic-analysis/taxonomy.qza \
  --o-visualization ${RESDIR}/Taxonomic-analysis/taxonomy.qzv

qiime taxa barplot \
  --i-table  ${RESDIR}/Denoised/table-dada2.qza \
  --i-taxonomy ${RESDIR}/Taxonomic-analysis/taxonomy.qza \
  --m-metadata-file ${METADATADIR}/metadata.txt \
  --o-visualization ${RESDIR}/Taxonomic-analysis/taxa-bar-plots.qzv
  
echo ""
echo "Analysis finished!"
