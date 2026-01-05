# Devbox y Taskfile (hechos actuales)

- devbox.json instala herramientas de lint/format (yamllint, yamlfmt, j2lint, shellcheck, shfmt), ansible/ansible-lint, helm, k9s, ripgrep, task.
- Taskfile.yml provee tareas de validacion (yaml/ansible/jinja/bash) y formato, mas helpers para secrets via ansible-vault.
