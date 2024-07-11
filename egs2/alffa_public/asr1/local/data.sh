#!/usr/bin/env bash

set -e
set -u
set -o pipefail

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

help_message=$(cat << EOF
Usage: $0 --official-data-dir <official_data_dir>

  required argument:
    --official-data-dir: path to the directory of official data for ALFFA Amharic ASR corpus with the following structure:

        <official_data_dir>
         |-- data/
         |   |-- wav/
         |   \-- transcript/
         |
         \-- README.md
EOF
)

official_data_dir=

log "$0 $*"
. utils/parse_options.sh

. ./path.sh || exit 1;
. ./cmd.sh || exit 1;
. ./db.sh || exit 1;

if [ $# -gt 0 ]; then
    log "${help_message}"
    exit 2
fi

if [ -z "${official_data_dir}" ]; then
    log "${help_message}"
    log "No such directory for --official-data-dir: '${official_data_dir}'"
    exit 1
fi

if [ -z "${ALFFA_AMHARIC}" ]; then
    log "Fill the value of 'ALFFA_AMHARIC' in db.sh"
    log "(available at https://github.com/getalp/ALFFA_PUBLIC/tree/master/ASR/AMHARIC)"
    exit 1
fi

# `log "Download data to ${ALFFA_AMHARIC}"
# if [ ! -d "${ALFFA_AMHARIC}" ]; then
#     mkdir -p "${ALFFA_AMHARIC}"
# fi
# # To absolute path
# ALFFA_AMHARIC=$(cd ${ALFFA_AMHARIC}; pwd)

# # Directly clone the repository if it doesn't already exist
# if [ ! -d "${ALFFA_AMHARIC}/.git" ]; then
#     git clone https://github.com/getalp/ALFFA_PUBLIC.git "${ALFFA_AMHARIC}"
# fi`

# Navigate to the ASR/AMHARIC directory
cd "${ALFFA_AMHARIC}/ASR/AMHARIC"

# Define paths
amharic_data_dir=${ALFFA_AMHARIC}/ASR/AMHARIC/data
train_dir=${amharic_data_dir}/train
test_dir=${amharic_data_dir}/test

log "Data Preparation"
output_train_dir=data/train
output_test_dir=data/test

mkdir -p $output_train_dir
mkdir -p $output_test_dir

# Copy the necessary files to the output directories
cp ${train_dir}/wav.scp $output_train_dir/wav.scp
cp ${train_dir}/utt2spk $output_train_dir/utt2spk
cp ${train_dir}/trsTrain.txt $output_train_dir/text
cp -r ${train_dir}/wav $output_train_dir/wav

cp ${test_dir}/wav.scp $output_test_dir/wav.scp
cp ${test_dir}/utt2spk $output_test_dir/utt2spk
cp ${test_dir}/trsTest.txt $output_test_dir/text
cp -r ${test_dir}/wav $output_test_dir/wav

# Ensure text files are correctly formatted
for dir in $output_train_dir $output_test_dir; do
    log "Formatting text file in $dir"
    cp $dir/text $dir/text.org
    paste -d " " <(cut -f 1 -d" " $dir/text.org) <(cut -f 2- -d" " $dir/text.org | tr -d " ") > $dir/text
    rm $dir/text.org
done

log "Successfully finished. [elapsed=${SECONDS}s]"
