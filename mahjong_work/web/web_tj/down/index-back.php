<?php
	$anzhuo_url = "http://fir.im/bu1p";
	$ios_url = "http://fir.im/bu1p";
	$zhengshu = "xxxx";
	$name = "河东麻将";
	$time = "2016-10-09 13:23";
?>
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=0,minimal-ui" />
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black">
<meta name="format-detection" content="telephone=no">
<title><?php echo $name;?></title>
<script src="zepto.min.js" type="text/javascript"></script>
</head>
<style type="text/css">
body{ margin: 0; padding: 20px 10px 10px; }
.main{ text-align: center; }
.download{ padding-top: 20px; }
.btn{ display: inline-block; height: 40px; line-height: 40px; margin-bottom: 30px; border-radius: 5px; background-color: #05a30d; color: #fff; text-align: center; width: 100%; text-decoration: none;  }
.btnOrange{ background-color: #f80; }
.tip{ font-size: 12px; color: #111; }
.footer{ font-size: 12px; color: #ccc; padding-top: 20px; }
.mask,.mask_ios { display: none; position: fixed; left: 0; top: 0; background: rgba(0, 0, 0, 0.9); width: 100vw; height: 100vh; z-index: 100; color: #fff; padding: 30px 10px; box-sizing:border-box; -moz-box-sizing:border-box; -webkit-box-sizing:border-box; }
.mask p{ text-align: center; margin: 0; height: 100%; position: relative; }
.mask i,.mask_ios i { color: #ff0; font-style: normal; }
.mask p img { width: 100%; height: 100%; }
.mask .close,.mask_ios .close { color: #fff; padding: 5px; font: bold 24px/26px simsun; text-shadow: 0 1px 0 #ddd; position: absolute; top: 0; left: 5px; }
</style>
<body>
<div class="main">
    <img src="icon.png" width="256" />
    <h1><?php echo $name;?></h1>
    <div class="download">
        <a href="<?php echo $anzhuo_url;?>" target="_blank" class="btn" id="android_btn">下载安卓版</a>
        <a href="itms-services://?action=download-manifest&url=https://slyx.oss-cn-shanghai.aliyuncs.com/pro/manifest.plist" target="_blank" class="btn btnOrange" id="ios_btn">下载IOS版</a>
    </div>
    <div class="tip">微信不允许直接下载文件，请点击右上角按钮，选择在浏览器中打开，或者复制链接到浏览器。</div>
    <div class="footer">最后更新：2016-8-15 17:28</div>
</div>
<div class="mask">
    <p>
        <img src="mask.png" alt="微信扫描打开APP下载链接提示代码优化">
        <span id="close" title="关闭" class="close">×</span>
    </p>
</div>
<div class="mask_ios">
    <p>应用授信教程：</p>
    <p>1.如果打开「<?php echo $name;?>」时，出现“未受信用的企业级开发者”。</p>
    <p>2.然后在设备中点击进入【<i>设置>>通用>>设备管理</i>】，找到 <?php echo $zhengshu;?>...</p>
    <p>3.点击信任“<?php echo $zhengshu;?>...”后再打开“<?php echo $name;?>”即可。</p>
    <span id="close" title="关闭" class="close">×</span>
</div>

<script type="text/javascript">
function is_weixin() {
    var ua = navigator.userAgent.toLowerCase();
    if (ua.match(/MicroMessenger/i) == "micromessenger") {
    return true;
    } else {
        return false;
    }
}
$(function(){
    $('#android_btn').on('click', function(){
        if(is_weixin()) {
            $('.mask').show();
            return false;
        }
    });
    $('.mask,.mask_ios').on('click', function(){
        $(this).hide();
    });
    $('#ios_btn').on('click', function(){
        if(is_weixin()) {
            $('.mask').show();
            return false;
        } else {
            $('.mask_ios').show();
            //alert('IOS版马上推出，尽请期待！');
            //return false;
        }
    });
});
</script>
</body>
</html>
