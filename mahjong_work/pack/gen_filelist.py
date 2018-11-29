#!/usr/bin/python
#-*- coding:utf8 -*-
import os
import sys
import hashlib
import re
import json
import conf

g_result = []
g_channels = []
g_gameids = []
g_channels_to_gameid = {}
g_need_channel_split_dir = []	
g_poker_game_dir = []
g_all_poker_games = []

def filter_entry(entry):
	exclude_entry = [".", "..", ".git", ".svn", "Makefile", ".DS_Store", ".gitmodules", "tool",
	"Thumbs.db", ".gitignore"]
	if entry in exclude_entry:
		return False
	pattern = re.compile(".proto$")
	if pattern.search(entry) == None:
		return True
	else:
		return False

def gen_file_info(path, collect):
	print(">>>> scaning file %s" % path)
	ret = []
	ret.append(path)
	ret.append(os.path.getsize(path))
	f = open(path)
	content = f.read()
	f.close()
	md5 = hashlib.md5(content)
	ret.append(md5.hexdigest())
	collect.append(ret)

def gen_dir_info(dir_name, collect):
	entry_list = os.listdir(dir_name)
	for entry in entry_list:
		if not filter_entry(entry):
			continue
		path = os.path.join(dir_name, entry)
		if os.path.isfile(path):
			gen_file_info(path, collect)
		else:
			if dir_name in g_need_channel_split_dir:
				if entry in g_gameids:
					continue
			if path in g_poker_game_dir:
				continue
			gen_dir_info(path, collect)

def write_result(output, collect):
	print (">>>> file list scan done")
	print (">>>> total entry count = %d" % len(collect))
	content = json.dumps(collect, sort_keys=True, indent=2)
	'''
	f = open("etc/files")	
	c = f.read()
	f.close()
	compare = json.loads(c) 
	print(">>>> original entry count = %d" % len(compare))
	missing = []
	diff = []
	for e in compare:
		bingo = False
		for _e in collect:
			if e[0] == _e[0]:
				bingo = True
				if e[2] != _e[2]:
					diff.append(e[0])
		if not bingo:
			missing.append(e[0])
	print(">>>> missing : %s" % missing)
	print(">>>> diff : %s" % diff)
	'''
	f = open(output, "w")
	f.write(content)
	f.close()

def handle_special(channel, collect):
	gameid = g_channels_to_gameid[channel]
	for path_entry in g_need_channel_split_dir:
		path = os.path.join(path_entry, gameid)
		if os.path.exists(path):
			gen_dir_info(path, collect)

def handle_poker_game(channel, collect):
	poker_channels = conf.get_poker_channels()
	if not channel in poker_channels:
		return
	pokers = poker_channels[channel]
	for path_entry in g_poker_game_dir:
		entry_list = os.listdir(path_entry)
		for entry in entry_list:
			if not filter_entry(entry):
				continue
			path = os.path.join(path_entry, entry)
			if os.path.isfile(path):
				gen_file_info(path, collect)
			else:
				if entry in g_all_poker_games and not entry in pokers:
					continue
				gen_dir_info(path, collect)

def init_env():
	global g_channels
	global g_gameids
	global g_need_channel_split_dir
	global g_poker_game_dir
	global g_all_poker_games
	g_channels = conf.get_channels()
	g_gameids = conf.get_gameids()
	g_need_channel_split_dir = conf.get_channel_split_dir()
	g_poker_game_dir = conf.get_poker_game_dir()
	g_all_poker_games = conf.get_all_poker_games()
	for i in xrange(0, len(g_channels)):
		channel = g_channels[i]
		gameid = g_gameids[i]
		g_channels_to_gameid[channel] = gameid

if __name__ == "__main__":
	if len(sys.argv) != 2:
		print("[usage] python pack/gen_filelist.py [channel]")
		exit(1)
	init_env()
	channel = sys.argv[1]	
	if not channel in g_channels:
		print("[error] %s is not an available channel name" % channel)
		print("[info] recommand channels: %s" % g_channels)
		exit(1)
	gen_dir_info("resource", g_result)
	gen_dir_info("home/script", g_result)
	gen_dir_info("home/shader", g_result)
	handle_special(channel, g_result)
	handle_poker_game(channel, g_result)
	write_result("etc/files_%s" % channel, g_result)
	exit(0)
