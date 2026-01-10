variable "REGISTRY" {
  default = "roucru"
}

variable "TAG" {
  default = "latest"
}

variable "XMRIG_VERSION" {
  default = "6.25.0"
}

variable "LOLMINER_VERSION" {
  default = "1.98a"
}

variable "LOLMINER_SHA256" {
  default = "0b8078299654a12846e4967f1db3506409cfb8b1031687a910965d1a99c6f270"
}

# Default group builds everything
group "default" {
  targets = ["cpu-miner-i9", "cpu-miner-generic", "gpu-miner"]
}

# 1. Optimized Build (i9)
target "cpu-miner-i9" {
  context = "images/cpu-miner"
  dockerfile = "Dockerfile"
  args = {
    XMRIG_VERSION = "${XMRIG_VERSION}"
    BUILD_TYPE = "native"
  }
  tags = ["${REGISTRY}/k3s-cpu-miner:i9", "${REGISTRY}/k3s-cpu-miner:latest"]
  platforms = ["linux/amd64"]
}

# 2. Generic Build
target "cpu-miner-generic" {
  context = "images/cpu-miner"
  dockerfile = "Dockerfile"
  args = {
    XMRIG_VERSION = "${XMRIG_VERSION}"
    BUILD_TYPE = "generic"
  }
  tags = ["${REGISTRY}/k3s-cpu-miner:generic"]
  platforms = ["linux/amd64"]
}

# 3. GPU Miner (Verified Checksum)
target "gpu-miner" {
  context = "images/gpu-miner"
  dockerfile = "Dockerfile"
  args = {
    LOLMINER_VERSION = "${LOLMINER_VERSION}"
    LOLMINER_SHA256 = "${LOLMINER_SHA256}"
  }
  tags = ["${REGISTRY}/k3s-gpu-miner:latest"]
  platforms = ["linux/amd64"]
}