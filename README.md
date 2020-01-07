# packer-centos-pkd

Packer template for creating a Centos Based PDK development environment

## Box Contents

* Centos 7.7
* Epel Repo
* Puppet Development Kit
* Tmux
* Tree
* Emacs

## Usage

This image is meant to be used as the basis for a local development environment. 

```
$ cd ~/my-project
$ vagrant init jmangt/centos-pdk
$ vagrant up
$ vagrant ssh

vagrant$ pkd --help
```

I recommend that you install the following plugins before using the box:

* [VBguest](https://github.com/dotless-de/vagrant-vbguest)

## Development

For local development you can make use of the included `Makefile`

```
$ git clone https://github.com/jmangt/packer-centos-pkd.git
$ cd ~/packer-centos-pdk
$ make
```

### Change Log

#### 1.15.0

* Initial Release