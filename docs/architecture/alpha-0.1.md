# KARTA Alpha 0.1 Architecture

## Request flow

```text
Mobile
  ↓ TLS
API
  ↓ authorization
Application services
  ↓ parameterized queries / ORM layer
PostgreSQL

Documents follow a separate encrypted object-storage path.
```

## Core rules

1. Authentication is separate from authorization.
2. Access tokens are short-lived; refresh tokens are rotated and stored securely.
3. Passwords and PINs are never stored in plaintext.
4. Document binaries are not stored in PostgreSQL.
5. Sensitive identity fields are encrypted where required.
6. Audit events must not contain sensitive document contents or secrets.
7. Every document operation is authorized against the owning user.
8. Production keys belong in managed KMS/secrets infrastructure.

## Alpha scope

- Authentication boundary
- User and identity profile boundary
- Document metadata boundary
- Audit boundary
- API health/readiness boundary

OCR, MRZ, QR verification and business API are later milestones.
