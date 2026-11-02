<div dir="rtl">

# البنية التقنية

## الفكرة
لا يتيح Windows لطابعة واحدة الإرسال إلى طابعتين. لذلك ينشئ MultiPrint طابعة افتراضية **تطبع إلى ملف PDF**، وتتولى خدمة صغيرة مراقبة هذا الملف وتوزيعه.

```
 أي تطبيق ──طباعة──▶ «طباعة الفواتير» (طابعة افتراضية)
                          │  Driver: Microsoft Print To PDF
                          │  Port:   C:\DualPrint\queues\q_xxx\incoming.pdf
                          ▼
                 خدمة MultiPrint (MultiPrint.exe --watch)
                          │  تكتشف incoming.pdf وتنتظر اكتمال كتابته
                          │  تنقله إلى jobs\job_….pdf
                          ├──▶ الطابعة 1  (SumatraPDF -print-to)
                          ├──▶ الطابعة 2  (SumatraPDF -print-to)
                          └──▶ مجلد PDF  (نسخ الملف بالاسم: البادئة_التاريخ_الوقت.pdf)
                          │
                          └──▶ history.jsonl  (اسم المستند ونتيجة كل وجهة)
```

## المكوّنات

### `src/Launcher.cs`: الملف التنفيذي
- برنامج C# صغير يعتمد على .NET Framework 4 المتوفر في Windows 10 و11.
- يتضمن الملف `MultiPrint.ps1` بوصفه مَوردًا مدمجًا (resource).
- يطلب صلاحيات المسؤول، باستثناء وضع `--watch`.
- يشغّل البرنامج **داخل العملية نفسها** عبر PowerShell Runspace على خيط STA، فيظهر في شريط المهام ومدير المهام باسمه وأيقونته دون نافذة PowerShell.
- يصل إلى `System.Management.Automation` عبر Reflection، فلا يحتاج إلى مراجع وقت البناء.

### `src/MultiPrint.ps1`: البرنامج
| الجزء | المسؤولية |
|---|---|
| الأدوات العامة | `Get-Config` و`Save-Config` و`Get-Targets` و`Write-Log` |
| المراقب (`-Watch`) | الدالة `Start-Watcher`: حلقة كل 0.7 ثانية، وقفل (Mutex) يمنع تشغيل نسختين، والتقاط اسم المستند عبر `Get-PrintJob`، والإرسال إلى كل وجهة، والتسجيل في السجل، وتنظيف الملفات الأقدم من سبعة أيام |
| وظائف الطابعات | `New-MultiPrinter` (المنفذ والطابعة)، و`Remove-MultiPrinter`، و`Register-Watcher` (مهمة مجدولة)، و`Set-DefaultMultiPrinter`، و`Find-Sumatra` |
| الواجهة (WPF) | ملف XAML للنافذة الرئيسية، وأجزاء XAML صغيرة تُبنى ديناميكيًا للبطاقات وصفوف السجل |
| اللغات | يُستبدل `__STRINGS_JSON__` وقت البناء بمحتوى `strings.json`، وتُعيد الدالة `T 'key'` النص المناسب |

### خدمة الطباعة (المهمة المجدولة `MultiPrint Watcher`)
- تشغّل `C:\DualPrint\MultiPrint.exe --watch` بصلاحيات المستخدم العادي.
- المشغّلات: عند تسجيل الدخول، وكل خمس دقائق لاستعادة الخدمة إذا توقفت.
- الإعدادات: دون حد زمني، وتستمر عند العمل على البطارية، وتُعاد المحاولة بعد دقيقة عند الفشل.
- يضمن الخيار `MultipleInstances IgnoreNew` مع القفل `Local\MultiPrintWatcher` تشغيل نسخة واحدة فقط.

## بنية الملف `printers.json`
```json
[
  {
    "Name": "طباعة الفواتير",
    "Folder": "C:\\DualPrint\\queues\\q_638...",
    "Port": "C:\\DualPrint\\queues\\q_638...\\incoming.pdf",
    "Targets": ["EPSON L4150 Series", "Microsoft Print to PDF"],
    "PdfFolder": "D:\\Invoices",
    "PdfPrefix": "فاتورة",
    "PaperSize": "A4",
    "PdfEnabled": true
  }
]
```
الحقول الحديثة اختيارية؛ تتجاهلها الإصدارات القديمة وتحافظ عليها دون تعديل.

## بنية الملف `history.jsonl` (سطر لكل عملية)
```json
{"Time":"2026-11-02T15:42:10+03:00","Printer":"طباعة الفواتير","Doc":"فاتورة مبيعات.pdf",
 "Results":[{"Target":"EPSON L4150 Series","Ok":true,"Msg":"exit 0"},
            {"Target":"Microsoft Print to PDF","Ok":true,"Msg":"D:\\Invoices\\فاتورة_….pdf"}]}
```

## إضافة لغة جديدة
1. انسخ كتلة `"en"` في `src/strings.json` باسم رمز اللغة (مثل `"tr"`) وترجم القيم.
2. أضف اللغة في `MultiPrint.ps1` ضمن `Show-LanguagePicker` و`$CultureMap` و`$LangNames`.
3. أعد بناء البرنامج.

## القيود المعروفة
- لا تنتقل إعدادات نافذة الطباعة (عدد النسخ، والدرج وغيرها) إلى الطابعات الأخرى؛ إذ تطبع كل طابعة وفق إعدادها الافتراضي، باستثناء مقاس الورق إذا حُدّد.
- يُستمد اسم المستند من Windows، ولا ترسله بعض التطبيقات، فيظهر حينها «مستند».
- الملف غير موقّع رقميًا، لذا تظهر رسالة SmartScreen عند التشغيل الأول (انظر [PUBLISHING.md](PUBLISHING.md)).

</div>
