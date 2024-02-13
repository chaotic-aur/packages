function append_variable(name, value) {
    if (variables[name] != "") {
        variables[name] = variables[name] "," value
    } else {
        variables[name] = value
    }
}

BEGIN {
    # "," separated
    variables["pkgnames"]=""
    variables["dependencies"]=""
    in_pkgbase=0
}

/^\tprovides = / {
    if (match($0, /^\tprovides = ([a-zA-Z0-9_-]+)(=.*)?$/, o)) {
        append_variable("pkgnames", o[1])
    }
}

/^pkgname = / {
    in_pkgbase=0
    if (match($0, /^pkgname = ([a-zA-Z0-9_-]+)$/, o)) {
        append_variable("pkgnames", o[1])
    }
}

/^pkgbase = / {
    in_pkgbase=1
}

/^\tdepends = / {
    if (in_pkgbase) {
        if (match($0, /^\tdepends = ([a-zA-Z0-9_-]+)([>=<].*)?$/, o)) {
            append_variable("dependencies", o[1])
        }
    }
}

/^\tmakedepends = / {
    if (in_pkgbase) {
        if (match($0, /^\tmakedepends = ([a-zA-Z0-9_-]+)([>=<].*)?$/, o)) {
            append_variable("dependencies", o[1])
        }
    }
}

END {
    print variables["pkgnames"] " " variables["dependencies"]
}