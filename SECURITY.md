# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it
**privately** using one of these methods:

1. **GitHub Private Vulnerability Reporting** — go to the
   [Security tab](https://github.com/hkaanturgut/openclaw-azure-foundry/security/advisories/new)
   and create a new advisory.
2. **Email** — send details to **kaanturgutbusiness@gmail.com**.

Please **do not** open a public issue for security vulnerabilities.

## What to Include

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

## Response Timeline

- **Acknowledgement**: within 48 hours
- **Initial assessment**: within 1 week
- **Fix or mitigation**: as soon as practical, coordinated with reporter

## Scope

This policy covers:

- The `openclaw-azure-cli` npm package
- GitHub Actions workflows in this repository
- Bicep / infrastructure templates
- Cloud-init provisioning scripts

## Security Considerations

This project deploys Azure infrastructure and handles sensitive credentials
(Telegram bot tokens, SSH keys, Azure service principals). The following
practices are in place:

- Secrets are stored in Azure Key Vault and fetched via managed identity
- No credentials are hardcoded in source or templates
- GitHub Actions workflows use OIDC federation (no long-lived secrets)
- npm packages are published with [provenance attestation](https://docs.npmjs.com/generating-provenance-statements)
- PR workflows from forks cannot access repository secrets
