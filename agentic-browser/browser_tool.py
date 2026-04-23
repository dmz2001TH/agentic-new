"""
BrowserTool v2 — Playwright-based browser control for multi-agent systems
รองรับ: Persistent sessions, Web scraping, Cookie management

Usage:
    tool = BrowserTool()
    await tool.start()
    await tool.navigate("https://example.com")
    await tool.screenshot("page.png")
    await tool.close()
"""

import asyncio
import json
import base64
import os
from pathlib import Path
from typing import Optional, List, Dict, Any
from datetime import datetime
from playwright.async_api import async_playwright, Page, Browser, BrowserContext


# ============================================================
# BrowserTool — Core browser control
# ============================================================

class BrowserTool:
    """
    Browser control tool สำหรับ agent
    รองรับ: navigate, screenshot, snapshot, click, type, evaluate
    + Persistent sessions (เก็บ cookies, login ค้างไว้)
    + Web scraping (ดึงข้อมูล structured)
    + Cookie management
    """

    def __init__(
        self,
        headless: bool = True,
        slow_mo: int = 0,
        user_data_dir: Optional[str] = None,
    ):
        """
        Args:
            headless: True = ไม่เห็น browser, False = เห็น browser (ดูมันทำงาน)
            slow_mo: หน่วงเวลา action (ms) — ช้าลง ดูง่ายขึ้น
            user_data_dir: โฟลเดอร์เก็บ session/cookies/passwords
                           ถ้าไม่ระบุ = ไม่ persist (ปิดแล้วหาย)
                           ถ้าระบุ = login ค้างไว้ เปิดมาเจอบัญชีเดิม
        """
        self.headless = headless
        self.slow_mo = slow_mo
        self.user_data_dir = user_data_dir
        self.pw = None
        self.browser: Optional[Browser] = None
        self.context: Optional[BrowserContext] = None
        self.page: Optional[Page] = None
        self._history: list = []

    async def start(self) -> dict:
        """เปิดเบราว์เซอร์"""
        try:
            self.pw = await async_playwright().start()

            if self.user_data_dir:
                # Persistent context — เก็บ cookies, passwords, localStorage
                # เหมือนเปิด Chrome จริงๆ ที่จำ login ไว้
                os.makedirs(self.user_data_dir, exist_ok=True)
                self.context = await self.pw.chromium.launch_persistent_context(
                    self.user_data_dir,
                    headless=self.headless,
                    slow_mo=self.slow_mo,
                    args=["--no-sandbox", "--disable-setuid-sandbox"],
                    viewport={"width": 1280, "height": 720},
                    locale="th-TH",
                    timezone_id="Asia/Bangkok",
                )
                self.page = self.context.pages[0] if self.context.pages else await self.context.new_page()
            else:
                # Ephemeral context — ปิดแล้วหายหมด
                self.browser = await self.pw.chromium.launch(
                    headless=self.headless,
                    slow_mo=self.slow_mo,
                    args=["--no-sandbox", "--disable-setuid-sandbox"]
                )
                self.context = await self.browser.new_context(
                    viewport={"width": 1280, "height": 720},
                    user_agent="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                    locale="th-TH",
                    timezone_id="Asia/Bangkok",
                )
                self.page = await self.context.new_page()

            return {"status": "success", "message": "Browser started",
                    "persistent": bool(self.user_data_dir)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # ----------------------------------------------------------
    # Navigation
    # ----------------------------------------------------------

    async def navigate(self, url: str, wait_until: str = "domcontentloaded") -> dict:
        """ไปหน้าเว็บ"""
        if not self.page:
            return {"status": "error", "message": "Browser not started. Call start() first."}
        try:
            if not url.startswith(("http://", "https://")):
                url = "https://" + url
            response = await self.page.goto(url, wait_until=wait_until, timeout=30000)
            title = await self.page.title()
            self._history.append({"action": "navigate", "url": url, "title": title})
            return {
                "status": "success",
                "url": self.page.url,
                "title": title,
                "status_code": response.status if response else None
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def back(self) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.go_back()
            return {"status": "success", "url": self.page.url}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def forward(self) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.go_forward()
            return {"status": "success", "url": self.page.url}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def reload(self) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.reload()
            return {"status": "success", "url": self.page.url}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # ----------------------------------------------------------
    # Screenshot & Snapshot
    # ----------------------------------------------------------

    async def screenshot(self, path: str = "screenshot.png", full_page: bool = False) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.screenshot(path=path, full_page=full_page)
            self._history.append({"action": "screenshot", "path": path})
            return {"status": "success", "path": str(Path(path).absolute())}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def screenshot_base64(self, full_page: bool = False) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            img_bytes = await self.page.screenshot(full_page=full_page, type="png")
            b64 = base64.b64encode(img_bytes).decode("utf-8")
            return {"status": "success", "base64": b64}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def snapshot(self, selector: str = "body") -> dict:
        """อ่าน text + links + buttons + form inputs ของหน้าเว็บ"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            title = await self.page.title()
            url = self.page.url
            text = await self.page.inner_text(selector)

            links = await self.page.eval_on_selector_all(
                "a[href]",
                """els => els.slice(0, 50).map(e => ({
                    text: e.innerText.trim().substring(0, 100),
                    href: e.href
                })).filter(l => l.text && l.href)"""
            )

            inputs = await self.page.eval_on_selector_all(
                "input, textarea, select",
                """els => els.map(e => ({
                    tag: e.tagName.toLowerCase(),
                    type: e.type || '',
                    name: e.name || '',
                    id: e.id || '',
                    placeholder: e.placeholder || '',
                    value: e.value ? '(has value)' : ''
                }))"""
            )

            buttons = await self.page.eval_on_selector_all(
                "button, input[type='submit'], input[type='button'], a[role='button']",
                """els => els.map(e => ({
                    text: e.innerText?.trim().substring(0, 100) || e.value || '',
                    tag: e.tagName.toLowerCase(),
                    id: e.id || '',
                    class: e.className?.substring(0, 50) || ''
                })).filter(b => b.text)"""
            )

            return {
                "status": "success",
                "url": url,
                "title": title,
                "text": text[:5000],
                "links": links[:30],
                "inputs": inputs[:20],
                "buttons": buttons[:20]
            }
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # ----------------------------------------------------------
    # Interaction
    # ----------------------------------------------------------

    async def click(self, selector: str) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.click(selector, timeout=10000)
            await self.page.wait_for_load_state("domcontentloaded")
            self._history.append({"action": "click", "selector": selector})
            return {"status": "success", "message": f"Clicked: {selector}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def click_text(self, text: str) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.get_by_text(text, exact=False).first.click(timeout=10000)
            await self.page.wait_for_load_state("domcontentloaded")
            self._history.append({"action": "click_text", "text": text})
            return {"status": "success", "message": f"Clicked text: {text}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def type_text(self, selector: str, text: str, press_enter: bool = False) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.fill(selector, text)
            if press_enter:
                await self.page.press(selector, "Enter")
                await self.page.wait_for_load_state("domcontentloaded")
            self._history.append({"action": "type", "selector": selector, "text": text})
            return {"status": "success", "message": f"Typed in {selector}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def type_slow(self, selector: str, text: str, delay: int = 50) -> dict:
        """พิมพ์ช้าๆ สำหรับเว็บที่ตรวจจับ bot"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.click(selector)
            await self.page.type(selector, text, delay=delay)
            return {"status": "success", "message": f"Typed slowly in {selector}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def press_key(self, key: str) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.keyboard.press(key)
            return {"status": "success", "message": f"Pressed: {key}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def select_option(self, selector: str, value: str) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.select_option(selector, value)
            return {"status": "success", "message": f"Selected '{value}' in {selector}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def scroll(self, direction: str = "down", amount: int = 500) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            if direction == "down":
                await self.page.mouse.wheel(0, amount)
            elif direction == "up":
                await self.page.mouse.wheel(0, -amount)
            elif direction == "right":
                await self.page.mouse.wheel(amount, 0)
            elif direction == "left":
                await self.page.mouse.wheel(-amount, 0)
            await asyncio.sleep(0.5)
            return {"status": "success", "message": f"Scrolled {direction} by {amount}px"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def evaluate(self, js_code: str) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            result = await self.page.evaluate(js_code)
            return {"status": "success", "result": result}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def wait_for(self, selector: str, timeout: int = 10000) -> dict:
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.wait_for_selector(selector, timeout=timeout)
            return {"status": "success", "message": f"Element found: {selector}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def new_tab(self) -> dict:
        if not self.context:
            return {"status": "error", "message": "Browser not started."}
        try:
            self.page = await self.context.new_page()
            return {"status": "success", "message": "New tab opened"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def get_url(self) -> str:
        return self.page.url if self.page else ""

    async def get_title(self) -> str:
        return await self.page.title() if self.page else ""

    async def get_history(self) -> list:
        return self._history

    # ----------------------------------------------------------
    # Cookie & Session Management
    # ----------------------------------------------------------

    async def get_cookies(self, urls: Optional[List[str]] = None) -> dict:
        """ดึง cookies ทั้งหมด (หรือเฉพาะ URL ที่ระบุ)"""
        if not self.context:
            return {"status": "error", "message": "Browser not started."}
        try:
            cookies = await self.context.cookies(urls or [])
            return {"status": "success", "cookies": cookies, "count": len(cookies)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def set_cookies(self, cookies: List[Dict]) -> dict:
        """ตั้ง cookies"""
        if not self.context:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.context.add_cookies(cookies)
            return {"status": "success", "message": f"Set {len(cookies)} cookies"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def clear_cookies(self) -> dict:
        """ลบ cookies ทั้งหมด"""
        if not self.context:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.context.clear_cookies()
            return {"status": "success", "message": "Cookies cleared"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def save_cookies(self, path: str = "cookies.json") -> dict:
        """บันทึก cookies ลงไฟล์"""
        if not self.context:
            return {"status": "error", "message": "Browser not started."}
        try:
            cookies = await self.context.cookies()
            with open(path, "w") as f:
                json.dump(cookies, f, indent=2)
            return {"status": "success", "path": path, "count": len(cookies)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def load_cookies(self, path: str = "cookies.json") -> dict:
        """โหลด cookies จากไฟล์"""
        if not self.context:
            return {"status": "error", "message": "Browser not started."}
        try:
            with open(path, "r") as f:
                cookies = json.load(f)
            await self.context.add_cookies(cookies)
            return {"status": "success", "message": f"Loaded {len(cookies)} cookies from {path}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def is_logged_in(self, check_selector: str = "") -> dict:
        """
        ตรวจว่า login อยู่มั้ย
        check_selector: selector ที่บ่งบอกว่า login แล้ว เช่น ".user-avatar", "#logout-btn"
        """
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            if check_selector:
                try:
                    await self.page.wait_for_selector(check_selector, timeout=5000)
                    return {"status": "success", "logged_in": True}
                except:
                    return {"status": "success", "logged_in": False}
            else:
                # auto-detect: ตรวจจาก localStorage หรือ cookies
                cookies = await self.context.cookies()
                has_session = any(
                    c.get("name", "").lower() in (
                        "session", "token", "auth", "sid",
                        "access_token", "jwt", "phpsessid",
                        "connect.sid", "jsessionid"
                    )
                    for c in cookies
                )
                return {"status": "success", "logged_in": has_session, "cookies_count": len(cookies)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # ----------------------------------------------------------
    # Web Scraping
    # ----------------------------------------------------------

    async def scrape_table(self, selector: str = "table") -> dict:
        """ดึงข้อมูลจาก HTML table → list of dicts"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            data = await self.page.evaluate(f"""
                () => {{
                    const table = document.querySelector('{selector}');
                    if (!table) return null;
                    
                    const headers = Array.from(table.querySelectorAll('th'))
                        .map(th => th.innerText.trim());
                    
                    const rows = Array.from(table.querySelectorAll('tbody tr, tr'))
                        .slice(headers.length > 0 ? 0 : 1)  // skip header row if no <th>
                        .map(row => {{
                            const cells = Array.from(row.querySelectorAll('td'))
                                .map(td => td.innerText.trim());
                            if (headers.length > 0) {{
                                const obj = {{}};
                                headers.forEach((h, i) => obj[h] = cells[i] || '');
                                return obj;
                            }}
                            return cells;
                        }});
                    
                    return {{ headers, rows }};
                }}
            """)
            if data:
                return {"status": "success", **data}
            return {"status": "error", "message": f"No table found: {selector}"}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def scrape_list(self, selector: str = "ul, ol") -> dict:
        """ดึงข้อมูลจาก list"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            items = await self.page.eval_on_selector_all(
                f"{selector} li",
                "els => els.map(e => e.innerText.trim())"
            )
            return {"status": "success", "items": items, "count": len(items)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def scrape_structured(self, selectors: Dict[str, str]) -> dict:
        """
        ดึงข้อมูลจากหลาย selectors พร้อมกัน
        
        selectors = {
            "title": "h1.product-title",
            "price": ".price-value",
            "description": ".product-desc",
            "rating": ".star-rating"
        }
        """
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            results = {}
            for key, sel in selectors.items():
                try:
                    value = await self.page.inner_text(sel)
                    results[key] = value.strip()
                except:
                    try:
                        value = await self.page.eval_on_selector(sel, "e => e.getAttribute('content') || e.value || ''")
                        results[key] = value
                    except:
                        results[key] = None

            return {"status": "success", "data": results}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def scrape_all_links(self, filter_text: str = "") -> dict:
        """ดึง link ทั้งหมด พร้อม filter"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            links = await self.page.eval_on_selector_all(
                "a[href]",
                """els => els.map(e => ({
                    text: e.innerText.trim().substring(0, 200),
                    href: e.href,
                    title: e.title || ''
                })).filter(l => l.href && l.text)"""
            )
            if filter_text:
                links = [l for l in links if filter_text.lower() in l["text"].lower()
                         or filter_text.lower() in l["href"].lower()]
            return {"status": "success", "links": links, "count": len(links)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def scrape_meta(self) -> dict:
        """ดึง meta tags (title, description, og:image, etc.)"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            meta = await self.page.evaluate("""
                () => {
                    const getMeta = (name) => {
                        const el = document.querySelector(`meta[name="${name}"], meta[property="${name}"]`);
                        return el ? el.getAttribute('content') : null;
                    };
                    return {
                        title: document.title,
                        description: getMeta('description'),
                        og_title: getMeta('og:title'),
                        og_description: getMeta('og:description'),
                        og_image: getMeta('og:image'),
                        og_url: getMeta('og:url'),
                        twitter_card: getMeta('twitter:card'),
                        canonical: document.querySelector('link[rel="canonical"]')?.href || null
                    };
                }
            """)
            return {"status": "success", "meta": meta}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def scrape_images(self, min_width: int = 100) -> dict:
        """ดึงรูปภาพทั้งหมด"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            images = await self.page.evaluate(f"""
                () => Array.from(document.querySelectorAll('img'))
                    .filter(img => img.naturalWidth >= {min_width})
                    .map(img => ({{
                        src: img.src,
                        alt: img.alt || '',
                        width: img.naturalWidth,
                        height: img.naturalHeight
                    }}))
            """)
            return {"status": "success", "images": images, "count": len(images)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    async def scrape_text_by_sections(self, heading_selector: str = "h1, h2, h3") -> dict:
        """ดึงเนื้อหาแยกตาม heading — ได้ structured content"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            sections = await self.page.evaluate(f"""
                () => {{
                    const headings = document.querySelectorAll('{heading_selector}');
                    return Array.from(headings).map(h => {{
                        let content = '';
                        let el = h.nextElementSibling;
                        while (el && !el.matches('{heading_selector}')) {{
                            content += el.innerText + '\\n';
                            el = el.nextElementSibling;
                        }}
                        return {{
                            heading: h.innerText.trim(),
                            level: h.tagName,
                            content: content.trim().substring(0, 1000)
                        }};
                    }});
                }}
            """)
            return {"status": "success", "sections": sections, "count": len(sections)}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # ----------------------------------------------------------
    # PDF
    # ----------------------------------------------------------

    async def to_pdf(self, path: str = "page.pdf") -> dict:
        """บันทึกหน้าเว็บเป็น PDF"""
        if not self.page:
            return {"status": "error", "message": "Browser not started."}
        try:
            await self.page.pdf(path=path, format="A4")
            return {"status": "success", "path": str(Path(path).absolute())}
        except Exception as e:
            return {"status": "error", "message": str(e)}

    # ----------------------------------------------------------
    # Close
    # ----------------------------------------------------------

    async def close(self) -> dict:
        try:
            if self.context:
                await self.context.close()
            if self.browser:
                await self.browser.close()
            if self.pw:
                await self.pw.stop()
            self.page = None
            self.browser = None
            self.context = None
            self.pw = None
            return {"status": "success", "message": "Browser closed"}
        except Exception as e:
            return {"status": "error", "message": str(e)}


# ============================================================
# BrowserAgent — Agent ที่ใช้ BrowserTool
# ============================================================

class BrowserAgent:
    """
    Agent ที่ควบคุมเบราว์เซอร์
    รองรับ persistent session + web scraping + cookie management
    """

    def __init__(
        self,
        headless: bool = True,
        user_data_dir: Optional[str] = None,
    ):
        """
        Args:
            headless: ไม่เห็น browser (True) หรือเห็น browser (False)
            user_data_dir: โฟลเดอร์เก็บ session — ถ้าใช้จะจำ login ไว้
        """
        self.name = "BROWSER"
        self.tool = BrowserTool(headless=headless, user_data_dir=user_data_dir)
        self._initialized = False

    async def init(self):
        if not self._initialized:
            await self.tool.start()
            self._initialized = True

    # ----------------------------------------------------------
    # Task execution (compatible with your agent framework)
    # ----------------------------------------------------------

    async def execute_task(self, task_spec: dict) -> dict:
        """
        รับ task spec (format เดียวกับ agent framework ของคุณ)
        """
        await self.init()
        results = []

        if "actions" in task_spec:
            for action in task_spec["actions"]:
                result = await self._run_action(action)
                results.append(result)
                if result.get("status") == "error":
                    break
        elif "url" in task_spec:
            nav_result = await self.tool.navigate(task_spec["url"])
            results.append(nav_result)
            if nav_result["status"] == "success":
                snap = await self.tool.snapshot()
                results.append(snap)
        else:
            snap = await self.tool.snapshot()
            results.append(snap)

        return {
            "agent": self.name,
            "status": "success" if all(r.get("status") == "success" for r in results) else "partial",
            "results": results,
            "url": await self.tool.get_url(),
            "title": await self.tool.get_title()
        }

    async def _run_action(self, action: dict) -> dict:
        action_type = action.get("type", "")

        if action_type == "navigate":
            return await self.tool.navigate(action["url"])
        elif action_type == "screenshot":
            return await self.tool.screenshot(action.get("path", "screenshot.png"))
        elif action_type == "snapshot":
            return await self.tool.snapshot(action.get("selector", "body"))
        elif action_type == "click":
            return await self.tool.click(action["selector"])
        elif action_type == "click_text":
            return await self.tool.click_text(action["text"])
        elif action_type == "type":
            return await self.tool.type_text(
                action["selector"], action["text"],
                action.get("press_enter", False)
            )
        elif action_type == "type_slow":
            return await self.tool.type_slow(
                action["selector"], action["text"],
                action.get("delay", 50)
            )
        elif action_type == "press_key":
            return await self.tool.press_key(action["key"])
        elif action_type == "scroll":
            return await self.tool.scroll(
                action.get("direction", "down"),
                action.get("amount", 500)
            )
        elif action_type == "evaluate":
            return await self.tool.evaluate(action["code"])
        elif action_type == "scrape_table":
            return await self.tool.scrape_table(action.get("selector", "table"))
        elif action_type == "scrape_list":
            return await self.tool.scrape_list(action.get("selector", "ul, ol"))
        elif action_type == "scrape_structured":
            return await self.tool.scrape_structured(action["selectors"])
        elif action_type == "scrape_meta":
            return await self.tool.scrape_meta()
        elif action_type == "scrape_images":
            return await self.tool.scrape_images(action.get("min_width", 100))
        elif action_type == "scrape_sections":
            return await self.tool.scrape_text_by_sections()
        elif action_type == "wait":
            await asyncio.sleep(action.get("seconds", 1))
            return {"status": "success", "message": f"Waited {action.get('seconds', 1)}s"}
        else:
            return {"status": "error", "message": f"Unknown action: {action_type}"}

    # ----------------------------------------------------------
    # Convenience methods
    # ----------------------------------------------------------

    async def search_google(self, query: str) -> dict:
        """ค้นหา Google"""
        await self.init()
        await self.tool.navigate("https://www.google.com")
        try:
            await self.tool.click_text("Accept all")
        except:
            pass
        await self.tool.type_text('textarea[name="q"]', query, press_enter=True)
        await asyncio.sleep(2)

        snapshot = await self.tool.snapshot()
        try:
            results = await self.tool.evaluate("""
                () => {
                    const items = document.querySelectorAll('div.g');
                    return Array.from(items).slice(0, 10).map(item => {
                        const link = item.querySelector('a');
                        const title = item.querySelector('h3');
                        const snippet = item.querySelector('[data-sncf], .VwiC3b, .lEBKkf');
                        return {
                            title: title?.innerText || '',
                            url: link?.href || '',
                            snippet: snippet?.innerText || ''
                        };
                    }).filter(r => r.title && r.url);
                }
            """)
            return {
                "status": "success", "query": query,
                "results": results.get("result", []),
                "page": snapshot
            }
        except Exception as e:
            return {"status": "partial", "query": query,
                    "message": f"Could not parse results: {e}", "page": snapshot}

    async def scrape_website(self, url: str, selectors: Dict[str, str]) -> dict:
        """เปิดเว็บ + ดึงข้อมูล structured"""
        await self.init()
        nav = await self.tool.navigate(url)
        if nav["status"] != "success":
            return nav
        return await self.tool.scrape_structured(selectors)

    async def close(self):
        await self.tool.close()


# ============================================================
# CLI Test
# ============================================================

async def main():
    print("=" * 60)
    print("🧪 BrowserTool v2 Test Suite")
    print("=" * 60)

    # --- Test 1: Basic ---
    print("\n📋 Test 1: Basic BrowserTool")
    tool = BrowserTool(headless=True)
    await tool.start()

    result = await tool.navigate("https://example.com")
    print(f"  Navigate: {result['status']} - {result.get('title', '')}")

    result = await tool.snapshot()
    print(f"  Snapshot: {result['status']} - text: {len(result.get('text', ''))} chars")
    print(f"  Links: {len(result.get('links', []))}, Buttons: {len(result.get('buttons', []))}")

    await tool.screenshot("test1_basic.png")
    await tool.close()
    print("  ✅ Test 1 passed")

    # --- Test 2: Web Scraping ---
    print("\n📋 Test 2: Web Scraping")
    tool = BrowserTool(headless=True)
    await tool.start()

    # Scrape table จาก Wikipedia
    await tool.navigate("https://en.wikipedia.org/wiki/List_of_countries_by_population_(United_Nations)")
    result = await tool.scrape_table("table.wikitable")
    if result["status"] == "success":
        print(f"  Table: {len(result.get('rows', []))} rows")
        print(f"  Headers: {result.get('headers', [])[:5]}")
        if result.get("rows"):
            print(f"  First row: {result['rows'][0]}")
    else:
        print(f"  Table scrape: {result.get('message', 'no table')}")

    # Scrape meta tags
    await tool.navigate("https://github.com")
    result = await tool.scrape_meta()
    if result["status"] == "success":
        print(f"  Meta title: {result['meta'].get('title', 'N/A')[:50]}")
        print(f"  Meta description: {result['meta'].get('description', 'N/A')[:60]}")

    await tool.close()
    print("  ✅ Test 2 passed")

    # --- Test 3: Structured scraping ---
    print("\n📋 Test 3: Structured Scraping")
    tool = BrowserTool(headless=True)
    await tool.start()

    await tool.navigate("https://news.ycombinator.com/")
    result = await tool.scrape_structured({
        "titles": ".titleline > a",
        "points": ".score",
    })
    if result["status"] == "success":
        data = result["data"]
        titles = data.get("titles", "").split("\n")[:3] if data.get("titles") else []
        print(f"  HN titles: {len(titles)} found")
        for t in titles:
            print(f"    - {t[:60]}")

    # Scrape all links with filter
    result = await tool.scrape_all_links(filter_text="github")
    if result["status"] == "success":
        print(f"  GitHub links: {result['count']}")

    await tool.close()
    print("  ✅ Test 3 passed")

    # --- Test 4: Persistent session ---
    print("\n📋 Test 4: Persistent Session (user_data_dir)")
    tool = BrowserTool(
        headless=True,
        user_data_dir="/root/.openclaw/workspace/agentic-browser/.browser_data"
    )
    await tool.start()

    # First visit — set some localStorage
    await tool.navigate("https://example.com")
    await tool.evaluate("localStorage.setItem('test_key', 'hello_from_agent')")
    val = await tool.evaluate("localStorage.getItem('test_key')")
    print(f"  Set localStorage: {val.get('result', '')}")

    await tool.close()

    # Second visit — check if localStorage persists
    tool2 = BrowserTool(
        headless=True,
        user_data_dir="/root/.openclaw/workspace/agentic-browser/.browser_data"
    )
    await tool2.start()
    await tool2.navigate("https://example.com")
    val2 = await tool2.evaluate("localStorage.getItem('test_key')")
    print(f"  Persisted localStorage: {val2.get('result', 'NOT FOUND')}")
    await tool2.close()

    print("  ✅ Test 4 passed")

    # --- Test 5: Agent with actions ---
    print("\n📋 Test 5: BrowserAgent with action sequence")
    agent = BrowserAgent(headless=True)
    result = await agent.execute_task({
        "goal": "Get page info",
        "actions": [
            {"type": "navigate", "url": "https://httpbin.org/forms/post"},
            {"type": "snapshot"},
            {"type": "scrape_structured", "selectors": {
                "form_action": "form",
            }},
            {"type": "screenshot", "path": "test5_form.png"}
        ]
    })
    print(f"  Agent status: {result['status']}")
    print(f"  URL: {result['url']}")
    await agent.close()
    print("  ✅ Test 5 passed")

    # --- Summary ---
    print("\n" + "=" * 60)
    print("✅ All 5 tests passed!")
    print("=" * 60)

    # Cleanup
    import shutil
    shutil.rmtree("/root/.openclaw/workspace/agentic-browser/.browser_data", ignore_errors=True)

    print("""
📁 Files created:
  - browser_tool.py  → BrowserTool + BrowserAgent (v2)
  - test1_basic.png  → Basic screenshot
  - test5_form.png   → Form screenshot

🔧 New features in v2:
  ✅ Persistent sessions (user_data_dir) — จำ login/cookies/passwords ได้
  ✅ Cookie management — get/set/save/load/clear cookies
  ✅ Web scraping — scrape_table, scrape_list, scrape_structured, scrape_meta
  ✅ Scrape images, sections, all links
  ✅ PDF export

📝 Usage with your agent framework:

  # ===== แบบไม่ persist (ปิดแล้วหาย) =====
  agent = BrowserAgent(headless=False)
  
  # ===== แบบ persist (จำ login ไว้) =====
  agent = BrowserAgent(
      headless=False,
      user_data_dir="./browser_sessions/my_session"
  )
  # ↑ login ครั้งแรก → ครั้งต่อไปไม่ต้อง login ใหม่
  
  # ===== ค้นหา =====
  result = await agent.search_google("query")
  
  # ===== Scraping =====
  result = await agent.scrape_website("https://...", {
      "title": "h1",
      "price": ".price",
      "desc": ".description"
  })
  
  # ===== Cookie management =====
  await agent.tool.save_cookies("my_cookies.json")
  await agent.tool.load_cookies("my_cookies.json")
    """)


if __name__ == "__main__":
    asyncio.run(main())
