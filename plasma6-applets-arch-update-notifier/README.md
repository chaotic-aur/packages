Because my brain forgot stuff all day long

```sh
git tag -s v6.4.1 -m "desc"
git show-ref --tags v6.4.0
git describe --long --abbrev=7 | sed 's/^v//;s/\([^-]*-g\)/r\1/;s/-/./g'
makepkg --printsrcinfo > .SRCINFO
```

