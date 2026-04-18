# บทที่ 5: Loops — งานที่ทำซ้ำ

บางงาน Oracle ต้องทำซ้ำ — ทุกชั่วโมง, ทุกวัน, ทุกสัปดาห์
Loops ทำให้ตั้ง schedule ได้ โดยไม่ต้องจำเองว่าต้องสั่งเมื่อไหร่

## Loop คืออะไร?

Loop = **scheduled task** ที่ maw trigger ตาม cron schedule แล้วส่ง prompt ให้ Oracle ทำ

ตัวอย่าง:
- ทุก 3 ชม. → AIA scan Gmail
- ทุกเช้า 9:00 → PA ส่ง morning briefing
- ทุกวันจันทร์ → BoB weekly review

## ดู Loop ทั้งหมด

```bash
maw loop
```

```
✓ aia-email-check [aia]
  AIA checks ePOS emails from Gmail
  0 8,12,17 * * * | last: 10:00 | next: 12:00

✓ pa-morning-briefing [pa]
  Daily morning briefing email
  0 7 * * * | last: 07:00 | next: tomorrow 07:00

○ bob-weekly-review [bob]
  BoB Monday weekly review
  0 9 * * 1 | never ran | next: Monday 09:00
```

- `✓` = enabled, ran successfully
- `○` = enabled, hasn't run yet
- `✗` = disabled

## สร้าง Loop

```bash
maw loop add '{
  "id": "my-daily-check",
  "oracle": "dev",
  "tmux": "02-dev:0",
  "schedule": "0 9 * * *",
  "prompt": "ตรวจสอบ API health แล้ว report ใน thread",
  "requireIdle": true,
  "enabled": true,
  "description": "Daily API health check"
}'
```

### ฟิลด์สำคัญ

| ฟิลด์ | คำอธิบาย | ตัวอย่าง |
|--------|---------|---------|
| `id` | ชื่อ unique | `"my-daily-check"` |
| `oracle` | Oracle ที่จะทำ | `"dev"` |
| `tmux` | tmux window:pane | `"02-dev:0"` |
| `schedule` | cron expression | `"0 9 * * *"` = ทุกวัน 9:00 |
| `prompt` | สิ่งที่ Oracle จะทำ | `"ตรวจ API แล้ว report"` |
| `requireIdle` | รอจน Oracle ว่าง | `true` |
| `enabled` | เปิด/ปิด | `true` |
| `description` | อธิบายสั้นๆ | `"Daily API check"` |

### Cron Expression ง่ายๆ

```
นาที  ชม.  วัน  เดือน  วันในสัปดาห์

0 9 * * *       = ทุกวัน 09:00
0 9,15 * * *    = ทุกวัน 09:00 + 15:00
*/30 * * * *    = ทุก 30 นาที
0 9 * * 1       = ทุกวันจันทร์ 09:00
0 9 * * 1-5     = จันทร์-ศุกร์ 09:00
7 * * * *       = ทุกชั่วโมง นาทีที่ 7
```

## จัดการ Loop

```bash
# Trigger ทันที (ไม่ต้องรอ schedule)
maw loop trigger my-daily-check

# ปิด loop
maw loop disable my-daily-check

# เปิด loop
maw loop enable my-daily-check

# ลบ loop
maw loop remove my-daily-check

# ดู history
maw loop history my-daily-check
```

## THE LAW: ห้ามใช้ CronCreate

> ต้องการ scheduled task → ใช้ `maw loop add` เท่านั้น
> **ห้ามใช้ CronCreate** — มันหายเมื่อ restart session

เหตุผล:
- CronCreate ไม่ persist ข้าม session
- CronCreate ไม่แสดงบน dashboard
- `maw loop add` persist, มี history, แสดงบน dashboard

## ตัวอย่างจริง: Discussion Monitor

```bash
maw loop add '{
  "id": "discussion-monitor",
  "oracle": "creator",
  "tmux": "15-creator:0",
  "schedule": "7 * * * *",
  "prompt": "Check GitHub Discussions on teaching repos — answer any new questions",
  "requireIdle": true,
  "enabled": true,
  "description": "Hourly discussion monitor — teaching org admin"
}'
```

ทุกชั่วโมง นาทีที่ 7 → Creator ตรวจ Discussions → ตอบคำถาม

## ลองทำ

1. ดู loops: `maw loop`
2. ถ้ามี loop → trigger: `maw loop trigger <id>`
3. อยากสร้าง? → ลอง daily health check

---

→ [บทที่ 6: Overview & Monitoring](06-overview.md)
