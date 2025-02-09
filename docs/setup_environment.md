# Setting up development environment

- [Setting up development environment](#setting-up-development-environment)
  - [Installing prerequisites](#installing-prerequisites)
  - [Installing the `cairo-lang` CLI](#installing-the-cairo-lang-cli)
    - [Step 1: Set up your virtual environment](#step-1-set-up-your-virtual-environment)
    - [Step 2: Install the necessary dependencies](#step-2-install-the-necessary-dependencies)
    - [Step 3: Install `cairo-lang` CLI](#step-3-install-cairo-lang-cli)
  - [Installing the `cairo` Cairo 1 compiler](#installing-the-cairo-cairo-1-compiler)
    - [Step1: Clone the cairo repository and set it up using the following instructions](#step1-clone-the-cairo-repository-and-set-it-up-using-the-following-instructions)
    - [Step 2: Add Cairo 1.0 executables to your path](#step-2-add-cairo-10-executables-to-your-path)
  - [Installing development tools](#installing-development-tools)
    - [Installing `scarb`](#installing-scarb)
    - [Installing `protostar`](#installing-protostar)
    - [Installing `starknet-devnet`](#installing-starknet-devnet)
  - [Configuring `VSCode` as an Editor](#configuring-vscode-as-an-editor)

This section will cover those steps:

- Installing prerequisites
- Installing the `cairo-lang` CLI
- Installing the `cairo` Cairo 1 compiler
- Installing development tools:`Scarb`, `protostar`and`starknet-devnet`
- Configuring `VSCode` as an Editor

## Installing prerequisites

In order to install and use `cairo` and `cairo-lang`, install the following:

- [Python 3.9+](https://www.python.org/downloads/release/python-390/)
- [Rust](https://www.rust-lang.org/tools/install)
- [NPM and Node 16+](https://www.npmjs.com/package/npm)

## Installing the `cairo-lang` CLI

### Step 1: Set up your virtual environment

We use `pyenv` manage python versions, which will compile python from source code. You need install python dependencies.

For Ubuntu:

```bash
sudo apt update
sudo apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev curl libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
```

For macOS:

If you haven't done so, install Xcode Command Line Tools (`xcode-select --install`) and [Homebrew](http://brew.sh/). Then:

```bash
brew install openssl readline sqlite3 xz zlib tcl-tk
```

Run the following commands for installing `pyenv` and configuring virtual environment:

```bash
# Install pyenv
curl https://pyenv.run | bash

# Add the following to your .bashrc or .zshrc
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

# Restart your terminal and run the following commands
pyenv install 3.9.0
pyenv virtualenv 3.9.0 cairo_venv
pyenv activate cairo_venv
```

**Either way, make sure the `cairo_venv` is activated – you should see (`cairo_venv`) in the command line prompt.**

### Step 2: Install the necessary dependencies

On Ubuntu, for example, you will have to first run:

```Bash
sudo apt install -y libgmp3-dev
```

On Mac, you can use brew:

```Bash
brew install gmp
```

Finally, install the following dependencies. **Note: you should install those in `cairo_venv`!**

```bash
pip install ecdsa fastecdsa sympy
```

There might be some other libraries which are not direct dependencies, but they might be indirect dependencies that you would need to install based on your operating system.

### Step 3: Install `cairo-lang` CLI

If you had `cairo-lang` installed previously, uninstall it and install the latest version.

```bash
# Uninstall the previous version
pip uninstall cairo-lang
# Install locally
pip install cairo-lang
```

Once you have installed the cairo lang package, make sure to test your installation by running the following command:

```
starknet --version
```

## Installing the `cairo` Cairo 1 compiler

### Step1: Clone the cairo repository and set it up using the following instructions

```shell
# Go to your $HOME directory
cd ~/
# Clone the `cairo` Cairo 1 compiler to a folder called .cairo in your home directory
git clone https://github.com/starkware-libs/cairo .cairo

# Checkout into the working branch and generate the release binaries
cd .cairo/
git checkout tags/v1.1.0
cargo build --all --release
```

**If you need upgrade, just run `git pull`, checkout to the newest tag, and rebuild the project.**

### Step 2: Add Cairo 1.0 executables to your path

Now that we have built the Cairo 1.0 binaries, we need to add them to the `PATH` environment variable. Add the following in your `.bashrc` or `.zshrc`:

```bash
# Add the below command to your .bashrc or .zshrc
export PATH="$HOME/.cairo/target/release:$PATH"
```

After that, open a new shell and check that the following command returns a version number:

```Bash
cairo-compile --version
```

## Installing development tools

### Installing `scarb`

[scarb](https://github.com/software-mansion/scarb/releases) is the Cairo package manager. It can manages your dependencies, compiles your projects and works as an extensible platform assisting in development.

**For now, scarb only support specify cairo1 version. If you upgrade cairo, you may should upgrade scarb as well.**

```shell
# Go to your $HOME directory
cd ~/
# Clone the `scarb` to a folder called .scarb in your home directory
git clone git@github.com:software-mansion/scarb.git .scarb

# Checkout into the working branch and generate the release binaries
cd .scarb/
git checkout tags/v0.3.0
cargo build --all --release

# Add the below command to your .bashrc or .zshrc
export PATH="$HOME/.scarb/target/release:$PATH"
```

**If you need upgrade, just run `git pull`, checkout to the newest tag, and rebuild the project.**

After that, open a new shell and check that the following command returns a version number:

```
scarb --version
```

### Installing `protostar`

>Since the development of Protostar is slow, the current version does not use Protostar, so you can temporarily **NOT** install it.

[protostar](https://docs.swmansion.com/protostar/) is a toolchain for developing Starknet smart contracts that helps with tasks such as dependencies management.

To installing `protostar` run the following command:

```
curl -L https://raw.githubusercontent.com/software-mansion/protostar/master/install.sh | bash
```

After that, open a new shell and check that the following command returns `cairo`, `cairo-lang` and `protostar` versions like this:

```bash
➜  ~ pyenv activate cairo_venv
(cairo_venv) ➜  ~ protostar -v
Protostar version: 0.13.0
Cairo-lang version: 0.11.2.1
Cairo 1 compiler version: 1.1.0
18:22:56 [INFO] Execution time: 1.25 s
```

To upgrade Protostar, run:

```
protostar upgrade
```

### Installing `starknet-devnet`

**You should execute follow command in previous `cairo_env` environment.**

```
pip install starknet-devnet
```

## Configuring `VSCode` as an Editor

Now, `cairo` just support `VSCode` as an Editor.

First, you should install Node.js 18 LTS:

```
sudo apt remove nodejs
sudo apt update
sudo apt install curl dirmngr apt-transport-https lsb-release ca-certificates vim
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install nodejs
```

Second, remember to rebuild the language server:

```
cargo build --bin cairo-language-server --release
```

Third, installing vscode-cairo support:

```shell
cd ~/.cairo/vscode-cairo
npm install --global @vscode/vsce
npm install
vsce package
code --install-extension cairo1*.vsix
```

Last, open `VSCode` after installation，and set `Language Server Path`, which should be`~/.cairo/target/release/cairo-language-server`.

<img src="https://raw.githubusercontent.com/zkcarter/picBed/main/markdown/extSettings.png" alt="image" style="zoom: 50%;" />