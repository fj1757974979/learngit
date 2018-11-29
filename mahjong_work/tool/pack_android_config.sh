#!/bin/bash

rm ../engine/android/assets/etc/config*
cp etc/config.json.$1 ../engine/android/assets/etc/config.json
