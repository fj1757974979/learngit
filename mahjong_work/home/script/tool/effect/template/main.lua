data = 
{
["alignX"] = 2.000000,
["alignY"] = 2.000000,
["children"] = {
    [1] = {
        ["alignY"] = 3.000000,
        ["children"] = {
            },
        ["className"] = "pButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onChoose",
            },
        ["name"] = "control2",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 366.000000,
            [2] = 362.000000,
            },
        ["ry"] = 9.000000,
        ["size"] = {
            [1] = 106.000000,
            [2] = 32.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "Choose",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [2] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 1996488959.000000,
        ["eventMap"] = {
            },
        ["name"] = "wndFrames",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 167.000000,
            [2] = 382.000000,
            },
        ["size"] = {
            [1] = 351.000000,
            [2] = 44.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "",
        },
    [3] = {
        ["children"] = {
            },
        ["className"] = "pEdit",
        ["eventMap"] = {
            ["ec_inactive"] = "onSpeedChange",
            },
        ["name"] = "editSpeed",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 611.000000,
            [2] = 58.000000,
            },
        ["size"] = {
            [1] = 77.000000,
            [2] = 24.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["textColor"] = 4278190080.000000,
        ["textFontSize"] = 20.000000,
        ["texturePath"] = "ui:input.png",
        },
    [4] = {
        ["children"] = {
            [1] = {
                ["alignX"] = 2.000000,
                ["children"] = {
                    },
                ["className"] = "pWindow",
                ["color"] = 1996488959.000000,
                ["eventMap"] = {
                    },
                ["name"] = "pointWnd",
                ["paramMap"] = {
                    },
                ["parent"] = "charWnd",
                ["position"] = {
                    [1] = 364.000000,
                    [2] = 256.000000,
                    },
                ["size"] = {
                    [1] = 1.000000,
                    [2] = 1.000000,
                    },
                ["splitImage"] = {
                    [1] = false,
                    [2] = false,
                    [3] = 10.000000,
                    },
                ["textFontSize"] = 20.000000,
                },
            },
        ["className"] = "pWindow",
        ["color"] = 1996488959.000000,
        ["eventMap"] = {
            },
        ["name"] = "charWnd",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 167.000000,
            [2] = 76.000000,
            },
        ["size"] = {
            [1] = 347.000000,
            [2] = 300.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["textFontSize"] = 20.000000,
        },
    [5] = {
        ["alignY"] = 3.000000,
        ["children"] = {
            },
        ["className"] = "pButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onSave",
            },
        ["name"] = "control4",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 218.000000,
            [2] = 362.000000,
            },
        ["ry"] = 9.000000,
        ["size"] = {
            [1] = 106.000000,
            [2] = 32.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "Save",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [6] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 0.000000,
        ["eventMap"] = {
            },
        ["isSelfShow"] = false,
        ["name"] = "wndHit",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 418.000000,
            [2] = 86.000000,
            },
        ["size"] = {
            [1] = 88.000000,
            [2] = 24.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "onHit",
        ["textColor"] = 4294967295.000000,
        },
    [7] = {
        ["autoBreakLine"] = false,
        ["checkedImage"] = "ui:button_selected.png",
        ["children"] = {
            },
        ["className"] = "pCheckButton",
        ["eventMap"] = {
            ["ec_checked"] = "chooseEffect",
            },
        ["group"] = 1.000000,
        ["name"] = "control5",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 16.000000,
            [2] = 30.000000,
            },
        ["size"] = {
            [1] = 139.000000,
            [2] = 31.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "td/effect",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [8] = {
        ["autoBreakLine"] = false,
        ["checkedImage"] = "ui:button_selected.png",
        ["children"] = {
            },
        ["className"] = "pCheckButton",
        ["eventMap"] = {
            ["ec_checked"] = "chooseNewEffect",
            },
        ["group"] = 1.000000,
        ["name"] = "control6",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 168.000000,
            [2] = 28.000000,
            },
        ["size"] = {
            [1] = 134.000000,
            [2] = 31.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "td/neweffect",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [9] = {
        ["autoBreakLine"] = false,
        ["checkedImage"] = "ui:button_selected.png",
        ["children"] = {
            },
        ["className"] = "pCheckButton",
        ["eventMap"] = {
            ["ec_checked"] = "chooseCharacter",
            },
        ["group"] = 1.000000,
        ["name"] = "control11",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 322.000000,
            [2] = 29.000000,
            },
        ["size"] = {
            [1] = 134.000000,
            [2] = 31.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "td/character",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [10] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 1996488959.000000,
        ["eventMap"] = {
            },
        ["name"] = "fileWnd",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 14.000000,
            [2] = 79.000000,
            },
        ["size"] = {
            [1] = 142.000000,
            [2] = 381.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["textFontSize"] = 20.000000,
        },
    [11] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 1996488959.000000,
        ["eventMap"] = {
            },
        ["isSelfShow"] = false,
        ["name"] = "control7",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 523.000000,
            [2] = 96.000000,
            },
        ["size"] = {
            [1] = 82.000000,
            [2] = 26.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "frame",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        },
    [12] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 1996488959.000000,
        ["eventMap"] = {
            },
        ["isSelfShow"] = false,
        ["name"] = "control3",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 523.000000,
            [2] = 59.000000,
            },
        ["size"] = {
            [1] = 82.000000,
            [2] = 26.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "Speed",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        },
    [13] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 1996488959.000000,
        ["eventMap"] = {
            },
        ["isSelfShow"] = false,
        ["name"] = "control12",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 525.000000,
            [2] = 135.000000,
            },
        ["size"] = {
            [1] = 82.000000,
            [2] = 26.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "z",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        },
    [14] = {
        ["children"] = {
            },
        ["className"] = "pEdit",
        ["eventMap"] = {
            ["ec_inactive"] = "onSpeedChange",
            },
        ["name"] = "editFrame",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 612.000000,
            [2] = 98.000000,
            },
        ["size"] = {
            [1] = 74.000000,
            [2] = 24.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["textColor"] = 4278190080.000000,
        ["textFontSize"] = 20.000000,
        ["texturePath"] = "ui:input.png",
        },
    [15] = {
        ["children"] = {
            },
        ["className"] = "pEdit",
        ["eventMap"] = {
            ["ec_inactive"] = "onZChange",
            },
        ["name"] = "editZ",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 614.000000,
            [2] = 134.000000,
            },
        ["size"] = {
            [1] = 74.000000,
            [2] = 24.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["textColor"] = 4278190080.000000,
        ["textFontSize"] = 20.000000,
        ["texturePath"] = "ui:input.png",
        },
    [16] = {
        ["autoBreakLine"] = false,
        ["checkedImage"] = "ui:button_selected.png",
        ["children"] = {
            },
        ["className"] = "pCheckButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onActionChange",
            },
        ["group"] = 1.000000,
        ["name"] = "chk_attack",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 635.000000,
            [2] = 444.000000,
            },
        ["size"] = {
            [1] = 54.000000,
            [2] = 29.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "attack",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 18.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [17] = {
        ["autoBreakLine"] = false,
        ["checkedImage"] = "ui:button_selected.png",
        ["children"] = {
            },
        ["className"] = "pCheckButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onActionChange",
            },
        ["group"] = 1.000000,
        ["name"] = "chk_magic",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 634.000000,
            [2] = 414.000000,
            },
        ["size"] = {
            [1] = 54.000000,
            [2] = 29.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "magic",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 18.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [18] = {
        ["autoBreakLine"] = false,
        ["checkedImage"] = "ui:button_selected.png",
        ["children"] = {
            },
        ["className"] = "pCheckButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onActionChange",
            },
        ["group"] = 1.000000,
        ["name"] = "chk_run",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 581.000000,
            [2] = 414.000000,
            },
        ["size"] = {
            [1] = 54.000000,
            [2] = 29.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "run",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 18.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [19] = {
        ["autoBreakLine"] = false,
        ["checkedImage"] = "ui:button_selected.png",
        ["children"] = {
            },
        ["className"] = "pCheckButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onActionChange",
            },
        ["group"] = 1.000000,
        ["name"] = "chk_guard",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 527.000000,
            [2] = 414.000000,
            },
        ["size"] = {
            [1] = 54.000000,
            [2] = 29.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "guard",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 18.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [20] = {
        ["alignY"] = 3.000000,
        ["children"] = {
            },
        ["className"] = "pButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onSetHit",
            },
        ["name"] = "btn_character",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 531.000000,
            [2] = 50.000000,
            },
        ["ry"] = 65.000000,
        ["size"] = {
            [1] = 157.000000,
            [2] = 32.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "Character",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [21] = {
        ["alignY"] = 3.000000,
        ["children"] = {
            },
        ["className"] = "pButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onSetHit",
            },
        ["name"] = "control10",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 544.000000,
            [2] = 50.000000,
            },
        ["ry"] = 103.000000,
        ["size"] = {
            [1] = 106.000000,
            [2] = 32.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "SetHit",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [22] = {
        ["alignY"] = 3.000000,
        ["children"] = {
            },
        ["className"] = "pButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onStop",
            },
        ["name"] = "control9",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 544.000000,
            [2] = 50.000000,
            },
        ["ry"] = 142.000000,
        ["size"] = {
            [1] = 106.000000,
            [2] = 32.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "Stop",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [23] = {
        ["alignY"] = 3.000000,
        ["children"] = {
            },
        ["className"] = "pButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "onPlay",
            },
        ["name"] = "control8",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 543.000000,
            [2] = 50.000000,
            },
        ["ry"] = 181.000000,
        ["size"] = {
            [1] = 106.000000,
            [2] = 32.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "Play",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        ["texturePath"] = "ui:button.png",
        },
    [24] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 1996488959.000000,
        ["eventMap"] = {
            },
        ["isSelfShow"] = false,
        ["name"] = "control13",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 525.000000,
            [2] = 175.000000,
            },
        ["size"] = {
            [1] = 82.000000,
            [2] = 26.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "repeat",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        },
    [25] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 1996488959.000000,
        ["eventMap"] = {
            },
        ["isSelfShow"] = false,
        ["name"] = "control14",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 524.000000,
            [2] = 214.000000,
            },
        ["size"] = {
            [1] = 82.000000,
            [2] = 26.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["text"] = "isFoot",
        ["textColor"] = 4294967295.000000,
        ["textFontSize"] = 20.000000,
        ["textShadowColor"] = 4278190080.000000,
        },
    [26] = {
        ["children"] = {
            },
        ["className"] = "pEdit",
        ["eventMap"] = {
            ["ec_inactive"] = "onRepeatChange",
            },
        ["name"] = "editRepeat",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 615.000000,
            [2] = 175.000000,
            },
        ["size"] = {
            [1] = 74.000000,
            [2] = 24.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["textColor"] = 4278190080.000000,
        ["textFontSize"] = 20.000000,
        ["texturePath"] = "ui:input.png",
        },
    [27] = {
        ["children"] = {
            },
        ["className"] = "pEdit",
        ["eventMap"] = {
            ["ec_inactive"] = "onIsFootChange",
            },
        ["name"] = "editIsFoot",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 615.000000,
            [2] = 215.000000,
            },
        ["size"] = {
            [1] = 74.000000,
            [2] = 24.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["textColor"] = 4278190080.000000,
        ["textFontSize"] = 20.000000,
        ["texturePath"] = "ui:input.png",
        },
    [28] = {
        ["alignX"] = 3.000000,
        ["children"] = {
            },
        ["className"] = "pButton",
        ["eventMap"] = {
            ["ec_mouse_click"] = "close",
            },
        ["name"] = "control1",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 512.000000,
            [2] = 4.000000,
            },
        ["size"] = {
            [1] = 40.000000,
            [2] = 40.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["textFontSize"] = 20.000000,
        ["texturePath"] = "ui:close.png",
        ["z"] = -1.000000,
        },
    },
["className"] = "pWindow",
["enableDrag"] = true,
["eventMap"] = {
    ["ec_checked"] = "onActionChange",
    },
["name"] = "mainPanel",
["paramMap"] = {
    },
["parent"] = "screen",
["position"] = {
    [1] = 219.000000,
    [2] = 139.000000,
    },
["size"] = {
    [1] = 698.000000,
    [2] = 476.000000,
    },
["splitImage"] = {
    [1] = false,
    [2] = false,
    [3] = 10.000000,
    },
["textFontSize"] = 20.000000,
["texturePath"] = "ui:panel.png",
["z"] = -100.000000,
}