# Source release verification

Checked on 2026-10-28. This release starts a new Git history with a contributor identity. Original repository histories, remotes, environment files, and deployment credentials are not included.

## Privacy and secret checks

- Gitleaks 8.30.1: no detected leaks in the public source. The downloaded scanner was checked against its official release checksum.
- Public-file guard: no recognized credentials, private configuration artifacts, personal filesystem paths, signing teams, or analytics registrations.
- A separate private comparison found no remaining matches for known original credentials and Firebase registrations. That comparison data is kept outside this repository.
- Original branding and hosted destinations were replaced with OpenCRM and example domains. Firebase initialization requires operator-supplied values.
- PNG text, EXIF, and timestamp metadata was removed while preserving image data. Retained contact fixtures use synthetic example data.
- Two SharedPreferences setting names carry narrowly scoped Gitleaks annotations; these are storage identifiers, not credentials. Token-encryption tests generate synthetic token fixtures at runtime.
- Internal Markdown, business plans, prompt packs, historical audits, logs, compiled backend files, and ownership-verification files were omitted. Three shared schema documents remain because integration scripts reference them.

## Build and test results

| Check | Result |
| --- | --- |
| CRM TypeScript and Vite build | Passed |
| Admin Vite build | Passed; existing bundle-size warning |
| Shared Functions TypeScript build | Passed |
| Shared Functions test command | 20 passed |
| CRM demo, contract, and token-encryption tests | 49 passed |
| Admin demo and callable-contract tests | 6 passed |
| Flutter Firebase/integration config analysis | Passed |
| Flutter external portal configuration tests | 2 passed |
| Inline JavaScript syntax in website and booking pages | 10 blocks passed |
| Cross-app smoke shell syntax | Passed |

The Flutter contract smoke suite does not compile with the installed Flutter 3.47.2 SDK: unchanged theme code references `CupertinoPageTransitionsBuilder`, which that SDK does not provide. An isolated check importing the original theme reproduces the same error. Full Flutter build and smoke acceptance remain open; this release does not claim them.

No configured Firebase project, provider integration, hosted deployment, native signing, or production end-to-end acceptance is supplied by this source release.

## Repeat the publication checks

```sh
python3 scripts/check-public-files.py
gitleaks dir . --redact --no-banner
gitleaks git . --redact --no-banner
```

The GitHub workflow runs these source and history checks on pushes and pull requests. GitHub secret scanning, push protection, and private vulnerability reporting are enabled for the public repository.

## License update — 2026-10-28

The project-level license files were changed from MIT to PolyForm Noncommercial License 1.0.0 at the owner's request. The README and repository description identify the project as free source-available CRM software for noncommercial use, with no active maintenance planned. This change does not withdraw permissions already granted for the initial MIT release. Third-party dependency licenses remain unchanged. No application behavior changed in this update.
