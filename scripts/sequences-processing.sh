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

SAMDIR=$(grep samples_directory: test_parameters.txt | awk '{ print $2 }')
echo "Sample directory is: ${SAMDIR}"

RESDIR=$(grep results_directory: test_parameters.txt | awk '{ print $2 }')
echo "Results will be stored at: ${RESDIR}"

METADATADIR=$(grep metadata_directory: test_parameters.txt | awk '{ print $2 }')
echo "Metadata file (double check that it is written as metadata.txt) is stored at ${METADATADIR}"

echo ""
echo "===============================" 
echo "| Quality control & filtering |"
echo "==============================="
echo ""

cd ${RESDIR}
mkdir fastqc_Report


cd ${SAMDIR}
fastqc * -o $RESDIR/fastqc_report -t 8

multiqc $RESDIR/fastqc_report/*.zip -o ../$RESDIR/

echo ""
echo "Quality control done. Check results at ${RESDIR}."
echo ""


echo ""
echo "===================================" 
echo "| Importing Ion Torrent sequences |"
echo "==================================="
echo ""
echo "Samples (located at ${SAMDIR} are being imported to ${RESDIR}." 
echo ""

cd ${RESDIR}
mkdir Demux

qiime tools import \
--type 'SampleData[SequencesWithQuality]'\
--input-path ${SAMDIR}/ \
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

echo "Denoising is taking place"

qiime dada2 denoise-single \
  --i-demultiplexed-seqs ${RESDIR}/Demux/single_end_demux.qza \
  --p-trunc-len-f 250 \
  --p-trunc-len-r 250 \
  --o-representative-sequences ${RESDIR}/Denoised/rep-seqs-dada2.qza \
  --o-table ${RESDIR}/Denoised/table-dada2.qza \
  --p-n-threads 8 \
  --p-max-ee 2 \
  --p-trunc-q  2
 
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
echo -e "\e[1m| Alpha and beta diversity is being calculated. |"
echo -e "\e[5m================================================="
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
  --m-metadata-file ${METADATADIR}/metadata.txt\
  --output-dir ${RESDIR}/Alpha-Beta-diversity/core-metrics-results

## Alpha group significance 


echo ""
echo -e "\e[1mAlpha diversity is being calculated."
echo ""
qiime diversity alpha-group-significance \
  --i-alpha-diversity ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file ${METADATADIR}/meta_data_rmd.txt \
  --o-visualization ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/faith-pd-group-significance.qzv

qiime diversity alpha-group-significance \
  --i-alpha-diversity ${RESDIR}/Alpha-Beta-diversity/evenness_vector.qza \
  --m-metadata-file ${METADATADIR}/meta_data_rmd.txt \
  --o-visualization ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/evenness-group-significance.qzv

## Beta group significance --> NECESITA REVISIÓN URGENTE PARA DETERMINAR
## CÓMO TIENE QUE SER EL ARCHIVO DE METADATOS DE LAS MUESTRAS.
## LOS TRES QIIME DIVERSITY DE ABAJO SON LO MISMO PERO CAMBIANDO EL
## NOMBRE DE LOS PARAMETROS CON LOS QUE HACE LA COMPARACION


echo ""
echo -e "\e[1mBeta diversity is being calculated."
echo ""

qiime diversity beta-group-significance \
  --i-distance-matrix ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file ${METADATADIR}/meta_data_rmd.txt \
  --m-metadata-category Treatment \
  --o-visualization ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/unweighted-unifrac-treatment-significance.qzv \
  --p-pairwise

qiime diversity beta-group-significance \
  --i-distance-matrix ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file ${METADATADIR}/meta_data_rmd.txt \
  --m-metadata-category Time \
  --o-visualization ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/unweighted-unifrac-time-significance.qzv  \
  --p-pairwise

qiime diversity beta-group-significance \
  --i-distance-matrix ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file ${METADATADIR}/meta_data_rmd.txt \
  --m-metadata-category Section \
  --o-visualization ${RESDIR}/Alpha-Beta-diversity/core-metrics-results/unweighted-unifrac-section-significance.qzv  \
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
  --m-metadata-file ${METADATADIR}/meta_data_rmd.txt \
  --o-visualization ${RESDIR}/Alpha-rarefaction/alpha-rarefaction.qzv

echo "Alpha rarefaction visualization is opening in a new window."

qiime tools view  $working_dir/alpha-rarefaction.qzv

echo ""
echo "======================" 
echo "| TAXONOMY ANALYSIS  |"
echo "======================"
echo ""

echo "SILVA 16S database was chosen for the analysis, as it is an up-to-date (SILVA v.138, the newest version on 3rd or December, 2020), reliable open source database recommended by many microbiologist experts. The file that is going to be used for the alignment is stored at the Results directory that you have provided in the parameters file (${RESDIR})"

cd ${RESDIR}
mkdir SILVA-classifier 
wget -O "SILVA-classifier/SILVA_138_515F_806R_seqs.qza" "https://data.qiime2.org/2020.8/common/silva-138-99-seqs-515-806.qza"
mkdir Taxonomic-analysis

qiime feature-classifier classify-sklearn \
  --i-classifier SILVA-classifier/SILVA_138_515F_806R_seqs.qza \
  --i-reads  ${RESDIR}/Denoised/rep-seqs-dada2.qza \
  --o-classification ${RESDIR}/Taxonomic-analysis/taxonomy.qza

qiime metadata tabulate \
  --m-input-file ${RESDIR}/Taxonomic-analysis/taxonomy.qza \
  --o-visualization .${RESDIR}/Taxonomic-analysis/taxonomy.qzv

qiime taxa barplot \
  --i-table  ${RESDIR}/Denoised/table-dada2.qza \
  --i-taxonomy ${RESDIR}/Taxonomic-analysis/taxonomy.qza \
  --m-metadata-file ${METADATADIR}/MappingFile_plate1_mod.txt \
  --o-visualization ${RESDIR}/Taxonomic-analysis/taxa-bar-plots.qzv
  
echo ""
echo "Analysis finished!"
