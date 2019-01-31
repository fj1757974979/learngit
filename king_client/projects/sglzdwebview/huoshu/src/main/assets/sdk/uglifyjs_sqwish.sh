#!/bin/sh
#js css压缩,生成更新包打包

CDN_SERVER='http://cdn.9133.com/static'


DIR_PATH="$( cd "$( dirname "$0"  )" && pwd  )"
echo "$DIR_PATH" 
cd $DIR_PATH
VERSION=`cat version.txt`
DIR_NAME=${DIR_PATH##*/}
ZIP_FILE="${DIR_NAME}_${VERSION}.zip"
SAVE_DIR="dst"
MD5=''
echo $DIR_NAME



function make_new_zip_file {
    cd $DIR_PATH
    mkdir -pv dst
    save_zip_file="${SAVE_DIR}/${ZIP_FILE}"
    [ -f "$save_zip_file" ] && rm "$save_zip_file" && echo "rm $save_zip_file"
    echo "zip $ZIP_FILE"
    zip  -x 'uglifyjs_sqwish.sh'  -x 'v.txt' -x '*.svn/*' -x "${SAVE_DIR}/*" -x "${ZIP_FILE}"  -r "${save_zip_file}" ./
    MD5=`md5sum dst/${ZIP_FILE} |cut -d ' ' -f1`

}
function make_version_file {
    make_new_zip_file
    cd $DIR_PATH
    URL="${CDN_SERVER}/${DIR_NAME}/${SAVE_DIR}/${ZIP_FILE}"
    echo "${VERSION}|${MD5}|${URL}" > v.txt
    cat v.txt
}
function uglifyjs_js_css {
    cd $DIR_PATH
    cd js/
    for f in `ls *.js`;do
        uglifyjs $f -m -o $f
    done
    cd ../skin

    unalias mv

    for f in `ls *.css`;do
    if [ -f "$f" ];then 

        sqwish $f 
        new_f=`basename $f css`
        new_f="$new_f""min.css"
        echo "  mv $new_f  $f"
        [ -f "$new_f" ] && mv $new_f  $f
    fi
    done
    cd ..
}


uglifyjs_js_css
make_version_file



