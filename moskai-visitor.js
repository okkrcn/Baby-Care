/* MoskAI anonymous website counter. No cookies, identity, titles or page contents. */
(function (root) {
  'use strict';

  var ENDPOINT = 'https://analytics.moskaisoft.com/api/send';
  var UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

  function consentAllowed(mode, env, website) {
    if (mode === 'none') return true;
    try {
      var raw;
      if (mode === 'moskai') {
        raw = JSON.parse(env.localStorage.getItem('moskai_cookie_preferences') || 'null');
        return !!raw && raw.consentGiven === true && raw.analytics === true;
      }
      if (mode === 'minutes') {
        raw = JSON.parse(env.localStorage.getItem('ms-cookie-consent-v2') || 'null');
        return !!raw && raw.value === 'accepted';
      }
      if (mode === 'ebe') return env.localStorage.getItem('ebc_cookie_consent') === 'accepted';
      if (mode === 'fleet') {
        raw = JSON.parse(env.localStorage.getItem('moskai_visit_consent_v1:' + website) || 'null');
        return !!raw && raw.version === 1 && raw.purpose === 'anonymous-visit' && raw.choice === 'granted';
      }
      if (mode === 'marifet') {
        var cookie = (env.document.cookie || '').split(';').map(function (value) { return value.trim(); }).find(function (value) { return value.indexOf('marifet_consent=') === 0; });
        raw = cookie ? JSON.parse(decodeURIComponent(cookie.slice('marifet_consent='.length))) : null;
        return !!raw && raw.analytics === true;
      }
    } catch {
      return false;
    }
    return false;
  }

  function allowed(config, env) {
    var browser = env.navigator || {};
    if (browser.globalPrivacyControl === true || browser.doNotTrack === '1' || browser.doNotTrack === 'yes' || env.doNotTrack === '1') return false;
    if (!env.location || config.hosts.indexOf(env.location.hostname) < 0) return false;
    if (config.paths && config.paths.indexOf(env.location.pathname) < 0) return false;
    return consentAllowed(config.consent, env, config.id);
  }

  function boot(config, environment) {
    var env = environment || root;
    if (!env || !config || !UUID.test(config.id || '') || !Array.isArray(config.hosts) || !config.hosts.length) return;
    if (config.path !== '/' && !/^\/[a-zA-Z_-][a-zA-Z0-9_/-]*$/.test(config.path || '')) return;
    if (config.paths && (!Array.isArray(config.paths) || config.paths.some(function (path) { return typeof path !== 'string'; }))) return;
    var sites = env.__moskaiVisitorSites || (env.__moskaiVisitorSites = {});
    if (sites[config.id]) return;
    var state = sites[config.id] = { attempted: false, sent: false };
    var timer;
    function attempt() {
      if (state.attempted || !allowed(config, env)) return;
      state.attempted = true;
      if (timer) env.clearInterval(timer);
      // Never derive this URL from the page; authenticated paths may contain PII.
      var payload = { website: config.id, hostname: env.location.hostname, language: (env.navigator || {}).language, url: config.path };
      try {
        Promise.resolve(env.fetch(ENDPOINT, {
          method: 'POST', credentials: 'omit', referrerPolicy: 'no-referrer',
          cache: 'no-store', keepalive: true,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ type: 'event', payload: payload })
        })).then(function (response) { state.sent = !!response.ok; }).catch(function () { return false; });
      } catch { return state; /* Analytics must never disrupt the application. */ }
    }
    attempt();
    if (!state.attempted && ['moskai', 'minutes', 'ebe', 'fleet', 'marifet'].indexOf(config.consent) >= 0) {
      timer = env.setInterval(attempt, 1000);
      env.addEventListener('storage', attempt);
      env.addEventListener('ms-consent-change', attempt);
      env.addEventListener('moskai-visit-consent-change', attempt);
      env.addEventListener('consent-changed', attempt);
    }
    return state;
  }

  var api = { boot: boot, consentAllowed: consentAllowed };
  if (typeof module === 'object' && module.exports) module.exports = api;
  else if (root) root.MoskaiVisitor = api;
})(typeof window === 'undefined' ? null : window);

/* Explicit website-only anonymous analytics choice; never reuses technical-cookie consent. */
(function (root) {
  'use strict';
  var UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  var copy = {
    tr: {
      title: 'Ziyaret ölçümüne izin verir misin?',
      body: 'Bu web sitesinde yalnız anonim ziyaret sayısını ölçeriz. İçerik, form veya kimlik bilgisi göndermeyiz. Ölçüm isteğe bağlıdır ve izin vermeden başlamaz.',
      grant: 'İzin ver', deny: 'Reddet', settings: 'Ölçüm tercihi',
      later: 'Tercihini dilediğin zaman buradan değiştirebilirsin. Tarayıcı gizlilik tercihin önceliklidir.',
      error: 'Tercih kaydedilemedi. Ölçüm kapalı kaldı; tekrar deneyebilirsin.'
    },
    en: {
      title: 'Allow anonymous visit measurement?',
      body: 'On this website, we only count anonymous visits. We do not send content, form entries or identity details. Measurement is optional and starts only with your permission.',
      grant: 'Allow', deny: 'Decline', settings: 'Measurement preference',
      later: 'You can change your choice here at any time. Your browser privacy preference takes priority.',
      error: 'Your choice could not be saved. Measurement remains off; you can try again.'
    },
    ru: {
      title: 'Разрешить анонимный подсчёт посещений?',
      body: 'На этом сайте мы считаем только анонимные посещения. Содержимое, данные форм и сведения о личности не отправляются. Подсчёт необязателен и начинается только с вашего разрешения.',
      grant: 'Разрешить', deny: 'Отклонить', settings: 'Настройки подсчёта',
      later: 'Вы можете изменить выбор здесь в любое время. Настройки конфиденциальности браузера имеют приоритет.',
      error: 'Не удалось сохранить выбор. Подсчёт остаётся отключённым; попробуйте ещё раз.'
    },
    ar: {
      title: 'هل تسمح بقياس الزيارات بشكل مجهول؟',
      body: 'نحسب الزيارات المجهولة لهذا الموقع فقط، ولا نرسل المحتوى أو بيانات النماذج أو معلومات الهوية. القياس اختياري ولا يبدأ دون إذنك.',
      grant: 'السماح', deny: 'الرفض', settings: 'تفضيل قياس الزيارات',
      later: 'يمكنك تغيير اختيارك هنا في أي وقت. تُحترم إعدادات الخصوصية في متصفحك أولاً.',
      error: 'تعذّر حفظ اختيارك. بقي القياس متوقفاً؛ يمكنك المحاولة مجدداً.'
    }
  };

  function read(id, env) {
    try {
      var choice = JSON.parse(env.localStorage.getItem('moskai_visit_consent_v1:' + id) || 'null');
      return choice && choice.version === 1 && choice.purpose === 'anonymous-visit' && ['granted', 'denied'].indexOf(choice.choice) >= 0 ? choice.choice : null;
    } catch { return null; }
  }

  function choose(id, value, env) {
    if (!UUID.test(id || '') || ['granted', 'denied'].indexOf(value) < 0) return false;
    try {
      env.localStorage.setItem('moskai_visit_consent_v1:' + id, JSON.stringify({ version: 1, purpose: 'anonymous-visit', choice: value }));
      env.dispatchEvent(new env.CustomEvent('moskai-visit-consent-change'));
      return true;
    } catch { return false; }
  }

  function mount(config, environment) {
    var env = environment || root;
    if (!env || !env.document || !env.document.body || !UUID.test(config.id || '')) return;
    if (config.paths && config.paths.indexOf(env.location.pathname) < 0) return;
    var document = env.document;
    var id = 'msvf-' + config.id;
    if (document.getElementById(id)) return;
    var language = String(config.locale || document.documentElement.lang || (env.navigator || {}).language || 'en').split('-')[0];
    var text = copy[language] || copy.en;
    function element(tag, className, content) {
      var node = document.createElement(tag);
      node.className = className;
      if (content) node.textContent = content;
      return node;
    }
    var container = element('div', 'msvf');
    container.id = id;
    container.setAttribute('data-theme', config.theme || 'light');
    container.setAttribute('dir', language === 'ar' ? 'rtl' : 'ltr');
    var panel = element('section', 'msvf-panel');
    panel.setAttribute('role', 'region');
    panel.setAttribute('aria-labelledby', id + '-title');
    var title = element('h2', 'msvf-title', text.title);
    title.id = id + '-title';
    panel.appendChild(title);
    panel.appendChild(element('p', 'msvf-body', text.body));
    var actions = element('div', 'msvf-actions');
    var reject = element('button', 'msvf-choice', text.deny);
    var grant = element('button', 'msvf-choice', text.grant);
    reject.type = grant.type = 'button';
    actions.appendChild(reject); actions.appendChild(grant);
    panel.appendChild(actions);
    panel.appendChild(element('p', 'msvf-later', text.later));
    var error = element('p', 'msvf-error');
    error.setAttribute('role', 'status');
    panel.appendChild(error);
    var settings = element('button', 'msvf-settings', text.settings);
    settings.type = 'button';
    settings.setAttribute('aria-controls', id + '-panel');
    panel.id = id + '-panel';
    function show(open) {
      panel.hidden = !open; settings.hidden = open;
      settings.setAttribute('aria-expanded', open ? 'true' : 'false');
    }
    function save(value) {
      if (!choose(config.id, value, env)) { error.textContent = text.error; return; }
      error.textContent = ''; show(false); settings.focus();
    }
    reject.addEventListener('click', function () { save('denied'); });
    grant.addEventListener('click', function () { save('granted'); });
    settings.addEventListener('click', function () { show(true); reject.focus(); });
    show(read(config.id, env) === null);
    container.appendChild(panel); container.appendChild(settings);
    document.body.appendChild(container);
    return container;
  }
  var api = { read: read, choose: choose, mount: mount, copy: copy };
  if (typeof module === 'object' && module.exports) module.exports = api;
  else if (root) root.MoskaiConsent = api;
})(typeof window === 'undefined' ? null : window);

(function(){var config={"id":"7d65c500-f157-5597-83b8-ee2aa8ebbeb8","hosts":["okkrcn.github.io"],"path":"/","consent":"fleet","paths":["/Baby-Care/","/Baby-Care/index.html","/Baby-Care/privacy.html"],"theme":"green"};window.MoskaiVisitor.boot(config,window);window.MoskaiConsent.mount(config,window);})();

