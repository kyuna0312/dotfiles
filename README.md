# Maririn312 Dotfiles

![Maririn312](logo.png)

Full and clean configurations for development environment on GNU Linux, macOS
and Cygwin.

## Prerequisite

- GNU Linux, macOS, Windows, Cygwin
- Git, Zsh/Powershell, curl/wget
- Recommend: GNU Emacs, tmux
- Optional: Vim

## Quickstart

### Linux, macOS and Cygwin

``` shell
sh -c "$(curl -fsSL https://github.com/maririn312/dotfiles/raw/main/install.sh)"

```

or

``` shell
sh -c "$(wget https://github.com/maririn312/dotfiles/raw/main/install.sh -O -)"
```

or

``` shell
git clone https://github.com/maririn312/dotfiles.git ~/.dotfiles  # or download the zip package
cd ~/.dotfiles
./install.sh
```

### Windows (Powershell)

``` powershell
git clone [https://github.com/maririn312/dotfiles.git ](https://github.com/maririn312/dotfiles.git)~/.dotfiles  # or download the zip package
cd ~/.dotfiles
install_scoop.ps1  # or install_choco.ps1
```

## Docker

``` shell
cd ~/.dotfiles
docker build -t centaur/ubuntu .
docker run -it centaur/ubuntu zsh
```

## Shortcuts

- `Alt-c`: cd into the selected directory.
- `Ctrl-r`: Paste the selected command from history into the command line.
- `Ctrl-t`: Paste the selected file path(s) into the command line.
- `TAB`: To completions.

That's it. Enjoy!

## Customization

### ZSH ENV

Add your zsh environments in `~/.zshenv`. This is recommended by ZSH officially.
For example:

``` shell
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/.rbenv/shims:$PATH
export PYTHONPATH=/usr/local/lib/python2.7/site-packages
```

### ZSH local config

Ste your personal zsh configurations in `~/.zshrc.local`. For example:

``` shell
# Oh-my-zsh plugin
zinit snippet OMZP::golang
zinit snippet OMZP::python
zinit snippet OMZP::ruby

# Github plugin
zinit light ptavares/zsh-direnv
```

See details on [zinit](https://github.com/zdharma-continuum/zinit).

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

- vim (NeoVim) config
- tmux config
- git config
- fish config
- PowerShell config

## Desktop

### [yabai](https://github.com/koekeishiya/yabai)

- System Preferences > Desktop and Dock (**bold** is required):
  - **Mission Control: uncheck "Automatically rearrange Spaces based on most recent use"**
- _Some advanced features of `yabai` [requires SIP to be disabled](https://github.com/koekeishiya/yabai/wiki/Disabling-System-Integrity-Protection)._ _**However, disabling SIP will also disable Apple Pay on your Mac.**_ **For my setup, I left SIP enabled. My configs doesn't use any advanced feature from `yabai`**

### [sketchybar](https://github.com/FelixKratz/SketchyBar)

SketchyBar Features:
----------------------

* I am using the excellent [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font) to display the active applications in the spaces.

* Left clicking a space will focus it, right clicking a space will destroy that space; clicking in the separator (>) will create a new space (all using yabai SIP disabled; optional)

* Mousing over the music icon in the center gives a small Spotify player widget with player controls:
<img width="381" alt="spotify" src="https://user-images.githubusercontent.com/22680421/211197221-a3d6f8dd-4a72-4cc1-9224-78c1e7ebbb75.png">


* The volume icon on the right side can be clicked to toggle the volume slider and animates volume changes:

https://user-images.githubusercontent.com/22680421/211197240-632582a1-7f88-4cf2-bec7-88587112b996.mp4

* The volume icon on the right side can be right-clicked to show and select the audio output device:
![Screenshot 2022-12-11 at 12 46 48](https://user-images.githubusercontent.com/22680421/206901837-f4f8793e-ba0f-465b-b3a5-72d4fea17de4.png)

* The bell can be hovered to view github notifications

* Clicking the date/time toggles a "zen" mode, hiding all distracting items in the bar:
<img width="1512" alt="Screenshot 2022-11-11 at 18 01 32" src="https://user-images.githubusercontent.com/22680421/201391668-c4282435-9866-491d-a007-398942abdfb9.png">

* The battery indicator is only shown when below 60%:
<img width="552" alt="battery" src="https://user-images.githubusercontent.com/22680421/211197318-6b6b5164-3fa9-44a1-856b-391c3b233fe2.png">

SketchyBar Setup
----------------------
* Dependencies(`sf-symbols`, `jq`, `github-cli`, `switchaudio-osx`, [sketchybar-app-font](https://github.com/kvndrsslr/sketchybar-app-font)):
```bash
brew install --cask sf-symbols
brew install jq
brew install gh
brew install switchaudio-osx
curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v1.0.4/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
```
* (optional) `gh auth login` for GitHub notifications
* (optional) If you don't use yabai you can safely remove the `yabai` item from `items/yabai.sh` or `sketchybarrc`
* (optional; needed for yabai window state and running application icons) yabai events:
```bash
yabai -m signal --add event=window_focused action="sketchybar --trigger window_focus"
yabai -m signal --add event=window_created action="sketchybar --trigger windows_on_spaces"
yabai -m signal --add event=window_destroyed action="sketchybar --trigger windows_on_spaces"
```



### [skhd](https://github.com/koekeishiya/skhd)

- System Preferences > Keyboard > Keyboard Shortcuts... (**bold** is required):
  - For each of the item on the left side bar > click "Restore Defaults"
  - **Mission Control > Make sure everything under Mission Control is checked (Move left/right, switch to desktop 1/2/etc.)**

### [Alfred](https://www.alfredapp.com/)

- Theme: [Gruvbox Dark (Hard)](/manual-application/Alfred/Gruvbox%20Dark%20(Hard).alfredappearance)

## Terminal Emulator + Shell + Package Manager


### [Zsh](https://github.com/ohmyzsh/ohmyzsh/wiki/Installing-ZSH)

- Plugin manager: [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh#basic-installation)
- Plugins:
  - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions/blob/master/INSTALL.md#oh-my-zsh)
  - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting/blob/master/INSTALL.md#oh-my-zsh)
  - [Powerlevel10k](https://github.com/romkatv/powerlevel10k#oh-my-zsh)

### [Homebrew](https://brew.sh/)


## Git Manager

### [Lazygit](https://github.com/jesseduffield/lazygit#homebrew)

## File Manager

### [Ranger](https://github.com/ranger/ranger)

- Install from HEAD commit instead of pre-built binary: `brew install --HEAD ranger`
- File preview dependencies (**bold** is required):
  - **[ImageMagick](https://formulae.brew.sh/formula/imagemagick)**
  - **[librsvg (`rsvg-convert`)](https://formulae.brew.sh/formula/librsvg)**
  - **[djvulibre (`ddjvu`)](https://formulae.brew.sh/formula/djvulibre)**
  - **[ffmpeg](https://formulae.brew.sh/formula/ffmpeg)**
  - **[ffmpegthumbnailer](https://formulae.brew.sh/formula/ffmpegthumbnailer)**
  - **[poppler (`pdftoppm`)](https://formulae.brew.sh/formula/poppler)**
  - [fontforge (`fontimage`)](https://formulae.brew.sh/formula/fontforge)
  - [pandoc](https://formulae.brew.sh/formula/pandoc)
  - [mu](https://formulae.brew.sh/formula/mu)
  - [xlsx2csv](https://github.com/dilshod/xlsx2csv): `pip3 install xlsx2csv`
  - [exiftool](https://formulae.brew.sh/formula/exiftool)
  - [media-info (`mediainfo`)](https://formulae.brew.sh/formula/media-info)
  - [binutils (`readelf`)](https://formulae.brew.sh/formula/binutils)
  - [rar (`unrar`)](https://formulae.brew.sh/cask/rar)
  - [p7zip (`7z`)](https://formulae.brew.sh/formula/p7zip)
  - [odt2txt](https://formulae.brew.sh/formula/odt2txt)
  - [w3m](https://formulae.brew.sh/formula/w3m)
  - [jq](https://formulae.brew.sh/formula/jq)

### Finder.app

- `cmd` + `3` to View as Columns
- `cmd` + `shift` + `.` to Show Hidden files

## Web Browser

### [Firefox](https://www.mozilla.org/en-US/firefox/new/)

- [Firefox Onebar](https://codeberg.org/Freeplay/Firefox-Onebar) theme with the following `about:config`:
  - `onebar.disable-autohide-of-URLbar-icons : false`
  - `onebar.disable-centering-of-URLbar      : false`
  - `onebar.disable-https-truncate           : false`
  - `onebar.disable-single-tab               : true`
  - `onebar.hide-all-URLbar-icons            : true`
  - `onebar.hide-navigation-buttons          : false`
- Color and layout tweaks to [Browser XUL](/manual-application/Firefox/userChrome.css) and [`:about` pages](/manual-application/Firefox/userContent.css) to match Gruvbox Dark (Hard) color (Firefox Onebar included)
  - **Only Dark theme is supported, no light theme or high-contrast theme support**
- System Preferences > Desktop and Dock > Default web browser: Firefox

## Other tools

- [`btop`](https://github.com/aristocratos/btop#installation)
- `cat` > [`bat`](https://github.com/sharkdp/bat#on-macos-or-linux-via-homebrew)
- `find` > [`fd`](https://github.com/sharkdp/fd#on-macos)
- [`fzf`](https://github.com/junegunn/fzf#using-homebrew)
  - `fzf` `fd` integration in part of [shell config](/.zshrc)
- `grep` > [ripgrep (`rg`)](https://github.com/BurntSushi/ripgrep#installation)
- `ls` > [`eza`](https://github.com/eza-community/eza#brew-macos)
- [`neofetch`](https://github.com/dylanaraps/neofetch/wiki/Installation#macos-homebrew)
- [pipes-sh (`pipes.sh`)](https://formulae.brew.sh/formula/pipes-sh)
- `ps` > [`procs`](https://github.com/dalance/procs#homebrew)
- [Taskwarrior (`task`)](https://taskwarrior.org/download/#distributions)
  - [Timewarrior (`timew`)](https://timewarrior.net/docs/install/#distributions)
  - [`taskwarrior-tui`](https://kdheepak.com/taskwarrior-tui/installation/)
- [`tty-clock`](https://formulae.brew.sh/formula/tty-clock)
- [`unimatrix`](https://github.com/will8211/unimatrix): `pip3 install git+https://github.com/will8211/unimatrix.git`

## Neovim setup

Requires [Neovim](https://neovim.io/) (>= 0.8)

- [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim) - A plugin manager for Neovim
- [svrana/neosolarized.nvim](https://github.com/svrana/neosolarized.nvim) - A truecolor, solarized dark colorscheme
- [nvim-lualine/lualine.nvim](https://github.com/nvim-lualine/lualine.nvim) - A blazing fast and easy to configure Neovim statusline written in Lua
- [onsails/lspkind-nvim](https://github.com/onsails/lspkind-nvim) - VSCode-like pictograms
- [L3MON4D3/LuaSnip](https://github.com/L3MON4D3/LuaSnip) - Snippet Engine for Neovim written in Lua
- [hrsh7th/cmp-nvim-lsp](https://github.com/hrsh7th/cmp-nvim-lsp) - nvim-cmp source for neovim's built-in LSP
- [hrsh7th/cmp-buffer](https://github.com/hrsh7th/cmp-buffer) - nvim-cmp source for buffer words
- [hrsh7th/nvim-cmp](https://github.com/hrsh7th/nvim-cmp) - A completion engine plugin for neovim written in Lua
- [neovim/nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) - A collection of configurations for Neovim's built-in LSP
- [jose-elias-alvarez/null-ls.nvim](https://github.com/jose-elias-alvarez/null-ls.nvim) - Use Neovim as a language server to inject LSP diagnostics, code actions, and more via Lua.
- [williamboman/mason.nvim](https://github.com/williamboman/mason.nvim) - Portable package manager for Neovim that runs everywhere Neovim runs. Easily install and manage LSP servers, DAP servers, linters, and formatters
- [williamboman/mason-lspconfig.nvim](https://github.com/williamboman/mason-lspconfig.nvim) - Extension to mason.nvim that makes it easier to use lspconfig with mason.nvim
- [glepnir/lspsaga.nvim](https://github.com/glepnir/lspsaga.nvim) - A light-weight lsp plugin based on neovim's built-in lsp with a highly performant UI
- [nvim-treesitter/nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) - [Treesitter](https://github.com/tree-sitter/tree-sitter) configurations and abstraction layer for Neovim
- [kyazdani42/nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons) - Lua `fork` of vim-web-devicons for neovim
- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) - A highly extendable fuzzy finder over lists
- [nvim-telescope/telescope-file-browser.nvim](https://github.com/nvim-telescope/telescope-file-browser.nvim) - File Browser extension for telescope.nvim
- [windwp/nvim-autopairs](https://github.com/windwp/nvim-autopairs) - Autopairs
- [windwp/nvim-ts-autotag](https://github.com/windwp/nvim-ts-autotag) - Use treesitter to auto close and auto rename html tag
- [norcalli/nvim-colorizer.lua](https://github.com/norcalli/nvim-colorizer.lua) - A high-performance color highlighter
- [akinsho/nvim-bufferline.lua](https://github.com/akinsho/nvim-bufferline.lua) - A snazzy bufferline
- [lewis6991/gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) - Git integration for buffers
- [dinhhuy258/git.nvim](https://github.com/dinhhuy258/git.nvim) - A simple clone of the plugin vim-fugitive
- [folke/zen-mode.nvim](https://github.com/folke/zen-mode.nvim) - Distraction-free mode
- [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) - Markdown live preview

## Shell setup (macOS & Linux)

- [Fish shell](https://fishshell.com/)
- [Fisher](https://github.com/jorgebucaran/fisher) - Plugin manager
- [Tide](https://github.com/IlanCosman/tide) - Shell theme. Use version 5: `fisher install ilancosman/tide@v5`
- [Nerd fonts](https://github.com/ryanoasis/nerd-fonts) - Powerline-patched fonts. I use Hack.
- [z for fish](https://github.com/jethrokuan/z) - Directory jumping
- [Exa](https://the.exa.website/) - `ls` replacement
- [ghq](https://github.com/x-motemen/ghq) - Local Git repository organizer
- [fzf](https://github.com/PatrickF1/fzf.fish) - Interactive filtering

## PowerShell setup (Windows)

- [Scoop](https://scoop.sh/) - A command-line installer
- [Git for Windows](https://gitforwindows.org/)
- [Oh My Posh](https://ohmyposh.dev/) - Prompt theme engine
- [Terminal Icons](https://github.com/devblackops/Terminal-Icons) - Folder and file icons
- [PSReadLine](https://docs.microsoft.com/en-us/powershell/module/psreadline/) - Cmdlets for customizing the editing environment, used for autocompletion
- [z](https://www.powershellgallery.com/packages/z) - Directory jumper
- [PSFzf](https://github.com/kelleyma49/PSFzf) - Fuzzy finder


## Screenshots

### Main (with Tmux)

![main](https://user-images.githubusercontent.com/140797/51855591-9717c880-2368-11e9-9270-bbadc3640982.png
"Main with tmux")

### Git Log

![git_log](https://user-images.githubusercontent.com/140797/51830877-cf4ce600-232b-11e9-9196-c35a59ebe491.png
" Git Log")
