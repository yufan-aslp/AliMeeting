# AliMeeting Speaker Diarization


## Usage
In speaker diarization process, we will only use the first channel as the SAD model and the Speaker-Embedding-Extrator do not support the multi-channel wav.

> You can find all the process in `speaker/run.sh` and the comments in it.



**Here is the main stage:**
1. we use kaldi tool, `ln -s /export/kaldi/utils/ utils` and `ln -s /export/kaldi/step/ step`
2. Stage 1 is to prepare AliMeeting data.
3. Stage 2 is to do VAD, which using the script `local/segmentation/detect_speech_activity.sh`.
4. When use the `VBx` tools for the diarization, you should convert the segments to the `.lab`. Use `scripts/segment_to_lab.sh` to change the file format.
5. The speaker diarization code needs two stage the speaker-embedding extract and the speaker-embedding cluster. Our baseline use the `VBx` tools to extract speaker-embeddings. The feature-extractor is inside, you don't have to prepare the feature before.
6. For the speaker-embedding cluster, the code will make the rttm for each audio in the wav.scp.
7. In step 5, we obtain the target rttm through the ground truth transcripts.
8. In step 6, we use tools `dscore` to get the DER results.




## Model Downloads

You need download the model from the [path](https://speech-lab-share-data.oss-cn-shanghai.aliyuncs.com/AliMeeting/speaker_part.tgz), you should mv the `exp` to our `speaker` dir and the `ResNet101_16kHz` to the `speaker/VBx/models`.




## Reference
1. [kaldi-sad-model](http://kaldi-asr.org/models/m12)
2. [VBx](https://github.com/BUTSpeechFIT/VBx)
3. [dscore](https://github.com/nryant/dscore.git)

