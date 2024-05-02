# Use with https://github.com/casey/just
cache_dir := justfile_directory() + "/.cache"
venv_dir := justfile_directory() + "/.venv"
tfstate_sops_file := "tfstate.sops.json"

export PIP_CACHE_DIR := cache_dir + "/pip"

export POETRY_CACHE_DIR := cache_dir + "/poetry"
export POETRY_VIRTUALENVS_PATH := venv_dir
export POETRY_VIRTUALENVS_IN_PROJECT := "1"

export ANSIBLE_CACHE_PLUGIN_CONNECTION := cache_dir + "/ansible"
export ANSIBLE_INVENTORY_PLUGINS := justfile_directory() + "/ansible/plugins/inventory"
export ANSIBLE_COLLECTIONS_PATH := cache_dir + "/ansible-collections"
export ANSIBLE_CACHE := cache_dir
export ANSIBLE_CONFIG := justfile_directory() + "/ansible/ansible.cfg"
export ANSIBLE_ROLES_PATH := cache_dir + "/ansible-roles:" + justfile_directory() + "/ansible/roles"

install:
  poetry install --no-interaction --no-root --sync
  poetry run ansible-galaxy install -r ansible/requirements.yml

decrypt_state:
  cd "terraform/" && \
  sops -d {{ tfstate_sops_file }} > terraform.tfstate

encrypt_state:
  cd "terraform/" && \
  cp terraform.tfstate terraform.json && \
  sops -e terraform.json > {{ tfstate_sops_file }} && \
  rm -f terraform.json terraform.tfstate*

output *OPTS: decrypt_state
  cd "terraform/" && \
  terragrunt output {{ OPTS }}

apply *OPTS: decrypt_state && encrypt_state
  cd "terraform/" && \
  terragrunt apply {{ OPTS }} || true

init *OPTS:
  cd "terraform/" && terragrunt init {{ OPTS }}

play *OPTS: decrypt_state
  poetry run ansible-playbook -i "terraform/" {{ OPTS }} "ansible/plays/vm.yml"

console *OPTS: decrypt_state
  poetry run ansible-console -i "terraform/" {{ OPTS }}

new-role NAME:
  poetry run ansible-galaxy init "ansible/roles/{{ NAME }}"

do *OPTS:
  {{ OPTS }}

helm *OPTS:
  @helm --kubeconfig terraform/files/generated.kubeconfig {{ OPTS }}

kubectl *OPTS:
  @kubectl --kubeconfig terraform/files/generated.kubeconfig {{ OPTS }}
