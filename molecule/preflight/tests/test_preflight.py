"""Tests for preflight role."""

import pytest


def test_network_connectivity(host):
    """Verify connectivity to K3s installation endpoint."""
    cmd = host.run("curl -sSf --max-time 10 https://get.k3s.io")
    assert cmd.rc == 0, "Failed to reach https://get.k3s.io"


def test_disk_space_sufficient(host):
    """Verify root partition has >20GB available."""
    df_output = host.check_output("df --output=avail / | tail -1")
    avail_kb = int(df_output.strip())
    min_kb = 20 * 1024 * 1024  # 20GB in KB

    assert avail_kb > min_kb, (
        f"Insufficient disk space: {avail_kb / 1024 / 1024:.2f}GB < 20GB"
    )


def test_memory_sufficient(host):
    """Verify system has >=4GB RAM."""
    meminfo = host.file("/proc/meminfo").content_string
    memtotal_line = [line for line in meminfo.split("\n") if "MemTotal" in line][0]
    memtotal_kb = int(memtotal_line.split()[1])
    memtotal_mb = memtotal_kb / 1024

    assert memtotal_mb >= 4096, (
        f"Insufficient memory: {memtotal_mb:.2f}MB < 4096MB"
    )


def test_architecture_x86_64(host):
    """Verify system architecture is x86_64."""
    arch = host.check_output("uname -m").strip()
    assert arch == "x86_64", f"Unsupported architecture: {arch}"


def test_curl_installed(host):
    """Verify curl is available (required by preflight checks)."""
    cmd = host.run("which curl")
    assert cmd.rc == 0, "curl not found in PATH"


def test_df_command_available(host):
    """Verify df command is available (required by preflight checks)."""
    cmd = host.run("which df")
    assert cmd.rc == 0, "df command not found in PATH"
