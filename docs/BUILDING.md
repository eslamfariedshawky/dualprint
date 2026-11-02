<div dir="rtl">

# بناء البرنامج من الشيفرة المصدرية

## على جهازك (Windows)
لا يتطلب البناء Visual Studio أو أي أدوات إضافية؛ إذ يستخدم المترجم `csc.exe` المرفق مع .NET Framework في Windows.

```powershell
git clone https://github.com/<اسم-الحساب>/multiprint.git
cd multiprint
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 2.2.5
```

المخرجات:
- `build\MultiPrint.exe`: البرنامج.
- `build\MultiPrint.zip`: الحزمة المعدّة للتوزيع.
- `build\MultiPrint.ps1`: البرنامج بعد دمج نصوص اللغات (للمراجعة).

## خطوات `build.ps1`
1. يقرأ `src\MultiPrint.ps1` ويضع محتوى `src\strings.json` مكان `__STRINGS_JSON__`.
2. يضيف رقم الإصدار إلى `Launcher.cs`.
3. يترجم الملف عبر `csc.exe` ويدمج البرنامج والأيقونة.
4. يضغط الملف التنفيذي في حزمة zip.

## البناء على GitHub (تلقائيًا)
ينفّذ الملف `.github/workflows/release.yml` الخطوات نفسها على جهاز Windows لدى GitHub:
- عند أي تحديث على الفرع `main`: يُبنى البرنامج ويُتاح من تبويب **Actions** ← آخر تشغيل ← **Artifacts**.
- عند إنشاء وسم (tag) مثل `v2.1.2`: يُبنى البرنامج ويُنشأ **Release** يتضمن `MultiPrint.zip`.

## قبل اعتماد أي تعديل
- [ ] يحتوي `strings.json` على المفاتيح نفسها في اللغات الخمس.
- [ ] جرى اختبار: إضافة طابعة، والتعديل، والطباعة على الطابعة المتعددة، وحفظ PDF في المجلد، وظهور العملية في السجل.
- [ ] جرى تحديث `CHANGELOG.md`.

</div>
