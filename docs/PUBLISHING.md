<div dir="rtl">

# النشر على GitHub والظهور في محركات البحث

جميع الخطوات مجانية ولا تتطلب تعديل أي ملف؛ إذ يُضاف رابط الموقع ورابط التنزيل تلقائيًا عند النشر.

## الخطوة 1: إنشاء المستودع
1. سجّل الدخول إلى [github.com](https://github.com)، أو أنشئ حسابًا مجانيًا.
2. افتح [github.com/new](https://github.com/new) وأدخل البيانات التالية:
   - **Repository name**: `multiprint`
   - **Description** (مهمة لمحركات البحث):
     `Print to multiple printers at once & auto-save PDF — free Windows virtual printer | الطباعة على عدة طابعات في آنٍ واحد`
   - **Public**
   - لا تحدد خيار *Add a README*.
3. اضغط **Create repository**.

## الخطوة 2: رفع الملفات من المتصفح
1. في صفحة المستودع الفارغة اختر **uploading an existing file**.
2. افتح المجلد `multiprint` على جهازك، وحدّد جميع محتوياته (Ctrl+A) واسحبها إلى الصفحة.
3. اضغط **Commit changes**.

> إذا لم يُرفع المجلد `.github` (قد يخفيه Windows)، فاختر **Add file ← Create new file**، واكتب في حقل الاسم `.github/workflows/release.yml` والصق محتوى الملف، ثم كرّر ذلك مع `pages.yml`.
> بديلًا عن ذلك يمكنك استخدام [GitHub Desktop](https://desktop.github.com): **File ← Add local repository ← Publish**.

## الخطوة 3: تفعيل الموقع (مرة واحدة)
1. افتح **Settings ← Pages**.
2. اختر **GitHub Actions** في خانة **Source**.
3. افتح **Actions ← Website ← Run workflow**.
4. بعد دقيقة تقريبًا يصبح الموقع متاحًا على: `https://اسم-الحساب.github.io/multiprint/`
5. في صفحة المستودع اضغط ⚙️ بجوار **About**، وفعّل **Use your GitHub Pages website**، وأضف في **Topics**:
   `windows` `printer` `virtual-printer` `print` `pdf` `multiple-printers` `print-to-pdf` `printing` `business` `free-software`

## الخطوة 4: الإصدار الأول (لتفعيل زر التنزيل)
1. افتح **Releases ← Create a new release**.
2. في **Choose a tag** اكتب `v2.2.5` ثم **Create new tag**.
3. في **Title** اكتب `MultiPrint 2.2.5` ثم اضغط **Publish release**.
4. خلال دقيقتين يبني GitHub البرنامج ويضيف `MultiPrint.zip` إلى الإصدار تلقائيًا (يمكنك المتابعة من **Actions**).

## الخطوة 5: محرك البحث Google
يكتشف Google الموقع تلقائيًا مع الوقت، وتُسرّع الخطوات التالية فهرسته:
1. افتح [Google Search Console](https://search.google.com/search-console) واختر **Add property ← URL prefix** والصق رابط الموقع.
2. اختر طريقة التحقق **HTML file** ونزّل الملف (اسمه مثل `google1234abcd.html`).
3. في المستودع افتح المجلد `website` واختر **Add file ← Upload files** وارفع الملف ثم **Commit**. انتظر دقيقة وعُد إلى Google واضغط **Verify**.
4. من القائمة اختر **Sitemaps** واكتب `sitemap.xml` ثم **Submit**.
5. من **URL inspection** الصق رابط كل صفحة (`/` و`/ar/` و`/guide/` و`/ar/guide/`…) واختر **Request indexing**.
6. سجّل الموقع أيضًا في [Bing Webmaster Tools](https://www.bing.com/webmasters) (يمكن استيراده من Google Search Console بضغطة)، وفي [Yandex Webmaster](https://webmaster.yandex.com) للبحث بالروسية.

يستغرق الظهور في نتائج البحث عادةً من عدة أيام إلى بضعة أسابيع، ويُسرّعه نشر رابط الموقع في المنصات والمجتمعات المهنية ذات الصلة.

## تحسينات محركات البحث المضمّنة في الموقع
- صفحة مستقلة لكل لغة: `/` (الإنجليزية) و`/ar/` و`/ru/` و`/de/` و`/es/` و`/fr/`، لكلٍّ منها عنوان ووصف وكلمات بحث بلغتها.
- صفحة دليل لكل لغة (`/guide/` و`/ar/guide/`…) تجيب عن سؤال «كيف أطبع على طابعتين في الوقت نفسه في Windows؟» وتوضح لماذا لا تؤدي ميزة Printer Pooling هذه المهمة، وترتبط بها الصفحة الرئيسية.
- سطر أعلى العنوان الرئيسي يتضمن عبارة البحث الأساسية بكل لغة.
- روابط `hreflang` بين اللغات، ورابط `canonical` لكل صفحة.
- بيانات منظّمة (Schema.org) من نوعي **SoftwareApplication** و**FAQPage**، ما قد يتيح ظهور الأسئلة الشائعة مباشرة في نتائج البحث.
- ملفا `sitemap.xml` و`robots.txt`.
- وسوم Open Graph لعرض الرابط بصورة وعنوان عند مشاركته.
- تصميم خفيف وسريع ومتوافق مع الأجهزة المحمولة، ويدعم الوضع الداكن وتفضيلات إمكانية الوصول.

## تعديل محتوى الموقع
توجد جميع النصوص في `tools/site_content.py`. بعد التعديل نفّذ:
```bash
python tools/build_site.py
```
ثم ارفع المجلد `website` المحدَّث، وسيُعاد نشر الموقع تلقائيًا.

## إصدار تحديثات البرنامج
1. ارفع الشيفرة المحدَّثة.
2. حدّث `CHANGELOG.md` وقيمة `VERSION` في `tools/site_content.py`، ثم نفّذ `build_site.py`.
3. أنشئ Release جديدًا برقم أعلى (`v2.1.2`…)، وسيشير زر التنزيل في الموقع إلى أحدث إصدار تلقائيًا.

## التوقيع الرقمي (اختياري، بمقابل مادي)
لا تختفي رسالة **Windows protected your PC** إلا بتوقيع الملف التنفيذي بشهادة Code Signing من جهة معتمدة (مثل Sectigo وDigiCert وSSL.com) أو عبر خدمة Microsoft Artifact Signing. وعند توفر الشهادة تُضاف خطوة التوقيع إلى `release.yml`.

</div>
