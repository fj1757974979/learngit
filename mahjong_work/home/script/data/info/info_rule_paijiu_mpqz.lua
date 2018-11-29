-- ------------------------------
-- desc: generated by xls2data.py
-- source: poker_rules.xlsx
-- sheet: 牌九-明牌抢庄
-- ------------------------------


data = table.protect({
	[1] = {
		['optionText1'] = TEXT('明牌抢庄'),
		['optionRanking'] = 1,
		['optionType'] = 1,
		['optionMenu'] = 'paijiu_mpqz',
		['defaultMenu'] = 'paijiu_mpqz',
		['isHide'] = 0,
	},
	[2] = {
		['optionText1'] = TEXT('局数'),
		['optionRanking'] = 2,
		['optionType'] = 1,
		['optionMenu'] = 'round_12;round_24',
		['defaultMenu'] = 'round_12',
		['isHide'] = 0,
	},
	[3] = {
		['optionText1'] = TEXT('抢庄'),
		['optionRanking'] = 3,
		['optionType'] = 1,
		['optionMenu'] = 'paijiu_qz_1;paijiu_qz_2;paijiu_qz_3',
		['defaultMenu'] = 'paijiu_qz_1',
		['isHide'] = 0,
	},
	[4] = {
		['optionText1'] = TEXT('压分'),
		['optionRanking'] = 4,
		['optionType'] = 1,
		['optionMenu'] = 'paijiu_yf_1_4;paijiu_yf_5_8',
		['defaultMenu'] = 'paijiu_yf_1_4',
		['isHide'] = 0,
	},
	[5] = {
		['optionText1'] = TEXT('推注'),
		['optionRanking'] = 5,
		['optionType'] = 1,
		['optionMenu'] = 'paijiu_tui_none;paijiu_tui_5',
		['defaultMenu'] = 'paijiu_tui_none',
		['isHide'] = 0,
	},
	[6] = {
		['optionText1'] = TEXT('翻倍'),
		['optionRanking'] = 6,
		['optionType'] = 1,
		['optionMenu'] = 'paijiu_double_none;paijiu_double_normal;paijiu_double_crazy',
		['defaultMenu'] = 'paijiu_double_none',
		['isHide'] = 0,
	},
})