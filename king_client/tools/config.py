#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2018 Register <registerdedicated(at)gmail.com>
#
# Distributed under terms of the GPLv3 license.

import os

HOME = os.getenv("HOME")
TINY_PNG_KEY= "a_ReGgWd7LqPWO8nRSv9jcuMttSOauYE"

def get_src_dir(device):
    if device == "mobile":
        return HOME + "/king_client"
    else:
        return HOME + "/king_client_pc"

def get_version_file(device):
    return get_src_dir(device) + "/version"

def get_publish_dir(device):
    if device == "mobile":
        return "/var/www/html/king_war_v2"
    else:
        return "/var/www/html/king_war_pc"

PARSE_SHEET_NAME = ["pool", "text", "skill", "target", "level", "campaign", "bonus", "duel", "diy",
		"exchange", "guide", "redframe", "treasure_config", "rank", "share_config", "ios_recharge",
		"android_recharge", "ios_limit_gift", "android_limit_gift", "sold_treasure", "sold_gold"]
def get_parse_sheet_name():
	return PARSE_SHEET_NAME
