# FinOps Cost Optimize

This repository contains practical Azure FinOps assets to help improve cloud cost visibility, governance, pricing efficiency, and usage efficiency.

## Repository layout

- `Cost Transparency/`
  - Azure Policy definitions to enforce, append, and audit cost-related tags.
- `Financial Controls/Budget/`
  - ARM templates for deploying Azure Budgets at management group, subscription, and resource group scopes.
- `Rate Optimize/Policy/`
  - Azure Policy definitions to enforce Azure Hybrid Benefit for Windows and SQL virtual machines.
- `Usage Optimize/PowerShell-Scripts/`
  - PowerShell scripts to identify and remove idle or unused resources (for example disks, public IPs, load balancers, app gateways, web apps) and to stop AKS clusters.

## How to use

1. Choose the folder that matches your FinOps goal (transparency, controls, rate, or usage optimization).
2. Review and customize the JSON policy/template parameters or PowerShell script variables for your environment.
3. Deploy policies/templates through Azure Policy or ARM/Bicep deployment workflows.
4. Run PowerShell scripts in a controlled environment with appropriate Azure permissions and test first in non-production.

## Notes

- Most assets are intended as starting points and should be adapted to your organization.
- Review script prerequisites (for example Az module versions and tenant/subscription values) before execution.
