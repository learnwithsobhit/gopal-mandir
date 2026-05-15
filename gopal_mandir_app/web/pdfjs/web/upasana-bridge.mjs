/**
 * Notifies the Flutter parent frame of page changes so resume position persists
 * (same keys as native SfPdfViewer). Payload is JSON for reliable parsing in Dart web.
 */
(function initUpasanaReadingDataset() {
  try {
    const p = new URLSearchParams(window.location.search);
    if (p.get("reading") === "1") {
      document.body.dataset.reading = "minimal";
    }
  } catch (_) {
    /* ignore */
  }
})();

async function initPageBridge() {
  const params = new URLSearchParams(window.location.search);
  const itemIdRaw = params.get("itemId");
  const itemId = itemIdRaw != null ? parseInt(itemIdRaw, 10) : NaN;
  if (itemIdRaw == null || Number.isNaN(itemId)) {
    return;
  }

  function waitForPdfApp() {
    return new Promise((resolve) => {
      function tick() {
        const app = window.PDFViewerApplication;
        if (app?.initializedPromise) {
          resolve(app);
          return;
        }
        requestAnimationFrame(tick);
      }
      tick();
    });
  }

  const app = await waitForPdfApp();
  await app.initializedPromise;

  const targetOrigin = window.location.origin;
  let debounceTimer = null;

  function postPage(page) {
    if (typeof page !== "number" || page < 1 || !Number.isFinite(page)) {
      return;
    }
    const payload = JSON.stringify({
      source: "daily-upasana-pdf",
      type: "page",
      itemId,
      page,
    });
    window.parent.postMessage(payload, targetOrigin);
  }

  function debouncedPost(page) {
    window.clearTimeout(debounceTimer);
    debounceTimer = window.setTimeout(() => postPage(page), 380);
  }

  app.eventBus.on("pagechanging", (evt) => {
    const page = evt?.pageNumber;
    debouncedPost(page);
  });

  // Initial notify once layout knows the page (resume hash may have jumped).
  debouncedPost(app.pdfViewer?.currentPageNumber ?? 1);
}

initPageBridge().catch(() => {
  /* non-fatal — reader still works without persistence */
});
