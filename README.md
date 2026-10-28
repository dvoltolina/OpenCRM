# OpenCRM

OpenCRM is CRM and scheduling software available at no charge for personal use and internal business use, including use by for-profit companies. You can study the code, modify it for your own operations, and share free forks under the project license.

The suite brings together a CRM, an appointment scheduling app, an administration dashboard, and a static marketing website. It uses React, TypeScript, Flutter, Firebase, and optional Python AI services.

**Free for your own use; commercial redistribution requires the project owner's prior written consent.** OpenCRM is source available under the [OpenCRM Personal and Internal Business Use License 1.0](LICENSE).

| Folder | Purpose |
| --- | --- |
| `The Schedular CRM/` | React CRM: leads, contacts, deals, reports, and workflows |
| `The Scheduler/` | Flutter scheduling app, shared Firebase backend, and Python services |
| `The Scheduler Admin Page/` | React administration dashboard |
| `Scheduler Website Home page/` | Static HTML/CSS website |

The original folder names are retained for sibling imports and cross-app scripts. Shared Cloud Functions, Firestore rules, and indexes are owned by `The Scheduler/`. The other apps consume that backend; their backend snapshots are retained for reference and should not be deployed over the shared backend.

## Getting started

Use Node.js 20.19+ for the React apps and Node.js 20 for the shared Functions backend. The Flutter project requires Dart 3.10 or later and a compatible Flutter SDK. Optional Python services have their own `requirements.txt` files.

```sh
cd "The Schedular CRM"
npm ci
cp .env.example .env.local
# Supply your own Firebase configuration before starting.
npm run dev
```

The Admin app follows the same pattern in `The Scheduler Admin Page/`. Follow [CONFIGURATION.md](CONFIGURATION.md) for Flutter, native Firebase files, backend services, and the public booking page.

To view the static website locally:

```sh
cd "Scheduler Website Home page"
python3 -m http.server 8088
```

Website links use example domains. Replace them with your own destinations.

## Project status

This is an abandoned, experimental source release with no active maintenance planned. Firebase projects, hosted demos, OAuth registrations, payment providers, messaging providers, signing identities, and AI endpoints must be configured by each operator. Some integrations and backend snapshots contain scaffolding. Publishing this source does not establish production readiness, clinical acceptance, or regulatory compliance.

Private Git history, environment files, deployment identities, internal Markdown, prompt packs, business plans, audit logs, and compiled bundles are excluded. Only setup, security, verification, and the three shared schema references are retained for this release.

## Checks

```sh
python3 scripts/check-public-files.py
gitleaks dir . --redact
```

Each app retains its existing test commands. See [VERIFICATION.md](VERIFICATION.md) for the release checks and their limits. Report sensitive findings through the private process described in [SECURITY.md](SECURITY.md).

## License

The current project license is the [OpenCRM Personal and Internal Business Use License 1.0](LICENSE), copyright Scheduler contributors.

| Use | Permission under the current license |
| --- | --- |
| Personal use, study, and modifications for yourself | Allowed at no charge |
| Internal use by any company, including a for-profit company | Allowed at no charge |
| Managing your own customers, sales, staff, and appointments | Allowed, even when your business earns revenue |
| Letting your own customers book or use a portal for your business | Allowed |
| Hiring someone to install, customize, maintain, or support your own instance | Allowed |
| Sharing free copies or modified forks | Allowed with the full license and required notices |
| Selling, repackaging, white-labeling, or bundling the software into a monetized product | Requires the project owner's prior written consent |
| Offering the software as a commercial hosted CRM or scheduling service to others | Requires the project owner's prior written consent |

The license applies to modified and rebranded versions as well as the original. Calling a bundled copy “free” or earning revenue through advertising does not bypass the commercial redistribution restriction. The full [LICENSE](LICENSE) governs these permissions. Request commercial permission from the project owner through the [original repository](https://github.com/dvoltolina/OpenCRM).

Because it restricts commercial redistribution, this release is **source available** and does not meet the [Open Source Definition](https://opensource.org/osd). “Free” means no license fee for the permitted uses above; it does not mean unrestricted resale rights.

**Earlier release:** the initial public revision, [`e0b2399`](https://github.com/dvoltolina/OpenCRM/commit/e0b2399), was distributed under MIT. This license change cannot revoke the permissions already granted for that revision, including commercial rights. Third-party dependencies retain their own licenses and notices.
