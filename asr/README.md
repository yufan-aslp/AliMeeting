# asr



## Usage
In ASR Track, We will provide a baseline system for single speaker and multi speaker ASR.

> You can find all the process in `ASR/run_local_conformer_near_alimeeting.sh` (Singele-Speaker ASR) and `run_local_multispeaker_conformer_alimeeting.sh` (Multi-Speaker ASR), and the comments in them.



**Here is the main stage:**

1. We use the Conformer ASR on ESPnet2. So you need to install the latest espnet, and then move our `asr` dir to the `espnet/egs2/you_dir/`.
2. Data preparation, LM trainging, ASR training and ASR decoder are all in asr_local.sh. We mainly updated the script for data preparation (`./local/alimeeting_data_prep.sh`) in the first step.
3. First, you should run `ASR/run_local_conformer_near_alimeeting.sh` to train the single speaker ASR model. And then run `run_local_multispeaker_conformer_alimeeting.sh` to train the multi speaker ASR model. It is worth noting that do not repeat the data preparation of the first step in `./local/alimeeting_data_prep.sh`,  it will prepare all the data at one time.




## Reference
1. [ESPnet](https://github.com/espnet/espnet.git)
2. [VBx](https://github.com/BUTSpeechFIT/VBx)

