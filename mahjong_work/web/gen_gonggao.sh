function gen() 
{
	cat $1/gonggao.html.template | sed "/%maintain_gonggao%/r maintain_gonggao"  > $1/gonggao.html
	cat $1/gonggao.html.template | sed "/%maintain_gonggao%/r maintain_gonggao"  > $1/gonggao_ios.html
	cat $1/gonggao.html.template | sed "/%maintain_gonggao%/r maintain_gonggao"  > $1/gonggao_android.html
	cat $1/gonggao.html.template | sed "/%maintain_gonggao%/r maintain_gonggao"  > $1/gonggao_kc.html
	cat $1/gonggao.html.template | sed "/%maintain_gonggao%/r maintain_gonggao"  > $1/gonggao_openew.html
}

for dir in `ls`; do
	if [ -d $dir ]; then
		gen $dir
	fi
done
