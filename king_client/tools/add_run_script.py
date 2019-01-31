
# -*- coding: utf-8 -*- 
import os 
import json
rootPath = "resource"
def walkFiles(rootDir, result): 
    list_dirs = os.walk(rootDir) 
    for root, dirs, files in list_dirs: 
        for d in dirs: 
            pass
        for f in files: 
            result.append([os.path.join(root, f), f])

files = []
walkFiles(rootPath + "/src", files)

jsFiles = [[full, file.replace(".json", "_json")] for full,file in files if file.find(".json") != -1]

# generate start.js
#fo = open(rootPath + "/src/start.json", "w");
#fo.writelines(["dofile_async(\"" + file + "\");\n" for full, file in jsFiles if file != "start_json"])
#fo.close()
# change default.res.json

jsonstr = ""
res = open (rootPath + "/default.res.json", "r")
jsonstr = res.read()
res.close()

resjson = json.loads(jsonstr)

resjson["resources"] = [ fileInfo for fileInfo in resjson["resources"] if not (fileInfo["url"].find("src/") != -1 and fileInfo["url"].find(".js") != -1)]
resjson["resources"].extend([{"url":full.replace("resource/", ""), "type":"json", "name":file} for full, file in jsFiles])
for group in resjson["groups"]:
    if group["name"] == "json_wx":
        group["keys"] = ",".join(file for full, file in jsFiles)
    	print group["keys"]

res = open (rootPath + "/default.res.json", "w")
res.write(json.dumps(resjson, sort_keys=True, indent=4, separators=(',', ': ')))
res.close()
