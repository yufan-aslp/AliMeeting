# AliMeeting


The project is associated with the recently-launched ICASSP 2022 Multi-channel Multi-party Meeting Transcription Challenge (M2MeT) to provide participants with baseline systems for speech recognition and speaker diarization in conference scenario. The project, served as baseline, is divided into two parts, named ***speaker*** and ***asr***. A detailed description of each system is in their respective README.md. The goal of this project is to simplify the training and evaluation procedure and make it easy and flexible for participants to carry out experiments and verify neural network based methods.

## Setup

```shell
git clone https://github.com/XXXX
```
## Introduction

* [ASR](asr): Train and evaluate the asr model. 
* [Speaker Diarization](sd): Generate the speaker diarization results. 

## General steps
1. Generate training data for speaker diarization and asr model and evaluation data for both track.
2. Do speaker diarization to generate rttm which includes vad and speaker diarization information, and then generate DER results.
3. Train single-speaker and multi-speaker ASR model respectively.
4. Generate CER results for both ASR models.




## Citation
If you use AliMeeting dataset and baseline system of M2MeT Challenge in a publication, please cite the following paper:

    @article{fyu,
    }
The paper is available at https://arxiv.org/abs/
Dataset is available at http://www.openslr.org// and http://

## Contributors

## Code license 

[Apache 2.0](./LICENSE)

