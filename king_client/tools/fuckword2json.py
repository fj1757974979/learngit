#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2018 Register <registerdedicated(at)gmail.com>
#
# Distributed under terms of the GPLv3 license.

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

import json
import codecs
import xlrd

def fuck_it():
    book = xlrd.open_workbook("fuck_word.xlsx")
    sheet = book.sheets()[0]
    all_words = sheet.col_values(0)
    all_words_set = {}
    for word in all_words:
        all_words_set[word] = True
    all_words = all_words_set.keys()
    for i, word in enumerate(all_words):
        all_words[i] = str(word)
    f = codecs.open("resource/dirty_words.json", "w", "utf-8")
    f.write( json.dumps(all_words, ensure_ascii=False, sort_keys=True, separators=(',', ':')) )
    f.close()

if __name__ == "__main__":
    fuck_it()

