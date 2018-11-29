#!bin/bash
root=`ls home/script/net/proto`
function parse_file()
{
	path=$1
	command="protoc --plugin=protoc-gen-lua=$PWD/home/script/tool/proto/protoc-gen-lua/plugin/protoc-gen-lua-tcg --lua_out=home/script/data/proto/ $path --proto_path=home/script/net/proto"
	echo $command
	`$command`
}

function parse_dir()
{
	files=`ls $1`
	for name in $files; do
		path=$1"/"$name
		if [ -d $path ]; then
			parse_dir $path
		else
			parse_file $path
		fi
	done
}

parse_dir "home/script/net/proto"
