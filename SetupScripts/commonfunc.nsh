Function AdjustInstallPath
	#此处判断最后一段，如果已经是与我要追加的目录名一样，就不再追加了，如果不一样，则还需要追加 同时记录好写入注册表的路径  	
	nsNiuniuSkin::StringHelper "$0" "\" "" "trimright"
	pop $0
	nsNiuniuSkin::StringHelper "$0" "\" "" "getrightbychar"
	pop $1	
		
	StrCpy $INSTDIR "$0"
	#${If} "$1" == "${INSTALL_APPEND_PATH}"
	#	StrCpy $INSTDIR "$0"
	#${Else}
	#	StrCpy $INSTDIR "$0\${INSTALL_APPEND_PATH}"
	#${EndIf}

FunctionEnd


#判断选定的安装路径是否合法，主要检测硬盘是否存在[只能是HDD]，路径是否包含非法字符 结果保存在$R5中 
Function IsSetupPathIlleagal

${GetRoot} "$INSTDIR" $R3   ;获取安装根目录  

StrCpy $R0 "$R3\"  
StrCpy $R1 "invalid"  
${GetDrives} "HDD" "HDDDetection"            ;获取将要安装的根目录磁盘类型

${If} $R1 == "HDD"              ;是硬盘       
	 StrCpy $R5 "1"	 
	 ${DriveSpace} "$R3\" "/D=F /S=M" $R0           #获取指定盘符的剩余可用空间，/D=F剩余空间， /S=M单位兆字节  
	 ${If} $R0 < 100                                #400即程序安装后需要占用的实际空间，单位：MB  
	    StrCpy $R5 "-1"		#表示空间不足 
     ${endif}
${Else}  
     #0表示不合法 
	 StrCpy $R5 "0"
${endif}

FunctionEnd


Function HDDDetection
${If} "$R0" == "$9"
StrCpy $R1 "HDD"
;goto funend
${Endif}
Push $0
funend:
FunctionEnd



#获取默认的安装路径 
Function GenerateSetupAddress
	#读取注册表安装路径 
	SetRegView 32	
	ReadRegStr $0 HKLM "Software\${PRODUCT_PATHNAME}" "InstPath"
	${If} "$0" != ""		#路径不存在，则重新选择路径  	
		#路径读取到了，直接使用 
		#再判断一下这个路径是否有效 
		nsNiuniuSkin::StringHelper "$0" "\\" "\" "replace"
		Pop $0
		StrCpy $INSTDIR "$0"
	${EndIf}
	
	#如果从注册表读的地址非法，则还需要写上默认地址      
	Call IsSetupPathIlleagal
	${If} $R5 == "0"
		StrCpy $INSTDIR "$PROGRAMFILES32\${INSTALL_APPEND_PATH}"		
	${EndIf}	
	
FunctionEnd


#====================获取默认安装的要根目录 结果存到$R5中 
Function GetDefaultSetupRootPath
#先默认到D盘 
${GetRoot} "D:\" $R3   ;获取安装根目录  
StrCpy $R0 "$R3\"  
StrCpy $R1 "invalid"  
${GetDrives} "HDD" "HDDDetection"            ;获取将要安装的根目录磁盘类型
${If} $R1 == "HDD"              ;是硬盘  
     #检查空间是否够用
	 StrCpy $R5 "D:\" 2 0
	 ${DriveSpace} "$R3\" "/D=F /S=M" $R0           #获取指定盘符的剩余可用空间，/D=F剩余空间， /S=M单位兆字节  
	 ${If} $R0 < 300                                #400即程序安装后需要占用的实际空间，单位：MB  
	    StrCpy $R5 "C:"
     ${endif}
${Else}  
     #此处需要设置C盘为默认路径了 
	 StrCpy $R5 "C:"
${endif}
FunctionEnd


# 生成卸载入口 
Function CreateUninstall
	#写入注册信息 
	SetRegView 32
	WriteRegStr HKLM "Software\${PRODUCT_PATHNAME}" "InstPath" "$INSTDIR"
	
	WriteUninstaller "$INSTDIR\uninst.exe"
	
	# 添加卸载信息到控制面板
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "DisplayName" "${PRODUCT_NAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "UninstallString" "$INSTDIR\uninst.exe"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "DisplayIcon" "$INSTDIR\${EXE_NAME}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "Publisher" "${PRODUCT_PUBLISHER}"
	WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}" "DisplayVersion" "${PRODUCT_VERSION}"
FunctionEnd

Function ExtractFunc
	#安装文件的7Z压缩包
	SetOutPath $INSTDIR

	#根据宏来区分是否走非NSIS7Z的进度条  
!ifdef INSTALL_WITH_NO_NSIS7Z
    !include "..\app.nsh"
!else
    File "${INSTALL_7Z_PATH}"
    GetFunctionAddress $R9 ExtractCallback
    nsis7zU::ExtractWithCallback "$INSTDIR\${INSTALL_7Z_NAME}" $R9
	Delete "$INSTDIR\${INSTALL_7Z_NAME}"
!endif
	
	Sleep 500
FunctionEnd

Function un.DeleteShotcutAndInstallInfo
	SetRegView 32
	DeleteRegKey HKLM "Software\${PRODUCT_PATHNAME}"	
	DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_PATHNAME}"
	
	; 删除快捷方式
	SetShellVarContext all
	Delete "$SMPROGRAMS\${PRODUCT_NAME}\${PRODUCT_NAME}.lnk"
	Delete "$SMPROGRAMS\${PRODUCT_NAME}\卸载${PRODUCT_NAME}.lnk"
	RMDir "$SMPROGRAMS\${PRODUCT_NAME}\"
	Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
	
	#删除开机启动  
    Delete "$SMSTARTUP\${PRODUCT_NAME}.lnk"
	SetShellVarContext current
FunctionEnd

!if '${NSIS_PACKEDVERSION}' <= 0x0300003f ; Older versions don't support !macroundef
!define GetOptionsBody_Alt GetOptionsBody_Alt
!undef GetOptions
!define GetOptions `!insertmacro GetOptionsCall_Alt`
!macro GetOptionsCall_Alt _PARAMETERS _OPTION _RESULT
    !verbose push
    !verbose ${_FILEFUNC_VERBOSE}
    Push `${_PARAMETERS}`
    Push `${_OPTION}`
    ${CallArtificialFunction} GetOptions_Alt_
    Pop ${_RESULT}
    !verbose pop
!macroend
!macro GetOptions_Alt_
    !verbose push
    !verbose ${_FILEFUNC_VERBOSE}
    !insertmacro ${GetOptionsBody_Alt} ''
    !verbose pop
!macroend
!else
!define GetOptionsBody_Alt GetOptionsBody
!macroundef ${GetOptionsBody_Alt}
!endif

!macro ${GetOptionsBody_Alt} _FILEFUNC_S ; This alternative version only knows about " quotes and assumes there is nothing or a space/tab before the prefix 
Exch $1 ; Prefix
Exch
Exch $0 ; String
Exch
Push $2 ; The quote type we are in if any (Currently only supports ")
Push $3 ; Position in $0
Push $4 ; Temp
Push $5 ; Temp
Push $6 ; Start of data
ClearErrors
StrCpy $2 ''
StrCpy $3 "-1"
StrCpy $6 "-1"
FileFunc_GetOptions${_FILEFUNC_S}_loop:
    StrCpy $5 $0 1 $3
    IntOp $3 $3 + 1
    StrCpy $4 $0 1 $3
    StrCmp $4 "" FileFunc_GetOptions${_FILEFUNC_S}_eos
    StrCmp $4 '"' FileFunc_GetOptions${_FILEFUNC_S}_foundquote
    StrCmp $2 '' 0 FileFunc_GetOptions${_FILEFUNC_S}_loop ; We are inside a quote, just keep looking for the end of it
    StrCmp -1 $6 0 FileFunc_GetOptions${_FILEFUNC_S}_dataisunquoted ; Have we already found the prefix and start of data?
    IntCmpU $3 0 +2 ; $3 starts as -1 so $5 might contain the last character so we force it to a space
    StrCmp $5 '$\t' 0 +2
    StrCpy $5 " "
    StrCmp $5 " " 0 FileFunc_GetOptions${_FILEFUNC_S}_loop ; The prefix must be at the start of the string or be prefixed by space or tab
    StrLen $4 $1
    StrCpy $5 $0 $4 $3
    StrCmp${_FILEFUNC_S} "$5" "$1" "" FileFunc_GetOptions${_FILEFUNC_S}_loop
    IntOp $6 $4 + $3 ; Data starts here
    IntOp $3 $6 - 1 ; This is just to ignore the + 1 at the top of the loop
    Goto FileFunc_GetOptions${_FILEFUNC_S}_loop
FileFunc_GetOptions${_FILEFUNC_S}_dataisunquoted:
    StrCmp $4 ' ' FileFunc_GetOptions${_FILEFUNC_S}_extractdata
    StrCmp $4 '$\t' FileFunc_GetOptions${_FILEFUNC_S}_extractdata FileFunc_GetOptions${_FILEFUNC_S}_loop
FileFunc_GetOptions${_FILEFUNC_S}_extractdata:
    IntOp $5 $3 - $6
    StrCpy $0 $0 $5 $6
    Goto FileFunc_GetOptions${_FILEFUNC_S}_return
FileFunc_GetOptions${_FILEFUNC_S}_foundquote:
    StrCmp $2 $4 FileFunc_GetOptions${_FILEFUNC_S}_endquote
    StrCpy $2 $4 ; Starting a quoted part
    Goto FileFunc_GetOptions${_FILEFUNC_S}_loop
FileFunc_GetOptions${_FILEFUNC_S}_endquote:
    StrCpy $2 ''
    StrCmp -1 $6 FileFunc_GetOptions${_FILEFUNC_S}_loop FileFunc_GetOptions${_FILEFUNC_S}_extractquoteddata
FileFunc_GetOptions${_FILEFUNC_S}_eos: ; End Of String
    StrCmp $2 '' +2
FileFunc_GetOptions${_FILEFUNC_S}_extractquoteddata:
    IntOp $6 $6 + 1 ; Skip starting quote when extracting the data
    StrCmp -1 $6 0 FileFunc_GetOptions${_FILEFUNC_S}_extractdata
    SetErrors
    StrCpy $0 ''
FileFunc_GetOptions${_FILEFUNC_S}_return:
Pop $6
Pop $5
Pop $4
Pop $3
Pop $2
Pop $1
Exch $0
!macroend