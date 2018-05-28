# pairon

Editor agnostic realtime pair programing with git as backend (PoC)

## Setup

Copy source and add to ```PATH```.

```sh
git clone https://github.com/icetan/pairon
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
pairon sync
```

Each time you do ```pairon sync``` your changes will be pushed out to the
connected repo.

Check out the ```editor-plugins``` directory for the best experience with your
editor.