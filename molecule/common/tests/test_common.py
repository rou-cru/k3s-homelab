"""Tests for common role."""

COMMON_PACKAGES = [
    "curl",
    "ca-certificates",
    "iptables",
    "ethtool",
    "network-manager",
    "acpid",
    "rsync",
]


def test_common_packages_installed(host):
    for package in COMMON_PACKAGES:
        assert host.package(package).is_installed, f"Package not installed: {package}"


def test_swap_entries_commented(host):
    """Ensure no active swap entries remain in /etc/fstab."""
    cmd = host.run("grep -E '^[^#].*[[:space:]]swap[[:space:]]' /etc/fstab")
    assert cmd.rc != 0, "Found active swap entry in /etc/fstab"
