<?php
	$anzhuo_url = "http://fir.im/hntjmj";
	//$anzhuo_url = "http://www.openew.com/games/tjmj/tjmj.apk";
	$ios_url = "https://fir.im/hntjmj";
	$zhengshu = "Lespeed Co.,Ltd.";
	$name = "乐闲桃江麻将";
	$time = "2017-04-14 15:39";
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
h2{margin:12px auto;}
h4{color: #ccc;margin:12px auto;}
.blue{color:#00008B;font-weight:bold;}
.main{ text-align: center; }
.download{ padding-top: 0px; }
.btn{ display: inline-block; height: 40px; line-height: 40px; margin-bottom: 30px; border-radius: 5px; background-color: #05a30d; color: #fff; text-align: center; width: 100%; text-decoration: none;  }
.btnOrange{ background-color: #f80; }
.tip{ font-size: 14px; color: #111; margin-top:15px;line-height: 26px;}
.footer{ font-size: 12px; color: #ccc; padding-top: 20px; }
.mask,.mask_ios { display: none; position: fixed; left: 0; top: 0; background: rgba(0, 0, 0, 0.9); width: 100vw; height: 100vh; z-index: 100; color: #fff; padding: 30px 10px; box-sizing:border-box; -moz-box-sizing:border-box; -webkit-box-sizing:border-box; }
.mask p{ text-align: center; margin: 0; height: 100%; position: relative; }
.mask i,.mask_ios i { color: #ff0; font-style: normal; }
.mask p img { width: 100%; height: 100%; }
.mask .close,.mask_ios .close { color: #fff; padding: 5px; font: bold 24px/26px simsun; text-shadow: 0 1px 0 #ddd; position: absolute; top: 0; left: 5px; }
.downlink{display: inline-block;border-radius: 5px;width: 280px;height: 64px;line-height: 60px;margin: 0 10px;}
.downlink img{vertical-align: middle;}
.bgandrion{background: #63d180;}
.bgios{background: #58adef;}
</style>
<body>
<div class="main">
    <img src="icon.png" />
    <h2><?php echo $name;?></h2>
    <h4>乐闲桃江麻将</h4>
    <!--h4 class="blue"><a href="https://mp.weixin.qq.com/s?__biz=MzI4NTQyMzAyMA==&mid=2247483684&idx=1&sn=6d77f846975feb9062ae98f774cd92ff&chksm=ebed25e7dc9aacf12bd1c009ccb2dd0d53626e1987bb15a72e7884a83a6c14ad51400b0dcacf#rd">点击关注官方公众号每天领钻石</a></h4-->
    <div class="download">
		<a class="downlink bgandrion" href="<?php echo $anzhuo_url;?>" target="_blank"><img src="icon_andrion.png"></a><br><br>
		<a class="downlink bgios" href="<?php echo $ios_url;?>" target="_blank"><img src="icon_iphone.png"></a>
    </div>
    <div class="tip">微信不允许直接下载文件，请点击右上角按钮，选择在浏览器中打开，或者复制链接到浏览器。</div>
    <div class="footer">最后更新：<?php echo $time?></div>
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
