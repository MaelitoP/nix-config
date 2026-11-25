# Installing NixOS on maelito-desktop

The desktop dual-boots Windows (2 TB NVMe, never touched here) and NixOS (1 TB Samsung 870 QVO, wiped by the install). The partition layout comes from `hosts/maelito-desktop/disk.nix`.

## Before

- Windows: Fast Startup off (`powercfg /h off`), anything worth keeping copied off the Linux disk.
- Firmware: Secure Boot disabled for the install (ASUS: `OS Type` on `Other OS`). FACEIT refuses to start until it is back on, see [Secure Boot](#secure-boot).
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

   `install -D` creates the missing parent directories as root, home included, so hand them back:

   ```
   sudo chown -R 1000:100 /mnt/home/maelito
   ```

6. Reboot without the key. In the firmware, keep Windows Boot Manager first in the boot order; NixOS is "Linux Boot Manager" in the boot menu.

## After the first boot

- Connect to Wi-Fi (`nmtui`), clone this repository into `~/dev/nix-config`, then use `just rebuild`.
- Remove the stale Ubuntu firmware entry: `efibootmgr` to list, `sudo efibootmgr -b <number> -B` to delete.

## Secure Boot

NixOS boots through lanzaboote, which signs the boot files with keys generated on the machine (`/var/lib/sbctl`). The firmware only accepts them once they are enrolled, next to Microsoft's so that Windows and the graphics card firmware keep loading.

1. Check that the keys exist and the boot files are signed. Files under `EFI/Linux` and `EFI/systemd` must show as signed; Windows files are not on this disk.

   ```
   sudo sbctl status
   sudo sbctl verify
   ```

2. Reboot into the firmware (ASUS: `Boot` → `Secure Boot`), set `Secure Boot Mode` to `Custom`, open `Key Management` → `PK Management` and delete the Platform Key. This puts the firmware in Setup Mode. Do not use "Clear Secure Boot Keys": it also empties the revocation list. Save and boot NixOS.

3. Enroll the keys. `--microsoft` is required: without Microsoft's certificates Windows stops booting and the graphics card may not initialise.

   ```
   sudo sbctl enroll-keys --microsoft
   ```

4. Reboot into the firmware, set `OS Type` to `Windows UEFI mode`, save. Check from NixOS with `bootctl status` (`Secure Boot: enabled (user)`) and from Windows with `Confirm-SecureBootUEFI`.

If anything goes wrong, `Key Management` → `Install Default Secure Boot Keys` restores the factory keys: Windows boots again, and NixOS needs `OS Type` on `Other OS` until the keys are enrolled.
