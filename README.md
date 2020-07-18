# Chaotic-AUR's packages

Here it's where you can submit new packages to Chaotic-AUR.

Every available package is (or should be) in the `entries` directory.

# Entries

Each folder in entries must have a "source" directory, that must be a submodule, or a syslink to the PKGBUILD directory.
The entry folder's name must be the same as the `pkgbase` of the PKGBUILD.

There are other optionals files that can interefere with the building, those are:

* variations.sh : List all combinations of parameters to run `variate.sh` with.  (See `linux-tkg` for example)

* variate.sh :  Apply some variation. (See `linux-tkg` for example)

* prepare: A bash (not any shell) script, good for sed replacements, use it widely.

* PKGBUILD.prepend: Prepends the contents to PKGBUILD.

* PKGBUILD.append: Appends the contents to PKGBUILD.

# Queues

These is how the servers organize and build the packages, each item must have the same name as an entry. There is no need for it to be a syslink, but I do it this way so we know if some item is invalid.

# How to add one package to the running server?

Create the entry directory, add the source submodule, send it as a pull request to this repository.

## Too lazy for a pull request?

Just open an issue with the package name or PKGBUILD location on the internet.