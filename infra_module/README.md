# Modular OCI OKE Infrastructure (infra_module)

This folder contains a fully modularized Terraform setup for provisioning an Oracle Cloud (OCI) OKE cluster, its VCN/network, and a node pool. It does not modify the original `infra/` directory and can be used by multiple developers independently.

## Layout

- `stack/` – a reusable composition module that wires together network, cluster, nodepool
- `modules/` – low-level reusable modules
  - `network/` – VCN, subnets, gateways, route tables, security lists
  - `cluster/` – OKE cluster
  - `nodepool/` – OKE node pool
- `envs/` – per-developer ROOTS (each env is a standalone Terraform root)
  - `envs/<name>/main.tf` – configures provider and calls `../../stack`
  - `envs/<name>/variables.tf` – inputs declared at the env level
  - `envs/<name>/dev.tfvars` – env-specific values

Note: Running Terraform from `envs/<name>/` makes `.terraform.lock.hcl` live inside that env folder (per-developer lock file), as you requested.

## Quick start

1. Create your own env folder and tfvars:

```bash
cp -R envs/sample envs/$USER
cp envs/sample/dev.tfvars envs/$USER/dev.tfvars
sed -i '' "s|ocid1.compartment.oc1..example|<your_compartment_ocid>|" envs/$USER/dev.tfvars
```

2. Initialize and plan/apply FROM YOUR ENV FOLDER (lockfile will be written here):

```bash
terraform -chdir=envs/$USER init
terraform -chdir=envs/$USER plan -var-file=dev.tfvars
terraform -chdir=envs/$USER apply -var-file=dev.tfvars
```

Optional: use Terraform workspaces per developer instead of separate tfvars files.

## Inputs overview

Key inputs (see `variables.tf` for full list and defaults):

- `compartment_ocid` (required)
- `ssh_public_key` (required)
- `name_prefix` (default: `oke`)
- `cluster_name` (default: `free-tier-oke`)
- `kubernetes_version` (default: `v1.34.1`)
- `node_pool_size`, `node_shape`, `node_ocpus`, `node_memory_gbs`
- CIDRs: `vcn_cidr`, `api_subnet_cidr`, `node_subnet_cidr`, `lb_subnet_cidr`

## Outputs

- `cluster_id`
- `kubeconfig_command` – convenient command to fetch kubeconfig

## Notes

- This structure mirrors the resources in `infra/` but decouples them into modules so multiple developers can provision isolated clusters by changing only tfvars (or using workspaces).
- No remote backend is configured; add one if you want shared state.
- If you previously ran Terraform from `infra_module/` root and created `.terraform.lock.hcl` there, switch to running from `envs/<name>/` and optionally delete the root lockfile.
