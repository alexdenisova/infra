# infra

Infrastructure configuration.

## Setup

### Install utilities

1. [`ansible`](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html);
2. [`sops`](https://github.com/mozilla/sops/releases/latest);
3. [`terraform`](https://developer.hashicorp.com/terraform/downloads);
4. [`terragrunt`](https://github.com/gruntwork-io/terragrunt/releases/latest);
5. [`kubectl`](https://kubernetes.io/ru/docs/tasks/tools/);
6. [`helm`](https://github.com/helm/helm/releases/latest);
7. [`just`](https://github.com/casey/just);

##### Debian/Ubuntu

```sh
# ANSIBLE
sudo apt install pipx
pipx install --include-deps ansible

# POETRY
pipx install poetry

# SOPS
curl -Lo sops https://github.com/mozilla/sops/releases/download/v3.7.2/sops-v3.7.2.linux.amd64
sudo mv ./sops /usr/local/bin/sops
chmod +x /usr/local/bin/sops

# TERRAFORM
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common
wget -O- https://apt.releases.hashicorp.com/gpg | \
gpg --dearmor | \
sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# TERRAGRUNT
curl -LO https://github.com/gruntwork-io/terragrunt/releases/download/v0.55.19/terragrunt_linux_amd64
sudo mv terragrunt_linux_amd64 /usr/local/bin/terragrunt
chmod +x /usr/local/bin/terragrunt

# KUBECTL
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# HELM
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm -f get_helm.sh

# JUST
curl -LO https://github.com/casey/just/releases/download/1.25.2/just-1.25.2-x86_64-unknown-linux-musl.tar.gz
mkdir just
tar -xzf just-1.25.2-x86_64-unknown-linux-musl.tar.gz -C just
sudo mv just/just /usr/local/bin/just
rm -rf just just-1.25.2-x86_64-unknown-linux-musl.tar.gz
```

### Configure `sops` to work with secrets

1. Install GnuPG to work with keys
2. Import the private key
3. Make the key trusted
4. If working with VSCode, install the sops extention @signageos/vscode-sops

##### Debian/Ubuntu

```sh
apt install gnupg
# import the private key
gpg --import private.key
#  get the key id
gpg --list-secret-keys
# make the key trusted
gpg --edit-key ${KEY_ID} trust quit
```

### Install all dependencies:

```sh
just install
```

## Justfile

Type `just --list` to see the commands.

## Repo structure

- [`ansible`](ansible/) - project-specific Ansible objects
  - [`inventories`](ansible/inventories/) - Ansible inventories (deprecated, inventory is currently configured with Terraform).
  - [`plays`](ansible/plays/) - Ansible playbooks
  - [`plugins`](ansible/plugins/) - Ansible plugins
  - [`roles`](ansible/roles/) - Ansible roles
- [`docker`](docker/) - docker images
- [`modules`](modules/) - Terraform modules
- [`terraform`](terraform/) - infrastructure objects described with [Hashicorp Configuration Language (HCL)](https://www.terraform.io/language/syntax/configuration)
- [`.sops.yaml`](.sops.yaml) - sops config
- [`justfile`](justfile) - justfile for command simplification
- [`terragrunt.hcl`](terragrunt.hcl) - terragrunt config
