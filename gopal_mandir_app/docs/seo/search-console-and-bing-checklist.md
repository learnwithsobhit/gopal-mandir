# Search Console and Bing Setup

Target site: `https://gopal-mandir-app.web.app/`
Sitemap: `https://gopal-mandir-app.web.app/sitemap.xml`

## Google Search Console

1. Open [Google Search Console](https://search.google.com/search-console).
2. Add property as `URL prefix` for `https://gopal-mandir-app.web.app/`.
3. Verify ownership using one method:
   - HTML file upload (recommended), or
   - HTML tag in `web/index.html`, or
   - DNS TXT record.
4. Go to `Sitemaps` and submit `sitemap.xml`.
5. Use `URL Inspection` to request indexing for:
   - `/`
   - `/gopal-mandir`
   - `/laddu-gopal`
   - `/gopal-ji-mathura`

## Bing Webmaster Tools

1. Open [Bing Webmaster Tools](https://www.bing.com/webmasters/about).
2. Import property from Search Console or add manually.
3. Verify ownership.
4. Submit sitemap: `https://gopal-mandir-app.web.app/sitemap.xml`.
5. Run URL submission for all key URLs listed above.

## Verification Notes

- If using HTML file verification, place the file under `web/` so Flutter copies it to web build output.
- After deployment, confirm:
  - `https://gopal-mandir-app.web.app/robots.txt`
  - `https://gopal-mandir-app.web.app/sitemap.xml`

## Weekly Checks (First 8 Weeks)

- Index coverage errors
- Crawled but not indexed URLs
- Query impressions for:
  - `gopal mandir`
  - `gopal ji`
  - `laddu gopal`
  - `gopal ji mathura`
  - `mathura`
