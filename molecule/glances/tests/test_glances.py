"""Tests for glances role."""


def test_glances_venv_present(host):
    venv_path = host.ansible.get_variables().get("glances_venv_path", "/opt/glances")
    assert host.file(f"{venv_path}/bin/python").exists


def test_glances_service_file_present(host):
    assert host.file("/etc/systemd/system/glances-web.service").exists


def test_glances_service_running(host):
    service = host.service("glances-web")
    assert service.is_enabled
    assert service.is_running
