# -*- coding: utf-8 -*-
#! /usr/bin/env python

import os
import sys
import re
import imp_luatable

VERSION = '$Revision: 1528 $'
SKILL_DATA_DIR = '../data/info/skills/'
STATUS_DATA_DIR = '../data/info/status/'
DOC_DIR = './'
KEY_STR = '__id__'		# define which row to be the key column

# check for module xlrd
try:
	import xlrd
except ImportError:
	print ">>> [E] no model xlrd, please install it"
	exit()

import xlrd

try:
	import config
	SKILL_DATA_DIR = config.DATA_DIR + 'skills/'
	STATUS_DATA_DIR = config.DATA_DIR + 'status/'
	DOC_DIR = config.DOC_DIR
except ImportError:
	print ">>> -----------------------------------------------------------------"
	print ">>> [W] No tools/config.py, use the default configurations in tools/xls2python.py"
	print ">>>     If you want to use you own configurations please:"
	print ">>>     1. Copy tools/config.py.template to tools/config.py"
	print ">>>     2. Change the variable DOC_DIR to you own document directory"
	print ">>>     3. Change the variable DATA_DIR to you own data directory(default is %s)"%(DATA_DIR)
	print ">>> -----------------------------------------------------------------"

SKILL_FILE_NAME = ['JN1技能设定.xlsx']
STATUS_FILE_NAME = 'JN2技能状态.xlsx'
ioimpl = imp_luatable

def doc_file(name): return DOC_DIR + name
def skill_data_file(name): return SKILL_DATA_DIR + name
def status_data_file(name): return STATUS_DATA_DIR + name

def usage():
	print ">>> -----------------------------------------------------------------"
	print ">>> You must run this script with one of following arguments: "
	print ">>>   --skill or --status"
	print ">>> -----------------------------------------------------------------"

def err(msg):
	print ">>> -----------------------------------------------------------------"
	print ">>> [E] Error: %s" % msg.encode('utf-8')
	print ">>> -----------------------------------------------------------------"

formula_var_table = {
		u"技能等级":{
				'name':'skillLv',
				'get':'self:getSkillLevel()',
				'set':'',
			},
		u"气血":{
				'name':'hp',
				'get':'performerObj:getProp(ATTR_HP)',
				'set':'performerObj:setProp(ATTR_HP, $value)',
			},
		u"攻击距离":{
				'name':'attScope',
				'get':'performerObj:getProp(ATTR_ATT_SCOPE)',
				'set':'performerObj:setProp(ATTR_ATT_SCOPE, $value)',
			},
		u"当前气血":{
				'name':'hp',
				'get':'performerObj:getProp(ATTR_CUR_HP)',
				'set':'performerObj:setProp(ATTR_CUR_HP, $value)',
			},
		u"物攻":{
				'name':'ad',
				'get':'performerObj:getProp(ATTR_AD)',
				'set':'performerObj:setProp(ATTR_AD, $value)',
			},
		u"法攻":{
				'name':'ap',
				'get':'performerObj:getProp(ATTR_AP)',
				'set':'performerObj:setProp(ATTR_AP, $value)',
			},
		u"物防":{
				'name':'ar',
				'get':'performerObj:getProp(ATTR_AR)',
				'set':'performerObj:setFury(ATTR_AR, $value)',
			},
		u"法防":{
				'name':'mr',
				'get':'performerObj:getProp(ATTR_MR)',
				'set':'performerObj:setProp(ATTR_MR, $value)',
			},
		u"命中":{
				'name':'hit',
				'get':'performerObj:getProp(ATTR_HIT)',
				'set':'performerObj:setProp(ATTR_HIT, $value)',
			},
		u"闪避":{
				'name':'doge',
				'get':'performerObj:getProp(ATTR_DOGE)',
				'set':'performerObj:setProp(ATTR_DOGE, $value)',
			},
		u"暴击":{
				'name':'critical',
				'get':'performerObj:getProp(ATTR_CRI)',
				'set':'performerObj:setProp(ATTR_CRI, $value)',
			},
		u"抗暴":{
				'name':'anti_critical',
				'get':'performerObj:getProp(ATTR_ANTI_CRI)',
				'set':'performerObj:setProp(ATTR_ANTI_CRI, $value)',
			},
		u"定身":{
				'name':'frozen',
				'get':'performerObj:getProp(ATTR_FROZEN)',
				'set':'performerObj:setProp(ATTR_FROZEN, $value)',
			},
		u"定身时间":{
				'name':'frozen_time',
				'get':'performerObj:getProp(ATTR_FROZEN_TIME)',
				'set':'performerObj:setProp(ATTR_FROZEN_TIME, $value)',
			},
		u"抗定身":{
				'name':'anti_frozen',
				'get':'performerObj:getProp(ATTR_ANTI_FROZEN)',
				'set':'performerObj:setProp(ATTR_ANTI_FROZEN, $value)',
			},
		u"刺杀命中":{
				'name':'ex_critical',
				'get':'performerObj:getProp(ATTR_EX_CRI)',
				'set':'performerObj:setProp(ATTR_EX_CRI, $value)',
			},
		u"刺杀闪避":{
				'name':'anti_ex_critical',
				'get':'performerObj:getProp(ATTR_ANTI_EX_CRI)',
				'set':'performerObj:setProp(ATTR_ANTI_EX_CRI, $value)',
			},
		u"护身":{
				'name':'ex_hp',
				'get':'performerObj:getProp(ATTR_EX_HP)',
				'set':'performerObj:setProp(ATTR_EX_HP, $value)',
			},
		u"伤害加深":{
				'name':'add_damage',
				'get':'performerObj:getProp(ATTR_ADD_D)',
				'set':'performerObj:setProp(ATTR_ADD_D, $value)',
			},
		u"伤害减免":{
				'name':'sub_damage',
				'get':'performerObj:getProp(ATTR_SUB_D)',
				'set':'performerObj:setProp(ATTR_SUB_D, $value)',
			},
		u"破盾":{
				'name':'break_shield',
				'get':'performerObj:getProp(ATTR_BR_SH)',
				'set':'performerObj:setProp(ATTR_BR_SH, $value)',
			},
		}	
skill_damage_var_table = formula_var_table
damage_opp_var_table = {
		u"OPP最大气血":{
				'name':'maxHPOpp',
				'get':'opp:getProp(ATTR_HP)',
				'set':'',
			},
		u"OPP攻击距离":{
				'name':'attScope',
				'get':'opp:getProp(ATTR_ATT_SCOPE)',
				'set':'',
			},
		u"OPP气血":{
				'name':'hpOpp',
				'get':'opp:getProp(ATTR_CUR_HP)',
				'set':'',
			},
		u"OPP初始气血":{
				'name':'basicHpOpp',
				'get':'opp:getBasicProp(ATTR_CUR_HP)',
				'set':'',
			},
		u"OPP物攻":{
				'name':'adOpp',
				'get':'opp:getProp(ATTR_AD)',
				'set':'',
			},
		u"OPP初始物攻":{
				'name':'basicAdOpp',
				'get':'opp:getBasicProp(ATTR_AD)',
				'set':'',
			},
		u"OPP法攻":{
				'name':'apOpp',
				'get':'opp:getProp(ATTR_AP)',
				'set':'',
			},
		u"OPP初始法攻":{
				'name':'basicApOpp',
				'get':'opp:getBasicProp(ATTR_AP)',
				'set':'',
			},
		u"OPP物防":{
				'name':'arOpp',
				'get':'opp:getProp(ATTR_AR)',
				'set':'',
			},
		u"OPP初始物防":{
				'name':'basicArOpp',
				'get':'opp:getBasicProp(ATTR_AR)',
				'set':'',
			},
		u"OPP法防":{
				'name':'mrOpp',
				'get':'opp:getProp(ATTR_MR)',
				'set':'',
			},
		u"OPP初始法防":{
				'name':'basicMrOpp',
				'get':'opp:getBasicProp(ATTR_MR)',
				'set':'',
			},
		u"OPP命中":{
				'name':'hitOpp',
				'get':'opp:getProp(ATTR_HIT)',
				'set':'',
			},
		u"OPP初始命中":{
				'name':'basicHitOpp',
				'get':'opp:getBasicProp(ATTR_HIT)',
				'set':'',
			},
		u"OPP闪避":{
				'name':'dogeOpp',
				'get':'opp:getProp(ATTR_DOGE)',
				'set':'',
			},
		u"OPP初始闪避":{
				'name':'basicDogeOpp',
				'get':'opp:getBasicProp(ATTR_DOGE)',
				'set':'',
			},
		u"OPP暴击":{
				'name':'criticalOpp',
				'get':'opp:getProp(ATTR_CI)',
				'set':'',
			},
		u"OPP初始暴击":{
				'name':'basicCriticalOpp',
				'get':'opp:getBasicProp(ATTR_CRI)',
				'set':'',
			},
		u"OPP抗暴":{
				'name':'antiCriOpp',
				'get':'opp:getProp(ATTR_ANTI_CRI)',
				'set':'',
			},
		u"OPP初始抗暴":{
				'name':'basicAntiCriOpp',
				'get':'opp:getBasicProp(ATTR_ANTI_CRI)',
				'set':'',
			},
		u"OPP定身":{
				'name':'frozenOpp',
				'get':'opp:getProp(ATTR_FROZEN)',
				'set':'',
			},
		u"OPP初始定身":{
				'name':'basicFrozenOpp',
				'get':'opp:getBasicProp(ATTR_FROZEN)',
				'set':'',
			},
		u"OPP定身时间":{
				'name':'frozenTimeOpp',
				'get':'opp:getProp(ATTR_FROZEN_TIME)',
				'set':'',
			},
		u"OPP初始定身时间":{
				'name':'basicFrozenTimeOpp',
				'get':'opp:getBasicProp(ATTR_FROZEN_TIME)',
				'set':'',
			},
		u"OPP抗定身":{
				'name':'antiFrozenOpp',
				'get':'opp:getProp(ATTR_ANTI_FROZEN)',
				'set':'',
			},
		u"OPP初始抗定身":{
				'name':'baseAntiFrozenOpp',
				'get':'opp:getBasicProp(ATTR_ANTI_FROZEN)',
				'set':'',
			},
		u"OPP刺杀命中":{
				'name':'exCriticalOpp',
				'get':'opp:getProp(ATTR_EX_CRI)',
				'set':'',
			},
		u"OPP初始刺杀命中":{
				'name':'baseExCriticalOpp',
				'get':'opp:getBasicProp(ATTR_EX_CRI)',
				'set':'',
			},
		u"OPP刺杀闪避":{
				'name':'antiExCriticalOpp',
				'get':'opp:getProp(ATTR_ANTI_EX_CRI)',
				'set':'',
			},
		u"OPP初始刺杀闪避":{
				'name':'baseAntiExCriticalOpp',
				'get':'opp:getBasicProp(ATTR_ANTI_EX_CRI)',
				'set':'',
			},
		u"OPP护身":{
				'name':'exHpOpp',
				'get':'opp:getProp(ATTR_EX_HP)',
				'set':'',
			},
		u"OPP初始护身":{
				'name':'baseExHpOpp',
				'get':'opp:getBasicProp(ATTR_EX_HP)',
				'set':'',
			},
		u"OPP伤害加深":{
				'name':'addDamageOpp',
				'get':'opp:getProp(ATTR_ADD_D)',
				'set':'',
			},
		u"OPP初始伤害加深":{
				'name':'baseAddDamageOpp',
				'get':'opp:getBasicProp(ATTR_ADD_D)',
				'set':'',
			},
		u"OPP伤害减免":{
				'name':'subDamageOpp',
				'get':'opp:getProp(ATTR_SUB_D)',
				'set':'',
			},
		u"OPP初始伤害减免":{
				'name':'baseSubDamageOpp',
				'get':'opp:getBasicProp(ATT_SUB_D)',
				'set':'',
			},
		u"OPP破盾":{
				'name':'breakShieldOpp',
				'get':'opp:getBasicProp(ATTR_BR_SH)',
				'set':'',
			},
		u"OPP初始破盾":{
				'name':'baseBreakShieldOpp',
				'get':'opp:getBasicProp(ATTR_BR_SH)',
				'set':'',
			},
	}

for (k, v) in damage_opp_var_table.items():
	skill_damage_var_table[k] = v

status_var_table = {
		u"叠加层数":{
				'name':'stackDepth',
				'get':'self:getCurStackDepth()',
				'set':'self:setCurStackDepth($value)',
			},
		u"最大叠加层数":{
				'name':'maxStackDepth',
				'get':'self:getMaxStackDepth()',
				'set':'',
			},
		u"技能等级":{
				'name':'skillLv',
				'get':'self.skillObj:getSkillLevel()',
				'set':'',
			},
		u"技能分类":{
				'name':'skillCate',
				'get':'self.skillObj:getSkillCategory()',
				'set':'',
			},
		u"最大气血":{
				'name':'maxHP',
				'get':'self:getOwnerProp(ATTR_HP)',
				'set':'',
			},
		u"攻击距离":{
				'name':'attScope',
				'get':'self:getOwnerProp(ATTR_ATT_SCOPE)',
				'set':'self:setOwnerProp(ATTR_ATT_SCOPE, $value)',
			},
		u"初始攻击距离":{
				'name':'basicAttScope',
				'get':'self:getOwnerBasicProp(ATTR_ATT_SCOPE)',
				'set':'',
			},
		u"气血":{
				'name':'hp',
				'get':'self:getOwnerProp(ATTR_CUR_HP)',
				'set':'self:setOwnerProp(ATTR_CUR_HP, $value)',
			},
		u"初始气血":{
				'name':'basicHp',
				'get':'self:getOwnerBasicProp(ATTR_CUR_HP)',
				'set':'',
			},
		u"物攻":{
				'name':'ad',
				'get':'self:getOwnerProp(ATTR_AD)',
				'set':'self:setOwnerProp(ATTR_AD, $value)',
			},
		u"初始物攻":{
				'name':'basicAd',
				'get':'self:getOwnerBasicProp(ATTR_AD)',
				'set':'',
			},
		u"法攻":{
				'name':'ap',
				'get':'self:getOwnerProp(ATTR_AP)',
				'set':'self:setOwnerProp(ATTR_AP, $value)',
			},
		u"初始法攻":{
				'name':'basicAp',
				'get':'self:getOwnerBasicProp(ATTR_AP)',
				'set':'',
			},
		u"物防":{
				'name':'ar',
				'get':'self:getOwnerProp(ATTR_AR)',
				'set':'self:setOwnerProp(ATTR_AR, $value)',
			},
		u"初始物防":{
				'name':'basicAr',
				'get':'self:getOwnerBasicProp(ATTR_AR)',
				'set':'',
			},
		u"法防":{
				'name':'mr',
				'get':'self:getOwnerProp(ATTR_MR)',
				'set':'self:setOwnerProp(ATTR_MR, $value)',
			},
		u"初始法防":{
				'name':'basicMr',
				'get':'self:getOwnerBasicProp(ATTR_MR)',
				'set':'',
			},
		u"命中":{
				'name':'hit',
				'get':'self:getOwnerProp(ATTR_HIT)',
				'set':'',
			},
		u"初始命中":{
				'name':'basicHit',
				'get':'self:getOwnerBasicProp(ATTR_HIT)',
				'set':'',
			},
		u"闪避":{
				'name':'doge',
				'get':'self:getOwnerProp(ATTR_DOGE)',
				'set':'self:setOwnerProp(ATTR_DOGE, $value)',
			},
		u"初始闪避":{
				'name':'basicDoge',
				'get':'self:getOwnerBasicProp(ATTR_DOGE)',
				'set':'',
			},
		u"暴击":{
				'name':'critical',
				'get':'self:getOwnerProp(ATTR_CI)',
				'set':'self:setOwnerProp(ATTR_CRI, $value)',
			},
		u"初始暴击":{
				'name':'basicCritical',
				'get':'self:getOwnerBasicProp(ATTR_CRI)',
				'set':'',
			},
		u"抗暴":{
				'name':'antiCri',
				'get':'self:getOwnerProp(ATTR_ANTI_CRI)',
				'set':'self:setOwnerProp(ATTR_ANTI_CRI, $value)',
			},
		u"初始抗暴":{
				'name':'basicAntiCri',
				'get':'self:getOwnerBasicProp(ATTR_ANTI_CRI)',
				'set':'',
			},
		u"定身":{
				'name':'frozen',
				'get':'self:getOwnerProp(ATTR_FROZEN)',
				'set':'self:setOwnerProp(ATTR_FROZEN, $value)',
			},
		u"初始定身":{
				'name':'basicFrozen',
				'get':'self:getOwnerBasicProp(ATTR_FROZEN)',
				'set':'',
			},
		u"定身时间":{
				'name':'frozenTime',
				'get':'self:getOwnerProp(ATTR_FROZEN_TIME)',
				'set':'self:setOwnerProp(ATTR_FROZEN_TIME, $value)',
			},
		u"初始定身时间":{
				'name':'basicFrozenTime',
				'get':'self:getOwnerBasicProp(ATTR_FROZEN_TIME)',
				'set':'',
			},
		u"抗定身":{
				'name':'antiFrozen',
				'get':'self:getOwnerProp(ATTR_ANTI_FROZEN)',
				'set':'self:setOwnerProp(ATTR_ANTI_FROZEN, $value)',
			},
		u"初始抗定身":{
				'name':'baseAntiFrozen',
				'get':'self:getOwnerBasicProp(ATTR_ANTI_FROZEN)',
				'set':'',
			},
		u"刺杀命中":{
				'name':'exCritical',
				'get':'self:getOwnerProp(ATTR_EX_CRI)',
				'set':'self:setOwnerProp(ATTR_EX_CRI, $value)',
			},
		u"初始刺杀命中":{
				'name':'baseExCritical',
				'get':'self:getOwnerBasicProp(ATTR_EX_CRI)',
				'set':'',
			},
		u"刺杀闪避":{
				'name':'antiExCritical',
				'get':'self:getOwnerProp(ATTR_ANTI_EX_CRI)',
				'set':'self:setOwnerProp(ATTR_ANTI_EX_CRI, $value)',
			},
		u"初始刺杀闪避":{
				'name':'baseAntiExCritical',
				'get':'self:getOwnerBasicProp(ATTR_ANTI_EX_CRI)',
				'set':'',
			},
		u"护身":{
				'name':'exHp',
				'get':'self:getOwnerProp(ATTR_EX_HP)',
				'set':'self:setOwnerProp(ATTR_EX_HP, $value)',
			},
		u"初始护身":{
				'name':'baseExHp',
				'get':'self:getOwnerBasicProp(ATTR_EX_HP)',
				'set':'',
			},
		u"伤害加深":{
				'name':'addDamage',
				'get':'self:getOwnerProp(ATTR_ADD_D)',
				'set':'self:setOwnerProp(ATTR_ADD_D, $value)',
			},
		u"初始伤害加深":{
				'name':'baseAddDamage',
				'get':'self:getOwnerBasicProp(ATTR_ADD_D)',
				'set':'',
			},
		u"伤害减免":{
				'name':'subDamage',
				'get':'self:getOwnerProp(ATTR_SUB_D)',
				'set':'self:setOwnerProp(ATTR_SUB_D, $value)',
			},
		u"初始伤害减免":{
				'name':'baseSubDamage',
				'get':'self:getOwnerBasicProp(ATT_SUB_D)',
				'set':'',
			},
		u"破盾":{
				'name':'breakShield',
				'get':'self:getOwnerProp(ATTR_BR_SH)',
				'set':'self:setOwnerProp(ATTR_BR_SH, $value)',
			},
		u"初始破盾":{
				'name':'baseBreakShield',
				'get':'self:getOwnerBasicProp(ATTR_BR_SH)',
				'set':'',
			},


		u"OPP最大气血":{
				'name':'maxHPOpp',
				'get':'self:getOppProp(opp, ATTR_HP)',
				'set':'',
			},
		u"OPP攻击距离":{
				'name':'attScopeOpp',
				'get':'self:getOppProp(opp, ATTR_ATT_SCOPE)',
				'set':'self:setOppProp(opp, ATTR_ATT_SCOPE, $value)',
			},
		u"OPP初始攻击距离":{
				'name':'basicAttScopeOpp',
				'get':'self:getOppBasicProp(opp, ATTR_ATT_SCOPE)',
				'set':'',
			},
		u"OPP气血":{
				'name':'hpOpp',
				'get':'self:getOppProp(opp, ATTR_CUR_HP)',
				'set':'self:setOppProp(opp, ATTR_CUR_HP, $value)',
			},
		u"OPP初始气血":{
				'name':'basicHpOpp',
				'get':'self:getOppBasicProp(opp, ATTR_CUR_HP)',
				'set':'',
			},
		u"OPP物攻":{
				'name':'adOpp',
				'get':'self:getOppProp(opp, ATTR_AD)',
				'set':'self:setOppProp(opp, ATTR_AD, $value)',
			},
		u"OPP初始物攻":{
				'name':'basicAdOpp',
				'get':'self:getOppBasicProp(opp, ATTR_AD)',
				'set':'',
			},
		u"OPP法攻":{
				'name':'apOpp',
				'get':'self:getOppProp(opp, ATTR_AP)',
				'set':'self:setOppProp(opp, ATTR_AP, $value)',
			},
		u"OPP初始法攻":{
				'name':'basicApOpp',
				'get':'self:getOppBasicProp(opp, ATTR_AP)',
				'set':'',
			},
		u"OPP物防":{
				'name':'arOpp',
				'get':'self:getOppProp(opp, ATTR_AR)',
				'set':'self:setOppProp(opp, ATTR_AR, $value)',
			},
		u"OPP初始物防":{
				'name':'basicArOpp',
				'get':'self:getOppBasicProp(opp, ATTR_AR)',
				'set':'',
			},
		u"OPP法防":{
				'name':'mrOpp',
				'get':'self:getOppProp(opp, ATTR_MR)',
				'set':'self:setOppProp(opp, ATTR_MR, $value)',
			},
		u"OPP初始法防":{
				'name':'basicMrOpp',
				'get':'self:getOppBasicProp(opp, ATTR_MR)',
				'set':'',
			},
		u"OPP命中":{
				'name':'hitOpp',
				'get':'self:getOppProp(opp, ATTR_HIT)',
				'set':'self:setOppProp(opp, ATTR_HIT, $value)',
			},
		u"OPP初始命中":{
				'name':'basicHitOpp',
				'get':'self:getOppBasicProp(opp, ATTR_HIT)',
				'set':'',
			},
		u"OPP闪避":{
				'name':'dogeOpp',
				'get':'self:getOppProp(opp, ATTR_DOGE)',
				'set':'self:setOppProp(opp, ATTR_DOGE, $value)',
			},
		u"OPP初始闪避":{
				'name':'basicDogeOpp',
				'get':'self:getOppBasicProp(opp, ATTR_DOGE)',
				'set':'',
			},
		u"OPP暴击":{
				'name':'criticalOpp',
				'get':'self:getOppProp(opp, ATTR_CI)',
				'set':'self:setOppProp(opp, ATTR_CRI, $value)',
			},
		u"OPP初始暴击":{
				'name':'basicCriticalOpp',
				'get':'self:getOppBasicProp(opp, ATTR_CRI)',
				'set':'',
			},
		u"OPP抗暴":{
				'name':'antiCriOpp',
				'get':'self:getOppProp(opp, ATTR_ANTI_CRI)',
				'set':'self:setOppProp(opp, ATTR_ANTI_CRI, $value)',
			},
		u"OPP初始抗暴":{
				'name':'basicAntiCriOpp',
				'get':'self:getOppBasicProp(opp, ATTR_ANTI_CRI)',
				'set':'',
			},
		u"OPP定身":{
				'name':'frozenOpp',
				'get':'self:getOppProp(opp, ATTR_FROZEN)',
				'set':'self:setOppProp(opp, ATTR_FROZEN, $value)',
			},
		u"OPP初始定身":{
				'name':'basicFrozenOpp',
				'get':'self:getOppBasicProp(opp, ATTR_FROZEN)',
				'set':'',
			},
		u"OPP定身时间":{
				'name':'frozenTimeOpp',
				'get':'self:getOppProp(opp, ATTR_FROZEN_TIME)',
				'set':'self:setOppProp(opp, ATTR_FROZEN_TIME, $value)',
			},
		u"OPP初始定身时间":{
				'name':'basicFrozenTimeOpp',
				'get':'self:getOppBasicProp(opp, ATTR_FROZEN_TIME)',
				'set':'',
			},
		u"OPP抗定身":{
				'name':'antiFrozenOpp',
				'get':'self:getOppProp(opp, ATTR_ANTI_FROZEN)',
				'set':'self:setOppProp(opp, ATTR_ANTI_FROZEN, $value)',
			},
		u"OPP初始抗定身":{
				'name':'baseAntiFrozenOpp',
				'get':'self:getOppBasicProp(opp, ATTR_ANTI_FROZEN)',
				'set':'',
			},
		u"OPP刺杀命中":{
				'name':'exCriticalOpp',
				'get':'self:getOppProp(opp, ATTR_EX_CRI)',
				'set':'self:setOppProp(opp, ATTR_EX_CRI, $value)',
			},
		u"OPP初始刺杀命中":{
				'name':'baseExCriticalOpp',
				'get':'self:getOppBasicProp(opp, ATTR_EX_CRI)',
				'set':'',
			},
		u"OPP刺杀闪避":{
				'name':'antiExCriticalOpp',
				'get':'self:getOppProp(opp, ATTR_ANTI_EX_CRI)',
				'set':'self:setOppProp(opp, ATTR_ANTI_EX_CRI, $value)',
			},
		u"OPP初始刺杀闪避":{
				'name':'baseAntiExCriticalOpp',
				'get':'self:getOppBasicProp(opp, ATTR_ANTI_EX_CRI)',
				'set':'',
			},
		u"OPP护身":{
				'name':'exHpOpp',
				'get':'self:getOppProp(opp, ATTR_EX_HP)',
				'set':'self:setOppProp(opp, ATTR_EX_HP, $value)',
			},
		u"OPP初始护身":{
				'name':'baseExHpOpp',
				'get':'self:getOppBasicProp(opp, ATTR_EX_HP)',
				'set':'',
			},
		u"OPP伤害加深":{
				'name':'addDamageOpp',
				'get':'self:getOppProp(opp, ATTR_ADD_D)',
				'set':'self:setOppProp(opp, ATTR_ADD_D, $value)',
			},
		u"OPP初始伤害加深":{
				'name':'baseAddDamageOpp',
				'get':'self:getOppBasicProp(opp, ATTR_ADD_D)',
				'set':'',
			},
		u"OPP伤害减免":{
				'name':'subDamageOpp',
				'get':'self:getOppProp(opp, ATTR_SUB_D)',
				'set':'self:setOppProp(opp, ATTR_SUB_D, $value)',
			},
		u"OPP初始伤害减免":{
				'name':'baseSubDamageOpp',
				'get':'self:getOppBasicProp(opp, ATT_SUB_D)',
				'set':'',
			},
		u"OPP破盾":{
				'name':'breakShield',
				'get':'self:getOppProp(opp, ATTR_BR_SH)',
				'set':'self:setOppProp(opp, ATTR_BR_SH, $value)',
			},
		u"OPP初始破盾":{
				'name':'baseBreakShield',
				'get':'self:getOppBasicProp(opp, ATTR_BR_SH)',
				'set':'',
			},
	}

skill_head_type_table = {
		u"编号":{'type':'str', 'index':True},
		u"名字":{'type':'text'},
		u"技能属主类型":{'type':'macro'},
		u"职业":{'type':'macro'},
		u"图标":{'type':'int'},
		u"技能类型":{'type':'macro'},
		u"技能分类":{'type':'str'},
		u"学习等级":{'type':'int'},
		u"施法特效":{'type':'str'},
		u"飞行特效":{'type':'str'},
		u"场景特效":{'type':'str'},
		u"受击特效":{'type':'str'},
		u"技能音效":{'type':'str'},
		u"受击音效":{'type':'str'},
		u"是否隐藏":{'type':'macro'},
		u"禁用施法动作":{'type':'macro'},
		u"施法动作":{'type':'str'},
		u"介绍":{'type':'format_str'},
		u"升级描述":{'type':'format_str'},
		u"等级关联技能":{'type':'str_list'},

		u"施法状态限制":{'type':'list_to_dict'},
		u"技能冷却":{'type':'lua_formula_function'},

		u"目标类型":{'type':'macro'},
		u"目标定位":{'type':'str_list'},
		u"势力定位":{'type':'macro'},
		u"状态约束":{'type':'str_list'},
		u"选择目标方式":{'type':'macro'},
		u"施法距离":{'type':'lua_formula_function'},
		u"作用半径":{'type':'lua_formula_function'},
		u"目标数量":{'type':'lua_formula_function'},
		u"目标排序方式":{'type':'macro'},
		u"目标忽视状态":{'type':'list_to_dict'},
		u"施法方向":{'type':'macro'},

		u"自己附加状态":{'type':'str_list'},
		u"目标附加状态":{'type':'str_list'},
		u"战场附加状态":{'type':'str_list'},

		u"技能伤害公式":{'type':'skill_damage_formula_function', 'var_table':skill_damage_var_table},
		u"对施法人属性影响":{'type':'lua_skill_lvar_function'},
		u"基础值":{'type':'int'},

		u"士气消耗":{'type':'lua_formula_function'},
		u"关联目标":{'type':'str_list'},
		u"关联目标数量":{'type':'int_list'},
		u"关联技能":{'type':'str'},

		u"召唤兵种编号":{'type':'str'},
		u"召唤数量":{'type':'lua_formula_function'},
	}

status_head_type_table = {
		u"名字":{'type':'str', 'index':True},
		u"状态类型":{'type':'int'},
		u"状态基类":{'type':'int'},
		u"持续时间":{'type':'lua_formula_function'},
		u"状态特效":{'type':'str'},
		u"最大叠加层数":{'type':'lua_formula_function', 'var_table':status_var_table},
		u"心跳间隔":{'type':'lua_formula_function'},
		u"特效播放方式":{'type':'macro'},
		u"音效":{'type':'str'},
		u"buff图标":{'type':'str'},
		u"结算次数限制":{'type':'lua_formula_function', 'var_table':status_var_table},
		u"状态覆盖":{'type':'list_to_dict'},
		u"状态互斥":{'type':'list_to_dict'},
		u"状态效果":{'type':'int'},
		u"状态初始判断":{'type':'lua_cond_function'},
		u"状态初始":{'type':'lua_lvar_function'},
		u"状态心跳判断":{'type':'lua_cond_function'},
		u"状态心跳":{'type':'lua_lvar_function'},
		u"状态结束判断":{'type':'lua_cond_function'},
		u"状态结束":{'type':'lua_lvar_function'},
		u"出手时判断":{'type':'lua_cond_function'},
		u"出手时":{'type':'lua_lvar_function'},
		u"攻击伤害结算前判断":{'type':'lua_cond_function'},
		u"攻击伤害结算前":{'type':'lua_lvar_function'},
		u"受击伤害结算前判断":{'type':'lua_cond_function'},
		u"受击伤害结算前":{'type':'lua_lvar_function'},
		u"攻击伤害结算后判断":{'type':'lua_cond_function'},
		u"攻击伤害结算后":{'type':'lua_lvar_function'},
		u"受击伤害结算后判断":{'type':'lua_cond_function'},
		u"受击伤害结算后":{'type':'lua_lvar_function'},
		#u"随机数":{'type':'lua_formula_function', 'var_table':status_var_table},
	}

formula_pattern = re.compile(r'[%=＋\+\-\*\＊\/\(\)\ ,\<\>!\?\:]')
expr_pattern = re.compile(u'[;；]')
lrvalue_pattern = re.compile(u'[=＝]')
instruct_pattern = re.compile(u' ')
compare_pattern_str = u'>[=]*|==|~=|<[=]*'
compare_pattern = re.compile(compare_pattern_str)
compare_expr_pattern = re.compile(u'and|or')

skill_base_dict = {
		"SKILL_TYPE_POINT":{'base':'pPointSkill', 'header':'local modSkillBase = import("logic/skill/point_skill.lua")'},
		"SKILL_TYPE_NON_POINT":{'base':'pNonPointSkill', 'header':'local modSkillBase = import("logic/skill/non_point_skill.lua")'},
		"SKILL_TYPE_PASSIVE":{'base':'pPassiveSkill', 'header':'local modSkillBase = import("logic/skill/passive_skill.lua")'},
		"SKILL_TYPE_ATTR":{'base':'pAttrSkill', 'header':'local modSkillBase = import("logic/skill/attribute_skill.lua")'},
		"SKILL_TYPE_CASTLE":{'base':'pPassiveSkill', 'header':'local modSkillBase = import("logic/skill/passive_skill.lua")'},
		"SKILL_TYPE_NORMAL":{'base':'pNormalAttSkill', 'header':'local modSkillBase = import("logic/skill/normal_att.lua")'},
		"SKILL_TYPE_ENTER":{'base':'pEnterSkill', 'header':'local modSkillBase = import("logic/skill/enter_skill.lua")'},
	}

common_skill_include = '''
%s

local pow = math.pow
local sqrt = math.sqrt

pSkill%s = pSkill%s or class(modSkillBase.%s)
'''

common_skill_code = '''
getSkillConf = function()
	return skillData
end

pSkill%s.init = function(self)
	self.staticData = skillData
	self.skillId = "%s"
	modSkillBase.%s.init(self)
end

pSkill%s.getSkillStaticProp = function(self, propName)
	return self.staticData[propName]
end
'''

status_base_dict = {
		'':{'base':'pStatus'},
		'0':{'base':'pStatus'},
		'1':{'base':'pSideStatus'},
	}

common_status_include = '''
local modStatus = import("logic/skill/status.lua")
local modSkill = import("logic/skill/skill.lua")

local pow = math.pow
local sqrt = math.sqrt

className = "pStatus%s"

pStatus%s = pStatus%s or class(modStatus.%s)
'''

common_status_code = '''
getStatusConf = function()
	return statusData
end

pStatus%s.init = function(self)
	self.staticData = statusData
	modStatus.pStatus.init(self)
end

pStatus%s.getStatusStaticProp = function(self, propName)
	return self.staticData[propName]
end
'''

add_status_code = '''
\t\t\t\tself:activateStatus(opp, self.skillObj, %s)
'''

add_self_status_code = '''
\t\t\t\tself:activateStatus(self.ownerObj, self.skillObj, %s)
'''

perform_skill_code = '''
\t\t\t\tself:activateSkill(%s)
'''

activate_skill_code = '''
\t\t\t\tself:activateSkill(%s, true)
'''

damage_mod_code = '''
\t\t\t\t__dDamage = %s
'''

clean_buff_code = '''
\t\t\t\tself.ownerObj:cleanAllBuff()
'''

clean_debuff_code = '''
\t\t\t\tself.ownerObj:cleanAllDebuff()
'''

stop_code = '''
\t\t\t\tself:stop()
'''

cond_func_code = '''
\t\t\t\tlocal %s = function()
\t\t\t\t	%s
\t\t\t\t	return %s
\t\t\t\tend
'''

lvar_func_common = '''
\t\t\t\tif not self:commonCalculate() then
\t\t\t\t	return 0
\t\t\t\tend
'''

begin = "----------------- Generated Code BTag ------------------"
end   = "----------------- Generated Code ETag ------------------"

def format_value(value, vtype):
	# if the value is interger number then make it interger
	if vtype == 2 and value == int(value): 
		return int(value)
	else:
		return value

def replace_str(val, k, v):
	ret = val
	pos = 0
	index = 0
	pos = ret.find(k, index)
	while pos >= 0:
		index = pos + len(k)
		ret = ret[0:pos] + v + ret[index:]
		pos = ret.find(k, index)
	return ret

def parse_right_var(rvalue, var_table = formula_var_table, tab = "\t\t\t\t"):
	if not isinstance(rvalue, str):
		rvalue = u"%s" % rvalue
	all_vars = formula_pattern.split(rvalue)
	index = 0
	src = ''
	ret_val = rvalue
	replace_dict = {}
	for var in all_vars:
		var = var.strip()
		if var in var_table:
			tmp_index = rvalue.find(var, index)
			if tmp_index >= 0:
				if tmp_index == 0:
					head = ''
				else:
					head = src[0:tmp_index]
				index = tmp_index + len(var)
				var_name = var_table[var]['name']
				get_func = var_table[var]['get']
				src += u"%s-- %s\n"%(tab, var)
				src += u"%slocal %s = %s\n"%(tab, var_name, get_func)
				replace_dict[var] = var_name
		else:
			# 获取技能id的指令
			# 技能等级["1000"]
			# 叠加层数["status"]
			get_skill_lv_str = u'.*\[.*\].*'
			p = re.search(get_skill_lv_str, var)
			var_name = ""
			get_func = ""
			plus_inst = ""
			if not p == None:
				indx1 = var.find("[", 0)
				indx2 = var.find("]", indx1)
				inst_name = var[:indx1]
				if inst_name == u"技能等级":
					skill_id = var[indx1+1:indx2]
					var_name = "skillLv_%d" % int(skill_id[1:-1])
					get_func = "performerObj:getSkillLevelById(%s)" % skill_id
					plus_inst = "local performerObj = performerObj or self:getSourceObj()"
				elif inst_name == u"OPP技能等级":
					skill_id = var[indx1+1:indx2]
					var_name = "oppSkillLv_%d" % int(skill_id[1:-1])
					get_func = "opp:getSkillLevelById(%s)" % skill_id
				elif inst_name == u"叠加层数":
					status_id = var[indx1+1:indx2]
					var_name = "statusName_%s" % status_id[1:-1]
					get_func = "opp:getStatusStackDepth(%s)" % status_id
				elif inst_name == u"SELF_HAS_STATUS":
					status_id = var[indx1+1:indx2]
					var_name = "selfHasStatusRes_%s" % status_id[1:-1]
					get_func = "self.ownerObj:inStatus(%s)" % status_id
				elif inst_name == u"OPP_HAS_STATUS":
					status_id = var[indx1+1:indx2]
					var_name = "oppHasStatusRes_%s" % status_id[1:-1]
					get_func = "opp:inStatus(%s)" % status_id
				else:
					continue
			else:
				continue
			tmp_index = rvalue.find(var, index)
			if tmp_index >= 0:
				if tmp_index == 0:
					head = ''
				else:
					head = src[0:tmp_index]
				index = tmp_index + len(var)
				src += u"%s-- %s\n"%(tab, var)
				if plus_inst != "":
					src += u"%s%s\n" % (tab, plus_inst)
				src += u"%slocal %s = %s\n"%(tab, var_name, get_func)
				replace_dict[var] = var_name
	
	keys = replace_dict.keys()
	def str_cmp(s1, s2):
		return len(s2) - len(s1)
	keys = sorted(keys, cmp=str_cmp)
	for k in keys:
		v = replace_dict[k]
		ret_val = replace_str(ret_val, k, v)

	if len(ret_val):
		src += "%s__rvalue = %s\n" % (tab, ret_val)
	else:
		src += "%s__rvalue = 0\n" % tab

	#src += "\t\t\t\treturn __ret"
#	print(src)
	return src 

def parse_left_var(lvalue, rvalue, var_table = formula_var_table):
	src = rvalue
	lvalue = lvalue.strip()
	if lvalue in var_table:
		var_name = var_table[lvalue]['name']
		set_func = var_table[lvalue]['set']
		src += u"\t\t\t\t__lvalue = __rvalue\n"
		src += u"\t\t\t\t__rvalue = 0\n"
		src += u"\t\t\t\t%s\n" % set_func
		src = replace_str(src, "$value", "__lvalue")
	elif lvalue == "dotDamage":
		src += u"\t\t\t\t__lvalue = __rvalue\n"
	return src

def parse_expr(value, var_table = status_var_table):
	exprs = expr_pattern.split(value)
	src = ''
	for expr in exprs:
		expr = expr.strip()
		if len(expr) == 0:
			continue
		lr = lrvalue_pattern.split(expr)
		if len(lr) == 2:
			lval = lr[0]
			rval = lr[1]
			r_result = parse_right_var(rval, var_table)
			l_result = parse_left_var(lval, r_result, var_table)
			src += "\n" + l_result
		else:
			#是否是特殊指令
			insts = instruct_pattern.split(expr)
			if len(insts) == 2:
				instr = insts[0]
				param = insts[1]
				if instr == "ADD_STATUS":
					status = param
					src += add_status_code % status
				elif instr == "ADD_STATUS_SELF":
					status = param
					src += add_self_status_code % status
				elif instr == "PERFORM_SKILL":
					skill = param
					src += perform_skill_code % skill
				elif instr == "ACTIVATE_SKILL":
					skill = param
					src += activate_skill_code % skill
				elif instr == "DAMAGE_MOD":
					diff = parse_right_var(param, var_table)
					src += diff 
					src += damage_mod_code % "__rvalue"
			elif len(insts) == 1:
				instr = insts[0]
				if instr == "CLEAN_BUFF":
					# 清除所有增益状态
					src += clean_buff_code
				elif instr == "CLEAN_DEBUFF":
					# 清除所有减益状态
					src += clean_debuff_code
				elif instr == "STOP":
					# 停止自己
					src += stop_code
				else:
					err("unkown instruction in expr: %s"%instr)
					exit()
			else:
				err("Expr parse error, you must supply '=' at least")
				print value
				exit()
	if len(src) == 0:
		src = ''
	return src

def parse_cond_expr(value):
	#exprs = expr_pattern.split(value)
	exprs = compare_expr_pattern.split(value)
	src = ''
	r = re.search(r'and|or', value)
	if r == None:
		logic_tag = "and"
	else:
		logic_tag = r.group()
	cond_funcs = []
	indx = 1
	for expr in exprs:
		expr = expr.strip()
		if len(expr) == 0:
			continue
		lr = compare_pattern.split(expr)
		#print(lr)
		if len(lr) == 2:
			lvalue = lr[0]
			rvalue = lr[1]
			s = re.search(compare_pattern_str, expr)
			if s == None:
				err("Expr cond parse error, can't find compare tag")
				exit()
			tag = s.group()
			rvalue_str = parse_right_var(rvalue, status_var_table, "\t\t\t\t\t")
			if lvalue == "RANDOM":
				content = "math.randomseed(getCurrentTime())\n\t\t\t\t\tlocal randNum = math.random(1000)\n"
				content += rvalue_str
				ret = "randNum %s __rvalue" % (tag)
				func_name = "randomFunc%d" % indx
				src += cond_func_code % (func_name, content, ret)
				cond_funcs.append(func_name)
			elif lvalue == "SKILLID":
				content = "\n" + rvalue_str
				content += "\n\t\t\t\t\tlocal skillId = skillObj:getSkillId()\n"
				ret = "skillId %s __rvalue" % (tag)
				func_name = "skillCmpFunc%d" % indx
				src += cond_func_code % (func_name, content, ret)	
				cond_funcs.append(func_name)
			elif lvalue == "SKILLCATE":
				content = "\n" + rvalue_str
				content += "\n\t\t\t\t\tlocal cate = skillObj:getSkillCategory()\n"
				ret = "cate %s __rvalue" % (tag)
				func_name = "skillCateCmpFunc%d" % indx
				src += cond_func_code % (func_name, content, ret)
				cond_funcs.append(func_name)
			elif lvalue == "DAMAGE":
				content = "\n" + rvalue_str
				ret = "damage %s __rvalue" % (tag)
				func_name = "damageCmpFunc%d" % indx
				src += cond_func_code % (func_name, content, ret)	
				cond_funcs.append(func_name)
			elif lvalue == "CRITICAL":
				content = "\n" + rvalue_str
				content += "\n\t\t\t\t\tif not isCritical then isCritical = false end"
				ret = "isCritical %s __rvalue" % (tag)
				func_name = "criticalJudge%d" % indx
				src += cond_func_code % (func_name, content, ret)
				cond_funcs.append(func_name)
			elif lvalue == "DINGSHEN":
				content = "\n" + rvalue_str
				content += "\n\t\t\t\t\tif not isDingshen then isDingshen = false end"
				ret = "isDingshen %s __rvalue" % (tag)
				func_name = "dingshenJudge%d" % indx
				src += cond_func_code % (func_name, content, ret)
				cond_funcs.append(func_name)
			elif lvalue == "CISHA":
				content = "\n" + rvalue_str
				content += "\n\t\t\t\t\tif not isCisha then isCisha = false end"
				ret = "isCisha %s __rvalue" % (tag)
				func_name = "cishaJudge%d" % indx
				src += cond_func_code % (func_name, content, ret)
				cond_funcs.append(func_name)
			elif lvalue == u"OPP目标类型" and (rvalue == "GENERAL_ALL" or "TROOP_ALL"):
				# TODO 此处强撸，FIXME！
				func_name = "attrCmpFunc%d" % indx
				content = ""
				ret = 'opp:isRelevantType(' + rvalue + ')'
				src += cond_func_code % (func_name, content, ret)
				cond_funcs.append(func_name)
			else:
				lvalue = parse_right_var(lvalue, status_var_table, "\t\t\t\t\t")
				func_name = "attrCmpFunc%d" % indx
				content = "\n" + lvalue
				content += "\t\t\t\t\t__lvalue = __rvalue"
				content += "\n" + rvalue_str
				ret = "__lvalue %s __rvalue" % (tag)
				src += cond_func_code % (func_name, content, ret)	
				cond_funcs.append(func_name)
			#print lvalue, rvalue, tag
		else:
			err("Expr cond parse error, you must supply compare tag")
			print(value.encode('utf-8'))
			print(expr.encode('utf-8'))
			exit()
		indx = indx + 1
	if len(src) == 0:
		src = ''
	else:
		ret_str = 'local final = ('
		indx = 0
		for f_name in cond_funcs:
			if indx > 0:
				ret_str += " %s " % logic_tag
			ret_str += "%s()" % f_name
			indx = indx + 1
		ret_str += ")"
		src += "\n\t\t\t\t" + ret_str
		src += "\n\t\t\t\treturn final"
	return src

def parse_format_str(value, var_table = formula_var_table):
	# 找$F(...)的元素，括号内为右值，整个串作为format
	# 一个(...)为一个%s
	if value == "":
		return '''\n\t\t\t\t__rvalue = ""\n'''
	else:
		#try:
		if True:
			# 找$F(...)的元素，括号内为右值，整个串作为format
			# 一个(...)为一个%s
			ret = ""
			temp = value
			idx = 1
			ret_val = ""
			fmt = ""
			vals = ""
			fpos = 0
			pos = value.find("$F", fpos)
			while pos >= 0:
				spos = pos + 3 
				# 匹配括号
				embrace_num = 0
				tmp_pos = value.find("(", spos)
				while True:
					if tmp_pos < 0:
						break
					embrace_num += 1
					tmp_pos = value.find("(", tmp_pos + 1)
				epos = value.find(")", spos)
				while True:
					if embrace_num <= 1:
						break
					embrace_num -= 1
					epos = value.find(")", epos + 1)
				if epos >= 0:
					fmt += value[fpos:pos]
					fmt +="%s"
					expr = value[spos:epos]
					fpos = epos+1
					ret += parse_right_var(expr)
					ret += "\n\t\t\t\tlocal var%d = __rvalue\n"%idx 
					vals += ", var%d"%idx
					pos = value.find("$F", fpos)
				else:
					break
				idx += 1
			fmt += value[fpos:]
			if vals != "":
				ret += '''\n\t\t\t\t__rvalue = string.format(TEXT("''' + fmt + '''") ''' + vals + ")\n"
			else:
				ret += '''\n\t\t\t\t__rvalue = TEXT("''' + fmt + '''")'''
			return ret
			'''
		except Exception, ex:
			print(value)
			print(ex)
			print("error format list!!")
			'''
			#return '''\n\t\t\t\t__rvalue = ""\n'''


def replaceChineseTag(value):
	'''
	value.replace(u"）", ")")
	value.replace(u"（", "(")
	value.replace(u"＋", "+")
	value.replace(u"－", "-")
	value.replace(u"＊", "*")
	value.replace(u"／", "/")
	value.replace(u"，", ",")
	'''
	value = replace_str(value, u"）", ")")
	value = replace_str(value, u"（", "(")
	value = replace_str(value, u"＋", "+")
	value = replace_str(value, u"－", "-")
	value = replace_str(value, u"＊", "*")
	value = replace_str(value, u"／", "/")
	value = replace_str(value, u"，", ",")
	return value

def parse_value(head_info, value):
	conf_type = head_info['type']
	var_table = formula_var_table
	if head_info.has_key("var_table"):
		var_table = head_info["var_table"]
	ret_type = conf_type
	init_vars_str  = "\t\t\t\tlocal __rvalue = 0\n\t\t\t\tlocal __lvalue = 0\n"
	if conf_type == 'str':
		ret_val = value
	elif conf_type == 'text':
		ret_val = value
	elif conf_type == 'int':
		ret_val = value
	elif conf_type == 'format_str':
		ret_val = parse_format_str(value) 
		ret_val = "function(self, performerObj)\n%s" % init_vars_str + ret_val + "\n\t\t\t\treturn __rvalue\n\t\t\tend"
	elif conf_type == 'str_list':
		try:
			value = str(value)
			value.replace(u"，", ",")
			if len(value) == 0:
				ret_val = []
			else:
				ret_val = value.split(",")
		except Exception, ex:
			print(conf_type)
			print(value.encode("gbk"))
			print(ex)
	elif conf_type == 'int_list':
		value = str(value)
		value.replace(u"，", ",")
		ret_val = value
	elif conf_type == 'lua_formula_function':
		ret_val = parse_right_var(value, var_table)
		ret_val = ("function(self, performerObj)\n%s" % init_vars_str) + ret_val + "\n\t\t\t\treturn __rvalue\n\t\t\tend"
	elif conf_type == 'skill_damage_formula_function':
		ret_val = parse_right_var(value, var_table)
		ret_val = ("function(self, performerObj, opp)\n%s" % init_vars_str) + ret_val + "\n\t\t\t\treturn __rvalue\n\t\t\tend"
	elif conf_type == 'lua_skill_lvar_function':
		value = replaceChineseTag(value)
		ret_val = parse_expr(value, formula_var_table)
		if len(ret_val) == 0:
			ret_val = ''
			ret_type = "str"
		else:
			ret_val = ("function(self, performerObj)\n%s" % init_vars_str) + ret_val + "\n\t\t\t\treturn __rvalue\n\t\t\tend"
	elif conf_type == 'lua_lvar_function':
		value = replaceChineseTag(value)
		ret_val = parse_expr(value)
		if len(ret_val) == 0:
			ret_val = ''
			ret_type = "str"
		else:
			ret_val = ("function(self, skillObj, opp, damage)\n%s\n\t\t\t\tlocal __dDamage = 0\n%s" % (lvar_func_common, init_vars_str)) + ret_val + "\n\t\t\t\t__dDamage = __rvalue\n\t\t\t\treturn __dDamage\n\t\t\tend"
	elif conf_type == "list_to_dict":
		value = str(value)
		value.replace(u"，", ",")
		if len(value) == 0:
			ret_val = {}
		else:
			tmp = value.split(",")
			ret_val = {}
			for t in tmp:
				ret_val[t] = True
		ret_type = "dict"
	elif conf_type == "macro":
		ret_val = str(value)
	elif conf_type == "lua_cond_function":
		ret_val = parse_cond_expr(value)
		if len(ret_val) == 0:
			ret_val = ''
			ret_type = "str"
		else:
			ret_val = ("function(self, skillObj, opp, damage, isCritical, isDingshen, isCisha)\n%s" % init_vars_str) + ret_val + "\n\t\t\tend"
	return ret_val, ret_type

def preprocess_file(filepath):
	global begin
	global end
	head = ''
	tail = ''
	try:
		src_data = open(filepath, "rb").read()
		if len(src_data) != 0:
			hpos = src_data.find(begin, 0)
			tpos = src_data.find(end, hpos + 1)
			head = src_data[0:hpos]
			tail = src_data[tpos+len(end):]
	except IOError:
		head = ''
		tail = ''

	return head + begin, end+ tail


def write_skill(skill_data):
	try:
		skill_id = skill_data["__idx__"]
		filepath = skill_data_file(str(skill_id))
		filepath += ".lua"
		print(filepath)

		skill_type = skill_data["skillType"]["val"]
		skill_base = skill_base_dict[skill_type]["base"]
		skill_header = skill_base_dict[skill_type]["header"]
		head, tail = preprocess_file(filepath)
		head = head + common_skill_include % (skill_header, skill_id, skill_id, skill_base)
		f = open(filepath, "w+b")
		f.write(head)
		ioimpl.START_DATA_FILE(f)
		ioimpl.START_DICT("local skillData")
		for k, v in skill_data.iteritems():
			if k == "__idx__":
				continue
			val_type = v["type"]
			val = v["val"]
			#print "write attr before, type: ", type(val)
			ioimpl.WRITE_ATTR(k, val, val_type)
		ioimpl.END_DATA()
		f.write(common_skill_code % (skill_id, skill_id, skill_base, skill_id))
		f.write(tail)
	except Exception, ex:
		print skill_data
		print ex
		err("Write file error [%s]"%ex)
		exit()
	
	ioimpl.END()
	return str(skill_id)

def write_status(status_data):
	status_id = status_data["__idx__"]
	filepath = status_data_file(str(status_id))
	filepath += ".lua"
	status_id = str(status_id)
	class_name = status_id.capitalize()
	status_type = status_data["statusBaseClass"]["val"]
	base = status_base_dict[str(status_type)]["base"]

	print(filepath)

	try:
		head, tail = preprocess_file(filepath)
		head = head + common_status_include % (class_name, class_name, class_name, base)
		f = open(filepath, "w+b")
		f.write(head)
		ioimpl.START_DATA_FILE(f)
		ioimpl.START_DICT("local statusData")
		for k, v in status_data.iteritems():
			if k == "__idx__":
				continue
			val_type = v["type"]
			val = v["val"]
			ioimpl.WRITE_ATTR(k, val, val_type)
		ioimpl.END_DATA()
		f.write(common_status_code % (class_name, class_name))
		f.write(tail)
	except Exception, ex:
		err("Write file error [%s]"%ex)
		exit()
	
	ioimpl.END()
	return str(status_id)


def record_all_skills(all_skillids):
	filepath = skill_data_file("all_skill.lua")
	head, tail = preprocess_file(filepath)

	f = open(filepath, "w+b")
	f.write(head)
	ioimpl.START_DATA_FILE(f)
	ioimpl.START_DICT("allSkillConf")
	ioimpl.WRITE_ATTR("allSkills", all_skillids, "str_list")
	ioimpl.END_DATA()
	f.write(tail)
	ioimpl.END()

def record_all_status(all_status):
	print all_status
	filepath = status_data_file("all_status.lua")
	head, tail = preprocess_file(filepath)

	f = open(filepath, "w+b")
	f.write(head)
	ioimpl.START_DATA_FILE(f)
	ioimpl.START_DICT("allStatusConf")
	ioimpl.WRITE_ATTR("allStatus", all_status, "str_list")
	ioimpl.END_DATA()
	f.write(tail)
	ioimpl.END()

def parse_sheet_fields(sheet, config_table):
	src = []
	for cidx in range(2, sheet.ncols):
		field_src = {}
		for ridx in range(0, sheet.nrows):
			head = format_value(sheet.cell_value(ridx, 0), sheet.cell_type(ridx, 0))
			if head == '' or not config_table.has_key(head):
				continue
			head_info = config_table[head]

			key = sheet.cell_value(ridx, 1)
			value = sheet.cell_value(ridx, cidx)
			xls_type = sheet.cell_type(ridx, cidx)
                        value = format_value(value, xls_type)

			if head_info.has_key('index'):
				field_src["__idx__"] = value
			v, t = parse_value(head_info, value)	
			field_src[key] = {'val':v, 'type':t}
		src.append(field_src)
	
	#print(src)
	return src

all_skillids = []
all_status = []

def parse_skills(sheet):
	src = parse_sheet_fields(sheet, skill_head_type_table)
	all_skillids_t = map(write_skill, src)
	all_skillids.extend(all_skillids_t)

skillSheetNames = {
	u"普通攻击":True, 
	u"装备技能":True,
}

statusSheetNames = {
	u"状态设定":True, 
	u"职业技能":True,
	u"装备状态":True,
}

def parse_status(sheet):
	src = parse_sheet_fields(sheet, status_head_type_table)
	all_status_t = map(write_status, src)
	all_status.extend(all_status_t)

def sheet_need_parse(sheet):
	if sheet.name in skillSheetNames or sheet.name in statusSheetNames:
		return True
	return False

def parse_file(filepath):
	try:
		book = xlrd.open_workbook(filepath)
	except Exception, ex:
		err("can't open file: %s [%s]"%(filepath, ex))
		usage()
		exit()
	
	sheets = filter(sheet_need_parse, book.sheets())
	for sheet in sheets:
		if sheet.name in skillSheetNames:
			parse_skills(sheet)
		elif sheet.name in statusSheetNames:
			parse_status(sheet)
	
	return True 

if __name__ == "__main__":
	if len(sys.argv) < 2:
		usage()
	else:
		if sys.argv[1] == "--skill":
			for file_name in SKILL_FILE_NAME:
				filepath = doc_file(file_name)
				parse_file(filepath)
			record_all_skills(all_skillids)
		elif sys.argv[1] == "--status":
			filepath = doc_file(STATUS_FILE_NAME)
			parse_file(filepath)
			record_all_status(all_status)
		else:
			usage()


