# KARTA — Digital Identity Wallet

**Your identity. Your documents. Your control.**

KARTA is a secure digital identity wallet designed to help people store, manage, and selectively share identity documents and verifiable identity information.

## Alpha 0.1

The first milestone focuses on the secure foundation:

- Account registration and authentication
- Secure wallet access
- Document metadata and encrypted document storage architecture
- Identity profile
- Audit trail
- Mobile-first experience

Future milestones will add OCR/MRZ processing, selective disclosure, QR verification, KARTA Verify, and a business verification API.

## Repository structure

```text
apps/
  api/          Backend API
  mobile/       Flutter mobile application
packages/
  shared-types/ Shared API/domain types
  security/     Security-related shared components
infrastructure/
  database/     Database migrations and schema
  storage/      Storage configuration
  deployment/   Deployment configuration
docs/
  architecture/ Architecture decisions
  api/          API documentation
  product/      Product specifications
```

## Security

KARTA handles highly sensitive identity information. No real passports, national IDs, or other personal identity documents should be committed to this repository or used in development environments.

See [SECURITY.md](SECURITY.md).
