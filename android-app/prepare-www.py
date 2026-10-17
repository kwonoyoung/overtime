"""PC용 초과근무기록장.html → 안드로이드 앱 화면(www/index.html)으로 복사·손질합니다.

PC용 파일(../pc/초과근무기록장.html)을 고친 뒤 이 스크립트를 돌리면(또는 GitHub에 올리면 자동으로)
앱에도 똑같이 반영됩니다.
  - 인터넷 글꼴 링크 제거 (인터넷 없는 폰에서도 바로 열리게, 휴대폰 기본 글꼴 사용)
  - 앱 전용 기능(native.js) 연결
"""
import re, pathlib

here = pathlib.Path(__file__).parent
src = (here.parent / "pc" / "초과근무기록장.html").read_text(encoding="utf-8")

# 인터넷 글꼴(Pretendard, Google Fonts) 링크 빼기
src = re.sub(r'\s*<link[^>]+(pretendard|fonts\.googleapis|fonts\.gstatic)[^>]*>', "", src)
src = src.replace("<!-- 글꼴: Pretendard(본문), Poppins(숫자·영문) — 둘 다 무료(SIL OFL). 인터넷이 없으면 맑은 고딕으로 표시됩니다. -->", "")
# 앱 전용 기능 연결
assert "</body>" in src
src = src.replace("</body>", '<script src="native.js"></script>\n</body>', 1)

(here / "www" / "index.html").write_text(src, encoding="utf-8")
print("www/index.html 준비 완료 (%d bytes)" % len(src.encode("utf-8")))
