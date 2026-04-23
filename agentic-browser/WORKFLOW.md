# 🌐 Browser Agent — Workflow

## Architecture รวม

```
                         ┌──────────────┐
                         │    USER      │
                         │  "หาข้อมูล X" │
                         └──────┬───────┘
                                │
                                ▼
                         ┌──────────────┐
                         │  JARVIS      │ ← Gateway รับ input
                         │  (Gateway)   │
                         └──────┬───────┘
                                │
                                ▼
                         ┌──────────────┐
                         │     GOD      │ ← วางแผน: "ต้องค้นหาเว็บ"
                         │  (Planner)   │
                         └──────┬───────┘
                                │ dispatch
           ┌────────────────────┼────────────────────┐
           ▼                    ▼                    ▼
   ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
   │  RESEARCHER  │    │   BROWSER    │    │    CODER     │
   │  วิเคราะห์   │◄──►│  ค้นหาเว็บ   │    │  เขียนโค้ด   │
   │  ข้อมูล      │    │  scrape ข้อมูล│    │              │
   └──────┬───────┘    └──────┬───────┘    └──────────────┘
          │                   │
          └─────────┬─────────┘
                    ▼
             ┌──────────────┐
             │   REVIEWER   │ ← ตรวจผลลัพธ์
             │   ตรวจสอบ    │
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │     GOD      │ ← รวมผล → ส่งกลับ user
             └──────┬───────┘
                    │
                    ▼
             ┌──────────────┐
             │    USER      │
             │  "นี่คือผล"   │
             └──────────────┘
```

---

## Workflow 1: ค้นหาข้อมูล (Search)

```
User: "Python async ทำงานยังไง?"
         │
         ▼
    GOD วิเคราะห์ → "ต้องค้นหาเว็บ"
         │
         ▼
    ┌─────────────────────────────────────────┐
    │  BROWSER AGENT                          │
    │                                         │
    │  1. navigate → google.com               │
    │  2. type → "Python async tutorial"      │
    │  3. wait → 2 วินาที                      │
    │  4. snapshot → อ่านผลลัพธ์               │
    │  5. click → ผลลัพธ์แรก                   │
    │  6. snapshot → อ่านเนื้อหา               │
    │  7. screenshot → 保存หลักฐาน            │
    │                                         │
    │  ส่งกลับ:                               │
    │  {                                      │
    │    "title": "Async IO in Python",       │
    │    "content": "Python's asyncio...",    │
    │    "links": [...],                      │
    │    "screenshot": "result.png"           │
    │  }                                      │
    └─────────────────────────────────────────┘
         │
         ▼
    GOD → RESEARCHER → สรุปข้อมูล → ส่งกลับ user
```

---

## Workflow 2: Scraping ข้อมูล (ดึงข้อมูล structured)

```
User: "ดึงราคาสินค้าจากเว็บนี้ https://..."
         │
         ▼
    GOD วิเคราะห์ → "ต้อง scrape ข้อมูล"
         │
         ▼
    ┌─────────────────────────────────────────┐
    │  BROWSER AGENT                          │
    │                                         │
    │  1. navigate → เว็บสินค้า                │
    │  2. scrape_structured({                 │
    │       "name": "h1.product-title",      │
    │       "price": ".price-value",          │
    │       "rating": ".star-rating",         │
    │       "stock": ".stock-status"          │
    │     })                                  │
    │  3. screenshot → 保存หลักฐาน            │
    │                                         │
    │  ส่งกลับ:                               │
    │  {                                      │
    │    "name": "iPhone 16 Pro",             │
    │    "price": "฿42,900",                  │
    │    "rating": "4.8/5",                   │
    │    "stock": "มีสินค้า"                   │
    │  }                                      │
    └─────────────────────────────────────────┘
         │
         ▼
    GOD → ส่งกลับ user ตรงๆ (ไม่ต้องผ่าน agent อื่น)
```

---

## Workflow 3: Login + ทำ task (ใช้ persistent session)

```
User: "เข้า Shopee เช็คคำสั่งซื้อล่าสุด"
         │
         ▼
    GOD วิเคราะห์ → "ต้อง login ก่อน"
         │
         ▼
    ┌─────────────────────────────────────────┐
    │  BROWSER AGENT (persistent session)     │
    │                                         │
    │  1. navigate → shopee.co.th             │
    │  2. is_logged_in()                      │
    │     ├─ YES → ไปข้อ 5                    │
    │     └─ NO →                             │
    │         3. click "เข้าสู่ระบบ"           │
    │         4. type → email + password       │
    │             (จาก user_data_dir ที่จำไว้) │
    │         5. navigate → orders page        │
    │         6. snapshot → อ่านคำสั่งซื้อ      │
    │         7. screenshot → 保存              │
    │                                         │
    │  ส่งกลับ:                               │
    │  {                                      │
    │    "orders": [                          │
    │      {"id": "...", "status": "จัดส่งแล้ว"},│
    │      {"id": "...", "status": "รอดำเนินการ"} │
    │    ]                                    │
    │  }                                      │
    └─────────────────────────────────────────┘
         │
         ▼
    GOD → ส่งกลับ user
```

---

## Workflow 4: Multi-agent ทำงานร่วมกัน

```
User: "สรุปข่าวเทคโนโลยีวันนี้ แล้วเขียนบล็อกโพสต์"
         │
         ▼
    GOD วางแผน:
    "1. BROWSER หาข่าว → 2. RESEARCHER วิเคราะห์ → 3. CODER เขียน"
         │
         ▼
    ┌─────────────────────────────────────────┐
    │  BROWSER AGENT                          │
    │  1. navigate → news.ycombinator.com     │
    │  2. scrape_structured({                 │
    │       "titles": ".titleline > a",       │
    │       "points": ".score"                │
    │     })                                  │
    │  3. navigate → techcrunch.com           │
    │  4. scrape_text_by_sections("h2, h3")   │
    │  5. screenshot ทั้งหมด                   │
    │                                         │
    │  ส่งกลับ: { news: [...], sections: [...] }
    └─────────────────────────────────────────┘
         │
         ▼
    ┌─────────────────────────────────────────┐
    │  RESEARCHER                             │
    │  - วิเคราะห์ข่าวที่ BROWSER หามา         │
    │  - เรียงลำดับความสำคัญ                   │
    │  - สรุป key points                      │
    │                                         │
    │  ส่งกลับ: { summary: [...], key_points: [...] }
    └─────────────────────────────────────────┘
         │
         ▼
    ┌─────────────────────────────────────────┐
    │  CODER (เขียนบล็อก)                      │
    │  - เขียน Markdown จาก summary           │
    │  - ใส่ link แหล่งที่มา                   │
    │                                         │
    │  ส่งกลับ: { blog_post: "..." }           │
    └─────────────────────────────────────────┘
         │
         ▼
    GOD → REVIEWER ตรวจ → ส่งกลับ user
```

---

## วิธีสั่งงาน (User → GOD → BROWSER)

### ผ่าน GOD agent:

```python
# god_agent.py

class GodAgent:
    def __init__(self):
        self.browser = BrowserAgent(
            headless=False,
            user_data_dir="./browser_sessions/main"
        )
        self.researcher = ResearcherAgent()
        self.coder = CoderAgent()

    async def handle(self, user_input: str):
        task_type = self._classify(user_input)

        if task_type == "search":
            # BROWSER ค้นหา → RESEARCHER สรุป
            search_result = await self.browser.search_google(user_input)
            summary = await self.researcher.summarize(search_result)
            return summary

        elif task_type == "scrape":
            # BROWSER scrape ข้อมูล
            result = await self.browser.execute_task({
                "goal": user_input,
                "actions": self._plan_scrape(user_input)
            })
            return result

        elif task_type == "browse_and_write":
            # BROWSER หาข้อมูล → CODER เขียน
            data = await self.browser.search_google(user_input)
            article = await self.coder.write_article(data)
            return article

        # ... handle other types ...
```

### ผ่าน CLI (god-dispatch):

```bash
# สั่งผ่าน GOD
python god.py "หาข้อมูล Python async แล้วสรุปให้หน่อย"

# สั่ง BROWSER ตรง
python browser_tool.py --task "search" --query "Python async"

# สั่ง scrape
python browser_tool.py --task "scrape" --url "https://..." --selectors '{"title": "h1"}'
```
