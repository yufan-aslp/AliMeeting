# Automatic Speech Recognition (ASR)



## Usage

For ASR track, we provide two baseline systems includes single-speaker and multi-speaker ASR. For single-speaker, please run all steps in `./run_local_conformer_near_alimeeting.sh`, while `./run_local_multispeaker_conformer_alimenting.sh` is used for the multi-speaker ASR.


**The main stage:**

1. We use the implementation of Conformer ASR model in the ESPnet2. Please install the latest ESPnet toolkit and copy our all files to the `espnet/egs2/AliMeeting/asr`.
2. Both data preparation, language model training, and ASR model training are included in `asr_local.sh`.
3. First, please run `./run_local_conformer_near_alimeeting.sh` to train the single-speaker ASR model. Then, run `run_local_multispeaker_conformer_alimeeting.sh` to train the multi-speaker ASR model. Please note that you don’t need to repeat the data preparation procedure in the multi-speaker ASR training, since all the preparation will be done in the first training.




## Reference
1. [ESPnet](https://github.com/espnet/espnet.git)
2. [VBx](https://github.com/BUTSpeechFIT/VBx)

