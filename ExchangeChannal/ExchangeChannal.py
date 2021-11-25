# coding:utf-8
import os
import sys
import wave
#import wavio
import numpy as np
import math

def _trivial__enter__(self):
		return self
	
def _self_close__exit__(self, exc_type, exc_value, traceback):
	self.close()

wave.Wave_read.__exit__ = wave.Wave_write.__exit__ = _self_close__exit__
wave.Wave_read.__enter__ = wave.Wave_write.__enter__ = _trivial__enter__

class ExchangeChannal:

	__wavInfo = {'waveRate':0, 'sampleWidth':0, 'channelCnt':0, 'nframes':0}

	def __init__(self, argv):
		print "__init__ ExchangeChannal"

	def __mergeWave(self, inputArray, outputFile):
		cmdline = "sox -M"
		for inputFile in inputArray :
			cmdline += " "
			cmdline += inputFile
		cmdline += " "
		cmdline += outputFile
		ret = os.system(cmdline)

		return ret

	def __removeTmpFile(self, inputArray):
		for inputFile in inputArray:
			os.remove(inputFile)

	def __splitChannel(self, inputFile, outputFile, channalID) :
		cmdline = ' '.join(("sox", inputFile, outputFile, "remix", str(channalID)))
		ret = os.system(cmdline)

		return ret

	def __exchange(self, strInFile, outDir, totalChannal, channalArray):
	    
		fileArray = []
		newChannalArray = []

		# with wave.open(strInFile) as wfile:
		# 	waveRate = wfile.getframerate()
		# 	sampleWidth = wfile.getsampwidth()
		# 	channelCnt = wfile.getnchannels()
		namearray = os.path.basename(strInFile).split('.')
		
		# File = wavio.read(strInFile)
		# print(File.data.shape)

		# for i in range(channelCnt) :
		# 	channel = File.data[:,i]
		# 	fileName = namearray[0] + "_ch_" + str(i+1) + ".wav"
		# 	wavio.write(fileName, channel, waveRate)
		# 	fileArray.append([fileName, 0])

		for i in range(totalChannal) :
			fileName = outDir + '/' + namearray[0] + "_ch_" + str(i+1) + ".wav"
			self.__splitChannel(strInFile, fileName, i+1)
			fileArray.append([fileName, 0])

		#print fileArray
		#print "\r\n"

		#print channalArray
		#print "\r\n"

		for i in range(len(channalArray)) :
			for j in range(totalChannal) :
				if fileArray[j][1] == 1 :
					continue
				if (j == channalArray[i] - 1) :
					#print 'get ' + str(j) + '\n'
					fileArray[j][1] = 1
					newChannalArray.append(fileArray[j][0])
					break

		outFile = outDir + '/' + namearray[0] + '.wav'
		self.__mergeWave(newChannalArray, outFile)

		self.__removeTmpFile(newChannalArray)

		#print newChannalArray

		return outFile

	def process(self, inputFile, outDir, totalChannal, channalArray):
		return self.__exchange(inputFile, outDir, totalChannal, channalArray)
	

usage = "python xxx.py input.wav channalcnt newchannals (example: xxx.py input.wav outDir 8 3 4 2 1 7 8 6 5)"

if __name__ == '__main__':
	__inputArray = []
	if len(sys.argv) < 5 :
		print usage
	tool = ExchangeChannal(sys.argv)
	for i in range(4, len(sys.argv)) :
		__inputArray.append(int(sys.argv[i]))
	tool.process(sys.argv[1], sys.argv[2], int(sys.argv[3]), __inputArray)

	exit(0)
