#!/bin/bash
#
# description   :Split a DarwinCore Archive file into n files for each dataset found 
# author        :Arturo Vargas turo.vargas@gmail.com
# date          :20150709
# usage         :bash explode_dwc.sh dwca_zip_file output_directory

# Update:  
#     Maria Mora: Add functionality to process multimedia.txt (20201205)

function isRelative {
    local dir=$1
    if [ "${dir:0:1}" = "/" ]
    then
        return 1
    else
        return 0
    fi
}

if [ "$#" -ne 2 ]; then
    echo "2 arguments required, $# provided"
    exit 1
fi

output_dir=$2
dwca=$1

if  isRelative $output_dir ; then
    output_dir=`pwd`"/$output_dir"
fi

working_dir="/tmp/"`date +%s%N`
echo $working_dir

#Unzip the DwC Archive in the /tmp
mkdir $working_dir
unzip -q $dwca -d $working_dir

# find datasetKey column index
dataset_column=`grep datasetKey $working_dir/meta.xml | grep -oP 'index="\K\d+'`

# increase the value because index value starts in cero.
dataset_column=$((dataset_column + 1))

#Prepare directories and files to process each dataset
for dataset in $(ls $working_dir/dataset)
do
    dataset="${dataset/.xml/}"
    echo "dataset: $dataset"

    mkdir -p $output_dir/$dataset

    # include meta.xml file in every directory
    cp $working_dir/meta.xml $output_dir/$dataset

    # include dataset metadata file
    mkdir $output_dir/$dataset/dataset
    cp $working_dir/dataset/$dataset.xml $output_dir/$dataset/dataset/

    head -n 1 $working_dir/occurrence.txt > $output_dir/$dataset/occurrence.txt

done

#Split occurrence.txt in a file for each datasetKey 
awk -F '\t' -v dataset=$dataset_column -v output_dir=$output_dir 'NR>1 { print >> output_dir"/"$dataset"/occurrence.txt"}' $working_dir/occurrence.txt


#Filter multimedia using the occurrence.txt (occurrence list) for each datasetKey 
#for dataset in $(ls $working_dir/dataset)
#do

#  dataset="${dataset/.xml/}"
#  echo "dataset: $dataset"
#  awk -F '\t' 'NR==FNR{c[$1]++;next};c[$1]'  $output_dir/$dataset/occurrence.txt $working_dir/multimedia.txt > $output_dir/$dataset/multimedia.txt
#done

#Zip each DwC Archive, one for each datasetKey
for dataset in $(ls $working_dir/dataset)
do
   dataset="${dataset/.xml/}"
   cd $output_dir/$dataset
   zip --no-dir-entries -q -r $output_dir/$dataset.zip .

   rm -r $output_dir/$dataset

done

echo 'cleanup'
rm -r $working_dir

