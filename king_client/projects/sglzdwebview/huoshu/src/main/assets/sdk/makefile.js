/**
 *	动态生成各游戏皮肤下对应的manifest文件。分别将带上修改时间戳的第三方库、业务逻辑js、
 *		sdk基本样式、指定皮肤样式、皮肤资源文件的路径添加到manifes文件中
 *		并将修改时间更新到html文档的资源引用中
 *	配置文件:config.js
 *	生成文件:skin/xxxx/sdk.manifest
 *	运行方法:node makefile.js
 **/
var fs = require('fs'),
	PATH = require('path'),
	config = require('./config.js');

var target = config.target;
var concat_with_mtime = config.concat_with_mtime;
var base_js = config.base_js;
var base_img = config.images;
var htmls = config.htmls;
//读取三个html文件的内容，以便后面更新引用信息

var html_content = [];
for (i = 0, l = htmls.length; i < l; i++) {
	html_content.push(fs.readFileSync(htmls[i], 'utf-8'));
}

function formatTime(mtime) {
	var date = '';
	date += mtime.getFullYear();
	var month = mtime.getMonth() + 1;
	month < 10 ? date += '0' + month : date += month;
	var day = mtime.getDate();
	day < 10 ? date += '0' + day : date += day;
	var hour = mtime.getHours();
	hour < 10 ? date += '0' + hour : date += hour;
	var minute = mtime.getMinutes();
	minute < 10 ? date += '0' + minute : date += minute;
	return date;
}
var content = [];
var path, mtime, jsPath, reg;
content.push('CACHE MANIFEST');
content.push('');

var now = new Date();
content.push('#version=' + formatTime(now));

for(var i=0, l= htmls.length; i<l; i++){
	path = htmls[i];
	if(PATH.existsSync(path)){
		// mtime = formatTime(fs.statSync(path).mtime);
		content.push('/static/sdk/' + path);// + '?' + mtime);
	}
}
for (i = 0, l = base_js.length; i < l; i++) {
	path = base_js[i];
	if (PATH.existsSync(path)) {
		mtime = formatTime(fs.statSync(path).mtime);
		content.push('/static/sdk/' + path + '?' + mtime);
		//更新login.html, center.html, pay.html的引用信息的版本号
		for (var j = 0, k = html_content.length; j < k; j++) {
			reg = new RegExp(path.replace('/', '\\/') + '\\?\\d+')
			html_content[j] = html_content[j].replace(reg, path + '?' + mtime);
		}
	} else {
		console.error('指定文件不存在:' + base_js[i]);
	}
}

for (i = 0, l = concat_with_mtime.length; i < l; i++) {
	path = concat_with_mtime[i];
	if (PATH.existsSync(path)) {
		mtime = formatTime(fs.statSync(path).mtime);
		content.push('/static/sdk/' + path + '?' + mtime);
		//更新login.html, center.html, pay.html的引用信息的版本号
		for (j = 0, k = html_content.length; j < k; j++) {
			reg = new RegExp(path.replace('/', '\\/') + '\\?\\d+')
			html_content[j] = html_content[j].replace(reg, path + '?' + mtime);
		}
	} else {
		console.error('指定文件不存在:' + path);
	}
}
// 添加sdk基本图片资源
/*
var base_img_files = fs.readdirSync(base_img);
for(i=0,l=base_img_files.length; i<l; i++){
	if(base_img_files[i].indexOf('.') == 0) continue;
	path = base_img + '/' + base_img_files[i];
	content.push('/static/sdk/' + path);
}
*/
//获取皮肤的最大mtime
/*
var skin_mtime = 0;
for(i=0, l= target.length; i<l; i++){
	path = 'skin/' + target[i] + '/skin.css';
	mtime = parseInt(formatTime(fs.statSync(path).mtime));
	if(mtime > skin_mtime) skin_mtime = mtime;
}
*/
//在基础文件上添加对应皮肤的样式和所需要的图片

var skin_content;
for (i = 0, l = target.length; i < l; i++) {
	
	path = 'skin/' + target[i];
	skin_content = content.concat();
	/*
	skin_content.push('/static/sdk/' + path + '/skin.css' + '?' + skin_mtime);
	*/
	//更新login.html, center.html, pay.html的引用信息的版本号
	for (j = 0, k = html_content.length; j < k; j++) {
		reg = new RegExp('data-v="\\d+"');
		html_content[j] = html_content[j].replace(reg, 'data-v="' + skin_mtime + '"');
	}
	//push the img fiels if exists
	/*
	var images = fs.readdirSync(path + '/img');
	for (var j = 0, k = images.length; j < k; j++) {
		if(images[j].indexOf('.') == 0) continue;
		var img_path = path + '/img/' + images[j];
		// mtime = formatTime(fs.statSync(img_path).mtime);
		skin_content.push('/static/sdk/' + path + '/img/' + images[j]) //+ '?' + mtime);
	}
	*/
	skin_content.push('NETWORK:');
	skin_content.push('*');
	skin_content = skin_content.join('\n');
	fs.writeFileSync(path + '/sdk.manifest', skin_content);
}


content.push('NETWORK:');
content.push('*');
//生成基础的没有皮肤的缓存文件
fs.writeFileSync('skin/sdk.manifest', content.join('\n'));
//将对html文件引用信息的修改写回文件中
for(i=0, l=htmls.length; i<l; i++){
	fs.writeFileSync(htmls[i], html_content[i]);
}