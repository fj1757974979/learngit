#!/usr/bin/python
#-*- coding:utf8 -*-
import os
import sys
import hashlib
import re
import json
import commands
import conf
import random

g_channels = []
g_gameids = []
g_channels_to_gameid = {}
g_need_channel_split_dir = []
g_poker_game_dir = []
g_all_poker_games = []
g_platforms = []

def init_env():
	global g_channels
	global g_gameids
	global g_need_channel_split_dir
	global g_poker_game_dir
	global g_all_poker_games
	global g_platforms
	g_channels = conf.get_channels()
	g_gameids = conf.get_gameids()
	g_need_channel_split_dir = conf.get_channel_split_dir()
	g_poker_game_dir = conf.get_poker_game_dir()
	g_all_poker_games = conf.get_all_poker_games()
	g_platforms = conf.get_platforms()
	for i in xrange(0, len(g_channels)):
		channel = g_channels[i]
		gameid = g_gameids[i]
		g_channels_to_gameid[channel] = gameid

def print_and_check_command_ret(status, output):
	print output
	ret = status >> 8
	if ret != 0:
		print("execute command fail")
		sys.exit()

def remove_prev_dir(platform):
	if platform == "ios":
		os.system("rm -rf ../nsg_res")
	elif platform == "android":
		os.system("rm -rf ../engine/android/assets/home")
		os.system("rm -rf ../engine/android/assets/*resource*")
		os.system("rm -rf ../engine/android/assets/config")
		os.system("rm -rf ../engine/android/assets/etc")
	os.system("rm -rf tmp/resource/*")
	os.system("rm -rf .build")

def new_res_dir(platform):
	if platform == "ios":
		os.system("mkdir -p ../nsg_res")
		os.system("mkdir -p ../nsg_res/home")
		os.system("mkdir -p ../nsg_res/resource")
		os.system("mkdir -p ../nsg_res/etc")
		os.system("mkdir -p tmp/resource/font")
	elif platform == "android":
		os.system("mkdir -p ../engine/android/assets")
		os.system("mkdir -p ../engine/android/assets/home/script")
		os.system("mkdir -p ../engine/android/assets/home/shader")
		os.system("mkdir -p ../engine/android/assets/resource/font")
		os.system("mkdir -p ../engine/android/assets/resource/icon")
		os.system("mkdir -p ../engine/android/assets/resource/ui")
		os.system("mkdir -p ../engine/android/assets/resource/effect")
		os.system("mkdir -p ../engine/android/assets/resource/music")
		os.system("mkdir -p ../engine/android/assets/resource/sound")
		os.system("mkdir -p ../engine/android/assets/etc")
	os.system("mkdir -p .build")

def build_script(platform):
	if platform == "ios":
		os.system("./tool/build_script_ios_armv7")
		os.system("./tool/build_script_ios_arm64")
		os.system("./tool/packpdb tmp/script tmp/script.pdb")
		os.system("./tool/packpdb tmp/script64 tmp/script64.pdb")
		os.system("./tool/packpdb home/shader/glsles tmp/shader.pdb")
	elif platform == "android":
		os.system("./tool/build_script_android")

def __filter_entry(entry):
	exclude_entry = [".", "..", ".git", ".svn", "Makefile", ".DS_Store", ".gitmodules", "Thumbs.db", ".gitignore"]
	if entry in exclude_entry:
		return False
	else:
		return True

def __handle_resource_dir(dir_name):
	print(">>> handle dir %s" % dir_name)
	os.system("mkdir -p .build/%s" % dir_name)
	entry_list = os.listdir(dir_name)
	for entry in entry_list:
		if not __filter_entry(entry):
			continue
		path = os.path.join(dir_name, entry)
		if os.path.isfile(path):
			__handle_resource_file(dir_name, path)
		else:
			if dir_name in g_need_channel_split_dir:
				if entry in g_gameids:
					continue
			if path in g_poker_game_dir:
				continue
			__handle_resource_dir(path)

def __handle_resource_file(dir_name, path):
	print(">>>> handle file %s" % path)
	os.system("cp %s .build/%s" % (path, dir_name))

def __handle_special(channel):
	gameid = g_channels_to_gameid[channel]
	for path_entry in g_need_channel_split_dir:
		path = os.path.join(path_entry, gameid)
		if os.path.exists(path):
			__handle_resource_dir(path)

def __handle_poker_game(channel):
	poker_channels = conf.get_poker_channels()
	if not channel in poker_channels:
		return
	pokers = poker_channels[channel]
	for path_entry in g_poker_game_dir:
		os.system("mkdir .build/%s" % path_entry)
		entry_list = os.listdir(path_entry)
		for entry in entry_list:
			if not __filter_entry(entry):
				continue
			path = os.path.join(path_entry, entry)
			if os.path.isfile(path):
				__handle_resource_file(path_entry, path)
			else:
				if entry in g_all_poker_games and not entry in pokers:
					continue
				__handle_resource_dir(path)

def build_resource(platform, channel):
	__handle_resource_dir("resource")
	__handle_special(channel)
	__handle_poker_game(channel)
	if platform == "ios":
		os.system("./tool/packpdb .build/resource/armature tmp/resource/armature.pdb")
		os.system("./tool/packpdb .build/resource/character tmp/resource/character.pdb")
		os.system("./tool/packpdb .build/resource/effect tmp/resource/effect.pdb")
		os.system("./tool/packpdb .build/resource/map tmp/resource/map.pdb")
		os.system("./tool/packpdb .build/resource/music tmp/resource/music.pdb")
		os.system("./tool/packpdb .build/resource/sound tmp/resource/sound.pdb")
		os.system("./tool/packpdb .build/resource/ui tmp/resource/ui.pdb")
	elif platform == "android":
		pass

def copy_files(platform, channel):
	if platform == "ios":
		os.system("cp -rf .build/resource/font/DroidSansFallback.ttf tmp/resource/font/")
		os.system("cp -rf .build/resource/font/*.png tmp/resource/font/")
		os.system("cp -rf etc/files_%s ../nsg_res/etc/" % channel)
		os.system("cp -rf etc/version_%s.ini ../nsg_res/etc/" % channel)
		os.system("cp -rf etc/config.json.%s_%s ../nsg_res/etc/config.json" % (channel, platform))
		os.system("cp tmp/script.pdb ../nsg_res/home/")
		os.system("cp tmp/script64.pdb ../nsg_res/home/")
		os.system("cp tmp/shader.pdb ../nsg_res/home/")
		os.system("cp -rf tmp/resource/* ../nsg_res/resource")
		num = random.randint(100, 1000)
		for i in range(1,num):
			name = random.randint(1000000,100000000)
			content = random.randint(100, 100000000)
			os.system("echo %d > ../nsg_res/resource/%d"%( content, name) )
	elif platform == "android":
		os.system("cp -rf tmp/script/* ../engine/android/assets/home/script")
		os.system("cp -rf home/shader/glsles/* ../engine/android/assets/home/shader")
		os.system("cp -rf .build/resource/font/* ../engine/android/assets/resource/font/")
		os.system("cp -rf .build/resource/icon/* ../engine/android/assets/resource/icon")
		os.system("cp -rf .build/resource/ui/* ../engine/android/assets/resource/ui")
		os.system("cp -rf .build/resource/effect/* ../engine/android/assets/resource/effect")
		os.system("cp -rf .build/resource/music/* ../engine/android/assets/resource/music")
		os.system("cp -rf .build/resource/sound/* ../engine/android/assets/resource/sound")
		os.system("cp -rf etc/files_%s ../engine/android/assets/etc/" % channel)
		os.system("cp -rf etc/version_%s.ini ../engine/android/assets/etc/" % channel)
		os.system("cp -rf etc/config.json.%s_%s ../engine/android/assets/etc/config.json" % (channel, platform))

def do_pack(platform, channel, code, version):
	if platform == "ios":
		# TODO
		pass
	elif platform == "android":
		gameid = g_channels_to_gameid[channel]
		cwd = os.getcwd()
		os.chdir("../engine")
		os.system("sh pack_android2.sh weixin %s %s %s" % (gameid, code, version))
		os.chdir(cwd)

def after_pack():
	os.system("rm -rf .build")

if __name__ == "__main__":
	if len(sys.argv) < 3:
		print("[usage] python pack/pack_res.py [ios|android] [channel] [--gen-package]")
		exit(1)
	init_env()
	platform = sys.argv[1]
	if not platform in g_platforms:
		print("[error] invalid platform, supported: %s" % g_platforms)
		exit(1)
	channel = sys.argv[2]
	status, output = commands.getstatusoutput("python pack/gen_filelist.py %s" % channel)
	print_and_check_command_ret(status, output)
	remove_prev_dir(platform)
	new_res_dir(platform)
	build_script(platform)
	build_resource(platform, channel)
	copy_files(platform, channel)
	if len(sys.argv) == 4:
		if sys.argv[3] == "--gen-package" and platform == "android":
			build_code = conf.get_android_build_codes(channel)
			build_version = conf.get_version(channel)
			if build_code and build_version:
				do_pack(platform, channel, build_code, build_version)
			else:
				print("[error] gen android package fail")
				print("[error] can't get build code or version")
		else:
			print("[warn] unknown option, no package generated")
	#after_pack()
	print(">>>> pack done")
