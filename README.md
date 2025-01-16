# Docker Terraform Setup

This Terraform configuration sets up a Docker environment with multiple containers and networks.

## Requirements

- Terraform >= 0.12
- Docker

## Providers

- Docker (kreuzwerker/docker)

## Variables

- `docker_host`: The Docker host.
- `ssh_key_path`: Path to the SSH key.
- `media_server`: The address of the media server.
- `transmission_mnt`: The mount point for the Transmission volume.
- `media_library_mnt`: The mount point for the media library volume.
- `semaphore_admin`: Semaphore admin username.
- `semaphore_admin_password`: Semaphore admin password.
- `semaphore_admin_name`: Semaphore admin name.
- `semaphore_admin_email`: Semaphore admin email.
- `timezone`: Timezone for the containers.
- `openvpn_username`: Username for OpenVPN.
- `openvpn_password`: Password for OpenVPN.

## Usage

1. Clone the repository.
2. Create a `terraform.tfvars` file with the required variables.
3. Run `terraform init` to initialize the configuration.
4. Run `terraform apply` to apply the configuration.

## Example `terraform.tfvars`

```hcl
docker_host        = "tcp://192.168.1.100:2376"
ssh_key_path       = "/path/to/ssh/key"
media_server       = "192.168.1.200"
transmission_mnt   = "/mnt/transmission"
media_library_mnt  = "/mnt/media-library"
semaphore_admin    = "admin"
semaphore_admin_password = "password"
semaphore_admin_name = "Admin Name"
semaphore_admin_email = "admin@example.com"
timezone           = "America/New_York"
openvpn_username   = "your_openvpn_username"
openvpn_password   = "your_openvpn_password"
```

## Resources

- Docker networks: `mgmt_net`, `flix_net`, `tovpn_net`
- Docker volumes: `transmission_dl_vol`, `media_library`, `portainer_data`, `uptime_kuma_data`, `semaphore_data`, `semaphore_config`, `semaphore_tmp`, `tdarr_data`, `tdarr_config`, `tdarr_logs`, `transcode_cache`, `tdarr_node_mov_configs`, `tdarr_node_mov_logs`, `tdarr_node_mov_cache`, `tdarr_node_tv_configs`, `tdarr_node_tv_logs`, `tdarr_node_tv_cache`, `transmission_conf_vol`
- Docker images: `portainer`, `uptime_kuma`, `semaphore_ui`, `tdarr`, `tdarr_node`, `transmission_openvpn`, `flaresolverr`
- Docker containers: `portainer`, `uptime_kuma`, `semaphore_ui`, `tdarr_server`, `tdarr_node_mov`, `tdarr_node_tv`, `transmission_openvpn`, `flaresolverr`