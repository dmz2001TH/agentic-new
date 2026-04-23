# 📋 HANDOFF — Browser Agent Integration
> **Date:** 2026-04-24 01:04 GMT+8
> **From:** OpenClaw Agent (external collaborator)
> **To:** Next agent continuing this work
> **Repo:** https://github.com/dmz2001TH/agentic-new

---

## ✅ สิ่งที่เสร็จแล้ว

### 1. BrowserTool (`browser_tool.py`)
- [x] **BrowserTool class** — Playwright-based browser control
  - [x] `navigate(url)` — ไปหน้าเว็บ
  - [x] `screenshot(path)` / `screenshot_base64()` — ถ่ายภาพ
  - [x] `snapshot()` — อ่าน text + links + buttons + inputs
  - [x] `click(selector)` / `click_text(text)` — คลิก
  - [x] `type_text(selector, text)` / `type_slow()` — พิมพ์
  - [x] `press_key(key)` — กด keyboard
  - [x] `select_option(selector, value)` — dropdown
  - [x] `scroll(direction, amount)` — เลื่อนหน้า
  - [x] `evaluate(js_code)` — รัน JavaScript
  - [x] `wait_for(selector)` — รอ element
  - [x] `back()` / `forward()` / `reload()` — navigation
  - [x] `to_pdf(path)` — export PDF

### 2. Persistent Sessions
- [x] `user_data_dir` — เก็บ cookies/passwords/localStorage ข้าม session
- [x] `get_cookies()` / `set_cookies()` / `clear_cookies()`
- [x] `save_cookies(path)` / `load_cookies(path)` — บันทึก/โหลด cookies
- [x] `is_logged_in(check_selector)` — ตรวจ login status

### 3. Web Scraping
- [x] `scrape_table(selector)` — ดึงข้อมูลจาก HTML table → list of dicts
- [x] `scrape_list(selector)` — ดึงข้อมูลจาก list
- [x] `scrape_structured(selectors)` — ดึงข้อมูลจากหลาย CSS selectors
- [x] `scrape_meta()` — ดึง meta tags (title, description, og:*)
- [x] `scrape_images(min_width)` — ดึงรูปภาพ
- [x] `scrape_text_by_sections(heading_selector)` — เนื้อหาแยกตาม heading
- [x] `scrape_all_links(filter_text)` — link ทั้งหมด + filter

### 4. BrowserAgent (`browser_agent.py`)
- [x] `execute_task(task_spec)` — รับ task spec (format เดียวกับ agent framework)
- [x] `search_google(query)` — ค้นหา Google + ดึงผลลัพธ์
- [x] `scrape_website(url, selectors)` — เปิดเว็บ + scrape
- [x] Action sequence support — ทำหลาย step ตามลำดับ

### 5. GOD Agent Integration (`god_agent.py`)
- [x] `GodAgent` class — orchestrator ที่ dispatch ไป BROWSER
- [x] `_classify()` — จำแนก task type (search/scrape/read_page/compare)
- [x] `_do_search()` — search workflow
- [x] `_do_scrape()` — scrape workflow
- [x] `_do_read_page()` — read page workflow
- [x] `_do_compare()` — multi-page compare workflow
- [x] 4 demo workflows ทำงานผ่าน

### 6. Demo & Tests
- [x] `browser_tool.py` — 5 tests ผ่าน (basic, agent, google, form, persistent)
- [x] `demo_visible.py` — 3 demo modes (headless, visible, agent)
- [x] `god_agent.py` — 4 workflow demos ผ่าน
- [x] Screenshots ทุก test

### 7. Documentation
- [x] `README.md` — คู่มือการใช้งาน + ตัวอย่าง
- [x] `WORKFLOW.md` — workflow diagrams (search, scrape, login, multi-agent)
- [x] `agents/browser/SOUL.md` — agent definition สำหรับ framework
- [x] `HANDOFF-2026-04-24-BROWSER-AGENT.md` — ไฟล์นี้

---

## 📁 ไฟล์ที่เพิ่มเข้ามา

```
agentic-new/
└── agentic-browser/              ← [NEW] Browser Agent Module
    ├── browser_tool.py           ← BrowserTool + BrowserAgent classes (v2)
    ├── god_agent.py              ← GOD Agent demo — workflow 4 ตัว
    ├── demo_visible.py           ← Demo 3 modes (headless/visible/agent)
    ├── README.md                 ← คู่มือ
    ├── WORKFLOW.md               ← Workflow diagrams
    ├── agents/
    │   └── browser/
    │       └── SOUL.md           ← Agent definition
    └── *.png                     ← Screenshots จาก test
```

---

## 🔧 สิ่งที่ต้องทำต่อ

### Priority 1: Integration เข้า Existing Agents

```python
# 1. เพิ่ม BROWSER agent เข้า GOD-HANDOFF-PROMPT.md
#    - เพิ่ม BROWSER ใน agent roles
#    - เพิ่ม routing logic สำหรับ web-related tasks

# 2. เชื่อมกับ RESEARCHER agent
#    - RESEARCHER ส่ง query → BROWSER ค้นหา → RESEARCHER วิเคราะห์
#    - ใช้ message protocol เดียวกับ agent framework

# 3. เชื่อมกับ MAW (multi-agent-workflow-kit)
#    - เพิ่ม browser agent ใน agents.yaml
#    - maw hey browser "search Python async"
```

### Priority 2: เพิ่ม Features

```python
# 1. Login automation
#    - Auto-login flow (username + password → submit)
#    - 2FA support (ถ้าเป็นไปได้)
#    - Login state detection

# 2. Anti-detection
#    - Random delays between actions
#    - Rotate user agents
#    - Stealth mode (playwright-stealth)

# 3. Error recovery
#    - Auto-retry on timeout
#    - Screenshot on error
#    - Fallback to different selector

# 4. Multi-tab support
#    - เปิดหลาย tab พร้อมกัน
#    - Switch between tabs
#    - Parallel scraping
```

### Priority 3: Production Ready

```python
# 1. Rate limiting
#    - Max requests per minute
#    - Respect robots.txt

# 2. Proxy support
#    - HTTP/SOCKS proxy
#    - Rotate proxies

# 3. Monitoring
#    - Log all actions
#    - Track success/failure rates
#    - Alert on repeated failures

# 4. Config
#    - Load selectors from config file
#    - Per-site scraping profiles
```

---

## 🧪 ผลทดสอบ

| Test | Status | Notes |
|------|--------|-------|
| Basic BrowserTool | ✅ | navigate, snapshot, screenshot, evaluate |
| BrowserAgent actions | ✅ | Action sequence ตามลำดับ |
| Google Search | ✅ | ค้นหา + ดึงผลลัพธ์ (headless อาจถูก block) |
| Form interaction | ✅ | กรอกชื่อ, เบอร์, อีเมล |
| Persistent session | ✅ | localStorage persist ข้าม session |
| Web scraping (table) | ✅ | Wikipedia table → 239 rows |
| Web scraping (meta) | ✅ | GitHub meta tags |
| Web scraping (structured) | ✅ | HN titles + points |
| GOD agent workflow | ✅ | 4 workflows (search/scrape/read/compare) |

---

## 📦 Dependencies

```bash
pip install playwright
playwright install chromium
playwright install-deps chromium  # Linux only
```

---

## 💡 Notes สำหรับ Agent ต่อไป

1. **Google Search ใน headless mode** อาจถูก Google block (anti-bot) — แก้โดยใช้ `user_data_dir` ที่มี session จริง หรือใช้ `headless=False`
2. **Persistent session** ทำงานจริง — localStorage persist ข้าม session ได้ (test 4 ยืนยัน)
3. **Scraping** ทำงานได้ดี — table, meta, structured data, links, images
4. **Action sequence** format เดียวกับ agent framework — ส่งเข้า `execute_task()` ได้เลย
5. **ไฟล์อยู่ใน `agentic-browser/`** — copy ไป integrate เข้า agent ตัวไหนก็ได้

---

## 🔗 Related Files

- `agent-framework/03-ARCHITECTURE.md` — System architecture
- `agent-framework/07-INTEGRATION.md` — Integration guide
- `GOD-HANDOFF-PROMPT.md` — GOD system prompt (ต้องเพิ่ม BROWSER role)
- `multi-agent-workflow-kit/` — MAW framework (ต้องเพิ่ม browser agent)
