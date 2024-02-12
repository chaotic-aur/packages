# Chaotic Repository Template

This repository contains the template for Chaotic-AUR's infra 4.0.
It supersedes Infra 3.0, taking a different approach to distributing and executing builds.

## Reasoning

Our previous build tools, the so-called [toolbox](https://github.com/chaotic-aur/toolbox) was initially created by @pedrohlc to deal with one issue: having a lot of packages to compile while not having many maintainers for all of the packages.
Additionally, Chaotic-AUR has quite inhomogeneous builders: servers, personal devices, and one HPC which all need to be integrated somehow.
The toolbox had a nice approach to this - keeping things as KISS as possible and using Git to distribute package builds between builders. These would then grab builds according to their activated routines. While this works fairly well, it had a few problems which we tried to get rid of in the new version.
A few key ideas about this new setup:

- Since we like working with CI a lot besides it providing great enhancement for automating boring tasks as well as making the whole process more transparent to the public as well, it was clear CI should be a major part of it.
- The system should have a scheduler that distributes build tasks to nodes, which prevents useless build routines and enables nodes to grab jobs whenever they are queued.
- The tools should be available as Docker containers to make them easy to use on other systems than Arch.
- All logic besides the scheduler (which is written in TypeScript using BullMQ) should be written in Bash

## How it works

The new system consists of three integral parts:

- The CI (which can be both GitLab CI and GitHub Actions!) handles PKGBUILDs, their changes, and figuring out what to build, utilizing a Chaotic Manager container to schedule packages via the central Redis instance.
- The central Redis instance storing information about currently scheduled builds.
- The [Chaotic Manager](https://gitlab.com/garuda-linux/tools/chaotic-manager) which is used to add new builds to the queue and execute them via the main manager container. All containers have SSH-tunneled access to the Redis instance, enabling the build containers to grab new builds whenever they enter the queue.

Compared to Infra 3.0, this means we have the following key differences:

- We no longer have package lists but a repository full of PKGBUILD folders. These PKGBUILDs are getting pulled either from AUR once a package has been updated or updated manually in case a Git repository and its tags serve as a source.
- No more dedicated builders (might change in the future, eg. for heavy builds?) but a common build queue.
- Routines are no longer necessary - CI determines and adds packages to the schedule as needed. The only "routine-like" thing we have is the CI schedule, executing tasks like PKGBUILD or version updates.
- The actual logic behind the build process (like `interfere.sh` or database management) was moved to the [builder container of Chaotic Manager](https://gitlab.com/garuda-linux/tools/chaotic-manager/-/tree/main/builder-container?ref_type=heads) - this one updates daily/on-commit and gets pulled regularly by the Manager instance.
- Live-updating build logs will be available via CI - multiple revisions instead of only the latest.
- The interfere repo is no longer needed, instead, package builds can be configured via the `.CI` folder in their respective PKGBUILD folders. All known interfere types can be put here (eg. `PKGBUILD.append` or `prepare.sh`), keeping existing interferes working.
- The CI's behavior concerning each package can be configured via a `config` file in the `.CI` folder: this file stores information like PKGBUILD source (it can be AUR or something different), PKGBUILD timestamp on AUR, most recent Git commit as well as settings like whether to push a PKGBUILD change back to AUR.
- PKGBUILD changes can now be reviewed in case of major (all changes other than pkgver, hashes, pkgrel) updates - CI automatically creates a PR containing the changes for human review.
- Adding and removing packages is entirely controlled via Git - after adding a new PKGBUILD folder via commit, the corresponding package will automatically be deployed. Removing it has the opposite effect.

## Workflows and information

### Adding packages

Adding packages is as easy as creating a new folder named after the `pkgname` of the package. Put the PKGBUILD and all other required files in here.
Finally, add a `.CI` folder containing the basic config (`CI_PKGBUILD_SOURCE` is required), commit any changes, and push the changes back to the main branch.
Please follow the [conventional commit convention](https://www.conventionalcommits.org/en/v1.0.0/) while doing so ([cz-cli](https://github.com/commitizen/cz-cli) can help with that!).

### Removing packages

This can be done by removing the folder containing a package's PKGBUILD. A cleanup job will then automatically remove any obsolete package via the `on-commit` pipeline run.

### On-commit pipeline

Whenever pushing a new commit, the following actions will be carried out by the CI pipeline:

- Checking when the last `scheduled` tag was created. This is used to determine which packages need to be scheduled.
- It parses each commit for a `[deploy $pkgname]` string, only accepting valid values derived from the existing PKGBUILD folders. `[deploy all]` is a valid parameter as well. Misspelling `$pkgname` is a fatal error here. Any issues must be fixed and force-pushed.
- Then, the changed files are parsed. This also includes removed packages. Any changed relevant field will cause a package deployment of the corresponding package.
- The final action is to build the schedule parameters (handing it over to the scheduled job via artifacts) and remove all obsolete packages in case an earlier step is detected.
- In case all of these actions succeed, the `scheduled` tag gets updated so we can refer to it on a later pipeline run.

### On-schedule pipeline

Every half an hour (or whatever the scheduled time is set to), the on-schedule pipeline will carry out a few tasks:

- Updating the CI template from the template repository (in case this is enabled via `.ci/config`)
- Check if the scheduled tag does not exist or scheduled does not point to HEAD (in this case abort mission!)
- Collect AUR timestamps of packages to determine whether a PKGBUILD changed
- Check whether a package change is determined by a few options
- Writing needed variables back to `.CI/config` (eg. Git hash)
- Either update the PKGBUILD silently in case of minor changes, create a PR for review in case of major updates (and only if `CI_HUMAN_REVIEW` is true)
- Schedule parameters are getting built and handed over to the scheduled job via artifact
- Obsolete branches (eg. merged review PRs) are getting pruned
- The scheduled tag gets updated again

### Adding interfere

Put the required interfere file in the `.CI` folder of a PKGBUILD folder:

- `prepare`: A script that is being executed after the building chroot has been set up. It can be used to source environment variables or modify other things before compilation starts.
  - If something needs to be set up before the actual compilation process, commands can be pushed by inserting eg. `$CAUR_PUSH 'source /etc/profile'`. Likewise, package conflicts can be solved, eg. as follows: `$CAUR_PUSH 'yes | pacman -S nftables'` (single quotes are important because we want the variables/pipes to evaluate in the guest's runtime and not while interfering)
- `interfere.patch`: a patch file that can be used to fix either multiple files or PKGBUILD if a lot of changes are required. All changes need to be added to this file.
- `PKGBUILD.prepend`: contents of this file are added to the beginning of PKGBUILD.
- `PKGBUILD.append`: contents of this file are added to the end of PKGBUILD. Fixing `build()` as is easy as adding the fixed `build()` into this file. This can be used for all kinds of fixes. If something needs to be added to an array, this is as easy as `makedepend+=(somepackage)`.
- `on-failure.sh`: A script that is being executed if the build fails.
- `on-success.sh`: A script that is being executed if the build succeeds.

### Bumping pkgrel

This is now carried out by adding the required variable `CI_PKGREL` to `.CI/config`. See below for more information.

### .CI/config

The `.CI/config` file inside each package directory contains additional flags to control the pipelines and build processes with.

- `CI_GIT_COMMIT`: Used by CI to determine whether the latest commit changed. Used by `fetch-gitsrc` to schedule new builds.
- `CI_IS_GIT_SOURCE`: By setting this to `1`, the `fetch-gitsrc` job will check out the latest git commit of the source and compare it with the value recorded in `CI_GIT_COMMIT`.
  If it differs, schedule a build.
  This is useful for packages that use `pkgver()` to set their version without having `-git` or another VCS package suffix.
- `CI_MANAGE_AUR`: By setting this variable to `1`, the CI will update the corresponding AUR repository at the end of a pipeline run if changes occur (omitting CI-related files)
- `CI_PKGREL`: Controls package bumps for all packages which don't have `CI_MANAGE_AUR` set to `1`. It increases `pkgrel` by `0.1` for every `+1` increase of this variable.
- `CI_PKGBUILD_SOURCE`: Sets the source for all PKGBUILD-related files, used for pulling updated files from remote repositories

### Managing AUR packages (WIP)

AUR packages can also be managed via this repository in an automated way using `.CI_CONFIG`. See the above section for details.

### Updating the CI's scripts

This is done automatically via the CI pipeline. Once changes have been detected on the template repository, all files will be updated to the current version.

### Resetting the build queue

There might be rare cases in which a reset of the build queue is needed. This can be done by shutting down the central Redis instance, removing its dump, and restarting its service.

### Deploying to different repos using the same infrastructure

This is now an officially supported use case. The only thing required is to use another repository that is going to store PKGBUILDs and execute CI pipelines.
The environment variables passed to the main Chaotic Manager instance control which repositories are available to use while scheduling packages. See below for more information.

## Chaotic Manager

This tool is distributed as Docker containers and consists of a pair of manager and builder instances.

- Manager: `registry.gitlab.com/garuda-linux/tools/chaotic-manager/manager`
  - Manages builds by adding them to the schedule
  - Provides log management and the live-updating logs
- Builder: `registry.gitlab.com/garuda-linux/tools/chaotic-manager/builder`
  - This one contains the actual logic behind package builds (seen [here](https://gitlab.com/garuda-linux/tools/chaotic-manager/-/tree/main/builder-container?ref_type=heads)) known from infra 3.0 like `interfere.sh`, `database.sh` etc.
  - Picks packages to build from the Redis instance managed by the manager instance

The manager is used by GitLab CI in the `schedule-package` job, scheduling packages by adding them to the build queue.
The builder can be used by any machine capable of running the container. It will pick available jobs from our central Redis instance.

An example of a valid config can be found in the [Garuda Linux infrastructure repository](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/docker-compose/chaotic-v4/docker-compose.yml?ref_type=heads#L38).

- `DATABASE_HOST`: database address published to the outside world
- `DATABASE_PORT`: the port behind packages can be deployed to
- `DATABASE_USER`: the user to use to deploy packages
- `GPG_PATH`: where the `.gnupg` folder resides (holding the key for signing packages)
- `LANDING_ZONE_PATH`: where the landing zone is (here packages get deployed and later picked up by the database job before getting into the final repository)
- `LOGS_URL`: the URL that serves the logfiles (we get sent here when clicking CI's external stages)
- `PACKAGE_REPOS_NOTIFIERS`: needed configs to provide external CI stages for GitLab CI/GitHub Actions
- `PACKAGE_REPOS`: the source repositories containing PKGBUILD folders
- `PACKAGE_TARGET_REPOS`: the repository a package is getting deployed to (including its URL and extra keyrings/repos needed)
- `REDIS_PASSWORD`: password for accessing the Redis instance
- `REDIS_SSH_HOST`: where to access the Redis instance
- `REDIS_SSH_USER: the user who can access the Redis instance
- `REPO_PATH`: the path where the final package deployment happens

## Development setup

This repository features a NixOS flake, which may be used to set up the needed things like pre-commit hooks and checks, as well as needed utilities, automatically via [direnv](https://direnv.net/). This includes checking PKGBUILDs via `shellcheck` and `shfmt`.
Needed are `nix` (the package manager) and [direnv](https://direnv.net/), after that, the environment may be entered by running `direnv allow`.
