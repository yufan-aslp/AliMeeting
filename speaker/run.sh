. path.sh
. cmd.sh
# cur_dir/data/work_dir is the main work folder


# data path
textgrid_dir=/export/Eval_Ali_far/textgrid_dir
wav_dir=/export/Eval_Ali_far/audio_dir
# work path
work_dir=./data/Eval_Ali_far
sad_dir=$work_dir/sad_part
sad_work_dir=$sad_dir/exp
sad_result_dir=$sad_dir/sad
dia_dir=$work_dir/dia_part
dia_vad_dir=$dia_dir/vad
dia_rttm_dir=$dia_dir/rttm
dia_emb_dir=$dia_dir/embedding
dia_rtt_label_dir=$dia_dir/label_rttm
dia_result_dir=$dia_dir/result_DER

mkdir -p $work_dir || exit 1;
mkdir -p $sad_dir || exit 1;
mkdir -p $sad_work_dir || exit 1;
mkdir -p $sad_result_dir || exit 1;
mkdir -p $dia_dir || exit 1;
mkdir -p $dia_vad_dir || exit 1;
mkdir -p $dia_rttm_dir || exit 1;
mkdir -p $dia_emb_dir || exit 1;
mkdir -p $dia_rtt_label_dir || exit 1;
mkdir -p $dia_result_dir || exit 1;

stage=1
stop_stage=8
nj=4

if [ $stage -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    # Prepare the AliMeeting data
    echo "Prepare Alimeeting data"
    find $wav_dir -name "*\.wav" > $work_dir/wavlist
    sort  $work_dir/wavlist > $work_dir/tmp
    cp $work_dir/tmp $work_dir/wavlist
    awk -F '/' '{print $NF}' $work_dir/wavlist | awk -F '.' '{print $1}' > $work_dir/uttid
    paste $work_dir/uttid $work_dir/wavlist > $work_dir/wav.scp 
    paste $work_dir/uttid $work_dir/uttid > $work_dir/utt2spk
    cp $work_dir/utt2spk $work_dir/spk2utt
    cp $work_dir/uttid $work_dir/text

    sad_feat=$sad_dir/feat/mfcc
    cp $work_dir/wav.scp $sad_dir
    cp $work_dir/utt2spk $sad_dir
    cp $work_dir/spk2utt $sad_dir
    cp $work_dir/text    $sad_dir

    utils/fix_data_dir.sh $sad_dir

    ## first we extract the feature for sad model
    steps/make_mfcc.sh --nj $nj --cmd "$train_cmd" \
        --mfcc-config conf/mfcc_hires.conf \
        $sad_dir $sad_dir/make_mfcc $sad_feat
fi

if [ $stage -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    # Do Speech Activity Detectation
    echo "Do SAD"
    ./utils/split_data.sh $sad_dir $nj
    ## do the segmentations
    local/segmentation/detect_speech_activity.sh --nj $nj --stage 0 \
        --cmd "$train_cmd" $sad_dir exp/segmentation_1a/tdnn_stats_sad_1a/ \
        $sad_dir/feat/mfcc $sad_work_dir $sad_result_dir
fi
if [ $stage -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    # The Speaker Embedding Extractor
    # The VBx tools need a special sad result, so convert the segments file to that format
    echo "Do Speaker Embedding Extractor"
    cp $work_dir/wav.scp $dia_dir

    python scripts/segment_to_lab.py --input_segments $sad_dir/sad_seg/segments \
                                     --label_path $dia_vad_dir \
                                     --output_label_scp_file $dia_dir/label.scp ||exit 1;

    ./utils/split_data.sh $work_dir $nj
    ${train_cmd} JOB=1:${nj} $dia_dir/exp/extract_embedding.JOB.log \
    python VBx/predict.py --in-file-list $work_dir/split${nj}/JOB/text \
                          --in-lab-dir $dia_dir/vad \
                          --in-wav-dir $wav_dir \
                          --out-ark-fn $dia_dir/embedding/embedding_out.JOB.ark \
                          --out-seg-fn $dia_dir/embedding/embedding_out.JOB.seg \
                          --weights VBx/models/ResNet101_16kHz/nnet/final.onnx \
                          --backend onnx

    echo "success"
    
fi
if [ $stage -le 4 ] && [ ${stop_stage} -ge 4 ]; then
    # The Speaker Embedding Cluster
    echo "Do the Speaker Embedding Cluster"
    # The meeting data is long so that the cluster is a little bit slow
    ${train_cmd} JOB=1:${nj} $dia_dir/exp/cluster.JOB.log \
     python VBx/vbhmm.py --init AHC+VB \
                         --out-rttm-dir $dia_dir/rttm \
                         --xvec-ark-file $dia_dir/embedding/embedding_out.JOB.ark \
                         --segments-file $dia_dir/embedding/embedding_out.JOB.seg \
                         --xvec-transform VBx/models/ResNet101_16kHz/transform.h5 \
                         --plda-file VBx/models/ResNet101_16kHz/plda \
                         --threshold -0.015 \
                         --lda-dim 128 \
                         --Fa 0.3 \
                         --Fb 17 \
                         --loopP 0.99
fi

if [ $stage -le 5 ] && [ ${stop_stage} -ge 5 ]; then
    echo "Process textgrid to obtain rttm label"
    find -L $textgrid_dir -iname "*.TextGrid" >  $work_dir/textgrid.flist
    sort  $work_dir/textgrid.flist  > $work_dir/tmp
    cp $work_dir/tmp $work_dir/textgrid.flist 
    paste $work_dir/uttid $work_dir/textgrid.flist > $work_dir/uttid_textgrid.flist
    while read text_file
    do
        text_grid=`echo $text_file | awk '{print $1}'`
        text_grid_path=`echo $text_file | awk '{print $2}'`
        python local/make_textgrid_rttm.py --input_textgrid_file $text_grid_path \
                                           --uttid $text_grid \
                                           --output_rttm_file $dia_rtt_label_dir/${text_grid}.rttm
    done < $work_dir/uttid_textgrid.flist
fi



if [ $stage -le 6 ] && [ $stop_stage -ge 6 ]; then
    echo "Get DER result"
    pwd_path=`pwd`
    find $pwd_path/$dia_rtt_label_dir  -name "*.rttm" > $dia_rtt_label_dir/ref.scp
    find $pwd_path/$dia_dir/rttm  -name "*.rttm" > $dia_dir/rttm/sys.scp
    collar_set="0 0.25"
    python local/meeting_speaker_number_process.py  --path=$work_dir \
        --label_path=$dia_rtt_label_dir   --predict_path=$dia_dir/rttm
    speaker_number="2 3 4"
    for weight_collar in $collar_set;
    do
        # all meeting 
        python dscore/score.py --collar $weight_collar  \
            -R $dia_rtt_label_dir/ref.scp  -S $dia_dir/rttm/sys.scp > $dia_result_dir/speaker_all_DER_overlaps_${weight_collar}.log
        # 2,3,4 speaker meeting
        for speaker_count in $speaker_number;
        do
            python dscore/score.py --collar $weight_collar  \
                -R $dia_rtt_label_dir/speaker${speaker_count}_id  -S $dia_dir/rttm/speaker${speaker_count}_id > $dia_result_dir/speaker_${speaker_count}_DER_overlaps_${weight_collar}.log
        done
    done

fi


if [ $stage -le 7 ] && [ $stop_stage -ge 7 ]; then
    echo "overlap ratio"
    python local/meeting_statistic.py --rttm_scp $dia_rtt_label_dir/ref.scp >$dia_result_dir/ratio_speaker_all
    speaker_number="2 3 4"
    for speaker_count in $speaker_number;
    do
        python local/meeting_statistic.py --rttm_scp $dia_rtt_label_dir/speaker${speaker_count}_id >$dia_result_dir/ratio_speak${speaker_count}
    done
fi
