#! /usr/bin/env python
# -*- coding: utf-8 -*-
# vim:fenc=utf-8
#
# Copyright © 2018 Register <registerdedicated(at)gmail.com>
#
# Distributed under terms of the GPLv3 license.
#

import sys
import os

if __name__ == "__main__":
    device = sys.argv[1]
    if device == "pc":
        os.system("cp index_pc.html index.html")
        os.system("cp wingProperties_pc.json wingProperties.json")
        os.system("cp tsconfig_pc.json tsconfig.json")
    else:
        os.system("cp index_mobile.html index.html")
        os.system("cp wingProperties_mobile.json wingProperties.json")
        os.system("cp tsconfig_mobile.json tsconfig.json")

