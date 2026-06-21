#cloud-config
autoinstall:
  version: 1
  locale: ${locale}
  keyboard:
    layout: ${keyboard_layout}
  timezone: ${timezone}
%{ if static_network_enabled ~}
  network:
    version: 2
    ethernets:
      ${installer_interface}:
        dhcp4: false
        addresses:
          - ${installer_ip}/${installer_prefix}
        routes:
          - to: default
            via: ${installer_gateway}
        nameservers:
          addresses:
            - ${installer_nameserver}
%{ if secondary_ip != "" ~}
      ${secondary_interface}:
        dhcp4: false
        addresses:
          - ${secondary_ip}
%{ endif ~}
%{ endif ~}
  identity:
    hostname: ${host_name}
    username: ${installer_username}
    password: "${installer_password_hash}"
  ssh:
    install-server: true
    allow-pw: false
    authorized-keys:
%{ for ssh_key in installer_authorized_keys ~}
      - ${ssh_key}
%{ endfor ~}
  packages:
    - cloud-init
    - open-vm-tools
    - openssh-server
    - perl
    - python3
    - sudo
    - tar
    - vim-tiny
  storage:
    layout:
      name: lvm
  late-commands:
    - ["curtin", "in-target", "--target=/target", "--", "systemctl", "enable", "ssh"]
    - ["curtin", "in-target", "--target=/target", "--", "systemctl", "enable", "open-vm-tools"]
    - ["curtin", "in-target", "--target=/target", "--", "mkdir", "-p", "/etc/sudoers.d"]
    - ["curtin", "in-target", "--target=/target", "--", "sh", "-c", "printf '%s ALL=(ALL) NOPASSWD: ALL\\n' '${installer_username}' > /etc/sudoers.d/90-${installer_username}"]
    - ["curtin", "in-target", "--target=/target", "--", "chmod", "0440", "/etc/sudoers.d/90-${installer_username}"]
    - ["curtin", "in-target", "--target=/target", "--", "apt-get", "clean"]
  user-data:
    disable_root: true
