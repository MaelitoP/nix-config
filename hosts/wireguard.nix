{ config, ... }:

{
  sops.age.keyFile = "${config.host.home}/.config/sops/age/keys.txt";
  sops.age.sshKeyPaths = [ ];
  sops.gnupg.sshKeyPaths = [ ];
  sops.secrets.wg_laptop_private_key.sopsFile = ../secrets/wireguard.yaml;

  networking.wg-quick.interfaces.laptop = {
    autostart = false;
    address = [ "10.83.42.2/32" ];
    dns = [
      "9.9.9.9"
      "1.1.1.1"
    ];
    mtu = 1380;
    privateKeyFile = config.sops.secrets.wg_laptop_private_key.path;
    peers = [
      {
        publicKey = "UT37FqH6fw8xTS79WSdNhSQRDZ2DWtw89+F6ndccyyk=";
        endpoint = "51.15.220.47:51871";
        # ::/0 routes IPv6 into the tunnel, where the server drops it, so nothing leaks outside.
        allowedIPs = [
          "0.0.0.0/0"
          "::/0"
        ];
        persistentKeepalive = 25;
      }
    ];
  };
}
