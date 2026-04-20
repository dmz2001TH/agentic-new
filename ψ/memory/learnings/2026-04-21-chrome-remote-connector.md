# สิ่งที่เรียนรู้
## 2026-04-21 — Chrome Remote Debugging Connector (Playwright & Puppeteer)
- **บริบท**: GOD มอบหมายให้วิจัยวิธีเชื่อมต่อ AI Agent เข้ากับ Google Chrome ที่ทำงานอยู่ เพื่อใช้ session เดิมของ Master Peach โดยไม่ต้อง login ใหม่
- **สิ่งที่เรียนรู้**: สามารถเชื่อมต่อผ่าน Remote Debugging Port (9222) ได้โดยใช้ CDP (Chrome DevTools Protocol) ทั้งใน Playwright และ Puppeteer
- **วิธีใช้**:
  1. เปิด Chrome ด้วย flag: `chrome.exe --remote-debugging-port=9222 --user-data-dir="C:\chrome-dev-profile"`
  2. เชื่อมต่อด้วย Code:

     **Playwright (Node.js)**
     ```javascript
     const { chromium } = require('playwright');
     
     (async () => {
         const browser = await chromium.connectOverCDP('http://localhost:9222');
         const defaultContext = browser.contexts()[0];
         const page = await defaultContext.newPage();
         // ใช้งาน page ตามปกติ
     })();
     ```

     **Playwright (Python)**
     ```python
     from playwright.sync_api import sync_playwright

     with sync_playwright() as p:
         browser = p.chromium.connect_over_cdp("http://localhost:9222")
         context = browser.contexts[0]
         page = context.new_page()
         # ใช้งาน page ตามปกติ
     ```

     **Puppeteer (Node.js)**
     ```javascript
     const puppeteer = require('puppeteer');
     
     (async () => {
         const browser = await puppeteer.connect({ browserURL: 'http://localhost:9222' });
         const pages = await browser.pages();
         const page = pages[0]; // หรือสร้างใหม่
         // ใช้งาน page ตามปกติ
     })();
     ```
- **แหล่งที่มา**: Official Documentation (Playwright/Puppeteer)
- **แท็ก**: #playwright #puppeteer #chrome #remote-debugging #automation #session-hijack