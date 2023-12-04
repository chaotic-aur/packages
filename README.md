### Chaotic-AUR package list

This is the right place to submit package requests, bug reports, or outdated packages of [Chaotic-AUR](https://aur.chaotic.cx). Please feel free to use issues! 📜

![Chaotic-AUR](https://avatars.githubusercontent.com/u/66071775?s=400&u=99bc0536e7e77fe3e58839996600848f2d930ed5&v=4)

#### Some packages we have already built

- [Linux-tkg kernels](https://github.com/Frogging-Family/linux-tkg) (BMQ, CFS,LTO, PDS, TT + their generic_v3 variations)
- Other popular kernel variations such as [Mainline](https://aur.archlinux.org/packages/linux-mainline)/, [Xanmod-{tt,rt,lts}](https://aur.archlinux.org/packages?O=0&SeB=nd&K=xanmod), [Vfio](https://aur.archlinux.org/packages/linux-vfio)/-[lts](https://aur.archlinux.org/packages/linux-vfio-lts), [Next-git](https://aur.archlinux.org/packages/linux-next-git), [Cachyos-BORE](https://aur.archlinux.org/packages/linux-cachyos-bore) or [TT](https://aur.archlinux.org/packages/linux-tt)
- A quite complete [KDE stack](https://invent.kde.org/explore/groups?sort=name_asc) in a [separate repo](https://forum.garudalinux.org/t/kde-6-repository-testing/31442). 
- Most of the existing emulators & gaming utilities like [Yuzu](https://yuzu-emu.org/), [RPCS3](https://github.com/RPCS3/rpcs3), and {[Proton](https://github.com/GloriousEggroll/proton-ge-custom),[Wine](https://github.com/GloriousEggroll/wine-ge-custom)}-GE-Custom
- A lot of browsers like [Firedragon](https://github.com/dr460nf1r3/firedragon-browser), [Ungoogled Chromium](https://github.com/Eloston/ungoogled-chromium), [Firefox-wayland-hg](https://aur.archlinux.org/packages/firefox-wayland-hg), , and [Icecat](http://www.gnu.org/software/gnuzilla/)
- ... a lot more. Check out the [package lists](https://github.com/chaotic-aur/packages/find/main) to find out what exactly gets built and when! 🕵️‍♀️

#### Modified packages

While we would prefer to build AUR packages without modification, doing so is often not practical or possible.

- Depends, options, or commands may be missing.
- Erroneous options or commands may be present.
- Packages may not build or function without changes.
- Packages may not meet packaging standards.

To address such issues:

- [Toolbox](https://github.com/chaotic-aur/toolbox) automatically corrects some common errors.
- Manual corrections may be applied with [Interfere](https://github.com/chaotic-aur/interfere).
- The original package may be forked as a custom package.

#### Special packages

- `chaotic-keyring`: Public keys to verify the Chaotic-AUR package signatures.
- `chaotic-mirrorlist`: List of servers mirroring Chaotic-AUR packages.
- `chaotic-interfere`: Marker indicating manually applied interferes.  This package is *not* intended to be installed.
- `chaotic-kf5-dummy`: Workaround to allow packages with outdated KF5-related depends to continue to function.  Eventually this, and related packages that haven't been updated, will be dropped.  Planned for when KF6 becomes the upstream default.

#### Banished and rejected packages 📑

This is a list of packages that we will reject for good reasons:

- **snapd**: We didn't know how to help our users with it since it breaks *A LOT*. We recommend using native packages or [FlatPak](https://wiki.archlinux.org/title/Flatpak) instead. Also, [there are a lot of other reasons to not use Snaps](https://old.reddit.com/r/linuxmemes/comments/ppyz0g/damn_you_ubuntu/hd7jg1p/).

- **lib32-\***: The difficulty of maintaining 32-bit packages is increasing as their usefulness decreases.  They may be considered to keep existing packages working, like `wine-*`.  Otherwise, use 64-bit packages when available.

- **gst-plugins-{ugly,bad}**: These need too frequent rebuilds which can't be dealt with as we don't control the packages pkgrel. Ultimately this would result in a bad user experience - dependency requests however are welcome!

- **ffmpeg-{full,headless}**:  These need too frequent rebuilds which can't be dealt with as we don't control the packages pkgrel. Ultimately this would result in a bad user experience - dependency requests however are welcome!

- **mpv-amd, ffmpeg-amd**: This is just MPV/FFMPEG without CUDA and NVENC to achieve shorter build times without actual end-user benefit.

- **unreal-engine (and -git)**: Some mirrors don't have sufficient storage space.

- **python2**: Has been EOL for a couple of years, and was [removed from Arch repositories](https://archlinux.org/news/removing-python2-from-the-repositories/). Requests for packages that depend on it in any way will be rejected (see [#1958](https://github.com/chaotic-aur/packages/issues/1958)).

- **linux-ck**: Two reasons, first our `linux-tkg-*` already includes those bits of optimizations, second there is [repo-ck](https://wiki.archlinux.org/title/Unofficial_user_repositories#repo-ck) with official pre-built binaries for it.

- Dependencies without any dependents: Such packages are useless by themselves.  Maintaining them wastes effort that is better spent elsewhere.

#### Banned due to licensing issues 🛑

- **aseprite{-git}**: Redistribution is explicitly prohibited in its [FAQ](https://www.aseprite.org/faq/#can-i-redistribute-aseprite).

- **multimc\***: Redistribution of custom binaries that include their API keys and trademarked assets is [explicitly prohibited](https://multimc.org/#Branding).

- **tlauncher**: Legal gray area, as it potentially allows playing Minecraft in a reduced capacity without license.

- **feishu**: Unauthorized redistribution of their applications is explicitly prohibited per [ToS](https://www.feishu.cn/en/terms).

- **rider**: Redistribution disallowed per [ToS](https://www.jetbrains.com/legal/docs/toolbox/user).
