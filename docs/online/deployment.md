# KARTA online beta — ready-to-deploy integration

Status: code/integration under test; NO live endpoint, domain, hosting subscription, public registration or production claim.

## Scope

Optional account and ONE latest manual encrypted backup per account. Offline wallet is unchanged. Client encrypts with the existing `.kartabackup` envelope; the backup password and wallet PIN are never sent to the API. Account email, account password verifier, session IDs, encrypted bytes, size and timestamp are stored on the server. Do not claim the server learns nothing: it sees this metadata and traffic. Password strength matters for offline attacks on stolen ciphertext.

The initial beta stores the bounded encrypted blob in PostgreSQL, atomically with its metadata. Maximum request: 48 MiB; existing client limit: 16 MiB encrypted vault files. Object-storage migration is a later scaling step, not an already deployed service.

Invited users can register, sign in (15-minute revocable session), upload/replace, see metadata, download, delete their backup and delete their account with password confirmation. No refresh tokens are issued. The mobile client retains its access token in memory only. No automatic sync, email verification, password reset or cross-account sharing is enabled.

## Hosting requirements and deployment

1. HMATIAS-controlled hosting account, region, budget and PostgreSQL persistence/backup policy. A domain with HTTPS, e.g. `api.<owned-domain>/api/v1`, must be selected and configured; no domain is provisioned here.
2. Build `apps/api/Dockerfile`. Supply DATABASE_URL, a random JWT_ACCESS_SECRET (at least 32 characters), and a private BETA_INVITE_CODE using the host's secret manager. Never put secrets in git or Flutter compile flags. Rotate invite codes between beta cohorts.
3. Use a fresh database for the first deployment. Start command applies Prisma migrations and then the API. For an EXISTING database, review migration history first: the old `0002_add_document_shares` file was renamed to `20260826122000_add_document_shares` because its old name sorted before the initial tables. If already applied, reconcile its migration record with a database administrator before deployment. Never reset a database to resolve this.
4. Terminate TLS at managed ingress; keep the API/private DB unreachable directly. Set request timeout >=90 seconds and body cap <=48 MiB, allow only required methods. Do not log Authorization, invite headers, request/response bodies or account passwords. Do not trust arbitrary X-Forwarded-For. Built-in limits are per IP, per process; behind ingress this conservatively groups clients unless trusted proxy handling is explicitly configured. Configure edge per-client limits before broad release.
5. Validate `/api/v1/health`, then run the two-account acceptance script/tests against a staging database with fictional content. Test server/database restart and restoration of the managed DB backup.
6. Build Flutter with `--dart-define=KARTA_API_URL=https://<approved-host>/api/v1`. Without this define the online screen clearly states that hosting is not connected. HTTP origins and redirects are rejected; no production credentials are embedded in the app.
7. Supply Android release signing through secure CI secrets before any Play distribution. The existing CI APK remains a debug build; it does not establish stable production signing.

`compose.online.yml` is loopback-only local staging, not an Internet deployment. Supply shell environment values (database password must be URL-safe, e.g. random hex) and run `docker compose -f compose.online.yml up --build`. Never expose PostgreSQL publicly.

## Acceptance / release gates

- Real PostgreSQL CI: ordered fresh migrations; separate accounts; anonymous rejection; byte-preserving upload/download; logout revocation; password-confirmed account deletion; session/backup cascade.
- Flutter: HTTPS-only requests, exact API prefix, ciphertext transfer, digest verification, expired session handling, disabled unconfigured UI, and existing offline regression suite.
- Physical devices: update without uninstalling, biometrics, share sheet, background lock, create/upload/download/restore to a SECOND empty installation, network loss and server unavailability. Retain the original until restoration is confirmed.
- Before public/commercial release: independent security review, hardware-bound vault-key plan, account recovery and email verification, account-enumeration review, distributed abuse limits, monitored capacity/cost/quota policy, tested infrastructure backups, privacy/retention policy including managed backups and access logs, Play Console account/privacy/Data safety/signing/review. Account deletion removes live data; retention in infrastructure backups must be decided and disclosed before hosting real data.
- Website must say beta/in development; no Play badge, commercial pricing, verified official identity claim, or claim of a live cloud service before those gates pass.
