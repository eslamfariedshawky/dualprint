# -*- coding: utf-8 -*-
# نصوص الموقع لكل لغة. عدّل هنا ثم شغّل: python tools/build_site.py
VERSION = "2.2.5"

LANGS = ["en", "ar", "ru", "de", "es", "fr"]

C = {}

C["en"] = dict(
    dir="ltr", name="English", locale="en_US",
    title="MultiPrint — Print to Multiple Printers at Once & Auto-Save PDF (Free, Windows)",
    desc="Free Windows app that connects two or more printers to one virtual printer. Print once and send the job to several printers at the same time, and automatically save a PDF copy. No complicated setup.",
    keywords="print to multiple printers at once, print to two printers simultaneously, connect two printers, virtual printer, duplicate print job, auto save PDF when printing, multi printer Windows, print PDF and printer at the same time, free printer software",
    h1="Print to multiple printers at once — and save a PDF automatically",
    sub="MultiPrint adds one virtual printer to Windows. Print to it from any program and the job goes to all the printers you chose — plus an automatic PDF copy in your folder.",
    tagline="A simple, free solution — no complicated settings",
    dl="Download for Windows", dl_note="Windows 10 / 11 · Free · Open source", gh="View on GitHub",
    nav_features="Features", nav_how="How it works", nav_faq="FAQ",
    how_title="Ready in 3 steps",
    steps=[("Create a multi printer", "Open MultiPrint, give it a name and pick two or more printers — real printers, PDF, or both."),
           ("Print as usual", "From Word, Excel, your browser or accounting software, choose the new printer by name."),
           ("Done", "Every printer gets the document at the same time, and the PDF is saved in your folder.")],
    feat_title="Everything you need, nothing you don't",
    feats=[("Print to 2+ printers", "One click sends the same job to every printer you linked."),
           ("Auto-save PDF", "Saves a PDF copy to a fixed folder — no “Save as” window."),
           ("Your file names", "Choose the file name prefix, e.g. Invoice_2026-11-02_15-45.pdf."),
           ("Several multi printers", "Invoices, reports, receipts — each with its own printers and folder."),
           ("Paper size per printer", "A4, A3, A5, Letter, Legal or automatic."),
           ("Print history", "See every document, where it went and whether it succeeded."),
           ("Runs in the background", "Starts with Windows and recovers by itself — the app doesn’t need to be open."),
           ("5 languages", "Arabic, English, Spanish, French and German.")],
    use_title="Made for real work",
    uses=[("Shops & accounting", "Print the invoice on the printer and keep a PDF archive automatically."),
          ("Office + warehouse", "One print reaches the office printer and the warehouse printer together."),
          ("Clinics & services", "Give the customer a copy and keep one on file in a single step.")],
    faq_title="Frequently asked questions",
    faqs=[("Is MultiPrint free?", "Yes. It is free and open source under the MIT license."),
          ("How do I print to two printers at the same time?", "Create a multi printer in MultiPrint, select both printers, then print to the new printer from any app. The job is sent to both."),
          ("Can it print and save a PDF at the same time?", "Yes. Select “Microsoft Print to PDF” as one of the printers and choose a folder. The PDF is saved there automatically without asking."),
          ("Which Windows versions are supported?", "Windows 10 and Windows 11 (64-bit)."),
          ("Does the app have to stay open?", "No. A small background service starts with Windows and does the printing."),
          ("Windows says “Windows protected your PC”. Is it safe?", "The file is not code-signed yet, so SmartScreen shows a warning. Click “More info” → “Run anyway”. The full source code is public on GitHub.")],
    cta_title="Print once. Get it everywhere.", cta_text="Download MultiPrint and create your first multi printer in under a minute.",
    footer="MultiPrint is free and open-source software.", alt="MultiPrint app showing a multi printer linked to an Epson printer and a PDF folder",
    langlabel="Language",
)

C["ar"] = dict(
    dir="rtl", name="العربية", locale="ar_SA",
    title="MultiPrint | الطباعة على عدة طابعات في آنٍ واحد مع حفظ PDF تلقائيًا — مجاني لنظام Windows",
    desc="MultiPrint برنامج مجاني لنظام Windows يربط طابعتين أو أكثر بطابعة افتراضية واحدة؛ اطبع المستند مرة واحدة ليصل إلى جميع الطابعات في اللحظة نفسها، مع حفظ نسخة PDF تلقائيًا ودون إعدادات معقدة.",
    keywords="الطباعة على أكثر من طابعة في نفس الوقت, الطباعة على طابعتين في آن واحد, ربط طابعتين, طابعة افتراضية, حفظ PDF تلقائيًا عند الطباعة, الطباعة وحفظ PDF في الوقت نفسه, برنامج طباعة مجاني, طابعة متعددة, multi printer",
    h1="اطبع على جميع طابعاتك. في آنٍ واحد.",
    sub="طابعة افتراضية واحدة تُرسل كل مستند إلى الطابعات التي تختارها، وتحفظ نسخة PDF في المجلد المحدد تلقائيًا.",
    tagline="حلٌّ بسيط ومجاني، دون إعدادات معقدة",
    dl="تنزيل لنظام Windows", learn="تعرّف على آلية العمل", dl_note="Windows 10 و11 · مجاني · مفتوح المصدر", gh="المشروع على GitHub",
    nav_features="المزايا", nav_how="آلية العمل", nav_faq="الأسئلة الشائعة",
    specs=[("+2", "طابعة لكل مستند"), ("PDF", "نسخة تُحفظ تلقائيًا"), ("0", "إعدادات معقدة"), ("مجاني", "ومفتوح المصدر")],
    how_title="ثلاث خطوات فقط.",
    steps=[("أنشئ طابعة متعددة", "حدّد اسمًا للطابعة واختر طابعتين أو أكثر، سواء أكانت طابعات فعلية أم PDF أم كليهما."),
           ("اطبع كالمعتاد", "من Word أو Excel أو المتصفح أو نظامك المحاسبي، اختر الطابعة الجديدة من قائمة الطباعة."),
           ("تمّ", "يصل المستند إلى جميع الطابعات في اللحظة نفسها، وتُحفظ نسخة PDF في المجلد المحدد.")],
    feat_title="كل ما تحتاجه. لا أكثر.",
    feats=[("الطباعة على طابعتين أو أكثر", "أمر طباعة واحد يصل إلى جميع الطابعات المرتبطة."),
           ("حفظ PDF تلقائيًا", "نسخة PDF في مجلد ثابت دون نافذة «حفظ باسم»."),
           ("تسمية الملفات حسب رغبتك", "حدّد بداية اسم الملف، مثل: فاتورة_2026-11-02_15-45.pdf."),
           ("طابعات متعددة مستقلة", "للفواتير والتقارير والإيصالات، لكلٍّ منها طابعاتها ومجلدها."),
           ("مقاس الورق لكل طابعة", "A4 أو A3 أو A5 أو Letter أو Legal أو تلقائي."),
           ("سجل الطباعة", "اسم كل مستند، ووجهاته، ونتيجة طباعته."),
           ("يعمل في الخلفية", "يبدأ مع تشغيل Windows ويستعيد عمله تلقائيًا، دون الحاجة إلى إبقاء البرنامج مفتوحًا."),
           ("خمس لغات", "العربية والإنجليزية والإسبانية والفرنسية والألمانية.")],
    use_title="مصمَّم لبيئة الأعمال.",
    uses=[("المتاجر والمحاسبة", "طباعة الفاتورة للعميل مع أرشفة نسخة PDF تلقائيًا."),
          ("المكاتب والمستودعات", "مستند واحد يصل إلى طابعة المكتب وطابعة المستودع معًا."),
          ("العيادات ومراكز الخدمة", "نسخة للعميل ونسخة للأرشيف بخطوة واحدة.")],
    faq_title="الأسئلة الشائعة",
    faqs=[("هل البرنامج مجاني؟", "نعم، البرنامج مجاني ومفتوح المصدر بموجب ترخيص MIT."),
          ("كيف أطبع على طابعتين في الوقت نفسه؟", "أنشئ طابعة متعددة في MultiPrint واختر الطابعتين، ثم اطبع على الطابعة الجديدة من أي برنامج، وسيصل المستند إلى كلتيهما."),
          ("هل يمكن الطباعة وحفظ ملف PDF في الوقت نفسه؟", "نعم. اختر «Microsoft Print to PDF» ضمن الطابعات وحدّد مجلدًا، وسيُحفظ الملف فيه تلقائيًا دون أي استفسار."),
          ("ما إصدارات Windows المدعومة؟", "Windows 10 وWindows 11 (64 بت)."),
          ("هل يجب أن يبقى البرنامج مفتوحًا؟", "لا. تتولى خدمة صغيرة تعمل في الخلفية مع بدء تشغيل Windows تنفيذ الطباعة."),
          ("تظهر رسالة «Windows protected your PC»، فهل البرنامج آمن؟", "لم يُوقَّع الملف رقميًا بعد، لذا يعرض Windows هذا التنبيه. اختر «More info» ثم «Run anyway». الشيفرة المصدرية كاملة منشورة على GitHub.")],
    cta_title="اطبع مرة واحدة. في كل مكان.", cta_text="نزّل MultiPrint وأنشئ طابعتك المتعددة الأولى في أقل من دقيقة.",
    footer="MultiPrint برنامج مجاني ومفتوح المصدر.", alt="واجهة برنامج MultiPrint تعرض طابعة متعددة مرتبطة بطابعة Epson ومجلد PDF",
    langlabel="اللغة",
)

C["ru"] = dict(
    dir="ltr", name="Русский", locale="ru_RU",
    title="MultiPrint — печать на несколько принтеров одновременно и автосохранение PDF (бесплатно, Windows)",
    desc="Бесплатная программа для Windows: объединяет два и более принтера в один виртуальный принтер. Печатайте один раз — документ уходит на все принтеры сразу и автоматически сохраняется в PDF. Без сложных настроек.",
    keywords="печать на несколько принтеров одновременно, печать на два принтера, подключить два принтера, виртуальный принтер, автосохранение PDF при печати, дублирование печати, мультипринтер Windows, бесплатная программа для печати",
    h1="Печать на несколько принтеров одновременно — с автоматическим сохранением PDF",
    sub="MultiPrint добавляет в Windows один виртуальный принтер. Печатайте на него из любой программы — задание уйдёт на все выбранные принтеры, а копия PDF сохранится в вашу папку.",
    tagline="Простое бесплатное решение — без сложных настроек",
    dl="Скачать для Windows", dl_note="Windows 10 / 11 · Бесплатно · Открытый код", gh="Открыть на GitHub",
    nav_features="Возможности", nav_how="Как это работает", nav_faq="Вопросы",
    how_title="Готово за 3 шага",
    steps=[("Создайте мультипринтер", "Откройте MultiPrint, задайте имя и выберите два или более принтера — обычные, PDF или оба."),
           ("Печатайте как обычно", "В Word, Excel, браузере или учётной программе выберите новый принтер по имени."),
           ("Готово", "Документ печатается на всех принтерах одновременно, а PDF сохраняется в папку.")],
    feat_title="Всё нужное — ничего лишнего",
    feats=[("Печать на 2+ принтера", "Одно нажатие отправляет задание на все связанные принтеры."),
           ("Автосохранение PDF", "Копия PDF в выбранной папке — без окна «Сохранить как»."),
           ("Свои имена файлов", "Задайте префикс, например Счёт_2026-11-02_15-45.pdf."),
           ("Несколько мультипринтеров", "Счета, отчёты, чеки — у каждого свои принтеры и папка."),
           ("Формат бумаги", "A4, A3, A5, Letter, Legal или автоматически."),
           ("История печати", "Какой документ, куда ушёл и успешно ли."),
           ("Работает в фоне", "Запускается вместе с Windows и восстанавливается сам — окно программы можно закрыть."),
           ("5 языков интерфейса", "Арабский, английский, испанский, французский и немецкий.")],
    use_title="Для реальной работы",
    uses=[("Магазины и бухгалтерия", "Счёт печатается на принтере, а PDF-архив ведётся автоматически."),
          ("Офис и склад", "Одна печать — сразу на офисный и складской принтеры."),
          ("Клиники и сервис", "Копия клиенту и копия в архив за один шаг.")],
    faq_title="Частые вопросы",
    faqs=[("MultiPrint бесплатный?", "Да. Программа бесплатная, с открытым исходным кодом (лицензия MIT)."),
          ("Как печатать на два принтера одновременно?", "Создайте мультипринтер в MultiPrint, выберите оба принтера и печатайте на новый принтер из любой программы."),
          ("Можно печатать и сохранять PDF одновременно?", "Да. Добавьте «Microsoft Print to PDF» и выберите папку — PDF будет сохраняться автоматически без вопросов."),
          ("Какие версии Windows поддерживаются?", "Windows 10 и Windows 11 (64-бит)."),
          ("Программа должна быть открыта?", "Нет. Печатью занимается небольшая фоновая служба, которая стартует вместе с Windows."),
          ("Windows пишет «Windows protected your PC». Это безопасно?", "Файл пока не подписан цифровой подписью, поэтому SmartScreen показывает предупреждение. Нажмите «More info» → «Run anyway». Исходный код открыт на GitHub.")],
    cta_title="Печатайте один раз — получайте везде.", cta_text="Скачайте MultiPrint и создайте первый мультипринтер меньше чем за минуту.",
    footer="MultiPrint — бесплатная программа с открытым исходным кодом.", alt="Программа MultiPrint: мультипринтер, связанный с принтером Epson и папкой PDF",
    langlabel="Язык",
)

C["de"] = dict(
    dir="ltr", name="Deutsch", locale="de_DE",
    title="MultiPrint — Auf mehreren Druckern gleichzeitig drucken & PDF automatisch speichern (kostenlos, Windows)",
    desc="Kostenlose Windows-App, die zwei oder mehr Drucker zu einem virtuellen Drucker verbindet. Einmal drucken – der Auftrag geht gleichzeitig an alle Drucker und eine PDF-Kopie wird automatisch gespeichert. Ohne komplizierte Einrichtung.",
    keywords="auf mehreren Druckern gleichzeitig drucken, auf zwei Druckern drucken, zwei Drucker verbinden, virtueller Drucker, Druckauftrag duplizieren, PDF automatisch speichern beim Drucken, Mehrfachdrucker Windows, kostenlose Drucksoftware",
    h1="Auf mehreren Druckern gleichzeitig drucken — und PDF automatisch speichern",
    sub="MultiPrint fügt Windows einen virtuellen Drucker hinzu. Drucke aus jedem Programm darauf und der Auftrag geht an alle ausgewählten Drucker – plus eine automatische PDF-Kopie in deinem Ordner.",
    tagline="Einfach und kostenlos — ohne komplizierte Einstellungen",
    dl="Für Windows herunterladen", dl_note="Windows 10 / 11 · Kostenlos · Open Source", gh="Auf GitHub ansehen",
    nav_features="Funktionen", nav_how="So funktioniert's", nav_faq="FAQ",
    how_title="In 3 Schritten startklar",
    steps=[("Mehrfachdrucker anlegen", "MultiPrint öffnen, Namen vergeben und zwei oder mehr Drucker wählen – echte Drucker, PDF oder beides."),
           ("Wie gewohnt drucken", "In Word, Excel, im Browser oder in der Buchhaltung den neuen Drucker auswählen."),
           ("Fertig", "Alle Drucker erhalten das Dokument gleichzeitig, das PDF landet in deinem Ordner.")],
    feat_title="Alles, was du brauchst",
    feats=[("Auf 2+ Druckern drucken", "Ein Klick schickt denselben Auftrag an alle verknüpften Drucker."),
           ("PDF automatisch speichern", "PDF-Kopie in einem festen Ordner – ohne „Speichern unter“."),
           ("Eigene Dateinamen", "Präfix wählen, z. B. Rechnung_2026-11-02_15-45.pdf."),
           ("Mehrere Mehrfachdrucker", "Rechnungen, Berichte, Belege – jeweils mit eigenen Druckern und Ordner."),
           ("Papierformat pro Drucker", "A4, A3, A5, Letter, Legal oder automatisch."),
           ("Druckverlauf", "Welches Dokument, wohin und ob es geklappt hat."),
           ("Läuft im Hintergrund", "Startet mit Windows und erholt sich selbst – die App muss nicht offen sein."),
           ("5 Sprachen", "Arabisch, Englisch, Spanisch, Französisch und Deutsch.")],
    use_title="Für den echten Arbeitsalltag",
    uses=[("Handel & Buchhaltung", "Rechnung drucken und automatisch ein PDF-Archiv führen."),
          ("Büro + Lager", "Ein Druck erreicht Büro- und Lagerdrucker zugleich."),
          ("Praxen & Service", "Kundenkopie und Ablage in einem Schritt.")],
    faq_title="Häufige Fragen",
    faqs=[("Ist MultiPrint kostenlos?", "Ja. Kostenlos und Open Source unter der MIT-Lizenz."),
          ("Wie drucke ich gleichzeitig auf zwei Druckern?", "Lege in MultiPrint einen Mehrfachdrucker an, wähle beide Drucker und drucke aus jeder App auf den neuen Drucker."),
          ("Kann ich gleichzeitig drucken und als PDF speichern?", "Ja. Wähle „Microsoft Print to PDF“ als einen der Drucker und einen Ordner – das PDF wird dort ohne Nachfrage gespeichert."),
          ("Welche Windows-Versionen werden unterstützt?", "Windows 10 und Windows 11 (64 Bit)."),
          ("Muss die App geöffnet bleiben?", "Nein. Ein kleiner Hintergrunddienst startet mit Windows und übernimmt das Drucken."),
          ("Windows zeigt „Windows protected your PC“. Ist das sicher?", "Die Datei ist noch nicht digital signiert, daher warnt SmartScreen. Klicke „More info“ → „Run anyway“. Der Quellcode ist öffentlich auf GitHub.")],
    cta_title="Einmal drucken. Überall ankommen.", cta_text="Lade MultiPrint herunter und lege deinen ersten Mehrfachdrucker in unter einer Minute an.",
    footer="MultiPrint ist kostenlose Open-Source-Software.", alt="MultiPrint-App mit einem Mehrfachdrucker, verbunden mit einem Epson-Drucker und einem PDF-Ordner",
    langlabel="Sprache",
)

C["es"] = dict(
    dir="ltr", name="Español", locale="es_ES",
    title="MultiPrint — Imprimir en varias impresoras a la vez y guardar PDF automáticamente (gratis, Windows)",
    desc="Aplicación gratuita para Windows que une dos o más impresoras en una impresora virtual. Imprime una vez y el trabajo llega a todas las impresoras a la vez, con una copia PDF guardada automáticamente. Sin configuraciones complicadas.",
    keywords="imprimir en varias impresoras a la vez, imprimir en dos impresoras al mismo tiempo, conectar dos impresoras, impresora virtual, guardar PDF automáticamente al imprimir, duplicar trabajo de impresión, programa gratis de impresión",
    h1="Imprime en varias impresoras a la vez — y guarda un PDF automáticamente",
    sub="MultiPrint añade una impresora virtual a Windows. Imprime en ella desde cualquier programa y el trabajo llega a todas las impresoras elegidas, más una copia PDF en tu carpeta.",
    tagline="Una solución sencilla y gratuita — sin configuraciones complicadas",
    dl="Descargar para Windows", dl_note="Windows 10 / 11 · Gratis · Código abierto", gh="Ver en GitHub",
    nav_features="Funciones", nav_how="Cómo funciona", nav_faq="Preguntas",
    how_title="Listo en 3 pasos",
    steps=[("Crea una impresora múltiple", "Abre MultiPrint, ponle un nombre y elige dos o más impresoras: reales, PDF o ambas."),
           ("Imprime como siempre", "Desde Word, Excel, el navegador o tu programa de contabilidad, elige la nueva impresora."),
           ("Listo", "Todas las impresoras reciben el documento a la vez y el PDF se guarda en tu carpeta.")],
    feat_title="Todo lo que necesitas",
    feats=[("Imprime en 2+ impresoras", "Un clic envía el mismo trabajo a todas las impresoras vinculadas."),
           ("PDF automático", "Copia PDF en una carpeta fija, sin ventana de «Guardar como»."),
           ("Tus nombres de archivo", "Elige el prefijo, p. ej. Factura_2026-11-02_15-45.pdf."),
           ("Varias impresoras múltiples", "Facturas, informes, tickets: cada una con sus impresoras y carpeta."),
           ("Tamaño de papel", "A4, A3, A5, Carta, Legal o automático."),
           ("Historial", "Qué documento, a dónde fue y si salió bien."),
           ("En segundo plano", "Arranca con Windows y se recupera solo; la app no tiene que estar abierta."),
           ("5 idiomas", "Árabe, inglés, español, francés y alemán.")],
    use_title="Pensado para el trabajo real",
    uses=[("Tiendas y contabilidad", "Imprime la factura y guarda un archivo PDF automáticamente."),
          ("Oficina + almacén", "Una impresión llega a la impresora de la oficina y a la del almacén."),
          ("Clínicas y servicios", "Copia para el cliente y copia para el archivo en un paso.")],
    faq_title="Preguntas frecuentes",
    faqs=[("¿MultiPrint es gratis?", "Sí. Es gratuito y de código abierto (licencia MIT)."),
          ("¿Cómo imprimo en dos impresoras al mismo tiempo?", "Crea una impresora múltiple en MultiPrint, selecciona ambas impresoras e imprime en la nueva desde cualquier programa."),
          ("¿Puede imprimir y guardar PDF a la vez?", "Sí. Añade «Microsoft Print to PDF» y elige una carpeta; el PDF se guarda allí sin preguntar."),
          ("¿Qué versiones de Windows admite?", "Windows 10 y Windows 11 (64 bits)."),
          ("¿La app tiene que estar abierta?", "No. Un pequeño servicio en segundo plano arranca con Windows y se encarga de imprimir."),
          ("Windows dice «Windows protected your PC». ¿Es seguro?", "El archivo aún no tiene firma digital, por eso SmartScreen avisa. Pulsa «More info» → «Run anyway». El código es público en GitHub.")],
    cta_title="Imprime una vez. Llega a todas partes.", cta_text="Descarga MultiPrint y crea tu primera impresora múltiple en menos de un minuto.",
    footer="MultiPrint es software gratuito y de código abierto.", alt="Aplicación MultiPrint con una impresora múltiple vinculada a una Epson y una carpeta PDF",
    langlabel="Idioma",
)

C["fr"] = dict(
    dir="ltr", name="Français", locale="fr_FR",
    title="MultiPrint — Imprimer sur plusieurs imprimantes en même temps et enregistrer le PDF automatiquement (gratuit, Windows)",
    desc="Application Windows gratuite qui relie deux imprimantes ou plus à une imprimante virtuelle. Imprimez une fois : le travail part sur toutes les imprimantes en même temps, avec une copie PDF enregistrée automatiquement. Sans réglages compliqués.",
    keywords="imprimer sur plusieurs imprimantes en même temps, imprimer sur deux imprimantes, connecter deux imprimantes, imprimante virtuelle, enregistrer PDF automatiquement à l'impression, dupliquer impression, logiciel d'impression gratuit",
    h1="Imprimez sur plusieurs imprimantes à la fois — et enregistrez le PDF automatiquement",
    sub="MultiPrint ajoute une imprimante virtuelle à Windows. Imprimez dessus depuis n’importe quel logiciel : le travail part vers toutes les imprimantes choisies, avec une copie PDF dans votre dossier.",
    tagline="Une solution simple et gratuite — sans réglages compliqués",
    dl="Télécharger pour Windows", dl_note="Windows 10 / 11 · Gratuit · Open source", gh="Voir sur GitHub",
    nav_features="Fonctions", nav_how="Fonctionnement", nav_faq="FAQ",
    how_title="Prêt en 3 étapes",
    steps=[("Créez une imprimante multiple", "Ouvrez MultiPrint, nommez-la et choisissez deux imprimantes ou plus : réelles, PDF ou les deux."),
           ("Imprimez comme d’habitude", "Depuis Word, Excel, le navigateur ou votre logiciel de compta, choisissez la nouvelle imprimante."),
           ("C’est fait", "Toutes les imprimantes reçoivent le document en même temps et le PDF est enregistré.")],
    feat_title="L’essentiel, rien de plus",
    feats=[("Impression sur 2+ imprimantes", "Un clic envoie le même travail à toutes les imprimantes liées."),
           ("PDF automatique", "Copie PDF dans un dossier fixe, sans fenêtre « Enregistrer sous »."),
           ("Vos noms de fichiers", "Choisissez le préfixe, par ex. Facture_2026-11-02_15-45.pdf."),
           ("Plusieurs imprimantes multiples", "Factures, rapports, tickets : chacune avec ses imprimantes et son dossier."),
           ("Format du papier", "A4, A3, A5, Letter, Legal ou automatique."),
           ("Historique", "Quel document, vers où, et si tout s’est bien passé."),
           ("En arrière-plan", "Démarre avec Windows et redémarre seul ; l’application n’a pas besoin d’être ouverte."),
           ("5 langues", "Arabe, anglais, espagnol, français et allemand.")],
    use_title="Pensé pour le vrai travail",
    uses=[("Commerces et comptabilité", "Imprimez la facture et gardez une archive PDF automatiquement."),
          ("Bureau + entrepôt", "Une impression arrive au bureau et à l’entrepôt en même temps."),
          ("Cabinets et services", "Copie client et copie archive en une seule étape.")],
    faq_title="Questions fréquentes",
    faqs=[("MultiPrint est-il gratuit ?", "Oui. Gratuit et open source (licence MIT)."),
          ("Comment imprimer sur deux imprimantes en même temps ?", "Créez une imprimante multiple dans MultiPrint, sélectionnez les deux imprimantes, puis imprimez sur la nouvelle depuis n’importe quel logiciel."),
          ("Peut-il imprimer et enregistrer un PDF en même temps ?", "Oui. Ajoutez « Microsoft Print to PDF » et choisissez un dossier : le PDF y est enregistré sans question."),
          ("Quelles versions de Windows ?", "Windows 10 et Windows 11 (64 bits)."),
          ("L’application doit-elle rester ouverte ?", "Non. Un petit service d’arrière-plan démarre avec Windows et gère l’impression."),
          ("Windows affiche « Windows protected your PC ». Est-ce sûr ?", "Le fichier n’est pas encore signé numériquement, d’où l’avertissement SmartScreen. Cliquez « More info » → « Run anyway ». Le code source est public sur GitHub.")],
    cta_title="Imprimez une fois. Partout.", cta_text="Téléchargez MultiPrint et créez votre première imprimante multiple en moins d’une minute.",
    footer="MultiPrint est un logiciel libre et gratuit.", alt="Application MultiPrint avec une imprimante multiple reliée à une Epson et à un dossier PDF",
    langlabel="Langue",
)

# عناوين قصيرة بأسلوب الشركات
C["en"].update({'h1': 'Print to every printer. At once.', 'sub': 'One virtual printer that sends each document to the printers you choose — and saves a PDF copy to your folder automatically.', 'learn': 'See how it works', 'tagline': 'Simple. Free. No complicated setup.', 'specs': [('2+', 'printers per document'), ('PDF', 'saved automatically'), ('0', 'complicated settings'), ('Free', 'and open source')], 'how_title': 'Three steps. That’s it.', 'feat_title': 'Everything you need. Nothing you don’t.', 'use_title': 'Built for business.', 'cta_title': 'Print once. Everywhere.'})
C["ru"].update({'h1': 'Печать на все принтеры. Одновременно.', 'sub': 'Один виртуальный принтер отправляет каждый документ на выбранные принтеры и автоматически сохраняет копию PDF в вашу папку.', 'learn': 'Как это работает', 'tagline': 'Просто. Бесплатно. Без сложных настроек.', 'specs': [('2+', 'принтера на документ'), ('PDF', 'сохраняется автоматически'), ('0', 'сложных настроек'), ('Бесплатно', 'и с открытым кодом')], 'how_title': 'Всего три шага.', 'use_title': 'Создано для бизнеса.', 'cta_title': 'Печатайте один раз. Везде.'})
C["de"].update({'h1': 'Auf allen Druckern drucken. Gleichzeitig.', 'sub': 'Ein virtueller Drucker sendet jedes Dokument an die gewählten Drucker – und speichert automatisch eine PDF-Kopie in Ihrem Ordner.', 'learn': 'So funktioniert es', 'tagline': 'Einfach. Kostenlos. Ohne komplizierte Einrichtung.', 'specs': [('2+', 'Drucker pro Dokument'), ('PDF', 'automatisch gespeichert'), ('0', 'komplizierte Einstellungen'), ('Kostenlos', 'und Open Source')], 'how_title': 'Drei Schritte. Fertig.', 'use_title': 'Für Unternehmen entwickelt.', 'cta_title': 'Einmal drucken. Überall.'})
C["es"].update({'h1': 'Imprime en todas tus impresoras. A la vez.', 'sub': 'Una impresora virtual envía cada documento a las impresoras que elijas y guarda automáticamente una copia PDF en tu carpeta.', 'learn': 'Cómo funciona', 'tagline': 'Sencillo. Gratis. Sin configuraciones complicadas.', 'specs': [('2+', 'impresoras por documento'), ('PDF', 'guardado automático'), ('0', 'ajustes complicados'), ('Gratis', 'y de código abierto')], 'how_title': 'Tres pasos. Nada más.', 'use_title': 'Diseñado para empresas.', 'cta_title': 'Imprime una vez. En todas partes.'})
C["fr"].update({'h1': 'Imprimez sur toutes vos imprimantes. En même temps.', 'sub': 'Une imprimante virtuelle envoie chaque document aux imprimantes choisies et enregistre automatiquement une copie PDF dans votre dossier.', 'learn': 'Voir le fonctionnement', 'tagline': 'Simple. Gratuit. Sans réglages compliqués.', 'specs': [('2+', 'imprimantes par document'), ('PDF', 'enregistré automatiquement'), ('0', 'réglage compliqué'), ('Gratuit', 'et open source')], 'how_title': 'Trois étapes. C’est tout.', 'use_title': 'Conçu pour les entreprises.', 'cta_title': 'Imprimez une fois. Partout.'})

# ميزة سهولة الإعداد
C["en"]["feats"] = C["en"]["feats"] + [('Easy to set up', 'No drivers to install, no configuration — your first multi printer is ready in under a minute.')]
C["ar"]["feats"] = C["ar"]["feats"] + [('سهل الإعداد', 'دون تثبيت تعريفات أو إعدادات معقدة؛ تصبح طابعتك المتعددة الأولى جاهزة في أقل من دقيقة.')]
C["ru"]["feats"] = C["ru"]["feats"] + [('Простая настройка', 'Без установки драйверов и сложных настроек — первый мультипринтер готов меньше чем за минуту.')]
C["de"]["feats"] = C["de"]["feats"] + [('Schnell eingerichtet', 'Keine Treiberinstallation, keine Konfiguration – der erste Mehrfachdrucker ist in unter einer Minute bereit.')]
C["es"]["feats"] = C["es"]["feats"] + [('Fácil de configurar', 'Sin instalar controladores ni ajustes complicados: tu primera impresora múltiple, lista en menos de un minuto.')]
C["fr"]["feats"] = C["fr"]["feats"] + [('Facile à configurer', 'Aucun pilote à installer, aucun réglage compliqué : votre première imprimante multiple est prête en moins d’une minute.')]


# ======================= مراجعة نهائية: عناوين/أوصاف بطول مناسب لجوجل، توحيد الأسلوب
C["en"].update(
    title="MultiPrint – Print to Multiple Printers at Once & Save PDF",
    desc="Free Windows app that connects two or more printers to one virtual printer. Print once to all of them and save a PDF copy automatically. No complicated setup.",
)
C["ar"].update(
    title="MultiPrint | الطباعة على عدة طابعات في آنٍ واحد وحفظ PDF",
    desc="برنامج مجاني لنظام Windows يربط عدة طابعات بطابعة افتراضية واحدة؛ اطبع مرة واحدة على جميعها واحفظ نسخة PDF تلقائيًا، دون إعدادات معقدة.",
    dl_note="Windows 10 / 11 · مجاني · مفتوح المصدر",
)
C["ar"]["faqs"][2] = ("هل يمكن الطباعة وحفظ ملف PDF في الوقت نفسه؟",
                      "نعم. أضف «Microsoft Print to PDF» إلى الطابعات وحدّد مجلدًا، وستُحفظ الملفات فيه تلقائيًا دون أن يُطلب منك اختيار مكان الحفظ.")
C["ar"]["faqs"][5] = ("تظهر رسالة «Windows protected your PC»، فهل البرنامج آمن؟",
                      "لم يُوقَّع الملف رقميًا بعد، لذا يعرض Windows هذا التنبيه. اختر «More info» ثم «Run anyway». والشيفرة المصدرية منشورة بالكامل على GitHub.")

C["ru"].update(
    title="MultiPrint — печать на несколько принтеров одновременно",
    desc="Бесплатная программа для Windows: объединяет несколько принтеров в один виртуальный. Печать сразу на все принтеры и автосохранение PDF без сложных настроек.",
    feat_title="Всё нужное. Ничего лишнего.",
)
C["ru"]["steps"][1] = ("Печатайте как обычно", "В Word, Excel, браузере или бухгалтерской программе выберите новый принтер по имени.")
C["ru"]["uses"][2] = ("Клиники и сервисные центры", "Копия клиенту и копия в архив за один шаг.")
C["ru"]["faqs"][0] = ("Программа MultiPrint бесплатная?", "Да. Программа бесплатная, с открытым исходным кодом (лицензия MIT).")

C["de"].update(
    title="MultiPrint – auf mehreren Druckern gleichzeitig drucken",
    desc="Kostenlose Windows-App: mehrere Drucker zu einem virtuellen Drucker verbinden, auf allen gleichzeitig drucken und PDFs automatisch speichern.",
    nav_how="So funktioniert es",
    feat_title="Alles, was Sie brauchen. Nichts weiter.",
    cta_text="Laden Sie MultiPrint herunter und legen Sie Ihren ersten Mehrfachdrucker in unter einer Minute an.",
)
C["de"]["steps"][2] = ("Fertig", "Alle Drucker erhalten das Dokument gleichzeitig, das PDF wird in Ihrem Ordner gespeichert.")
C["de"]["faqs"][1] = ("Wie drucke ich gleichzeitig auf zwei Druckern?", "Legen Sie in MultiPrint einen Mehrfachdrucker an, wählen Sie beide Drucker und drucken Sie aus jeder Anwendung auf den neuen Drucker.")
C["de"]["faqs"][2] = ("Kann ich gleichzeitig drucken und als PDF speichern?", "Ja. Wählen Sie „Microsoft Print to PDF“ als einen der Drucker und legen Sie einen Ordner fest – das PDF wird dort ohne Nachfrage gespeichert.")
C["de"]["faqs"][5] = ("Windows zeigt „Windows protected your PC“. Ist das sicher?", "Die Datei ist noch nicht digital signiert, daher zeigt SmartScreen eine Warnung. Klicken Sie auf „More info“ → „Run anyway“. Der Quellcode ist öffentlich auf GitHub verfügbar.")

C["es"].update(
    title="MultiPrint – Imprimir en varias impresoras a la vez",
    desc="App gratuita para Windows: une varias impresoras en una impresora virtual, imprime en todas a la vez y guarda una copia PDF automáticamente. Sin complicaciones.",
    how_title="Tres pasos. Y listo.",
    feat_title="Todo lo que necesitas. Nada más.",
)
C["es"]["feats"][3] = ("Varias impresoras múltiples", "Facturas, informes, recibos: cada una con sus impresoras y su carpeta.")

C["fr"].update(
    title="MultiPrint – Imprimer sur plusieurs imprimantes à la fois",
    desc="Application Windows gratuite : reliez plusieurs imprimantes à une imprimante virtuelle, imprimez sur toutes à la fois et enregistrez le PDF automatiquement.",
    feat_title="L’essentiel. Rien de plus.",
)

# اسم الترخيص في التذييل
for _l, _v in {"en": "MIT License", "ar": "ترخيص MIT", "ru": "Лицензия MIT", "de": "MIT-Lizenz", "es": "Licencia MIT", "fr": "Licence MIT"}.items():
    C[_l]["license"] = _v

# ======================= SEO: سطر كلمات البحث فوق العنوان + صفحة الدليل لكل لغة
_EYEBROW = {
    "en": "Free Windows app to print to multiple printers at the same time",
    "ar": "برنامج مجاني لنظام Windows للطباعة على أكثر من طابعة في الوقت نفسه",
    "ru": "Бесплатная программа для Windows: печать на несколько принтеров одновременно",
    "de": "Kostenlose Windows-App zum gleichzeitigen Drucken auf mehreren Druckern",
    "es": "App gratuita para Windows para imprimir en varias impresoras a la vez",
    "fr": "Application Windows gratuite pour imprimer sur plusieurs imprimantes à la fois",
}
for _l, _v in _EYEBROW.items():
    C[_l]["eyebrow"] = _v

G = {}
G["en"] = dict(
    nav="Guide",
    title="How to Print to Two Printers at the Same Time in Windows 10/11",
    desc="Step-by-step guide: send one print job to two or more printers at once in Windows 10 and 11, and save a PDF copy automatically. Why printer pooling doesn't do it, and the free fix.",
    h1="How to print to two printers at the same time in Windows",
    lead="Windows sends every print job to one printer only. Here is how to print the same document on two or more printers at once, and keep an automatic PDF copy, in about a minute.",
    why_t="Why Windows can't do it by default",
    why=["When you press Print, Windows hands the job to exactly one printer. There is no built-in setting to duplicate it.",
         "“Printer pooling” in Printer properties is often suggested, but it does something else: it sends each job to the first free printer in the pool, so every page is printed once, not on every printer.",
         "Printing the document twice works, but it is slow and easy to forget, especially for invoices that need a paper copy and an archived PDF."],
    steps_t="Print to multiple printers with MultiPrint",
    steps=[("Download MultiPrint", "Download the free app for Windows 10 or 11, unzip it and run MultiPrint.exe. Approve the administrator prompt once."),
           ("Add a multi printer", "Click Add printer and give it a name, for example “Invoices”."),
           ("Choose the printers", "Tick two or more printers. Add “Microsoft Print to PDF” if you also want a PDF copy."),
           ("Pick the PDF folder", "If PDF is selected, choose a folder and an optional file name prefix. Files are saved there automatically."),
           ("Print from any app", "In Word, Excel, your browser or accounting software, choose the new printer by name and print."),
           ("Check the history", "Each document appears in the print history with every destination and its result.")],
    tip_t="Print and save as PDF at the same time",
    tip="Select one real printer plus “Microsoft Print to PDF”. You get the paper copy and a PDF named like Invoice_2026-11-02_15-45-00.pdf in the folder you chose, without a Save As window.",
    faq=[("Can Windows print to two printers at once without extra software?", "No. Windows sends a job to one printer. Printer pooling only spreads jobs across printers; it does not print on all of them."),
         ("Does it work with network and USB printers?", "Yes. Any printer installed in Windows can be used, including network, USB and receipt printers."),
         ("Can I use different paper sizes?", "Each multi printer has a paper size setting (A4, A3, A5, Letter, Legal or automatic). Other settings use each printer's defaults."),
         ("Is it free?", "Yes. MultiPrint is free and open source under the MIT license.")],
    back="Back to MultiPrint", cta="Download for Windows",
)
G["ar"] = dict(
    nav="الدليل",
    title="كيف تطبع على طابعتين في الوقت نفسه في Windows 10 و11",
    desc="دليل خطوة بخطوة لإرسال أمر طباعة واحد إلى طابعتين أو أكثر في الوقت نفسه في Windows 10 و11 مع حفظ نسخة PDF تلقائيًا، ولماذا لا تؤدي ميزة Printer Pooling هذه المهمة.",
    h1="كيف تطبع على طابعتين في الوقت نفسه في Windows",
    lead="يرسل Windows كل أمر طباعة إلى طابعة واحدة فقط. يشرح هذا الدليل كيفية طباعة المستند نفسه على طابعتين أو أكثر في آنٍ واحد، مع الاحتفاظ بنسخة PDF تلقائيًا، في دقيقة تقريبًا.",
    why_t="لماذا لا يتيح Windows ذلك افتراضيًا؟",
    why=["عند الضغط على «طباعة» يرسل Windows المستند إلى طابعة واحدة فقط، ولا يوجد إعداد مدمج لتكراره على طابعة أخرى.",
         "يُقترح كثيرًا استخدام ميزة «Printer Pooling» من خصائص الطابعة، لكنها توزّع المهام على أول طابعة متاحة، فيُطبع المستند مرة واحدة لا على جميع الطابعات.",
         "إعادة الطباعة يدويًا مرتين حلٌّ بطيء ومعرّض للنسيان، خاصة في الفواتير التي تحتاج إلى نسخة ورقية ونسخة PDF للأرشيف."],
    steps_t="الطباعة على عدة طابعات باستخدام MultiPrint",
    steps=[("نزّل MultiPrint", "نزّل البرنامج المجاني لنظام Windows 10 أو 11، وفكّ الضغط وشغّل MultiPrint.exe، ووافق على طلب صلاحيات المسؤول مرة واحدة."),
           ("أضف طابعة متعددة", "اختر «إضافة طابعة» وأدخل اسمًا لها، مثل «الفواتير»."),
           ("اختر الطابعات", "حدّد طابعتين أو أكثر، وأضف «Microsoft Print to PDF» إذا أردت نسخة PDF أيضًا."),
           ("حدّد مجلد PDF", "عند اختيار PDF، حدّد المجلد وبداية اسم الملف (اختياريًا)، وستُحفظ الملفات فيه تلقائيًا."),
           ("اطبع من أي تطبيق", "من Word أو Excel أو المتصفح أو النظام المحاسبي، اختر الطابعة الجديدة باسمها ثم اطبع."),
           ("راجع سجل الطباعة", "يظهر كل مستند في سجل الطباعة مع وجهاته ونتيجة كلٍّ منها.")],
    tip_t="الطباعة والحفظ بصيغة PDF في الوقت نفسه",
    tip="اختر طابعة فعلية مع «Microsoft Print to PDF»، فتحصل على النسخة الورقية وعلى ملف PDF باسم مثل فاتورة_2026-11-02_15-45-00.pdf في المجلد المحدد، دون نافذة «حفظ باسم».",
    faq=[("هل يمكن الطباعة على طابعتين في Windows دون برامج إضافية؟", "لا. يرسل Windows أمر الطباعة إلى طابعة واحدة، وميزة Printer Pooling توزّع المهام فقط ولا تطبع على جميع الطابعات."),
         ("هل يعمل مع طابعات الشبكة وطابعات USB؟", "نعم، يمكن استخدام أي طابعة مثبتة في Windows، بما فيها طابعات الشبكة وUSB وطابعات الإيصالات."),
         ("هل يمكن تحديد مقاس الورق؟", "لكل طابعة متعددة إعداد لمقاس الورق (A4 أو A3 أو A5 أو Letter أو Legal أو تلقائي)، وتُستخدم الإعدادات الافتراضية لكل طابعة فيما عدا ذلك."),
         ("هل البرنامج مجاني؟", "نعم، MultiPrint مجاني ومفتوح المصدر بموجب ترخيص MIT.")],
    back="العودة إلى MultiPrint", cta="تنزيل لنظام Windows",
)
G["ru"] = dict(
    nav="Инструкция",
    title="Как печатать на два принтера одновременно в Windows 10/11",
    desc="Пошаговая инструкция: как отправить одно задание на два и более принтера одновременно в Windows 10 и 11 и автоматически сохранить PDF. Почему пул принтеров для этого не подходит.",
    h1="Как печатать на два принтера одновременно в Windows",
    lead="Windows отправляет каждое задание только на один принтер. Ниже показано, как за минуту настроить печать одного документа сразу на два и более принтера с автоматическим сохранением PDF.",
    why_t="Почему Windows не умеет этого по умолчанию",
    why=["При нажатии «Печать» Windows передаёт задание ровно одному принтеру. Встроенной настройки для дублирования нет.",
         "Часто советуют «пул принтеров» в свойствах принтера, но он отправляет задание на первый свободный принтер, а не на все сразу.",
         "Можно печатать документ дважды, но это медленно и легко забыть — особенно со счетами, где нужны бумажная копия и PDF в архиве."],
    steps_t="Печать на несколько принтеров с MultiPrint",
    steps=[("Скачайте MultiPrint", "Скачайте бесплатную программу для Windows 10 или 11, распакуйте и запустите MultiPrint.exe. Один раз подтвердите запрос администратора."),
           ("Добавьте мультипринтер", "Нажмите «Добавить принтер» и задайте имя, например «Счета»."),
           ("Выберите принтеры", "Отметьте два или более принтера. Добавьте «Microsoft Print to PDF», если нужна копия PDF."),
           ("Укажите папку для PDF", "Если выбран PDF, укажите папку и при желании префикс имени файла — файлы будут сохраняться туда автоматически."),
           ("Печатайте из любой программы", "В Word, Excel, браузере или учётной программе выберите новый принтер по имени."),
           ("Проверьте историю", "Каждый документ появляется в истории печати с результатом по каждому принтеру.")],
    tip_t="Печать и сохранение в PDF одновременно",
    tip="Выберите обычный принтер и «Microsoft Print to PDF». Вы получите бумажную копию и PDF с именем вроде Счёт_2026-11-02_15-45-00.pdf в выбранной папке без окна «Сохранить как».",
    faq=[("Можно ли печатать на два принтера в Windows без дополнительных программ?", "Нет. Windows отправляет задание на один принтер, а пул принтеров лишь распределяет задания, но не печатает на всех."),
         ("Работает ли с сетевыми и USB-принтерами?", "Да. Подходит любой принтер, установленный в Windows, включая сетевые, USB и чековые принтеры."),
         ("Можно ли задать формат бумаги?", "У каждого мультипринтера есть настройка формата (A4, A3, A5, Letter, Legal или автоматически). Остальные параметры берутся из настроек принтера."),
         ("Это бесплатно?", "Да. MultiPrint бесплатный, с открытым исходным кодом (лицензия MIT).")],
    back="Назад к MultiPrint", cta="Скачать для Windows",
)
G["de"] = dict(
    nav="Anleitung",
    title="Auf zwei Druckern gleichzeitig drucken in Windows 10/11",
    desc="Schritt-für-Schritt-Anleitung: einen Druckauftrag in Windows 10 und 11 gleichzeitig an zwei oder mehr Drucker senden und automatisch als PDF speichern. Warum Druckerpools das nicht leisten.",
    h1="So drucken Sie in Windows gleichzeitig auf zwei Druckern",
    lead="Windows sendet jeden Druckauftrag nur an einen Drucker. Diese Anleitung zeigt, wie Sie dasselbe Dokument in etwa einer Minute auf zwei oder mehr Druckern gleichzeitig drucken und automatisch eine PDF-Kopie speichern.",
    why_t="Warum Windows das standardmäßig nicht kann",
    why=["Beim Drucken übergibt Windows den Auftrag genau einem Drucker. Eine integrierte Einstellung zum Duplizieren gibt es nicht.",
         "Oft wird der „Druckerpool“ in den Druckereigenschaften empfohlen. Er sendet jeden Auftrag jedoch an den ersten freien Drucker – nicht an alle.",
         "Zweimal drucken funktioniert, ist aber langsam und fehleranfällig, besonders bei Rechnungen, die auf Papier und als PDF im Archiv benötigt werden."],
    steps_t="Mit MultiPrint auf mehreren Druckern drucken",
    steps=[("MultiPrint herunterladen", "Laden Sie die kostenlose App für Windows 10 oder 11 herunter, entpacken Sie sie und starten Sie MultiPrint.exe. Bestätigen Sie einmalig die Administratorabfrage."),
           ("Mehrfachdrucker anlegen", "Klicken Sie auf „Drucker hinzufügen“ und vergeben Sie einen Namen, z. B. „Rechnungen“."),
           ("Drucker auswählen", "Wählen Sie zwei oder mehr Drucker. Fügen Sie „Microsoft Print to PDF“ hinzu, wenn Sie auch eine PDF-Kopie möchten."),
           ("PDF-Ordner festlegen", "Bei PDF wählen Sie einen Ordner und optional ein Dateinamen-Präfix. Die Dateien werden dort automatisch gespeichert."),
           ("Aus jeder Anwendung drucken", "Wählen Sie in Word, Excel, im Browser oder in der Buchhaltung den neuen Drucker aus."),
           ("Verlauf prüfen", "Jedes Dokument erscheint im Druckverlauf mit allen Zielen und deren Ergebnis.")],
    tip_t="Gleichzeitig drucken und als PDF speichern",
    tip="Wählen Sie einen echten Drucker und „Microsoft Print to PDF“. Sie erhalten den Ausdruck und eine PDF-Datei wie Rechnung_2026-11-02_15-45-00.pdf im gewählten Ordner – ohne „Speichern unter“.",
    faq=[("Kann Windows ohne Zusatzsoftware auf zwei Druckern gleichzeitig drucken?", "Nein. Windows sendet einen Auftrag an einen Drucker; ein Druckerpool verteilt Aufträge nur und druckt nicht auf allen."),
         ("Funktioniert es mit Netzwerk- und USB-Druckern?", "Ja. Jeder in Windows installierte Drucker funktioniert, auch Netzwerk-, USB- und Bondrucker."),
         ("Kann ich das Papierformat festlegen?", "Jeder Mehrfachdrucker hat eine Formateinstellung (A4, A3, A5, Letter, Legal oder automatisch). Weitere Einstellungen kommen vom jeweiligen Drucker."),
         ("Ist es kostenlos?", "Ja. MultiPrint ist kostenlos und Open Source unter der MIT-Lizenz.")],
    back="Zurück zu MultiPrint", cta="Für Windows herunterladen",
)
G["es"] = dict(
    nav="Guía",
    title="Cómo imprimir en dos impresoras a la vez en Windows 10/11",
    desc="Guía paso a paso para enviar un trabajo a dos o más impresoras a la vez en Windows 10 y 11 y guardar una copia PDF automáticamente. Por qué la agrupación de impresoras no sirve para esto.",
    h1="Cómo imprimir en dos impresoras a la vez en Windows",
    lead="Windows envía cada trabajo a una sola impresora. Así puedes imprimir el mismo documento en dos o más impresoras a la vez, con una copia PDF automática, en un minuto.",
    why_t="Por qué Windows no lo hace por defecto",
    why=["Al pulsar Imprimir, Windows entrega el trabajo a una única impresora. No existe un ajuste integrado para duplicarlo.",
         "Se suele recomendar la «agrupación de impresoras» (printer pooling), pero envía cada trabajo a la primera impresora libre, no a todas.",
         "Imprimir dos veces funciona, pero es lento y fácil de olvidar, sobre todo con facturas que necesitan copia en papel y PDF archivado."],
    steps_t="Imprimir en varias impresoras con MultiPrint",
    steps=[("Descarga MultiPrint", "Descarga la app gratuita para Windows 10 u 11, descomprímela y ejecuta MultiPrint.exe. Acepta una vez el aviso de administrador."),
           ("Añade una impresora múltiple", "Pulsa Añadir impresora y ponle un nombre, por ejemplo «Facturas»."),
           ("Elige las impresoras", "Marca dos o más impresoras. Añade «Microsoft Print to PDF» si también quieres una copia PDF."),
           ("Elige la carpeta PDF", "Si eliges PDF, indica la carpeta y un prefijo opcional para el nombre. Los archivos se guardan allí automáticamente."),
           ("Imprime desde cualquier app", "En Word, Excel, el navegador o tu programa de contabilidad, elige la nueva impresora."),
           ("Revisa el historial", "Cada documento aparece en el historial con cada destino y su resultado.")],
    tip_t="Imprimir y guardar en PDF a la vez",
    tip="Elige una impresora real y «Microsoft Print to PDF». Obtienes la copia impresa y un PDF como Factura_2026-11-02_15-45-00.pdf en la carpeta elegida, sin ventana de «Guardar como».",
    faq=[("¿Puede Windows imprimir en dos impresoras sin programas adicionales?", "No. Windows envía el trabajo a una impresora; la agrupación de impresoras solo reparte trabajos, no imprime en todas."),
         ("¿Funciona con impresoras de red y USB?", "Sí. Sirve cualquier impresora instalada en Windows, incluidas las de red, USB y de tickets."),
         ("¿Puedo elegir el tamaño de papel?", "Cada impresora múltiple tiene un ajuste de tamaño (A4, A3, A5, Carta, Legal o automático). El resto de ajustes son los de cada impresora."),
         ("¿Es gratis?", "Sí. MultiPrint es gratuito y de código abierto (licencia MIT).")],
    back="Volver a MultiPrint", cta="Descargar para Windows",
)
G["fr"] = dict(
    nav="Guide",
    title="Imprimer sur deux imprimantes en même temps sous Windows 10/11",
    desc="Guide pas à pas pour envoyer une impression à deux imprimantes ou plus en même temps sous Windows 10 et 11 et enregistrer une copie PDF automatiquement. Pourquoi le pool d’imprimantes ne suffit pas.",
    h1="Comment imprimer sur deux imprimantes en même temps sous Windows",
    lead="Windows envoie chaque impression à une seule imprimante. Voici comment imprimer le même document sur deux imprimantes ou plus à la fois, avec une copie PDF automatique, en une minute environ.",
    why_t="Pourquoi Windows ne le fait pas par défaut",
    why=["Quand vous cliquez sur Imprimer, Windows confie le travail à une seule imprimante. Aucun réglage intégré ne permet de le dupliquer.",
         "Le « pool d’imprimantes » est souvent conseillé, mais il envoie chaque travail à la première imprimante libre, pas à toutes.",
         "Imprimer deux fois fonctionne, mais c’est lent et facile à oublier, surtout pour les factures qui exigent un papier et un PDF archivé."],
    steps_t="Imprimer sur plusieurs imprimantes avec MultiPrint",
    steps=[("Téléchargez MultiPrint", "Téléchargez l’application gratuite pour Windows 10 ou 11, décompressez-la et lancez MultiPrint.exe. Acceptez une fois la demande administrateur."),
           ("Ajoutez une imprimante multiple", "Cliquez sur Ajouter une imprimante et donnez-lui un nom, par exemple « Factures »."),
           ("Choisissez les imprimantes", "Cochez deux imprimantes ou plus. Ajoutez « Microsoft Print to PDF » pour obtenir aussi une copie PDF."),
           ("Choisissez le dossier PDF", "Si le PDF est sélectionné, indiquez le dossier et un préfixe de nom facultatif. Les fichiers y sont enregistrés automatiquement."),
           ("Imprimez depuis n’importe quel logiciel", "Dans Word, Excel, le navigateur ou votre logiciel de compta, choisissez la nouvelle imprimante."),
           ("Consultez l’historique", "Chaque document apparaît dans l’historique avec chaque destination et son résultat.")],
    tip_t="Imprimer et enregistrer en PDF en même temps",
    tip="Sélectionnez une imprimante réelle et « Microsoft Print to PDF ». Vous obtenez le papier et un PDF nommé comme Facture_2026-11-02_15-45-00.pdf dans le dossier choisi, sans fenêtre « Enregistrer sous ».",
    faq=[("Windows peut-il imprimer sur deux imprimantes sans logiciel supplémentaire ?", "Non. Windows envoie un travail à une imprimante ; le pool d’imprimantes répartit seulement les travaux sans imprimer sur toutes."),
         ("Est-ce compatible avec les imprimantes réseau et USB ?", "Oui. Toute imprimante installée dans Windows convient, y compris réseau, USB et imprimantes de tickets."),
         ("Puis-je choisir le format du papier ?", "Chaque imprimante multiple a un réglage de format (A4, A3, A5, Letter, Legal ou automatique). Les autres réglages sont ceux de chaque imprimante."),
         ("Est-ce gratuit ?", "Oui. MultiPrint est gratuit et open source (licence MIT).")],
    back="Retour à MultiPrint", cta="Télécharger pour Windows",
)
# أوصاف الدليل بطول مناسب لنتائج جوجل (≤ 160 حرف)
G["en"]["desc"] = "Send one print job to two or more printers at once in Windows 10 and 11, and save a PDF copy automatically. Why printer pooling won't do it, and the free fix."
G["ar"]["desc"] = "اطبع المستند على طابعتين أو أكثر في الوقت نفسه في Windows 10 و11 مع حفظ نسخة PDF تلقائيًا، ولماذا لا تؤدي ميزة Printer Pooling هذه المهمة."
G["ru"]["desc"] = "Как отправить одно задание сразу на два и более принтера в Windows 10 и 11 и сохранить PDF. Почему пул принтеров не подходит и бесплатное решение."
G["de"]["desc"] = "Einen Druckauftrag in Windows 10 und 11 gleichzeitig an mehrere Drucker senden und als PDF speichern. Warum Druckerpools das nicht können – die kostenlose Lösung."
G["es"]["desc"] = "Envía un trabajo a dos o más impresoras a la vez en Windows 10 y 11 y guarda un PDF automáticamente. Por qué la agrupación no sirve y la solución gratuita."
G["fr"]["desc"] = "Envoyez une impression à plusieurs imprimantes en même temps sous Windows 10 et 11 et enregistrez un PDF. Pourquoi le pool d’imprimantes ne suffit pas."
G["en"]["title"] = "How to Print to Two Printers at Once in Windows 10/11"
G["fr"]["title"] = "Imprimer sur deux imprimantes à la fois sous Windows"
