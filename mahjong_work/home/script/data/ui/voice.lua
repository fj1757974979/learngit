data = 
{
["alignX"] = 3.000000,
["alignY"] = 2.000000,
["children"] = {
    [1] = {
        ["alignX"] = 4.000000,
        ["alignY"] = 4.000000,
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["eventMap"] = {
            },
        ["name"] = "control1",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 15.000000,
            [2] = 75.000000,
            },
        ["rx"] = 15.000000,
        ["ry"] = 15.000000,
        ["size"] = {
            [1] = 426.000000,
            [2] = 568.000000,
            },
        ["splitImage"] = {
            [1] = true,
            [2] = true,
            [3] = 20.000000,
            },
        ["texturePath"] = "ui:bottom2.png",
        },
    [2] = {
        ["alignX"] = 2.000000,
        ["alignY"] = 3.000000,
        ["children"] = {
            [1] = {
                ["alignY"] = 2.000000,
                ["checkedImage"] = "ui:voice_send_input.png",
                ["children"] = {
                    },
                ["className"] = "pEdit",
                ["eventMap"] = {
                    },
                ["name"] = "edit_input",
                ["paramMap"] = {
                    },
                ["parent"] = "wnd_send_bg",
                ["position"] = {
                    [1] = 9.000000,
                    [2] = 0.000000,
                    },
                ["size"] = {
                    [1] = 280.000000,
                    [2] = 72.000000,
                    },
                ["splitImage"] = {
                    [1] = true,
                    [2] = true,
                    [3] = 10.000000,
                    },
                ["textAlignX"] = 1.000000,
                ["textColor"] = 4281671956.000000,
                ["textFontSize"] = 30.000000,
                ["texturePath"] = "ui:voice_send_input.png",
                },
            [2] = {
                ["alignX"] = 3.000000,
                ["alignY"] = 2.000000,
                ["children"] = {
                    [1] = {
                        ["alignX"] = 2.000000,
                        ["alignY"] = 2.000000,
                        ["children"] = {
                            },
                        ["className"] = "pWindow",
                        ["eventMap"] = {
                            },
                        ["isEnableEvent"] = false,
                        ["name"] = "wnd_send_text",
                        ["offsetX"] = -0.176483,
                        ["offsetY"] = -1.000000,
                        ["paramMap"] = {
                            },
                        ["parent"] = "btn_send",
                        ["size"] = {
                            [1] = 80.000000,
                            [2] = 30.000000,
                            },
                        ["splitImage"] = {
                            [1] = false,
                            [2] = false,
                            [3] = 10.000000,
                            },
                        ["texturePath"] = "ui:voice_send.png",
                        },
                    },
                ["className"] = "pButton",
                ["eventMap"] = {
                    },
                ["name"] = "btn_send",
                ["offsetY"] = 3.000000,
                ["paramMap"] = {
                    },
                ["parent"] = "wnd_send_bg",
                ["rx"] = 0.176483,
                ["size"] = {
                    [1] = 130.000000,
                    [2] = 65.000000,
                    },
                ["sound"] = "sound:ui/button.mp3",
                ["splitImage"] = {
                    [1] = false,
                    [2] = false,
                    [3] = 10.000000,
                    },
                ["texturePath"] = "ui:btn3.png",
                ["z"] = -2.000000,
                },
            },
        ["className"] = "pWindow",
        ["eventMap"] = {
            },
        ["name"] = "wnd_send_bg",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 50.000000,
            [2] = 50.000000,
            },
        ["ry"] = 17.000000,
        ["size"] = {
            [1] = 419.000000,
            [2] = 90.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["texturePath"] = "ui:voice_send_bg.png",
        ["z"] = -1.000000,
        },
    [3] = {
        ["children"] = {
            },
        ["className"] = "pWindow",
        ["color"] = 0.000000,
        ["eventMap"] = {
            },
        ["name"] = "wnd_list",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 22.764954,
            [2] = 84.117691,
            },
        ["size"] = {
            [1] = 410.000000,
            [2] = 460.000000,
            },
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["z"] = -1.000000,
        },
    [4] = {
        ["alignY"] = 3.000000,
        ["checkedImage"] = "ui:voice_face_true.png",
        ["children"] = {
            [1] = {
                ["alignX"] = 2.000000,
                ["alignY"] = 3.000000,
                ["bindWithParent"] = true,
                ["checkedImage"] = "ui:chk_face_txt2.png",
                ["children"] = {
                    },
                ["className"] = "pCheckButton",
                ["clickDownImage"] = "ui:chk_face_txt1.png",
                ["eventMap"] = {
                    },
                ["group"] = 0.000000,
                ["isEnableEvent"] = false,
                ["name"] = "cb_face_child",
                ["paramMap"] = {
                    },
                ["parent"] = "cb_face",
                ["position"] = {
                    [1] = 50.000000,
                    [2] = 50.000000,
                    },
                ["ry"] = 10.000000,
                ["size"] = {
                    [1] = 80.000000,
                    [2] = 39.000000,
                    },
                ["splitImage"] = {
                    [1] = false,
                    [2] = false,
                    [3] = 10.000000,
                    },
                ["texturePath"] = "ui:chk_face_txt1.png",
                },
            },
        ["className"] = "pCheckButton",
        ["clickDownImage"] = "ui:voice_face_true.png",
        ["eventMap"] = {
            },
        ["group"] = 1.000000,
        ["name"] = "cb_face",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 242.351807,
            [2] = 23.000000,
            },
        ["ry"] = 579.999390,
        ["size"] = {
            [1] = 161.000000,
            [2] = 62.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["texturePath"] = "ui:voice_face_false.png",
        ["z"] = -1.000000,
        },
    [5] = {
        ["alignY"] = 3.000000,
        ["checkedImage"] = "ui:voice_face_true.png",
        ["children"] = {
            [1] = {
                ["alignX"] = 2.000000,
                ["alignY"] = 3.000000,
                ["bindWithParent"] = true,
                ["checkedImage"] = "ui:chk_voice_txt2.png",
                ["children"] = {
                    },
                ["className"] = "pCheckButton",
                ["clickDownImage"] = "ui:chk_voice_txt1.png",
                ["eventMap"] = {
                    },
                ["group"] = 0.000000,
                ["isEnableEvent"] = false,
                ["name"] = "cb_voice_child",
                ["paramMap"] = {
                    },
                ["parent"] = "cb_voice",
                ["position"] = {
                    [1] = 50.000000,
                    [2] = 50.000000,
                    },
                ["ry"] = 10.000000,
                ["size"] = {
                    [1] = 80.000000,
                    [2] = 39.000000,
                    },
                ["splitImage"] = {
                    [1] = false,
                    [2] = false,
                    [3] = 10.000000,
                    },
                ["texturePath"] = "ui:chk_voice_txt1.png",
                },
            },
        ["className"] = "pCheckButton",
        ["clickDownImage"] = "ui:voice_face_true.png",
        ["eventMap"] = {
            },
        ["group"] = 1.000000,
        ["name"] = "cb_voice",
        ["paramMap"] = {
            },
        ["parent"] = "mainPanel",
        ["position"] = {
            [1] = 68.470352,
            [2] = 23.000000,
            },
        ["ry"] = 579.999390,
        ["size"] = {
            [1] = 161.000000,
            [2] = 62.000000,
            },
        ["sound"] = "sound:ui/button.mp3",
        ["splitImage"] = {
            [1] = false,
            [2] = false,
            [3] = 10.000000,
            },
        ["texturePath"] = "ui:voice_face_false.png",
        ["z"] = -1.000000,
        },
    },
["className"] = "pWindow",
["eventMap"] = {
    },
["name"] = "mainPanel",
["paramMap"] = {
    },
["parent"] = "screen",
["rx"] = 0.000015,
["size"] = {
    [1] = 456.000000,
    [2] = 658.000000,
    },
["splitImage"] = {
    [1] = true,
    [2] = true,
    [3] = 20.000000,
    },
["texturePath"] = "ui:bottom1.png",
}