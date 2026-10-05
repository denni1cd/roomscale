# Verified main protection

[Active ruleset24544582](https://github.com/denni1cd/roomscale/rules/24544582)
was configured through authenticated GitHub REST and independently read back with
`gh api repos/denni1cd/roomscale/rulesets/24544582` and
`gh api repos/denni1cd/roomscale/rules/branches/main`.
The branch API returns protected=true. Exact readback is in protection-readback.json.

Only refs/heads/main is targeted. Pull requests are required; the exact required check
is **fast**, bound to GitHub Actions app15368, discovered from successful main run
[37374235413](https://github.com/denni1cd/roomscale/actions/runs/37374235413).
This is .github/workflows/quality.yml, with Ruff check/format,Godot import and Fast.
Branches must be up to date. Force pushes and branch deletion are blocked.

Approving review count=0; code-owner,last-push,extra-unattributed-change approvals and
review-thread requirements are false. No signature,linear-history,deployment or
Robustness/Soak requirement is added. Allowed normal merge methods remain unchanged.
No standing bypass exists; the current authenticated admin cannot bypass these rules.
Emergency recovery remains available through the owner's existing admin permission to
edit/disable this specific ruleset in Settings > Rules > Rulesets. Routine work uses PRs.
No account/permission limitation prevented configuration; readback succeeded.

Ruleset REST schema: [GitHub documentation](https://docs.github.com/en/rest/repos/rules#create-a-repository-ruleset).
