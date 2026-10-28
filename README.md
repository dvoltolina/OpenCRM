# OpenCRM

OpenCRM brings together a CRM, an appointment scheduling app, an administration dashboard, and a static marketing website. The suite uses React, TypeScript, Flutter, Firebase, and optional Python AI services.

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

This is a source release. Firebase projects, hosted demos, OAuth registrations, payment providers, messaging providers, signing identities, and AI endpoints must be configured by each operator. Some integrations and backend snapshots contain scaffolding. Publishing this source does not establish production readiness, clinical acceptance, or regulatory compliance.

Private Git history, environment files, deployment identities, internal Markdown, prompt packs, business plans, audit logs, and compiled bundles are excluded. Only setup, security, verification, and the three shared schema references are retained for this release.

## Checks

```sh
python3 scripts/check-public-files.py
gitleaks dir . --redact
```

Each app retains its existing test commands. See [VERIFICATION.md](VERIFICATION.md) for the release checks and their limits. Report sensitive findings through the private process described in [SECURITY.md](SECURITY.md).

## License

MIT, copyright Scheduler contributors. See [LICENSE](LICENSE). Dependencies retain their respective licenses.
