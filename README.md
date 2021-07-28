# Chaotic-AUR's packages

Here it is the place to submit requests related to packages for Chaotic-AUR.

Please, use issues!

There are a few kind of requests which we will deny:

# Banished and rejected packages:

- snapd:
	I didn't knew how to help my users with it, it breaks A LOT.
	I recommend you using native packages or FlatPak instead.

- lib32-x265:
	There is no use-case in this face of the world where a 32-bit application (Linux or Windows) will want to ENCODE HEVC.
	I recommend you disabling x265 in the packages that depends on it (usually ffmpeg or gstreamer).

- gst-plugins-{ugly,bad} (and lib32):
	Needs rebuilds too frequently, we don't control the pkgrel, so it would break user experience.
	(Dependencies requests are welcomed)

- ffmpeg-{full,headless} (and lib32):
	Needs rebuilds too frequently, we don't control the pkgrel, so it would break user experience.
	(Dependencies requests are welcomed)

- mpv-amd, ffmpeg-amd:
	That's just MPV/FFMPEG without CUDA and NVENC for reducing building time, no gain for our end users.

- unreal-engine (and -git):
	Not enougth spaces in some of our mirrors.

