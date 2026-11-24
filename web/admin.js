import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.2/firebase-app.js";
import {
  getAuth,
  GoogleAuthProvider,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signInWithPopup,
  signOut,
} from "https://www.gstatic.com/firebasejs/11.0.2/firebase-auth.js";

// Firebase Web Auth config for Omakase project (public client identifiers)
const FIREBASE_CONFIG = {
  apiKey: [
    "AIzaSyBr65-gxqDg",
    "CbFyJvVrSILPbEn7kixsyHU",
  ].join(""),
  authDomain: "gen-lang-client-0120875563.firebaseapp.com",
  projectId: "gen-lang-client-0120875563",
};

const PROD_API_BASE = "https://omakase-backend-20235796246.us-central1.run.app";

// ============================================================================
// METRIC GLOSSARY — Every metric self-explains in plain Turkish
// ============================================================================

const METRIC_GLOSSARY = {
  total_users: {
    title: "Toplam Kayıtlı Kullanıcı",
    short: "Bugüne kadar hesap oluşturan toplam kişi sayısı ve bugün yeni katılanlar.",
    why: "Lansman günü organik/paid trafiğin kaç kullanıcıya dönüştüğünü en net gösteren sayaçtır.",
    target: "İlk 48 saatte gelen trafik ile kayıt oranı düşükse Auth/Onboarding ekranlarını sadeleştir.",
  },
  dau_wau: {
    title: "DAU / WAU & Stickiness",
    short: "DAU bugün aktif olan tekil kişi, WAU son 7 gün aktifi; Stickiness ise geri gelme sıklığıdır (DAU/WAU).",
    why: "İnsanlar sadece indirip gidiyor mu yoksa günlük alışkanlık kuruyor mu onu ölçer.",
    target: "Günlük kültür/okuma uygulamasında sağlıklı Stickiness hedefi %20–35 arasıdır.",
  },
  plates: {
    title: "Üretilen Tabaklar (Plates)",
    short: "Şefin kullanıcılar için canlı yazdığı 60 kelimelik kültür postlarının toplam sayısı.",
    why: "Uygulamanın çekirdek değer önermesinin (core value) tüketilme hacmini gösterir.",
    target: "Kullanıcı başına günde ortalama 2.5+ tabak görüyorsan içerik kalitesi tutmuş demektir.",
  },
  deep_dives: {
    title: "Derin İnceleme (Deep Dive)",
    short: "Bir postu beğenip 'daha derine in' butonuna basanların açtığı uzun analiz sayısı.",
    why: "Ücretsiz kullanıcıya günde 1 tane verildiği için Pro aboneliklerin en güçlü tetikleyicisidir.",
    target: "Tabak başına %15+ Derin İnceleme açılması içeriğin merak uyandırdığını kanıtlar.",
  },
  pro_trials: {
    title: "Aktif Pro & Deneme (Trial)",
    short: "Şu anda ücretli Pro aboneliği veya 7 günlük ücretsiz denemesi aktif olan kullanıcı sayısı.",
    why: "Ürünün sadece beğenilmediğini, insanların kartını bağlayacak kadar değer bulduğunu gösterir.",
    target: "Paywall görenlerin %4–8'inin Trial başlatması sağlıklı erken aşama hedefidir.",
  },
  mrr_revenue: {
    title: "MRR & 28 Günlük Gelir",
    short: "MRR aylık tekrarlayan abonelik geliridir (yıllık plan/12 + aylık). RevenueCat'ten veya Firestore'dan beslenir.",
    why: "Büyümenin finansal sürdürülebilirliğini ve API maliyetini ne kadar rahat karşıladığını gösterir.",
    target: "RevenueCat v2 API anahtarı eklendiğinde Apple Store kesintileri ve net gelir canlı senkronlanır.",
  },
  ai_cost: {
    title: "Gemini AI Maliyeti & Tabak Başı Birim Maliyet",
    short: "Gemini Flash / Flash-Lite modellerine ödenen tahmini API token maliyeti ve tek tabak maliyeti.",
    why: "Ücretsiz kullanıcıların bütçeni yakıp yakmadığını ve Pro fiyatının karlılığını ölçer.",
    target: "Tabak başı ~$0.00025 civarıdır; Pro brüt marjı %90+ kalmalıdır.",
  },
  health: {
    title: "Sistem Sağlığı & Başarı Oranı",
    short: "İçerik üretim isteklerinin hatasız tamamlanma yüzdesi ve dönem içi API/safety hata sayısı.",
    why: "Lansmanda ilk 30 saniyede hata gören kullanıcı uygulamayı siler.",
    target: "Başarı oranı %98+ olmalı. %95 altına düşerse Hata Triyajı preset'i ile Agent'a aktar.",
  },
  source_tap_rate: {
    title: "Birincil Kaynakça Tıklama Oranı",
    short: "Üretilen tabakların yüzde kaçında kullanıcının alttaki kaynak kapsülüne dokunduğu.",
    why: "'Wikipedia yok, birincil kaynak var' vaadine kullanıcıların gerçekten güvenip merak ettiğini ölçer.",
    target: "%10+ çok güçlüdür; düşükse PostSourceView kapsülünü daha görünür yapabilirsin.",
  },
  cooldown_rate: {
    title: "Okuma Tamamlama (Cooldown)",
    short: "15–25 saniyelik sindirme sayacını sonuna kadar bekleyip okuyanların tabaklara oranı.",
    why: "Doomscrolling karşıtı ritüelimizin kullanıcıyı sıkıp sıkmadığını ya da okuttuğunu gösterir.",
    target: "%65+ iyidir; %40 altındaysa sindirme süresi fazla uzun geliyor olabilir.",
  },
  share_rate: {
    title: "Kart Paylaşım Oranı",
    short: "Instagram/iMessage için #F5F0E8 paylaşım kartını dışa aktaranların oranı.",
    why: "Sıfır reklam bütçesiyle yeni kullanıcı getiren organik büyüme (K-factor) sinyalidir.",
    target: "Paylaşımla +1 Deep Dive bonusu bu oranı %3–6 bandında tutmaya yardım eder.",
  },
  stickiness: {
    title: "Stickiness (DAU / WAU)",
    short: "Haftalık aktif kullanıcıların yüzde kaçının bugün de uygulamayı açtığı.",
    why: "Bildirimlerin ve günlük 3 tabak ritüelinin alışkanlık oluşturup oluşturmadığını gösterir.",
    target: "%25+ günlük alışkanlık ürünü için harikadır.",
  },
};

const ENGAGEMENT_META = [
  {
    key: "source_tap_rate_pct",
    countKey: "source_tapped",
    label: "Kaynakça Tıklama Oranı",
    explain: "Tabak altındaki birincil kaynak kapsülüne dokunma oranı.",
  },
  {
    key: "cooldown_completion_rate_pct",
    countKey: "cooldown_completed",
    label: "Okuma Tamamlama (Cooldown)",
    explain: "15–25 sn sindirme süresini sonuna kadar okuma oranı.",
  },
  {
    key: "deep_dive_rate_pct",
    countKey: null,
    label: "Derin İnceleme Açma Oranı",
    explain: "Üretilen tabaklardan kaçının Derin İnceleme'ye dönüştüğü.",
  },
  {
    key: "share_rate_pct",
    countKey: "share_card_shared",
    label: "Paylaşım Kartı Oranı",
    explain: "Görsel kart dışa aktarıp +1 bonus tetikleme oranı.",
  },
  {
    key: "paywall_to_pro_pct",
    countKey: "paywall_viewed",
    label: "Paywall → Trial/Pro",
    explain: "Paywall'u görenlerden deneme/Pro başlatanların oranı.",
  },
];

const FUNNEL_EXPLAINS = {
  signup: "Hesap oluşturan yeni kullanıcı sayısı.",
  onboarding_completed: "3 slaytlık girişi tamamlayıp akışa girenler.",
  plates_generated: "En az bir yapay zeka tabağı üretilmesi.",
  cooldown_completed: "15–25 sn okuma süresini tamamlayan gerçek okumalar.",
  daily_limit_reached: "Günde 3 ücretsiz tabağı bitirip limit kartını görenler (en sıcak adaylar).",
  paywall_viewed: "Pro yükseltme ekranını açanlar.",
  trial_or_pro: "Aktif 7 günlük deneme veya ücretli Pro aboneliğe geçenler.",
};

// ============================================================================
// DEMO DATA (Used only when user explicitly clicks "Demo Veriyle Paneli İncele")
// ============================================================================

function buildDemoOverview(days) {
  const series = [];
  const now = new Date();
  for (let i = days - 1; i >= 0; i--) {
    const d = new Date(now.getTime() - i * 86400000);
    const iso = d.toISOString().slice(0, 10);
    const wave = Math.sin((days - i) * 0.7) * 0.25 + 1;
    const dau = Math.round(14 + (days - i) * 1.4 * wave);
    const plates = Math.round(dau * 2.8);
    const dd = Math.round(plates * 0.22);
    const errs = i === 2 ? 2 : i === 0 ? 1 : 0;
    series.push({
      date: iso,
      dau,
      new_users: Math.max(1, Math.round(dau * 0.35)),
      plates,
      deep_dives: dd,
      errors: errs,
      ai_cost_usd: Number(((plates * 0.00024) + (dd * 0.00042)).toFixed(4)),
      paywall_views: Math.round(dau * 0.42),
      trials_started: i % 2 === 0 ? 1 : 0,
    });
  }
  const sum = (k) => series.reduce((acc, r) => acc + Number(r[k] || 0), 0);
  const platesPeriod = sum("plates");
  const ddPeriod = sum("deep_dives");
  const last = series[series.length - 1];

  return {
    generated_at: new Date().toISOString(),
    period_days: days,
    connections: {
      firestore: true,
      gemini_model: "gemini-3.5-flash",
      gemini_deep_dive_model: "gemini-3.5-flash",
      gemini_suggest_model: "gemini-3.1-flash-lite",
      revenuecat: {
        connected: false,
        mode: "firestore_fallback",
        project_id: "projfdc295f4",
        reason: "Demo modu: Örnek veriler gösteriliyor.",
        metrics: {},
      },
    },
    kpis: {
      total_users: 84,
      new_users_today: last.new_users,
      new_users_period: sum("new_users"),
      dau_today: last.dau,
      wau_7d: 52,
      stickiness_pct: Number(((last.dau / 52) * 100).toFixed(1)),
      plates_today: last.plates,
      plates_period: platesPeriod,
      letterboxd_plates_period: Math.round(platesPeriod * 0.19),
      deep_dives_today: last.deep_dives,
      deep_dives_period: ddPeriod,
      suggestions_period: Math.round(platesPeriod * 0.34),
      category_expansions_period: 48,
      active_pro: 4,
      active_trials: 7,
      billing_issues: 0,
      expired_pro: 1,
      free_users: 73,
      yearly_subs: 3,
      monthly_subs: 1,
      mrr_usd: 11.49,
      revenue_28d_usd: 93.96,
      revenue_source: "firestore_estimated",
      api_errors_period: sum("errors"),
      safety_blocks_period: 1,
      rate_limits_period: 0,
      quota_blocks_period: 6,
      generation_success_rate_pct: 99.3,
      shared_posts_total: 29,
      open_feedback_count: 2,
      open_reports_count: 1,
      share_bonuses_period: 11,
    },
    ai_economics: {
      input_tokens: platesPeriod * 520 + ddPeriod * 710,
      output_tokens: platesPeriod * 155 + ddPeriod * 420,
      estimated_cost_usd: Number(sum("ai_cost_usd").toFixed(4)),
      cost_per_plate_usd: 0.00026,
      avg_monthly_cost_free_user_usd: 0.0234,
      avg_monthly_cost_pro_user_usd: 0.1404,
      pro_gross_margin_pct: 94.4,
    },
    engagement: {
      app_opens: sum("dau") * 2,
      onboarding_completed: Math.round(sum("new_users") * 0.84),
      onboarding_skipped: 4,
      cooldown_completed: Math.round(platesPeriod * 0.71),
      cooldown_completion_rate_pct: 71.0,
      source_tapped: Math.round(platesPeriod * 0.14),
      source_opened_browser: Math.round(platesPeriod * 0.06),
      source_tap_rate_pct: 14.0,
      share_card_shared: 17,
      share_rate_pct: Number(((17 / Math.max(1, platesPeriod)) * 100).toFixed(1)),
      post_bookmarked: Math.round(platesPeriod * 0.18),
      deep_dive_rate_pct: Number(((ddPeriod / Math.max(1, platesPeriod)) * 100).toFixed(1)),
      daily_limit_reached: Math.round(sum("dau") * 0.45),
      paywall_viewed: sum("paywall_views"),
      paywall_to_pro_pct: Number(((11 / Math.max(1, sum("paywall_views"))) * 100).toFixed(1)),
    },
    funnel: [
      { id: "signup", label: "Yeni Kayıt", count: sum("new_users"), conversion_from_prev_pct: 100, conversion_from_top_pct: 100 },
      { id: "onboarding_completed", label: "Onboarding Tamamlandı", count: Math.round(sum("new_users") * 0.84), conversion_from_prev_pct: 84.0, conversion_from_top_pct: 84.0 },
      { id: "plates_generated", label: "Tabak Üretildi", count: platesPeriod, conversion_from_prev_pct: 100, conversion_from_top_pct: 100 },
      { id: "cooldown_completed", label: "Okuma Tamamlandı (Cooldown)", count: Math.round(platesPeriod * 0.71), conversion_from_prev_pct: 71.0, conversion_from_top_pct: 71.0 },
      { id: "daily_limit_reached", label: "3/3 Günlük Limite Ulaştı", count: Math.round(sum("dau") * 0.45), conversion_from_prev_pct: 36.2, conversion_from_top_pct: 25.0 },
      { id: "paywall_viewed", label: "Paywall Görüntülendi", count: sum("paywall_views"), conversion_from_prev_pct: 91.0, conversion_from_top_pct: 22.8 },
      { id: "trial_or_pro", label: "Trial / Pro Dönüşümü", count: 11, conversion_from_prev_pct: 11.4, conversion_from_top_pct: 11.4 },
    ],
    daily_series: series,
    languages: { tr: 162, en: 128, ja: 34, de: 19, fr: 14, es: 12, ko: 9 },
    top_topics: [
      { topic: "cinema_noir", count: 44 },
      { topic: "ramen_craft", count: 31 },
      { topic: "letterboxd", count: 29 },
      { topic: "brutalist_architecture", count: 24 },
      { topic: "jazz_tokyo", count: 19 },
      { topic: "stoic_ethics", count: 16 },
    ],
    paywall_sources: { plateLimit: 48, firstPlateSoft: 27, deepDiveLimit: 18, profile: 9 },
    error_codes: { content_blocked: 1, generation_failed: 2 },
    insights: [
      {
        severity: "warn",
        title: "2 yeni kullanıcı geri bildirimi bekliyor",
        detail: "İlk gün kullanıcıları Letterboxd senkronizasyonu ve koyu tema hakkında not bırakmış.",
        action: "Geri Bildirim sekmesinden detayları oku.",
      },
      {
        severity: "good",
        title: "Birincil kaynakça etkileşimi güçlü (%14.0)",
        detail: "Okuyucular PostSourceView kapsülüne tıklayıp kaynakları kontrol ediyor.",
        action: "Bu davranışı mağaza görsellerinde vurgulamaya devam et.",
      },
      {
        severity: "good",
        title: "AI birim ekonomisi sağlıklı (Pro brüt marj ~%94.4)",
        detail: "Tabak başı tahmini Gemini maliyeti $0.00026.",
        action: "Mevcut kotalar sürdürülebilir.",
      },
    ],
  };
}

const DEMO_FEEDBACK = [
  {
    id: "demo-fb-1",
    uid: "u1",
    displayName: "Deniz Kaya",
    username: "denizk",
    isPro: true,
    subscriptionStatus: "trial",
    category: "idea",
    rating: 5,
    message: "15 saniyelik okuma barı fikrine bayıldım. Kaydettiğimiz postları klasörlere göre PDF/Markdown dışa aktarabilsek harika olur!",
    appVersion: "1.0 (14)",
    osVersion: "iOS 18.2",
    deviceModel: "iPhone",
    language: "tr",
    status: "new",
    adminNote: "",
    createdAt: new Date(Date.now() - 3600000).toISOString(),
  },
  {
    id: "demo-fb-2",
    uid: "u2",
    displayName: "Mert Arslan",
    username: "mertfilm",
    isPro: false,
    subscriptionStatus: "free",
    category: "bug",
    rating: 4,
    message: "Letterboxd kullanıcı adımı ilk girdiğimde son izlediğim film hemen gelmedi, ekranı yenileyince düzeldi.",
    appVersion: "1.0 (14)",
    osVersion: "iOS 18.1",
    deviceModel: "iPhone",
    language: "tr",
    status: "new",
    adminNote: "",
    createdAt: new Date(Date.now() - 9200000).toISOString(),
  },
];

const DEMO_REPORTS = [
  {
    id: "demo-rep-1",
    targetType: "post",
    postId: "p-123",
    reason: "Spam / tekrar içerik",
    status: "open",
    createdAt: new Date(Date.now() - 5400000).toISOString(),
    postPreview: {
      title: "Test Başlık",
      text: "Topluluk akışında deneme amaçlı paylaşılan tekrar metin örneği.",
      authorName: "Test Kullanıcısı",
      authorUsername: "testuser",
    },
  },
];

const DEMO_USERS = [
  { uid: "Kp6J1wDQd5huj8FRrp3Vb3EuJ333", displayName: "Kuzey", username: "kuzey", isPro: true, subscriptionStatus: "active", platesToday: 6, interestsCount: 14, createdAt: new Date().toISOString() },
  { uid: "u1", displayName: "Deniz Kaya", username: "denizk", isPro: true, subscriptionStatus: "trial", platesToday: 9, interestsCount: 8, createdAt: new Date(Date.now() - 3600000).toISOString() },
  { uid: "u2", displayName: "Mert Arslan", username: "mertfilm", isPro: false, subscriptionStatus: "free", platesToday: 3, interestsCount: 5, createdAt: new Date(Date.now() - 10800000).toISOString() },
];

// ============================================================================
// APP STATE
// ============================================================================

const state = {
  demoMode: false,
  apiBase: localStorage.getItem("omakase.admin.apiBase") || PROD_API_BASE,
  days: 7,
  activeTab: "overview",
  chartSeries: "plates",
  exportPreset: "launch",
  user: null,
  idToken: null,
  overview: null,
  feedback: [],
  reports: [],
  users: [],
  autoRefreshTimer: null,
  openHelpCards: new Set(),
};

// Initialize Firebase Auth
const fbApp = initializeApp(FIREBASE_CONFIG);
const fbAuth = getAuth(fbApp);

// ============================================================================
// HELPERS
// ============================================================================

function $(id) {
  return document.getElementById(id);
}

function escapeHtml(str) {
  return String(str ?? "")
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");
}

function showToast(msg) {
  const el = $("toast");
  if (!el) return;
  el.textContent = msg;
  el.classList.remove("hidden");
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => el.classList.add("hidden"), 2600);
}

function formatNumber(n) {
  return Number(n || 0).toLocaleString("tr-TR");
}

function formatRelative(iso) {
  if (!iso) return "-";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return String(iso);
  const diffMin = Math.round((Date.now() - d.getTime()) / 60000);
  if (diffMin < 1) return "Az önce";
  if (diffMin < 60) return `${diffMin} dk önce`;
  const diffH = Math.round(diffMin / 60);
  if (diffH < 24) return `${diffH} sa önce`;
  return d.toLocaleDateString("tr-TR", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" });
}

function applyTheme(theme) {
  document.documentElement.setAttribute("data-theme", theme);
  localStorage.setItem("omakase.admin.theme", theme);
  const meta = $("theme-color-meta");
  if (meta) meta.content = theme === "dark" ? "#000000" : "#FAFAFA";
}

async function apiFetch(path, options = {}) {
  if (!state.user) throw new Error("Oturum bulunamadı.");
  const token = await state.user.getIdToken();
  state.idToken = token;
  const resp = await fetch(`${state.apiBase}${path}`, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...(options.headers || {}),
    },
  });
  const ct = resp.headers.get("content-type") || "";
  const body = ct.includes("application/json") ? await resp.json() : await resp.text();
  if (!resp.ok) {
    const detail = (body && typeof body === "object" && body.detail) ? body.detail : `HTTP ${resp.status}`;
    const err = new Error(detail);
    err.status = resp.status;
    throw err;
  }
  return body;
}

// ============================================================================
// AUTH FLOW
// ============================================================================

function showAuthGate(errorMsg = "") {
  $("auth-gate").classList.remove("hidden");
  $("dashboard-shell").classList.add("hidden");
  const banner = $("auth-error-banner");
  if (errorMsg) {
    banner.textContent = errorMsg;
    banner.classList.remove("hidden");
  } else {
    banner.classList.add("hidden");
  }
}

function showDashboard() {
  $("auth-gate").classList.add("hidden");
  $("dashboard-shell").classList.remove("hidden");
  $("demo-banner").classList.toggle("hidden", !state.demoMode);
}

onAuthStateChanged(fbAuth, async (user) => {
  if (state.demoMode) return;
  if (!user) {
    state.user = null;
    showAuthGate();
    return;
  }
  state.user = user;
  try {
    await apiFetch("/admin/me");
    showDashboard();
    await loadAllData();
  } catch (err) {
    if (err.status === 403) {
      await signOut(fbAuth);
      showAuthGate(`Bu hesap (${user.email || user.uid}) ADMIN_UIDS yetkisine sahip değil.`);
    } else {
      showAuthGate(`Backend doğrulama hatası (${state.apiBase}): ${err.message}`);
    }
  }
});

$("google-signin-btn").addEventListener("click", async () => {
  try {
    $("auth-error-banner").classList.add("hidden");
    const provider = new GoogleAuthProvider();
    await signInWithPopup(fbAuth, provider);
  } catch (err) {
    showAuthGate(`Google girişi tamamlanamadı: ${err.message}`);
  }
});

$("email-signin-form").addEventListener("submit", async (e) => {
  e.preventDefault();
  try {
    $("auth-error-banner").classList.add("hidden");
    await signInWithEmailAndPassword(fbAuth, $("email-input").value.trim(), $("password-input").value);
  } catch (err) {
    showAuthGate(`Giriş başarısız: ${err.message}`);
  }
});

$("signout-btn").addEventListener("click", async () => {
  state.demoMode = false;
  clearInterval(state.autoRefreshTimer);
  await signOut(fbAuth);
  showAuthGate();
});

$("demo-mode-btn").addEventListener("click", () => {
  state.demoMode = true;
  showDashboard();
  loadAllData();
});

$("exit-demo-btn").addEventListener("click", () => {
  state.demoMode = false;
  showAuthGate();
});

$("api-base-select").value = state.apiBase;
$("api-base-select").addEventListener("change", (e) => {
  state.apiBase = e.target.value;
  localStorage.setItem("omakase.admin.apiBase", state.apiBase);
  showToast(`API adresi: ${state.apiBase}`);
});

// ============================================================================
// DATA LOADING
// ============================================================================

async function loadAllData() {
  if (state.demoMode) {
    state.overview = buildDemoOverview(state.days);
    state.feedback = [...DEMO_FEEDBACK];
    state.reports = [...DEMO_REPORTS];
    state.users = [...DEMO_USERS];
    renderAll();
    return;
  }

  try {
    const [overview, fbRes, repRes, usrRes] = await Promise.all([
      apiFetch(`/admin/overview?days=${state.days}`),
      apiFetch(`/admin/feedback?status=${encodeURIComponent($("feedback-status-filter").value)}&limit=80`),
      apiFetch(`/admin/reports?status=${encodeURIComponent($("reports-status-filter").value)}&limit=60`),
      apiFetch(`/admin/users?limit=60&search=${encodeURIComponent($("users-search").value.trim())}`),
    ]);
    state.overview = overview;
    state.feedback = fbRes.items || [];
    state.reports = repRes.items || [];
    state.users = usrRes.items || [];
    renderAll();
  } catch (err) {
    showToast(`Veri yenileme hatası: ${err.message}`);
  }
}

async function refreshFeedbackOnly() {
  if (state.demoMode) {
    renderFeedback();
    return;
  }
  const res = await apiFetch(`/admin/feedback?status=${encodeURIComponent($("feedback-status-filter").value)}&limit=80`);
  state.feedback = res.items || [];
  renderFeedback();
}

async function refreshReportsOnly() {
  if (state.demoMode) {
    renderReports();
    return;
  }
  const res = await apiFetch(`/admin/reports?status=${encodeURIComponent($("reports-status-filter").value)}&limit=60`);
  state.reports = res.items || [];
  renderReports();
}

async function refreshUsersOnly() {
  if (state.demoMode) {
    renderUsers();
    return;
  }
  const res = await apiFetch(`/admin/users?limit=60&search=${encodeURIComponent($("users-search").value.trim())}`);
  state.users = res.items || [];
  renderUsers();
}

// ============================================================================
// RENDERING
// ============================================================================

function renderAll() {
  if (!state.overview) return;
  renderConnectionPills();
  renderBadges();
  renderInsights();
  renderKpis();
  renderTrendChart();
  renderFunnel();
  renderEngagement();
  renderLanguages();
  renderTopicsAndPaywall();
  renderRevenueAndAI();
  renderFeedback();
  renderReports();
  renderUsers();
  $("last-updated-label").textContent = `Güncellendi: ${new Date(state.overview.generated_at).toLocaleTimeString("tr-TR")}`;
}

function renderConnectionPills() {
  const c = state.overview.connections;
  const rc = c.revenuecat || {};
  const rcLabel = rc.connected ? "RevenueCat: Canlı v2" : "RevenueCat: Firestore Yedek";
  const rcDot = rc.connected ? "dot-good" : "dot-warn";
  const fsDot = c.firestore ? "dot-good" : "dot-danger";
  $("connection-pills").innerHTML = `
    <span class="status-chip"><span class="dot dot-good"></span> Cloud Run API</span>
    <span class="status-chip"><span class="dot ${fsDot}"></span> Firestore ${c.firestore ? "Bağlı" : "Yok"}</span>
    <span class="status-chip" title="${escapeHtml(rc.reason || "RevenueCat v2 bağlı")}"><span class="dot ${rcDot}"></span> ${rcLabel}</span>
    <span class="status-chip"><span class="dot dot-good"></span> Model: <code>${escapeHtml(c.gemini_model)}</code></span>
  `;
}

function renderBadges() {
  const k = state.overview.kpis;
  const fbCount = k.open_feedback_count || 0;
  const repCount = k.open_reports_count || 0;

  $("badge-feedback-desktop").textContent = fbCount;
  $("badge-feedback-desktop").classList.toggle("hidden", fbCount === 0);
  $("badge-feedback-mobile").classList.toggle("hidden", fbCount === 0);

  $("badge-reports-desktop").textContent = repCount;
  $("badge-reports-desktop").classList.toggle("hidden", repCount === 0);
  $("badge-reports-mobile").classList.toggle("hidden", repCount === 0);
}

function renderInsights() {
  const list = state.overview.insights || [];
  $("insights-container").innerHTML = list
    .map(
      (ins) => `
    <article class="insight-card sev-${escapeHtml(ins.severity)}">
      <div class="insight-title">${escapeHtml(ins.title)}</div>
      <p class="insight-detail">${escapeHtml(ins.detail)}</p>
      <div class="insight-action">→ ${escapeHtml(ins.action)}</div>
    </article>`
    )
    .join("");
}

function kpiCardHtml(id, valueText, deltaText) {
  const g = METRIC_GLOSSARY[id];
  const isOpen = state.openHelpCards.has(id);
  return `
    <article class="kpi-card">
      <div class="kpi-top">
        <span class="kpi-label">${escapeHtml(g.title)}</span>
        <button class="help-btn ${isOpen ? "open" : ""}" data-help-id="${escapeHtml(id)}" type="button" title="Detaylı açıklama">?</button>
      </div>
      <div class="kpi-value-row">
        <span class="kpi-value">${escapeHtml(valueText)}</span>
        ${deltaText ? `<span class="kpi-delta">${escapeHtml(deltaText)}</span>` : ""}
      </div>
      <p class="kpi-explain">${escapeHtml(g.short)}</p>
      <div class="kpi-drawer ${isOpen ? "" : "hidden"}" id="drawer-${escapeHtml(id)}">
        <div><strong>Neden Önemli:</strong> ${escapeHtml(g.why)}</div>
        <div><strong>Hedef &amp; Eylem:</strong> ${escapeHtml(g.target)}</div>
      </div>
    </article>
  `;
}

function renderKpis() {
  const k = state.overview.kpis;
  const ai = state.overview.ai_economics;
  const cards = [
    kpiCardHtml("total_users", formatNumber(k.total_users), `Bugün +${k.new_users_today}`),
    kpiCardHtml("dau_wau", `${formatNumber(k.dau_today)} / ${formatNumber(k.wau_7d)}`, `Stickiness %${k.stickiness_pct}`),
    kpiCardHtml("plates", formatNumber(k.plates_period), `Bugün ${formatNumber(k.plates_today)}`),
    kpiCardHtml("deep_dives", formatNumber(k.deep_dives_period), `Bugün ${formatNumber(k.deep_dives_today)}`),
    kpiCardHtml("pro_trials", `${formatNumber(k.active_pro)} Pro · ${formatNumber(k.active_trials)} Trial`, `${formatNumber(k.free_users)} Free`),
    kpiCardHtml("mrr_revenue", `$${Number(k.mrr_usd).toFixed(2)}`, `28g: $${Number(k.revenue_28d_usd).toFixed(2)}`),
    kpiCardHtml("ai_cost", `$${Number(ai.estimated_cost_usd).toFixed(4)}`, `Tabak ~$${Number(ai.cost_per_plate_usd).toFixed(5)}`),
    kpiCardHtml("health", `%${k.generation_success_rate_pct}`, `${k.api_errors_period} hata · ${k.safety_blocks_period} safety`),
  ];
  $("kpi-grid").innerHTML = cards.join("");
}

function renderTrendChart() {
  const series = state.overview.daily_series || [];
  const key = state.chartSeries;
  const wrap = $("trend-chart-wrap");
  if (!series.length) {
    wrap.innerHTML = `<div class="empty-state">Günlük veri henüz yok.</div>`;
    return;
  }

  const W = 620;
  const H = 210;
  const padL = 38;
  const padR = 16;
  const padT = 16;
  const padB = 28;
  const plotW = W - padL - padR;
  const plotH = H - padT - padB;

  const vals = series.map((d) => Number(d[key] || 0));
  const maxVal = Math.max(...vals, key === "ai_cost_usd" ? 0.001 : 4);

  const pts = series.map((d, idx) => {
    const x = series.length === 1 ? padL + plotW / 2 : padL + (idx / (series.length - 1)) * plotW;
    const y = padT + plotH - (Number(d[key] || 0) / maxVal) * plotH;
    return { x, y, d, val: Number(d[key] || 0) };
  });

  const polyline = pts.map((p) => `${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" ");
  const areaPath = pts.length
    ? `M ${pts[0].x.toFixed(1)},${(padT + plotH).toFixed(1)} L ${pts.map((p) => `${p.x.toFixed(1)},${p.y.toFixed(1)}`).join(" L ")} L ${pts[pts.length - 1].x.toFixed(1)},${(padT + plotH).toFixed(1)} Z`
    : "";

  const gridLines = [0, 0.5, 1].map((ratio) => {
    const y = padT + plotH - ratio * plotH;
    const lbl = key === "ai_cost_usd" ? `$${(maxVal * ratio).toFixed(3)}` : Math.round(maxVal * ratio);
    return `
      <line x1="${padL}" y1="${y.toFixed(1)}" x2="${W - padR}" y2="${y.toFixed(1)}" stroke="var(--stroke)" stroke-dasharray="3 3" />
      <text x="${padL - 6}" y="${(y + 4).toFixed(1)}" text-anchor="end" fill="var(--ink-3)" font-size="10" font-family="var(--font-mono)">${lbl}</text>
    `;
  }).join("");

  const labelStep = Math.max(1, Math.ceil(series.length / 6));
  const xLabels = pts
    .filter((_, idx) => idx % labelStep === 0 || idx === pts.length - 1)
    .map(
      (p) => `<text x="${p.x.toFixed(1)}" y="${H - 6}" text-anchor="middle" fill="var(--ink-3)" font-size="10" font-family="var(--font-mono)">${p.d.date.slice(5)}</text>`
    )
    .join("");

  const dots = pts
    .map(
      (p, idx) => `
      <circle cx="${p.x.toFixed(1)}" cy="${p.y.toFixed(1)}" r="4.2" fill="var(--paper)" stroke="var(--ink)" stroke-width="2" />
      <circle class="chart-hit" data-idx="${idx}" cx="${p.x.toFixed(1)}" cy="${p.y.toFixed(1)}" r="15" fill="transparent" style="cursor:pointer" />
    `
    )
    .join("");

  wrap.innerHTML = `
    <svg class="chart-svg" viewBox="0 0 ${W} ${H}" role="img" aria-label="Günlük metrik grafiği">
      ${gridLines}
      <path d="${areaPath}" fill="var(--ink)" opacity="0.07" />
      <polyline points="${polyline}" fill="none" stroke="var(--ink)" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round" />
      ${xLabels}
      ${dots}
    </svg>
  `;

  const lastPt = pts[pts.length - 1];
  updateChartHoverBar(lastPt.d);

  wrap.querySelectorAll(".chart-hit").forEach((el) => {
    const show = () => {
      const item = series[Number(el.dataset.idx)];
      if (item) updateChartHoverBar(item);
    };
    el.addEventListener("mouseenter", show);
    el.addEventListener("click", show);
  });
}

function updateChartHoverBar(d) {
  $("chart-hover-bar").textContent =
    `${d.date} · DAU: ${d.dau} · Yeni: ${d.new_users} · Tabak: ${d.plates} · Derin: ${d.deep_dives} · Hata: ${d.errors} · AI: $${Number(d.ai_cost_usd).toFixed(4)}`;
}

function renderFunnel() {
  const funnel = state.overview.funnel || [];
  let minConv = 101;
  let bottleneckId = null;
  funnel.slice(1).forEach((s) => {
    if (s.conversion_from_prev_pct < minConv && s.count > 0) {
      minConv = s.conversion_from_prev_pct;
      bottleneckId = s.id;
    }
  });

  $("funnel-list").innerHTML = funnel
    .map((step, idx) => {
      const isBottleneck = step.id === bottleneckId && idx > 0;
      return `
        <div class="funnel-row ${isBottleneck ? "bottleneck" : ""}">
          <div class="funnel-top">
            <span>${idx + 1}. ${escapeHtml(step.label)} ${isBottleneck ? "⚠️" : ""}</span>
            <span class="mono-muted">${formatNumber(step.count)} (%${step.conversion_from_prev_pct})</span>
          </div>
          <div class="funnel-track">
            <div class="funnel-fill" style="width:${Math.max(3, Math.min(100, step.conversion_from_top_pct))}%"></div>
          </div>
          <div class="funnel-meta">
            <span>${escapeHtml(FUNNEL_EXPLAINS[step.id] || "")}</span>
            <span>Baştan: %${step.conversion_from_top_pct}</span>
          </div>
        </div>
      `;
    })
    .join("");
}

function renderEngagement() {
  const eng = state.overview.engagement || {};
  $("engagement-list").innerHTML = ENGAGEMENT_META.map((m) => {
    const pct = eng[m.key] ?? 0;
    const rawCount = m.countKey ? ` (${formatNumber(eng[m.countKey] || 0)} kez)` : "";
    return `
      <div class="metric-row">
        <div class="metric-row-top">
          <span>${escapeHtml(m.label)}</span>
          <span class="badge-mono">%${pct}${escapeHtml(rawCount)}</span>
        </div>
        <p class="metric-row-sub">${escapeHtml(m.explain)}</p>
      </div>
    `;
  }).join("");
}

function renderLanguages() {
  const langs = state.overview.languages || {};
  const entries = Object.entries(langs).sort((a, b) => b[1] - a[1]);
  const total = entries.reduce((acc, [, v]) => acc + v, 0) || 1;
  const max = Math.max(...entries.map(([, v]) => v), 1);

  $("language-bars").innerHTML = entries
    .map(([code, cnt]) => {
      const share = ((cnt / total) * 100).toFixed(0);
      const width = Math.max(cnt > 0 ? 4 : 0, (cnt / max) * 100);
      return `
        <div>
          <div class="bar-item-top">
            <span><code>${escapeHtml(code.toUpperCase())}</code></span>
            <span class="mono-muted">${formatNumber(cnt)} (%${share})</span>
          </div>
          <div class="bar-track"><div class="bar-fill" style="width:${width}%"></div></div>
        </div>
      `;
    })
    .join("");
}

function renderTopicsAndPaywall() {
  const topics = state.overview.top_topics || [];
  const pw = state.overview.paywall_sources || {};
  const errs = state.overview.error_codes || {};

  const topicsHtml = topics.length
    ? `<div class="chip-cloud">${topics.map((t) => `<span class="topic-chip">${escapeHtml(t.topic.replaceAll("_", " "))} · ${t.count}</span>`).join("")}</div>`
    : `<p class="micro-help">Henüz konu verisi birikmedi.</p>`;

  const pwEntries = Object.entries(pw);
  const pwHtml = pwEntries.length
    ? `<div class="chip-cloud">${pwEntries.map(([k, v]) => `<span class="topic-chip">${escapeHtml(k)}: ${v}</span>`).join("")}</div>`
    : `<p class="micro-help">Henüz paywall tetikleme verisi yok.</p>`;

  const errEntries = Object.entries(errs);
  const errHtml = errEntries.length
    ? `<div class="chip-cloud">${errEntries.map(([k, v]) => `<span class="topic-chip" style="border-color:var(--danger);color:var(--danger);">${escapeHtml(k)}: ${v}</span>`).join("")}</div>`
    : `<p class="micro-help">Dönem içinde API hatası yok.</p>`;

  $("topics-and-paywall").innerHTML = `
    <div>
      <div class="kpi-label" style="margin-bottom:6px;">Popüler Konular</div>
      ${topicsHtml}
    </div>
    <div>
      <div class="kpi-label" style="margin-bottom:6px;">Paywall Tetikleme Kaynakları</div>
      ${pwHtml}
    </div>
    <div>
      <div class="kpi-label" style="margin-bottom:6px;">Hata Kodları</div>
      ${errHtml}
    </div>
  `;
}

function renderRevenueAndAI() {
  const k = state.overview.kpis;
  const ai = state.overview.ai_economics;
  const rc = state.overview.connections.revenuecat || {};
  const rcM = rc.metrics || {};

  const rcStatusHtml = rc.connected
    ? `<span class="status-chip"><span class="dot dot-good"></span> RevenueCat v2 Canlı (${escapeHtml(rc.project_id)})</span>`
    : `<span class="status-chip"><span class="dot dot-warn"></span> Firestore Yedek Modu</span><p class="micro-help" style="margin-top:8px;">${escapeHtml(rc.reason || "")}</p>`;

  const rcDetails = rc.connected
    ? `
      <div class="metric-rows" style="margin-top:12px;">
        <div class="metric-row"><div class="metric-row-top"><span>RevenueCat MRR</span><span>$${Number(rcM.mrr?.value || 0).toFixed(2)}</span></div><p class="metric-row-sub">Son 28 günlük aylık tekrarlayan gelir.</p></div>
        <div class="metric-row"><div class="metric-row-top"><span>28 Günlük Brüt Gelir</span><span>$${Number(rcM.revenue?.value || 0).toFixed(2)}</span></div><p class="metric-row-sub">App Store üzerinden doğrulanan toplam satış.</p></div>
        <div class="metric-row"><div class="metric-row-top"><span>Yeni / Aktif Müşteri (28g)</span><span>${formatNumber(rcM.new_customers?.value || 0)} / ${formatNumber(rcM.active_users?.value || 0)}</span></div><p class="metric-row-sub">RevenueCat SDK gören cihaz/kullanıcılar.</p></div>
      </div>
    `
    : `
      <div class="metric-rows" style="margin-top:12px;">
        <div class="metric-row"><div class="metric-row-top"><span>Yıllık Pro ($29.99/yıl)</span><span>${formatNumber(k.yearly_subs)}</span></div><p class="metric-row-sub">Aylık eşdeğer katkı ~$2.50/kullanıcı.</p></div>
        <div class="metric-row"><div class="metric-row-top"><span>Aylık Pro ($3.99/ay)</span><span>${formatNumber(k.monthly_subs)}</span></div><p class="metric-row-sub">Aylık yenilenen plan.</p></div>
        <div class="metric-row"><div class="metric-row-top"><span>Webhook Geliri (Dönem)</span><span>$${Number(k.revenue_28d_usd).toFixed(2)}</span></div><p class="metric-row-sub">RevenueCat webhook olaylarından toplanan tutar.</p></div>
      </div>
    `;

  $("revenue-content").innerHTML = `
    <article class="panel-card">
      <div class="panel-head">
        <div>
          <h3>RevenueCat &amp; Abonelik Dağılımı</h3>
          <p class="panel-desc">Ödeme durumu, denemeler ve yenileme sorunları.</p>
        </div>
      </div>
      ${rcStatusHtml}
      ${rcDetails}
    </article>

    <article class="panel-card">
      <div class="panel-head">
        <div>
          <h3>Kullanıcı Katmanları (Firestore Entitlements)</h3>
          <p class="panel-desc">Veritabanındaki yetki durumlarının anlık kırılımı.</p>
        </div>
      </div>
      <div class="metric-rows">
        <div class="metric-row"><div class="metric-row-top"><span>Aktif Pro Abone</span><span class="badge-mono">${formatNumber(k.active_pro)}</span></div><p class="metric-row-sub">Sınırsız okuma ve 40/gün Derin İnceleme hakkına sahip.</p></div>
        <div class="metric-row"><div class="metric-row-top"><span>Aktif 7 Gün Deneme (Trial)</span><span class="badge-mono">${formatNumber(k.active_trials)}</span></div><p class="metric-row-sub">İlk 7 gün içinde dönüşüm aşamasındaki adaylar.</p></div>
        <div class="metric-row"><div class="metric-row-top"><span>Ödeme Sorunu (Billing Issue)</span><span class="badge-mono">${formatNumber(k.billing_issues)}</span></div><p class="metric-row-sub">Kart yenilemesinde sorun yaşayan abonelikler.</p></div>
        <div class="metric-row"><div class="metric-row-top"><span>Süresi Dolan (Expired)</span><span class="badge-mono">${formatNumber(k.expired_pro)}</span></div><p class="metric-row-sub">Geri kazanım (win-back) kampanyası hedef kitlesi.</p></div>
      </div>
    </article>
  `;

  $("ai-econ-content").innerHTML = `
    <article class="kpi-card">
      <div class="kpi-label">Toplam Token (Girdi / Çıktı)</div>
      <div class="kpi-value">${formatNumber(ai.input_tokens)} / ${formatNumber(ai.output_tokens)}</div>
      <p class="kpi-explain">Seçili dönemde Gemini API'ye gönderilen prompt ve üretilen kelime token'ları.</p>
    </article>
    <article class="kpi-card">
      <div class="kpi-label">Aylık Ücretsiz Kullanıcı Maliyeti</div>
      <div class="kpi-value">$${Number(ai.avg_monthly_cost_free_user_usd).toFixed(4)}</div>
      <p class="kpi-explain">Günde 3 tabak tüketen aktif bir ücretsiz kullanıcının aylık tahmini Gemini faturası.</p>
    </article>
    <article class="kpi-card">
      <div class="kpi-label">Aylık Pro Kullanıcı Maliyeti</div>
      <div class="kpi-value">$${Number(ai.avg_monthly_cost_pro_user_usd).toFixed(4)}</div>
      <p class="kpi-explain">Günde ortalama 18 tabak tüketen aktif bir Pro abonenin aylık API maliyeti.</p>
    </article>
    <article class="kpi-card">
      <div class="kpi-label">Pro Brüt Marj (AI Sonrası)</div>
      <div class="kpi-value">%${ai.pro_gross_margin_pct}</div>
      <p class="kpi-explain">Yıllık planın aylık geliri ($2.50) içinden Gemini maliyeti düşüldükten sonra kalan brüt marj.</p>
    </article>
  `;
}

function renderFeedback() {
  const catFilter = $("feedback-cat-filter").value;
  const needle = $("feedback-search").value.trim().toLowerCase();
  const list = state.feedback.filter((f) => {
    if (catFilter !== "all" && f.category !== catFilter) return false;
    if (needle) {
      const hay = `${f.message} ${f.username} ${f.displayName} ${f.email}`.toLowerCase();
      if (!hay.includes(needle)) return false;
    }
    return true;
  });

  if (!list.length) {
    $("feedback-list").innerHTML = `<div class="empty-state">Seçili filtreye uygun kullanıcı geri bildirimi bulunamadı.</div>`;
    return;
  }

  $("feedback-list").innerHTML = list
    .map((f) => {
      const statusCls = f.status === "new" ? "is-new" : f.status === "resolved" ? "is-resolved" : "";
      const stars = f.rating ? "★".repeat(f.rating) + "☆".repeat(5 - f.rating) : "Puan yok";
      const who = f.username ? `@${f.username}` : f.displayName || f.uid?.slice(0, 8) || "Anonim";
      return `
        <article class="triage-card" data-fb-id="${escapeHtml(f.id)}">
          <div class="triage-head">
            <div class="triage-badges">
              <span class="pill-tag">${escapeHtml(f.category)}</span>
              <span class="pill-tag ${statusCls}">${escapeHtml(f.status)}</span>
              <span class="pill-tag ${f.isPro ? "is-pro" : ""}">${f.isPro ? "PRO" : "FREE"}</span>
              <span class="mono-muted">${escapeHtml(stars)}</span>
            </div>
            <span class="mono-muted">${escapeHtml(formatRelative(f.createdAt))}</span>
          </div>
          <p class="triage-msg">${escapeHtml(f.message)}</p>
          <div class="triage-meta">
            <strong>${escapeHtml(who)}</strong> · Dil: <code>${escapeHtml(f.language || "-")}</code> · Sürüm: <code>${escapeHtml(f.appVersion || "-")}</code> · ${escapeHtml(f.osVersion || "-")} (${escapeHtml(f.deviceModel || "-")})
          </div>
          <div class="triage-actions">
            <input class="note-input" type="text" placeholder="Admin notu ekle…" value="${escapeHtml(f.adminNote || "")}">
            <button class="btn btn-xs btn-outline fb-action-btn" data-status="reviewed" type="button">İncelendi</button>
            <button class="btn btn-xs btn-primary fb-action-btn" data-status="resolved" type="button">Çözüldü</button>
            <button class="btn btn-xs btn-ghost fb-action-btn" data-status="archived" type="button">Arşivle</button>
          </div>
        </article>
      `;
    })
    .join("");
}

function renderReports() {
  if (!state.reports.length) {
    $("reports-list").innerHTML = `<div class="empty-state">Bu filtrede moderasyon şikayeti yok.</div>`;
    return;
  }

  $("reports-list").innerHTML = state.reports
    .map((r) => {
      const p = r.postPreview;
      const previewHtml = p
        ? `<div class="post-preview-box"><strong>${escapeHtml(p.title)}</strong> (${escapeHtml(p.authorUsername ? "@" + p.authorUsername : p.authorName)})<br>${escapeHtml(p.text)}</div>`
        : `<div class="triage-meta">İlişkili gönderi silinmiş veya yorum/kullanıcı bazlı şikayet.</div>`;
      return `
        <article class="triage-card" data-rep-id="${escapeHtml(r.id)}">
          <div class="triage-head">
            <div class="triage-badges">
              <span class="pill-tag">${escapeHtml(r.targetType || "post")}</span>
              <span class="pill-tag ${r.status === "open" ? "is-new" : "is-resolved"}">${escapeHtml(r.status)}</span>
            </div>
            <span class="mono-muted">${escapeHtml(formatRelative(r.createdAt))}</span>
          </div>
          <p class="triage-msg"><strong>Neden:</strong> ${escapeHtml(r.reason || "Belirtilmedi")}</p>
          ${previewHtml}
          <div class="triage-actions">
            <input class="note-input" type="text" placeholder="Moderasyon notu…" value="${escapeHtml(r.adminNote || "")}">
            <button class="btn btn-xs btn-primary rep-action-btn" data-status="resolved" data-del="false" type="button">Çözüldü</button>
            <button class="btn btn-xs btn-ghost rep-action-btn" data-status="dismissed" data-del="false" type="button">Yoksay</button>
            ${r.postId ? `<button class="btn btn-xs btn-danger rep-action-btn" data-status="resolved" data-del="true" type="button">Postu Sil &amp; Çöz</button>` : ""}
          </div>
        </article>
      `;
    })
    .join("");
}

function renderUsers() {
  const wrap = $("users-container");
  if (!state.users.length) {
    wrap.innerHTML = `<div class="empty-state">Eşleşen kullanıcı bulunamadı.</div>`;
    return;
  }

  const rows = state.users
    .map(
      (u) => `
      <tr>
        <td data-label="Kullanıcı"><strong>${escapeHtml(u.displayName)}</strong> ${u.username ? `<span class="mono-muted">@${escapeHtml(u.username)}</span>` : ""}</td>
        <td data-label="Katman"><span class="pill-tag ${u.isPro ? "is-pro" : ""}">${escapeHtml((u.subscriptionStatus || "free").toUpperCase())}</span></td>
        <td data-label="Bugün Tabak"><span class="mono-muted">${u.platesToday} tabak · ${u.deepDivesToday || 0} inceleme</span></td>
        <td data-label="İlgi">${u.interestsCount} tat</td>
        <td data-label="Kayıt">${escapeHtml(formatRelative(u.createdAt))}</td>
      </tr>`
    )
    .join("");

  wrap.innerHTML = `
    <table class="users-table">
      <thead>
        <tr>
          <th>Kullanıcı</th>
          <th>Katman</th>
          <th>Bugünkü Kullanım</th>
          <th>İlgi Alanı</th>
          <th>Kayıt</th>
        </tr>
      </thead>
      <tbody>${rows}</tbody>
    </table>
  `;
}

// ============================================================================
// AI AGENT EXPORT & GLOSSARY MODALS
// ============================================================================

function buildDemoMarkdownExport(preset) {
  const o = state.overview;
  const k = o.kpis;
  const ai = o.ai_economics;
  const eng = o.engagement;
  const prompts = {
    launch: "Lansman günü darboğazlarını, en kritik kullanıcı feedback'lerini ve önümüzdeki 24 saat için 3 somut aksiyonu öner.",
    conversion: "Paywall tetikleme anları ve Trial dönüşümünü artırmak için somut A/B testleri ve copy önerileri üret.",
    triage: "Hata kodları ve feedback'leri önceliklendir; düzeltilecek ilk 3 işi dosya bazında planla.",
    growth: "Dil/konu dağılımı ve paylaşım oranına göre organik büyüme ve içerik stratejisi çıkar.",
  };
  return [
    `# Omakase — AI Agent Veri Brifingi (DEMO · ${preset})`,
    `> Pencere: Son ${o.period_days} gün · Dışa Aktarım: ${new Date().toISOString()}`,
    "",
    "## 1. KPI Özeti",
    `- Kullanıcılar: **${k.total_users}** (Bugün +${k.new_users_today}) · DAU **${k.dau_today}** / WAU **${k.wau_7d}** (Stickiness %${k.stickiness_pct})`,
    `- İçerik: **${k.plates_period}** tabak, **${k.deep_dives_period}** Derin İnceleme`,
    `- Monetizasyon: **${k.active_pro}** Pro · **${k.active_trials}** Trial · MRR **$${k.mrr_usd}**`,
    `- Kalite: Kaynakça **%${eng.source_tap_rate_pct}** · Okuma **%${eng.cooldown_completion_rate_pct}** · Başarı **%${k.generation_success_rate_pct}** · AI Maliyet **$${ai.estimated_cost_usd}**`,
    "",
    "## 2. Görev Talimatı",
    prompts[preset] || prompts.launch,
  ].join("\n");
}

let cachedExportJson = null;
let cachedExportMd = "";

async function loadExportPreview() {
  $("export-preview").textContent = "Hazırlanıyor…";
  if (state.demoMode) {
    cachedExportJson = {
      schema_version: "1.0",
      mode: "demo",
      preset: state.exportPreset,
      overview: state.overview,
      recent_feedback: state.feedback,
      open_moderation_reports: state.reports,
    };
    cachedExportMd = buildDemoMarkdownExport(state.exportPreset);
    $("export-preview").textContent = cachedExportMd;
    return;
  }

  try {
    const [md, jsonPayload] = await Promise.all([
      apiFetch(`/admin/export?days=${state.days}&format=markdown&preset=${state.exportPreset}`),
      apiFetch(`/admin/export?days=${state.days}&format=json&preset=${state.exportPreset}`),
    ]);
    cachedExportMd = typeof md === "string" ? md : JSON.stringify(md, null, 2);
    cachedExportJson = jsonPayload;
    $("export-preview").textContent = cachedExportMd;
  } catch (err) {
    $("export-preview").textContent = `Dışa aktarım hatası: ${err.message}`;
  }
}

function downloadText(filename, content, mime) {
  const blob = new Blob([content], { type: mime });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

function renderGlossaryModal(filter = "") {
  const needle = filter.trim().toLowerCase();
  const entries = Object.values(METRIC_GLOSSARY).filter((g) => {
    if (!needle) return true;
    return `${g.title} ${g.short} ${g.why} ${g.target}`.toLowerCase().includes(needle);
  });
  $("glossary-list").innerHTML = entries
    .map(
      (g) => `
      <div class="glossary-item">
        <h4>${escapeHtml(g.title)}</h4>
        <p><strong>Ne demek:</strong> ${escapeHtml(g.short)}</p>
        <p><strong>Neden önemli:</strong> ${escapeHtml(g.why)}</p>
        <p><strong>Hedef &amp; Eylem:</strong> ${escapeHtml(g.target)}</p>
      </div>
    `
    )
    .join("");
}

// ============================================================================
// EVENT LISTENERS
// ============================================================================

function switchTab(tabName) {
  state.activeTab = tabName;
  document.querySelectorAll(".tab-pill, .mnav-btn").forEach((b) => {
    b.classList.toggle("active", b.dataset.tab === tabName);
  });
  document.querySelectorAll(".tab-panel").forEach((p) => {
    p.classList.toggle("active", p.id === `tab-${tabName}`);
  });
}

document.querySelectorAll(".tab-pill, .mnav-btn").forEach((btn) => {
  btn.addEventListener("click", () => switchTab(btn.dataset.tab));
});

document.querySelectorAll(".range-btn").forEach((btn) => {
  btn.addEventListener("click", () => {
    state.days = Number(btn.dataset.days);
    document.querySelectorAll(".range-btn").forEach((b) => b.classList.toggle("active", b === btn));
    loadAllData();
  });
});

$("refresh-btn").addEventListener("click", () => {
  loadAllData();
  showToast("Veriler yenilendi");
});

$("autorefresh-checkbox").addEventListener("change", (e) => {
  clearInterval(state.autoRefreshTimer);
  if (e.target.checked) {
    state.autoRefreshTimer = setInterval(loadAllData, 60000);
    showToast("60 sn otomatik yenileme açıldı");
  }
});

$("chart-series-pills").addEventListener("click", (e) => {
  const btn = e.target.closest(".series-btn");
  if (!btn) return;
  state.chartSeries = btn.dataset.series;
  document.querySelectorAll(".series-btn").forEach((b) => b.classList.toggle("active", b === btn));
  renderTrendChart();
});

$("kpi-grid").addEventListener("click", (e) => {
  const btn = e.target.closest(".help-btn");
  if (!btn) return;
  const id = btn.dataset.helpId;
  if (state.openHelpCards.has(id)) {
    state.openHelpCards.delete(id);
  } else {
    state.openHelpCards.add(id);
  }
  btn.classList.toggle("open");
  const drawer = $(`drawer-${id}`);
  if (drawer) drawer.classList.toggle("hidden");
});

$("feedback-status-filter").addEventListener("change", refreshFeedbackOnly);
$("feedback-cat-filter").addEventListener("change", renderFeedback);
$("feedback-search").addEventListener("input", renderFeedback);
$("reports-status-filter").addEventListener("change", refreshReportsOnly);

let userSearchTimer = null;
$("users-search").addEventListener("input", () => {
  clearTimeout(userSearchTimer);
  userSearchTimer = setTimeout(refreshUsersOnly, 280);
});

$("feedback-list").addEventListener("click", async (e) => {
  const btn = e.target.closest(".fb-action-btn");
  if (!btn) return;
  const card = btn.closest("[data-fb-id]");
  const fbId = card.dataset.fbId;
  const nextStatus = btn.dataset.status;
  const note = card.querySelector(".note-input").value;

  if (state.demoMode) {
    const item = state.feedback.find((x) => x.id === fbId);
    if (item) {
      item.status = nextStatus;
      item.adminNote = note;
    }
    renderFeedback();
    showToast(`Demo: Durum '${nextStatus}' yapıldı`);
    return;
  }

  try {
    await apiFetch(`/admin/feedback/${encodeURIComponent(fbId)}`, {
      method: "PATCH",
      body: JSON.stringify({ status: nextStatus, admin_note: note }),
    });
    showToast("Geri bildirim güncellendi");
    await loadAllData();
  } catch (err) {
    showToast(`Güncelleme hatası: ${err.message}`);
  }
});

$("reports-list").addEventListener("click", async (e) => {
  const btn = e.target.closest(".rep-action-btn");
  if (!btn) return;
  const card = btn.closest("[data-rep-id]");
  const repId = card.dataset.repId;
  const nextStatus = btn.dataset.status;
  const deletePost = btn.dataset.del === "true";
  const note = card.querySelector(".note-input").value;

  if (deletePost && !window.confirm("Bu topluluk gönderisini kalıcı olarak silip şikayeti kapatmak istediğine emin misin?")) {
    return;
  }

  if (state.demoMode) {
    const item = state.reports.find((x) => x.id === repId);
    if (item) {
      item.status = nextStatus;
      if (deletePost) item.postPreview = null;
    }
    renderReports();
    showToast("Demo: Moderasyon işlemi uygulandı");
    return;
  }

  try {
    await apiFetch(`/admin/reports/${encodeURIComponent(repId)}`, {
      method: "PATCH",
      body: JSON.stringify({ status: nextStatus, admin_note: note, delete_post: deletePost }),
    });
    showToast(deletePost ? "Gönderi silindi ve şikayet kapatıldı" : "Şikayet güncellendi");
    await loadAllData();
  } catch (err) {
    showToast(`İşlem hatası: ${err.message}`);
  }
});

// Modals
$("open-export-btn").addEventListener("click", () => {
  $("export-modal").classList.remove("hidden");
  loadExportPreview();
});

$("open-glossary-btn").addEventListener("click", () => {
  renderGlossaryModal("");
  $("glossary-modal").classList.remove("hidden");
});

$("glossary-search").addEventListener("input", (e) => renderGlossaryModal(e.target.value));

$("export-preset-pills").addEventListener("click", (e) => {
  const btn = e.target.closest(".preset-btn");
  if (!btn) return;
  state.exportPreset = btn.dataset.preset;
  document.querySelectorAll(".preset-btn").forEach((b) => b.classList.toggle("active", b === btn));
  loadExportPreview();
});

$("copy-md-btn").addEventListener("click", async () => {
  await navigator.clipboard.writeText(cachedExportMd || $("export-preview").textContent);
  showToast("Markdown brifing panoya kopyalandı!");
});

$("copy-json-btn").addEventListener("click", async () => {
  await navigator.clipboard.writeText(JSON.stringify(cachedExportJson || {}, null, 2));
  showToast("JSON verisi panoya kopyalandı!");
});

$("download-md-btn").addEventListener("click", () => {
  const day = new Date().toISOString().slice(0, 10);
  downloadText(`omakase-agent-brief-${day}.md`, cachedExportMd || "", "text/markdown");
});

$("download-json-btn").addEventListener("click", () => {
  const day = new Date().toISOString().slice(0, 10);
  downloadText(`omakase-metrics-${day}.json`, JSON.stringify(cachedExportJson || {}, null, 2), "application/json");
});

document.querySelectorAll("[data-close-modal]").forEach((btn) => {
  btn.addEventListener("click", () => $(btn.dataset.closeModal).classList.add("hidden"));
});

document.querySelectorAll(".modal-backdrop").forEach((backdrop) => {
  backdrop.addEventListener("click", (e) => {
    if (e.target === backdrop) backdrop.classList.add("hidden");
  });
});

$("theme-toggle-btn").addEventListener("click", () => {
  const current = document.documentElement.getAttribute("data-theme") || "light";
  applyTheme(current === "dark" ? "light" : "dark");
});

// Restore saved theme
applyTheme(localStorage.getItem("omakase.admin.theme") || "light");
