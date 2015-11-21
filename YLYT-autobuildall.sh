#!/bin/bash
SHELL_DIR=$(cd `dirname $0`; pwd)
 
	# 1.修改配置文件（xxx-buildsetting.plist）配置内容，具体修改如下
	# 	1）SDK_VERSION
	# 		当前你可以编译sdk版本（使用xcodebuild -showsdks）
	# 	2）ARCHITECTURES
	# 		cpu架构（armv7, arm64）ps:暂不支持，直接根据XCode设置
	# 	3）TARGET
	# 		你工程的target是什么名字就填什么名字
	# 	4）CONFIGURATION
	# 		目前使用Release, 可以为Debug,AdHoc,Release,Distribution
	# 	5）CODE_SIGN_IDENTITY*
	# 		你的工程对应的签名id，（xcode点击工程文件，再点击target，选择build setting，单击Code Signing Identity的键值，选择Other，选择出现的字符串）
	# 	6）PROVISIONING_PROFILE*
	# 		你的工程授权文件的id值，（xcode点击工程文件，再点击target，选择build setting，单击Provisioning Profile的键值，选择Other，选择出现的字符串）
	# 	7）GCC_PREPROCESSOR_DEFINITIONS
	# 		如果有需要预处理的宏定义，需要在这里指定
	# 	8）PROJECT_TYPE
	# 		工程类型，如果用的是xcworkspace的目录，填写workspace，如果是xcodeproj，可不填
	# 		

	# 2.修改本文件的SOURCE_CODE_FOLDER,xcodepro或者xcworkspace
	# XC所在目录

	# 3.修改本文件的PROJECT_NAME，工程的名称

	# 4. ipa默认生成在Output目录下面，会根据当前的编译时间生成文件夹
	# 

#代码路径（xcodeproj或者xcworkspace所在的目录）
SOURCE_CODE_FOLDER="/Users/jackyzonewen/Repository/SVN/ios_wft/branches/YSZF"
PROJECT_NAME="YLYT"

#xcode编译临时文件的存储路径
XCODE_BUILD_FOLDER="$SHELL_DIR/xcodebuildcache"

#生成ipa的位置
APP_BUILD_TIME=$(date +%Y%m%d%H%M) #编译时间

#输出的根目录
OUTPUT_ROOT_PATH="$SHELL_DIR/Output"
if [ ! -d $OUTPUT_ROOT_PATH ]; then
	mkdir $OUTPUT_ROOT_PATH
fi

STORE_IPA_PATH="$OUTPUT_ROOT_PATH/${PROJECT_NAME}_$APP_BUILD_TIME/${PROJECT_NAME}_adhoc.ipa"

#自动编译并且打包签名
COMPILE_IPA_PATH="$SHELL_DIR/${PROJECT_NAME}-buildsetting.plist" #编译配置文件

echo "#### 开始自动打包服务···"

sh $SHELL_DIR/Private/autobuildipa.sh $SOURCE_CODE_FOLDER $STORE_IPA_PATH $COMPILE_IPA_PATH $XCODE_BUILD_FOLDER

#分目录
IPA_OUT_FOLDER="$(dirname "$STORE_IPA_PATH")"

DSYM_OUT_FOLDER="$(dirname "$STORE_IPA_PATH")_dSYM"

if [ ! -d $DSYM_OUT_FOLDER ]; then
	mkdir $DSYM_OUT_FOLDER
fi

mv $IPA_OUT_FOLDER/*.dSYM $DSYM_OUT_FOLDER

echo "#### 自动打包服务执行结束!"



