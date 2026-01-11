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

variable "RIGEL_VERSION" {
  default = "1.23.1"
}

variable "RIGEL_SHA256" {
  default = "c6081504eb56473647d85ac5888058e00e03c1ca59bb2703e6af413ef897df0a"
}

variable "TNN_REF" {
  default = "dev"
}

variable "TNN_CMAKE_VERSION" {
  default = "3.30.5"
}

# Default group builds everything
group "default" {
  targets = ["cpu-miner-i9", "cpu-miner-generic", "cpu-miner-tnn", "gpu-miner", "gpu-miner-rigel"]
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

# 2b. CPU Miner TNN (CPU-only)
target "cpu-miner-tnn" {
  context = "images/cpu-miner-tnn"
  dockerfile = "Dockerfile"
  args = {
    TNN_REF = "${TNN_REF}"
    CMAKE_VERSION = "${TNN_CMAKE_VERSION}"
  }
  tags = ["${REGISTRY}/k3s-cpu-miner:tnn"]
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

# 4. GPU Miner Rigel (Experimental)
target "gpu-miner-rigel" {
  context = "images/gpu-miner-rigel"
  dockerfile = "Dockerfile"
  args = {
    RIGEL_VERSION = "${RIGEL_VERSION}"
    RIGEL_SHA256 = "${RIGEL_SHA256}"
  }
  tags = ["${REGISTRY}/k3s-gpu-miner:rigel"]
  platforms = ["linux/amd64"]
}
