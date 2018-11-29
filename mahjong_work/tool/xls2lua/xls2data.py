# -*- coding: utf-8 -*-
#! /usr/bin/env python

# 2010-03-10 11:31:43 by BlueQ  change the target language from lua to python
# 2010-03-15 12:05:38 by BlueQ  attention: if the key is start with '#' then the column will not output
# 2010-03-15 13:21:19 by BlueQ  empty key also means not output this column, fix the bug: "'" in strings
# 2010-03-16 12:34:07 by BlueQ  change the key string from 'id' to '__id__', because this is internal used key word
#				use python's rule, internal variable starts with '__' ends with '__'
# 2010-03-24 17:49:31 by BlueQ  add type define
# 2010-03-26 01:23:07 by BlueQ  reimplement ( more SAMPLE and more BEAUTIFUL )
import os
import re
import string
import sys

VERSION = '$Revision: 1528 $'
DATA_DIR = '../data/info/'
DOC_DIR = './'
KEY_STR = '__id__'		# define which row to be the key column

# check for module xlrd
try:
	import xlrd
except ImportError:
	print ">>> [E] no model xlrd, please install it"
	exit()

import xlrd
LOCALE = "cn"

def load_config():
	# if local file config.py exist then use the configurations in it
	try:
		global LOCALE
		global DOC_DIR
		global DATA_DIR
		if LOCALE == "cn":
			import config as config
		elif LOCALE == "yn":
			import config_yn as config
		else:
			import config
		DATA_DIR = config.DATA_DIR
		DOC_DIR = config.DOC_DIR
		print DATA_DIR
		print DOC_DIR
	except ImportError:
		print ">>> -----------------------------------------------------------------"
		print ">>> [W] No tools/config.py, use the default configurations in tools/xls2python.py"
		print ">>>     If you want to use you own configurations please:"
		print ">>>     1. Copy tools/config.py.template to tools/config.py"
		print ">>>     2. Change the variable DOC_DIR to you own document directory"
		print ">>>     3. Change the variable DATA_DIR to you own data directory(default is %s)"%(DATA_DIR)
		print ">>> -----------------------------------------------------------------"

# write protocols
ioprotocol = None

def doc_file(name): return DOC_DIR + name
def data_file(name): return DATA_DIR + name
def encode(s): return s #.encode('gbk')
def format_value(value, vtype):
	# if the value is interger number then make it interger
	if vtype == 2 and value == int(value): 
		return int(value)
	else:
		return value

# translate one work sheet
# take a sheet
# return a list like:
# [
#	[xxx, xxx, ..., xxx],
#	[xxx, xxx, ..., xxx],
#	...
# ]

def sheet2dict(sheet):
	data = []
	# print("\t%s" % sheet.name)
	for ridx in xrange(sheet.nrows):
		row = []
		for cidx in xrange(sheet.ncols):
			value = sheet.cell_value(ridx, cidx)
			vtype = sheet.cell_type(ridx, cidx)
			v = format_value(value, vtype)
			row.append(v)
		data.append(row)
	return (sheet.name, data)

# check the sheet, if it need output return True else return False
# if the first line of sheet is "outpu   TRUE", it need translate
# otherwise it need not.
def need_output(sheet):
	try:
		return sheet.cell_value(0,0) == "output" and sheet.cell_value(0,1)
	except IndexError:
		return False

	return False


# process the header of excel, and get configurations
def process_header(data):
	file_name = None	# output file name
	key_row = None		# the key of the dict is in which row
	start_row = None	# from which row the data starts
	dict_name = None	# the output dict name
	code_sheet = None
	for row in data:
		if len(row) < 2: continue
		if row[0] == "file_name":
			file_name = row[1]
		elif row[0] == "key_row":
			key_row = row[1]
		elif row[0] == "start_row":
			start_row = row[1]
		elif row[0] == "dict_name":
			dict_name = row[1]
		elif row[0] == "code_sheet":
			code_sheet = row[1]
	return file_name, key_row, start_row, dict_name, code_sheet

# get the key name and clumn type
def process_key(key):
	# Rules:
	# 1. no key the clumn not output
	# 2. if the key start with '#' then the clumn not output( think of python comment )
	# 3. if the key start with '--' then the clumn not output( think of lua comment ) 
	# key has the following type: int, float, str, py, lua, default
	if key == "": return None, None
	if re.match(r"^#.*", key): return None, None
	if re.match(r"\-\-.*", key): return None, None
	ls = key.replace(")", "").split("(")
	ls.append("default")
	return ls[0], ls[1]
	
# store dict to file
def store_dict(xls_name, sheet_name, data, sheets):
	file_name, key_row, start_row, dict_name, code_sheet = process_header(data)
	
	# slice the real data
	real_data = ( row for row in iter(data[start_row-1:]) if any(row) )

	# process key
	keys = [ process_key(key) for key in data[key_row-1] ]

	# the __id__ is in which clumn
	id_index = 0
	for i,(key,_) in enumerate(keys):
		if key == KEY_STR:
			id_index = i
			break
	# process the key data

	py_data = {}
	ioprotocol.START_DATA(xls_name, data_file(file_name), encode(sheet_name))
	if code_sheet:
		for row in real_data:
			# get the id and its type
			id_ = row[id_index]
			type_ = keys[id_index][1]

			item = {}
			for i in xrange(len(row)):
				if i == id_index: continue # skip the __id__ clumn
				if keys[i] == (None, None): continue # skip the clumn 
				key = keys[i][0]
				type_ = keys[i][1]

				if type_ == "int":
					try:
						item[key] = int(float(row[i]))
					except:
						item[key] = 0
				elif type_ == "float":
					try:
						item[key] = float(row[i])
					except:
						item[key] = 0.0						
				else:
					item[key] = unicode(row[i])
		
			py_data[id_] = item
	else:
		ioprotocol.START_DICT_PROTECT(dict_name)
		for row in real_data:
			# get the id and its type
			id_ = row[id_index]
			type_ = keys[id_index][1]
			
			if id_ == "":
				continue

			ioprotocol.START_ROW(id_, type_)

			for i in xrange(len(row)):
				if i == id_index: continue # skip the __id__ clumn
				if keys[i] == (None, None): continue # skip the clumn 
				key = keys[i][0]
				type_ = keys[i][1]
				try:
					ioprotocol.WRITE_ATTR(key, row[i], type_)
				except:
					print u">>> [E] parse table error " #, xls_name , sheet_name, 
					print "id=",id_,"key=", key
					print key, row[i], type_
					print row
					sys.exit()
			ioprotocol.END_ROW()
			
		ioprotocol.END_DATA_PROTECT()


	# 代码表格
	# print ">>>>>", code_sheet
	if code_sheet:
		# find the sheet
		sheet = None

		for sh in sheets:
			# print ">>>", sh.name
			if sh.name == code_sheet:
				sheet = sh
		# 写入数据
		if sheet:
			# print py_data

			def main_(mapping):
				print u">>> [E] main 方法必须定义"
		
			try:
				code = sheet.cell_value(0,0)
			except:
				print u">>> [E] 处理代码未填写"
					
				#exec("print 'test'")
				#main = main_

			print u">>> [I] 执行附加代码(%s)..."%code_sheet
			main = execute_string(code)
			dicts = main(py_data)

			if not isinstance(dicts, dict):
				print u">>> [E] 附加代码要返回字典列表"
			else:
				for name in dicts.iterkeys():
					mapping = dicts[name]
					ioprotocol.WRITE_VAR(name, mapping)
				
	ioprotocol.END()
				
	#print encode(">>> [I] write sheet %s to %s success"%(sheet_name, file_name))

def execute_string(code):
	exec code
	return main

# excel to python convert function
def excel2python(filename):
	print ">>> processing", filename
	if not os.path.isfile(filename):
		print  ">>> [E] %s is not a valid filename" %	filename
		return 
	book = xlrd.open_workbook(filename)#, formatting_info=True)
	
	# choose the sheets that need translate to python dict
	sheets = filter( need_output, book.sheets() )

	# get the raw data of these sheets
	sheet_datas = map( sheet2dict, sheets )

	# write the data to file
	[ store_dict(filename, name, data, book.sheets()) for (name, data) in sheet_datas ]

def notice():
	print "------- xls2data %s -------"%VERSION
	print "-     2010-03-14 14:31:43 by BlueQ       "
	print "--------------------------------------------"

def process_args():
    # parse command line options
	import getopt,sys
	try:
		opts, args = getopt.getopt(sys.argv[1:], "hf", ["help", "lua", "python", "file", "locale="])
	except getopt.error, msg:
		print msg
		print "for help use --help"
		sys.exit(2)
	# install default write protocol implement
	global ioprotocol

	# install write protocol
	for o, a in opts:
		if o in ("-h", "--help"):
			print "for lua: xls2data.py -l lua"
			print "for python: xls2data.py -l python"
			print "for help: xls2data.py -h | xls2data.py --help"
			sys.exit(0)
		elif o in ("--lua", ):
			import imp_luatable
			ioprotocol = imp_luatable

		elif o in ("--python", ):
			import imp_pydict
			ioprotocol = imp_pydict
		elif o in ("--locale", ):
			global LOCALE
			LOCALE = a
	return [ f.replace("\\", "/") for f in args]

def get_files(path):
	fs = []
	for dir,subdir,files in os.walk(path):
		for f in files:
			fs.append(dir+"/"+f)
	return fs

if __name__=="__main__":
	# translation the excel according to the file filelist.csv
	# why use csv format;
	# 1. easy to merge because it is text file format(svn)
	# 2. easy to edit use excel. micsoft excel can read csv direct

	notice()
	files = process_args()

	load_config()

	# application config
	LIST_FILE = doc_file("listfile.txt")

	# read from the listfile
	import codecs
	listfile = codecs.open(LIST_FILE, mode='r')
	lines = listfile.readlines()
	listfile.close()

	if len(files) == 0:
		files = get_files(DOC_DIR)
		files += lines

		files = (file_.strip("\r\n ") for file_ in files if re.match(r'.*\.xlsx?$', file_))
	# filter the excel files which end with .xls
	# files = ( line.rstrip('\n') for line in lines if re.match(r'.*\.xls$',line) )

	# do the translation
	map( lambda file_:excel2python(file_), files )

