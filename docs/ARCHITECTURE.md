# Technical Architecture

## The idea
Windows does not let a single printer send to two printers. So MultiPrint creates a virtual printer that **prints to a PDF file**, and a small service watches that file and distributes it.

```
 Any app ──print──▶ "Invoice Printing" (virtual printer)
                          │  Driver: Microsoft Print To PDF
                          │  Port:   C:\DualPrint\queues\q_xxx\incoming.pdf
                          ▼
                 MultiPrint service (MultiPrint.exe --watch)
                          │  detects incoming.pdf and waits until it is fully written
                          │  moves it to jobs\job_….pdf
                          ├──▶ Printer 1  (SumatraPDF -print-to)
                          ├──▶ Printer 2  (SumatraPDF -print-to)
                          └──▶ PDF folder (copies the file as: Prefix_Date_Time.pdf)
                          │
                          └──▶ history.jsonl  (document name and result for each destination)
```

## Components

### `src/Launcher.cs`: the executable
- A small C# program that relies on .NET Framework 4, which is available in Windows 10 and 11.
- Embeds `MultiPrint.ps1` as a resource.
- Requests administrator rights, except in `--watch` mode.
- Runs the app **in the same process** through a PowerShell Runspace on an STA thread, so it appears in the taskbar and Task Manager with its own name and icon, without a PowerShell window.
- Accesses `System.Management.Automation` through Reflection, so it needs no build-time references.

### `src/MultiPrint.ps1`: the app
| Part | Responsibility |
|---|---|
| General utilities | `Get-Config`, `Save-Config`, `Get-Targets` and `Write-Log` |
| Watcher (`-Watch`) | The `Start-Watcher` function: a loop every 0.7 seconds, a lock (Mutex) that prevents two instances from running, capturing the document name through `Get-PrintJob`, sending to each destination, writing to the history, and cleaning up files older than seven days |
| Printer functions | `New-MultiPrinter` (port and printer), `Remove-MultiPrinter`, `Register-Watcher` (scheduled task), `Set-DefaultMultiPrinter` and `Find-Sumatra` |
| UI (WPF) | A XAML file for the main window, and small XAML fragments built dynamically for the cards and history rows |
| Languages | `__STRINGS_JSON__` is replaced at build time with the contents of `strings.json`, and the `T 'key'` function returns the matching text |

### Print service (the `MultiPrint Watcher` scheduled task)
- Runs `C:\DualPrint\MultiPrint.exe --watch` with normal user rights.
- Triggers: at logon, and every five minutes to restore the service if it has stopped.
- Settings: no time limit, keeps running on battery power, and retries after one minute on failure.
- The `MultipleInstances IgnoreNew` option together with the `Local\MultiPrintWatcher` lock ensures only one instance runs.

## Structure of `printers.json`
```json
[
  {
    "Name": "Invoice Printing",
    "Folder": "C:\\DualPrint\\queues\\q_638...",
    "Port": "C:\\DualPrint\\queues\\q_638...\\incoming.pdf",
    "Targets": ["EPSON L4150 Series", "Microsoft Print to PDF"],
    "PdfFolder": "D:\\Invoices",
    "PdfPrefix": "Invoice",
    "PaperSize": "A4",
    "PdfEnabled": true
  }
]
```
Newer fields are optional; older versions ignore them and keep them unchanged.

## Structure of `history.jsonl` (one line per job)
```json
{"Time":"2026-11-02T15:42:10+03:00","Printer":"Invoice Printing","Doc":"Sales invoice.pdf",
 "Results":[{"Target":"EPSON L4150 Series","Ok":true,"Msg":"exit 0"},
            {"Target":"Microsoft Print to PDF","Ok":true,"Msg":"D:\\Invoices\\Invoice_….pdf"}]}
```

The samples above use English values; printer names, document names and file-name prefixes can also be non-English text (for example Arabic).

## Adding a new language
1. Copy the `"en"` block in `src/strings.json` under the language code (for example `"tr"`) and translate the values.
2. Add the language in `MultiPrint.ps1` in `Show-LanguagePicker`, `$CultureMap` and `$LangNames`.
3. Rebuild the app.

## Known limitations
- Print dialog settings (number of copies, tray, and so on) are not passed on to the other printers; each printer prints with its own default settings, except for the paper size if one is set.
- The document name comes from Windows. Some applications do not send it, in which case "Document" is shown.
- The file is not digitally signed, so a SmartScreen message appears on first run (see [PUBLISHING.md](PUBLISHING.md)).
