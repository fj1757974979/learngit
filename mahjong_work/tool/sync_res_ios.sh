#source ./tool/ios_profile
./tool/build_script_ios_armv7 # armv6 armv7
./tool/build_script_ios_arm64 # arm64
./tool/assets
rsync -av -e 'ssh -p 22' -r tmp/script server@106.75.132.200:/data/web/mahjong_web_ios/static/home/
rsync -av -e 'ssh -p 22' -r tmp/script64/* server@106.75.132.200:/data/web/mahjong_web_ios/static/arch64/home/script
rsync -av -e 'ssh -p 22' -r home/shader server@106.75.132.200:/data/web/mahjong_web_ios/static/home/
rsync -av -e 'ssh -p 22' -r home/shader server@106.75.132.200:/data/web/mahjong_web_ios/static/arch64/home/
rsync -av -e 'ssh -p 22' -r resource/* server@106.75.132.200:/data/web/mahjong_web_ios/static/resource/
rsync -av -e 'ssh -p 22' -r resource/* server@106.75.132.200:/data/web/mahjong_web_ios/static/arch64/resource/
tool/zipstr etc/files etc/files.z
rsync -av -e 'ssh -p 22' etc/files*.z server@106.75.132.200:/data/web/mahjong_web_ios/static/etc/
rsync -av -e 'ssh -p 22' etc/files* server@106.75.132.200:/data/web/mahjong_web_ios/static/etc/

