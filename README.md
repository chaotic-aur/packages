# Chaotic-AUR's packages

Here it is the place to submit new packages to Chaotic-AUR.

Every available package is (or should be) in the `entries` directory.

# Entries

Each folder in entries must have a `source` directory, preferably a submodule, or a symlink to the PKGBUILD directory.
The entry folder's name must be the same as the `pkgbase` of the PKGBUILD.

Other optional files can interfere with the building. Those are:

* variations.sh : List all variation of combinations of parameters to run `variate.sh`.  (See `linux-tkg` for example)

* variate.sh :  Apply some variation. (See `linux-tkg` for example)

* prepare: A bash (not any shell) script. Good for sed replacements, use it wisely.

* PKGBUILD.prepend: Prepends the contents to PKGBUILD.

* PKGBUILD.append: Appends the contents to PKGBUILD.

# Queues

These are how the servers organize and build packages. Each item must have the same name as an entry subdirectory. There is no need for it to be a symlink, but we have done it this way, so we know if some item is invalid.

# How to add one package to the running server?

Create the entry directory, add the source submodule, send it as a pull request to this repository.

## Too lazy for a pull request?

Just open an issue with the package name or PKGBUILD location on the internet.