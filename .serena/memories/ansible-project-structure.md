# Estructura del proyecto Ansible (hechos)

- Raiz contiene: ansible.cfg, inventory.ini, site.yaml, requirements.yml, Taskfile.yml, devbox.json/devbox.lock, secrets.example.yaml, secrets.yaml (local), directorios roles/ y k8s/.
- roles/ incluye: preflight, common, developer_tools, tailscale, k3s_server, cilium, nvidia_gpu.
- k8s/ contiene manifiestos de workloads bajo namespaces/miners y miners/{unmineable,unmineable-gpu,honeygain}.
- ansible.cfg usa inventory.ini, roles_path=./roles, pipelining=true, fact caching jsonfile en /tmp/ansible_facts, vault_password_file=.ansible_vault_pass.
- inventory.ini define grupo k3s_server con host master1 (ansible_host=192.168.65.16) y vars globales ansible_user=rc, ansible_become=true, ansible_python_interpreter=/usr/bin/python3.
