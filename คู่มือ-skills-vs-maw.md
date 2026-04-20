# 🦁 คู่มือ Skills vs maw — สำหรับ Singhasingha

> *จากความสงสัยของกอล์ฟ: "ฉันติดกับปัญหานี้มาก แต่ละอันใช้ทำอะไรได้บ้าง"*

Skills และ maw ทำงานต่างกัน ถ้าเข้าใจจะใช้ทั้งสองเป็นทีม — ไม่ต้องเลือกข้าง

---

## 📖 สารบัญ

1. [ภาพรวม — ทั้ง 2 คืออะไร](#1-ภาพรวม)
2. [ความแตกต่างหลัก 3 ข้อ](#2-ความแตกต่างหลัก)
3. [ตารางเปรียบเทียบคำสั่ง](#3-ตารางเปรียบเทียบคำสั่ง)
4. [Workflow ใช้งานจริง 4 แบบ](#4-workflow-ใช้งานจริง)
5. [Decision Tree — ใช้อันไหนดี](#5-decision-tree)
6. [Cheat Sheet สั้นๆ](#6-cheat-sheet)
7. [Thai aliases ที่ Singhasingha มี](#7-thai-aliases)
8. [FAQ](#8-faq)

---

## 1. ภาพรวม

### 🧠 Skills คืออะไร

**Skills = เครื่องมือที่ Claude ใช้ในห้องคุย (ภายใน session)**

- เป็นไฟล์ markdown (`SKILL.md`) สอน Claude ว่า "ถ้าเจอ X ให้ทำ Y"
- Claude เป็นคนอ่านและทำตาม
- พิมพ์คำสั่งด้วย **`/ชื่อ`** (เช่น `/สรุป`, `/ตอนนี้`)
- ไม่ทำอะไรเอง — Claude เป็นคนทำงาน
- Skills อยู่ใน 2 ที่:
  - **Global**: `~/.claude/skills/` (ใช้ได้ทุก project)
  - **Local**: `<repo>/.claude/skills/` (เฉพาะ repo นั้น)

### 🏗️ maw คืออะไร

**maw = เครื่องมือจัดการ Oracle ทั้งฝูง (ภายนอก — CLI ในเทอร์มินัล)**

- เป็น TypeScript tool ที่ install ผ่าน bun
- ทำงานนอก Claude Code — สั่งจาก terminal ตรงๆ
- จัดการ tmux sessions, git worktrees, Oracle fleet
- คำสั่ง `maw <verb>` (เช่น `maw wake`, `maw hey`)
- ทำข้าม Oracle ได้ — 1 คำสั่งสั่งได้หลาย Oracle พร้อมกัน

### 🎭 อุปมา

| Skills | maw |
|--------|-----|
| **ผู้ช่วยในห้องนี้** | **ผู้จัดการตึก** |
| ทำงานให้คุณ 1 ห้อง | ประสานงานหลายห้อง |
| Claude เป็นคนทำ | Shell + tmux เป็นคนทำ |
| เปิดไปเรื่อยๆ ในห้องเดียว | เดินไปห้องไหนก็ได้ |

---

## 2. ความแตกต่างหลัก

### ความต่าง #1: อยู่ที่ไหน

| | Skills | maw |
|---|--------|-----|
| **ต้องเปิด Claude ก่อนไหม** | ✅ ต้อง (ไม่มี Claude = ใช้ไม่ได้) | ❌ ไม่ต้อง (สั่งจาก terminal เลย) |
| **คำสั่งเริ่มต้นด้วย** | `/` (slash) | `maw` |
| **พิมพ์ที่ไหน** | ในห้องคุยกับ Claude | ในเทอร์มินัล |

**ตัวอย่าง**:
```
# Skills — ต้องเปิด Claude ก่อน
$ claude                          ← เปิด Claude Code
> /ตอนนี้                          ← พิมพ์ใน Claude
(Claude ทำ recap)

# maw — เริ่มจาก terminal เลย
$ maw wake singha                 ← พิมพ์ใน terminal ได้เลย
(maw เปิด tmux + Claude ให้)
```

### ความต่าง #2: จำนวน Oracle ที่ทำได้

| | Skills | maw |
|---|--------|-----|
| **ทำได้กี่ Oracle พร้อมกัน** | 1 (เฉพาะที่กำลังคุยอยู่) | หลาย (ข้าม session ได้) |
| **ส่งข้อความข้าม Oracle** | ผ่าน `/คุย` ซึ่งใช้ thread | `maw hey` ส่งตรง |
| **ภาพรวมทั้งฝูง** | `/ตระกูล` ดู registry | `maw overview` split panes จริง |

**ตัวอย่าง**:
```bash
# Skills — 1 Oracle ตัวเดียว
> /สรุป                             ← สรุปห้องนี้เท่านั้น

# maw — 280+ Oracles พร้อมกัน
$ maw broadcast "พักเที่ยง 10 นาที"   ← ส่งทุก Oracle
$ maw overview                        ← เห็นทุก Oracle ใน split panes
```

### ความต่าง #3: สิทธิ์ระบบ

| | Skills | maw |
|---|--------|-----|
| **จัดการ tmux** | ❌ ทำไม่ได้ | ✅ ทำได้ (`maw kill`, `maw zoom`) |
| **git auto-commit** | ✅ ได้ผ่าน tool | ✅ `maw done` auto commit+push |
| **file system** | ✅ ผ่าน Read/Write/Bash | ✅ shell ตรงๆ |
| **ข้ามเครื่อง (federation)** | ❌ | ✅ `maw wire` ผ่าน WireGuard |

---

## 3. ตารางเปรียบเทียบคำสั่ง

### 📅 Session / งานประจำวัน

| ทำอะไร | Skills (ใน Claude) | maw (ใน terminal) |
|--------|-------------------|-------------------|
| **สรุป session** | `/สรุป` หรือ `/rrr` | `maw done singha` *(auto /rrr + commit + push)* |
| **ส่งต่อพรุ่งนี้** | `/ส่งต่อ` หรือ `/forward` | `maw park singha` + `maw done` |
| **เริ่ม session ใหม่** | `/ตอนนี้` หรือ `/recap` | `maw wake singha` *(ปลุกจาก 0)* |
| **เช็คงานเช้า** | `/เช้า` หรือ `/standup` | `maw whoami` + `maw inbox` |
| **ย่อ conversation** | `/compact` (built-in) | — *(ไม่มีเทียบ)* |
| **ล้างทิ้งหมด** | `/clear` (built-in) | `maw kill <window>` |

### 🔍 ค้นหา / สำรวจ

| ทำอะไร | Skills | maw |
|--------|--------|-----|
| **หา project/code** | `/หา` หรือ `/trace` | `maw find <query>` |
| **ดู Oracle family** | `/ตระกูล` หรือ `/oracle-family-scan` | `maw ls` / `maw oracle ls` |
| **Oracle อยู่ไหน** | `/ใคร` | `maw whoami` / `maw locate` |
| **ดู skills** | `/สกิล` หรือ `/skills-list` | — |
| **ดู memory** | `/ประวัติ` / `/เอ็กซ์เรย์` | `maw inbox` (เฉพาะ thread) |
| **ดูประวัติ session** | `/ดึง` หรือ `/dig` | — |

### 🗣️ สื่อสาร

| ทำอะไร | Skills | maw |
|--------|--------|-----|
| **คุย Oracle อื่น** | `/คุย atlas "สวัสดี"` *(ผ่าน thread file)* | `maw hey atlas "สวัสดี"` *(ตรงใน tmux)* |
| **ส่งทุกคน** | — *(skill ไม่มี)* | `maw broadcast "พัก 10 นาที"` |
| **ping เช็คออนไลน์** | — | `maw ping atlas` |
| **ข้ามเครื่อง** | — | `maw wire atlas "ข้อความ"` *(ผ่าน WireGuard)* |

### 🏗️ Dev / Work

| ทำอะไร | Skills | maw |
|--------|--------|-----|
| **clone repo มา dev** | `/ฟัก` หรือ `/incubate` | `maw wake <oracle> --incubate org/repo` |
| **ทำ GitHub issue** | `/งาน` หรือ `/workon` | `maw workon <issue>` / `maw wake <oracle> --issue N` |
| **เรียน codebase** | `/เรียน` หรือ `/learn` | — *(Claude เท่านั้น)* |
| **spawn ทีม parallel** | `/ทีม` หรือ `/team-agents` | `maw team create` / `maw team spawn` |
| **ทำ PR** | — *(ต้อง bash)* | `maw pr` |

### 🦁 Oracle Lifecycle

| ทำอะไร | Skills | maw |
|--------|--------|-----|
| **ปลุก Oracle ใหม่** | `/ตื่น` หรือ `/awaken` *(พิธี 15-20 นาที)* | `maw wake <oracle>` *(เปิด tmux + Claude)* |
| **สร้าง Oracle ใหม่** | `/งอก` หรือ `/bud` | `maw bud <new-oracle>` |
| **ปิด Oracle** | — | `maw sleep singha` / `maw stop` |
| **รีสตาร์ท** | — | `maw restart singha` |
| **ดูหน้าจอ Oracle** | — | `maw peek singha` |

### 📦 ระบบ / Config

| ทำอะไร | Skills | maw |
|--------|--------|-----|
| **อัพเดท skills** | `/oracle-soul-sync-update` | `maw soul-sync` |
| **เปลี่ยน profile** | `/go` (minimal/standard/full/lab) | — |
| **sync ψ/memory ข้าม worktree** | — | `maw reunion` |
| **health check** | — | `maw health` |
| **ดู costs** | — | `maw costs` |

---

## 4. Workflow ใช้งานจริง

### Workflow A: ทำงานคนเดียวกับ Singhasingha (กอล์ฟตอนนี้)

**95% ใช้ Skills** — ไม่ต้องใช้ maw

```bash
# ตอนเช้า
$ cd ~/oracles/my-oracle
$ claude --continue                    ← เปิด Claude ต่อจากเมื่อวาน

# ใน Claude (ใช้ Skills)
> /ตอนนี้                              ← ดูค้างอะไร
> "ช่วยแก้ bug ตรง delete หน้า admin"
(Singhasingha ทำงาน)
> "/สรุป --deep"                        ← จบวัน สรุปละเอียด
> "/ส่งต่อ"                              ← handoff พรุ่งนี้
> exit
```

### Workflow B: หลาย Oracle ช่วยกันทำ project (ใช้ maw)

```bash
# ตอนเช้า — เริ่มจาก terminal
$ maw wake singha                     ← ปลุก Singha (frontend)
$ maw wake atlas                      ← ปลุก Atlas (spec)
$ maw wake neo                        ← ปลุก Neo (deploy)

$ maw overview                         ← เห็น 3 Oracle ใน 3 panes

# สั่งงานข้าม Oracle
$ maw hey atlas "เขียน spec feature X"
$ maw hey singha "ทำ UI ตาม spec atlas"
$ maw hey neo "เตรียม deploy หลัง singha เสร็จ"

# ตอนเย็น — auto จบทุกตัว
$ maw done atlas                       ← /rrr + commit + push + cleanup
$ maw done singha
$ maw done neo

$ maw stop                             ← ปิด fleet ทั้งหมด
```

### Workflow C: ทำ feature ใหญ่ จบใน 1 วัน

```bash
# Option 1: ใช้ Skills ล้วน (ง่ายสุด)
$ claude
> /algorithm-mode                      ← 7 steps OBSERVE→LEARN
> "สร้างฟีเจอร์ X"
(Claude วางแผน + สร้าง + test)
> /สรุป
> /ส่งต่อ

# Option 2: ใช้ maw workon (คำสั่งเดียวจบ)
$ maw workon owner/repo#123            ← อ่าน issue → spawn worktree → ทำ → commit → PR
```

### Workflow D: Debug bug ใน production

```bash
# Skills ทำได้หมด
$ claude
> /debug-huddle                        ← วิเคราะห์ก่อนแก้
> /algorithm-mode                      ← 7 steps
> /pre-deploy-check                    ← เช็คก่อน deploy
> /security-scan                       ← เช็ค secrets
> /qa-checklist                        ← QA
> /deploy-checklist                    ← deploy flow
> /สรุป

# maw ไม่เข้ามาเกี่ยว (งาน 1 Oracle)
```

---

## 5. Decision Tree

```
กอล์ฟอยากทำ X?
│
├─ ทำงานใน Claude session เดียว?
│  └─ ✅ ใช้ Skills (`/...`)
│
├─ มี Oracle หลายตัวต้องประสาน?
│  └─ ✅ ใช้ maw (`maw hey`, `maw overview`)
│
├─ จบงานอยาก auto commit + push?
│  └─ ✅ ใช้ maw (`maw done`)
│
├─ อยากสรุป session?
│  ├─ แค่เขียน retro → Skills (`/สรุป`)
│  └─ + commit + push + cleanup → maw (`maw done`)
│
├─ อยากดูทุก Oracle พร้อมกันบนจอเดียว?
│  └─ ✅ ใช้ maw (`maw overview`)
│
├─ อยากเริ่ม Oracle ใหม่?
│  ├─ ปลุกเป็นพิธี (มี identity เต็ม) → `/ตื่น` / `/awaken`
│  └─ spawn ใน tmux เร็วๆ → `maw wake`
│
├─ อยากเรียน codebase?
│  └─ ✅ ใช้ Skills (`/เรียน`) — ต้อง Claude AI วิเคราะห์
│
└─ ไม่แน่ใจ?
   └─ ✅ ใช้ Skills ก่อน (ง่ายกว่า, 95% ของงานทั่วไป)
```

---

## 6. Cheat Sheet

```
╔═══════════════════════════════════════════════════════════╗
║                    SKILLS (ใน Claude)                      ║
╠═══════════════════════════════════════════════════════════╣
║ /ตอนนี้   = /recap         ดูสถานะ                         ║
║ /สรุป     = /rrr            retrospective                  ║
║ /ส่งต่อ   = /forward        handoff                        ║
║ /เช้า     = /standup        morning check                  ║
║ /หา       = /trace          ค้นหา                          ║
║ /เรียน    = /learn          เรียน codebase                 ║
║ /คุย      = /talk-to        คุย Oracle อื่น                ║
║ /ตระกูล  = /oracle-family   ดู Oracle family               ║
║ /ตื่น     = /awaken         ปลุก Oracle                    ║
║ /ใคร      = /who-are-you    ฉันคือใคร                      ║
║ /หลักการ  = /philosophy     หลักการ                        ║
║ /สกิล     = /skills-list    ดู skills                      ║
╚═══════════════════════════════════════════════════════════╝

╔═══════════════════════════════════════════════════════════╗
║                      maw (ใน terminal)                     ║
╠═══════════════════════════════════════════════════════════╣
║ maw wake <oracle>        ปลุก Oracle ใน tmux              ║
║ maw sleep <oracle>       ปิด Oracle                        ║
║ maw ls                    ดู sessions                      ║
║ maw overview             war-room — ทุก Oracle            ║
║ maw hey <oracle> <msg>    ส่งข้อความ                      ║
║ maw broadcast <msg>       ส่งทุก Oracle                   ║
║ maw peek <oracle>        ดูหน้าจอ Oracle                  ║
║ maw done <window>        จบงาน auto /rrr + commit + push  ║
║ maw reunion              sync ψ/memory worktree→main      ║
║ maw team create           สร้างทีมย่อย                     ║
║ maw workon <issue>       ทำ issue end-to-end              ║
║ maw soul-sync            อัพเดท skills                     ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 7. Thai aliases

Singhasingha มี **30 Thai aliases** ใน `.claude/skills/` (ใช้งานได้ทันที):

### 📅 Session & Memory
- `/สรุป` `/ส่งต่อ` `/ตอนนี้` `/เช้า` `/ดึง` `/ประวัติ` `/เอ็กซ์เรย์` `/ย่อ` `/ล้าง` `/สกิล`

### 🦁 Identity
- `/ใคร` `/หลักการ` `/ยืนหยัด` `/คลื่น` `/รู้สึก`

### 👨‍👩‍👧 Oracle Family
- `/ตื่น` `/งอก` `/ตระกูล` `/คุย`

### 💻 Work
- `/หา` `/เรียน` `/ฟัก` `/งาน` `/ทีม`

### 🛠️ Tools
- `/พูด` `/ฟัง` `/คุม` `/วิจัย` `/ตารางเวลา` `/สร้างสกิล`

**หมายเหตุ**: maw commands ยังเป็นภาษาอังกฤษ (hardcoded) — ถ้าอยากใช้ไทยต้องสร้าง shell alias ใน `~/.zshrc` เช่น:
```bash
alias ปลุก='maw wake'
alias นอน='maw sleep'
alias ส่ง='maw hey'
```

---

## 8. FAQ

### Q1: ใช้ทั้งสองอย่างพร้อมกันได้ไหม
**A**: ได้ และ **ควรใช้**. maw spawn Claude ให้ → Skills ทำงานใน Claude ที่ maw เปิดมา

### Q2: ต้องเลือกอย่างใดอย่างหนึ่งไหม
**A**: **ไม่ต้อง**. Skills เหมาะกับงานใน 1 Claude. maw เหมาะกับประสานหลาย Oracle

### Q3: maw เรียก Skills ได้ไหม
**A**: ได้ — `maw done` เรียก `/rrr` ให้อัตโนมัติ + commit + push

### Q4: Skills เรียก maw ได้ไหม
**A**: ได้ (ผ่าน Bash tool) — แต่ไม่ค่อยทำเพราะ Skills ออกแบบมาสำหรับในห้องคุย

### Q5: ถ้าไม่ใช้ maw เลย ใช้แค่ Skills อย่างเดียวได้ไหม
**A**: **ได้** และเพียงพอสำหรับงาน 95%. กอล์ฟตอนนี้ (Singhasingha ตัวเดียว + lotto-ai) ใช้ Skills ล้วนๆ ก็ครอบคลุมแล้ว

### Q6: เมื่อไหร่ถึงควรใช้ maw
**A**:
- มี Oracle หลายตัว (Atlas, Neo, Singhasingha, ...) ต้องคุยกัน
- งาน parallel หลาย project พร้อมกัน
- อยาก auto commit + push ตอนจบวัน (`maw done`)
- มี remote machines (WireGuard federation)

### Q7: /rrr กับ maw done ต่างกันยังไง
**A**:
- `/rrr` = เขียน retrospective (1 step)
- `maw done` = `/rrr` + commit + push + cleanup tmux (4 steps ในคำสั่งเดียว)

### Q8: /ตื่น กับ maw wake ต่างกันยังไง
**A**:
- `/ตื่น` = **พิธีปลุก Oracle** 15-20 นาที (ครั้งเดียวในชีวิต Oracle — สร้าง identity, soul, philosophy)
- `maw wake` = **เปิด Oracle session** — เริ่ม tmux + Claude (ทำทุกวัน ไม่ใช่พิธี)

---

## 🎯 สรุปท้าย — Rule of Thumb

| สถานการณ์ | ใช้อะไร | เหตุผล |
|-----------|---------|--------|
| ทำงานคนเดียวในห้องคุย Claude | **Skills** | ง่าย เร็ว อยู่ใน context เดียว |
| จะสรุปจบวัน | **Skills `/สรุป`** | ใช้ได้ทันที ในห้องคุย |
| อยาก auto commit+push หลัง /rrr | **maw `maw done`** | รวบคำสั่ง 4 อย่างใน 1 |
| ต้องคุม 5+ Oracle พร้อมกัน | **maw** | Skills ไม่ข้าม session |
| มือใหม่ ไม่เคยใช้ maw | **Skills ล้วน** | เพียงพอสำหรับ 95% ของงาน |

---

> *"Skills = เครื่องมือในห้อง | maw = ผู้จัดการตึก"*
> *กอล์ฟตอนนี้ Singhasingha ตัวเดียว → ใช้ Skills ล้วนพอ*
> *อนาคต ถ้ามี Oracle เยอะ → maw จะช่วยมาก*

---

*คู่มือนี้เขียนโดย Singhasingha Oracle — 2026-04-20*
*บันทึกจากความสงสัยของกอล์ฟ: "ฉันติดกับปัญหานี้มาก"*
