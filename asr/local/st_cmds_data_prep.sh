#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
help_message=$(cat << EOF
Usage: $0
EOF
)

SECONDS=0

log "$0 $*"


. ./utils/parse_options.sh

. ./db.sh
. ./path.sh
. ./cmd.sh


if [ $# -gt 0 ]; then
  log "${help_message}"
  exit 2
fi

if [ -z "${ST_CMD}" ]; then
  log "Error: \$ST_CMD is not set in db.sh."
  exit 2
fi

if [ ! -d "${ST_CMD}" ]; then
  log "Error: ${ST_CMD} is empty."
  exit 2
fi

# To absolute path
ST_CMD=$(cd ${ST_CMD}; pwd)

log "ST_CMD Data Preparation"
dir=data/local/st_cmd
mkdir -p $dir

# find wav audio files
find -L ${ST_CMD} -iname "*.wav" > $dir/wav.flist
n=$(wc -l < $dir/wav.flist)
[ $n -ne 102600 ] && log Warning: expected 102600 data data files, found $n

# find transcription files
find -L ${ST_CMD} -iname "*.txt" > $dir/trans.flist
n=$(wc -l < $dir/trans.flist)
[ $n -ne 102600 ] && log Warning: expected 102600 data data files, found $n

# wav.scp preparation
sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{print $NF}' > $dir/utt.list
paste -d' ' $dir/utt.list $dir/wav.flist > $dir/wav.scp_all

# transcriptions preparation
while read line; do
  uttid=`echo $line | sed -e 's/\.txt//' | awk -F '/' '{print $NF}'`
  text=`cat $line`
  echo "$uttid $text"
done < $dir/trans.flist > $dir/text_all
utils/filter_scp.pl -f 1 $dir/utt.list $dir/text_all | local/text_normalize.pl | sort -u > $dir/text

awk '{print $1}' $dir/text > $dir/utt.list
utils/filter_scp.pl -f 1 $dir/utt.list $dir/wav.scp_all | sort -u > $dir/wav.scp

# spk2utt prepartion
cat $dir/utt.list | awk '{print substr($1,9,7)}' > $dir/spk.list
paste -d' ' $dir/utt.list $dir/spk.list > $dir/utt2spk
utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt

utils/copy_data_dir.sh --utt-prefix st_cmd- --spk-prefix st_cmd- \
  $dir data/st_cmd

# remove space in text
cp data/st_cmd/text data/st_cmd/text.org
paste -d " " <(cut -f 1 -d" " data/st_cmd/text.org) <(cut -f 2- -d" " data/st_cmd/text.org | tr -d " ") \
    > data/st_cmd/text
rm data/st_cmd/text.org

utils/subset_data_dir_tr_cv.sh data/st_cmd data/st_cmd_train data/st_cmd_dev
