
# PacUI

PacUI provides useful and advanced Pacman and Yay/Pikaur/Aurman/Pakku/Trizen/Paru/Pacaur/Pamac-cli commands in a convenient and easy to use text interface.

PacUI is aimed at experienced/intermediate/advanced users of Arch Linux (and Arch-based distributions, including Manjaro), who have at least basic knowledge of their Linux system, Pacman and [Yay](https://github.com/Jguer/yay)/[Pikaur](https://github.com/actionless/pikaur)/[Aurman](https://github.com/polygamma/aurman)/[Pakku](https://github.com/kitsunyan/pakku)/[Trizen](https://github.com/trizen/trizen)/[Paru](https://github.com/Morganamilo/paru)/[Pacaur](https://github.com/rmarquis/pacaur)/[Pamac-cli](https://aur.archlinux.org/packages/pamac-cli/). Absolute beginners are probably overwhelmed by the choices PacUI offers.

This fork of an [older version of pacli](https://github.com/Manjaro-Pek/pacli/tree/f98e9226eb75ea00217481f436399328fe73d3ae) called PacUI follows the KISS principle: The whole script is contained within one file, which consists of easy to read bash code with many helpful comments. PacUI offers many more features over pacli in order to enhance comfort and speed of CLI based package management.


Table of Contents
-----------------

   * [Screenshots](#screenshots)
   * [Installation](#installation)
      * [Dependencies](#dependencies)
      * [Execute without prior Installation](#execute-without-prior-installation)
      * [Manual Installation](#manual-installation)
      * [Manjaro](#manjaro)
      * [Arch Linux](#arch-linux)
      * [chaotic-aur](#chaotic-aur)
   * [Usage](#usage)
      * [Start PacUI with UI](#start-pacui-with-ui)
      * [Start PacUI without UI: Using Options](#start-pacui-without-ui-using-options)
      * [Start PacUI without UI: Using Options and Package Names](#start-pacui-without-ui-using-options-and-package-names)
      * [Start PacUI without UI: Passing Arguments to AUR helper or Pacman](#start-pacui-without-ui-passing-arguments-to-aur-helper-or-pacman)
      * [Multiple installed AUR helpers](#multiple-installed-aur-helpers)
      * [Diff program](#diff-program)
   * [Useful Tips and Recommended Settings](#useful-tips-and-recommended-settings)
      * [Additional Pacman Settings](#additional-pacman-settings)
      * [Alias](#alias)
      * [Search syntax](#search-syntax)
   * [Help](#help)
      * [Short PacUI Help](#short-pacui-help)
      * [Detailed PacUI Help](#detailed-pacui-help)
      * [Manjaro Forum Threads](#manjaro-forum-threads)


## Screenshots

UI of PacUI:

![Screenshot 01](https://i.postimg.cc/RZPRTyz4/2020-06-07.png)


Installing the package "cantata" from system repositories by entering its name:

![Screenshot 02](https://s31.postimg.cc/7ltg222bf/2018.1.16.gif)


## Installation

### Dependencies
PacUI has the following hard dependency:
- sudo

If you want PacUI to fully work, these dependencies are needed as well:
- [expac](https://github.com/falconindy/expac)
- [fzf](https://github.com/junegunn/fzf)
- [pacman-contrib](https://www.archlinux.org/packages/community/x86_64/pacman-contrib/) (on Arch Linux)

By default, Pacman is used for package management. If you want to enable the use of the AUR, PacUI optionally requires at least one of these AUR helpers: 
- [Yay](https://github.com/Jguer/yay)
- [Pikaur](https://github.com/actionless/pikaur)
- [Aurman](https://github.com/polygamma/aurman)
- [Pakku](https://github.com/kitsunyan/pakku)
- [Trizen](https://github.com/trizen/trizen)
- [Paru](https://github.com/Morganamilo/paru)
- [Pacaur](https://github.com/rmarquis/pacaur)
- [Pamac-cli](https://aur.archlinux.org/packages/pamac-cli/)

PacUI supports even more features, if these packages are installed:
- pacman-mirrors (on Manjaro): PacUI uses "pacman-mirrors" to update your list of repository mirrors and automatically choose the fastest one for you. If this is not installed, "rankmirrors" (which is part of "pacman-contrib") gets used instead.
- [reflector](https://archlinux.org/packages/community/any/reflector/) (on Arch Linux): PacUI uses "reflector" to update your list of repository mirrors and automatically choose the fastest one for you. If this is not installed, "rankmirrors" (which is part of "pacman-contrib") gets used instead.
- [flatpak](https://archlinux.org/packages/extra/x86_64/flatpak/): PacUI uses "flatpak" to update and clean your installed flatpak packages.
- [snapd](https://aur.archlinux.org/packages/snapd): PacUI uses "snapd" to update and clean your installed snapd packages.
- [fwupd](https://archlinux.org/packages/community/x86_64/fwupd/): PacUI uses "fwupd" to install firmware updates for your system.
- [downgrade](https://aur.archlinux.org/packages/downgrade): PacUI activates a hidden "Downgrade Packages" option, which lets you use "downgrade" from within PacUI.

### Execute without prior Installation
If possible, read chapter [Dependencies](#dependencies) first and install any dependencies you need.
PacUI file can be downloaded and run without prior installation:
```
wget https://raw.githubusercontent.com/excalibur1234/pacui/master/pacui
```
```
bash pacui
```
I find this feature of PacUI invaluable for fixing systems. Here are two examples:

- A large number of updates broke (parts of) the GUI, e.g. xorg, window manager, or desktop environment. In this case, switching to a different tty (with CTRL + ALT + F2), installing PacUI and using "Roll Back System" to roll back all the latest updates can fix the system (temporarily).

- A broken keyring makes it impossible to apply updates or install any packages. Executing PacUI without prior installation and using "Fix Pacman Errors" (which does not require "expac", "fzf", or "pacman-contrib") to fix the keyring and all related problems is the easiest and fastest solution I know of.

### Manual Installation
Please read chapter [Dependencies](#dependencies) first and decide which packages to install to suit your needs.

PacUI can be manually installed (i.e. executing the same steps as described in the PKBUILD file) as follows:
1. Download 'pacui' file:
```
wget https://raw.githubusercontent.com/excalibur1234/pacui/master/pacui
```
2. Make 'pacui' file executable:
```
chmod +x pacui
```
3. Install 'pacui' file manually:
```
sudo cp pacui /usr/bin/
```

### Manjaro
In Manjaro, you can simply install the stable version of PacUI from the Manjaro repositories:
```
sudo pacman -S pacui
```
There is also an (often outdated) development version available:
```
sudo pacman -S pacui-git
```

### Arch Linux
PacUI is [no longer available on the AUR](https://github.com/excalibur1234/pacui/issues/45).
PKGBUILDs are still availble (see `PKGBUILD_AUR` file) and Pacui can be executed without installation or manually installed (see above).

### chaotic-aur
Both the stable and -git version of PacUI are in [chaotic-aur](https://lonewolf.pedrohlc.com/chaotic-aur/).  After adding chaotic-aur to your list of repositories, PacUI can be installed using the same commands as within Manjaro (see above).


## Usage

### Start PacUI with UI
After successful installation, type the following command into your terminal in order to start PacUI with a simple UI:
```
pacui
```

### Start PacUI without UI: Using Options
Using PacUI without its UI requires less keystrokes and can therefore be much quicker. An overview of all PacUI options is displayed with `pacui h`.

For example, you want to display the **R**everse dependency **T**ree of a package. Please note the marked letters "R" and "T" in PacUI's corresponding UI option.
PacUI does not care, whether you use upper or lower case letters as options or whether you use no, one or two dashes in front. Therefore, the following four commands are equivalent:
- `pacui RT`
- `pacui rt`
- `pacui -rt`
- `pacui --rt`

This principle can be used with all of PacUI's options. Here is another random example (of PacUI's hidden "List Packages by Size" option):
- `pacui LS`
- `pacui -LS`
- `pacui --LS`
- `pacui ls`
- `pacui -ls`
- `pacui --ls`

### Start PacUI without UI: Using Options and Package Names
You can also use package names in addition to options. For example, you want to install the package "cantata". Then, you can use a command like
```
pacui i cantata
```
Instead of a list of all available packages, a much shorter already filtered list is displayed. Simply select the "cantata" package you want to install and press ENTER in order to install it.

If an argument contains special characters, it has to be passed on as string. This can be achieved differently depending on the used shell. For example when using regular expressions in zsh in order to search package file names starting with string "archlinux-":
```
pacui s '^archlinux-'
```

### Start PacUI without UI: Passing Arguments to AUR helper or Pacman
For advanced use (e.g. in scripting or an alias), PacUI can have a "flag" argument, which gets passed directly to an AUR helper and/or Pacman.
Examples:
- ` pacui -r 0ad --flag="--noconfirm"`
- ` pacui u flag --noconfirm`
- ` pacui --FLAG --asdeps --i --bash`
- ` pacui b --flag=--noconfirm`


### Multiple installed AUR helpers
If more than one AUR helper is installed, they are automatically used in the same order as listed [above](#dependencies) (i.e. Yay is used with priority while Pamac-cli is only used as a last resort). A specific AUR helper can be set with the `PACUI_AUR_HELPER` environment variable.

Environment variables can typically be set by adding them to your /etc/environment file. If this file exists on your system, it can be selected using PacUI's "Edit Config Files" option:
```
pacui c
```

### Diff program
As described in [Detailed PacUI Help](#detailed-pacui-help), PacUI uses [pacdiff](https://wiki.archlinux.org/title/Pacman/Pacnew_and_Pacsave#pacdiff) for comparing .pac* files and a diff program specified by the `DIFFPROG` environment variable.

If the `DIFFPROG` environment variable is not set, PacUI uses its own diff program to (only!) show any differences in old and new .pac* files.

## Useful Tips and Recommended Settings

It is highly recommended to use an utility, which notifies the user about available updates alongside of PacUI. Such a lightweight utility is for example [update-notifier](https://github.com/Chrysostomus/update-notifier).

Along with PacUI the following settings are recommended by the author:

### Additional Pacman Settings
- An easy way to edit the /etc/pacman.conf file by using PacUI is:
```
pacui c
```
- A fancy list view for all Pacman updates can be enabled by uncommenting the following line:
```
#VerbosePkgLists
```
- Parallel Pacman downloads can be enabled by uncommenting the following line:
```
#ParallelDownloads = 3
```

### Alias
If you use PacUI without the UI it is recommended to use an alias for PacUI to reduce the amount of necessary typing. Do this by adding the following line to your ~/.bashrc file (if you use bash):
```
alias p='pacui'
```
This will set "p" as an alias to "pacui" within your terminal (after a restart of your shell or computer). For example, you can now update your system using
```
p u
```

### Search syntax
PacUI uses [fuzzy finder (fzf)](https://github.com/junegunn/fzf) to display lists of items (such as packages, package groups, logs, patchs, etc.) and by starting to type, you can easily search/filter those lists. Regular expressions can be used to improve the search results, e.g.:

| Search Term | Description                       |
| ----------- | --------------------------------- |
|  `"sbtrkt"`   | Items that match `sbtrkt`         |
|  `"^music"`   | Items that start with `music`     |
|  `"git$"`     | Items that end with `git`         |
|  `"'wild"`    | Items that include `wild`         |
|  `"!fire"`    | Items that do not include `fire`  |
|  `"!-git$"`   | Items that do not end with `-git` |

A single bar character term acts as an OR operator. For example, the following query matches entries that start with `core` or end with `go`, `rb`, or `py`.
```
"^core|go$|rb$|py$"
```


## Help

### Short PacUI Help
For short help, e.g. when using PacUI without UI, use one of the following commands:
- `pacui h`
- `pacui -h`

### Detailed PacUI Help
Choose the "Help" option within PacUI's UI by pressing "H" or "h". `pacui --help` from the terminal will call PacUI's detailed help page, too.

This help page explains some general stuff such as how to navigate PacUI. It also explains every PacUI option in detail. If you want to look up which commands PacUI uses under the hood and understand them in order to use PacUI correctly, this is the right place for you!

### Manjaro Forum Threads
 - [New Forum](https://forum.manjaro.org/t/pacui-bash-script-providing-advanced-pacman-and-yay-pikaur-aurman-pakku-trizen-pacaur-pamac-cli-functionality-in-a-simple-ui/561)
 - [Archived Forum - Read-Only Topic](https://archived.forum.manjaro.org/t/pacui-a-simple-bash-frontend-for-pacman-and-yaourt-pacaur/677)
 - [Classic Forum - Inactive Thread](https://classicforum.manjaro.org/index.php?topic=21399.0)
