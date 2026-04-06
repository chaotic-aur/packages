/^[[:space:]]*pkgver[[:space:]]*=/ {
    line = $0
    sub(/^[[:space:]]*pkgver[[:space:]]*=[[:space:]]*/, "", line)
    gsub(/^["\047]|["\047]$/, "", line)
    print line
    exit
}
