#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
import sys
import os
import json
import random

all_dirs = {"HandJoy":"https://client.dny.lzd.openew.com/king_war_google/"}
work_dir = "./.updat_res_dir"
target_dir = ""
rand_num = random.randint(0, 1000000)
cur_channel = ""

def prepare():
	global target_dir
	target_dir = "projects/x5launcher/src/%s/assets" % sys.argv[1]
	os.system("rm -rf %s/*" % target_dir)
	os.system("mkdir %s/js" % target_dir)
	os.system("mkdir %s/resource" % target_dir)
	os.system("mkdir %s" % work_dir)

def done():
	os.system("rm -rf %s" % work_dir)

def pull_js_files():
	http_root = all_dirs[cur_channel]
	os.system("mkdir -r %s/js" % target_dir)
	command = "curl %s/manifest.json?v=%d > %s/manifest.json" % (http_root, rand_num, work_dir)
	os.system(command)
	f = open("%s/manifest.json" % work_dir)
	content = f.read()
	f.close()
	data = json.loads(content)
	game_js_list = list(set(data["game"]) | set(data["initial"]))
	for js_path in game_js_list:
		name = js_path.split("/")[1].split("?")[0]
		tar_js_path = "%s/js/%s" % (target_dir, name)
		cmd = "curl %s/%s?v=%d > %s" % (http_root, js_path, rand_num, tar_js_path)
		os.system(cmd)
	version = data["version"]
	os.system('echo "%s" > %s/version.ini' % (version, target_dir))
	os.system("rm -rf %s" % work_dir)

def copy_resources():
	os.system("cp -r resource/* %s/resource" % target_dir)
	os.system("rm %s/resource/serverlist.json" % target_dir)
	os.system("rm %s/resource/wxconfig.json" % target_dir)
	os.system("rm %s/resource/king_ui/fui/*.png" % target_dir)
	os.system("rm %s/resource/king_ui/fui/*.mp3" % target_dir)
	os.system("rm %s/resource/king_ui/exclude.list" % target_dir)
	os.system("rm %s/resource/king_ui/king_ui.fairy" % target_dir)
	os.system("rm -rf %s/resource/king_ui/logs" % target_dir)
	os.system("rm -rf %s/resource/king_ui/settings" % target_dir)
	os.system("rm %s/resource/king_ui/sync_resource.py" % target_dir)

def _gen_file_list(dirname):
	paths = os.listdir(dirname)
	print "_gen_file_list path: %s, content: %s" % (dirname, str(paths))
	for path in paths:
		_path = os.path.join(dirname, path)
		if path.find(".") == 0:
			os.system("rm -rf %s" % _path)
			continue
		if os.path.isdir(_path):
			if dirname == ".":
				_gen_file_list(path)
			else:
				_gen_file_list(_path)
		else:
			if dirname == ".":
				os.system("echo %s >> files.ini" % path)
			else:
				os.system("echo %s/%s >> files.ini" % (dirname, path))

def gen_file_list():
	cur_dir = os.curdir
	os.chdir(target_dir)
	os.system("touch files.ini")
	_gen_file_list(".")
	os.chdir(cur_dir)

if __name__ == "__main__":
	flavorDir = sys.argv[1]
	if not flavorDir in all_dirs:
		print "supported args: " + str(all_dirs)
	else:
		global cur_channel
		cur_channel = flavorDir
		prepare()
		pull_js_files()
		copy_resources()
		gen_file_list()
		done()

