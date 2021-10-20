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

if [ -z "${AIDATATANG}" ]; then
  log "Error: \$AIDATATANG is not set in db.sh."
  exit 2
fi

if [ ! -d "${AIDATATANG}" ]; then
  log "Error: ${AIDATATANG} is empty."
  exit 2
fi

# To absolute path
AIDATATANG=$(cd ${AIDATATANG}; pwd)
aidatatang_audio_dir=${AIDATATANG}/corpus
aidatatang_text=${AIDATATANG}/transcript/aidatatang_200_zh_transcript.txt

log "Aidatatang Data Preparation"
train_dir=data/local/aidatatang_train
dev_dir=data/local/aidatatang_dev
test_dir=data/local/aidatatang_test
tmp_dir=data/local/tmp

mkdir -p $train_dir
mkdir -p $dev_dir
mkdir -p $test_dir
mkdir -p $tmp_dir

# find wav audio file for train, dev and test resp.
find -L $aidatatang_audio_dir -iname "*.wav" > $tmp_dir/wav.flist
n=$(wc -l < $tmp_dir/wav.flist)
[ $n -ne 237265 ] && log Warning: expected 237265 data data files, found $n

grep -i "corpus/train" $tmp_dir/wav.flist > $train_dir/wav.flist || exit 1;
grep -i "corpus/dev" $tmp_dir/wav.flist > $dev_dir/wav.flist || exit 1;
grep -i "corpus/test" $tmp_dir/wav.flist > $test_dir/wav.flist || exit 1;

rm -r $tmp_dir

# transcriptions preparation
for dir in $train_dir $dev_dir $test_dir; do
  sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{print $NF}' > $dir/utt.list
  sed -e 's/\.wav//' $dir/wav.flist | awk -F '/' '{i=NF-1;printf("%s %s\n",$NF,$i)}' > $dir/utt2spk_all
  paste -d' ' $dir/utt.list $dir/wav.flist > $dir/wav.scp_all
  utils/filter_scp.pl -f 1 $dir/utt.list $aidatatang_text > $dir/transcripts.txt
  awk '{print $1}' $dir/transcripts.txt > $dir/utt.list
  utils/filter_scp.pl -f 1 $dir/utt.list $dir/utt2spk_all | sort -u > $dir/utt2spk
  utils/filter_scp.pl -f 1 $dir/utt.list $dir/wav.scp_all | sort -u > $dir/wav.scp
  sort -u $dir/transcripts.txt | local/text_normalize.pl > $dir/text
  utils/utt2spk_to_spk2utt.pl $dir/utt2spk > $dir/spk2utt
done

utils/copy_data_dir.sh --utt-prefix aidatatang- --spk-prefix aidatatang- \
  $train_dir data/aidatatang_train
utils/copy_data_dir.sh --utt-prefix aidatatang- --spk-prefix aidatatang- \
  $dev_dir data/aidatatang_dev
utils/copy_data_dir.sh --utt-prefix aidatatang- --spk-prefix aidatatang- \
  $test_dir data/aidatatang_test

# remove space in text
for x in aidatatang_train aidatatang_dev aidatatang_test; do
  cp data/${x}/text data/${x}/text.org
  paste -d " " <(cut -f 1 -d" " data/${x}/text.org) <(cut -f 2- -d" " data/${x}/text.org | tr -d " ") \
      > data/${x}/text
  rm data/${x}/text.org
done
