# Chaotic Repository Template

This repository contains the template for Chaotic-AUR's infra 4.0.
It supersedes Infra 3.0, taking a different approach to distributing and executing builds.

## Reasoning

Our previous build tools, the so-called [toolbox](https://github.com/chaotic-aur/toolbox) was initially created by
@pedrohlc to deal with one issue: having a lot of packages to compile while not having many maintainers for all of the
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
- No more dedicated builders (might change in the future, eg. for heavy builds?) but a common build queue.
- Routines are no longer necessary - CI determines and adds packages to the schedule as needed. The only "routine-like"
  thing we have is the CI schedule, executing tasks like PKGBUILD or version updates.
- The actual logic behind the build process (like `interfere.sh` or database management) was moved to
  the [builder container of Chaotic Manager](https://gitlab.com/garuda-linux/tools/chaotic-manager/-/tree/main/builder-container?ref_type=heads) -
  this one updates daily/on-commit and gets pulled regularly by the Manager instance.
- Live-updating build logs will be available via CI - multiple revisions instead of only the latest.
- The interfere repo is no longer needed, instead, package builds can be configured via the `.CI` folder in their
  respective PKGBUILD folders. All known interfere types can be put here (eg. `PKGBUILD.append` or `prepare.sh`),
  keeping existing interferes working.
- The CI's behavior concerning each package can be configured via a `config` file in the `.CI` folder: this file stores
  information like PKGBUILD source (it can be AUR or something different), PKGBUILD timestamp on AUR, most recent Git
  commit as well as settings like whether to push a PKGBUILD change back to AUR.
- PKGBUILD changes can now be reviewed in case of major (all changes other than pkgver, hashes, pkgrel) updates - CI
  automatically creates a PR containing the changes for human review.
- Adding and removing packages is entirely controlled via Git - after adding a new PKGBUILD folder via commit, the
  corresponding package will automatically be deployed. Removing it has the opposite effect.

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

### On-schedule pipeline

#### Half-hourly

Every half an hour, the on-schedule pipeline will carry out a few tasks:

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

#### Running scheduled pipelines on-demand

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

This is now carried out by adding the required variable `CI_PACKAGE_BUMP` to `.CI/config`. See below for more information.

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
- `CI_PACKAGE_BUMP`: Controls package bumps for all packages which don't have `CI_MANAGE_AUR` set to `true`. The format this needs
  to follow is either `1:1.2.3-1/1` (full current version and bump count after the slash) or `1.2.3` (full current package version,
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
  Packages having this variable set will **not** be scheduled via the regular on-schedule pipeline, hence this one can also be used to prevent wasting builder resources, e.g. useful for huge `-git` packages with a lot of commit activity, like `llvm-git`.
- `CI_REBUILD_TRIGGERS`: Add packages known to be causing rebuilds to this variable. A list of repositories to track package versions for is provided via the repositories' `CI_LIB_DB` parameter. Each package version is hashed and dumped to `.ci/lib.state`. Each scheduled pipeline run compares versions by checking hash mismatches and will bump each each affected package via `CI_PACKAGE_BUMP`.
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

### CI pipeline variables

These variables can be set in in the repo root's`.ci/config` to configure the pipeline behavior globally as follows:

- `BUILD_REPO`: The target repository that will be the deploy target
- `GIT_AUTHOR_EMAIL`: The email of the user that will be used to commit
- `GIT_AUTHOR_NAME`: The name of the user that will be used to commit
- `REDIS_SSH_HOST`: The Redis SSH host for the target repository (for SSH tunneling)
- `REDIS_SSH_PORT`: The Redis SSH port for the target repository (for SSH tunneling)
- `REDIS_SSH_USER`: The Redis SSH user for the target repository (for SSH tunneling)
- `REDIS_PORT`: The redis port for the target repository (inside the SSH tunnel)
- `REPO_NAME`: The name that this repository is referred to in Chaotic Manager's config
- `CI_HUMAN_REVIEW`: If merge/pull requests should be created for non pkgver changes
- `CI_MANAGE_AUR`: This should be set to true in case select AUR repositories should be managed by CI
- `CI_OVERWRITE_COMMITS`: If we should overwrite existing automated commits to reduce the size of the git history
- `CI_CLONE_DELAY`: How long to wait between every executed git clone command for rate limits
- `CI_AUR_PROXY`: Proxy to use for AUR requests

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

### Issues and pipeline failures

#### Last on-commit pipeline failed

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

#### Resetting the build queue

There might be rare cases in which a reset of the build queue is needed. This can be done by shutting down the central
Redis instance, removing its dump, and restarting its service.

### Deploying to different repos using the same infrastructure

This is now an officially supported use case. The only thing required is to use another repository that is going to
store PKGBUILDs and execute CI pipelines.
The environment variables passed to the main Chaotic Manager instance control which repositories are available to use
while scheduling packages. See below for more information.

## Chaotic Manager

This tool is distributed as Docker containers and consists of a pair of manager and builder instances.

- Manager: `registry.gitlab.com/garuda-linux/tools/chaotic-manager/manager`
  - Manages builds by adding them to the schedule, used e.g. in the schedule step of CI pipelines
  - Provides log management and the live-updating logs
  - Manages any existing builds by spinning up build containers, picking from the available BullMQ builder / database
    queues
  - Picks up already built package archives from the landing zone (builder containers push finished build archives here)
    to add them to the database of the target repository
- Builder: `registry.gitlab.com/garuda-linux/tools/chaotic-manager/builder`
  - This one contains the actual logic behind package builds (
    seen [here](https://gitlab.com/garuda-linux/tools/chaotic-manager/-/tree/main/builder-container?ref_type=heads))
    known from infra 3.0 like `interfere.sh`, `database.sh` etc.
  - This one is used by an executing manager instance to run the build processes with. It runs jobs present in the
    builder BullMQ queue.

An example of a valid config can be found in
the [Garuda Linux infrastructure repository](https://gitlab.com/garuda-linux/infra-nix/-/blob/main/docker-compose/chaotic-v4/docker-compose.yml?ref_type=heads#L38).
The following variables can be set in Docker environment:

- `DATABASE_HOST`: database address published to the outside world
- `DATABASE_PORT`: the port behind packages can be deployed to
- `DATABASE_USER`: the user to use to deploy packages
- `GPG_PATH`: where the `.gnupg` folder resides (holding the key for signing packages)
- `LANDING_ZONE_PATH`: where the landing zone is (here packages get deployed and later picked up by the database job
  before getting into the final repository)
- `LOGS_URL`: the URL that serves the logfiles (we get sent here when clicking CI's external stages)
- `PACKAGE_REPOS_NOTIFIERS`: needed configs to provide external CI stages for GitLab CI/GitHub Actions
- `PACKAGE_REPOS`: the source repositories containing PKGBUILD folders
- `PACKAGE_TARGET_REPOS`: the repository a package is getting deployed to (including its URL and extra keyrings/repos
  needed)
- `REDIS_PASSWORD`: password for accessing the Redis instance
- `REDIS_SSH_HOST`: where to access the Redis instance
- `REDIS_SSH_USER`: the user who can access the Redis instance
- `REPO_PATH`: the path where the final package deployment happens
- `TELEGRAM_BOT_TOKEN`: the token for the Telegram bot, used for notifications
- `TELEGRAM_CHAT_ID`: the chat ID for the Telegram bot to send deployment or failure notifications to

The following variables are only relevant for builder instances:

- `BUILDER_HOSTNAME`: the hostname of the builder will be displayed in package logs to determine which builder built a
  package
- `BUILDER_TIMEOUT`: the timeout for a package build, 3600 seconds by default. Should be increased on slow builders

### Setting up

#### Requirements

The base requirements for running this kind of setup are as follows:

- Docker/Podman must be installed in the target system, docker-/podman-compose are good to have as well. We will use it
  in our following examples.
- A Redis instance must be available, e.g. installed on the host system or added to ´docker-compose.yml`:

  ```yml
  chaotic-redis:
    image: redis:alpine
    container_name: chaotic-redis
    restart: always
    ports:
      - "6379:6379"
    command: redis-server --save 60 1 --loglevel warning --requirepass verysecurepassword
    volumes:
      - ./redis-data:/data
  ```

  The following examples assume Redis to be installed on the host system. In case it is added to `docker-compose.yml`,
  replace any occurances of `host.docker.internal` with `chaotic-redis`.

- A reverse proxy like Nginx to expose the Chaotic Manager's logs to the public in a secure way should be available.
  E.g., using Nginx it is sufficient to `proxy_pass` the specified `--web-port` value to the Manager instance container.
  Additionally, the following settings might be usedful:

  ```ǹginx
  proxy_buffering off;
  proxy_read_timeout 330s;
  ```

#### Repository setup

The repository needs to be derived from the [repository template](https://github.com/chaotic-cx/chaotic-repository-template). On GitHub, the ["Use this template"](https://github.com/new?template_name=chaotic-repository-template&template_owner=chaotic-cx) feature may be used.
Afterward, customize the `.ci/config` file according to your needs. This file contains global configuration for pipeline runs and CI behaviour.
The following options exist as of today:

- `BUILD_REPO`: The target repository that will be the deploy target
- `GIT_AUTHOR_EMAIL`: The email of the user that will be used to commit
- `GIT_AUTHOR_NAME`: The name of the user that will be used to commit
- `REDIS_SSH_HOST`: The redis host for the target repository
- `REDIS_SSH_PORT`: The redis port for the target repository
- `REDIS_SSH_USER`: The redis user for the target repository
- `REDIS_PORT`: The redis port for the target repository
- `REPO_NAME`: The name that this repository is referred to in chaotic-manager's config
- `CI_HUMAN_REVIEW`: Whether merge/pull requests should be created for non pkgver changes (false/true)
- `CI_MANAGE_AUR`: This should be set to true in case select AUR repositories should be managed by CI. A fitting SSH key needs to be deployed as AUR_KEY via secret CI variable.
- `CI_OVERWRITE_COMMITS`: Whether we should overwrite existing automated commits to reduce the size of the git history (false/true)
- `CI_CLONE_DELAY`: How long to wait between every executed git clone command for ratelimits (false/true)
- `CI_AUR_PROXY`: Proxy to use for AUR requests
- `CI_LIB_DB`: Archlinux / Chaotic-AUR repo mirror to use for pulling db files from, in the following format: `https://arch.mirror.constant.com/core/os/x86_64/core.db https://arch.mirror.constant.com/community/os/x86_64/community.db ...`

#### Exemplary manager instance setup

```yaml
chaotic-manager:
  image: registry.gitlab.com/garuda-linux/tools/chaotic-manager/manager:latest
  container_name: chaotic-manager
  command: database --web-port 8080
  environment:
    DATABASE_HOST: sub.domain.tld
    DATABASE_PORT: 22
    DATABASE_USER: package-deployer
    GPG_PATH: /var/awesome-repo/gnupg
    LANDING_ZONE_PATH: /var/awesome-repo/landing-zone
    LOGS_URL: https://sub.domain.tld/logs/logs.html
    REDIS_PASSWORD: verysecurepassword
    REDIS_SSH_HOST: host.docker.internal
    REDIS_SSH_USER: package-deployer
    REPO_PATH: /srv/http/repos
    TELEGRAM_BOT_TOKEN: 1234567890
    TELEGRAM_CHAT_ID: 0987654321
    PACKAGE_REPOS: >-
      {
          "awesome-repo": {
              "url": "https://gitlab.com/awesome-repo/pkgbuilds"
          }
      }
    PACKAGE_TARGET_REPOS: >-
      {
          "awesome-repo": {
              "extra_repos": [
                  {
                      "name": "awesome-repo",
                      "servers": [
                          "https://sub.domain.tld/awesome-repo/x86_64"
                      ]
                  }
              ],
              "extra_keyrings": [
                  "https://sub.domain.tld/awesome-repo/awesome-keyring.pkg.tar.zst"
              ]
          }
      }
    PACKAGE_REPOS_NOTIFIERS: >-
      {
          "awesome-repo": {
              "id": "123456",
              "token": "GITLABAPITOKENWITHAPIACCESS",
              "check_name": "awesome-repo: %pkgbase%"
          }
      }
  volumes:
    - ./sshkey:/app/sshkey
    - /var/run/docker.sock:/var/run/docker.sock
    - /srv/http/repos:/repo_root
  extra_hosts:
    - "host.docker.internal:host-gateway"
  ports: [8080:8080]
```

The following things are to note:

- `PACKAGE_REPOS`, `PACKAGE_TARGET_REPOS` and `PACKAGE_REPOS_NOTIFIERS` are JSON values and need to be valid JSON in
  order to be processed.
- The above setup assumes the docker-compose.yml to be present in `var/awesome-repo`.
- `LOGS_URL` needs to match the address which the reverse proxy publishes `--web-port 8080` to the outside world.
- `REPO_PATH` is the path of the repository _on the Docker host_. The same path must be mapped to `/repo_root` inside
  the container via volumes.
- `/app/sshkey` is assumed to be the private SSH key
- Ports don't have to explicitly exposed if using an Nginx Docker container, in this setup however, our Nginx and Redis
  instance are present on the host system.
- `PACKAGE_REPOS_NOTIFIERS` and `TELEGRAM_*` variables are optional but provide additional functionality of they are
  set.
- `DATABASE_HOST` refers to the address published to the outside world, e.g. for additional builders an other servers.

#### Examplary builder instance setup

```yaml
---
services:
  chaotic-builder:
    image: registry.gitlab.com/garuda-linux/tools/chaotic-manager/manager:latest
    container_name: chaotic-builder
    command: builder
    environment:
      BUILDER_TIMEOUT: 7200
      BUILDER_HOSTNAME: awesome-builder
      REDIS_PASSWORD: verysecurepassword
      REDIS_SSH_HOST: host.docker.internal
      REDIS_SSH_USER: package-deployer
      SHARED_PATH: /var/chaotic/shared
      DATABASE_HOST: host.docker.internal
      DATABASE_PORT: 22
    volumes:
      - ./shared:/shared
      - ./sshkey:/app/sshkey
      - /var/run/docker.sock:/var/run/docker.sock
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

The following things are to note:

- The above setup assumes the docker-compose.yml to be present in `var/awesome-repo`.
- The `SHARED_PATH` variable needs to match the directory mapped to `/shared` inside the container.
- `DATABASE_HOST` can in theory be any other host, but can be set to `host.docker.internal` in case the Redis instance
  runs on the Docker host.
- The Docker socket needs to be mounted as the builder instance will use it to spin up build container instances.
- `/app/sshkey` is assumed to be the private SSH key used for pushing finished package builds to the manager instance's
  landing zone.
- `BUILDER_TIMEOUT` only needs to be set in case it is a slower build machine which does not finish heaver tasks in one
  hour.
- As many instances of this container can be added the setup as wanted. Each of them will allow processing another build
  at the same time in total.

### Features

#### Chaotic-Manager container commands

- `schedule`: Schedules a new package build by adding it to the Redis instance. It takes the following arguments:
  - `arch`: The architecture to build the package for
  - `target-repo`: The target repository to deploy the package to, referring to the `PACKAGE_TARGET_REPOS` variable set
    in the Docker environment variables.
  - `source-repo`: The source repository to pull the package from, referring to the `PACKAGE_REPOS` variable set in the
    Docker environment variables.
  - `commit`: The commit hash which the schedule call originates from
  - `deptree`: the dependency tree built by the CI pipeline. This parameter is omitted in CI pipelines and instead
    passed as file, reading from `/.ci/deptree.txt`. The reason is that the parameter will be to huge to be processed by
    the shell if 100+ packages are
    scheduled at the same time.
    It contains information about the build order of packages and their dependencies.
- `builder`: Starts the build job, which then grabs any available build jobs from the build queue.
- `auto-repo-remove`: Removes obsolete packages from the target repository. Further parameters must include the pkgbases
  to be removed.
- `database`: Starts the manager instance, which is responsible for managing queues, logs and database jobs. It
  additionally spins up a web server to serve logs from if `--web-port` is passed as argument.
- `web`: Starts the web server to serve logs from. This is only needed in case the manager instance does not run the web
  server.

#### Web server

Available routes on the port set up be the `--web-port` parameter are as follows:

- `/api/logs/:id/:timestamp`: Returns the log file of a package build. The `id` is the package's ID, the `timestamp` is
  the timestamp of the build.
- `/api/logs/:id`: Returns the latest log file of a package build. The `id` is the package's ID.
- `/api/queue/stats`: Returns a JSON object containing the current queue stats.
- `/api/queue/packages`: Returns a JSON object containing information the currently scheduled packages.
- `/metrics`: Returns collected Prometheus metrics.

#### Notifications

Notifications about relevant events can be sent to a Telegram channel or chat via a Bot.
This requires a valid Bot token and the Chat ID to be set.
The following events are currently supported:

- Build failures: additionally contains links to full build logs and the originating commit.

  ```text
  🚨 Failed deploying to awesome-repo:
  > freecad-git - logs- commit
  ```

- Build success:

  ```text
  📣 New deployment to awesome-repo:
  > freecad-git
  ```

- Timed out build: Contains links to full build logs and the originating commit.

  ```text
  ⏳ Build for awesome-repo failed due to a timeout:
  > freecad-git - logs - commit
  ```

- Successful repo-remove jobs:

  ```text
  ✅ Repo-remove job for awesome-repo finished successfully
  ```

- Failed repo-remove jobs:

  ```text
  🚫 Repo-remove job for awesome-repo failed
  ```

#### Build order

The build order is determined by the dependency tree built by the CI pipeline.
This tree is passed to the manager and is then used to determine the correct build order automatically.
No further intervention is needed to achieve this.

#### Live-updating logs

Logs are live-updating and can be viewed in real-time via the web server.
In case GitLab is used and `PACKAGE_REPOS_NOTIFIERS` is set,
an external CI stage will be created for every package scheduled during the CI run, linking to the log.

#### Prometheus metrics

Prometheus metrics are available at the `/metrics` endpoint of the web server.
Currently, we collect default `prom-client` metrics as well as statistics about total event count of each build status
(failed, successful, already-built, timed out) as well as metrics about overall build times.
These can be collected via a Prometheus instance and then be visualized using Grafana.

## Development setup

This repository features a NixOS flake, which may be used to set up the needed things like pre-commit hooks and checks,
as well as needed utilities, automatically via [direnv](https://direnv.net/). This includes checking PKGBUILDs
via `shellcheck` and `shfmt`.
Needed are `nix` (the package manager) and [direnv](https://direnv.net/), after that, the environment may be entered by
running `direnv allow`.
