# Speaker Diarization


## Usage

For the speaker diarzation track, only the first channel of waves will be used.


**The main stage:**

1. We use the implementation of Kaldi toolkits. Please install the Kaldi toolkits and conduct ` ln -s /export/kaldi/utils/ utils` and ` ln -s /export/kaldi/step/ step`.
2. Stage 1 is for the data preparation and stage 2 is for the voice detect activity (VAD).
3. When using the `VBx` toolkits for diarization, please convert the segments file to `.lab`. Use ` scripts/segment_to_lab.sh` to change the file format.
4. The speaker diarization consists of speaker embedding extraction and speaker embedding clustering. In our baseline system, the `VBx` toolkit is used to extract the speaker embeddings.
5. For the speaker-embedding cluster, the code will get the hypothesis rttm for each audio in the wav.scp.
6. We obtain the reference rttm through the ground truth transcripts.
7. We use toolkits `dscore` to get the DER results.


## Pre-traiend Model Download

Download the model from the [path](https://speech-lab-share-data.oss-cn-shanghai.aliyuncs.com/AliMeeting/speaker_part.tgz). Then, move the `exp` directory to our `speaker` directory and move the ` ResNet101_16kHz` to ` speaker/VBx/models`.



## Reference
1. [kaldi-sad-model](http://kaldi-asr.org/models/m12)
2. [VBx](https://github.com/BUTSpeechFIT/VBx)
3. [dscore](https://github.com/nryant/dscore.git)

