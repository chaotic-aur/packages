# Chaotic-AUR PKGBUILDs

This is the right place to submit package requests, bug reports, or outdated packages
of [Chaotic-AUR](https://aur.chaotic.cx) 📜

⚠️ We switched to our entirely [new infra 4.0 on October 18](https://gitlab.com/chaotic-aur/pkgbuilds), which means we
now operate on GitLab CI!
While we still accept issues and bug reports on our previous `packages` repo, on GitHub,
all the pipelines, updates and insights in general ongoings will majorly be happening on the other side.
Still, the old repo will be kept around as a push-only mirror.

![Chaotic-AUR](https://avatars.githubusercontent.com/u/66071775?s=400&u=99bc0536e7e77fe3e58839996600848f2d930ed5&v=4)

## Some packages we have already built

- Variations of the Linux kernel such as
  - [Cachyos](https://aur.archlinux.org/packages/linux-cachyos) / [Cachyos-BORE](https://aur.archlinux.org/packages/linux-cachyos-bore),
  - [Clear](https://aur.archlinux.org/packages/linux-clear),
  - [Nitrous](https://aur.archlinux.org/packages/linux-nitrous),
  - [VFIO](https://aur.archlinux.org/packages/linux-vfio),
  - [XanMod](https://aur.archlinux.org/packages/linux-xanmod) / [XanMod-RT](https://aur.archlinux.org/packages/linux-xanmod-rt) / [XanMod-LTS](https://aur.archlinux.org/packages/linux-xanmod-lts),
  - [Mainline](https://aur.archlinux.org/packages/linux-mainline),
  - [LQX](https://aur.archlinux.org/packages/linux-lqx)
  - and a few architecture-specific variants of the previously mentioned kernels
- Emulators and gaming utilities
- A lot of browsers like
  [Firedragon](https://github.com/dr460nf1r3/firedragon-browser),
  [Firefox-wayland-hg](https://aur.archlinux.org/packages/firefox-wayland-hg),
  [Floorp](https://floorp.app/),
  [Icecat](http://www.gnu.org/software/gnuzilla/),
  and [Ungoogled Chromium](https://github.com/Eloston/ungoogled-chromium)
- ... a lot more ...

Every folder in this repository will be built by our build system,
for information about currently queued up packages and build logs
check out our [build status page](https://aur.chaotic.cx/status)!
🕵️‍♀️

A complete list of packages with their current versions is additionally
available [here](https://aur.chaotic.cx/packages).

## Modified packages

While we would prefer to build AUR packages without modification, doing so is often not practical or possible.

- Depends, options or commands may be missing.
- Erroneous options or commands may be present.
- Packages may not build or function without changes.
- Packages may not meet packaging standards.

To address such issues:

- The build system automatically corrects some common errors.
- Manual corrections may be applied with an interfere
- The original package may be forked as a custom package.

## Special packages

- `chaotic-keyring`: Public keys to verify the Chaotic-AUR package signatures.
- `chaotic-mirrorlist`: List of servers mirroring Chaotic-AUR packages.
- `chaotic-interfere`: Marker indicating manually applied interferes. This package is _not_ intended to be installed.

## Banished and rejected packages 📑

This is a list of packages that we will reject for good reasons:

- **snapd**: We didn't know how to help our users with it since it breaks _A LOT_. We recommend using native packages
  or [FlatPak](https://wiki.archlinux.org/title/Flatpak) instead.
  Also, [there are a lot of other reasons to not use Snaps](https://old.reddit.com/r/linuxmemes/comments/ppyz0g/damn_you_ubuntu/hd7jg1p/).

- **lib32-\***: The difficulty of maintaining 32-bit packages is increasing as their usefulness decreases. They may be
  considered to keep existing packages working, like `wine-*`. Otherwise, use 64-bit packages when available.

- **gst-plugins-{ugly,bad}**: These need to be rebuilt too frequently, which can't be dealt with as we don't control the
  packages pkgrel. Ultimately this would result in a bad user experience.

- **ffmpeg-headless**: Needs to be rebuilt too frequently, which can't be dealt with as we don't
  control the packages pkgrel. Ultimately this would result in a bad user experience.

- **mpv-amd, ffmpeg-amd**: This is just MPV/FFMPEG without CUDA and NVENC to achieve shorter build times without actual
  end-user benefit.

- **unreal-engine (and -git)**: Some mirrors don't have sufficient storage space.

- **python2**: Has been EOL for years and
  was [removed from Arch repositories](https://archlinux.org/news/removing-python2-from-the-repositories/).

- **linux-ck**: Other kernels contain the same optimizations, and official pre-built binaries are available
  from [repo-ck](https://wiki.archlinux.org/title/Unofficial_user_repositories#repo-ck).

- Packages that use EOL, non-standard, or modified versions of Electron. Packages that use Electron as a web browser.

- Dependencies without any dependents: Such packages are useless by themselves. Maintaining them wastes effort that is
  better spent elsewhere.

## Banned due to licensing issues 🛑

- **AMDGPU PRO** Drivers. Redistribution of both software and documentation is prohibited.

- **aseprite{-git}**: Redistribution is explicitly prohibited in
  its [FAQ](https://www.aseprite.org/faq/#can-i-redistribute-aseprite).

- **feishu**: Unauthorized redistribution of their applications is explicitly prohibited
  per [ToS](https://www.feishu.cn/en/terms).

- **multimc\***: Redistribution of custom binaries that include their API keys and trademarked assets
  is [explicitly prohibited](https://multimc.org/#Branding).

- **rider**: Redistribution disallowed per [ToS](https://www.jetbrains.com/legal/docs/toolbox/user).

- **tlauncher**: Legal gray area, as it potentially allows playing Minecraft in a reduced capacity without a license.

## Build system details

Our previous build tools, the so-called [toolbox](https://github.com/chaotic-aur/toolbox) was initially created by
@pedrohlc to deal with one issue: having a lot of packages to compile while not having many maintainers for all the
packages.
Additionally, Chaotic-AUR has quite inhomogeneous builders: servers, personal devices, and one HPC which all need to be
integrated somehow.
The toolbox had a nice approach to this - keeping things as KISS as possible and using Git to distribute package builds
between builders. These would then grab builds according to their activated routines. While this works fairly well, it
had a few problems which we tried to get rid of in the new version.
A few key ideas about this new setup:

- Since we like working with CI a lot besides it providing great enhancement for automating boring tasks as well as
  making the whole process more transparent to the public as well, it was clear CI should be a major part of it.
- The system should have a scheduler that distributes build tasks to nodes, which prevents useless build routines and
  enables nodes to grab jobs whenever they are queued.
- The tools should be available as Docker containers to make them easy to use on other systems than Arch.
- All logic besides the scheduler (which is written in TypeScript using BullMQ) should be written in Bash

## How it works

The new system consists of three integral parts:

- The CI (which can be both GitLab CI and GitHub Actions!) handles PKGBUILDs, their changes, and figuring out what to
  build, utilizing a Chaotic Manager container to schedule packages via the central Redis instance.
- The central Redis instance storing information about currently scheduled builds.
- The [Chaotic Manager](https://gitlab.com/garuda-linux/tools/chaotic-manager) which is used to add new builds to the
  queue and execute them via the main manager container. All containers have SSH-tunneled access to the Redis instance,
  enabling the build containers to grab new builds whenever they enter the queue.

Compared to Infra 3.0, this means we have the following key differences:

- We no longer have package lists but a repository full of PKGBUILD folders. These PKGBUILDs are getting pulled either
  from AUR once a package has been updated or updated manually in case a Git repository and its tags serve as a source.
- No more dedicated builders (might change in the future, e.g. for heavy builds?) but a common build queue.
- Routines are no longer necessary - CI determines and adds packages to the schedule as needed. The only "routine-like"
  thing we have is the CI schedule, executing tasks like PKGBUILD or version updates.
- The actual logic behind the build process (like `interfere.sh` or database management) was moved to
  the [builder container of Chaotic Manager](https://gitlab.com/garuda-linux/tools/chaotic-manager/-/tree/main/builder-container?ref_type=heads) -
  this one updates daily/on-commit and gets pulled regularly by the Manager instance.
- Live-updating build logs will be available via CI - multiple revisions instead of only the latest.
- The interfere repo is no longer needed, instead, package builds can be configured via the `.CI` folder in their
  respective PKGBUILD folders. All known interfere types can be put here (e.g. `PKGBUILD.append` or `prepare.sh`),
  keeping existing interferes working.
- The CI's behavior concerning each package can be configured via a `config` file in the `.CI` folder: this file stores
  information like PKGBUILD source (it can be AUR or something different), PKGBUILD timestamp on AUR, most recent Git
  commit as well as settings like whether to push a PKGBUILD change back to AUR.
- PKGBUILD changes can now be reviewed in case of major (all changes other than pkgver, hashes, pkgrel) updates - CI
  automatically creates a PR containing the changes for human review.
- Adding and removing packages is entirely controlled via Git - after adding a new PKGBUILD folder via commit, the
  corresponding package will automatically be deployed. Removing it has the opposite effect.

The following will contain information to understand how it all works together, the full build system API documentation
can be found [here](https://chaotic-manager.pages.dev/).

## Workflows and information

### Adding packages

Adding packages is as easy as creating a new folder named after the `$pkgbase` of the package. Put the PKGBUILD and all
other required files in here.
Adding AUR packages is therefore as simple as cloning its repo and removing the `.git` folder.
CI relies on `.SRCINFO` files to parse most information, therefore, it is important to have them in place and up-to-date
in case of self-managed packages.
Finally, add a `.CI` folder containing the basic config (`CI_PKGBUILD_SOURCE` is required in case its external package,
self-managed PKBUILDs don't need it), commit any changes, and push the changes back to the main branch.
Please follow the [conventional commit convention](https://www.conventionalcommits.org/en/v1.0.0/) while doing
so ([cz-cli](https://github.com/commitizen/cz-cli) can help with that!). This means commits like:

- `feat($pkgname): init`
- `fix($pkgname): fix xyz`
- `chore($pkgname): update PKGBUILD`
- `ci(config): update`

This not only helps with having a uniform commit history, it also allows automatic changelog generation.

### Removing packages

This can be done by removing the folder containing a package's PKGBUILD. A cleanup job will then automatically remove
any obsolete package via the `on-commit` pipeline run. This will also consider any split packages that a package might
produce.
Renaming folders does also count as removing packages.

### On-commit pipeline

Whenever pushing a new commit, the CI pipeline will carry out the following actions:

- Checking when the last `scheduled` tag was created. This is used to determine which packages need to be scheduled.
- It parses each commit for a `[deploy $foldername]` string, only accepting valid values derived from the existing
  PKGBUILD folders. `[deploy all]` is a valid parameter as well. Misspelling `$pkgname` is a fatal error here. Any
  issues must be fixed and force-pushed.
- Then, the changed files are parsed. This also includes removed packages. Any changed relevant folder content will
  cause a package deployment of the corresponding package.
- The final action is to build the schedule parameters (handing it over to the scheduled job via artifacts) and remove
  all obsolete packages in case an earlier step is detected.
- In case all of these actions succeed, the `scheduled` tag gets updated, so we can refer to it on a later pipeline run.

### On-schedule pipelines

#### Hourly

Every hour, the on-schedule pipeline will carry out a few tasks:

- Updating the CI template from the template repository (in case this is enabled via `.ci/config`)
- Check if the scheduled tag does not exist or scheduled does not point to HEAD (in this case abort mission!)
- Check whether the .state worktree containing the state of the packages exists, if it does, it sets it up. Otherwise,
  it re-creates it from scratch (e.g., on force push)
- Check whether the last commit is automated (containing "chore(packages): update packages [skip ci]"), if yes, the
  commit resulting from the schedule will overwrite it to keep the commit history clean.
- Collect AUR timestamps of packages to determine whether a PKGBUILD changed
- Loop through each valid package and carry out the following actions:
  - Read the `.CI/config` file to gain information about the package configuration (e.g., whether to manage the AUR
    repository, the source of the PKGBUILD, etc.)
  - Update PKGBUILD in the following cases:
    - CI_PKGBUILD_SOURCE is set to `gitlab`: Updates the PKGBUILD from the GitLab repository tags
    - CI_PKGBUILD_SOURCE is set to `aur`: Updates the PKGBUILD from the AUR repository, pulling in the git repo and
      replacing the existing files with the new ones.
      If the AUR timestamp could not be collected earlier, the package update gets skipped.
    - CI_PKGBUILD_SOURCE is not set to `gitlab` or `aur`:
      tries to update the PKGBUILD by pulling the repository specified in CI_PKGBUILD_SOURCE.
      In case cloning was not successful after 2 tries, the update process gets skipped.
  - In case CI_GIT_COMMIT is set in the packages configuration variables, the latest commit of the git URL set in
    the `source` section of the PKGBUILD is
    updated. If it differs, schedule a build.
  - In case a custom hook exists (`.CI/update.sh` inside the package directory), it gets executed - this can be used for
    updating PKGBUILDs with a custom script.
  - Writing needed variables back to `.CI/config` (eg. Git hash)
- Either update the PKGBUILD silently in case of minor changes, create a PR for review in case of major updates (and
  only if `CI_HUMAN_REVIEW` is true)
  - Updates are only considered if diff actually reports changes between current PKGBUILD folder and AUR PKGBUILD repo
  - Any change made to the source files is detected, this however does _not_ detect malicious changes in the upstream
    project source that the package builds
- The state worktree gets updated with new information
- Schedule parameters are getting built and handed over to the scheduled job via artifact
- Obsolete branches (eg. merged review PRs) are getting pruned
- The scheduled tag gets updated again

#### Daily

A daily pipeline schedule has been added for specific packages which generate their `pkgver` dynamically.
To make use of it, set `CI_ON_TRIGGER=daily` inside the `.CI/config` file of the package.

### Manual scheduling

#### Scheduling packages without git commits

Packages can be added to the schedule manually by going to
the [pipeline runs](https://gitlab.com/chaotic-aur/pkgbuilds/-/pipelines) page, selecting "Run pipeline" and
adding `PACKAGES` as a variable with the package names as its value. The pipeline will then pick up the packages and
schedule them.
`PACKAGES` can also be set to `all` to schedule all packages. In case one or many packages are getting scheduled, it
needs to follow the format `pkgname1:pkgname2:pkgname3`.

##### Running scheduled pipelines on-demand

This can be done by going to the [pipeline runs](https://gitlab.com/chaotic-aur/pkgbuilds/-/pipeline_schedules) page,
selecting "Run pipeline" (the play symbol). A link to the pipeline page will be provided, where the pipeline logs can be
obtained.

### Adding interfere

Put the required interfere file in the `.CI` folder of a PKGBUILD folder:

- `prepare`: A script that is being executed after the building chroot has been set up. It can be used to source
  environment variables or modify other things before compilation starts.
  - If something needs to be set up before the actual compilation process, commands can be pushed by inserting
    eg. `$CAUR_PUSH 'source /etc/profile'`. Likewise, package conflicts can be solved, eg. as
    follows: `$CAUR_PUSH 'yes | pacman -S nftables'` (single quotes are important because we want the variables/pipes to
    evaluate in the guest's runtime and not while interfering)
- `interfere.patch`: a patch file that can be used to fix either multiple files or PKGBUILD if a lot of changes are
  required. All changes need to be added to this file.
- `PKGBUILD.prepend`: contents of this file are added to the beginning of PKGBUILD.
- `PKGBUILD.append`: contents of this file are added to the end of PKGBUILD. Fixing `build()` as is easy as adding the
  fixed `build()` into this file. This can be used for all kinds of fixes. If something needs to be added to an array,
  this is as easy as `makedepend+=(somepackage)`.
- `on-failure.sh`: A script that is being executed if the build fails.
- `on-success.sh`: A script that is being executed if the build succeeds.

### Bumping pkgrel

This is now carried out by adding the required variable `CI_PACKAGE_BUMP` to `.CI/config`. See below for more
information.

### Dependency trees

The CI builds dependency trees automatically. They are passed to the Chaotic manager as a CI artifact and read whenever
a schedule command is being executed.
No manual intervention is needed.

### .CI/config

The `.CI/config` file inside each package directory contains additional flags to control the pipelines and build
processes with.

- `CI_MANAGE_AUR`: By setting this variable to `true`, the CI will update the corresponding AUR repository at the end of
  a
  pipeline run if changes occur (omitting CI-related files)
- `CI_PACKAGE_BUMP`: Controls package bumps for all packages which don't have `CI_MANAGE_AUR` set to `true`. The format
  this needs
  to follow is either `1:1.2.3-1/1` (full current version and bump count after the slash) or `1.2.3` (full current
  package version,
  resolves to bump count `1`).
- `CI_PKGBUILD_SOURCE`: Sets the source for all PKGBUILD-related files, used for pulling updated files from remote
  repositories.
  Valid values as of now are:
  - `gitlab`: Pulls the PKGBUILD from the GitLab repository tags. It needs to follow the format `gitlab:$PROJECT_ID`.
    The ID can be obtained by browsing the repository settings general section.
  - `aur`: Pulls the PKGBUILD from the AUR repository, pulling in the git repo and replacing the existing files with the
    new ones.
- `CI_ON_TRIGGER`: Can be provided in case a special schedule trigger should schedule the corresponding package. This
  can be used to schedule packages daily, by setting the value to `daily`.
  Since this checks whether "$TRIGGER == $CI_ON_TRIGGER", any custom schedule can be created using pipeline schedules
  and setting `TRIGGER` to `midnight`, adding a fitting schedule and setting `CI_ON_TRIGGER` for any affected package
  to `midnight`.
  Packages having this variable set will **not** be scheduled via the regular on-schedule pipeline, hence this one can
  also be used to prevent wasting builder resources, e.g. useful for huge `-git` packages with a lot of commit activity,
  like `llvm-git`.
- `CI_REBUILD_TRIGGERS`: Add packages known to be causing rebuilds to this variable. A list of repositories to track
  package versions for is provided via the repositories' `CI_LIB_DB` parameter. Each package version is hashed and
  dumped to `.ci/lib.state`. Each scheduled pipeline run compares versions by checking hash mismatches and will bump
  each affected package via `CI_PACKAGE_BUMP`. It needs to follow the format `package1:package2:package3`.
- `BUILDER_CACHE_SOURCES`: Can be set to `true` in case the sources should be cached between builds. This can be useful
  in case of slow sources or sources that are not available all the time. Sources will be cleared automatically after 1
  month, which is important in case packages are getting removed or the source changes.
- `BUILDER_EXTRA_TIMEOUT`: If set, will multiply the global `BUILDER_TIMEOUT` value with the given multiplier.
  If e.g., the default timeout value of `3600` is used, setting this to `2` would increase the build timeout to `7200`.

### Known state variables

State will be kept in the .state worktree. It can be viewed by browsing the `state` branch of a PKGBUILD repository.
Each package will have their own file named after the package name. The following variables are known to be stored:

- `CI_GIT_COMMIT`: Used by CI to determine whether the latest commit changed. Used by `fetch-gitsrc` to schedule new
  builds. Needs to be provided in case the package should be treated as a git package. CI will automatically update the
  latest available commit of the git URL set in the `source` section of the PKGBUILD. If it differs, schedule a
  build. -`CI_PKGBUILD_TIMESTAMP`: The last modified date of the PKGBUILD on AUR. This is used to determine whether the
  PKGBUILD has changed. If it differs, schedule a build. Will be maintained automatically.

### Managing AUR packages

AUR packages can also be managed via this repository in an automated way using `.CI_CONFIG`.
This means that after each scheduled and on-commit pipeline, the AUR repository will be updated to reflect the changes
done to the PKGBUILD folder's files.
Files not relevant to AUR maintenance (e.g. `.CI` folders) will be omitted.
The commit message reflects the fact that the commit was created by a CI pipeline
and contains the link to the source repository's commit history and the pipeline run which triggered the update commit.

### Updating the CI's scripts

This is done automatically via the CI pipeline. Once changes have been detected on the template repository, all files
will be updated to the current version.

## Issues and pipeline failures

### Last on-commit pipeline failed

This can happen in case of a few reasons, for example having provided an invalid package name. This causes
the `scheduled` tag to not be updated.
In this case, the on-schedule pipeline will not be able to run.
The last on-commit pipeline needs to be fixed before the on-schedule pipeline can run again.
Build failures however are not accounted as the `scheduled` tag would be updated already as soon as the scheduling
parameters were generated.
Force pushing a fixed up commit is actively encouraged in such a case, as pushing another commit will cause the CI to
evaluate the previous commits it missed, leading to noticing the same issue again and bailing out instead of silently
continuing.
This has been a design decision to prevent failures from being overlooked.

### Resetting the build queue

There might be rare cases in which a reset of the build queue is needed. This can be done by shutting down the central
Redis instance, removing its dump, and restarting its service. This will, however, also wipe any logs stored inside
Redis.

### Live-updating logs

Logs are live-updating and can be viewed in real-time via the web server.
In case GitLab is used and `PACKAGE_REPOS_NOTIFIERS` is set,
an external CI stage will be created for every package scheduled during the CI run, linking to the log.

### Prometheus metrics

Prometheus metrics are available at the `/metrics` endpoint of the web server.
Currently, we collect default `prom-client` metrics as well as statistics about total event count of each build status
(failed, successful, already-built, timed out) as well as metrics about overall build times.
These can be collected via a Prometheus instance and then be visualized using Grafana.

### Development setup

This repository features a NixOS flake, which may be used to set up the needed things like pre-commit hooks and checks,
as well as needed utilities, automatically via [direnv](https://direnv.net/). This includes checking PKGBUILDs
via `shellcheck` and `shfmt`.

### With Nix

Needed are `nix` (the package manager) and [direnv](https://direnv.net/), after that, the environment may be entered by
running `direnv allow`.

### Without Nix

A bundled variant of the devshell is available via the `repo-common` [GitLab CI artifacts](https://gitlab.com/chaotic-aur/repo-common/-/pipelines).
After downloading and unzipping simply execute the binary inside the PKGBUILDS folder.
Bootstrapping will take a while since dependencies will be unpacked.
