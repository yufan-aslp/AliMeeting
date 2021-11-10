# AliMeeting


This project provides the baseline system recipes for the ICASSP 2020 Multi-channel Multi-party Meeting Transcription Challenge (M2MeT). The challenge mainly consists of two tracks, named automatic speech recognition (ASR)(***asr***) and speaker diarization(***speaker***). For each track, detailed descriptions can be found in its corresponding directory. The goal of this project is to simplify the training and evaluation procedures and make it flexible for participants to reproduce the baseline experiments and develop novelty methods.  


## Setup

```shell
git clone https://github.com/qq379840315/AliMeeting.git
```

## Introduction

* [Speech Recognition Track](asr): Follow the detailed steps in `./asr`. 
* [Speaker Diarization Track](speaker): Follow the detailed steps in `./speaker`. 

## General steps

1.Prepare the training data for speaker diarization and ASR model, respectively
2.Follow the running steps of the speaker diarization experiment and obtain the `rttm` file. The `rttm` file includes the voice activity detection (VAD) and speaker diarization results, which will be used to compute the final Diarization Error Rate (DER) scores.
3.For ASR track, we can train the single-speaker or multi-speaker ASR models. The evaluation metric of ASR systems is Character Error Rate (CER).




## Citation

If you use the challenge dataset or our baseline systems, please consider citing the following:

    @article{yu2021m2met,
    title={M2MeT: The ICASSP 2022 Multi-Channel Multi-Party Meeting Transcription Challenge},
    author={Yu, Fan and Zhang, Shiliang and Fu, Yihui and Xie, Lei and Zheng, Siqi and Du, Zhihao and Huang, Weilong and Guo, Pengcheng and Yan, Zhijie and Ma, Bin and others},
    journal={arXiv preprint arXiv:2110.07393},
    year={2021}
    }
    
Our paper is available at https://arxiv.org/abs/2110.07393

The data download method will be sent to registered challenge participants via email.

## Organizing Committee 
* Lei Xie, AISHELL Foundation, China, lxie@nwpu.edu.cn
* Bin Ma, Principal Engineer at Alibaba, Singapore, b.ma@alibaba-inc.com
* DeLiang Wang, Professor, Ohio State University, USA, dwang@cse.ohio-state.edu
* Zheng-Hua Tan, Professor, Aalborg University, Denmark, zt@es.aau.dk
* Kong Aik Lee, Senior Scientist, Institute for Infocomm Research, A*STAR, Singapore, kongaik.lee@ieee.org
* Zhijie Yan, Principal Engineer at Alibaba, China, zhijie.yzj@alibaba-inc.com
* Yanmin Qian, Associate Professor, Shanghai Jiao Tong University, China,
yanminqian@sjtu.edu.cn
* Hui Bu, CEO, AIShell Inc., China, buhui@aishelldata.com

## Contributors

[<img width="300" height="100" src="https://github.com/qq379840315/AliMeeting/blob/main/alibaba.png"/>](https://damo.alibaba.com/labs/speech/?lang=zh)[<img width="300" height="100" src="https://github.com/qq379840315/AliMeeting/blob/main/fig_aishell.jpg"/>](http://www.aishelltech.com/sy)


## Code license 

[Apache 2.0](./LICENSE)

