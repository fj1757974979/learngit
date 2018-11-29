#!/usr/bin/python
#-*- coding:utf8 -*-
import conf
import sys
import os

if __name__ == "__main__":
	if len(sys.argv) == 2:
		if sys.argv[1] == "--test":	
			version = conf.get_version("test")
			print(">>>> sync channel test version = %s" % version)
			os.system('''curl -XPOST -d'{"version":"%s"}' kxqp.test.openew.cn:7892/client_config?channel_id=test''' % version)
		exit(1)
	channels = conf.get_channels()
	for channel in channels:
		version = conf.get_version(channel)
		print(">>>> sync channel %s version = %s" % (channel, version))
		if channel != "test":
			os.system('''curl -XPOST -d'{"version":"%s"}' kxqp.src.openew.cn:8892/client_config?channel_id=%s''' % (version, channel))
	print(">>>> sync channels version done")
