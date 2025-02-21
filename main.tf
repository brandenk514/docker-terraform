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

### NETWORKS ###

resource "docker_network" "mgmt_net" {
  name   = "mgmt_net"
  driver = "bridge"
}

resource "docker_network" "flix_net" {
  name   = "flix_net"
  driver = "bridge"
}

resource "docker_network" "tovpn_net" {
  name   = "tovpn_net"
  driver = "bridge"
}

### VOLUMES ###

resource "docker_volume" "transmission_dl_vol" {
  name   = "transmission_dl_vol"
  driver = "local"
  driver_opts = {
    type   = "nfs4"
    o      = "addr=${var.media_server},rw,noatime,rsize=8192,wsize=8192,tcp,timeo=14"
    device = var.transmission_mnt
  }
}

resource "docker_volume" "media_library" {
  name   = "media-library"
  driver = "local"
  driver_opts = {
    type   = "nfs4"
    o      = "addr=${var.media_server},rw,noatime,rsize=8192,wsize=8192,tcp,timeo=14"
    device = var.media_library_mnt
  }
}

### IMAGES ###

resource "docker_image" "portainer" {
  name          = "portainer/portainer-ce:2.21.5"
  keep_locally  = true
}

resource "docker_image" "uptime_kuma" {
  name          = "louislam/uptime-kuma:1.23.16"
  keep_locally  = true
}

resource "docker_image" "semaphore_ui" {
  name          = "semaphoreui/semaphore:v2.11.2"
  keep_locally  = true
}

resource "docker_image" "tdarr" {
  name          = "ghcr.io/haveagitgat/tdarr:latest"
  keep_locally  = true
}

resource "docker_image" "tdarr_node" {
  name          = "ghcr.io/haveagitgat/tdarr_node:latest"
  keep_locally  = true
}

resource "docker_image" "transmission_openvpn" {
  name          = "haugene/transmission-openvpn"
  keep_locally  = true
}

resource "docker_image" "flaresolverr" {
  name          = "flaresolverr/flaresolverr:latest"
  keep_locally  = true
}

### CONTAINERS ###

resource "docker_container" "portainer" {
  image   = docker_image.portainer.image_id
  name    = "portainer"
  restart = "unless-stopped"
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

resource "docker_container" "uptime_kuma" {
  image   = docker_image.uptime_kuma.image_id
  name    = "uptime-kuma"
  restart = "unless-stopped"
  networks_advanced {
    name    = docker_network.mgmt_net.name
    aliases = ["uptime-kuma"]
  }
  ports {
    internal = 3001
    external = 3001
  }
  volumes {
    volume_name    = "uptime_kuma_data"
    container_path = "/app/data"
  }
}

resource "docker_container" "semaphore_ui" {
  image   = docker_image.semaphore_ui.image_id
  name    = "semaphore-ui"
  restart = "unless-stopped"
  networks_advanced {
    name    = docker_network.mgmt_net.name
    aliases = ["semaphore-ui"]
  }
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

resource "docker_container" "tdarr_server" {
  image        = docker_image.tdarr.image_id
  name         = "tdarr_server"
  restart      = "unless-stopped"
  network_mode = "bridge"
  networks_advanced {
    name    = docker_network.flix_net.name
    aliases = ["tdarr_server"]
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
    "TZ=${var.timezone}",
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
    volume_name    = docker_volume.media_library.name
    container_path = "/media"
  }
  volumes {
    volume_name    = "tdarr_transcode_cache"
    container_path = "/temp"
  }
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
    "TZ=${var.timezone}",
    "PUID=1000",
    "PGID=1000",
    "UMASK_SET=002",
    "nodeName=tdarr-node_mov",
    "serverIP=${docker_container.tdarr_server.network_data.0.ip_address}",
    "serverPort=8266",
    "inContainer=true",
    "ffmpegVersion=6",
  ]
  volumes {
    volume_name    = "tdarr_node_mov_configs"
    container_path = "/app/configs"
  }
  volumes {
    volume_name    = "tdarr_node_mov_logs"
    container_path = "/app/logs"
  }
  volumes {
    volume_name    = docker_volume.media_library.name
    container_path = "/media"
  }
  volumes {
    volume_name    = "tdarr_node_mov_cache"
    container_path = "/temp"
  }
}

resource "docker_container" "tdarr_node_tv" {
  image   = docker_image.tdarr_node.image_id
  name    = "tdarr_node_tv"
  restart = "unless-stopped"
  networks_advanced {
    name    = docker_network.flix_net.name
    aliases = ["tdarr_node_tv"]
  }
  env = [
    "TZ=${var.timezone}",
    "PUID=1000",
    "PGID=1000",
    "UMASK_SET=002",
    "nodeName=tdarr-node_tv",
    "serverIP=${docker_container.tdarr_server.network_data.0.ip_address}",
    "serverPort=8266",
    "inContainer=true",
    "ffmpegVersion=6",
  ]
  volumes {
    volume_name    = "tdarr_node_tv_configs"
    container_path = "/app/configs"
  }
  volumes {
    volume_name    = "tdarr_node_tv_logs"
    container_path = "/app/logs"
  }
  volumes {
    volume_name    = docker_volume.media_library.name
    container_path = "/media"
  }
  volumes {
    volume_name    = "tdarr_node_tv_cache"
    container_path = "/temp"
  }
}

resource "docker_container" "transmission_openvpn" {
  image   = docker_image.transmission_openvpn.image_id
  name    = "tovpn"
  restart = "unless-stopped"
  capabilities {
    add = ["NET_ADMIN"]
  }
  privileged = true
  networks_advanced {
    name    = docker_network.tovpn_net.name
    aliases = ["tovpn"]
  }
  ports {
    internal = 9091
    external = 9091
  }
  env = [
    "OPENVPN_PROVIDER=NORDVPN",
    "OPENVPN_CONFIG=",
    "OPENVPN_USERNAME=${var.openvpn_username}",
    "OPENVPN_PASSWORD=${var.openvpn_password}",
    "LOCAL_NETWORK=192.168.100.0/24, 192.168.105.0/24",
    "TRANSMISSION_WEB_HOME=/opt/transmission-ui/flood-for-transmission"
  ]
  volumes {
    volume_name    = docker_volume.transmission_dl_vol.name
    container_path = "/data"
  }
  volumes {
    volume_name    = "transmission_conf_vol"
    container_path = "/config"
  }
}

resource "docker_container" "flaresolverr" {
  image   = docker_image.flaresolverr.image_id
  name    = "flaresolverr"
  restart = "unless-stopped"
  networks_advanced {
    name    = docker_network.tovpn_net.name
    aliases = ["flaresolverr"]
  }
  ports {
    internal = 8191
    external = 8191
  }
  env = [
    "LOG_LEVEL=info",
    "LOG_HTML=false",
    "CAPTCHA_SOLVER=none",
    "TZ=${var.timezone}",
  ]
}
