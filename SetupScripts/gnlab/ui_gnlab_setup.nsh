
# ===================== 外部插件以及宏 =============================
!include "StrFunc.nsh"
!include "WordFunc.nsh"
${StrRep}
${StrStr}
!include "LogicLib.nsh"
!include "nsDialogs.nsh"
!include "common.nsh"
!include "x64.nsh"
!include "MUI.nsh"
!include "WinVer.nsh" 
!include "..\commonfunc.nsh"

!insertmacro MUI_LANGUAGE "SimpChinese"
# ===================== 安装包版本 =============================
VIProductVersion             		"${PRODUCT_VERSION}"
VIAddVersionKey "ProductVersion"    "${PRODUCT_VERSION}"
VIAddVersionKey "ProductName"       "${PRODUCT_NAME}"
VIAddVersionKey "CompanyName"       "${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileVersion"       "${PRODUCT_VERSION}"
VIAddVersionKey "InternalName"      "${EXE_NAME}"
VIAddVersionKey "FileDescription"   "${PRODUCT_NAME}"
VIAddVersionKey "LegalCopyright"    "${PRODUCT_LEGAL}"

!define INSTALL_PAGE_CONFIG 			0
;!define INSTALL_PAGE_LICENSE 			1
!define INSTALL_PAGE_PROCESSING 		1
!define INSTALL_PAGE_UPDATING		 	2
!define INSTALL_PAGE_FINISH 			3
!define INSTALL_PAGE_UNISTCONFIG 		4
!define INSTALL_PAGE_UNISTPROCESSING 	5
!define INSTALL_PAGE_UNISTFINISH 		6


# 自定义页面
Page custom DUIPage

# 卸载程序显示进度
UninstPage custom un.DUIPage

# ======================= DUILIB 自定义页面 =========================
Var hInstallDlg
Var hInstallSubDlg
Var sCmdFlag
Var sCmdSetupPath
Var sSetupPath 
Var sReserveData   #卸载时是否保留数据 
Var InstallState   #是在安装中还是安装完成  
Var UnInstallValue  #卸载的进度  
Var Updating
Var lastRunApp
Var manualAppDir

Var temp11
Var temp12
Function DUIPage
    StrCpy $InstallState "0"	#设置未安装完成状态
	StrCpy $Updating "0"
	InitPluginsDir   	
	SetOutPath "$PLUGINSDIR"
	File "${INSTALL_LICENCE_FILENAME}"
    File "${INSTALL_RES_PATH}"
	File /oname=logo.ico "${INSTALL_ICO}" 		#此处的目标文件一定是logo.ico，否则控件将找不到文件 
	nsNiuniuSkin::InitSkinPage "$PLUGINSDIR\" "${INSTALL_LICENCE_FILENAME}" #指定插件路径及协议文件名称
    Pop $hInstallDlg
   	
	#生成安装路径，包含识别旧的安装路径  
    Call GenerateSetupAddress
	
	#通过命令行设置需要安装的产品名称和安装路径
	push $R0
	push $R1
	push $R2
	StrCpy $R1 ""
	StrCpy $R2 ""
	StrCpy $manualAppDir ""
	#获取命令行参数，形式 -path="D:\TEMP"
	${Getparameters} $R0

	#解析参数数据
	${GetOptions} $R0 "APPDIR=" $R2
	${GetOptions} $R0 "lastRunApp=" $R1
	pop $R0

	#${StrRep} $R2 $R2 " l" ""
	#${StrRep} $R2 $R2 '"' ""

	#StrCpy $R8 "$R2"
	#StrCpy $R7 "0"
	#Call ShowMsgBox

	#设置安装路径
	${If} $R2 == ""
	${Else}
		StrCpy $manualAppDir "$R2"
		StrCpy $INSTDIR "$R2"
		StrCpy $Updating "1"
    ${endif}

	pop $R2

	#最后运行程序
	${If} $R1 == ""
	${Else}
		StrCpy $lastRunApp "$R1"
    ${endif}

	pop $R1

	#设置控件显示安装路径 
    nsNiuniuSkin::SetControlAttribute $hInstallDlg "editDir" "text" "$INSTDIR\"
	Call OnRichEditTextChange
	#设置安装包的标题及任务栏显示  
	nsNiuniuSkin::SetWindowTile $hInstallDlg"${PRODUCT_NAME}安装程序"

	#configpage
	#nsNiuniuSkin::SetControlAttribute $hInstallDlg "configpage_title" "text" "${COMPANY_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "configpage_productname" "text" "${PRODUCT_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "configpage_description" "text" "${PRODUCT_DESCRIPTION}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "configpage_version" "text" "v${PRODUCT_VERSION}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "configpage_diskusage" "text" "软件所需空间：${DISK_USAGE}"

	#installingpage
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "installingpage_title" "text" "${PRODUCT_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "installingpage_description" "text" "请稍后，安装向导正在安装${PRODUCT_NAME}，期间可能需要几分钟。"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "installingpage_feature1" "text" "${FEATURE_1_DESCRIPTION}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "installingpage_feature2" "text" "${FEATURE_2_DESCRIPTION}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "installingpage_feature3" "text" "${FEATURE_3_DESCRIPTION}"

	#finishpage
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "finishpage_title" "text" "${PRODUCT_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "finishpage_description" "text" "${PRODUCT_NAME}已成功安装完成。"

	#licensepage
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "licensename" "text" "${PRODUCT_NAME}服务条款"
	#nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnAgreement" "text" "  用户许可协议"

	#updatingpage
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "updatingpage_title" "text" "${PRODUCT_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "updatingpage_productname" "text" "${PRODUCT_NAME}"

    Call BindUIControls	

	${If} $Updating == "1"
		call OnBtnInstall
	${Else}
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_CONFIG}
	${endif}
	
    nsNiuniuSkin::ShowPage 0	
    	
FunctionEnd

Function un.DUIPage
	StrCpy $InstallState "0"
    InitPluginsDir
	SetOutPath "$PLUGINSDIR"
    File "${INSTALL_RES_PATH}"
	nsNiuniuSkin::InitSkinPage "$PLUGINSDIR\" "" 
    Pop $hInstallDlg
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_UNISTCONFIG}
	#设置安装包的标题及任务栏显示  
	nsNiuniuSkin::SetWindowTile $hInstallDlg"${PRODUCT_NAME}卸载程序"
	nsNiuniuSkin::SetWindowSize $hInstallDlg 656 370
	Call un.BindUnInstUIControls
	
	#uninstallpage
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallpage_title" "text" "${PRODUCT_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallpage_productname" "text" "${PRODUCT_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallpage_version" "text" "v${PRODUCT_VERSION}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallpage_description" "text" "是否卸载${PRODUCT_NAME}，如程序无法正常运行，你可以尝试至官网下载最新安装包。"

	#uninstallingpage
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallingpage_title" "text" "${PRODUCT_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallingpage_description" "text" "请稍后，正在卸载${PRODUCT_NAME}，期间可能需要几分钟。"
	
	#uninstallfinishpage
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallfinishpage_title" "text" "${PRODUCT_NAME}"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallfinishpage_finished_description" "text" "${PRODUCT_NAME}已卸载"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "uninstallfinishpage_description" "text" "${UNINSTALL_FINISH_DESCRIPTION}"

	nsNiuniuSkin::SetControlAttribute $hInstallDlg "chkAutoRun" "selected" "true"
	
    nsNiuniuSkin::ShowPage 0
	
FunctionEnd

#绑定卸载的事件 
Function un.BindUnInstUIControls
	GetFunctionAddress $0 un.ExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnUninstalled" $0
	
	GetFunctionAddress $0 un.onUninstall
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnUnInstall" $0
	
	GetFunctionAddress $0 un.ExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnClose" $0
FunctionEnd

#绑定安装的界面事件 
Function BindUIControls
	# License页面
    GetFunctionAddress $0 OnExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnLicenseClose" $0
    
    GetFunctionAddress $0 OnBtnMin
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnLicenseMin" $0
    
	
	GetFunctionAddress $0 OnBtnLicenseClick
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnAgreement" $0
	
    # 目录选择 页面
    GetFunctionAddress $0 OnExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnDirClose" $0
	
	GetFunctionAddress $0 OnExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnLicenseCancel" $0
    
    GetFunctionAddress $0 OnBtnMin
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnDirMin" $0
    
    GetFunctionAddress $0 OnBtnSelectDir
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnSelectDir" $0
    
    GetFunctionAddress $0 OnBtnDirPre
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnDirPre" $0
    
	GetFunctionAddress $0 OnBtnShowConfig
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnAgree" $0
	
    GetFunctionAddress $0 OnBtnCancel
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnDirCancel" $0
        
    GetFunctionAddress $0 OnBtnInstall
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnInstall" $0
    
    # 安装进度 页面
    GetFunctionAddress $0 OnExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnDetailClose" $0
    
    GetFunctionAddress $0 OnBtnMin
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnDetailMin" $0

    # 安装完成 页面
    GetFunctionAddress $0 OnFinished
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnRun" $0
    
    GetFunctionAddress $0 OnBtnMin
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnFinishedMin" $0
    
    GetFunctionAddress $0 OnExitDUISetup
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnClose" $0
	
	GetFunctionAddress $0 OnCheckLicenseClick
    nsNiuniuSkin::BindCallBack $hInstallDlg "chkAgree" $0
	
	GetFunctionAddress $0 OnBtnShowMore
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnShowMore" $0

	GetFunctionAddress $0 OnBtnInstall
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnInstallNow" $0
	
	GetFunctionAddress $0 OnBtnHideMore
    nsNiuniuSkin::BindCallBack $hInstallDlg "btnHideMore" $0
	
	#绑定窗口通过alt+f4等方式关闭时的通知事件 
	GetFunctionAddress $0 OnSysCommandCloseEvent
    nsNiuniuSkin::BindCallBack $hInstallDlg "syscommandclose" $0
	
	#绑定路径变化的通知事件 
	GetFunctionAddress $0 OnRichEditTextChange
    nsNiuniuSkin::BindCallBack $hInstallDlg "editDir" $0
FunctionEnd

#此处是路径变化时的事件通知 
Function OnRichEditTextChange
	#可在此获取路径，判断是否合法等处理 
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "editDir" "text"
    Pop $0	
	StrCpy $INSTDIR "$0"
	
	Call IsSetupPathIlleagal
	${If} $R5 == "0"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "text" "路径非法"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "textcolor" "#ffff0000"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "false"
		goto TextChangeAbort
    ${EndIf}
	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "textcolor" "#FF999999"
	${If} $R0 > 1024                               #400即程序安装后需要占用的实际空间，单位：MB  
	    
		IntOp $R1  $R0 % 1024	
		IntOp $R0  $R0 / 1024;		
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "text" "剩余空间：$R0.$R1GB"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "local_space" "text" "剩余空间：$R0.$R1MB"
     ${endif}
	
#	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkAgree" "selected"
#    Pop $0
#	${If} $0 == "1"        
#		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "true"
#	${Else}
#		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "false"
#    ${EndIf}
	
TextChangeAbort:
FunctionEnd


#根据选中的情况来控制按钮是否灰度显示 
Function OnCheckLicenseClick
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkAgree" "selected"
    Pop $0
	${If} $0 == "0"        
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "true"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "enabled" "false"
    ${EndIf}
FunctionEnd

Function OnBtnLicenseClick
    ;nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_LICENSE}
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "licenseshow" "visible" "true"
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "moreconfiginfo" "visible"
	Pop $0
	${If} $0 = 0        
		;pos="10,35,560,405"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "licenseshow" "pos" "93,35,563,365"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "editLicense" "height" "250"		
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "licenseshow" "pos" "93,35,563,475"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "editLicense" "height" "360"
    ${EndIf}
	
FunctionEnd

# 添加一个静默安装的入口
Section "silentInstallSec" SEC01
    #MessageBox MB_OK|MB_ICONINFORMATION "Test silent install. you can add your silent install code here."
SectionEnd

Function ShowMsgBox
	nsNiuniuSkin::InitSkinSubPage "msgBox.xml" "btnOK" "btnCancel,btnClose"  ; "提示" "${PRODUCT_NAME} 正在运行，请退出后重试!" 0
	Pop $hInstallSubDlg
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "lblTitle" "text" "提示"
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "lblMsg" "text" "$R8"
	${If} "$R7" == "1"
		nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "hlCancel" "visible" "true"
	${EndIf}
	
	nsNiuniuSkin::ShowSkinSubPage 0 
FunctionEnd

Function GetLatestDotNETVersion
 
	;Save the variables in case something else is using them
 
	Push $0		; Registry key enumerator index
	Push $1		; Registry value
	Push $2		; Temp var
	Push $R0	; Max version number
	Push $R1	; Looping version number
 
	StrCpy $R0 "0.0.0"
	StrCpy $0 0
 
	loop:
 
		; Get each sub key under "SOFTWARE\Microsoft\NET Framework Setup\NDP"
		EnumRegKey $1 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP" $0
 
		StrCmp $1 "" done 	; jump to end if no more registry keys
 
		IntOp $0 $0 + 1 	; Increase registry key index
		StrCpy $R1 $1 "" 1 	; Looping version number, cut of leading 'v'
 
		${VersionCompare} $R1 $R0 $2
		; $2=0  Versions are equal, ignore
		; $2=1  Looping version $R1 is newer
        ; $2=2  Looping version $R1 is older, ignore
 
		IntCmp $2 1 newer_version loop loop
 
		newer_version:
		StrCpy $R0 $R1
		goto loop
 
	done:
 
	; If the latest version is 0.0.0, there is no .NET installed ?!
	${VersionCompare} $R0 "0.0.0" $2
	IntCmp $2 0 no_dotnet clean clean
 
	no_dotnet:
	StrCpy $R0 ""
 
	clean:
	; Pop the variables we pushed earlier
	Pop $0
	Pop $1
	Pop $2
	Pop $R1
 
	; $R0 contains the latest .NET version or empty string if no .NET is available
FunctionEnd

Function CheckAndInstallDotNet
    ; Magic numbers from http://msdn.microsoft.com/en-us/library/ee942965.aspx
    ClearErrors
    ReadRegDWORD $0 HKLM "SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" "Release"

    IfErrors NotDetected

    ${If} $0 >= 379893
	
        DetailPrint "Microsoft .NET Framework 4.5.2 is installed ($0)"
    ${Else}
    NotDetected:
        DetailPrint "Installing Microsoft .NET Framework 4.5.2"
        SetDetailsPrint listonly
		nsNiuniuSkin::SetWindowSize $hInstallDlg 0 0
		SetOutPath $TEMP\gnlab\${PRODUCT_NAME}
		File "${INSTALL_7Z_PATH}"
		nsis7zU::Extract "$TEMP\gnlab\${PRODUCT_NAME}\${INSTALL_7Z_NAME}"
        ExecWait '"$TEMP\gnlab\${PRODUCT_NAME}\${DOT_NET_FRAMEWORK}" /passive /norestart' $0
        RMDir /r $TEMP\gnlab\${PRODUCT_NAME}
		nsNiuniuSkin::SetWindowSize $hInstallDlg 656 370
        ${If} $0 == 3010 
        ${OrIf} $0 == 1641
            DetailPrint "Microsoft .NET Framework 4.5.2 installer requested reboot"
            SetRebootFlag true
        ${EndIf}
        SetDetailsPrint lastused
        DetailPrint "Microsoft .NET Framework 4.5.2 installer returned $0"
    ${EndIf}

FunctionEnd

Function CreateShortcut
	SetShellVarContext all
  	CreateDirectory "$SMPROGRAMS\${PRODUCT_NAME}"
  	CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk" "$INSTDIR\${EXE_NAME}"
  	CreateShortCut "$SMPROGRAMS\${PRODUCT_NAME}\卸载${PRODUCT_NAME}.lnk" "$INSTDIR\uninst.exe"
  
  	#根据复选框的值来决定是否添加桌面快捷方式  
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkShotcut" "selected"
	Pop $R0
	
	${If} $R0 == "1" #添加到桌面快捷方式的动作 在此添加  
	CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" "$INSTDIR\${EXE_NAME}"	
	${EndIf}
  	SetShellVarContext current
FunctionEnd

# 开始安装
Function OnBtnInstall
	Call CheckAndInstallDotNet

    nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkAgree" "selected"
    Pop $0
	StrCpy $0 "1"
		
	#如果未同意，直接退出 
	StrCmp $0 "0" InstallAbort 0
	
	#此处检测当前是否有程序正在运行，如果正在运行，提示先卸载再安装 
	nsProcess::_FindProcess "${EXE_NAME}"
	Pop $R0
	
	${If} $R0 == 0
        StrCpy $R8 "${PRODUCT_NAME} 正在运行，是否关闭并继续?"
		StrCpy $R7 "1"
		Call ShowMsgBox
		pop $0
		${If} $0 == 1
			nsProcess::_KillProcess "${EXE_NAME}"
		${Else}
			nsNiuniuSkin::ExitDUISetup
			goto InstallAbort
		${EndIf}	
    ${EndIf}		

	nsNiuniuSkin::GetControlAttribute $hInstallDlg "editDir" "text"
    Pop $0
    StrCmp $0 "" InstallAbort 0
	
	#校正路径（追加）  
	Call AdjustInstallPath
	StrCpy $sSetupPath "$INSTDIR"	
	
	Call IsSetupPathIlleagal
	${If} $R5 == "0"
		StrCpy $R8 "路径非法，请使用正确的路径安装!"
		StrCpy $R7 "0"
		Call ShowMsgBox
		goto InstallAbort
    ${EndIf}	
	${If} $R5 == "-1"
		StrCpy $R8 "目标磁盘空间不足，请使用其他的磁盘安装!"
		StrCpy $R7 "0"
		Call ShowMsgBox
		goto InstallAbort
    ${EndIf}
	
	
	nsNiuniuSkin::SetWindowSize $hInstallDlg 656 370
#	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "false"

	${If} $Updating == "1"
		nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_UPDATING}
	${Else}
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_PROCESSING}
	${endif}
    
    nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrProgress" "min" "0"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrProgress" "max" "100"
	
    # 将这些文件暂存到临时目录
    #Call BakFiles
    
    #启动一个低优先级的后台线程
    GetFunctionAddress $0 ExtractFunc
    BgWorker::CallAndWait	

	Call CreateShortcut
	Call CreateUninstall

	Sleep 500

	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "true"		
	StrCpy $InstallState "1"
	#如果不想完成立即启动的话，需要屏蔽下面的OnFinished的调用，并且打开显示INSTALL_PAGE_FINISH

	${If} $Updating == "1"
		${If} $lastRunApp != ""
			Exec "$lastRunApp"
		${endif}
		Call OnFinished
	${Else}
		nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_FINISH}
	${endif}
InstallAbort:
FunctionEnd

Function ExtractCallback
    Pop $1
    Pop $2
    System::Int64Op $1 * 100
    Pop $3
    System::Int64Op $3 / $2
    Pop $0
	
	${If} $Updating == "1"
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUpdatingProgress" "value" "$0"	
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "updating_progress_pos" "text" "$0%"
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrProgress" "value" "$0"	
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_pos" "text" "$0%"
	${endif}

    ${If} $1 == $2  
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrProgress" "value" "100"	
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "progress_pos" "text" "100%"
    ${EndIf}
FunctionEnd

#CTRL+F4关闭时的事件通知 
Function OnSysCommandCloseEvent
	Call OnExitDUISetup
FunctionEnd

#安装界面点击退出，给出提示 
Function OnExitDUISetup
	${If} $InstallState == "0"		
		StrCpy $R8 "安装尚未完成，您确定退出安装么？"
		StrCpy $R7 "1"
		Call ShowMsgBox
		pop $0
		${If} $0 == 0
			goto endfun
		${EndIf}
	${EndIf}
	nsNiuniuSkin::ExitDUISetup
endfun:    
FunctionEnd

Function OnBtnMin
    SendMessage $hInstallDlg ${WM_SYSCOMMAND} 0xF020 0
FunctionEnd

Function OnBtnCancel
	nsNiuniuSkin::ExitDUISetup
FunctionEnd

Function OnFinished	
		    
	#立即启动
    Exec "$INSTDIR\${EXE_NAME}"
    Call OnExitDUISetup
FunctionEnd

Function OnBtnSelectDir
    nsNiuniuSkin::SelectInstallDirEx $hInstallDlg "请选择安装路径"
    Pop $0
	${Unless} "$0" == ""
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "editDir" "text" $0
	${EndUnless}
FunctionEnd

Function StepHeightSizeAsc
${ForEach} $R0 473 463 + 10
  nsNiuniuSkin::SetWindowSize $hInstallDlg 656 $R0
  Sleep 5
${Next}
FunctionEnd

Function StepHeightSizeDsc
${ForEach} $R0 370 380 - 10
  nsNiuniuSkin::SetWindowSize $hInstallDlg 656 $R0
  Sleep 5
${Next}
FunctionEnd

Function OnBtnShowMore	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnShowMore" "enabled" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnHideMore" "enabled" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "moreconfiginfo" "visible" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnHideMore" "visible" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnShowMore" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstallNow" "visible" "true"
	;调整窗口高度 
	 GetFunctionAddress $0 StepHeightSizeAsc
    BgWorker::CallAndWait
	
	nsNiuniuSkin::SetWindowSize $hInstallDlg 656 473
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnShowMore" "enabled" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnHideMore" "enabled" "true"
FunctionEnd

Function OnBtnHideMore
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnShowMore" "enabled" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnHideMore" "enabled" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "moreconfiginfo" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnHideMore" "visible" "false"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnShowMore" "visible" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstall" "visible" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnInstallNow" "visible" "false"
	;调整窗口高度 
	 GetFunctionAddress $0 StepHeightSizeDsc
    BgWorker::CallAndWait
	nsNiuniuSkin::SetWindowSize $hInstallDlg 656 370
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnShowMore" "enabled" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnHideMore" "enabled" "true"
FunctionEnd


Function OnBtnShowConfig
    ;nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_CONFIG}
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "licenseshow" "visible" "false"
FunctionEnd

Function OnBtnDirPre
    
	StrCpy $R8 "安装尚未完成，您确定退出安装么？"
	StrCpy $R7 "0"
	Call ShowMsgBox
		;nsNiuniuSkin::PrePage "wizardTab"
FunctionEnd


Function un.ShowMsgBox
	nsNiuniuSkin::InitSkinSubPage "msgBox.xml" "btnOK" "btnCancel,btnClose"  ; "提示" "${PRODUCT_NAME} 正在运行，请退出后重试!" 0
	Pop $hInstallSubDlg
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "lblTitle" "text" "提示"
	nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "lblMsg" "text" "$R8"
	${If} "$R7" == "1"
		nsNiuniuSkin::SetControlAttribute $hInstallSubDlg "hlCancel" "visible" "true"
	${EndIf}
	
	nsNiuniuSkin::ShowSkinSubPage 0 
FunctionEnd

Function un.ExitDUISetup
	nsNiuniuSkin::ExitDUISetup
FunctionEnd


# 添加一个静默卸载的入口 
Section "un.silentInstallSec" SEC02
    #MessageBox MB_OK|MB_ICONINFORMATION "Test silent install. you can add your silent uninstall code here."
SectionEnd

#执行具体的卸载 
Function un.onUninstall
	nsNiuniuSkin::GetControlAttribute $hInstallDlg "chkReserveData" "selected"
    Pop $0
	StrCpy $sReserveData $0
		
	#此处检测当前是否有程序正在运行，如果正在运行，提示先卸载再安装 
	nsProcess::_FindProcess "${EXE_NAME}"
	Pop $R0
	
	${If} $R0 == 0
		StrCpy $R8 "${PRODUCT_NAME} 正在运行，请退出后重试!"
		StrCpy $R7 "0"
		Call un.ShowMsgBox
		goto InstallAbort
    ${EndIf}
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "false"
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_UNISTPROCESSING}
	
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "min" "0"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "max" "100"
	IntOp $UnInstallValue 0 + 1
	
	Call un.DeleteShotcutAndInstallInfo
	
	IntOp $UnInstallValue $UnInstallValue + 8
    
	#删除文件 
	GetFunctionAddress $0 un.RemoveFiles
    BgWorker::CallAndWait
	InstallAbort:
FunctionEnd

#在线程中删除文件，以便显示进度 
Function un.RemoveFiles
	${Locate} "$INSTDIR" "/G=0 /M=*.*" "un.onDeleteFileFound"
	StrCpy $InstallState "1"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "btnClose" "enabled" "true"
	nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "value" "100"	
	nsNiuniuSkin::ShowPageItem $hInstallDlg "wizardTab" ${INSTALL_PAGE_UNISTFINISH}
FunctionEnd


#卸载程序时删除文件的流程，如果有需要过滤的文件，在此函数中添加  
Function un.onDeleteFileFound
    ; $R9    "path\name"
    ; $R8    "path"
    ; $R7    "name"
    ; $R6    "size"  ($R6 = "" if directory, $R6 = "0" if file with /S=)
    
	
	#是否过滤删除  
			
	Delete "$R9"
	RMDir /r "$R9"
    RMDir "$R9"
	
	IntOp $UnInstallValue $UnInstallValue + 2
	${If} $UnInstallValue > 100
		IntOp $UnInstallValue 100 + 0
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "value" "100"	
	${Else}
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "slrUnInstProgress" "value" "$UnInstallValue"	
		nsNiuniuSkin::SetControlAttribute $hInstallDlg "un_progress_pos" "text" "$UnInstallValue%"
		
		Sleep 100
	${EndIf}	
	undelete:
	Push "LocateNext"	
FunctionEnd