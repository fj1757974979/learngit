#!/usr/bin/python
#-*- coding:utf8 -*-
import json
import os
import sys
import conf

test_channels = ["test"]

def add_version(channel):
	path = ""
	if len(channel) > 0:
		path = "etc/version_%s.ini" % channel
	else:
		path = "etc/version.ini"
	if not os.path.exists(path):
		print("file %s not found" % path)
		exit()
	f = open(path, "r")
	content = f.read()
	f.close()
	print("modify version file [%s] [%s]" % (path, content))
	ver_data = json.loads(content)
	ver_str = ver_data["version"]
	ver_list = ver_str.split(".")
	last_ver = int(ver_list[2]) + 1
	ver_data["version"] = "%s.%s.%d" % (ver_list[0], ver_list[1], last_ver)
	new_content = json.dumps(ver_data)
	print("		--> %s" % new_content)
	f = open(path, "w")
	f.write(new_content)
	f.close()

def gen_filelist(channel):
	os.system("python pack/gen_filelist.py %s" % channel)
	os.system("tool/zipstr etc/files_%s etc/files_%s.z" % (channel, channel))

def sync_resource():
	os.system("./tool/assets") # 兼容老包
	os.system("sh tool/sync_res_ios.sh")
	os.system("sh tool/sync_res_android.sh")

def sync_versions():
	os.system("sh tool/sync_version_ios.sh")
	os.system("sh tool/sync_version_android.sh")

def sync_test_resource():
	os.system("./tool/assets") # 兼容老包
	os.system("sh tool/sync_res_ios_test.sh")
	os.system("sh tool/sync_res_android_test.sh")

def sync_test_versions():
	os.system("sh tool/sync_version_ios_test.sh")
	os.system("sh tool/sync_version_android_test.sh")

if __name__ == "__main__":
	if len(sys.argv) >= 2:
		if sys.argv[1] == "--test":
			for channel in test_channels:
				add_version(channel)
				gen_filelist(channel)
			sync_test_resource()
			sync_test_versions()
		else:
			channel = sys.argv[1]
			if channel == "test":
				print(">>>> if you want patch 'test' channel, use --test arg")
				exit()
			if conf.is_available_channel(channel):
				add_version(channel)
				gen_filelist(channel)
				sync_resource()
				sync_versions()
			else:
				print(">>>> invalid channel name %s" % channel)
				print(">>>> available as %s" % conf.get_channels())
	else:
		channels = conf.get_channels()
		for channel in channels:
			add_version(channel)
			gen_filelist(channel)
		add_version("")
		sync_resource()
		sync_versions()
