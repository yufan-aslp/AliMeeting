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
tgt=val #test or train
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
AliMeeting=/mnt/fyu/data/AliMeeting/Mars/
echo $AliMeeting
alimeeting_audio_dir=${AliMeeting}/
alimeeting_text_dir=${AliMeeting}/

mars_dir=data/local/alimeeting_${tgt}_mars
array_dir=data/local/alimeeting_${tgt}_array
tmp_dir=data/local/tmp_${tgt}
stage=1
stop_stage=8
mkdir -p $mars_dir
mkdir -p $array_dir
mkdir -p $tmp_dir
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then 
    log "stage 1:process alimeeting all wav and text to tmp dir"
    find -L $alimeeting_audio_dir/ -iname "*.wav" >  $tmp_dir/wav_all.flist
    find -L $alimeeting_text_dir/ -iname "*.txt" > $tmp_dir/text_all.flist
fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    log "stage 2:process alimeeting test (contain *wav and *pcm)"
    
    grep -i "Array/wav" $tmp_dir/wav_all.flist > $array_dir/wav_ori.flist || exit 1;
    grep -i "Array/trans" $tmp_dir/text_all.flist > $array_dir/text_ori.flist || exit 1;

    grep -i "MS" $tmp_dir/wav_all.flist > $mars_dir/wav_ori.flist || exit 1;
fi

if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    log "stage 3: wav preparation for alimeeting test"

    sed -e 's/\.txt//' $array_dir/text_ori.flist | awk -F '/' '{print $NF}' > $array_dir/utt.list
    paste -d' ' $array_dir/utt.list $array_dir/wav_ori.flist > $array_dir/wav_all.scp
    
    grep -i  "wav" $array_dir/wav_all.scp > $array_dir/wav_wav.scp
    cat $array_dir/wav_wav.scp | awk '{printf("%s sox -t wav  %s -r 16000 -b 16 -c 1 -t wav  - |\n", $1, $2)}' | \
        sort -u > $array_dir/wav.scp

    sed -e 's/\.wav//' $mars_dir/wav_ori.flist | awk -F '/' '{print $NF}' > $mars_dir/utt.list
    paste -d' ' $mars_dir/utt.list $mars_dir/wav_ori.flist > $mars_dir/wav_all.scp
    grep -i  "wav" $mars_dir/wav_all.scp > $mars_dir/wav_wav.scp
    cat $mars_dir/wav_wav.scp | awk '{printf("%s sox -t wav  %s -r 16000 -b 16 -c 1 -t wav - |\n", $1, $2)}' | \
        sort -u > $mars_dir/wav.scp
fi
if [ ${stage} -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    log "stage 4: array text preparation for alimeeting test"
    text_array_dir=$array_dir/text_dir
    text_clean_dir=$array_dir/text_clean
    mkdir -p $text_array_dir
    mkdir -p $text_clean_dir
    mkdir -p $text_clean_dir/final
    paste -d' ' $array_dir/utt.list $array_dir/text_ori.flist > $array_dir/text_all.scp
    while read text_file
    do
        m=`echo $text_file | awk '{print $1}'`
        in_text=`echo $text_file | awk '{print $2}'`
        out_text=${text_array_dir}/${m}.TextGrid
        encoding_form=`file $in_text|awk '{print $3}'`
        if [ "$encoding_form" = "UTF-16" ];then
            iconv -f UTF-16 -t UTF-8 $in_text >$text_clean_dir/${m}_utf8.txt
        else
            cp $in_text $text_clean_dir/${m}_utf8.txt
        fi

        grep -v "无效" $text_clean_dir/${m}_utf8.txt  > $text_clean_dir/${m}.txt
        sed -e 's/ //g' $text_clean_dir/${m}.txt> $text_clean_dir/${m}_0.txt
        sed -e 's/(noise)//g' $text_clean_dir/${m}_0.txt> $text_clean_dir/${m}_1.txt
        sed -e 's/(overlap)//g' $text_clean_dir/${m}_1.txt> $text_clean_dir/${m}_2.txt
        sed -e 's/(\/overlap)//g' $text_clean_dir/${m}_2.txt> $text_clean_dir/${m}_3.txt
        sed -e 's/(\~)//g' $text_clean_dir/${m}_3.txt> $text_clean_dir/${m}_4.txt

        cp $text_clean_dir/${m}_4.txt $text_clean_dir/final/${m}.txt
        python local/text2textgrid.py --in_path=$text_clean_dir/${m}_4.txt --out_path=$out_text
    done < $array_dir/text_all.scp
    pwd_path=$(pwd)
    find -L $pwd_path/$text_array_dir -iname "*.TextGrid" >  $array_dir/textgrid.flist

    python local/alimeeting_process_textgrid.py --path $array_dir --no-overlap False
    cat $array_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $array_dir/text
    utils/filter_scp.pl -f 1 $array_dir/text $array_dir/utt2spk_all | sort -u > $array_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $array_dir/utt2spk > $array_dir/spk2utt
    utils/filter_scp.pl -f 1 $array_dir/text $array_dir/segments_all | sort -u > $array_dir/segments
fi
if [ ${stage} -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    log "stage 5: mars text preparation for alimeeting test"
    text_mars_dir=$mars_dir/text_dir
    text_clean_dir=$mars_dir/text_clean
    # if text_clean_dir already exit, you should rm it 
    mkdir -p $text_mars_dir
    mkdir -p $text_clean_dir
    pwd_path=$(pwd)
    find -L $array_dir/text_clean/final/ -iname "*.txt" >  $mars_dir/text_array.scp
    while read text_file
    do
        file=`echo $text_file |awk '{split($0,lst,"/"); utt1=lst[6];print(utt1)}'`
        file=`echo $file |awk -F"." '{print($1)}'`
        mars_file=`echo $file |awk -F"_" '{printf("%s_%s",$1,$2)}'`
        speaker_id=`echo $file |awk -F"_" '{printf("%s_%s",$3,$4)}'`
        sed -e "s/S1/${speaker_id}/g"  $text_file > $text_clean_dir/tmp1
        sed -e "s/S2/${speaker_id}/g"  $text_clean_dir/tmp1 > $text_clean_dir/tmp2
        sed -e "s/S3/${speaker_id}/g"  $text_clean_dir/tmp2 > $text_clean_dir/tmp3
        sed -e "s/c1/${speaker_id}/g"  $text_clean_dir/tmp3 > $text_clean_dir/tmp
        cat $text_clean_dir/tmp >> $text_clean_dir/${mars_file}.txt
    done < $mars_dir/text_array.scp
    
    find -L $text_clean_dir -iname "*.txt" >  $mars_dir/text_array2mars.flist
    
    while read text_file
    do
        file=`echo $text_file |awk '{split($0,lst,"/"); utt1=lst[5];print(utt1)}'`
        file=`echo $file |awk -F"." '{print($1)}'`
        #echo $file
        python local/text2textgrid.py --speaker_limit=False  --in_path=$text_file --out_path=$text_mars_dir/${file}.TextGrid
    done < $mars_dir/text_array2mars.flist
    
    find -L $pwd_path/$text_mars_dir -iname "*.TextGrid" >  $mars_dir/textgrid.flist

    python local/alimeeting_process_textgrid.py --path $mars_dir --no-overlap $no_overlap --mars True
    cat $mars_dir/text_all | local/text_normalize.pl | local/text_format.pl | sort -u > $mars_dir/text
    utils/filter_scp.pl -f 1 $mars_dir/text $mars_dir/utt2spk_all | sort -u > $mars_dir/utt2spk
    utils/utt2spk_to_spk2utt.pl $mars_dir/utt2spk > $mars_dir/spk2utt
    utils/filter_scp.pl -f 1 $mars_dir/text $mars_dir/segments_all | sort -u > $mars_dir/segments
fi


if [ ${stage} -le 8 ] && [ ${stop_stage} -ge 8 ]; then
    log "stage 8: finali data process"

    utils/copy_data_dir.sh --utt-prefix alimeeting- --spk-prefix alimeeting- \
        $array_dir data/alimeeting_${tgt}_array
    utils/copy_data_dir.sh --utt-prefix alimeeting- --spk-prefix alimeeting- \
        $mars_dir data/alimeeting_${tgt}_mars
    # remove space in text
    #for x in alimeeting_${tgt}_array alimeeting_${tgt}_mars; do
    for x in alimeeting_${tgt}_array alimeeting_${tgt}_mars; do
        cp data/${x}/text data/${x}/text.org
        paste -d " " <(cut -f 1 -d" " data/${x}/text.org) <(cut -f 2- -d" " data/${x}/text.org | tr -d " ") \
        > data/${x}/text
        rm data/${x}/text.org
    done

    log "Successfully finished. [elapsed=${SECONDS}s]"
fi

