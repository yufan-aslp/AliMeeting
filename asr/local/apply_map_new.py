import codecs
import sys

dict = sys.argv[1]
input = sys.argv[2]
output = sys.argv[3]
unk = sys.argv[4]
warning = sys.argv[5]
unit_name = sys.argv[6]

map = {}
units = []

with codecs.open(dict, 'r', encoding='utf-8') as f1:
    for line in f1:
        if len(line.split('\t')) > 1:
            word = line.split('\t')[0]
            tokens = line.rstrip('\n').split('\t')[1]
        else:
            word = line.split(' ')[0]
            tokens = line.rstrip('\n').split(' ')[1]
        map[word] = tokens

with codecs.open(input, 'r', encoding='utf-8') as f2:
    with codecs.open(output, 'w', encoding='utf-8') as f3 ,codecs.open(warning, 'w', encoding='utf-8') as f4:
        for line in f2:
            if len(line.split('\t')) > 1:
                head = line.split('\t')[0]
                sentence = line.rstrip('\n').split('\t')[1].split(' ')
            else:
                head = line.split(' ')[0]
                sentence = line.rstrip('\n').split(' ')[1:]
            result = head + '\t'
            for word in sentence:
                if len(word):
                    if word in map:
                        result += map[word] + ' '
                        for unit in map[word].split(' '):
                            if unit not in units:
                                units.append(unit)
                    else:
                        f4.write(word + '\n')
                        result += unk + ' '
            f3.write(result.rstrip(' ').lstrip(' ') + '\n')

list.sort(units)
units.insert(0, '<unk>')
with codecs.open(unit_name, 'w', encoding='utf-8') as f5:
    for i in range(len(units)):
       f5.write(str(units[i]) + ' ' + str(i+1)+'\n')
