#!/usr/bin/python
#-*- coding:utf8 -*-
import conf
import os

if __name__ == "__main__":
	channels = conf.get_channels()
	for channel in channels:
		print(">>>> begin pack for %s" % channel)
		os.system("python pack/pack_res.py android %s --gen-package" % channel)
		print(">>>> pack %s done" % channel)
	print(">>>> pack all done")
