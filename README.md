# Kyuna0312 DotConfig file


![Kyuna0312](logo.png)

Full and clean configurations for a development environment on GNU/Linux and macOS.

## Prerequisite

- GNU Linux and macOS
- Git, Zsh, curl/wget
- Recommend: Neovim, tmux

## Quickstart

### Linux and macOS

``` shell
sh -c "$(curl -fsSL https://github.com/kyuna0312/dotfiles/raw/main/install.sh)"

```

or

``` shell
sh -c "$(wget https://github.com/kyuna0312/dotfiles/raw/main/install.sh -O -)"
```

or

``` shell
git clone https://github.com/kyuna0312/dotfiles.git ~/.dotfiles  # or download the zip package
cd ~/.dotfiles
./install.sh
```

## Customization

### Zsh customization

If you run `./install.sh`, this repo will symlink `~/.zshrc`, `~/.bashrc`, Starship config, and tmux config.
For OS-specific behavior, check `shell/zsh/linux.zsh` and `shell/zsh/macos.zsh`.

### Git local config

Set your git configurations in `~/.gitconfig.local`, e.g. user credentials.

``` shell
[commit]
    # Sign commits using GPG.
    # https://help.github.com/articles/signing-commits-using-gpg/
    gpgsign = true

[user]
    name = John Doe
    email = john.doe@example.com
    signingkey = XXXXXXXX
```

## Contents

- zsh config (Starship prompt + modular OS layers)
- bash config
- nvim (NeoVim) config
- tmux config (TPM + plugins)
- starship prompt
- git config
- nushell config


## Shell setup (macOS & Linux)

- `zsh` (neon Lucy-inspired Starship prompt)
- `tmux` (TPM + cyberpunk UI, vim pane keys, session restore)
- fast nav: `fd` + `fzf`, `zoxide` (lazy-loaded)
- optional: `nushell` + `atuin` (history) if you use Nushell
