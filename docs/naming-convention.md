# Naming convention

The templates compose most resource names from:

```text
<organizational-unit>-<business-area>-<workload>-<environment>-<region-code>-<instance>
```

For example, `fin-tax-intmod-dev-eus-001`.

Parameters:

| Parameter | Purpose | Example |
| --- | --- | --- |
| `ou` | Organizational unit | `fin` |
| `biz` | Business area or domain | `tax` |
| `app` | Workload abbreviation; keep it source-platform neutral | `intmod` |
| `env` | `dev`, `tst`, `uat`, `stg`, or `prd` | `dev` |
| `regionCode` | Organization-approved Azure region abbreviation | `eus` |
| `instance` | Three-digit uniqueness suffix | `001` |

Storage account and Key Vault names are normalized and truncated to satisfy Azure naming constraints. Confirm generated names against organizational policy, global uniqueness, and environment/subscription boundaries before deployment.
