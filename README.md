# SCPClear

เครื่องมือดูแลคอมพิวเตอร์ภาษาไทย (SCPclear) และชุดโปรแกรมสำนักงานภาษาไทยสำหรับงานราชการ (SCP Office)

## โฟลเดอร์

| โฟลเดอร์ | คืออะไร |
|---|---|
| `SCP2/` | **SCPclear 2.3 (รุ่นล่าสุด)** โปรแกรม PowerShell/WPF คอมไพล์เป็น .exe ด้วย ps2exe: ล้างไฟล์ขยะ ตรวจสุขภาพเครื่อง ถอนโปรแกรม รายงาน PDF เครื่องมือช่าง (BSOD RAM ดิสก์ LAN winget สำรองข้อมูล) สร้างด้วย `BUILD-EXE.bat` |
| `SCP1/`, `SCP/`, `files/` | รุ่นเก่า เก็บไว้เป็นสำรอง |
| `Office/` | **SCP Office** ซอร์สโปรแกรมสำนักงานโอเพนซอร์ส (แบบ Word, Excel, PowerPoint, PDF) ที่ดึงมาจาก [storytold](https://github.com/storytold) และแก้ให้ใช้ภาษาไทยได้ รายละเอียดใน [`Office/README-TH.md`](Office/README-TH.md) |

## SCP Office — สิ่งที่แก้เพิ่มจากต้นทาง

ในโฟลเดอร์ `Office/wordcraft`:

- เมนูภาษาไทยทั้งหมด (2,649 ข้อความ) `crates/ui-egui/src/i18n/th.tsv`
- ฟอนต์ Sarabun (SIL OFL) สำหรับเมนู
- ตัดบรรทัดภาษาไทยด้วยพจนานุกรมตัดคำ (ICU4X) `crates/layout/src/thai.rs`

สร้างโปรแกรมด้วย `Office/BUILD-OFFICE.bat` (ต้องมี Rust 1.95 ขึ้นไป) ต้นทางระบุว่าโปรแกรมยังเป็น alpha ห้ามใช้กับเอกสารสำคัญหรือข้อมูลผู้ป่วยจนกว่าจะทดสอบเสร็จ

## สัญญาอนุญาต

- ซอร์สใน `Office/` (ไม่รวมโลโก้ ArtCraft ซึ่งเป็นเครื่องหมายการค้า ดู `Office/README-TH.md`) มาจากโปรเจกต์ของ storytold ใต้สัญญา MIT หรือ Apache-2.0 ตามที่ระบุในแต่ละโฟลเดอร์ (ไฟล์ `LICENSE-*` และ `NOTICE`) ส่วนที่เพิ่มเข้าไปใช้สัญญาเดียวกัน
- `SCP2/Lib/PdfSharp.dll` คือ PDFsharp (MIT) ดู `SCP2/Lib/PDFsharp-LICENSE.txt`
- ฟอนต์ Sarabun ใช้ SIL Open Font License 1.1 (`SCP2/Fonts/OFL.txt`)
- โค้ด SCPclear เอง ยังไม่ได้กำหนดสัญญาอนุญาต
