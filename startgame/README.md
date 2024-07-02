# startgame

CLI/Steam custom game launching helper

## Usage:

```sh
startgame ${options[@]} -- %command%
```

## Options:

- `--ao=alsa`
  Forces SDL_AUDIODRIVER to use ALSA

- `--ao=pulse`
  Forces SDL_AUDIODRIVER to use PulseAudio

- `--ao=pw`
  Forces SDL_AUDIODRIVER to use PipeWire

- `--dxr`
  Enable DXR in VKD3D

- `--fsr=[0-5]`
  Foces AMD's FidelityFX

- `--gamescope`
  Enable Gamescope

- `--gl=zink`
  Force Mesa's OpenGL/Gallium to Vulkan

- `--llvm`
  Disables ACO (for AMD GPU's only)

- `--log`
  Enable Proton, Wine and DXVK's logs

- `--log-mfplat`
  Enable Wine's mfplat logs

- `--log-all`
  Enable Wine's "+all" logs

- `--nocapture`
  Don't force VkCapture

- `--nodcc`
  RADV's nodcc (for AMD GPU's only)

- `--nomango`
  Disables MangoHud

- `--nox`
  Remove X11 and XWayland access (forces Wayland-only)

- `--nsdl{,=32,=64}`
  Force system's SDL libraries

- `--singlecore`
  Simulate singlecore CPU topology

- `--soldier`
  Enable Steam Soldier (see #notes)

- `--term`
  Opens a terminal instead of the game (exposes game command in `"$GAME_CMD"`)

- `--vk=amdpro`
  Forces VK ICD to amdpro (for AMD GPU's only)

- `--vk=amdvlk`
  Forces VK ICD to amdvlk (for AMD GPU's only)

- `--vk=radeon`
  Forces VK ICD to radeon (for AMD GPU's only)

- `--wayland`
  Don't force XWayland

## Requirements:

- ArchLinux

- `gamemode`, `lib32-gamemode`

- `mangohud`, `lib32-mangohud`

- `obs-vkcapture`

- `vulkan-amdgpu-pro`, `lib32-vulkan-amdgpu-pro` (optional)

- `amdvlk`, `lib32-amdvlk` (optional)

- `gamescope` (optional)

- `sdl2`, `lib32-sdl2` (optional)

- Wine with FSR pattches (optional)

## This script by default:

- Enables mangohud;

- Disables logs from Proton, Wine and DXVK;

- On Wayland, forces games to use XWayland (with `SDL_VIDEODRIVER` and `XDG_SESSION_TYPE`);

- If available, enables VkCapture;

- Skips Steam Soldier (needs manual action, see #notes);

- Logs stdout and stderr to `"/tmp/game-user-timestamp.log"`.

## Notes:

- Set `$GUITERM` to use `--term`;

- Gamescope parameters can be configured in `"~/.config/gamescope-flags.conf"`;

- For enabling/skipping Steam Solider with `--soldier`, you'll need this line prepended (after shebang) in `"~/.steam/steam/steamapps/common/SteamLinuxRuntime_soldier/_v2-entry-point"`:

```sh
if [[ -z "${STEAM_ENABLE_SOLDIER:-}" ]]; then shift 4; exec "${@}"; fi
```

- For changing default values, copy `"gamerc.example"` to `"~/.config/gamerc"`.

## Examples:

- Portal 2, native in Wayland: `startgame -w --nsdl %command% -novid -vulkan`

- Left 4 Dead 2, native in Wayland: `startgame -w --nsdl=32 %command% -novid -vulkan`

- Terraria, native in Wayland, and using PipeWire: `startgame --ao=pw -w --nsdl %command%`
