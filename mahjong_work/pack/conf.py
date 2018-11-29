#-*- coding:utf8 -*-
import os
import json

channels = [
		"openew",
		"test",
		"tj_lexian",
		"ds_queyue",
		"ly_youwen",
		"jz_laiba",
		"yy_doudou",
		"xy_hanshui",
		"rc_xianle",
		"nc_tianjiuwang",
		"za_queyue",
	]
gameids = [
		"kxmj",
		"kxmj",
		"tjmj",
		"dsmj",
		"ywmj",
		"jzmj",
		"yymj",
		"xykwx",
		"rcxianle",
		"nctianjiuwang",
		"zaqueyue",
	]
android_build_codes = {
		"openew":4,
		"test":4,
		"tj_lexian":4,
		"ds_queyue":4,
		"ly_youwen":4,
		"jz_laiba":4,
		"yy_doudou":1,
		"xy_hanshui":1,
		"rc_xianle":1,
		"nc_tianjiuwang":1,
		"za_queyue":1,
	}
need_channel_split_dir = [
		"resource/sound",
		"resource/sound/voices/female",
		"resource/sound/voices/male",
	]
poker_game_dir = [
		"resource/ui/card_game",
		"resource/effect/card_game",
		"resource/sound/card_game",
	]
poker_channels = {
		"test":["niuniu", "paijiu"],
		"openew":["niuniu", "paijiu"],
		"nc_tianjiuwang":["paijiu", "niuniu"],
		"ly_youwen":["niuniu"],
		"yy_doudou":["niuniu"],
	}
all_poker_games = ["niuniu", "paijiu"]
platforms = ["ios", "android"]

def get_channels():
	return channels

def get_gameids():
	return gameids

def get_channel_split_dir():
	return need_channel_split_dir

def get_poker_game_dir():
	return poker_game_dir

def get_poker_channels():
	return poker_channels

def get_all_poker_games():
	return all_poker_games

def get_platforms():
	return platforms

def is_available_channel(channel):
	return channel in channels

def get_android_build_codes(channel):
	return android_build_codes[channel]

def get_version(channel):
	path = "etc/version_%s.ini" % channel
	if os.path.exists(path):
		f = open(path, "r")
		content = f.read()
		f.close()
		ver_data = json.loads(content)
		return ver_data["version"]
	else:
		return None
