---
sidebar_position: 1
---

# Nvim тохиргоо

dotfiles

This script will automatically setup your development environment.
How to run

  1  Make sure both of curl and git commands are installed.

  2  Just type following command:

  ```bash
sh -c "$(curl -L dot.soncho.net)"
```

## Start your site

fisher config server:

With Fisher

```bash
fisher install h-matsuo/fish-color-scheme-switcher
```

With Oh My Fish

```bash
  omf install https://github.com/h-matsuo/fish-color-scheme-switcher
  omf reload
```

Usage

scheme command is available after installation.

```bash
scheme
Usage:
   scheme list, ls
       List available color schemes.
   scheme preview [scheme-name]
       Preview the color scheme of scheme-name.
       If scheme-name is empty, preview the current scheme.
   scheme set scheme-name
       Set color scheme to scheme-name.
```

Tips
Comparing all available schemes

```bash
scheme ls | xargs -n1 -I {} fish -c 'scheme preview {} ; echo'
```

Open `docs/intro.md` (this page) and edit some lines: the site **reloads automatically** and displays your changes.
