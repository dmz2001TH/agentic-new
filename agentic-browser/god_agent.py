"""
GOD Agent — Demo วิธี dispatch ไป BROWSER agent
รันไฟล์นี้เพื่อดู workflow จริง
"""

import asyncio
import json
from browser_tool import BrowserTool, BrowserAgent


# ============================================================
# GOD Agent — Orchestrator (ตัวอย่าง)
# ============================================================

class GodAgent:
    """
    ตัวอย่าง GOD agent ที่ dispatch งานไป BROWSER agent
    """

    def __init__(self, headless=True, user_data_dir=None):
        self.browser = BrowserAgent(
            headless=headless,
            user_data_dir=user_data_dir
        )
        self._tasks_done = []

    async def handle(self, user_input: str) -> dict:
        """รับ input จาก user → วิเคราะห์ → dispatch"""

        print(f"\n{'='*60}")
        print(f"🧠 GOD: รับ request → \"{user_input}\"")
        print(f"{'='*60}")

        # 1. วิเคราะห์ task type
        task_type = self._classify(user_input)
        print(f"📋 GOD: วิเคราะห์ → task type = {task_type}")

        # 2. Dispatch ตาม type
        if task_type == "search":
            result = await self._do_search(user_input)
        elif task_type == "scrape":
            result = await self._do_scrape(user_input)
        elif task_type == "read_page":
            result = await self._do_read_page(user_input)
        elif task_type == "compare":
            result = await self._do_compare(user_input)
        else:
            result = await self._do_search(user_input)  # default: search

        self._tasks_done.append({
            "input": user_input,
            "type": task_type,
            "status": result.get("status", "unknown")
        })

        return result

    def _classify(self, text: str) -> str:
        """จำแนก task type จาก user input"""
        text_lower = text.lower()

        if any(kw in text_lower for kw in ["scrape", "ดึงข้อมูล", "ตาราง", "table"]):
            return "scrape"
        elif any(kw in text_lower for kw in ["อ่าน", "อ่านหน้า", "read", "สรุปหน้า"]):
            return "read_page"
        elif any(kw in text_lower for kw in ["เปรียบเทียบ", "compare", "ราคา"]):
            return "compare"
        else:
            return "search"

    # ----------------------------------------------------------
    # Search workflow
    # ----------------------------------------------------------

    async def _do_search(self, query: str) -> dict:
        """
        Workflow: BROWSER ค้นหา → สรุปผล
        
        User → GOD → BROWSER (search) → GOD → User
        """
        print(f"\n🌐 GOD: dispatch → BROWSER (search)")
        print(f"   query: \"{query}\"")

        # BROWSER ค้นหา
        search_result = await self.browser.search_google(query)

        if search_result["status"] != "success":
            return {"status": "error", "message": "ค้นหาไม่สำเร็จ"}

        results = search_result.get("results", [])
        print(f"   ✅ BROWSER: พบ {len(results)} ผลลัพธ์")

        # GOD สรุป (ในระบบจริงส่งให้ RESEARCHER)
        summary = {
            "status": "success",
            "type": "search",
            "query": query,
            "results_count": len(results),
            "top_results": results[:5],
            "message": f"พบ {len(results)} ผลลัพธ์สำหรับ \"{query}\""
        }

        print(f"\n📊 GOD: สรุปผล")
        for i, r in enumerate(results[:3], 1):
            print(f"   {i}. {r.get('title', 'N/A')[:60]}")
            print(f"      {r.get('url', 'N/A')[:70]}")

        return summary

    # ----------------------------------------------------------
    # Scrape workflow
    # ----------------------------------------------------------

    async def _do_scrape(self, user_input: str) -> dict:
        """
        Workflow: BROWSER scrape ข้อมูล structured
        
        User → GOD → BROWSER (scrape) → GOD → User
        """
        print(f"\n🌐 GOD: dispatch → BROWSER (scrape)")

        # ตัวอย่าง: scrape HN
        result = await self.browser.execute_task({
            "goal": user_input,
            "actions": [
                {"type": "navigate", "url": "https://news.ycombinator.com/"},
                {"type": "scrape_structured", "selectors": {
                    "titles": ".titleline > a",
                    "points": ".score",
                    "ages": ".age",
                }},
                {"type": "screenshot", "path": "scrape_result.png"}
            ]
        })

        if result["status"] == "success":
            data = result["results"][1].get("data", {})
            titles = data.get("titles", "").split("\n")[:5]
            print(f"\n📊 GOD: ผลลัพธ์ scraping")
            for i, t in enumerate(titles, 1):
                print(f"   {i}. {t[:60]}")

        return result

    # ----------------------------------------------------------
    # Read page workflow
    # ----------------------------------------------------------

    async def _do_read_page(self, user_input: str) -> dict:
        """
        Workflow: BROWSER อ่านหน้าเว็บ → สรุป
        
        User → GOD → BROWSER (navigate + snapshot) → GOD → User
        """
        print(f"\n🌐 GOD: dispatch → BROWSER (read_page)")

        # extract URL จาก input (ง่ายๆ)
        import re
        urls = re.findall(r'https?://[^\s]+', user_input)
        url = urls[0] if urls else "https://example.com"

        result = await self.browser.execute_task({
            "goal": f"อ่านเนื้อหาจาก {url}",
            "actions": [
                {"type": "navigate", "url": url},
                {"type": "scrape_meta"},
                {"type": "scrape_sections"},
                {"type": "snapshot"},
                {"type": "screenshot", "path": "page_read.png"}
            ]
        })

        if result["status"] == "success":
            meta = result["results"][1].get("meta", {})
            print(f"\n📊 GOD: อ่านหน้าเว็บสำเร็จ")
            title = meta.get('title') or 'N/A'
            desc = meta.get('description') or 'N/A'
            print(f"   Title: {title[:60]}")
            print(f"   Description: {desc[:60]}")

        return result

    # ----------------------------------------------------------
    # Compare workflow (multi-page)
    # ----------------------------------------------------------

    async def _do_compare(self, user_input: str) -> dict:
        """
        Workflow: BROWSER เปิดหลายเว็บ → scrape → เปรียบเทียบ
        
        User → GOD → BROWSER (page1) → BROWSER (page2) → GOD → User
        """
        print(f"\n🌐 GOD: dispatch → BROWSER (compare - multi-page)")

        # ตัวอย่าง: เปรียบเทียบ Python frameworks
        pages = [
            {"name": "FastAPI", "url": "https://fastapi.tiangolo.com/"},
            {"name": "Flask", "url": "https://flask.palletsprojects.com/"},
        ]

        results = []
        for page in pages:
            print(f"   📖 Reading: {page['name']}...")
            result = await self.browser.execute_task({
                "goal": f"อ่าน {page['name']}",
                "actions": [
                    {"type": "navigate", "url": page["url"]},
                    {"type": "scrape_meta"},
                    {"type": "snapshot"},
                ]
            })
            if result["status"] == "success":
                meta = result["results"][1].get("meta", {})
                results.append({
                    "name": page["name"],
                    "title": meta.get("title") or "",
                    "description": meta.get("description") or "",
                })

        print(f"\n📊 GOD: เปรียบเทียบ")
        for r in results:
            desc = r['description'][:60] if r['description'] else 'N/A'
            print(f"   {r['name']}: {desc}")

        return {"status": "success", "type": "compare", "results": results}

    async def close(self):
        await self.browser.close()


# ============================================================
# DEMO — รัน workflow จริง
# ============================================================

async def demo_search():
    """Demo 1: ค้นหา Google"""
    print("\n" + "=" * 60)
    print("🎬 DEMO 1: Search Workflow")
    print("=" * 60)

    god = GodAgent(headless=True)
    result = await god.handle("Python async await tutorial")
    await god.close()
    return result


async def demo_scrape():
    """Demo 2: Scraping ข้อมูล"""
    print("\n" + "=" * 60)
    print("🎬 DEMO 2: Scrape Workflow")
    print("=" * 60)

    god = GodAgent(headless=True)
    result = await god.handle("ดึงข้อมูล Hacker News")
    await god.close()
    return result


async def demo_read_page():
    """Demo 3: อ่านหน้าเว็บ"""
    print("\n" + "=" * 60)
    print("🎬 DEMO 3: Read Page Workflow")
    print("=" * 60)

    god = GodAgent(headless=True)
    result = await god.handle("อ่านหน้า https://httpbin.org/forms/post")
    await god.close()
    return result


async def demo_persistent():
    """Demo 4: Persistent session (จำ login)"""
    print("\n" + "=" * 60)
    print("🎬 DEMO 4: Persistent Session Workflow")
    print("=" * 60)

    session_dir = "/root/.openclaw/workspace/agentic-browser/.demo_session"

    # ครั้งแรก: set data
    print("\n  📌 Session 1: Set data")
    god = GodAgent(headless=True, user_data_dir=session_dir)
    result = await god.handle("อ่านหน้า https://example.com")
    # set localStorage
    await god.browser.tool.navigate("https://example.com")
    await god.browser.tool.evaluate("localStorage.setItem('demo_user', 'peach')")
    val = await god.browser.tool.evaluate("localStorage.getItem('demo_user')")
    print(f"  💾 Set localStorage: demo_user = {val.get('result', 'N/A')}")
    await god.close()

    # ครั้งที่สอง: check data persists
    print("\n  📌 Session 2: Check data persists")
    god2 = GodAgent(headless=True, user_data_dir=session_dir)
    await god2.browser.tool.navigate("https://example.com")
    val2 = await god2.browser.tool.evaluate("localStorage.getItem('demo_user')")
    print(f"  ✅ Persisted: demo_user = {val2.get('result', 'NOT FOUND')}")
    await god2.close()

    # cleanup
    import shutil
    shutil.rmtree(session_dir, ignore_errors=True)


async def demo_interactive():
    """Demo 5: Interactive — สั่งงานเอง"""
    print("\n" + "=" * 60)
    print("🎬 DEMO 5: Interactive Mode")
    print("=" * 60)
    print("พิมพ์คำสั่ง เช่น:")
    print("  - 'search Python tutorial'")
    print("  - 'scrape Hacker News'")
    print("  - 'read https://example.com'")
    print("  - 'quit' เพื่อออก")
    print("=" * 60)

    god = GodAgent(headless=True)

    while True:
        try:
            user_input = input("\n🧑 You: ").strip()
            if user_input.lower() in ("quit", "exit", "q"):
                break
            if not user_input:
                continue

            # Auto-prefix ถ้าไม่มี
            if not any(user_input.lower().startswith(p) for p in ["search", "scrape", "read", "อ่าน", "ดึง", "ค้นหา"]):
                user_input = f"search {user_input}"

            result = await god.handle(user_input)

            print(f"\n📤 Result:")
            print(json.dumps(result, indent=2, ensure_ascii=False)[:1000])

        except KeyboardInterrupt:
            break
        except EOFError:
            break

    await god.close()
    print("\n👋 Bye!")


# ============================================================
# Main
# ============================================================

async def main():
    print("=" * 60)
    print("🤖 GOD Agent + Browser Workflow Demo")
    print("=" * 60)

    # รัน demo ทั้งหมด
    await demo_search()
    await demo_scrape()
    await demo_read_page()
    await demo_persistent()

    print("\n" + "=" * 60)
    print("✅ All demos completed!")
    print("=" * 60)

    # Uncomment เพื่อทดลอง interactive mode:
    # await demo_interactive()


if __name__ == "__main__":
    asyncio.run(main())
