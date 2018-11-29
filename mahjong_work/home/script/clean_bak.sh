function clean_dir()
{
	dirs=`ls $1`
	for name in $dirs; do
		path=$1"/"$name
		if [ -d $path ]; then
			clean_dir $path
		else
			if [[ $name == *bak ]]; then
				`rm $path`
			fi
		fi
	done
}

clean_dir `pwd`

