# KARTA Security Policy

KARTA handles highly sensitive identity information. Security is a product requirement, not an afterthought.

## Development rules

- Never commit real identity documents.
- Never commit passwords, API keys, private keys, tokens, certificates, or cloud credentials.
- Use synthetic test data only.
- Secrets must be supplied through secure environment/secret-management systems.
- Sensitive fields and document objects must be encrypted in production.
- Authentication, authorization, audit logging, rate limiting, and secure session handling are mandatory controls.

## Reporting vulnerabilities

Do not disclose security vulnerabilities publicly before coordinated remediation. Report suspected vulnerabilities privately to the project maintainers.

## Security baseline

The implementation will follow established secure-development practices and relevant OWASP application/mobile security guidance. Production deployment will include encryption in transit and at rest, managed key storage, least-privilege access, monitoring, backups, and audited administrative access.
