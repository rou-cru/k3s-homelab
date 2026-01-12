# Integración Molecule para Testing Ansible

## Arquitectura
- **Driver:** Vagrant + libvirt (solo una tecnología)
- **Ejecución:** SSH a master1 (192.168.65.16), ejecutar localmente ahí
- **Coverage:** 80-90% real (vs 20% Docker)
- **Restricción:** Solo 1 VM activa a la vez

## Dependencias (pyproject.toml)
```toml
dependencies = [
  "docsible>=0.7.17",
  "molecule>=24.0.0",
  "molecule-plugins[vagrant]>=23.5.0",
  "python-vagrant>=1.0.0",
  "pytest-testinfra>=10.0.0",
]
```

## Estructura
```
molecule/
└── preflight/              # MVP
    ├── molecule.yml        # Driver vagrant + libvirt
    ├── converge.yml        # Ejecuta el rol
    └── tests/
        └── test_preflight.py  # 6 tests
```

## molecule.yml (preflight)
```yaml
driver:
  name: vagrant
  provider:
    name: libvirt
platforms:
  - name: preflight-ubuntu
    box: generic/ubuntu2404
    memory: 4096
    cpus: 2
provisioner:
  name: ansible
verifier:
  name: testinfra
  directory: tests
```

## Taskfile.yml (agregar)
```yaml
test:preflight:
  desc: "Run Molecule tests for preflight role (Vagrant)"
  preconditions:
    - sh: command -v molecule
    - sh: command -v vagrant
    - sh: systemctl is-active --quiet libvirtd
  cmds:
    - cd molecule/preflight && molecule test

test:converge:preflight:
  cmds:
    - cd molecule/preflight && molecule converge

test:verify:preflight:
  cmds:
    - cd molecule/preflight && molecule verify

test:destroy:
  cmds:
    - molecule destroy --all
```

## .gitignore (agregar)
```
.molecule/
.vagrant/
*.box
molecule/**/.cache/
molecule/**/pytest_cache/
molecule/**/__pycache__/
```

## Setup en master1
```bash
# Vagrant + libvirt se instalan automáticamente por el rol developer_tools
# devtools_install_vagrant: true (default en defaults/main.yml)

# Solo instalar deps Python
cd /home/rc/k3s-homelab
devbox shell
uv sync
```

## Ejecución
```bash
# En master1
ssh rc@192.168.65.16
cd /home/rc/k3s-homelab
devbox shell

# Test completo (~10-12 min primera vez, ~8-10 min subsecuente)
task test:preflight

# Iteración rápida
task test:converge:preflight  # ~3-4 min
task test:verify:preflight    # ~30s
task test:destroy
```

## Roadmap
1. **Preflight** (MVP) - Validaciones read-only, 100% coverage
2. **Glances** - Systemd services, 100% coverage
3. **Tailscale** - Networking + secrets, 80% coverage
4. **Common** - Sysctl + kernel modules, 90% coverage
5. **K3s** - Cluster completo (8GB RAM, 4 CPUs), 95% coverage

## Limitaciones
- **nvidia_gpu:** 50% coverage (instala drivers, no valida GPU física)
- **cilium:** Requiere K3s funcionando primero
- **Tiempo:** Vagrant es lento pero necesario para coverage real

## Recursos
- Box descarga: ~600MB primera vez
- Por VM: 2-3GB disco, 4GB RAM
- **IMPORTANTE:** Destruir VM después de cada test
