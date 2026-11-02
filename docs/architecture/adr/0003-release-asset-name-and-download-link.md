# ADR 0003: Release asset name and download-link compatibility

- Status: Accepted; T010 canonical-only decision superseded by the Owner-approved T013 compatibility decision.
- Feature: F005 (US-6, AC-6.1–6.5, AC-8.x)

## Original context (T010; superseded release contract)
The site's download button uses `<repo>/releases/latest/download/MultiPrint.zip`. GitHub resolves `releases/latest/download/<asset-name>` against the **current** latest release only ([GitHub docs: Linking to releases](https://docs.github.com/en/repositories/releasing-projects-on-github/linking-to-releases)). The spec requires the asset to be `DualPrint.zip`, and AC-6.3 fixes the assets to exactly `DualPrint.zip` and `SHA256SUMS.txt`. The CEO brief asks that people arriving from the old link can still download.

Facts:
- The repo rename redirects web and git traffic from `dualprinter` to `dualprint`, but **not** the Pages site ([GitHub docs: Renaming a repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/renaming-a-repository)). The old site, the only page that linked to `latest/download/MultiPrint.zip`, therefore goes offline at the rename (AC-8.3).
- 2.2.5 was published less than a day before this decision.

## Original options (T010)
1. **Only `DualPrint.zip`** (+ checksums). Matches the spec and one name. `…/latest/download/MultiPrint.zip` returns 404 from 3.0.0 on.
2. **Also attach `MultiPrint.zip` (same bytes) to 3.0.0.** Keeps the old latest-link alive only while 3.0.0 is the latest release. To last, it must be attached to every future release. It contradicts AC-6.3 and Goal 1, and adds "MultiPrint" to every release page.
3. **Attach the alias for 3.0.x only, then drop it.** Breaks the old link later instead of now, at the cost of the same contradictions.

## Original decision (T010; superseded)
Option 1. `release.yml` publishes `DualPrint.zip` and `SHA256SUMS.txt` (line `<sha256>  DualPrint.zip`), with title `DualPrint <version>` and notes from `docs/release-notes/<tag>.md`. The site link becomes `<repo>/releases/latest/download/DualPrint.zip`, with `<repo>` filled by `pages.yml` from `github.repository`, so it follows the rename automatically. `build.ps1` refuses to produce a zip with any `MultiPrint` entry.

## Original consequences (T010; superseded)
- Links pinned to a version keep working, e.g. `…/releases/download/v2.2.5/MultiPrint.zip`, also through the old `dualprinter` repo URL via GitHub's redirect.
- `…/releases/latest/download/MultiPrint.zip` returns GitHub's 404 after 3.0.0. Expected traffic is near zero (the old site is gone, and the product is one day old).
- **Owner confirmation requested**, because this does not meet the brief's "old link keeps working" literally. If the Owner prefers Option 2, devops adds a copy step plus a `files:` entry and a checksum line (about 3 lines), and the product-manager amends AC-6.3.
- The CI artifact name changes to `DualPrint`. No external consumer depends on it.

## Current decision (T013; Owner approved)
Option 2 supersedes the canonical-only release contract above. For 3.0.0 and every future release, CI publishes exactly `DualPrint.zip`, `MultiPrint.zip` and `SHA256SUMS.txt`. `DualPrint.zip` is canonical; `MultiPrint.zip` is a compatibility alias copied from it with identical bytes. `SHA256SUMS.txt` contains one line for each zip (`<sha256>  DualPrint.zip` and `<sha256>  MultiPrint.zip`), with the same hash on both lines.

`build.ps1` continues to produce only canonical `DualPrint` outputs, and the zip still contains exactly `DualPrint.exe`. The alias is created by `release.yml` after the canonical build; it does not introduce legacy filenames inside either archive. The CI artifact remains named `DualPrint` and carries all three release files. The website continues to link to `releases/latest/download/DualPrint.zip`.

## Current consequences
- `releases/latest/download/MultiPrint.zip` remains usable on each future release while the alias contract is maintained; version-pinned legacy links remain unchanged.
- Every future release must include the alias and both checksum lines. This ongoing compatibility requirement is intentional and Owner approved.
- The T013 amendment to AC-6.3 replaces the original two-asset constraint. No Owner confirmation remains pending for this choice.
