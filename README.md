# Setup environment

Clone repository as bare repository

```
$ git clone --bare https://github.com/tomverelst/.dotfiles.git $HOME/.dotfiles
```

Alias dotfiles

```
$ alias dotfiles='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'
```

Checkout dotfiles

```
$ dotfiles checkout
```

Install on OSX

```
./.install/osx/install.sh
```

Install on Linux

```
./.install/linux/install.sh
```

Done!
