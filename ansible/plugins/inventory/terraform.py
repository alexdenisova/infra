"""
Ansible Terraform inventory plugin
"""
from __future__ import absolute_import, division, print_function

__metaclass__ = type

import json
import os
import shutil
import textwrap
from enum import Enum
from pathlib import Path
from subprocess import PIPE, Popen
from typing import Any, Callable, Dict, Iterator, List, Optional, Tuple, Union

from ansible.errors import AnsibleParserError, AnsiblePluginError
from ansible.inventory.data import InventoryData
from ansible.parsing.dataloader import DataLoader
from ansible.plugins.inventory import BaseInventoryPlugin, Cacheable
from ansible.utils.display import Display
from pydantic import BaseModel

DOCUMENTATION = """
---
name: terraform
plugin_type: inventory
requirements:
  - pydantic >= 1.8
extends_documentation_fragment:
  - inventory_cache
short_description: Terraform logical inventory plugin
description:
  - Generates ansible inventory from terraform state
  - Use with ansible logical provider https://github.com/nbering/terraform-provider-ansible/
notes:
  - terraform directory must contain file C(main.tf)
version_added: 0.1.0
options:
  terraform_path:
    description: path to terraform executable
    default: null
    required: false
    type: path
    env:
      - name: TERRAFORM_PATH
"""


class InventoryModule(BaseInventoryPlugin, Cacheable):
    NAME = "terraform"
    ENCODING = "utf-8"
    TERRAFORM_EXECUTABLE = "terraform"
    TERRAFORM_MAIN_FILE = "main.tf"
    DISPLAY = Display()

    def __init__(self):
        super().__init__()
        self._terraform_path: Optional[str] = None

    @property
    def terraform_path(self) -> str:
        if self._terraform_path is None:
            self._terraform_path = self._get_terraform_path()
            self.DISPLAY.v(f"using terraform executable {self._terraform_path!r}")

        return self._terraform_path

    def parse(
        self,
        inventory: InventoryData,
        loader: DataLoader,
        path: str,
        cache=True,
    ) -> None:
        if self._skip_file(path):
            self.DISPLAY.vv(f"skipping file {path!r}")
            return

        super().parse(inventory, loader, path)
        self.set_options()
        tf_directory = Path(path).resolve(strict=True).parent
        model = self._get_inventory_model(tf_directory, cache)
        self.DISPLAY.vvvv(f"parsed terraform state: {model.json()}")
        model.apply(inventory, loader)

    def _skip_file(self, path: str) -> bool:
        return Path(path).name != self.TERRAFORM_MAIN_FILE

    def _get_inventory_model(self, path: Path, cache=True) -> "AnsibleInventoryModel":
        self.load_cache_plugin()
        cache_key = self.get_cache_key(path)
        user_cache_setting = self.get_option("cache")
        attempt_to_read_cache = user_cache_setting and cache
        cache_needs_update = user_cache_setting and not cache

        result: Optional[AnsibleInventoryModel] = None
        state = self._get_terraform_state(path)

        cached_result = (
            self._read_cached_inventory_model(
                cache_key, TerraformStateIdModel.from_state(state)
            )
            if attempt_to_read_cache
            else None
        )
        if cached_result:
            result = cached_result
        else:
            cache_needs_update = True

        if result is None:
            result = self._read_inventory_model(state)
        if cache_needs_update:
            self._cache[cache_key] = result.dict()

        return result

    def _read_cached_inventory_model(
        self, cache_key: str, state_id: "TerraformStateIdModel"
    ) -> Optional["AnsibleInventoryModel"]:
        result = None
        raw_cache = self._cache.get(cache_key)
        if not raw_cache:
            return result
        cached_result = AnsibleInventoryModel.parse_obj(raw_cache)
        if cached_result.state_id and cached_result.state_id == state_id:
            result = cached_result
        return result

    def _read_inventory_model(self, state: Dict[str, Any]) -> "AnsibleInventoryModel":
        builder = AnsibleInventoryBuilder()
        for res_type, res in self._get_ansible_resources(state):
            builder.add_source(res_type, res)
        return builder.build(TerraformStateIdModel.from_state(state))

    @staticmethod
    def _get_ansible_resources(
        state: Any,
    ) -> Iterator[Tuple["AnsibleResourceType", "AnsibleResource"]]:
        for r in state_get_key(state, "resources"):
            tf_resource_type = state_get_key(r, "type")
            ansible_resource_type = AnsibleResourceType.from_str(tf_resource_type)
            if not ansible_resource_type:
                continue

            instances = state_get_path(r, "instances")
            for inst in instances:
                yield ansible_resource_type, AnsibleResource(
                    tf_resource_type=tf_resource_type, resource=inst
                )

    def _get_terraform_path(self) -> str:
        option = self.get_option("terraform_path")

        if not option:
            result = shutil.which(self.TERRAFORM_EXECUTABLE)
            if not result:
                raise AnsiblePluginError(
                    f"unable to find {self.TERRAFORM_EXECUTABLE} in path"
                )
        else:
            try:
                path = Path(option).resolve(strict=True)
                if not path.is_file() or not os.access(str(path), os.X_OK):
                    raise AnsiblePluginError("invalid terraform path")
                result = str(path)
            except FileNotFoundError as e:
                raise AnsiblePluginError(f"path {option!r} does not exist") from e
            except RuntimeError as e:
                raise AnsiblePluginError() from e

        return result

    def _get_terraform_state(self, path: Path) -> Any:
        path_str = str(path)

        with Popen(
            args=[self.terraform_path, "state", "pull"],
            stdout=PIPE,
            stderr=PIPE,
            encoding=self.ENCODING,
            cwd=path_str,
        ) as p:
            self.DISPLAY.v(f"reading terraform state from {path_str!r}")
            stdout, stderr = p.communicate()
            if p.returncode != 0:
                raise AnsiblePluginError(
                    f"terraform failed with exit code {p.returncode}:\n{textwrap.indent(stderr, '  ')}"
                )
            return json.loads(stdout)


class Raise:
    pass


class AnsibleHostModel(BaseModel):
    name: str
    groups: List[str]
    host_vars: Dict[str, Any]


class AnsibleGroupModel(BaseModel):
    name: str
    children: List[str]
    group_vars: Dict[str, Any]


class TerraformStateIdModel(BaseModel):
    lineage: str
    serial: int

    @staticmethod
    def from_state(state: Dict[str, Any]) -> "TerraformStateIdModel":
        return TerraformStateIdModel(
            lineage=state_get_path(state, "lineage", converter=str),
            serial=state_get_path(state, "serial", converter=int),
        )

    def __eq__(self, other: "TerraformStateIdModel"):
        return self.lineage == other.lineage and self.serial == other.serial


class AnsibleInventoryModel(BaseModel):
    state_id: Optional[TerraformStateIdModel] = None
    hosts: List[AnsibleHostModel]
    groups: List[AnsibleGroupModel]

    def apply(self, inventory: InventoryData, loader: DataLoader) -> None:
        def _load(value):
            return loader.load(value, json_only=False)

        for group in self.groups:
            inventory.add_group(group.name)
            for k, v in group.group_vars.items():
                inventory.set_variable(group.name, k, _load(v))
        for group in self.groups:
            for c in group.children:
                inventory.add_child(group.name, c)
        for host in self.hosts:
            inventory.add_host(host.name)
            for group_name in host.groups:
                inventory.add_child(group_name, host.name)
            for k, v in host.host_vars.items():
                inventory.set_variable(host.name, k, _load(v))


class AnsibleResourceType(Enum):
    GROUP = "group"
    HOST = "host"

    @staticmethod
    def from_str(value: str) -> Optional["AnsibleResourceType"]:
        result = None
        if value.startswith("ansible_group"):
            result = AnsibleResourceType.GROUP
        elif value.startswith("ansible_host"):
            result = AnsibleResourceType.HOST
        return result


class AnsibleResource:
    def __init__(self, tf_resource_type: str, resource: Dict[str, Any]) -> None:
        self._name = tf_resource_type
        self._resource = resource
        self._attributes = state_get_path(resource, "attributes")

    @property
    def tf_resource_type(self) -> str:
        return self._name

    @property
    def group_name(self) -> str:
        return state_get_key(self._attributes, "inventory_group_name")

    @property
    def host_name(self) -> str:
        return state_get_key(self._attributes, "inventory_hostname")

    @property
    def priority(self) -> int:
        return int(state_get_key(self._attributes, "variable_priority", default=0))

    @property
    def groups(self) -> List[str]:
        return state_get_key(self._attributes, "groups", default=[])

    @property
    def children(self) -> List[str]:
        return state_get_key(self._attributes, "children", default=[])

    @property
    def vars(self) -> Dict[str, Any]:
        return state_get_key(self._attributes, "vars", default={})

    @property
    def var(self) -> Dict[str, Any]:
        key = state_get_key(self._attributes, "key")
        value = state_get_key(self._attributes, "value")
        return {key: value}


class AnsibleHostBuilder:
    def __init__(self, name: str) -> None:
        self._name = name
        self._sources: List[AnsibleResource] = []
        # every host belongs to `all` group
        self._groups = set(["all"])
        self._vars = {}

    def add_source(self, *sources: AnsibleResource) -> "AnsibleHostBuilder":
        self._sources.extend(sources)
        return self

    def build(self) -> AnsibleHostModel:
        for src in sorted(self._sources, key=lambda x: x.priority):
            if src.tf_resource_type == "ansible_host":
                groups = src.groups
                host_vars = src.vars
                self._update(groups=groups, host_vars=host_vars)
            elif src.tf_resource_type == "ansible_host_var":
                host_vars = src.var
                self._update(host_vars=host_vars)

        return AnsibleHostModel(
            name=self._name,
            groups=sorted(self._groups),
            host_vars=self._vars,
        )

    def _update(
        self,
        *,
        groups: Optional[List[str]] = None,
        host_vars: Optional[Dict[str, Any]] = None,
    ):
        if host_vars:
            self._vars.update(host_vars)
        if groups:
            self._groups.update(groups)


class AnsibleGroupBuilder:
    def __init__(self, name: str) -> None:
        self._name = name
        self._sources: List[AnsibleResource] = []
        self._children = set()
        self._vars = {}

    def add_source(self, source: AnsibleResource) -> None:
        self._sources.append(source)

    def build(self) -> AnsibleGroupModel:
        for src in sorted(self._sources, key=lambda x: x.priority):
            if src.tf_resource_type == "ansible_group":
                children = src.children
                group_vars = src.vars
                self._update(children=children, group_vars=group_vars)
            elif src.tf_resource_type == "ansible_group_var":
                group_vars = src.var
                self._update(group_vars=group_vars)

        return AnsibleGroupModel(
            name=self._name,
            children=sorted(self._children),
            group_vars=self._vars,
        )

    def _update(
        self,
        *,
        children: Optional[List[str]] = None,
        group_vars: Optional[Dict[str, Any]] = None,
    ):
        if group_vars:
            self._vars.update(group_vars)
        if children:
            self._children.update(children)


class AnsibleInventoryBuilder:
    def __init__(self) -> None:
        self._hosts: Dict[str, AnsibleHostBuilder] = {}
        self._groups: Dict[str, AnsibleGroupBuilder] = {}

        # 'all' group always exists
        self._groups["all"] = AnsibleGroupBuilder("all")

    def add_source(self, resource_type: AnsibleResourceType, resource: AnsibleResource):
        if resource_type == AnsibleResourceType.GROUP:
            name = resource.group_name
            builder = self._groups.get(name)
            if not builder:
                builder = AnsibleGroupBuilder(name)
                self._groups[name] = builder
        elif resource_type == AnsibleResourceType.HOST:
            name = resource.host_name
            builder = self._hosts.get(name)
            if not builder:
                builder = AnsibleHostBuilder(name)
                self._hosts[name] = builder
        builder.add_source(resource)

    def build(self, state_id: TerraformStateIdModel) -> AnsibleInventoryModel:
        return AnsibleInventoryModel(
            state_id=state_id,
            hosts=[i.build() for i in self._hosts.values()],
            groups=[i.build() for i in self._groups.values()],
        )


def _default_converter(x: Any) -> Any:
    return x


def state_get_path(
    obj,
    *args: Union[str, int],
    converter: Callable[[Any], Any] = _default_converter,
    default: Any = Raise,
) -> Any:
    for last, item in mark_last(args):
        obj = state_get_key(
            obj,
            item,
            converter=converter,
            default=default if last else Raise,
        )
    return obj


def state_get_key(
    obj,
    index: Union[int, str],
    converter: Callable[[Any], Any] = _default_converter,
    default: Any = Raise,
) -> Any:
    result = None
    try:
        result = obj[index]
        result = result if result or default is Raise else default
    except (IndexError, KeyError, AttributeError) as e:
        if default is Raise:
            raise AnsibleParserError(f"no key {index!r} in {obj!r}") from e
        result = default
    try:
        result = converter(result)
    except Exception as e:
        raise AnsibleParserError(f"unable to convert value {result!r}") from e
    return result


def mark_last(iterable) -> Iterator[Tuple[bool, Any]]:
    it = iter(iterable)
    try:
        prev = next(it)
    except StopIteration:
        return
    for cur in it:
        yield False, prev
        prev = cur
    yield True, prev
