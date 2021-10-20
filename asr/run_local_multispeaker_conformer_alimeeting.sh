#!/usr/bin/env bash
# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

ngpu=2
device=4,5
#stage 1 creat both near and far
stage=7
stop_stage=12


train_set=Train_Ali_far
valid_set=Eval_Ali_far
test_sets="Test_Ali_far"
asr_config=conf/array/train_asr_conformer.yaml
inference_config=conf/decode_asr_rnn.yaml

lm_config=conf/train_lm_transformer.yaml
use_lm=true
use_wordlm=false
./asr_local.sh                                               \
    --device ${device}                                 \
    --ngpu ${ngpu}                                     \
    --stage ${stage}                                   \
    --stop_stage ${stop_stage}                         \
    --asr_exp exp/asr_train_asr_multispeaker_conformer_raw_zh_char_data_alimeeting \
    --asr_stats_dir exp/asr_stats_multispeaker_conformer_raw_zh_char_data_alimeeting    \
    --lm_exp exp/lm_train_lm_multispeaker_transformer_zh_char_data_alimeeting \
    --lm_stats_dir exp/lm_stats_multispeaker_zh_char_data_alimeeting \
    --lang zh                                          \
    --audio_format wav                                 \
    --feats_type raw                                   \
    --token_type char                                  \
    --use_lm ${use_lm}                                 \
    --use_word_lm ${use_wordlm}                        \
    --lm_config "${lm_config}"                         \
    --asr_config "${asr_config}"                       \
    --inference_config "${inference_config}"           \
    --train_set "${train_set}"                         \
    --valid_set "${valid_set}"                         \
    --test_sets "${test_sets}"                         \
    --asr_speech_fold_length 1024 \
    --asr_text_fold_length 600 \
    --lm_fold_length 600 \
    --lm_train_text "data/${train_set}/text" "$@"
