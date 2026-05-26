(function () {
  "use strict";

  // Force the dark slate palette and clear any stored light-mode preference.
  try {
    document.documentElement.setAttribute("data-md-color-scheme", "slate");
    document.documentElement.setAttribute("data-md-color-primary", "custom");
    document.documentElement.setAttribute("data-md-color-accent", "custom");
    if (window.localStorage) {
      window.localStorage.setItem(
        "__palette",
        JSON.stringify({ index: 0, color: { scheme: "slate", primary: "custom", accent: "custom" } })
      );
    }
  } catch (e) { /* ignore */ }

  var path = window.location.pathname;

  // Redirect legacy markdown URLs like /my-agent-memory/page.md to /my-agent-memory/page/
  if (/\.md$/i.test(path)) {
    var query = window.location.search || "";
    var hash = window.location.hash || "";
    var target = path.replace(/\.md$/i, "") + "/";
    window.location.replace(target + query + hash);
  }
})();
