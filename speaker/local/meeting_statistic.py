# encoding=utf-8

# Author: Zhihao Du
# Date:   2021.07.27
# To use this script, you must prepare rttm.scp including a rttm file in each line
# Note 1: The rttm file has the following format:
# SPEAKER <meeting_id> <NotUsed> <start> <duration> NA NA <local_speaker_id> NA NA


import numpy as np
from multiprocessing import Pool
import argparse
from tqdm import tqdm
import sys
import pdb

#reload(sys)
#sys.setdefaultencoding("utf-8")


class MultiProcessRunner:
    def __init__(self, fn):
        self.args = None
        self.process = fn

    def run(self):
        parser = argparse.ArgumentParser("")
        # Task-independent options
        parser.add_argument("--nj", type=int, default=16)
        parser.add_argument("--debug", action="store_true", default=False)
        parser.add_argument("--no_pbar", action="store_true", default=False)

        task_list, args = self.prepare(parser)
        result_list = self.pool_run(task_list, args)
        self.post(result_list, args)

    def prepare(self, parser):
        raise NotImplementedError("Please implement the prepare function.")

    def post(self, result_list, args):
        raise NotImplementedError("Please implement the post function.")

    def pool_run(self, tasks, args):
        results = []
        if args.debug:
            one_result = self.process(tasks[0])
            results.append(one_result)
        else:
            pool = Pool(args.nj)
            for one_result in tqdm(pool.imap(self.process, tasks), total=len(tasks), ascii=True, disable=args.no_pbar):
                results.append(one_result)
            pool.close()

        return results


class MyRunner(MultiProcessRunner):
    def prepare(self, parser):
        parser.add_argument("--rttm_scp", type=str, default=None)
        args = parser.parse_args()
        scp = open(args.rttm_scp, 'r')
        task_list = scp.readlines()
        return task_list, args

    def post(self, result_list, args):
        avg_ratio = np.zeros(5, dtype=np.float)
        for one_result in result_list:
            for mid, (count, total) in one_result:
                ratio = 1.0 * count / total * 100.0
                print("{} {}".format(mid, " ".join(["{:.2f}".format(x) for x in ratio[1:]])))
                avg_ratio += ratio
        avg_ratio /= len(result_list)
        print("Avg {}".format(" ".join(["{:.2f}".format(x) for x in avg_ratio][1:])))


def statistic(spk_list, turn_list):
    length = 0
    for _, start, dur in turn_list:
        if start + dur > length:
            length = start + dur
    olp_label = np.zeros((len(spk_list), int(length/0.01)), dtype=np.int)
    for spk_id, start, dur in turn_list:
        idx = spk_list.index(spk_id)
        olp_label[idx, int(start/0.01): int((start+dur)/0.01)] = 1
    count = np.zeros(5, dtype=np.int)
    spk_count = np.repeat(np.sum(olp_label, axis=0, keepdims=True), len(spk_list), axis=0)
    count[1] = np.sum(np.logical_and(olp_label == 1, spk_count == 1))
    total = np.sum(olp_label)
    for i in range(2, 5):
        count[i] = np.sum(np.logical_and(olp_label == 1, spk_count >= i))
    return count, total


def process(rttm_file):
    meetings = {}
    with open(rttm_file.strip(), 'r') as f:
        for one_line in f:
            info_list = one_line.strip().split(' ')
            mid = info_list[1]
            if mid not in meetings:
                meetings[mid] = {"turn_list": [], "spk_list": []}
            spk_id, start, dur = info_list[-3], float(info_list[3]), float(info_list[4])
            meetings[mid]["turn_list"].append([spk_id, start, dur])
            if spk_id not in meetings[mid]["spk_list"]:
                meetings[mid]["spk_list"].append(spk_id)
    results = []
    for mid, meet in meetings.items():
        results.append((mid, statistic(meet["spk_list"], meet["turn_list"])))

    return results


def test():
    spk_list = ["1", "2", "3"]
    turn_list = [
        ("1", 0.01, 0.05),
        ("2", 0.03, 0.05),
        ("3", 0.04, 0.05),
    ]
    print(statistic(spk_list, turn_list))


if __name__ == '__main__':
    #test()
    runner = MyRunner(process)
    runner.run()
