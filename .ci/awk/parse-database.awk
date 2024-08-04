BEGINFILE {
    version=""
    base=""
}

/%BASE%/ {
    v=1
    next
}
/%VERSION%/ {
    v=2
    next
}

v==1 {
    base=$0
    v=0
}
v==2 {
    version=$0
    v=0
}

ENDFILE {
    print base, version
}
