# Installing NixOS on maelito-desktop

The desktop dual-boots Windows (2 TB NVMe, never touched here) and NixOS (1 TB Samsung 870 QVO, wiped by the install). The partition layout comes from `hosts/maelito-desktop/disk.nix`.

## Before

- Windows: Fast Startup off (`powercfg /h off`), anything worth keeping copied off the Linux disk.
- Firmware: Secure Boot disabled for the install. FACEIT refuses to start until it is back on.
- A USB key with the NixOS graphical ISO, and the age key (`keys.txt`) on a second drive.

## Install

1. Boot the key from the firmware boot menu, close the installer window, connect to Wi-Fi.
2. Check that the disk in `disk.nix` is the Samsung 870 QVO:

   ```
   ls -l /dev/disk/by-id/ | grep 870_QVO
   ```

3. Partition, format and mount it under `/mnt`:

   ```
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
     --mode destroy,format,mount --flake github:MaelitoP/nix-config#maelito-desktop
   ```

4. Install the system, then set the user's password:

   ```
   sudo nixos-install --no-root-passwd --flake github:MaelitoP/nix-config#maelito-desktop
   sudo nixos-enter --root /mnt -c 'passwd maelito'
   ```

5. Put the age key in place, owned by the user (uid 1000, group `users`):

   ```
   sudo install -D -m 600 -o 1000 -g 100 /path/to/keys.txt /mnt/home/maelito/.config/sops/age/keys.txt
   ```

6. Reboot without the key. In the firmware, keep Windows Boot Manager first in the boot order; NixOS is "Linux Boot Manager" in the boot menu.

## After the first boot

- Connect to Wi-Fi (`nmtui`), clone this repository into `~/dev/nix-config`, then use `just rebuild`.
- Remove the stale Ubuntu firmware entry: `efibootmgr` to list, `sudo efibootmgr -b <number> -B` to delete.
- Secure Boot is still off at this point.
