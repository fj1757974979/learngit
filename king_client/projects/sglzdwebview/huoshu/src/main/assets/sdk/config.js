//游戏皮肤对应manifest文件的生成配置文件， 包括基本的第三方库、业务逻辑js、样式

var base_js = [
	'js/fastclick.min.1.0.js',
	'js/zepto.min.js',
	'js/doT.min.js',
	'js/iscroll.min.1.0.js'
]

var concat_with_mtime = [
	'skin/new_sdk.min.css',
	'skin/responsive.min.css',
	'js/core.min.js',
	'js/loader.min.js',
	'js/center.min.js',
	'js/pay.min.js',
	'js/login.min.js'
]

var htmls = [
	'login.html',
	'center.html',
	'pay.html',
	'share.html'
]

var images = 'skin/img';

var target = [
	'bllm',
	'bwts',
	'bwzq',
	'fytx',
	'hxjh',
	'rxxt',
	'sgg',
	'smlw',
	'twzw',
	'whj'
]
exports.htmls = htmls;
exports.target = target;
exports.concat_with_mtime = concat_with_mtime;
exports.base_js = base_js;
exports.images = images;