chef-solo-workstation
=====================

A Chef-Solo package to wrap [workstation](https://github.com/julienlevasseur/chef-workstation) cookbook to manage your workstation.

# Table of Contents

**[Usage](#usage)**

* [run.sh](#run.sh)

* [solo.rb](#solo.rb)

* [attributes.json](#attributes.json)

**[About Vendoring](#about-vendoring)**

* [Berkshelf](#berkshelf)

**[Nodes](#nodes)**

**[Workstation Setup Examples](#workstation-setup-examples)**

* [Workstation](#workstation)

* [Sublime Text](#sublime-text)

* [Atom](#atom)

# Usage

## run.sh

The `run.sh` tool is here to help you with this chef-solo package.

`./run.sh --help` - Show help

`./run.sh --vendor` - Vendoring dependencies

> Vendoring is the moving of all 3rd party items such as plugins, gems and even rails into the /vendor directory. This is one method for ensuring that all files are deployed to the production server the same as the dev environment.
> With Berkshelf, the vendoring folder is `berks-cookbooks`.

`./run.sh --whyrun` - Execute chef-solo un whyrun mode (nothing will be updated)

`./run.sh --test` - Execute the [Inspec](https://www.inspec.io/) tests.

`./run.sh` - Execute a whyrun as first step, then, if the whyrun would have updated one resource or more, exeute the chef-solo convergence and finally run the Inspec tests.

## solo.rb

A solo.rb file is used to specify the configuration details for chef-solo.

* This file is loaded every time chef-solo is run
* The default location in which chef-solo expects to find this file is /etc/chef/solo.rb; use the --config option from the command line to change this location
* When a solo.rb file is present in this directory, the settings contained within that file will override the default configuration settings

## attributes.json

chef-solo does not interact with the Chef server. Consequently, node-specific attributes must be located in a JSON file on the target system, a remote location (such as Amazon Simple Storage Service (S3)), or a web server on the local network.

The JSON file must also specify the recipes that are part of the run-list.

# About Vendoring

Use berks vendor to vendor groups of cookbooks (as specified by group name) into a directory.

## Berkshelf

Berkshelf is a dependency manager for Chef cookbooks. With it, you can easily depend on community cookbooks and have them safely included in your workflow. You can also ensure that your CI systems reproducibly select the same cookbook versions, and can upload and bundle cookbook dependencies without needing a locally maintained copy. Berkshelf is included in the Chef Development Kit.

___
**Note**

`run.sh` tool include an auto vendoring if `berks-cookbooks` fodler doesn't exist :

```bash
test_vendoring() {
    if [ ! -d "./berks-cookbooks" ]
        then
        berks_vendor
    fi
}
```

Usefull for the first usage of this chef-solo cookbook.
___

# Nodes

Unlike chef-client, where the node object is stored on the Chef server, chef-solo stores its node objects as JSON files on local disk. By default, chef-solo stores these files in a nodes folder in the same directory as your cookbooks directory. You can control the location of this directory via the node_path value in your configuration file.

___
**Note**

Be carefull with the removing of resource instances as they can not be removed fom the node object.

For example, if you decide to uninstall a system package, you will uninstall it then remove it from `default['workstation']['packages']` :

before:
```json
    "workstation": {
        "packages": [
            "vim",
            "git",
            "meld"
```

after:
```json
    "workstation": {
        "packages": [
            "vim",
            "git"
```

But, it's still inside `normal['workstation']['packages']` :

```json
{
    "normal": {
        "workstation": {
            "packages": [
                "vim",
                "git",
                "meld"
            ]
        }
    }
}
```

To ensure that the next chef-solo run will not re-install it, be sure to remove it from nodes/`node.name`.json.


The proper approach is still to manage a package uninstallation in 3 steps :

1. Remove the package's reference from `attributes.json`.

2. Uninstall the package from a `workstation` cookbook's recipe:

    ```ruby
    package 'FOO' do
        action :remove
    end
    ```

3. Remove the package remove resource from the recipe.
___

# Workstation Setup Examples

This Chef-Solo package is intented to be used with [workstation](https://github.com/julienlevasseur/chef-workstation).

Edit `attributes.json` to customize your setup.

## Workstation

`['workstation']['users']`:

List of users to configure.

```json
"users": [
    {
        "name": "username",
        "home": "/home/username"
    }
],
```

`['workstation']['packages']`:

List of system packages to install.

```json
"packages": [
            "vim",
            "git",
            "meld",
            "evolution",
            "evolution-ews",
            "chromium-browser",
            "ruby-full",
            "gcc",
            "make"
]
```

`['workstation']['gems']`:

List of gems to install.

```json
"gems": [
        "bundler",
        "rake",
        "inspec",
        "ohai",
        "chef",
        "docker",
        "test-kitchen",
        "kitchen-docker",
        "kitchen-ansible"
]
```

`['workstation']['pip']`:

List of pip packages to install.

```json
"pip": {
    "ansible": "2.3.2.0",
    "pyOpenSSL": "17.5.0"
}
```

`['workstation']['hosts']`:

List of `/etc/hosts` entries.

```json
"hosts": [
        {"127.0.1.1": "My_Super_Workstation.local.net"},
        {"127.0.0.1": "consul"},
        {"127.0.0.1": "nomad"},
]
```

`['workstation']['ssh_config']`:

List of ssh configs.

```json
"ssh_config": [
                {
                    "name": "bastion",
                    "options": {
                        "HostName": "1.2.3.4",
                        "User": "remote_username",
                        "IdentityFile": "~/.ssh/ssh_key"
                    },
                    "user": "my_username"
                }
]
```

## Sublime Text

Add `sublime_text` cookbook's default recipe in your run_list :

```json
"run_list": [
    "recipe[workstation::default]",
    "recipe[sublime_text::default]"
]
```



And override the `sublime_text` attributes :

List the users for whom you want to configure Sublime Text:

```json
"sublime_text": {
    "users": [
        "username"
    ],
```

List the PackageControl's packages you want :

```json
    "packages": [
        {
            "name": "Jinja2",
            "url": "https://github.com/kudago/jinja2-tmbundle/archive/master.zip"
        },
        {
            "name": "SummitLinter",
            "url": "https://github.com/corvisa/SummitLinter/archive/master.zip"
        },
        {
            "name": "Pylinter",
            "url": "https://github.com/biermeester/Pylinter/archive/master.zip"
        },
        {
            "name": "SublimeLinter-contrib-ansible-lint",
            "url": "https://github.com/mliljedahl/SublimeLinter-contrib-ansible-lint/archive/master.zip"
        },
        {
            "name": "SublimeLinter-pylint",
            "url": "https://github.com/SublimeLinter/SublimeLinter-pylint/archive/master.zip"
        },
        {
            "name": "Terraform",
            "url": "https://github.com/alexlouden/Terraform.tmLanguage/archive/master.zip"
        }
    ],
```

And finally, set the syntax specific configs you want :

```json
    "syntax_specific": {
        "Python": {
            "tab_size": 4,
            "translate_tabs_to_spaces": true
        },
        "Ruby": {
            "tab_size": 2,
            "translate_tabs_to_spaces": true
        },
        "Ruby Haml": {
            "tab_size": 2,
            "translate_tabs_to_spaces": true
        }
    }
}
```

## Atom

Add `atom` cookbook's platform recipe in your run_list :

```json
"run_list": [
    "recipe[workstation::default]",
    "recipe[atom::debian]"
]
```

```json
"run_list": [
    "recipe[workstation::default]",
    "recipe[atom::macos]"
]
```

```json
"run_list": [
    "recipe[workstation::default]",
    "recipe[atom::windows]"
]
```
