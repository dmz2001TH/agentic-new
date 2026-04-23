# 🌐 Agentic Browser — Browser Tool for Multi-Agent System

Playwright-based browser control สำหรับ agent framework ของคุณ

## 📦 ติดตั้ง

```bash
pip install playwright
playwright install chromium
playwright install-deps chromium  # Linux only
```

## 🚀 วิธีใช้

### ใช้ BrowserTool ตรงๆ

```python
import asyncio
from browser_tool import BrowserTool

async def main():
    tool = BrowserTool(headless=False)  # headless=False = เห็น browser
    await tool.start()

    # ไปหน้าเว็บ
    await tool.navigate("https://example.com")

    # อ่านเนื้อหา
    snapshot = await tool.snapshot()
    print(snapshot["text"])
    print(snapshot["links"])

    # ถ่าย screenshot
    await tool.screenshot("result.png")

    # คลิก + พิมพ์
    await tool.click("a.some-link")
    await tool.type_text("input[name='q']", "search query", press_enter=True)

    # รัน JavaScript
    result = await tool.evaluate("document.title")

    await tool.close()

asyncio.run(main())
```

### ใช้ BrowserAgent (มี search + task runner)

```python
import asyncio
from browser_tool import BrowserAgent

async def main():
    agent = BrowserAgent(headless=False)

    # ค้นหา Google
    result = await agent.search_google("Python async best practices")
    for r in result["results"]:
        print(f"  {r['title']}: {r['url']}")

    # ทำ task ตามลำดับ
    task = {
        "goal": "ดึงข้อมูลจากเว็บ",
        "actions": [
            {"type": "navigate", "url": "https://example.com"},
            {"type": "snapshot"},
            {"type": "screenshot", "path": "output.png"}
        ]
    }
    result = await agent.execute_task(task)

    await agent.close()

asyncio.run(main())
```

## 📋 Supported Actions

| Action | Description | Example |
|--------|-------------|---------|
| `navigate` | ไปหน้าเว็บ | `{"type": "navigate", "url": "https://..."}` |
| `snapshot` | อ่าน DOM/text | `{"type": "snapshot"}` |
| `screenshot` | ถ่ายภาพหน้าจอ | `{"type": "screenshot", "path": "out.png"}` |
| `click` | คลิก element (CSS selector) | `{"type": "click", "selector": "button"}` |
| `click_text` | คลิกจาก text | `{"type": "click_text", "text": "Submit"}` |
| `type` | พิมพ์ข้อความ | `{"type": "type", "selector": "input", "text": "..."}` |
| `press_key` | กดปุ่ม | `{"type": "press_key", "key": "Enter"}` |
| `scroll` | เลื่อนหน้า | `{"type": "scroll", "direction": "down"}` |
| `evaluate` | รัน JavaScript | `{"type": "evaluate", "code": "..."}` |
| `wait` | รอ | `{"type": "wait", "seconds": 2}` |

## 📐 Integrate เข้า Agent Framework

```python
# ใน GOD agent — dispatch ไป BROWSER agent

async def dispatch_to_browser(task_spec):
    from browser_tool import BrowserAgent
    agent = BrowserAgent(headless=True)
    result = await agent.execute_task(task_spec)
    await agent.close()
    return result

# GOD dispatch
task = {
    "goal": "ค้นหา API docs สำหรับ FastAPI",
    "actions": [
        {"type": "navigate", "url": "https://google.com"},
        {"type": "type", "selector": "textarea[name='q']",
         "text": "FastAPI official documentation", "press_enter": True},
        {"type": "wait", "seconds": 2},
        {"type": "snapshot"}
    ]
}
result = await dispatch_to_browser(task)
```

## 📁 ไฟล์ในโปรเจกต์

```
agentic-browser/
├── browser_tool.py                    ← BrowserTool + BrowserAgent classes
├── agents/browser/SOUL.md             ← Agent definition สำหรับ framework
├── README.md                          ← ไฟล์นี้
├── test_screenshot.png                ← ผลลัพธ์จาก test
├── agent_screenshot.png               ← ผลลัพธ์จาก agent test
└── form_filled.png                    ← ผลลัพธ์จาก form test
```

## 🧪 ทดสอบ

```bash
cd agentic-browser
python3 browser_tool.py
```

## 📚 References

- [Playwright Python Docs](https://playwright.dev/python/)
- [Playwright Selectors](https://playwright.dev/python/selectors)
- [Chrome DevTools Protocol](https://chromedevtools.github.io/devtools-protocol/)
