# User Guide

## Requirements
- Windows 10 or Windows 11 (64-bit).
- Administrator rights to add printers; the app requests them automatically.
- **Microsoft Print to PDF** enabled (it is enabled by default in Windows).
- An internet connection on first use only, to download SumatraPDF, the tool used to print on physical printers.

## Installation
1. Download `MultiPrint.zip` from the Releases page and extract it.
2. Run `MultiPrint.exe` and approve the permission prompt.
3. If the message **Windows protected your PC** appears, choose **More info**, then **Run anyway**.
4. Choose the interface language. You can change it later in **Settings**.

The app copies itself to the `C:\DualPrint` folder and starts the print service in the background. You can keep the original executable anywhere.

## Creating a multi-printer
1. On the **Printers** page, choose **Add printer**.
2. **Printer name**: the name that will appear in the print dialog of every application, for example "Invoice Printing".
3. **Print to**: choose one or more printers. For example, choosing a single printer plus PDF saving archives every document automatically. A green dot means the printer is connected; a red dot means it is offline.
4. **Paper size**: leave it on "Automatic" so each printer uses its own default, or select a specific size.
5. When you select **Microsoft Print to PDF**, the following fields appear:
   - **PDF save folder**: files are saved here directly, with no "Save As" dialog.
   - **File name prefix**: for example `Invoice`, which makes the file name `Invoice_2026-11-02_15-45-00.pdf`. If the field is left empty, the printer name is used.
6. Click **Save**.

## Printing
In any application choose **Print**, select the multi-printer by its name, and click **Print**. The document reaches all the printers linked to it within a second or two.

If you create more than one multi-printer, each one works independently, and you choose the one you want in the print dialog.

## Printer card
| Item | What it does |
|---|---|
| ✏ next to the name / **Edit** | Edit the name, printers, paper size and PDF folder, or **Delete** the printer |
| **Ready** badge | All linked printers are connected; otherwise it shows the number of offline printers |
| **Default** badge | This printer is the Windows default printer |
| **Printer settings** | Opens the Windows settings for the selected printer |
| **Change folder** | Changes the PDF save folder |
| **Paper size** | The change is saved immediately |
| **Save PDF automatically** | Pauses or resumes the PDF copy without removing it |
| **Print test page** | Sends a Windows test page to the multi-printer |
| **Set as default** | Makes the multi-printer the Windows default printer |

## Print history
- The **Printers** page shows the last five jobs.
- The **Print history** page shows the last 200 jobs, with the printer name.
- Job statuses: **Completed** (reached all destinations), **Partial** (reached some of them) and **Failed**. Hover over the status to see the details for each destination.

## Settings
- **Language**.
- **Print service**: choose **Restart** if printing stops.
- **Detailed log**: a text file with details of every job and any errors.
- **Remove all**: deletes every printer the app created and stops the service. Saved PDF files are not deleted.

## File locations
All data is stored in the `C:\DualPrint` folder. It is shared by all versions of the app on the computer and is not affected by updates:

| File | Contents |
|---|---|
| `printers.json` | Multi-printers and their settings |
| `settings.json` | Language |
| `history.jsonl` | Print history |
| `log.txt` | Detailed log |
| `MultiPrint.exe` | The copy of the service that runs in the background |

## Uninstalling
In **Settings**, choose **Remove all**, then delete the `C:\DualPrint` folder and the executable.
