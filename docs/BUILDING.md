# Building from Source

## On your computer (Windows)
The build does not need Visual Studio or any extra tools; it uses the `csc.exe` compiler that ships with the .NET Framework in Windows.

```powershell
git clone https://github.com/<account-name>/multiprint.git
cd multiprint
powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 2.2.5
```

Output:
- `build\MultiPrint.exe`: the app.
- `build\MultiPrint.zip`: the package ready for distribution.
- `build\MultiPrint.ps1`: the app after the language texts are merged in (for review).

## What `build.ps1` does
1. Reads `src\MultiPrint.ps1` and puts the contents of `src\strings.json` in place of `__STRINGS_JSON__`.
2. Adds the version number to `Launcher.cs`.
3. Compiles the file with `csc.exe`, embedding the app and the icon.
4. Compresses the executable into a zip package.

## Building on GitHub (automatically)
The `.github/workflows/release.yml` file runs the same steps on a GitHub-hosted Windows machine:
- On any update to the `main` branch: the app is built and made available under the **Actions** tab → latest run → **Artifacts**.
- When a tag such as `v2.1.2` is created: the app is built and a **Release** containing `MultiPrint.zip` is created.

## Before accepting any change
- [ ] `strings.json` has the same keys in all five languages.
- [ ] Tested: adding a printer, editing, printing to the multi-printer, saving the PDF to the folder, and the job appearing in the history.
- [ ] `CHANGELOG.md` has been updated.
