# Repository Guidelines

## Project Structure & Module Organization
This repository is an Ansible-driven K3s homelab.
- `site.yaml`, `site-vps.yaml`: top-level playbooks.
- `roles/<role_name>/`: role defaults, tasks, templates, handlers, and role docs.
- `group_vars/`: inventory group variables (`all.yml`, `k3s_server.yml`, etc.).
- `k8s/bootstrap/` and `k8s/gitops/`: cluster bootstrap and GitOps manifests.
- `molecule/<scenario>/`: Molecule scenarios with Testinfra tests.
- `images/`: container image definitions used by miner workloads.
- `.task/`: generated artifacts for local validation (do not commit).

## Build, Test, and Development Commands
Use the dev environment first:
- `devbox shell`: installs toolchain and syncs `.venv`.

Primary commands (via Task):
- `task validate`: runs YAML lint, Checkov, Ansible syntax check, Jinja2 lint, and Bash checks.
- `task ci-quick`: fast checks (`ansible-playbook --syntax-check` + Bash validation).
- `task ci-full`: full local CI (`validate` + formatting diff checks).
- `task format`: applies YAML and rendered shell formatting.
- `task clean`: removes `.task/rendered` and checksum cache.

Scenario testing:
- `molecule test -s preflight`
- `molecule test -s common`

## Coding Style & Naming Conventions
- YAML: 2-space indentation, max line length 120 (warning), no document start (`---`) required.
- Templates: keep Jinja2 logic minimal; prefer role defaults/vars for configurability.
- Bash: target `bash`, validate with `shellcheck`, format with `shfmt -i 4`.
- Ansible role naming: snake_case directories under `roles/` (for example `k3s_server`, `external_secrets`).
- Variable names: descriptive snake_case; keep environment-specific values in `group_vars/`.

## Testing Guidelines
- Test framework: Molecule + Testinfra (`molecule/*/tests/test_*.py`).
- Name tests `test_<behavior>.py` and functions `test_<expectation>()`.
- Add/adjust Molecule coverage when role behavior changes, especially package installs, services, and host tuning.
- Run `task ci-full` before opening a PR.

## Commit & Pull Request Guidelines
Recent history shows Conventional Commit usage is preferred (`feat(scope): ...`, `fix: ...`, `docs: ...`, `chore: ...`).
- Keep commits focused by role or subsystem.
- Use imperative, specific subjects (example: `feat(cilium): enable kube-proxy replacement`).
- PRs should include: purpose, impacted roles/paths, validation evidence (command output summary), and linked issue(s).
- For manifest or gateway changes, include a brief rollout/rollback note.

## Security & Configuration Tips
- Never commit live secrets (`secrets.yaml`, key material).
- Use `task secrets:init` and `task secrets:set -- KEY VALUE` for encrypted secret entries.
- Keep `secrets.example.yaml` updated when introducing new required secret keys.
