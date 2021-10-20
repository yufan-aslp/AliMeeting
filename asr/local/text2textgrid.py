# -*- coding: utf-8 -*-
"""
Process the textgrid files
"""
import argparse
import codecs
from distutils.util import strtobool
from pathlib import Path
import textgrid
import pdb

class Segment(object):
    def __init__(self, uttid, spkr, stime, etime, text):
        self.uttid = uttid
        self.spkr = spkr
        self.stime = round(stime, 2)
        self.etime = round(etime, 2)
        self.text = text

    def change_stime(self, time):
        self.stime = time

    def change_etime(self, time):
        self.etime = time


def get_args():
    parser = argparse.ArgumentParser(description="process the textgrid files")
    parser.add_argument("--in_path", type=str, required=True, help="Text input path")
    parser.add_argument("--out_path", type=str, required=True, help="Text output path")
    parser.add_argument("--speaker_limit", type=strtobool, default=True, help="speaker is only c1")
    args = parser.parse_args()
    return args


def main(args):
    text = codecs.open(Path(args.in_path), "r", "utf-8")
    #text_uttid = args.uttid
    # get the path of textgrid file for each utterance
    spk2textgrid = {}
    xmin = 0
    xmax = 0
    for line in text:
        uttlist = line.split()
        utt_id = uttlist[0]
        if utt_id == "编号" or utt_id == "文本":
            continue
        utt_text = uttlist[1]
        utt_use = uttlist[2]
        #pdb.set_trace()
        utt_time_s, utt_time_e=uttlist[-1].strip('[').strip(']').split('][')
        if float(utt_time_s) < 0:
            raise ValueError(float(utt_time_s))
        if float(utt_time_e) < 0:
            raise ValueError(float(utt_time_e))

        if utt_use == "有效":
            utt_speaker = uttlist[3]
            if args.speaker_limit == True and (utt_speaker != "c1" and utt_speaker != "S1" and utt_speaker != "S2" and utt_speaker != "S3"):
                raise ValueError(str(utt_id)+" "+str(utt_speaker))
            if utt_speaker not in spk2textgrid:
                spk2textgrid[utt_speaker] = []
            xmax = max(xmax,float(utt_time_e))
            spk2textgrid[utt_speaker].append(
                Segment(
                    utt_id,
                    utt_speaker,
                    float(utt_time_s),
                    float(utt_time_e),
                    utt_text.strip(),
                )
            )
    text.close()
    #pdb.set_trace()
    #for segments in spk2textgrid.keys():
    #    spk2textgrid[segments] = sorted(spk2textgrid[segments], key=lambda x: x.stime)
    xmax=xmax+0.01
    textgrid = codecs.open(Path(args.out_path), "w", "utf-8")
    textgrid.write("File type = \"ooTextFile\"\n")
    textgrid.write("Object class = \"TextGrid\"\n\n")

    textgrid.write("xmin = %s\n" % (xmin))
    textgrid.write("xmax = %s\n" % (xmax))
    textgrid.write("tiers? <exists>\n")
    textgrid.write("size = %s\n" % (len(spk2textgrid)))
    textgrid.write("item []:\n")
    num_spk = 1
    for segments in spk2textgrid.keys():
        textgrid.write("\titem [%s]:\n" % (num_spk))
        num_spk = num_spk + 1
        textgrid.write("\t\tclass = \"IntervalTier\"\n")
        textgrid.write("\t\tname = \"%s\"\n" % spk2textgrid[segments][0].spkr)
        textgrid.write("\t\txmin = %s\n" % (xmin))
        textgrid.write("\t\txmax = %s\n" % (xmax))
        textgrid.write("\t\tintervals: size = %s\n" % (len(spk2textgrid[segments])))
        #pdb.set_trace()
        for i in range(len(spk2textgrid[segments])):
            #spk2textgrid[segments][i]
            #pdb.set_trace()
            textgrid.write("\t\tintervals [%s]:\n" % (i+1))
            textgrid.write("\t\t\txmin = %s\n" % (spk2textgrid[segments][i].stime))
            textgrid.write("\t\t\txmax = %s\n" % (spk2textgrid[segments][i].etime))
            textgrid.write("\t\t\ttext = \"%s\"\n" % (spk2textgrid[segments][i].text))
            #textgrid.write("%s %s %s %s %s \n" % (spk2textgrid[segments][i].uttid, spk2textgrid[segments][i].spkr,spk2textgrid[segments][i].stime,
            #spk2textgrid[segments][i].etime,spk2textgrid[segments][i].text))
    textgrid.close()


if __name__ == "__main__":
    args = get_args()
    main(args)
