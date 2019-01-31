cd projects/x5launcher/src/main/assets/
let count=0
let complete=0
function count_dir() {
        for file in `ls $1`       #注意此处这是两个反引号，表示运行系统命令
        do
            if [ -d $1"/"$file ]  #注意此处之间一定要加上空格，否则会报错
            then
                count_dir $1"/"$file
            else
                let count++
            fi
        done
}

function read_dir(){
        for file in `ls $1`       #注意此处这是两个反引号，表示运行系统命令
        do
            if [ -d $1"/"$file ]  #注意此处之间一定要加上空格，否则会报错
            then
                read_dir $1"/"$file
            else
                let complete++
                name=`echo $1"/"$file`   #在此处处理文件即可
                f=${name:2:100}
		echo "$f" >> files.ini
                printf "%-80s \033[32m[%3d/%3d]\033[0m\n" "find $f" $complete $count
            fi
        done
}

touch files.ini
count_dir .
read_dir .
echo list complete!!!
