rm -rf tmp/resource/*
./tool/build_script_android
cp -rf home/script/locale/cn tmp/script/locale/
cp -rf resource/font tmp/resource

rm -rf ../engine/android/assets/home
rm -rf ../engine/android/assets/*resource*
rm -rf ../engine/android/assets/config
rm -rf ../engine/android/assets/etc
mkdir -p ../engine/android/assets/
cp -rf etc ../engine/android/assets/
mkdir -p ../engine/android/assets/home/script
cp -rf tmp/script/* ../engine/android/assets/home/script
mkdir -p ../engine/android/assets/home/shader
cp -rf home/shader/glsles/* ../engine/android/assets/home/shader
mkdir -p ../engine/android/assets/config
cp -rf config/* ../engine/android/assets/config
cp -rf home/script/locale/cn ../engine/android/assets/home/script/locale/

mkdir -p ../engine/android/assets/resource/font
cp -rf resource/font/* ../engine/android/assets/resource/font/

mkdir -p ../engine/android/assets/resource/icon
cp -rf resource/icon/* ../engine/android/assets/resource/icon

mkdir -p ../engine/android/assets/resource/ui
cp -rf resource/ui/* ../engine/android/assets/resource/ui

#mkdir -p ../engine/android/assets/resource/ui_review
#cp -rf resource/ui_review/* ../engine/android/assets/resource/ui_review

mkdir -p ../engine/android/assets/resource/uipack
cp -rf resource/uipack/* ../engine/android/assets/resource/uipack

mkdir -p ../engine/android/assets/resource/character
cp -rf resource/character/* ../engine/android/assets/resource/character

mkdir -p ../engine/android/assets/resource/effect
cp -rf resource/effect/* ../engine/android/assets/resource/effect

mkdir -p ../engine/android/assets/resource/icon
cp -rf resource/icon/* ../engine/android/assets/resource/icon

mkdir -p ../engine/android/assets/resource/weapon
cp -rf resource/weapon/* ../engine/android/assets/resource/weapon

mkdir -p ../engine/android/assets/resource/map
cp -rf resource/map/* ../engine/android/assets/resource/map

mkdir -p ../engine/android/assets/resource/music
cp -rf resource/music/* ../engine/android/assets/resource/music

mkdir -p ../engine/android/assets/resource/sound
cp -rf resource/sound/* ../engine/android/assets/resource/sound

mkdir -p ../engine/android/assets/resource/armature
cp -rf resource/armature/* ../engine/android/assets/resource/armature
