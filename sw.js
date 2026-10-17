// sw.js — 서비스 워커: 인터넷이 없어도 앱이 열리게 파일을 폰에 저장(캐시)해 둡니다.
// 앱을 고쳐서 다시 올릴 때는 아래 VERSION 숫자를 하나 올려 주세요. (예: v2 → v3)
const VERSION = "v11";
const CACHE = "overtime-" + VERSION;
const FILES = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/maskable-512.png",
  "./icons/apple-touch-icon.png",
  "./icons/favicon-32.png",
  "./img/hero.webp",
];

// 설치될 때: 앱 파일을 미리 저장
self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(FILES)).then(() => self.skipWaiting()));
});

// 새 버전이 켜질 때: 예전 저장본 지우기
self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// 파일 요청 처리
//  - 화면(html): 인터넷이 되면 새 버전을 받고, 안 되면 저장본 사용
//  - 그 밖(아이콘·글꼴): 저장본이 있으면 바로 사용, 없으면 받아서 저장
self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  if (req.mode === "navigate") {
    e.respondWith(
      fetch(req)
        .then((res) => { const copy = res.clone(); caches.open(CACHE).then((c) => c.put("./index.html", copy)); return res; })
        .catch(() => caches.match("./index.html"))
    );
    return;
  }
  e.respondWith(
    caches.match(req).then((hit) => hit || fetch(req).then((res) => {
      if (res.ok || res.type === "opaque") { const copy = res.clone(); caches.open(CACHE).then((c) => c.put(req, copy)); }
      return res;
    }))
  );
});

// 알림을 누르면 앱 화면으로 이동
self.addEventListener("notificationclick", (e) => {
  e.notification.close();
  e.waitUntil(
    self.clients.matchAll({ type: "window", includeUncontrolled: true }).then((list) => {
      for (const c of list) if ("focus" in c) return c.focus();
      return self.clients.openWindow("./");
    })
  );
});
