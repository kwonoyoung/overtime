; 초과근무 기록장 — Windows 설치 프로그램 (NSIS 3)
; 만들기: build.sh 실행 (pc/초과근무기록장.html 과 pc/사용설명서.pdf 를 담습니다)
; 관리자 권한 없이 사용자 폴더에 설치하고, Edge(없으면 Chrome)의 "앱 창"으로 엽니다.
Unicode true
ManifestDPIAware true
!include "MUI2.nsh"
!include "WordFunc.nsh"
!include "FileFunc.nsh"

!define APPNAME   "초과근무 기록장"
!define APPID     "OvertimeLog"
!ifndef VERSION
  !define VERSION "1.0.6"
!endif
!define PUBLISHER "오춘기 권오영"
!define UNINSTKEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APPID}"

Name "${APPNAME}"
OutFile "OvertimeLog-v${VERSION}.exe"
InstallDir "$LOCALAPPDATA\Programs\${APPID}"
RequestExecutionLevel user
SetCompressor /SOLID lzma
BrandingText "${PUBLISHER}"

VIProductVersion "${VERSION}.0"
VIAddVersionKey /LANG=1042 "ProductName" "${APPNAME}"
VIAddVersionKey /LANG=1042 "FileDescription" "${APPNAME} 설치 프로그램"
VIAddVersionKey /LANG=1042 "CompanyName" "${PUBLISHER}"
VIAddVersionKey /LANG=1042 "LegalCopyright" "${PUBLISHER}"
VIAddVersionKey /LANG=1042 "FileVersion" "${VERSION}"
VIAddVersionKey /LANG=1042 "ProductVersion" "${VERSION}"

!define MUI_ICON "app.ico"
!define MUI_UNICON "app.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "side.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "side.bmp"
!define MUI_ABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "${APPNAME} 설치"
!define MUI_WELCOMEPAGE_TEXT "교직원 초과근무 시작·종료 기록, 인정시간 계산, 근무 확인 알림, 월별 엑셀 저장을 도와주는 프로그램입니다.$\r$\n$\r$\n관리자 권한 없이 설치되며, 인터넷이 없어도 동작합니다.$\r$\n$\r$\n[다음]을 눌러 주세요."
!insertmacro MUI_PAGE_WELCOME
!define MUI_LICENSEPAGE_TEXT_TOP "사용 전에 꼭 읽어 주세요."
!define MUI_LICENSEPAGE_BUTTON "확인"
!define MUI_LICENSEPAGE_TEXT_BOTTOM "내용을 확인했으면 [확인]을 누르세요."
!insertmacro MUI_PAGE_LICENSE "notice.txt"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_TITLE "설치가 끝났습니다"
!define MUI_FINISHPAGE_TEXT "바탕화면과 시작 메뉴의 [${APPNAME}] 아이콘으로 실행하세요.$\r$\n$\r$\n초과근무 중 근무 확인 알림은 프로그램 창이 열려 있을 때 울립니다. (최소화는 괜찮습니다)"
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_TEXT "지금 ${APPNAME} 실행"
!define MUI_FINISHPAGE_RUN_FUNCTION RunApp
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\사용설명서.pdf"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "사용설명서 보기"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "Korean"

Var Browser   ; 앱 창으로 열 브라우저 실행 파일 (없으면 빈칸)
Var AppArgs   ; 브라우저에 넘길 인수

; Edge → Chrome 순서로 브라우저를 찾습니다.
!macro TryAppPath ROOT EXE
  ${If} $Browser == ""
    ReadRegStr $0 ${ROOT} "Software\Microsoft\Windows\CurrentVersion\App Paths\${EXE}" ""
    ${If} $0 != ""
    ${AndIf} ${FileExists} "$0"
      StrCpy $Browser "$0"
    ${EndIf}
  ${EndIf}
!macroend
!macro TryFile PATH
  ${If} $Browser == ""
  ${AndIf} ${FileExists} "${PATH}"
    StrCpy $Browser "${PATH}"
  ${EndIf}
!macroend

Function FindBrowser
  StrCpy $Browser ""
  SetRegView 64
  !insertmacro TryAppPath HKLM "msedge.exe"
  !insertmacro TryAppPath HKCU "msedge.exe"
  SetRegView 32
  !insertmacro TryAppPath HKLM "msedge.exe"
  !insertmacro TryAppPath HKCU "msedge.exe"
  ReadEnvStr $1 "ProgramFiles(x86)"
  ReadEnvStr $2 "ProgramW6432"
  !insertmacro TryFile "$1\Microsoft\Edge\Application\msedge.exe"
  !insertmacro TryFile "$2\Microsoft\Edge\Application\msedge.exe"
  SetRegView 64
  !insertmacro TryAppPath HKLM "chrome.exe"
  !insertmacro TryAppPath HKCU "chrome.exe"
  SetRegView 32
  !insertmacro TryAppPath HKLM "chrome.exe"
  !insertmacro TryAppPath HKCU "chrome.exe"
  !insertmacro TryFile "$2\Google\Chrome\Application\chrome.exe"
  !insertmacro TryFile "$1\Google\Chrome\Application\chrome.exe"
  !insertmacro TryFile "$LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
  SetRegView lastused

  ${WordReplace} "$INSTDIR\overtime.html" "\" "/" "+" $3
  StrCpy $AppArgs '--app="file:///$3" --window-size=1180,880'
FunctionEnd

; 바로 가기 하나 만들기: 브라우저가 있으면 앱 창, 없으면 기본 브라우저로 html 열기
!macro MakeLink LNK
  ${If} $Browser != ""
    CreateShortCut "${LNK}" "$Browser" "$AppArgs" "$INSTDIR\app.ico" 0 SW_SHOWNORMAL "" "${APPNAME}"
  ${Else}
    CreateShortCut "${LNK}" "$INSTDIR\overtime.html" "" "$INSTDIR\app.ico" 0 SW_SHOWNORMAL "" "${APPNAME}"
  ${EndIf}
!macroend

Section "프로그램 (필수)" SecMain
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "overtime.html"
  File "app.ico"
  File "/oname=사용설명서.pdf" "manual.pdf"
  Call FindBrowser

  CreateDirectory "$SMPROGRAMS\${APPNAME}"
  !insertmacro MakeLink "$SMPROGRAMS\${APPNAME}\${APPNAME}.lnk"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\사용설명서.lnk" "$INSTDIR\사용설명서.pdf"
  CreateShortCut "$SMPROGRAMS\${APPNAME}\${APPNAME} 제거.lnk" "$INSTDIR\uninstall.exe"

  WriteUninstaller "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "${UNINSTKEY}" "DisplayName" "${APPNAME}"
  WriteRegStr HKCU "${UNINSTKEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNINSTKEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "${UNINSTKEY}" "DisplayIcon" "$INSTDIR\app.ico"
  WriteRegStr HKCU "${UNINSTKEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINSTKEY}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKCU "${UNINSTKEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTKEY}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  WriteRegDWORD HKCU "${UNINSTKEY}" "EstimatedSize" "$0"
SectionEnd

Section "바탕화면 바로 가기" SecDesktop
  !insertmacro MakeLink "$DESKTOP\${APPNAME}.lnk"
SectionEnd

Section /o "Windows 시작할 때 자동 실행" SecStartup
  !insertmacro MakeLink "$SMSTARTUP\${APPNAME}.lnk"
SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecMain} "초과근무 기록장 프로그램과 사용설명서, 시작 메뉴 바로 가기"
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "바탕화면에 실행 아이콘을 만듭니다."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecStartup} "PC를 켜면 자동으로 열려, 초과근무 알림을 놓치지 않게 합니다."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Function RunApp
  ${If} $Browser != ""
    Exec '"$Browser" $AppArgs'
  ${Else}
    ExecShell "open" "$INSTDIR\overtime.html"
  ${EndIf}
FunctionEnd

Section "Uninstall"
  Delete "$DESKTOP\${APPNAME}.lnk"
  Delete "$SMSTARTUP\${APPNAME}.lnk"
  RMDir /r "$SMPROGRAMS\${APPNAME}"
  Delete "$INSTDIR\overtime.html"
  Delete "$INSTDIR\app.ico"
  Delete "$INSTDIR\사용설명서.pdf"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  DeleteRegKey HKCU "${UNINSTKEY}"
SectionEnd

Function un.onUninstSuccess
  MessageBox MB_ICONINFORMATION|MB_OK "${APPNAME}을(를) 제거했습니다.$\r$\n$\r$\n저장된 초과근무 기록은 브라우저에 남아 있어, 다시 설치하면 이어서 쓸 수 있습니다." /SD IDOK
FunctionEnd
