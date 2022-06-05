### Chaotic-AUR package list

This is the right place to submit package requests, bug reports or outdated packages of [Chaotic-AUR](https://aur.chaotic.cx). Please feel free to use issues! 📜

![Chaotic-AUR](https://avatars.githubusercontent.com/u/66071775?s=400&u=99bc0536e7e77fe3e58839996600848f2d930ed5&v=4)

### Examples of packages we already build:

- [Linux-tkg kernels](https://github.com/Frogging-Family/linux-tkg)
- Other popular kernel variations such as [Mainline](https://aur.archlinux.org/packages/linux-mainline)-{[Anbox}(https://aur.archlinux.org/packages/linux-mainline-anbox)}, [Xanmod-{tt,anbox,rt,lts,edge}](https://aur.archlinux.org/packages?O=0&SeB=nd&K=xanmod), [Vfio](https://aur.archlinux.org/packages/linux-vfio)-{[lts](https://aur.archlinux.org/packages/linux-vfio-lts)}, [Next-git](https://aur.archlinux.org/packages/linux-next-git), [BORE](https://aur.archlinux.org/packages/linux-bore) or [TT](https://aur.archlinux.org/packages/linux-tt)
- A quite complete [KDE stack build from master branch](https://invent.kde.org/explore/groups?sort=name_asc) 
- Most of the existing emulators & gaming utilities like [Yuzu](https://yuzu-emu.org/), [RPCS3](https://github.com/RPCS3/rpcs3) or {[Proton](https://github.com/GloriousEggroll/proton-ge-custom),[Wine](https://github.com/GloriousEggroll/wine-ge-custom)}-GE-Custom
- A lot of browsers like [Ungoogled Chromium](https://github.com/Eloston/ungoogled-chromium), [Firefox-wayland-hg](https://aur.archlinux.org/packages/firefox-wayland-hg), [Icecat](http://www.gnu.org/software/gnuzilla/) or the [Tor Browser](https://www.torproject.org/projects/torbrowser.html)
- .. a lot more. Check out the [package lists](https://github.com/chaotic-aur/packages/find/main) to find out what exactly gets build when! 🕵️‍♀️

#### Banished and rejected packages 📑

This is a list of packages which we will reject for good reasons:

- **snapd**: I didn't know how to help my users with it since it breaks *A LOT*. 	I recommend using native packages or [FlatPak](https://wiki.archlinux.org/title/Flatpak) instead. Also [there are a lot of other reasons to not use Snaps](https://old.reddit.com/r/linuxmemes/comments/ppyz0g/damn_you_ubuntu/hd7jg1p/).

- **lib32-x265**:	There is absolutely no use case in which a 32-bit application (Linux or Windows) would want to ENCODE HEVC. I recommend disabling x265 for the packages depending on it (usually `ffmpeg` or `gstreamer`).

- **gst-plugins-{ugly,bad} (and lib32)**: These need too frequent rebuilds which can't by dealt with as we don't control the packages pkgrel. Ultimately this would result in a bad user experience - dependency request however are welcome!

- **ffmpeg-{full,headless} (and lib32)**:  These need too frequent rebuilds which can't by dealt with as we don't control the packages pkgrel. Ultimately this would result in a bad user experience - dependency request however are welcome!

- **mpv-amd, ffmpeg-amd**: This is just MPV/FFMPEG without CUDA and NVENC to achieve shorter build times without actual end user benefit.

- **unreal-engine (and -git)**: Some mirrors don't have sufficient storage space.



#### Banned due to licensing issues 🛑

- **aseprite{-git}**: Redistribution is explicitly prohibited in its [FAQ](https://www.aseprite.org/faq/#can-i-redistribute-aseprite).

- **multimc-git**: This application is licensed under the Apache 2 license, which [prohibits distributing custom binaries](https://multimc.org/#Branding) as the one built by us.
