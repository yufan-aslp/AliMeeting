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

if [ -z "${AISHELL}" ]; then
  log "Error: \$AISHELL is not set in db.sh."
  exit 2
fi

if [ ! -d "${AISHELL}" ]; then
  log "Error: ${AISHELL} is empty."
  exit 2
fi

# To absolute path
AISHELL=$(cd ${AISHELL}; pwd)
aishell_audio_dir=${AISHELL}/data_aishell/wav
aishell_text=${AISHELL}/data_aishell/transcript/aishell_transcript_v0.8.txt

log "Aishell Data Preparation"
train_dir=data/local/aishell_train
dev_dir=data/local/aishell_dev
test_dir=data/local/aishell_test
tmp_dir=data/local/tmp

mkdir -p $train_dir
mkdir -p $dev_dir
mkdir -p $test_dir
mkdir -p $tmp_dir

# find wav audio file for train, dev and test resp.
find -L $aishell_audio_dir -iname "*.wav" > $tmp_dir/wav.flist
n=$(wc -l < $tmp_dir/wav.flist)
[ $n -ne 141925 ] && log Warning: expected 141925 data data files, found $n

grep -i "wav/train" $tmp_dir/wav.flist > $train_dir/wav.flist || exit 1;
grep -i "wav/dev" $tmp_dir/wav.flist > $dev_dir/wav.flist || exit 1;
grep -i "wav/test" $tmp_dir/wav.flist > $test_dir/wav.flist || exit 1;

rm -r $tmp_dir

# transcriptions preparation
for dir in $train_dir $dev_dir $test_dir; do
  sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{print $NF}' > $dir/utt.list
  sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{i=NF-1;printf("%s %s\n",$NF,$i)}' > $dir/utt2spk_all
  paste -d' ' $dir/utt.list $dir/wav.flist > $dir/wav.scp_all
  utils/filter_scp.pl -f 1 $dir/utt.list $aishell_text > $dir/transcripts.txt
  awk '{print $1}' $dir/transcripts.txt > $dir/utt.list
  utils/filter_scp.pl -f 1 $dir/utt.list $dir/utt2spk_all | sort -u > $dir/utt2spk
  utils/filter_scp.pl -f 1 $dir/utt.list $dir/wav.scp_all | sort -u > $dir/wav.scp
  sort -u $dir/transcripts.txt | local/text_normalize.pl > $dir/text
  utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt
done

utils/copy_data_dir.sh --utt-prefix aishell- --spk-prefix aishell- \
  $train_dir data/aishell_train
utils/copy_data_dir.sh --utt-prefix aishell- --spk-prefix aishell- \
  $dev_dir data/aishell_dev
utils/copy_data_dir.sh --utt-prefix aishell- --spk-prefix aishell- \
  $test_dir data/aishell_test

# remove space in text
for x in aishell_train aishell_dev aishell_test; do
  cp data/${x}/text data/${x}/text.org
  paste -d " " <(cut -f 1 -d" " data/${x}/text.org) <(cut -f 2- -d" " data/${x}/text.org | tr -d " ") \
      > data/${x}/text
  rm data/${x}/text.org
done
