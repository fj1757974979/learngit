#coding:utf-8

import sys
reload(sys)
sys.setdefaultencoding('utf-8')

import re
import codecs
import xlrd
import os
import config
import json

XLS_PATH = os.getenv("HOME") +  "/puppy/king_design/exl/"
#XLS_PATH = "../king_design/exl/"

def get_dst_path(device):
    if device == "mobile":
        return "resource/src/data/"
    else:
        return "resource_pc/src/data/"

def get_xls_files(device):
    if device == "pc":
        return [XLS_PATH + "configure_king_pc.xlsx"]
    else:
        xlsx_files = []
        for f in os.listdir(XLS_PATH):
            if "$" in f:
                continue
            if f[-4:] == "xlsx":
                xlsx_files.append(XLS_PATH + f)
        return xlsx_files


class StringType(object):
    def gen_ts_str(self, value):
        return "\"%s\"" % str(value)

class TextType(object):
    def gen_ts_str(self, value):
        if not value:
            value = 0
        return "\"#TEXT_%s\"" % str(value)

class IntType(object):
    def gen_ts_str(self, value):
        if not value:
            value = 0
        return str(int(value))

class FloatType(object):
    def gen_ts_str(self, value):
        if not value:
            value = 0.0
        return str(value)

class ListType(object):
    def __init__(self, elemType):
        self.elemType = elemType

    def gen_ts_str(self, value):
        if not value:
            return "[]"
        strVlist = str(value).split(";")
        vlist = []
        for v in strVlist:
            elem = self.elemType.gen_ts_str(v)
            if elem and elem != "[]":
                vlist.append(elem)
        return "[%s]" % ", ".join(vlist)

class ArgListType(object):
    def __init__(self, elemType):
        self.elemType = elemType

    def gen_ts_str(self, value):
        if not value:
            return "[]"
        strVlist = str(value).split(":")
        vlist = []
        for v in strVlist:
            elem = self.elemType.gen_ts_str(v)
            if elem and elem != "[]":
                vlist.append(elem)
        return "[%s]" % ", ".join(vlist)

def gen_key_type(_type):
    if _type == "str":
        return StringType()
    if _type == "int":
        return IntType()
    if _type == "text":
        return TextType()
    if _type == "float":
        return FloatType()
    if _type[:4] == "list":
        elemType = gen_key_type(_type[5:-1])
        return ListType(elemType)
    if _type[:7] == "arglist":
        elemType = gen_key_type(_type[8:-1])
        return ArgListType(elemType)
    return None

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
    ls[1] = gen_key_type( ls[1].replace(" ", "") )
    return ls[0], ls[1]

def gen_header(cls_name):
    head = ""
    return """
{
            """ 

def gen_tail(cls_name):
    if cls_name == "text":
        tail = "\n\tCore.StringUtils.textGameData = Data.text;\n"
    elif cls_name == "text2":
        tail = "\n\tCore.StringUtils.textGameData2 = Data.text;\n"
    else:
        tail = ""
    return """
   }
    """ 

def process_header(data):
    key_row = None              # the key of the dict is in which row
    for row in data:
        if len(row) < 2:
            continue
        elif row[0] == "key_row":
            key_row = row[1]
            break
    return key_row

def sheet2ts(device, sheet_data, cls_name):
    key_row = process_header(sheet_data)
    keys = [ process_key(key) for key in sheet_data[key_row-1] ]
    if keys[0][0] != "__id__":
        print "not __id__"
        return
    if not isinstance(keys[0][1], IntType) and not isinstance(keys[0][1], StringType):
        print "wrong __id__ type %s" % keys[0][1]
        return

    real_data = ( row for row in iter(sheet_data[key_row:]) if any(row) )
    tsfilename = get_dst_path(device) + cls_name + ".json"
    f = codecs.open(tsfilename, "w", "utf-8")
    f.write(gen_header(cls_name))
    _ids = []

    flagi = 0
    for i, row in enumerate(real_data):
        _v = row[0]
        if not _v:
            continue

        flagj = 0
        if flagi != 0:
            f.write(",\n\t\t\t")
        flagi += 1

        for j, (k, t) in enumerate(keys):
            if not k:
                continue

            if flagj == 0:
                if isinstance(keys[0][1], IntType):
                    _ids.append(int(row[j]))
                    f.write("\"%s\": {" % str(row[j]))
                else:
                    _ids.append(str(row[j]))
                    f.write('''"%s": {''' % str(row[j]))
                flagj += 1
                #continue
            #elif flagj == 1:
                f.write("\"%s\": " % k)
            else:
                f.write(", \"%s\": " % k)
            flagj += 1

            v = row[j]
            if t:
                f.write(t.gen_ts_str(v))
            else:
                print "what the fuck type"
                print tsfilename
                print "i=%d, j=%d" % (i, j)
                print "k=%s, v=%s, t=%s" % (k, v, t)
                return

        f.write(" }")

    #f.write("keys:%s,\n" % _ids)
    f.write(gen_tail(cls_name))
    f.close()

def format_value(value, vtype):
    if vtype == 2 and value == int(value):
        return int(value)
    else:
        return value

def sheet2dict(sheet):
    data = []
    for ridx in range(sheet.nrows):
        row = []
        for cidx in xrange(sheet.ncols):
            value = sheet.cell_value(ridx, cidx)
            vtype = sheet.cell_type(ridx, cidx)
            v = format_value(value, vtype)
            row.append(v)
        data.append(row)
    return data

def need_output(sheet):
    try:
        if sheet.name == "errcode":
            return False
        return (sheet.cell_value(1,0) == "client_output" and sheet.cell_value(1,1)) or sheet.name == "text"
    except IndexError:
        return False
    return False

def parse(device, sheet_name_list):
    cls_names = []
    path =  get_dst_path(device)
    path = os.path.dirname(path) 
    path = os.path.dirname(path)
    for xls_file in get_xls_files(device):
        book = xlrd.open_workbook(xls_file)
        sheets = filter( need_output, book.sheets() )
        for sheet in sheets:
            print "i am fucking %s ..." % sheet.name
            sdata = sheet2dict(sheet)
            sheet2ts(device, sdata, sheet.name)
	    cls_names.append(sheet.name)
            print "%s fuck done" % sheet.name

    # 输出文件名
    f = open(path + "/start.json", "w")
    f.write(json.dumps(cls_names))
    f.close() 

if __name__ == "__main__":
    #device = sys.argv[1]
    device = "mobile"
    parse(device, config.get_parse_sheet_name())
