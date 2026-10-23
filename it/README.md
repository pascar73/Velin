# Tenant admin pack — Entra + Teams (run once per customer)

Linux first-boot cannot create a Teams bot in someone else’s tenant. **IT runs this once** (Cloud Shell or a Windows jump box). Output is three strings we drop into cloud-init / first-run. No client secrets in the ISO.

Need: Global Admin or Application Administrator + Teams Administrator.

App ID is ours (multi-tenant). Replace `AEL_APP_ID` when we register it.

After this script:

- Service principal exists in the tenant
- Admin consent recorded for *send channel message + read mentions only*
- One team + one channel allowlisted
- Print `ael.entra.tenant`, `ael.teams.team`, `ael.teams.channel` for the AEL wizard / cloud-init
