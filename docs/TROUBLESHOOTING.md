# Troubleshooting

Always start here: in **Settings**, open the **Detailed log** and review the last lines.

| Problem | Likely cause | Solution |
|---|---|---|
| The message "Windows protected your PC" | The file is not digitally signed | Choose **More info**, then **Run anyway** |
| The app closes right after starting, or an error message appears | PowerShell library or permissions | Run it with **Run as administrator**, and send the contents of `C:\DualPrint\error.txt` |
| Nothing was printed | The print service is stopped | The indicator at the bottom of the side menu should be green and read **Service running**. If it is red, click it, or choose **Settings → Restart** |
| The PDF was saved but the paper copy was not printed | SumatraPDF is not available or the printer is offline | The app downloads the tool automatically when internet is available. If that fails, install SumatraPDF version 3.6 or later from the [official website](https://www.sumatrapdfreader.org) in the default location under Program Files, then reopen the app |
| The status shows **Partial** in the history | One of the destinations could not be reached | Hover over the status to see the destination and the reason for the failure |
| A red card appears instead of the printer card | A problem in the printer's settings | Choose **Edit** and save again; if the problem persists, send the text shown on the card |
| "Driver 'Microsoft Print To PDF' not found" | The feature is not enabled in Windows | Enable it from **Turn Windows features on or off → Microsoft Print to PDF** |
| The document name shows as "Document" | The source application does not send the document name | Normal behavior; it does not affect printing |
| The number of copies set in the print dialog was not applied | Known limitation | Each printer prints with its own default settings |
| Duplicate printing | A legacy watcher or duplicate destination may be active | Follow the upgrade checks below before sending another job |

## Upgrade and duplicate-print checks

1. Pause new print jobs and close old MultiPrint windows. Open `C:\DualPrint\DualPrint.exe` as administrator once; this retries legacy cleanup and service setup.
2. In Task Scheduler, check **DualPrint Service** runs `C:\DualPrint\DualPrint.exe --watch`. Its normal triggers are user logon and a one-minute repeat. `MultiPrint Watcher` and the original `DualPrint Watcher` should be absent. Do not confuse **DualPrint Service** with that original task.
3. Check **Settings > Print service** and the detailed log. A task or `DualPrint.exe` process can exist while startup is waiting for a legacy lock; **Service running** requires the separate Ready signal after both legacy locks are held. If it stays stopped, use **Restart** and inspect `log.txt` for task, permission or legacy-lock errors.
4. Wait at least three minutes, check that an old task has not returned, then send one test page. Check each configured destination, paper copy, PDF and history entry before resuming work. Check that a destination is not configured twice. Re-pin the new executable if an old shortcut keeps opening MultiPrint.

A retained `MultiPrint.exe` means readiness or retirement may not have completed; it is not proof of an active legacy service. Do not launch the old executable during normal use. For access-repair failures, also inspect `%TEMP%\DualPrint-acl.txt`.

## Manual rollback to MultiPrint 2.2.5

Use this only if the upgrade fails and you need the previous version. Do not choose **Remove all**: that removes your virtual printers.

1. Stop submitting jobs, let active jobs finish if possible, close both app windows, and back up `C:\DualPrint` and your PDF output folders to a separate location. Preserve all existing rollback copies.
2. In Task Scheduler, disable **DualPrint Service** first so its one-minute trigger cannot restart it, then choose **End**. In Task Manager, confirm the installed `C:\DualPrint\DualPrint.exe --watch` process has ended before starting any old watcher. If it remains, end only that verified watcher process. Never run both services together.
3. Copy the preserved `C:\DualPrint\MultiPrint.exe.old` (or the appropriate `.old.<guid>` copy) to a separate folder and name that copy `MultiPrint.exe`. Alternatively, extract your trusted v2.2.5 release archive. Keep the preserved original untouched.
4. Run that `MultiPrint.exe` as administrator. It reinstalls its service using the existing data. Confirm **MultiPrint Watcher** is running and **DualPrint Service** remains disabled. Check printers, language, history and PDF destinations, then send one test page.
5. Keep the new executable and backups for diagnosis. To retry 3.0.0 later, close MultiPrint and run `DualPrint.exe` as administrator. Choose **Settings > Print service > Restart** to re-register the service if **DualPrint Service** remains disabled, including when rollback stopped before recreating the legacy task. Opening the app alone may only try to start the disabled task. Confirm the task is enabled, the app reports **Service running**, and a single test page reaches each destination once before resuming work.

These are recovery instructions, not evidence that runtime rollback has passed QA. See [validation limits](qa/T012-upgrade-validation.md#remaining-checks-and-practical-limits).

## Full reset
1. In **Settings**, choose **Remove all**.
2. Delete the `C:\DualPrint` folder.
3. Run the latest version and create the printers again.
