# Contributing

## Development Workflow

1. Enter the devbox shell: `devbox shell`
2. Run validation: `task validate`
3. Format files: `task format`
4. Run full CI check: `task ci-full`

## Requirements

- [devbox](https://www.jetify.com/devbox/) — manages all tooling
- Python 3.12 via devbox (managed with `uv`)
- Ansible 2.20+

## Conventions

- Conventional Commits for all commit messages
- YAML files use 2-space indentation
- All roles require `meta/main.yml` with `min_ansible_version: "2.20.0"`
- Become is controlled at play level, not globally
- No hardcoded values in Kubernetes manifests — use Ansible templates
- Helm chart versions must be pinned in `group_vars/all.yml`

## Project Structure

| Directory | Purpose |
|-----------|---------|
| `roles/` | Ansible roles |
| `k8s/` | Kubernetes manifests (bootstrap + gitops) |
| `group_vars/` | Ansible variables |
| `.github/workflows/` | CI pipeline |

## Before Submitting

- Run `task ci-full` — must pass
- Run `task format` — no formatting changes left
- Verify with `task validate`
