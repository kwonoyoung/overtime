// native.js — 안드로이드 앱에서만 쓰는 기능
//  ① 앱을 닫거나 화면이 꺼져도 근무 확인 알림이 울리도록 휴대폰 알람에 예약
//  ② 엑셀·CSV·백업 파일을 휴대폰에 저장하거나 카톡·메일 등으로 보내기
//  ③ 휴대폰 [뒤로] 버튼 처리
// 화면과 계산은 PC용과 똑같은 index.html 을 그대로 씁니다.
(function () {
  const Cap = window.Capacitor;
  if (!Cap || !Cap.isNativePlatform || !Cap.isNativePlatform()) return; // 브라우저에서 열면 아무것도 안 함
  const { LocalNotifications: LN, Filesystem, Share, App } = Cap.Plugins;

  // ── 문구를 휴대폰에 맞게 ──
  document.querySelectorAll("footer, .hint, #notiState").forEach((el) => {
    el.innerHTML = el.innerHTML.replace(/이 PC/g, "이 휴대폰").replace(/윈도우 알림/g, "알림");
  });
  const allowBtn = document.getElementById("allowNoti");
  if (allowBtn) allowBtn.textContent = "알림 권한 확인";

  // ── 알림 채널 (안드로이드는 '채널'마다 소리·진동이 정해짐) ──
  const TONE_NAMES = Object.fromEntries(Object.entries(TONES).map(([k, t]) => [k, t.name]));
  const MODE_NAMES = { both: "소리+진동", sound: "소리", vibrate: "진동", silent: "무음" };
  const made = new Set();
  async function channelFor(s) {
    const mode = s.alertMode || "both", tone = s.soundType || "bell";
    let ch;
    if (mode === "vibrate") ch = { id: "ot_vibrate", sound: "tone_silence.wav", vibration: true };
    else if (mode === "silent") ch = { id: "ot_silent", sound: "tone_silence.wav", vibration: false };
    else if (tone === "custom") ch = { id: "ot_custom_" + mode, vibration: mode === "both" }; // 내 소리 파일은 휴대폰 기본 알림음으로
    else ch = { id: `ot_${tone}_${mode}`, sound: `tone_${tone}.wav`, vibration: mode === "both" };
    if (!made.has(ch.id)) {
      const toneName = mode === "vibrate" || mode === "silent" ? "" : (tone === "custom" ? "기본 알림음" : TONE_NAMES[tone]) + " · ";
      await LN.createChannel({ ...ch, name: `근무 확인 알림 (${toneName}${MODE_NAMES[mode]})`,
        description: "초과근무 중 정해진 시각에 근무 상황을 확인하라고 알려 줍니다.", importance: 5, visibility: 1, lights: true, lightColor: "#E8622A" });
      made.add(ch.id);
    }
    return ch.id;
  }

  // ── 휴대폰 알람 예약 / 취소 ──
  async function cancelAll() {
    try {
      const { notifications } = await LN.getPending();
      if (notifications.length) await LN.cancel({ notifications: notifications.map((n) => ({ id: n.id })) });
    } catch (e) {}
  }
  async function scheduleAll() {
    await cancelAll();
    const key = runningKey(), s = state.settings;
    if (!key || !s.alarmOn) return;
    const r = runningSess(state.days[key]), now = Date.now(), list = [];
    const channelId = await channelFor(s);
    for (let k = Math.max(1, (r.ackHour || 0) + 1); list.length < 300; k++) {
      const p = alarmPoint(k);
      if (r.start + p * 60000 > now + 16 * 3600000) break; // 16시간 앞까지만 예약
      for (let rep = 0; rep <= s.alarmRepeat; rep++) {
        const at = r.start + (p + rep) * 60000;
        if (at <= now + 2000) continue;
        list.push({
          id: k * 100 + rep,
          title: "초과근무 확인 시간입니다",
          body: `초과근무 시작(${hm(r.start)}) 후 ${fmt(p + rep)} 지났습니다. 눌러서 확인해 주세요.`,
          schedule: { at: new Date(at), allowWhileIdle: true },
          channelId, smallIcon: "ic_stat_overtime", iconColor: "#E8622A", autoCancel: true, extra: { k },
        });
      }
    }
    if (list.length) await LN.schedule({ notifications: list });
  }

  // 앱이 화면에 있을 때는 화면 안 알림창이 담당 → 예약 취소
  // 앱을 내리거나 화면이 꺼지면 → 휴대폰 알람에 예약
  App.addListener("appStateChange", async ({ isActive }) => {
    if (isActive) {
      state = load();
      await cancelAll();
      try { await LN.removeAllDeliveredNotifications(); } catch (e) {}
      renderTodayForm(); checkAlarm();
    } else {
      await scheduleAll();
    }
  });
  // 알림을 눌러 앱을 열면 오늘 화면으로
  LN.addListener("localNotificationActionPerformed", () => {
    document.querySelector('.tabs button[data-tab="today"]').click();
    setTimeout(checkAlarm, 300);
  });

  // ── 권한 (알림 표시 · 정확한 시각 알람) ──
  async function ensurePermissions(ask) {
    try {
      let p = await LN.checkPermissions();
      if (p.display !== "granted" && (ask || p.display === "prompt")) p = await LN.requestPermissions();
      const ex = await LN.checkExactNotificationSetting().catch(() => ({ exact_alarm: "granted" }));
      const okExact = (ex.exact_alarm || ex.value || "granted") === "granted";
      const st = document.getElementById("notiState");
      if (st) st.textContent = p.display === "granted"
        ? (okExact ? "알림 권한: 허용됨 ✔ (앱을 닫아도 정해진 시각에 울립니다)" : "알림은 허용됨. '정확한 알람' 권한이 꺼져 있어 몇 분 늦게 울릴 수 있습니다.")
        : "알림 권한이 꺼져 있습니다. [알림 권한 확인]을 눌러 허용해 주세요.";
      if (ask && p.display === "granted" && !okExact) await LN.changeExactNotificationSetting();
      if (ask && p.display !== "granted") notice("휴대폰 설정 → 애플리케이션 → 초과근무 기록장 → 알림에서 허용해 주세요.");
    } catch (e) {}
  }
  if (allowBtn) allowBtn.onclick = () => ensurePermissions(true);
  const _renderSettings = renderSettings;
  renderSettings = function () { _renderSettings(); ensurePermissions(false); };
  ensurePermissions(false);

  // 화면 안 알림: 앱이 열려 있을 때만 쓰이므로 그대로 둠 (소리·진동은 설정 따라)

  // ── 파일 저장 (엑셀·CSV·백업) → 휴대폰 공유 창 ──
  const _click = HTMLAnchorElement.prototype.click;
  HTMLAnchorElement.prototype.click = function () {
    if (!(this.download && this.href.startsWith("blob:"))) return _click.call(this);
    const name = this.download, href = this.href;
    (async () => {
      try {
        const blob = await (await fetch(href)).blob();
        const data = await new Promise((res) => { const fr = new FileReader(); fr.onload = () => res(String(fr.result).split(",")[1]); fr.readAsDataURL(blob); });
        const { uri } = await Filesystem.writeFile({ path: name, data, directory: "CACHE" });
        await Share.share({ title: name, files: [uri], dialogTitle: `${name} 저장·보내기` });
      } catch (e) {
        if (!/cancel/i.test(String(e && e.message))) notice("파일을 저장하지 못했습니다.\n" + (e && e.message ? e.message : ""));
      }
    })();
  };

  // ── [뒤로] 버튼 ──
  App.addListener("backButton", () => {
    const ask = document.getElementById("askDlg"), edit = document.getElementById("editDlg");
    if (document.getElementById("alarmDlg").open) return;          // 근무 확인 알림은 [확인]으로만 닫기
    if (ask.open) return document.getElementById(document.getElementById("askNo").hidden ? "askYes" : "askNo").click();
    if (edit.open) return edit.close();
    const on = document.querySelector(".tabs button.on");
    if (on && on.dataset.tab !== "today") return document.querySelector('.tabs button[data-tab="today"]').click();
    App.minimizeApp();
  });
})();
