# Vexari UI – แพตช์ที่ 3: Dashboard (fps/ms, Profile, Stats, Header, indicator แท็บ, ปุ่มแคปซูล)

ใช้กับ repo ที่ลงชุดก่อนหน้าไว้แล้ว (ไม่ต้องอัปโหลด `PATCH.md` ขึ้น repo)
ชื่อโฟลเดอร์ต้องตรงกับใน repo เพื่อให้ทับของเดิมได้

## A. ทับของเดิม (7 ไฟล์ — จำเป็น)
| ไฟล์ใน repo | ทำอะไร |
| --- | --- |
| `dist/main.lua` | ไฟล์ที่ `loadstring` โหลด (ต้องทับ ไม่งั้นไม่เห็นอะไรเปลี่ยน) |
| `src/components/window/Init.lua` | Config ใหม่ `Style`, `Status`, `TabIndicator`, `UppercaseSections` + `Window:SetStatus` |
| `src/components/window/Openbutton.lua` | ปุ่มแคปซูล: แถว fps/ms ใต้ชื่อ + `Style = "Minimal"` |
| `src/components/window/Tab.lua` | แถบ indicator ด้านซ้ายของแท็บที่เลือก |
| `src/components/window/Section.lua` | หัวกลุ่มใน sidebar เป็นตัวพิมพ์ใหญ่ |
| `src/elements/Init.lua` | ลงทะเบียน `Tab:Header`, `Tab:Profile`, `Tab:Stats` |
| `src/themes/Init.lua` | ธีมใหม่ `Obsidian` |

## B. เพิ่มไฟล์ใหม่ (9 ไฟล์ — จำเป็น)
| ไฟล์ | ทำอะไร |
| --- | --- |
| `src/components/ui/Status.lua` | ตัววัด fps/ping + แถว "● 60 fps ● 78 ms" |
| `src/components/ui/StatCard.lua` | การ์ดตัวเลขหลายคอลัมน์ (COINS / GEMS / LEVEL) |
| `src/components/ui/ProfileCard.lua` | การ์ดโปรไฟล์ (avatar, ชื่อ, @user, ปุ่มขวา, ชิปสถานะ) |
| `src/components/ui/PageHeader.lua` | หัวหน้า (กล่องไอคอน + OVERVIEW + ชื่อหน้า) |
| `src/components/ui/Chip.lua` | ป้ายสถานะเล็ก ๆ |
| `src/elements/Stats.lua`, `Profile.lua`, `Header.lua` | ตัวห่อให้เรียก `Tab:Stats / Tab:Profile / Tab:Header` |
| `src/modules/Format.lua` | จัดรูปแบบตัวเลข (1,540) และสี |

## C. ไม่บังคับ
`main_dashboard.lua` (ตัวอย่างหน้า Home), `tests/vexari/test_dashboard.lua` + `run_tests.py` (ชุดทดสอบ), `README.md`, `changelog.md`, `NOTICE.md`

## วิธีทำบน GitHub (เว็บ)
1. แตก ZIP แล้วเข้า repo → Add file → Upload files
2. ลากโฟลเดอร์ `src`, `dist`, `tests` และไฟล์ด้านนอกเข้าไป → Commit changes
