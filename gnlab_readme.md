# 安装包安装使用

## 配置需要安装的文件 ##
将所有需要安装的文件复制到FilesToInstall文件夹下。(包括.net安装包，必须名字为dotNetFx45_Full_setup.exe)

## 设置版本 ##
将对应的(如gnlab/baidu_keyword_version.nsh)里面的版本号修改为需要的版本。（可用 echo !define PRODUCT_VERSION "2.5.0.0">baidu_keyword_version.nsh）

## 运行脚本 ##
运行build_baidu_keyword.bat或可以根据需要自己按照里面的参数修改内容。（主要是对应的baidu_keyword_setup.nsi文件)

## 运行参数 ##
APPDIR：安装路径
lastRunApp: 安装好后运行该程序。