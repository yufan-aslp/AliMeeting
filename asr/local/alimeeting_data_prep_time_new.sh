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
tgt=train  #test or train
no_overlap=false


log "$0 $*"

. ./utils/parse_options.sh

. ./db.sh
. ./path.sh
. ./cmd.sh

if [ $# -gt 2 ]; then
    log "${help_message}"
    exit 2
fi


echo "process the ${tgt} set , and no_overlap is ${no_overlap}"

if [ -z "${AliMeeting}" ]; then
  log "Error: \$AliMeeting is not set in db.sh."
  exit 2
fi

if [ ! -d "${AliMeeting}" ]; then
  log "Error: ${AliMeeting} is empty."
  exit 2
fi

# To absolute path
AliMeeting=$(cd ${AliMeeting}; pwd)
echo $AliMeeting
alimeeting_audio_dir=${AliMeeting}/
alimeeting_text_dir=${AliMeeting}/

mars_dir=data/local/alimeeting_${tgt}_mars_time_new
mars_raw_dir=data/local/alimeeting_${tgt}_mars
array_dir=data/local/alimeeting_${tgt}_array_time_new
tmp_dir=data/local/tmp_${tgt}
stage=66
stop_stage=66
mars_overlap_dir=data/local/alimeeting_${tgt}_mars_overlaps_time_new
mars_overlap_merge_dir=data/local/alimeeting_${tgt}_mars_overlaps_merge_time_new
mars_overlap_dir_force=data/local/alimeeting_${tgt}_mars_overlaps_force_time_new
mars_nooverlap_dir=data/local/alimeeting_${tgt}_mars_nooverlaps_time_new
mars_xvec=data/local/alimeeting_${tgt}_mars_xvector_singe_speaker
mkdir -p $mars_overlap_dir_force
mkdir -p $mars_overlap_dir
mkdir -p $mars_dir
mkdir -p $array_dir
mkdir -p $tmp_dir
mkdir -p $mars_nooverlap_dir
mkdir -p $mars_overlap_merge_dir
if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    log "stage 5: mars text preparation for alimeeting test"
    head -n 120  $mars_raw_dir/wav.scp >   $mars_dir/wav.scp
    cp $array_dir/textgrid_mars.flist $mars_dir/textgrid_id.flist
    cut -d " "  -f 1 $mars_dir/textgrid_id.flist > $mars_dir/uttid
    cut -d " "  -f 2 $mars_dir/textgrid_id.flist > $mars_dir/textgrid.flist
    python local/alimeeting_process_textgrid.py --path $mars_dir --no-overlap $no_overlap --mars True
    cat $mars_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $mars_dir/text
    utils/filter_scp.pl -f 1 $mars_dir/text $mars_dir/utt2spk_all | sort -u > $mars_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $mars_dir/utt2spk > $mars_dir/spk2utt
    utils/filter_scp.pl -f 1 $mars_dir/text $mars_dir/segments_all | sort -u > $mars_dir/segments
    utils/copy_data_dir.sh --utt-prefix alimeetingmars- --spk-prefix alimeetingmars- \
        $mars_dir data/alimeeting_${tgt}_mars_time_new
    for x in alimeeting_${tgt}_mars_time_new; do
        cp data/${x}/text data/${x}/text.org
        paste -d " " <(cut -f 1 -d" " data/${x}/text.org) <(cut -f 2- -d" " data/${x}/text.org | tr -d " ") \
            > data/${x}/text
        rm data/${x}/text.org
    done

fi


if [ ${stage} -le 6 ] && [ ${stop_stage} -ge 6 ]; then
       
    cp -r  $mars_dir/*  $mars_overlap_dir
    python local/alimeeting_process_overlap.py  --path $mars_overlap_dir \
        --no-overlap false --mars True \
        --overlap_length 0.8 --max_length 7
    cat $mars_overlap_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $mars_overlap_dir/text
    utils/filter_scp.pl -f 1 $mars_overlap_dir/text $mars_overlap_dir/utt2spk_all | sort -u > $mars_overlap_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $mars_overlap_dir/utt2spk > $mars_overlap_dir/spk2utt
    utils/filter_scp.pl -f 1 $mars_overlap_dir/text $mars_overlap_dir/segments_all | sort -u > $mars_overlap_dir/segments

fi

if [ ${stage} -le 66 ] && [ ${stop_stage} -ge 66 ]; then
       
    cp  $mars_xvec/textgrid.flist  $mars_overlap_merge_dir/textgrid.flist
    cp  $mars_xvec/wav.scp  $mars_overlap_merge_dir
    python local/alimeeting_process_textgrid_speaker.py  --path $mars_overlap_merge_dir \
        --overlap_length 0.8 --max_length 7
    cat $mars_overlap_merge_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $mars_overlap_merge_dir/text
    utils/filter_scp.pl -f 1 $mars_overlap_merge_dir/text $mars_overlap_merge_dir/utt2spk_all | sort -u > $mars_overlap_merge_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $mars_overlap_merge_dir/utt2spk > $mars_overlap_merge_dir/spk2utt
    utils/filter_scp.pl -f 1 $mars_overlap_merge_dir/text $mars_overlap_merge_dir/segments_all | sort -u > $mars_overlap_merge_dir/segments
    sed -e "s/(\~)//g" $mars_overlap_merge_dir/text > $mars_overlap_merge_dir/tmp
    sed -e "s/ $//g" $mars_overlap_merge_dir/tmp > $mars_overlap_merge_dir/tmp2
    sed -e "s/！//g" $mars_overlap_merge_dir/tmp2 > $mars_overlap_merge_dir/text
    
fi
if [ ${stage} -le 7 ] && [ ${stop_stage} -ge 7 ]; then
       
    cp -r  $mars_dir/*  $mars_overlap_dir_force
    python local/alimeeting_process_overlap_force.py  --path $mars_overlap_dir_force \
        --no-overlap false --mars True \
        --overlap_length 0.8 --max_length 7
    cat $mars_overlap_dir_force/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $mars_overlap_dir_force/text
    utils/filter_scp.pl -f 1 $mars_overlap_dir_force/text $mars_overlap_dir_force/utt2spk_all | sort -u > $mars_overlap_dir_force/utt2spk
    utils/utt2spk_to_spk2utt.pl $mars_overlap_dir_force/utt2spk > $mars_overlap_dir_force/spk2utt
    utils/filter_scp.pl -f 1 $mars_overlap_dir_force/text $mars_overlap_dir_force/segments_all | sort -u > $mars_overlap_dir_force/segments
fi
if [ ${stage} -le 9 ] && [ ${stop_stage} -ge 9 ]; then
       
    cp -r  $mars_dir/*  $mars_nooverlap_dir
    python local/alimeeting_process_overlap.py  --path $mars_nooverlap_dir \
        --no-overlap true --mars True
    cat $mars_nooverlap_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $mars_nooverlap_dir/text
    utils/filter_scp.pl -f 1 $mars_nooverlap_dir/text $mars_nooverlap_dir/utt2spk_all | sort -u > $mars_nooverlap_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $mars_nooverlap_dir/utt2spk > $mars_nooverlap_dir/spk2utt
    utils/filter_scp.pl -f 1 $mars_nooverlap_dir/text $mars_nooverlap_dir/segments_all | sort -u > $mars_nooverlap_dir/segments
    utils/copy_data_dir.sh --utt-prefix alimeetingnooverlap- --spk-prefix alimeetingnooverlap- \
        $mars_nooverlap_dir data/alimeeting_${tgt}_mars_nooverlap_time_new
    for x in alimeeting_${tgt}_mars_nooverlap_time_new; do
        cp data/${x}/text data/${x}/text.org
        paste -d " " <(cut -f 1 -d" " data/${x}/text.org) <(cut -f 2- -d" " data/${x}/text.org | tr -d " ") \
            > data/${x}/text
        rm data/${x}/text.org
    done
fi

if [ ${stage} -le 8 ] && [ ${stop_stage} -ge 8 ]; then
    log "stage 8: finali data process"

    #utils/copy_data_dir.sh --utt-prefix alimeeting- --spk-prefix alimeeting- \
    #    $array_dir data/alimeeting_${tgt}_array
    #utils/copy_data_dir.sh --utt-prefix alimeeting- --spk-prefix alimeeting- \
    #    $mars_dir data/alimeeting_${tgt}_mars
    utils/copy_data_dir.sh --utt-prefix alimeetingoverlap- --spk-prefix alimeetingoverlap- \
        $mars_overlap_dir data/alimeeting_${tgt}_mars_overlaps_time_new
    utils/copy_data_dir.sh --utt-prefix alimeetingoverlapforce- --spk-prefix alimeetingoverlapforce- \
        $mars_overlap_dir_force data/alimeeting_${tgt}_mars_overlaps_force_time_new

    # remove space in text
    #for x in alimeeting_${tgt}_array alimeeting_${tgt}_mars; do
    for x in alimeeting_${tgt}_mars_overlaps_time_new alimeeting_${tgt}_mars_overlaps_force_time_new; do
        cp data/${x}/text data/${x}/text.org
        paste -d " " <(cut -f 1 -d" " data/${x}/text.org) <(cut -f 2- -d" " data/${x}/text.org | tr -d " ") \
        > data/${x}/text
        rm data/${x}/text.org
    done

    log "Successfully finished. [elapsed=${SECONDS}s]"
fi

if [ ${stage} -le 10 ] && [ ${stop_stage} -ge 10 ]; then
    log "stage 10: process mars one channel"

    #for x in alimeeting_${tgt}_mars_time_new; do
    for x in alimeeting_${tgt}_mars_overlaps_time_new alimeeting_${tgt}_mars_overlaps_force_time_new alimeeting_${tgt}_mars_nooverlap_time_new; do
        cp -r data/${x} data/${x}_onechannel
        cp data/${x}_onechannel/wav.scp data/${x}_onechannel/wav_bak
        sed -e "s/-r 16000/-r 16000 -c 1/g" ./data/${x}_onechannel/wav.scp >./data/${x}_onechannel/tmp
        cp ./data/${x}_onechannel/tmp ./data/${x}_onechannel/wav.scp
        ./utils/fix_data_dir.sh ./data/${x}_onechannel/
        
    done
fi
