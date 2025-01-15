terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.1"
    }
  }
}

provider "docker" {
  host     = var.docker_host
  ssh_opts = ["-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-i", var.ssh_key_path]
}

resource "docker_network" "mgmt_net" {
  name   = "mgmt_net"
  driver = "bridge"
}

resource "docker_network" "flix_net" {
  name   = "flix_net"
  driver = "bridge"
}

resource "docker_volume" "media_volume" {
  name   = "media_volume"
  driver = "local"
  driver_opts = {
    type   = "nfs"
    o      = "addr=${var.media_server},rw"
    device = "${var.media_server_mount}"
  }
}

resource "docker_image" "portainer" {
  name = "portainer/portainer-ce:2.21.5"
}

resource "docker_container" "portainer" {
  image = docker_image.portainer.image_id
  name  = "portainer"
  ports {
    internal = 8000
    external = 8000
  }
  ports {
    internal = 9000
    external = 9000
  }
  ports {
    internal = 9443
    external = 9443
  }
  networks_advanced {
    name    = docker_network.mgmt_net.name
    aliases = ["portainer"]
  }
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  volumes {
    volume_name    = "portainer_data"
    container_path = "/data"
  }
}

resource "docker_image" "uptime_kuma" {
  name = "louislam/uptime-kuma:1.23.16"
}

resource "docker_container" "uptime_kuma" {
  image   = docker_image.uptime_kuma.image_id
  name    = "uptime-kuma"
  restart = "unless-stopped"
  ports {
    internal = 3001
    external = 3001
  }
  volumes {
    volume_name    = "uptime_kuma_data"
    container_path = "/app/data"
  }
}

resource "docker_image" "semaphore_ui" {
  name = "semaphoreui/semaphore:v2.11.2"
}

resource "docker_container" "semaphore_ui" {
  image   = docker_image.semaphore_ui.image_id
  name    = "semaphore-ui"
  restart = "unless-stopped"
  ports {
    internal = 3000
    external = 30080
  }
  env = [
    "SEMAPHORE_DB_DIALECT=bolt",
    "SEMAPHORE_ADMIN=${var.semaphore_admin}",
    "SEMAPHORE_ADMIN_PASSWORD=${var.semaphore_admin_password}",
    "SEMAPHORE_ADMIN_NAME=${var.semaphore_admin_name}",
    "SEMAPHORE_ADMIN_EMAIL=${var.semaphore_admin_email}"
  ]
  volumes {
    volume_name    = "semaphore_data"
    container_path = "/var/lib/semaphore"
  }
  volumes {
    volume_name    = "semaphore_config"
    container_path = "/etc/semaphore"
  }
  volumes {
    volume_name    = "semaphore_tmp"
    container_path = "/tmp/semaphore"
  }
}

resource "docker_image" "tdarr" {
  name = "ghcr.io/haveagitgat/tdarr:latest"
}

resource "docker_container" "tdarr" {
  image        = docker_image.tdarr.image_id
  name         = "tdarr"
  restart      = "unless-stopped"
  network_mode = "bridge"
  networks_advanced {
    name    = docker_network.flix_net.name
    aliases = ["tdarr"]
  }
  ports {
    internal = 8265
    external = 8265
  }
  ports {
    internal = 8266
    external = 8266
  }
  env = [
    "TZ=America/Los_Angeles",
    "PUID=1000",
    "PGID=1000",
    "UMASK_SET=002",
    "serverIP=0.0.0.0",
    "serverPort=8266",
    "webUIPort=8265",
    "internalNode=false",
    "inContainer=true",
    "ffmpegVersion=6",
    "nodeName=dstack-tdarr",
  ]
  volumes {
    volume_name    = "tdarr_data"
    container_path = "/app/server"
  }
  volumes {
    volume_name    = "tdarr_config"
    container_path = "/app/configs"
  }
  volumes {
    volume_name    = "tdarr_logs"
    container_path = "/app/logs"
  }
  volumes {
    volume_name    = docker_volume.media_volume.name
    container_path = "/media"
  }
  volumes {
    volume_name    = "transcode_cache"
    container_path = "/temp"
  }
}

resource "docker_image" "tdarr_node" {
  name = "ghcr.io/haveagitgat/tdarr_node:latest"
}

resource "docker_container" "tdarr_node_mov" {
  image   = docker_image.tdarr_node.image_id
  name    = "tdarr-node_mov"
  restart = "unless-stopped"
  networks_advanced {
    name    = docker_network.flix_net.name
    aliases = ["tdarr-node_mov"]
  }
  env = [
    "TZ=America/Los_Angeles",
    "PUID=1000",
    "PGID=1000",
    "UMASK_SET=002",
    "nodeName=dstack-tdarr-node_mov",
    "serverIP=${docker_container.tdarr.network_data.0.ip_address}",
    "serverPort=8266",
    "inContainer=true",
    "ffmpegVersion=6",
  ]
  volumes {
    volume_name    = "tdarr_node_configs"
    container_path = "/app/configs"
  }
  volumes {
    volume_name    = "tdarr_node_logs"
    container_path = "/app/logs"
  }
  volumes {
    volume_name    = docker_volume.media_volume.name
    container_path = "/media"
  }
  volumes {
    volume_name    = "node_transcode_cache"
    container_path = "/temp"
  }
}

resource "docker_container" "tdarr_node_tv" {
  image   = docker_image.tdarr_node.image_id
  name    = "tdarr-node_tv"
  restart = "unless-stopped"
  networks_advanced {
    name    = docker_network.flix_net.name
    aliases = ["tdarr-node_tv"]
  }
  env = [
    "TZ=America/Los_Angeles",
    "PUID=1000",
    "PGID=1000",
    "UMASK_SET=002",
    "nodeName=dstack-tdarr-node_tv",
    "serverIP=${docker_container.tdarr.network_data.0.ip_address}",
    "serverPort=8266",
    "inContainer=true",
    "ffmpegVersion=6",
  ]
  volumes {
    volume_name    = "tdarr_node_configs_tv"
    container_path = "/app/configs"
  }
  volumes {
    volume_name    = "tdarr_node_logs_tv"
    container_path = "/app/logs"
  }
  volumes {
    volume_name    = docker_volume.media_volume.name
    container_path = "/media"
  }
  volumes {
    volume_name    = "node_transcode_cache_tv"
    container_path = "/temp"
  }
}
