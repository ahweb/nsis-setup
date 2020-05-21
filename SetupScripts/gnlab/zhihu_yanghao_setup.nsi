# ====================== 自定义宏 产品信息==============================
!define COMPANY_NAME                    "光年实验室"
!define PRODUCT_NAME           		    "知乎养号工具"
!define PRODUCT_DESCRIPTION             "模拟真实用户行为，提升账号权重"
!define DISK_USAGE                      "92.0MB"
!define FEATURE_1_DESCRIPTION           ""
!define FEATURE_2_DESCRIPTION           ""
!define FEATURE_3_DESCRIPTION           ""
!define COMPANY_URL                     "http://www.gnlab.com"
!define UNINSTALL_FINISH_DESCRIPTION    "感谢你的使用"
!define PRODUCT_PATHNAME 			    "Zhihu_Yanghao_PC"  #安装卸载项用到的KEY
!define INSTALL_APPEND_PATH             "LightYear\ZhihuYangHao"	  #安装路径追加的名称 
!define INSTALL_DEFALT_SETUPPATH        ""       #默认生成的安装路径  
!define EXE_NAME               		    "ZhihuYangHao.exe"
!define PRODUCT_PUBLISHER      		    "光年实验室"
!define PRODUCT_LEGAL          		    "光年实验室 Copyright（c）2020"
!define INSTALL_OUTPUT_BASE_NAME        "Zhihu_Yanghao_PC_Setup"

# ====================== 自定义宏 安装信息==============================
!define INSTALL_7Z_PATH 	   		"..\app.7z"
!define INSTALL_7Z_NAME 	   		"app.7z"
!define INSTALL_RES_PATH       		"skin.zip"
!define INSTALL_LICENCE_FILENAME    "licence_zhihu.rtf"
!define INSTALL_ICO 				"logo.ico"

!include "zhihu_yanghao_version.nsh"
!include "ui_gnlab_setup.nsh"

# ==================== NSIS属性 ================================

# 针对Vista和win7 的UAC进行权限请求.
# RequestExecutionLevel none|user|highest|admin
RequestExecutionLevel admin

#SetCompressor zlib

; 安装包名字.
Name "${PRODUCT_NAME}"

# 安装程序文件名.

OutFile "..\..\Output\${INSTALL_OUTPUT_BASE_NAME}_v${PRODUCT_VERSION}.exe"

;$PROGRAMFILES32\

InstallDir "1"

# 安装和卸载程序图标
Icon              "${INSTALL_ICO}"
UninstallIcon     "uninst.ico"
