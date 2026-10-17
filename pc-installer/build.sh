#!/bin/sh
# PC 설치 파일 만들기 (리눅스·맥: apt install nsis / brew install makensis)
# 사용법: sh build.sh [버전]   예) sh build.sh 1.0.7
set -e
cd "$(dirname "$0")"
VER="${1:-1.0.6}"
cp ../pc/초과근무기록장.html overtime.html
cp ../pc/사용설명서.pdf manual.pdf
makensis -V2 -INPUTCHARSET UTF8 -DVERSION="$VER" setup.nsi
rm -f overtime.html manual.pdf
echo "완성: pc-installer/OvertimeLog-v$VER.exe"
