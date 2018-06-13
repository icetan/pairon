# pairon

Editor agnostic realtime pair programing with git as backend (PoC)

## Setup

Dependencies:
- git
- ssh
- inotify-tools or fswatch

Copy source:

```sh
git clone https://github.com/icetan/pairon
```

`pairon` using Nix:

```sh
nix-env -i -f ./pairon
```

Without Nix on Debian or Ubuntu:

```sh
apt-get install git openssh inotify-tools
```

Or on Mac OS:

```sh
brew install git openssh fswatch
```

Add to ```PATH```:

```sh
export PATH=$PWD/pairon:$PATH
```

## Usage

Start a central pairon share by first creating a shared ssh user.

```sh
sudo useradd -m pairon
sudo -u pairon mkdir -p ~pairon/.ssh
sudo -u pairon tee -a ~pairon/.ssh/authorized_keys < ~/.ssh/id_rsa.pub
sudo chmod g+s ~pairon
sudo chmod -R 755 ~pairon
sudo chmod 600 ~pairon/.ssh/authorized_keys
```

Create a directory with files that you want to share.

```sh
mkdir my-share
cd my-share
echo Look at this file! > a-file
```

Start sharing your files.

```sh
pairon connect pairon@127.0.0.1:shared-repo
```

Then you can start editing files.

```sh
echo It is awesome >> a-file
```

To get the best experience in your editor enable auto-save and auto-reloading of
files. The faster to save/reload files the better.

Check out the ```editor-plugins``` directory for plugins/settings that match
your editor.
