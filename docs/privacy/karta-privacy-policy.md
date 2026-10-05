# KARTA Privacy Policy — release source

**Effective date:** 5 October 2026  
**Developer:** HMATIAS – Prestação de Serviços SU, LDA  
**Product:** KARTA Identity Wallet  
**Privacy contact:** geral@comercialhmatiasps.com

This document is the release-source text for the public KARTA privacy policy and the in-app privacy disclosure. The public canonical URL for Google Play is:

`https://comercialhmatiasps.com/karta-privacidade.html`

## 1. Local-first data handling

KARTA is designed to work locally without requiring an online account. Identity-profile data, local credentials, document metadata, images, PDFs, biometric preference, PIN-verification metadata and other wallet state are stored in the application's private device storage. Document-vault files are encrypted before storage.

KARTA is not a government-issued identity document and does not claim to replace a passport, national identity card or other official credential.

## 2. PIN and biometrics

KARTA does not store the wallet PIN in plaintext. PIN verification uses a derived verifier and rate limiting/lockout controls.

Biometric authentication is performed by the device operating system. KARTA does not receive or store fingerprint templates, face templates or other raw biometric characteristics.

## 3. Camera, files, QR and sharing

Camera, gallery and file-selection capabilities are used only when the user initiates capture, import, QR scanning or file selection.

Sharing and export happen only after a user action and use the Android system chooser. Once a user sends an exported copy to another application or recipient, the selected destination's privacy practices apply.

## 4. Encrypted backups

Local backup files are encrypted on the device using the backup password chosen by the user. The backup password is not embedded in the backup file.

## 5. Optional online account and encrypted backup

The current product contains an optional online-backup beta path that is inactive unless a KARTA API URL is configured.

When configured and used, the service may process:
- account email address;
- a secure password hash rather than the plaintext account password;
- short-lived authentication-session records;
- the encrypted backup envelope uploaded by the user;
- backup size, cryptographic digest and update timestamp;
- security/operational connection logs needed to run and protect the service.

The encrypted backup is created on the device. The server validates envelope structure and integrity but does not receive the backup password required to decrypt the content.

## 6. Advertising and analytics

The current KARTA mobile application does not include advertising, advertising identifiers or a behavioural analytics SDK.

The public HMATIAS website is separate from the KARTA mobile app and has its own website cookie/analytics disclosures.

## 7. Retention and deletion

Local data remains on the device until the user deletes the wallet, removes individual content, or uninstalls the application subject to Android behaviour.

When an online KARTA account is available, the app provides controls to delete the online backup and to delete the account. Account deletion removes the user record and associated server-side records through database cascade deletion.

## 8. Security measures

KARTA uses application-private storage, authenticated encryption for vault files, secure system storage for sensitive state, session locking, PIN-attempt controls and HTTPS-only application networking.

No system can guarantee absolute security. Users should keep the device updated and protect their PIN and backup password.

## 9. Contact

HMATIAS – Prestação de Serviços SU, LDA  
Viana, Luanda, Angola  
Email: geral@comercialhmatiasps.com
