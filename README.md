# KARTA — Digital Identity Wallet

**Your identity. Your documents. Your control.**

KARTA is a privacy-focused digital document and identity wallet designed to help users store, organize, protect, back up and selectively share personal documents and identity-related information.

> KARTA is not a government-issued identity document and does not claim to replace an official passport, national ID or other state-issued credential.

## Release line

Current stabilization target: **KARTA 0.9 RC1**.

The release-candidate line consolidates the tested Alpha 0.9 feature set, including:

- local-first wallet onboarding;
- hardened PIN protection and biometric unlock;
- encrypted local document vault;
- document import/capture and profile management;
- PDF viewing and controlled export;
- selective QR generation and scanning;
- system sharing for supported document/QR flows;
- session locking and screenshot protection;
- password-encrypted local backup and fresh-install restore;
- optional online account/encrypted-backup beta components;
- update and migration safety checks.

## Repository structure

```text
apps/
  api/          Backend API
  mobile/       Flutter mobile application
infrastructure/ Supporting infrastructure
docs/           Architecture, release and product documentation
scripts/        Build/update validation helpers
```

## Security

KARTA handles highly sensitive identity information. No real passports, national IDs, private keys, production credentials, secrets or personal identity documents should be committed to this repository or used in development environments.

See [SECURITY.md](SECURITY.md).

## Ownership and licensing

KARTA is proprietary software. Public repository access, testing access or distribution of development builds does not grant permission to copy, modify, redistribute or commercially exploit proprietary KARTA code or assets.

See [LICENSE](LICENSE) and [OWNERSHIP.md](OWNERSHIP.md).

Third-party libraries, fonts and frameworks remain subject to their respective licences.
