#!/bin/bash
SHELL_DIR=$(cd `dirname $0`; pwd)

#参数校验
if [ $# -lt 2 ]; then
	echo "调用自动打包的脚本的参数个数有误,例如:./autobuildipa.sh sourcepath [ipa_filepath] [buildsetting.plist's filepath] [build_cache_path]"
	exit 1
fi

#1.读取工程路径
XCODEPROJ_FOLDER_PATH="$1"
echo "-> 工程路径:"$XCODEPROJ_FOLDER_PATH

#2.ipa路径
IPA_PATH=$SHELL_DIR/$TARGET.ipa
#如果存在2个参数，那么第二个参数为ipa的路径
if [ $# -gt 1 ]; then
	IPA_PATH="$2"
	echo "-> ipa输出路径:"$IPA_PATH
fi

#3.编译配置文件路径
BUILDSETTINGFILE="$SHELL_DIR/buildsetting.plist"
#如果有自定义配置文件路径
if [ $# -gt 2 ]; then
	BUILDSETTINGFILE="$3"
fi
echo "-> 编译配置文件路径:"$BUILDSETTINGFILE

#4.编译临时文件路径
XCODE_BUILD_PATH="../buildtmp" #"$(pwd)/build"
if [ $# -gt 3 ]; then
	XCODE_BUILD_PATH="$4"
fi

#读取Plist函数
function readItem()
{
	if [ $# -lt 2 ]; then
		echo "usage : readItem setting.plist itemName"
	fi
	
	plistFilePath=$1
	itemName=$2

	/usr/libexec/PlistBuddy -c "print :$2" $1
}

#5.读取编译配置文件
SDK=`readItem $BUILDSETTINGFILE SDK_VERSION`
ARCH=`readItem $BUILDSETTINGFILE ARCHITECTURES`
TARGET=`readItem $BUILDSETTINGFILE TARGET`
CONFIGURATION=`readItem $BUILDSETTINGFILE CONFIGURATION`
CODE_SIGN_IDENTITY=`readItem $BUILDSETTINGFILE CODE_SIGN_IDENTITY`
PROVISIONING_PROFILE=`readItem $BUILDSETTINGFILE PROVISIONING_PROFILE`
PROJECT_NAME=`readItem $BUILDSETTINGFILE PROJECT_NAME`
BUILD_TYPE=`readItem $BUILDSETTINGFILE PROJECT_TYPE`
GCC_PREPROCESSOR_DEFINITIONS=`readItem $BUILDSETTINGFILE GCC_PREPROCESSOR_DEFINITIONS`

pushd $(pwd)
cd $XCODEPROJ_FOLDER_PATH

errorcode=0

#############安装brew 和xctool#############
if which brew 2>/dev/null; then
  echo "-> brew已经安装"
else
  echo "-> 检测到brew未安装,开始安装brew···"
  curl -LsSf http://github.com/mxcl/homebrew/tarball/master | sudo tar xvz -C/usr/local --strip 1
fi

if which xctool>/dev/null; then
  echo "-> xctool已经安装"
else
  echo "-> 检测到xctool未安装,开始安装xctool···"
  sudo brew update
  sudo brew install xctool 
fi

# build前清除缓存目录
if [ $XCODE_BUILD_PATH  ] && [ -d $XCODE_BUILD_PATH ]; then
	rm -rf $XCODE_BUILD_PATH
fi

#使用xctool自动打包
schemeName=$TARGET

#编译代码
#/usr/bin/xcodebuild \
#	-target $TARGET \
#	-configuration $CONFIGURATION \
#	-arch $ARCH \
#	-sdk "$SDK" \
#	CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
#	PROVISIONING_PROFILE="$PROVISIONING_PROFILE" \
#	CONFIGURATION_BUILD_DIR="$XCODE_BUILD_PATH" \
#	GCC_PREPROCESSOR_DEFINITIONS="$GCC_PREPROCESSOR_DEFINITIONS" \
#	clean \
#	build

if [ "$BUILD_TYPE" = "workspace" ];  then

	echo "-> 开始编译工作空间"

	project_path=$XCODEPROJ_FOLDER_PATH/$PROJECT_NAME".xcworkspace"

	xctool \
		-workspace $project_path \
		-scheme $schemeName \
		-configuration $CONFIGURATION \
		-sdk $SDK \
		clean
	xctool \
		-workspace  $project_path \
		-scheme $schemeName \
		-configuration $CONFIGURATION \
		-sdk $SDK \
		CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY" \
		PROVISIONING_PROFILE="$PROVISIONING_PROFILE" \
		CONFIGURATION_BUILD_DIR="$XCODE_BUILD_PATH" \
		ONLY_ACTIVE_ARCH=NO \
		build
else
	echo "-> 开始编译工程"

	project_path=$XCODEPROJ_FOLDER_PATH/$TARGET".xcodeproj"

	xctool \
		-project $project_path \
		-scheme $schemeName \
		-configuration $CONFIGURATION \
		-sdk $SDK \
		clean
	xctool \
		-project  $project_path \
		-scheme $schemeName \
		-configuration $CONFIGURATION \
		-sdk $SDK \
		CONFIGURATION_BUILD_DIR="$XCODE_BUILD_PATH" \
		ONLY_ACTIVE_ARCH=NO \
		build
fi

errorcode=$?

if [ ! $errorcode -eq 0 ]; then
	echo "-> 编译失败"
else
	echo "-> 编译成功"

	APP_BUILD_PATH=$(find $XCODE_BUILD_PATH -type d -name "*.app")
	APP_dSYM_PATH=$(find $XCODE_BUILD_PATH -type d -name "*.app.dSYM")
	IPA_dSYM_PATH=$IPA_PATH".dSYM"

	echo "##############"

	IPA_OUT_FOLDER="$(dirname "$IPA_PATH")"
	if [ -d $IPA_OUT_FOLDER ]; then
		rm -rf $IPA_OUT_FOLDER
	fi
	mkdir $IPA_OUT_FOLDER
	
	#打包程序 
	#--sign $CODE_SIGN_IDENTITY --embed $PROVISIONING_PROFILE
	echo "-> 开始打包···"
	xcrun -sdk iphoneos PackageApplication -v $APP_BUILD_PATH -o $IPA_PATH 
	errorcode=$?

	if [ ! $errorcode -eq 0 ]; then
		echo "-> 打包失败"
	else
		DSYM_OUT_FOLDER="$(dirname "$IPA_dSYM_PATH")"
		if [ ! -d $DSYM_OUT_FOLDER ]; then
			mkdir $DSYM_OUT_FOLDER
		fi

		cp -aR $APP_dSYM_PATH $IPA_dSYM_PATH
		echo "-> 打包成功"

		echo "-> 导出的ipa路径:"$IPA_PATH
		echo "-> 编译成功的app路径:"$APP_BUILD_PATH
		echo "-> 编译成功的dSYM路径:"$APP_dSYM_PATH
	fi
fi

# 打包完成后清除缓存目录
if [ $XCODE_BUILD_PATH  ] && [ -d $XCODE_BUILD_PATH ]; then
	rm -rf $XCODE_BUILD_PATH
fi

exit $errorcode;
popd