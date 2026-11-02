# Publishing DualPrint

This is the maintainer procedure. DualPrint 3.0.0 is prepared here; these instructions do not assert that it has been published or that Windows runtime QA has passed. Obtain approval for the specific remote actions before pushing tags, publishing or deploying.

## Prepare a release

1. Finish review, automated checks and the real Windows checks in [Building](BUILDING.md). Confirm the intended code, documentation and generated website are integrated into the release commit.
2. Update `CHANGELOG.md`, `docs/release-notes/v3.0.0.md` and the website version in `tools/site_content.py` for this release. Rebuild website content with `python tools/build_site.py` when site content changes; commit the generated output with its source.
3. Run the build, tests and packaging verification from [Building](BUILDING.md). Check the version and archive contents before any tag push.
4. After approval, tag the reviewed release commit and push that tag to the configured repository remote:

```powershell
git tag v3.0.0 <reviewed-release-commit>
git push origin v3.0.0
```

Replace `<reviewed-release-commit>` with the approved commit hash. These commands are a publishing procedure, not a request to execute them now. Do not reuse an existing release tag.

## What the release workflow publishes

[Build & Release](../.github/workflows/release.yml) responds to a pushed `v*` tag, builds on Windows, then publishes a release titled **DualPrint 3.0.0** for `v3.0.0`. It loads `docs/release-notes/<exact-tag>.md` if present and also enables generated GitHub release notes. A missing note file does not block the job. A manually published Release does not trigger this build workflow.

Every release, including releases after 3.0.0, must contain exactly:

| Asset | Contract |
|---|---|
| `DualPrint.zip` | Canonical archive containing exactly `DualPrint.exe` |
| `MultiPrint.zip` | Compatibility alias copied from the canonical zip, byte for byte; also contains only `DualPrint.exe` |
| `SHA256SUMS.txt` | Two SHA-256 lines with the same hash, one for each zip filename |

The workflow creates the alias after the canonical local build. The Actions artifact is named **DualPrint** and contains these same three files. Verify the downloaded zips against their respective lines:

```powershell
Get-FileHash .\DualPrint.zip -Algorithm SHA256
Get-FileHash .\MultiPrint.zip -Algorithm SHA256
Get-Content .\SHA256SUMS.txt
```

The website advertises only `releases/latest/download/DualPrint.zip`. The older `releases/latest/download/MultiPrint.zip` link remains supported by the alias on every release. Version-pinned links such as `releases/download/v2.2.5/MultiPrint.zip` keep their historical contents.

## Repository and website

The intended repository name is `dualprint`; a repository rename is an Owner account action. Do not assume the rename has happened from this document. Confirm the configured remote and repository About URL after the rename. GitHub Pages should use **Settings > Pages > Source: GitHub Actions**.

[Website](../.github/workflows/pages.yml) deploys on qualifying `main` pushes affecting `website/**` or its workflow, a published Release event, or manual dispatch. It substitutes the actual repository and Pages URLs for the generated placeholders. A change only to `tools/site_content.py` does not deploy: regenerate and commit `website/` too. Confirm the deployed site and both latest-download links after publication.

Search Console, Bing and other account configuration is maintained separately by the Owner. Check canonical URLs, sitemap and redirects after the repository rename; do not treat search indexing as a release success check.

## Recovery

If the publishing job fails, inspect the Actions logs and existing assets before retrying the failed job. Do not move a published tag or replace an existing release without a separately approved recovery decision. For installed-user recovery, use [manual rollback](TROUBLESHOOTING.md#manual-rollback-to-multiprint-225); keep the preserved old exe and data backups.
