#!/bin/bash
#
# description   :Split a DarwinCore Archive file into n files for each dataset found 
# author        :Arturo Vargas turo.vargas@gmail.com
# date          :20150709
# usage         :bash explode_dwc.sh dwca_zip_file output_directory

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

mkdir $working_dir
unzip -q $dwca -d $working_dir

  # find datasetKey column index
dataset_column=`grep datasetKey $working_dir/meta.xml | grep -oP 'index="\K\d+'`
dataset_column=$((dataset_column + 1))

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

# where the magic happens
awk -F '\t' -v dataset=$dataset_column -v output_dir=$output_dir 'NR>1 { print >> output_dir"/"$dataset"/occurrence.txt"}' $working_dir/occurrence.txt

for dataset in $(ls $working_dir/dataset)
do
   dataset="${dataset/.xml/}"
   cd $output_dir/$dataset
   zip --no-dir-entries -q -r $output_dir/$dataset.zip .

   rm -r $output_dir/$dataset

done

echo 'cleanup'
rm -r $working_dir

