#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2018 Register <registerdedicated(at)gmail.com>
#
# Distributed under terms of the GPLv3 license.

import sys
import os
import md5
import copy
import json
import zipfile
import config

VERSION_FILE = ""
SRC_DIR = ""
PUBLISH_DIR = ""
RAW_PUBLISH_DIR = ""

PUBLISH_SRC_DIR = ""
VERSION = "0.0.0"
diff_file = ["index.html", "manifest.json", "index_fbadvert.html"]
all_lang = ["cn", "en", "tw", "th", "id"]

device_config = {
    "mobile": {
        "resource_dir": "resource/",
    },

    "pc": {
        "resource_dir": "resource_pc/",
    },
}

channel_config = {
    "ctc_fire2333": {
        "tdAppid": "DA82D687626F4F3185D914C449302546",
        "release": True,
    },

    "debug": {
        "tdAppid": "DA82D687626F4F3185D914C449302546",
        "release": False,
    },

    "lzd_pkgsdk": {
        "tdAppid": "DA82D687626F4F3185D914C449302546",
        "release": True,
    },

    "lzd_handjoy": {
        "tdAppid": "",
        "release": True,
    }
}

def get_res_lang_path(res_dir, res_path, lang):
    path = res_dir + res_path
    path.replace("assets", "assets_" + lang)
    if os.path.isfile(PUBLISH_SRC_DIR + "/" + path):
        return path
    else:
        return res_dir + res_path

def gen_new_version():
    f = open(VERSION_FILE, "r")
    version_data = f.read()
    f.close()
    version = version_data.split(".")
    new_version = copy.copy(version)
    new_version[2] = str( int(new_version[2]) + 1)
    new_version_data = ".".join(new_version)
    f = open(VERSION_FILE, "w")
    f.write(new_version_data)
    f.close()
    global VERSION
    VERSION = new_version_data
    return new_version_data

def is_diff(file):
    file1 = open(PUBLISH_DIR + "/" + file, "r")
    data1 = file1.read()
    file1.close()
    file2 = open(PUBLISH_SRC_DIR + "/" + file, "r")
    data2 = file2.read()
    file2.close()
    return md5.md5(data1).hexdigest() != md5.md5(data2).hexdigest()

def get_file_version(path):
    file_info = path.split("?")
    file_path = file_info[0]
    version = ""
    if len(file_info) > 1:
        # v=0.0.1
        version = file_info[1][2:]
    return file_path, version

def gen_file_with_version(path, version):
    if not version:
        return path
    return path + "?v=" + version

def do_publish_js(tag, dst_manifest, src_manifest):
    dst_js = {}
    for path in dst_manifest[tag]:
        file_path, version = get_file_version(path)
        dst_js[file_path] = version

    for i, file_path in enumerate(src_manifest[tag]):
        if file_path not in dst_js:
            # 新文件
            diff_file.append(file_path)
            src_manifest[tag][i] = gen_file_with_version(file_path, VERSION)
        elif is_diff(file_path):
            # 有更新的文件
            diff_file.append(file_path)
            src_manifest[tag][i] = gen_file_with_version(file_path, VERSION)
        else:
            # 无更新的老文件
            src_manifest[tag][i] = gen_file_with_version(file_path, dst_js[file_path])


def merge_core_js(manifest):
    core_file = open(PUBLISH_SRC_DIR + "/js/core.min.js", "wa")
    fairygui_path = ""
    for path in manifest["initial"]:
        if "fairygui" in path:
            fairygui_path = path
        else:
            file_path = PUBLISH_SRC_DIR + "/" + path
            _file = open(file_path, "r")
            core_file.write(_file.read())
            _file.close()
    core_file.close()
    manifest["initial"] = ["js/core.min.js", fairygui_path]

def publish_js(channel):
    dst_manifest_file = open(PUBLISH_DIR + "/manifest.json", "r")
    dst_manifest = json.loads( dst_manifest_file.read() )
    dst_manifest_file.close()
    src_manifest_file = open(PUBLISH_SRC_DIR + "/manifest.json", "r")
    src_manifest = json.loads( src_manifest_file.read() )
    src_manifest_file.close()
    merge_core_js(src_manifest)
    do_publish_js("initial", dst_manifest, src_manifest)
    do_publish_js("game", dst_manifest, src_manifest)

    src_manifest["version"] = VERSION
    if channel:
        src_manifest["release"] = channel_config[channel]["release"]
        src_manifest["tdAppid"] = channel_config[channel]["tdAppid"]
        src_manifest["channel"] = channel

    src_manifest_file = open(PUBLISH_SRC_DIR + "/manifest.json", "w")
    src_manifest_file.write( json.dumps(src_manifest, sort_keys=True, separators=(',', ':')) )
    src_manifest_file.close()

def publish_resource(device):
    res_dir = "resource/"
    res_json_path = "/" + res_dir + "default.res.json"
    src_res_file = open(PUBLISH_SRC_DIR + res_json_path, "r")
    src_res = json.loads( src_res_file.read() )
    src_res_file.close()
    lang_to_dst_res = {}
    lang_to_publish_res = {}
    all_lang2 = ["raw"]
    all_lang2.extend(all_lang)
    for lang in all_lang2:
        if lang == "raw":
            res_json_path = "/resource/default.res.json"
        else:
            res_json_path = "/resource/default.res." + lang + ".json"
        dst_res_file = open(PUBLISH_DIR + res_json_path, "r")
        dst_res = json.loads( dst_res_file.read() )
        dst_res_file.close()
        diff_file.append(res_json_path)
        lang_to_dst_res[lang] = dst_res
        lang_to_publish_res[lang] = copy.deepcopy(src_res)
        lang_to_publish_res[lang]["version"] = VERSION

    dst_resource = {}
    res_path = {}
    for lang, dst_res in lang_to_dst_res.items():
        for res_info in dst_res["resources"]:
            path = res_info["url"]
            file_path, version = get_file_version(path)
            dst_resource[file_path] = version

    for i, res_info in enumerate(src_res["resources"]):
        file_path = res_info["url"]
        res_path[res_info["name"]] = [file_path]

        for lang in all_lang2:
            file_path = res_info["url"]
            publish_res = lang_to_publish_res[lang]
            if lang != "raw":
                file_path2 = file_path.replace("assets/", "assets_" + lang + "/")
                if os.path.isfile(PUBLISH_SRC_DIR + "/" + res_dir + file_path2):
                    file_path = file_path2
                    res_path[res_info["name"]].append(file_path)
                else:
                    publish_res["resources"][i]["url"] = lang_to_publish_res["raw"]["resources"][i]["url"]
                    continue

            if file_path not in dst_resource or not os.path.isfile(PUBLISH_DIR + "/" + res_dir + file_path):
                # 新文件
                diff_file.append(res_dir + file_path)
                file_url = gen_file_with_version(file_path, VERSION)
            elif is_diff(res_dir + file_path):
                # 有更新的文件
                diff_file.append(res_dir + file_path)
                file_url = gen_file_with_version(file_path, VERSION)
            else:
                # 无更新的老文件
                file_url = gen_file_with_version(file_path, dst_resource[file_path])
            publish_res["resources"][i]["url"] = file_url
    
    for lang, publish_res in lang_to_publish_res.items():
        if lang == "raw":
            res_json_path = "/resource/default.res.json"
        else:
            res_json_path = "/resource/default.res." + lang + ".json"
        res_file = open(PUBLISH_SRC_DIR + res_json_path, "w")
        res_file.write( json.dumps(publish_res, sort_keys=True, separators=(',', ':')) )
        res_file.close()
    zip_file(res_dir, src_res, res_path)

def zip_file(res_dir, res_json, res_path):
    old_dir = os.getcwd()
    os.chdir(PUBLISH_SRC_DIR + "/" + res_dir)
    for group_info in res_json["groups"]:
        group_name = group_info["name"]
        keys = group_info["keys"].split(",")
        zip_file = zipfile.ZipFile(group_name + ".zip", 'w')
        for k in keys:
            if k not in res_path:
                raise Exception("fuck key %s no path" % k)
            for url in res_path[k]:
                url = url.split("?v=")[0]
                zip_file.write(url, compress_type=zipfile.ZIP_DEFLATED)
        if group_name == "init_wx":
            zip_file.write("default.res.json", compress_type=zipfile.ZIP_DEFLATED)
        zip_file.close()
        print "zip %s ok" % group_name
        diff_file.append(res_dir + group_name + ".zip")

    os.chdir(old_dir)

def copy_diff_file():
    for file_path in diff_file:
        print "update  " + file_path
        publish_dir = os.path.dirname(PUBLISH_DIR + "/" + file_path)
        os.system( "mkdir -p " + publish_dir )
        os.system( "cp " + PUBLISH_SRC_DIR + "/" + file_path + " " + PUBLISH_DIR + "/" + file_path )

def fuck(device, channel):
    res_dir = device_config[device]["resource_dir"]
    #diff_file.append("resource/default.res.json")
    #os.system("cp " + SRC_DIR + "/wingProperties_" + device + ".json " + 
    #        SRC_DIR + "/wingProperties.json")
    os.system("python tools/setup.py " + device)
    version = gen_new_version()
    publish_cmd = "cd " + SRC_DIR  + "&& egret publish --version " + version
    os.system(publish_cmd)
    global PUBLISH_SRC_DIR
    PUBLISH_SRC_DIR = SRC_DIR + "/bin-release/web/" + version
    #os.system( "cp " + config.SRC_DIR + "/template/runtime/index.html " + PUBLISH_SRC_DIR + "/index.html" )
    os.system( "cp " + SRC_DIR + "/version " + PUBLISH_SRC_DIR + "/version" )
    os.system( "cp " + SRC_DIR + "/template/web/index_" + device + "_" +
            channel + ".html " + PUBLISH_SRC_DIR + "/index.html" )
    os.system( "cp " + SRC_DIR + "/template/web/index_fbadvert.html " + PUBLISH_SRC_DIR + "/index_fbadvert.html" )
    os.system( "cp -r " + SRC_DIR + "/" + res_dir[:-1] + " " + PUBLISH_SRC_DIR + "/resource" )

    if not os.path.isfile(PUBLISH_DIR + "/index.html"):
        os.system( "cp -r " + PUBLISH_SRC_DIR + "/* " + PUBLISH_DIR + "/" )
        for lang in all_lang:
            os.system( "cp " + PUBLISH_DIR + "/resource/default.res.json " + PUBLISH_DIR + "/resource/default.res." + lang + ".json" )
        return

    # TODO ttf
    publish_js(channel)
    publish_resource(device)
    copy_diff_file()

if __name__ == "__main__":
    channel = sys.argv[1]
    device = "mobile"
    VERSION_FILE = config.get_version_file(device)
    SRC_DIR = config.get_src_dir(device)
    PUBLISH_DIR = config.get_publish_dir(device)
    cfg = channel_config[channel]
    fuck(device, channel)

