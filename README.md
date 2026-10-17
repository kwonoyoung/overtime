# 초과근무 기록장 (웹앱)

## 폴더 구성
- index.html — 앱 화면과 기능 전부
- manifest.webmanifest — 앱 이름·아이콘 정보 (홈 화면 설치용)
- sw.js — 인터넷 없이도 열리게 해 주는 파일
- icons/ — 앱 아이콘

## GitHub Pages에 올리기
1. github.com 로그인 → 오른쪽 위 + → New repository
2. 이름 예: overtime → Public 선택 → Create repository
3. "uploading an existing file" 클릭 → 이 폴더 안의 파일과 icons 폴더를 모두 끌어다 놓기 → Commit changes
4. Settings → Pages → Branch: main, 폴더: / (root) → Save
5. 1~2분 뒤 https://(아이디).github.io/overtime/ 주소로 열립니다.

## 폰에 설치
- 안드로이드(크롬): 주소 열기 → 설정 탭 [홈 화면에 설치] 또는 ⋮ 메뉴 → 홈 화면에 추가
- 아이폰(Safari): 주소 열기 → 공유 버튼(□↑) → 홈 화면에 추가

## 고친 뒤 다시 올릴 때
- sw.js 맨 위 VERSION 숫자를 올리고(v1 → v2) 파일을 다시 올리면, 폰 앱도 다음 실행 때 새 버전으로 바뀝니다.

## 주의
- 기록은 기기마다 따로 저장됩니다(PC 기록 ≠ 폰 기록). 옮길 때는 설정 → 백업 파일 저장/불러오기.
- 알림은 앱이 열려 있을 때 울립니다. 앱을 완전히 닫으면 울리지 않습니다.
