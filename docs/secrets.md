# Handling secrets in your Nix configuration

Managing secrets securely and conveniently is critical for reproducible system configuration—especially when setting up a new machine. This repository leverages [sops](https://github.com/mozilla/sops) and [age](https://github.com/FiloSottile/age) to handle secrets.

## Why use sops and age?

The main goal is to ensure that you **only need your age key** to access all necessary secrets when provisioning a new machine. This approach prevents the need to manually import multiple secrets every time.

## 1. Generate your age key

First, generate a new age key if you do not already have one. This key will be used by sops to encrypt and decrypt all your secrets.

```console
age-keygen -o ~/.config/sops/age/keys.txt
```

> **Note:**
> Keep this key secure! It is the only secret you must have on hand to bootstrap your configuration and unlock all other secrets.

## 2. How secrets are used

The age key is referenced in various parts of this Nix configuration to unlock secrets. For example, the file [`modules/gpg.nix`](../modules/gpg.nix) uses it to decrypt your GPG private key, and [`modules/ssh.nix`](../modules/ssh.nix) uses it to deploy SSH keys.

## 3. Organizing secrets

Secrets are split across multiple YAML files in the [`secrets/`](../secrets/) directory:

- **`secrets/common.yaml`** — Application tokens: `github_token`, `slite_api_key`, `slack_bot_token`, `shortcut_api_token`, `openai_token`
- **`secrets/gpg.yaml`** — GPG keys: `gpg_private_key`, `gpg_passphrase`
- **`secrets/ssh.yaml`** — SSH keys: `id_rsa`, `id_rsa_pub`

To add a new secret:

1. **Create or edit the appropriate YAML file in the `secrets/` directory:**

    ```yaml
    my_new_secret: your_secret_value
    ```

2. **Encrypt the file with sops:**

    ```console
    sops -e -i secrets/common.yaml
    ```

    This will encrypt the file in-place using your age key.

## 4. Understanding the `.sops.yaml` configuration file

This repository includes a `.sops.yaml` file in its root directory. This file defines encryption rules to ensure consistency and security when managing secrets. Here is an overview of its configuration:

- **`path_regex`**: Specifies that files matching `secrets/.*\.yaml$` (all `.yaml` files in the `secrets` directory) should be encrypted.
- **`age`**: Lists the AGE recipient public keys used for encryption. Only holders of the corresponding private key can decrypt the secrets.

This configuration ensures that sensitive keys and data are always encrypted and follow a strict, predefined pattern.

## 5. Updating and decrypting secrets

- **To update the list of keyholders (e.g., after generating a new age key):**

    ```console
    sops updatekeys secrets/common.yaml
    sops updatekeys secrets/gpg.yaml
    sops updatekeys secrets/ssh.yaml
    ```

- **To decrypt and view a secret file:**

    ```console
    sops -d secrets/common.yaml
    ```

    Or simply open for editing with:

    ```console
    sops secrets/common.yaml
    ```

    (This will automatically decrypt, let you edit, then re-encrypt on save.)

## 6. Good practices

- **Never commit unencrypted secrets to the repository.** Always use sops to manage sensitive files.
- **Backup your age key** (`~/.config/sops/age/keys.txt`) securely (e.g., password manager, hardware key, secure USB).
- Rotate keys if you suspect they may be compromised and use `sops updatekeys` to re-encrypt secrets with new keys.

## 7. Further Reading

- [sops documentation](https://github.com/mozilla/sops)
- [age documentation](https://github.com/FiloSottile/age)

---

By following this workflow, you can quickly and safely set up any new machine without the hassle of manually importing multiple secrets.
