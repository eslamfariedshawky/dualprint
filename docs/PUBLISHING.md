# Publishing on GitHub and Appearing in Search Engines

All steps are free and require no file changes; the website link and the download link are added automatically on publishing.

## Step 1: Create the repository
1. Sign in to [github.com](https://github.com), or create a free account.
2. Open [github.com/new](https://github.com/new) and enter the following:
   - **Repository name**: `multiprint`
   - **Description** (important for search engines; the Arabic part is intentional, for Arabic search results):
     `Print to multiple printers at once & auto-save PDF — free Windows virtual printer | الطباعة على عدة طابعات في آنٍ واحد`
   - **Public**
   - Do not select *Add a README*.
3. Click **Create repository**.

## Step 2: Upload the files from the browser
1. On the empty repository page, choose **uploading an existing file**.
2. Open the `multiprint` folder on your computer, select all its contents (Ctrl+A) and drag them onto the page.
3. Click **Commit changes**.

> If the `.github` folder was not uploaded (Windows may hide it), choose **Add file → Create new file**, type `.github/workflows/release.yml` in the name field and paste the file's contents, then repeat for `pages.yml`.
> Alternatively, you can use [GitHub Desktop](https://desktop.github.com): **File → Add local repository → Publish**.

## Step 3: Enable the website (once)
1. Open **Settings → Pages**.
2. Choose **GitHub Actions** under **Source**.
3. Open **Actions → Website → Run workflow**.
4. After about a minute, the website is available at: `https://<account-name>.github.io/multiprint/`
5. On the repository page, click ⚙️ next to **About**, enable **Use your GitHub Pages website**, and add these under **Topics**:
   `windows` `printer` `virtual-printer` `print` `pdf` `multiple-printers` `print-to-pdf` `printing` `business` `free-software`

## Step 4: First release (to enable the download button)
1. Open **Releases → Create a new release**.
2. In **Choose a tag**, type `v2.2.5`, then **Create new tag**.
3. In **Title**, type `MultiPrint 2.2.5`, then click **Publish release**.
4. Within two minutes, GitHub builds the app and adds `MultiPrint.zip` to the release automatically (you can follow progress under **Actions**).

## Step 5: Google search
Google discovers the website automatically over time; the following steps speed up indexing:
1. Open [Google Search Console](https://search.google.com/search-console), choose **Add property → URL prefix** and paste the website link.
2. Choose the **HTML file** verification method and download the file (its name looks like `google1234abcd.html`).
3. In the repository, open the `website` folder, choose **Add file → Upload files**, upload the file, then **Commit**. Wait a minute, go back to Google and click **Verify**.
4. From the menu, choose **Sitemaps**, type `sitemap.xml`, then **Submit**.
5. In **URL inspection**, paste the link of each page (`/`, `/ar/`, `/guide/`, `/ar/guide/`…) and choose **Request indexing**.
6. Also register the website in [Bing Webmaster Tools](https://www.bing.com/webmasters) (it can be imported from Google Search Console in one click), and in [Yandex Webmaster](https://webmaster.yandex.com) for Russian search.

Appearing in search results usually takes from several days to a few weeks. Sharing the website link on relevant professional platforms and communities speeds it up.

## Search engine optimizations built into the website
- A separate page for each language: `/` (English), `/ar/`, `/ru/`, `/de/`, `/es/` and `/fr/`, each with its own title, description and search keywords in that language.
- A guide page for each language (`/guide/`, `/ar/guide/`…) that answers the question "How do I print to two printers at the same time in Windows?", explains why the Printer Pooling feature does not do this job, and is linked from the home page.
- A line above the main heading containing the main search phrase in each language.
- `hreflang` links between languages, and a `canonical` link for each page.
- Structured data (Schema.org) of the **SoftwareApplication** and **FAQPage** types, which may allow the FAQ to appear directly in search results.
- `sitemap.xml` and `robots.txt` files.
- Open Graph tags so the link shows an image and title when shared.
- A light, fast, mobile-friendly design that supports dark mode and accessibility preferences.

## Editing the website content
All texts are in `tools/site_content.py`. After editing, run:
```bash
python tools/build_site.py
```
Then upload the updated `website` folder, and the website will be republished automatically.

## Releasing app updates
1. Upload the updated code.
2. Update `CHANGELOG.md` and the `VERSION` value in `tools/site_content.py`, then run `build_site.py`.
3. Create a new Release with a higher number (`v2.1.2`…); the download button on the website will point to the latest release automatically.

## Code signing (optional, paid)
The **Windows protected your PC** message only goes away when the executable is signed with a Code Signing certificate from a trusted authority (such as Sectigo, DigiCert and SSL.com) or through the Microsoft Artifact Signing service. Once a certificate is available, a signing step is added to `release.yml`.
