rm -rf ../nsg_res/home/*
rm -rf tmp/resource/*
./tool/build_script_ios_armv7
./tool/build_script_ios_arm64
cp -rf home/script/locale/cn tmp/script/locale/
./tool/packpdb tmp/script tmp/script.pdb
./tool/packpdb tmp/script64 tmp/script64.pdb
./tool/packpdb home/shader/glsles tmp/shader.pdb
./tool/packpdb resource/armature tmp/resource/armature.pdb
./tool/packpdb resource/character tmp/resource/character.pdb
./tool/packpdb resource/effect tmp/resource/effect.pdb
mkdir -p tmp/resource/font
cp -rf resource/font/DroidSansFallback.ttf tmp/resource/font/
cp -rf resource/font/*.png tmp/resource/font/
#rm -rf tmp/resource/font/DroidSansFallback.ttf
#cp DroidSansFallback.ttf tmp/resource/font/
#./tool/packpdb resource/icon tmp/resource/icon.pdb
./tool/packpdb resource/map tmp/resource/map.pdb
./tool/packpdb resource/music tmp/resource/music.pdb
./tool/packpdb resource/sound tmp/resource/sound.pdb
./tool/packpdb resource/ui tmp/resource/ui.pdb
#./tool/packpdb resource/ui_review tmp/resource/ui_review.pdb
#./tool/packpdb resource/uipack tmp/resource/uipack.pdb

rm -rf ../nsg_res
mkdir -p ../nsg_res
cp -rf etc ../nsg_res/
mkdir -p ../nsg_res/home
cp tmp/script.pdb ../nsg_res/home/
cp tmp/script64.pdb ../nsg_res/home/
cp tmp/shader.pdb ../nsg_res/home/
mkdir -p ../nsg_res/config
mkdir -p ../nsg_res/resource
cp -rf tmp/resource/* ../nsg_res/resource
mkdir -p ../nsg_res/home/script/locale

rm ../nsg_res/etc/config.json*
