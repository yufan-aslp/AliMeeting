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
help_messge=$(cat << EOF
Usage: $0

Options:
    --no_overlap (bool): Whether to ignore the overlapping utterance in the training set.
    --tgt (string): Which set to process, test or train.
EOF
)

SECONDS=0
no_overlap=true
tgt=train #test or train

log "$0 $*"


. ./utils/parse_options.sh

. ./db.sh
. ./path.sh
. ./cmd.sh


if [ $# -gt 1 ]; then
  log "${help_message}"
  exit 2
fi

if [ -z "${AISHELL4}" ]; then
  log "Error: \$AISHELL4 is not set in db.sh."
  exit 2
fi

if [ ! -d "${AISHELL4}" ]; then
  log "Error: ${AISHELL4} is empty."
  exit 2
fi

# To absolute path
AISHELL4=$(cd ${AISHELL4}; pwd)
aishell4_audio_dir=${AISHELL4}
aishell4_text_dir=${AISHELL4}

log "Aishell4 Data Preparation"
train_nooverlap_dir=data/local/aishell4_${tgt}_nooverlap
train_overlap_merge_dir=data/local//aishell4_${tgt}_overlap_merge
train_overlap_dir=data/local/aishell4_${tgt}_overlap

tmp_dir=data/local/tmp_${tgt}
stage=0
stop_stage=10

mkdir -p $train_nooverlap_dir
mkdir -p $train_overlap_merge_dir
mkdir -p $train_overlap_dir

mkdir -p $tmp_dir
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    log "stage 1:process aishell4 all wav and text to tmp dir"
    # find wav audio files
    find -L $aishell4_audio_dir -iname "*.flac" > $tmp_dir/wav.flist
    grep -i "${tgt}" $tmp_dir/wav.flist > $train_nooverlap_dir/wav.flist || exit 1;

    # find textgrid files
    find -L $aishell4_text_dir -iname "*.TextGrid" > $tmp_dir/textgrid.flist
    grep -i "${tgt}" $tmp_dir/textgrid.flist > $train_nooverlap_dir/textgrid.flist || exit 1;

    rm -r $tmp_dir
fi
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    log "stage 2:transcriptions preparation"
    # training set
    sed -e 's/\.flac//' $train_nooverlap_dir/wav.flist | awk -F '/' '{print $NF}' > $train_nooverlap_dir/utt.list
    paste -d' ' $train_nooverlap_dir/utt.list $train_nooverlap_dir/wav.flist > $train_nooverlap_dir/wav_all.scp
    cat $train_nooverlap_dir/wav_all.scp | awk '{printf("%s sox  -t flac %s -r 16000 -c 8 -b 16  -t wav - |\n", $1, $2)}' | \
        sort -u > $train_nooverlap_dir/wav.scp
    cp $train_nooverlap_dir/* $train_overlap_merge_dir
    cp $train_nooverlap_dir/* $train_overlap_dir

fi
if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    log "stage 3: train_nooverlap_dir preocess"
    python local/aishell4_process_textgrid.py --path $train_nooverlap_dir --no-overlap True
    cat $train_nooverlap_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $train_nooverlap_dir/text
    utils/filter_scp.pl -f 1 $train_nooverlap_dir/text $train_nooverlap_dir/utt2spk_all | sort -u > $train_nooverlap_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $train_nooverlap_dir/utt2spk > $train_nooverlap_dir/spk2utt
    utils/filter_scp.pl -f 1 $train_nooverlap_dir/text $train_nooverlap_dir/segments_all | sort -u > $train_nooverlap_dir/segments
fi

if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    log "stage 4: train_overlap_merge_dir preocess"
    python local/aishell4_process_textgrid.py --path $train_overlap_merge_dir --no-overlap False \
        --overlap_length 0.8 --max_length 7 --merge-overlap True
    cat $train_overlap_merge_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $train_overlap_merge_dir/text
    utils/filter_scp.pl -f 1 $train_overlap_merge_dir/text $train_overlap_merge_dir/utt2spk_all | sort -u > $train_overlap_merge_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $train_overlap_merge_dir/utt2spk > $train_overlap_merge_dir/spk2utt
    utils/filter_scp.pl -f 1 $train_overlap_merge_dir/text $train_overlap_merge_dir/segments_all | sort -u > $train_overlap_merge_dir/segments
fi
if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    log "stage 5: train_overlap_dir preocess"
    python local/aishell4_process_textgrid.py --path $train_overlap_dir \
        --no-overlap False  --merge-overlap False
    cat $train_overlap_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $train_overlap_dir/text
    utils/filter_scp.pl -f 1 $train_overlap_dir/text $train_overlap_dir/utt2spk_all | sort -u > $train_overlap_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $train_overlap_dir/utt2spk > $train_overlap_dir/spk2utt
    utils/filter_scp.pl -f 1 $train_overlap_dir/text $train_overlap_dir/segments_all | sort -u > $train_overlap_dir/segments
fi

if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
    log "stage 6: finali data process"
    utils/copy_data_dir.sh --utt-prefix aishell4nooverlap-  --spk-prefix aishell4nooverlap- \
        $train_nooverlap_dir data/aishell4_${tgt}_nooverlap
    utils/copy_data_dir.sh --utt-prefix aishell4overlap-  --spk-prefix aishell4overlap- \
        $train_overlap_dir data/aishell4_${tgt}_overlap
    utils/copy_data_dir.sh --utt-prefix aishell4overlapmerge- --spk-prefix aishell4overlapmerge- \
        $train_overlap_merge_dir data/aishell4_${tgt}_overlap_merge

    # remove space in text
    for x in aishell4_${tgt}_nooverlap aishell4_${tgt}_overlap aishell4_${tgt}_overlap_merge; do
        cp data/${x}/text data/${x}/text.org
        paste -d " " <(cut -f 1 -d" " data/${x}/text.org) <(cut -f 2- -d" " data/${x}/text.org | tr -d " ") \
        > data/${x}/text
        rm data/${x}/text.org
    done

    log "Successfully finished. [elapsed=${SECONDS}s]"
fi


if [ ${stage} -le 7 ] && [ ${stop_stage} -ge 7 ]; then
    log "stage 7: process mars one channel"
    for x in aishell4_${tgt}_nooverlap aishell4_${tgt}_overlap aishell4_${tgt}_overlap_merge; do
        cp -r data/${x} data/${x}_onechannel
        cp data/${x}_onechannel/wav.scp data/${x}_onechannel/wav_bak
        sed -e "s/-c 8/-c 1/g" ./data/${x}_onechannel/wav.scp >./data/${x}_onechannel/tmp
        cp ./data/${x}_onechannel/tmp ./data/${x}_onechannel/wav.scp
        ./utils/fix_data_dir.sh ./data/${x}_onechannel/
    done   
fi
