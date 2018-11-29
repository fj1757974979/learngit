#sh tool/addversion.sh
#cocos compile -p android #-m release
#rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_kx/* server@sdk.openew.cn:/var/www/html/games/mj
#rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_tj/* server@sdk.openew.cn:/var/www/html/games/tjmj
#rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_ds/* server@sdk.openew.cn:/var/www/html/games/dsmj

#rsync -av -pgo -e 'ssh -p 22' -r frameworks/runtime-src/proj.android/bin/KaixinMJ-debug.apk server@sdk.openew.cn:/var/www/html/games/masmj/masmj.apk
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_kx/* while1@www.src.openew.cn:/var/www/html/games/mj
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_tj/* while1@www.src.openew.cn:/var/www/html/games/tjmj
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_ds/* while1@www.src.openew.cn:/var/www/html/games/dsmj
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_yw/* while1@www.src.openew.cn:/var/www/html/games/ywmj
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_jzlaiba/* while1@www.src.openew.cn:/var/www/html/games/jzlaiba
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_yydoudou/* while1@www.src.openew.cn:/var/www/html/games/yydoudou
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_zaqueyue/* while1@www.src.openew.cn:/var/www/html/games/zaqueyue
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_xyhanshui/* while1@www.src.openew.cn:/var/www/html/games/xyhanshui
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_nctianjiuwang/* while1@www.src.openew.cn:/var/www/html/games/nctianjiuwang
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_rcxianle/* while1@www.src.openew.cn:/var/www/html/games/rcxianle
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r web_jdqs/* while1@www.src.openew.cn:/var/www/html/games/jdqs
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r apks/* while1@www.src.openew.cn:/var/www/html/games/apks
rsync -av --chmod=ugo=rwX -e 'ssh -p 22' -r 2048/* while1@www.src.openew.cn:/var/www/html/games/2048

#rm frameworks/runtime-src/proj.android/bin/KaixinMJ-debug-*.apk
#tool/channelname frameworks/runtime-src/proj.android/bin/ -c masmj
#tool/login gzkxkxmj Loveota201@ frameworks/runtime-src/proj.android/bin/
