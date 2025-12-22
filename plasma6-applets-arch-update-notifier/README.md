```sh
git tag -s v6.4.1 -m "desc"
git describe --long --abbrev=7
git show-ref --tags v6.4.0
makepkg --printsrcinfo > .SRCINFO
```

