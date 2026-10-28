# Security

Do not post credentials, personal data, client records, or exploit details in public issues.

Use GitHub's private vulnerability reporting for this repository when available. Include reproduction steps with synthetic data and identify the affected app. If private reporting is unavailable, open a public issue requesting a private reporting channel without including sensitive details.

Operators supply their own service credentials, configure tenant access and Firebase rules, and review integrations before production use. The source release is not a security certification or a statement of regulatory compliance.

Run `python3 scripts/check-public-files.py` and `gitleaks dir . --redact` before publishing changes. Keep server secrets out of browser and mobile configuration. Rotate exposed credentials at their providers.
