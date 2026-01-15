"""Tests for glances role."""


def test_glances_venv_present(host):
    """
    Verify the Glances virtual environment includes a Python executable.
    
    Checks that the Python binary exists at "<glances_venv_path>/bin/python", where the path is taken from the Ansible variable `glances_venv_path` (defaults to "/opt/glances").
    """
    venv_path = host.ansible.get_variables().get("glances_venv_path", "/opt/glances")
    assert host.file(f"{venv_path}/bin/python").exists


def test_glances_service_file_present(host):
    """
    Check that the Glances systemd service unit file exists at /etc/systemd/system/glances-web.service.
    """
    assert host.file("/etc/systemd/system/glances-web.service").exists


def test_glances_service_running(host):
    """
    Verify the "glances-web" systemd service is enabled and running.
    
    Asserts that the 'glances-web' service is enabled to start at boot and is currently active.
    
    Parameters:
        host: testinfra host fixture representing the target system under test.
    """
    service = host.service("glances-web")
    assert service.is_enabled
    assert service.is_running