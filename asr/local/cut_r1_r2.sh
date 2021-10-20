dir=$1

mkdir -p $dir/R1_R2/

grep "R1" $dir/wav.scp > $dir/R1_R2/wav.scp
grep "R2" $dir/wav.scp >> $dir/R1_R2/wav.scp

cp $dir/text $dir/R1_R2/text 
cp $dir/utt2spk $dir/R1_R2/utt2spk
cp $dir/spk2utt $dir/R1_R2/spk2utt

./utils/fix_data_dir.sh $dir/R1_R2
