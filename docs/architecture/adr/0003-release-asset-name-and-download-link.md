# ADR 0003: Release asset name and download-link compatibility

- Status: Accepted (architect, T010). Confirmation requested from the Owner (see Consequences).
- Feature: F005 (US-6, AC-6.1–6.5, AC-8.x)

## Context
The site's download button uses `<repo>/releases/latest/download/MultiPrint.zip`. GitHub resolves `releases/latest/download/<asset-name>` against the **current** latest release only ([GitHub docs: Linking to releases](https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases)). The spec requires the asset to be `DualPrint.zip`, and AC-6.3 fixes the assets to exactly `DualPrint.zip` and `SHA256SUMS.txt`. The CEO brief asks that people arriving from the old link can still download.

Facts:
- The repo rename redirects web and git traffic from `dualprinter` to `dualprint`, but **not** the Pages site ([GitHub docs: Renaming a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository)). The old site, the only page that linked to `latest/download/MultiPrint.zip`, therefore goes offline at the rename (AC-8.3).
- 2.2.5 was published less than a day before this decision.

## Options
1. **Only `DualPrint.zip`** (+ checksums). Matches the spec and one name. `…/latest/download/MultiPrint.zip` returns 404 from 3.0.0 on.
2. **Also attach `MultiPrint.zip` (same bytes) to 3.0.0.** Keeps the old latest-link alive only while 3.0.0 is the latest release. To last, it must be attached to every future release. It contradicts AC-6.3 and Goal 1, and adds "MultiPrint" to every release page.
3. **Attach the alias for 3.0.x only, then drop it.** Breaks the old link later instead of now, at the cost of the same contradictions.

## Decision
Option 1. `release.yml` publishes `DualPrint.zip` and `SHA256SUMS.txt` (line `<sha256>  DualPrint.zip`), with title `DualPrint <version>` and notes from `docs/release-notes/<tag>.md`. The site link becomes `<repo>/releases/latest/download/DualPrint.zip`, with `<repo>` filled by `pages.yml` from `github.repository`, so it follows the rename automatically. `build.ps1` refuses to produce a zip with any `MultiPrint` entry.

## Consequences
- Links pinned to a version keep working, e.g. `…/releases/download/v2.2.5/MultiPrint.zip`, also through the old `dualprinter` repo URL via GitHub's redirect.
- `…/releases/latest/download/MultiPrint.zip` returns GitHub's 404 after 3.0.0. Expected traffic is near zero (the old site is gone, and the product is one day old).
- **Owner confirmation requested**, because this does not meet the brief's "old link keeps working" literally. If the Owner prefers Option 2, devops adds a copy step plus a `files:` entry and a checksum line (about 3 lines), and the product-manager amends AC-6.3.
- The CI artifact name changes to `DualPrint`. No external consumer depends on it.
