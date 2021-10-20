
# The tools need you to change the kaldi root by yourself
#export KALDI_ROOT=/home/work_nfs/common/kaldi-20190604-cuda10

work_path=$1
wav_dir=$2
while read text_file
do
    audio=`echo $text_file | awk '{print $1}'`
    audio_path=`echo $text_file | awk '{print $2}'`
    mv   $audio_path $wav_dir/${audio}.wav
done < $work_path/wav.scp

