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
| Duplicate printing | A very old version (DualPrint) is running | Run the latest version once, and it will stop the old service |

## Full reset
1. In **Settings**, choose **Remove all**.
2. Delete the `C:\DualPrint` folder.
3. Run the latest version and create the printers again.
