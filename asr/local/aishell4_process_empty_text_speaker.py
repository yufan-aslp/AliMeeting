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



def get_args():
    parser = argparse.ArgumentParser(description="process the textgrid files")
    parser.add_argument("--path", type=str, required=True, help="Data path")
    args = parser.parse_args()
    return args

def main(args):
    text = codecs.open(Path(args.path) / "text_process", "r", "utf-8")
    utt2spk_merge = codecs.open(Path(args.path) / "utt2spk_merge_process", "r", "utf-8")

    text_file_new = codecs.open(Path(args.path) / "text_new", "w", "utf-8")
    utt2spk_file_new = codecs.open(Path(args.path) / "utt2spk_merge_new", "w", "utf-8")

    all_segments = []
    for line1,line2 in zip(text,utt2spk_merge):
        uttid1 = line1.strip().split(" ")[0]
        uttid2 = line2.strip().split(" ")[0]
        assert uttid1 == uttid2
        context1 = line1.strip().split(" ")[1].split("$")
        context2 = line2.strip().split(" ")[1].split("$")
        assert len(context1) == len(context2)
        text_file_new.write("%s " % (uttid1))
        utt2spk_file_new.write("%s " % (uttid2))
        for i in range(len(context1)):
            if context1[i]!="":
                text_file_new.write("SRC%s" % (context1[i]))
                utt2spk_file_new.write("SRC%s" % (context2[i]))
        text_file_new.write("\n")
        utt2spk_file_new.write("\n")
    text.close()
    utt2spk_merge.close()
    utt2spk_file_new.close()
    text_file_new.close()

if __name__ == "__main__":
    args = get_args()
    main(args)
