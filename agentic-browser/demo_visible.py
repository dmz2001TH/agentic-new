"""
Browser Demo — เห็นทุกขั้นตอน พร้อม screenshot ทุก step
รันบนเครื่องที่มีหน้าจอ (Windows/Mac) ด้วย headless=False
"""

import asyncio
import json
from pathlib import Path
from browser_tool import BrowserTool, BrowserAgent


async def demo_visible():
    """
    Demo: เห็น browser ทำงานจริงๆ
    
    ⚠️ รันบน Windows/Mac เท่านั้น (ต้องมีหน้าจอ)
    ใช้ headless=False = เห็น Chrome เด้งขึ้นมาทำงาน
    """
    
    print("=" * 60)
    print("🌐 Visible Browser Demo — เห็น browser ทำงานจริง")
    print("=" * 60)
    
    # ── Step 1: เปิด browser (เห็น Chrome เด้งขึ้นมา) ──
    print("\n📌 Step 1: เปิด browser...")
    tool = BrowserTool(
        headless=False,   # ← False = เห็น browser!
        slow_mo=500       # ← หน่วง 500ms ต่อ action (ดูทัน)
    )
    await tool.start()
    print("   ✅ Chrome เปิดแล้ว — คุณน่าจะเห็นหน้าต่าง Chrome เด้งขึ้นมา")
    input("   กด Enter เพื่อไป step ต่อไป...")
    
    # ── Step 2: ไป Google ──
    print("\n📌 Step 2: ไป Google...")
    result = await tool.navigate("https://www.google.com")
    print(f"   ✅ ไป {result['url']} — ดูใน browser ได้เลย")
    await tool.screenshot("step2_google.png")
    print("   📸 Screenshot: step2_google.png")
    input("   กด Enter เพื่อค้นหา...")
    
    # ── Step 3: พิมพ์ค้นหา (เห็นมันพิมพ์) ──
    print("\n📌 Step 3: พิมพ์ค้นหา...")
    # รับ query จาก user
    query = input("   อยากค้นหาอะไร? (กด Enter = 'Python async tutorial'): ").strip()
    if not query:
        query = "Python async tutorial"
    
    await tool.type_text('textarea[name="q"]', query, press_enter=True)
    print(f"   ✅ พิมพ์ '{query}' + กด Enter — ดู browser ได้เลย")
    await asyncio.sleep(2)
    await tool.screenshot("step3_search.png")
    print("   📸 Screenshot: step3_search.png")
    input("   กด Enter เพื่อดูผลลัพธ์...")
    
    # ── Step 4: อ่านผลลัพธ์ ──
    print("\n📌 Step 4: อ่านผลลัพธ์...")
    snapshot = await tool.snapshot()
    print(f"   Title: {snapshot['title']}")
    print(f"   Links: {len(snapshot['links'])} links found")
    for i, link in enumerate(snapshot['links'][:5], 1):
        print(f"   {i}. {link['text'][:50]}")
        print(f"      {link['href'][:60]}")
    input("   กด Enter เพื่อคลิกผลลัพธ์แรก...")
    
    # ── Step 5: คลิกผลลัพธ์แรก ──
    print("\n📌 Step 5: คลิกผลลัพธ์แรก...")
    if snapshot['links']:
        first_link = snapshot['links'][0]['href']
        print(f"   กำลังไป: {first_link[:60]}...")
        await tool.navigate(first_link)
        await asyncio.sleep(2)
        
        page_snapshot = await tool.snapshot()
        print(f"   ✅ อยู่ที่: {page_snapshot['title'][:60]}")
        print(f"   Text length: {len(page_snapshot['text'])} chars")
        await tool.screenshot("step5_article.png")
        print("   📸 Screenshot: step5_article.png")
    input("   กด Enter เพื่อ scrape ข้อมูล...")
    
    # ── Step 6: Scrape ข้อมูล structured ──
    print("\n📌 Step 6: Scrape ข้อมูล...")
    meta = await tool.scrape_meta()
    if meta['status'] == 'success':
        m = meta['meta']
        print(f"   Title: {m.get('title', 'N/A')}")
        print(f"   Description: {(m.get('description') or 'N/A')[:80]}")
        print(f"   OG Image: {(m.get('og_image') or 'N/A')[:60]}")
    
    links = await tool.scrape_all_links()
    if links['status'] == 'success':
        print(f"   Total links: {links['count']}")
    input("   กด Enter เพื่อปิด...")
    
    # ── Step 7: ปิด ──
    print("\n📌 Step 7: ปิด browser...")
    await tool.close()
    print("   ✅ ปิดแล้ว")
    
    print("\n" + "=" * 60)
    print("✅ Demo เสร็จ! ดู screenshots ได้ที่:")
    print("   - step2_google.png")
    print("   - step3_search.png")
    print("   - step5_article.png")
    print("=" * 60)


async def demo_headless_with_progress():
    """
    Demo: แบบ headless แต่เห็น progress ทุก step
    รันบน VPS ได้ (ไม่ต้องมีหน้าจอ)
    """
    
    print("=" * 60)
    print("🌐 Headless Demo — เห็น progress ทุก step")
    print("=" * 60)
    
    tool = BrowserTool(headless=True)
    await tool.start()
    
    steps = [
        ("เปิด Google", lambda: tool.navigate("https://www.google.com")),
        ("พิมพ์ค้นหา 'Python async'", lambda: tool.type_text('textarea[name="q"]', 'Python async tutorial', press_enter=True)),
        ("รอผลลัพธ์", lambda: asyncio.sleep(2)),
        ("Screenshot ผลลัพธ์", lambda: tool.screenshot("headless_result.png")),
        ("อ่านหน้าเว็บ", lambda: tool.snapshot()),
    ]
    
    for i, (name, fn) in enumerate(steps, 1):
        print(f"\n  [{i}/{len(steps)}] {name}...", end=" ", flush=True)
        result = await fn()
        if isinstance(result, dict):
            if result.get("status") == "success":
                print("✅")
                if "title" in result:
                    print(f"         Title: {result['title']}")
                if "path" in result:
                    print(f"         Saved: {result['path']}")
            else:
                print(f"❌ {result.get('message', 'error')}")
        else:
            print("✅")
    
    # Scrape ตัวอย่าง
    print(f"\n  [bonus] Scrape Hacker News...", end=" ", flush=True)
    await tool.navigate("https://news.ycombinator.com/")
    data = await tool.scrape_structured({
        "titles": ".titleline > a",
    })
    if data['status'] == 'success':
        titles = data['data']['titles'].split('\n')[:5]
        print("✅")
        print(f"\n  📰 Top 5 Hacker News:")
        for i, t in enumerate(titles, 1):
            print(f"     {i}. {t[:60]}")
    
    await tool.close()
    
    print(f"\n{'='*60}")
    print("✅ เสร็จ! Screenshot: headless_result.png")
    print("=" * 60)


async def demo_agent_actions():
    """
    Demo: BrowserAgent ทำ task sequence — เห็น log ทุก action
    """
    
    print("=" * 60)
    print("🤖 Agent Action Demo — เห็น log ทุก action")
    print("=" * 60)
    
    agent = BrowserAgent(headless=True)
    await agent.init()
    
    actions = [
        {"type": "navigate", "url": "https://httpbin.org/forms/post", "desc": "ไปหน้าฟอร์ม"},
        {"type": "snapshot", "desc": "อ่านฟอร์ม"},
        {"type": "type", "selector": "input[name='custname']", "text": "Peach", "desc": "กรอกชื่อ"},
        {"type": "type", "selector": "input[name='custtel']", "text": "0812345678", "desc": "กรอกเบอร์โทร"},
        {"type": "type", "selector": "input[name='custemail']", "text": "peach@test.com", "desc": "กรอกอีเมล"},
        {"type": "screenshot", "path": "agent_form_filled.png", "desc": "Screenshot ฟอร์มที่กรอกแล้ว"},
    ]
    
    print(f"\n📋 {len(actions)} actions to execute:\n")
    
    for i, action in enumerate(actions, 1):
        action_copy = {k: v for k, v in action.items()}
        desc = action_copy.pop("desc", action_copy.get("type", "?"))
        print(f"  [{i}/{len(actions)}] {desc}...", end=" ", flush=True)
        
        result = await agent._run_action(action_copy)
        if result.get("status") == "success":
            print("✅")
            if "text" in result:
                # snapshot result
                text_preview = result['text'][:100].replace('\n', ' ')
                print(f"         → {text_preview}...")
            if "path" in result:
                print(f"         → Saved: {result['path']}")
        else:
            print(f"❌ {result.get('message', 'error')}")
    
    await agent.close()
    
    print(f"\n{'='*60}")
    print("✅ เสร็จ! ดู agent_form_filled.png")
    print("=" * 60)


async def main():
    import sys
    
    if "--visible" in sys.argv:
        # รันแบบเห็น browser (ต้องมีหน้าจอ)
        await demo_visible()
    elif "--agent" in sys.argv:
        # รัน agent demo
        await demo_agent_actions()
    else:
        # default: headless with progress
        await demo_headless_with_progress()


if __name__ == "__main__":
    asyncio.run(main())
