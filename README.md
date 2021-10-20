# AliMeeting


The project is associated with the recently-launched ICASSP 2022 Multi-channel Multi-party Meeting Transcription Challenge (M2MeT) to provide participants with baseline systems for speech recognition and speaker diarization in conference scenario. The project, served as baseline, is divided into two parts, named ***speaker*** and ***asr***. A detailed description of each system is in their respective README.md. The goal of this project is to simplify the training and evaluation procedure and make it easy and flexible for participants to carry out experiments and verify neural network based methods.

## Setup

```shell
git clone https://github.com/qq379840315/AliMeeting.git
```
## Introduction

* [ASR](asr): Train and evaluate the asr model. 
* [Speaker Diarization](speaker): Generate the speaker diarization results. 

## General steps
1. Generate training data for speaker diarization and asr model and evaluation data for both track.
2. Do speaker diarization to generate rttm which includes vad and speaker diarization information, and then generate DER results.
3. Train single-speaker and multi-speaker ASR model respectively.
4. Generate CER results for both ASR models.




## Citation
If you use AliMeeting dataset and baseline system of M2MeT Challenge in a publication, please cite the following paper:

    @article{yu2021m2met,
    title={M2MeT: The ICASSP 2022 Multi-Channel Multi-Party Meeting Transcription Challenge},
    author={Yu, Fan and Zhang, Shiliang and Fu, Yihui and Xie, Lei and Zheng, Siqi and Du, Zhihao and Huang, Weilong and Guo, Pengcheng and Yan, Zhijie and Ma, Bin and others},
    journal={arXiv preprint arXiv:2110.07393},
    year={2021}
    }
The paper is available at https://arxiv.org/abs/2110.07393

The data will be sent to all challenge participants through email.

## Contributors

[<img width="300" height="100" src="https://github.com/qq379840315/AliMeeting/main/fig_aishell.jpg"/>](http://www.aishelltech.com/sy)


## Code license 

[Apache 2.0](./LICENSE)

