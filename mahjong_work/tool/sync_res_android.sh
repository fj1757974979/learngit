#source ./tool/android_profile
./tool/build_script_android
#runhaskell tool/build_script_ios_arm64.hs
./tool/assets
rsync -av -e 'ssh -p 22' -r tmp/script server@106.75.132.200:/data/web/mahjong_web/static/home/
rsync -av -e 'ssh -p 22' -r home/shader server@106.75.132.200:/data/web/mahjong_web/static/home/
rsync -av -e 'ssh -p 22' -r resource/* server@106.75.132.200:/data/web/mahjong_web/static/resource/
tool/zipstr etc/files etc/files.z
rsync -av -e 'ssh -p 22' etc/files*.z server@106.75.132.200:/data/web/mahjong_web/static/etc/
rsync -av -e 'ssh -p 22' etc/files* server@106.75.132.200:/data/web/mahjong_web/static/etc/

