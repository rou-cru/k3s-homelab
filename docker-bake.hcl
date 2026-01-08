variable "REGISTRY" {
  default = "roucru"
}

variable "TAG" {
  default = "latest"
}

variable "XMRIG_VERSION" {
  default = "6.21.0"
}

variable "LOLMINER_VERSION" {
  default = "1.84"
}

# Default group builds everything
group "default" {
  targets = ["cpu-miner-i9", "cpu-miner-generic", "gpu-miner"]
}

# 1. Optimized Build (i9) - Tagged as :i9 and :latest
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

# 2. Generic Build - Tagged as :generic
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

# 3. GPU Miner
target "gpu-miner" {
  context = "images/gpu-miner"
  dockerfile = "Dockerfile"
  args = {
    LOLMINER_VERSION = "${LOLMINER_VERSION}"
  }
  tags = ["${REGISTRY}/k3s-gpu-miner:latest"]
  platforms = ["linux/amd64"]
}
