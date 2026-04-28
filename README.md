# obscura-cdp

Docker image wrapping [Obscura](https://github.com/h4ckf0r0day/obscura) — a lightweight Rust headless browser — with a reverse proxy that makes its CDP endpoint accessible remotely.

Obscura exposes Chrome DevTools Protocol (CDP) only on `127.0.0.1`. This image adds an nginx reverse proxy that rewrites the `webSocketDebuggerUrl` so tools like Playwright can connect from a remote machine (e.g. over Tailscale).

## Why

| | Obscura | Chrome headless |
|---|---|---|
| RAM | ~30 MB | ~200 MB |
| Startup | ~85 ms | ~500 ms |
| Anti-fingerprint | built-in | manual |
| CDP completeness | partial (v0.1.x) | full |

## Quick start

```bash
docker run -d \
  --name obscura \
  --restart unless-stopped \
  -p 9223:9223 \
  ghcr.io/painteau/obscura-cdp:latest
```

CDP endpoint: `http://<host>:9223`

## Usage with Playwright (Python)

```python
from playwright.async_api import async_playwright

async with async_playwright() as p:
    browser = await p.chromium.connect_over_cdp("http://localhost:9223")
    page = await browser.new_page()
    await page.goto("https://example.com")
    print(await page.title())
    await browser.close()
```

## Usage with Playwright (Node.js)

```js
const { chromium } = require('playwright');

const browser = await chromium.connectOverCDP('http://localhost:9223');
const page = await browser.newPage();
await page.goto('https://example.com');
console.log(await page.title());
await browser.close();
```

## Docker Compose

```yaml
services:
  obscura:
    image: ghcr.io/painteau/obscura-cdp:latest
    restart: unless-stopped
    ports:
      - "9223:9223"
```

## Architecture

```
Remote client (Playwright / script)
        |
        | HTTP/WS :9223
        v
    nginx (rewrites webSocketDebuggerUrl)
        |
        | :9222 (localhost only)
        v
    Obscura (CDP server)
```

Obscura binds CDP only on `127.0.0.1:9222`. nginx proxies port 9223 and rewrites the WebSocket URL in `/json/version` so remote clients get a reachable address instead of `ws://127.0.0.1:9222`.

## Known limitations

Obscura v0.1.x implements a subset of CDP. The following are not yet supported:

- `Page.getLayoutMetrics` → `page.screenshot()` fails
- Some advanced DOM/JS APIs

Basic navigation, scraping, and form interaction work.

## Building locally

```bash
docker build -t obscura-cdp .
```

## License

MIT — see [LICENSE](LICENSE).

Obscura is developed by [@h4ckf0r0day](https://github.com/h4ckf0r0day) and has its own license.
