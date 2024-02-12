BEGIN {
    is_sum = 0
}
function check_sum(sum) {
    r = gensub(/\x27([a-zA-Z0-9_.-]+)\x27/, "\\1", "g", sum)
    r = gensub(/"([a-zA-Z0-9_.-]+)"/, "\\1", "g", r)
    if (r ~ /^ *[a-zA-Z0-9]+$/) {
        return 1
    }
    if (r ~ /^ *[a-zA-Z0-9]+\)$/) {
        is_sum = 0
        return 1
    }
    print r
    return 0
}

{
    if (!is_sum) {
        # Handle sum arrays
        if (match($0, /^(sha(256|512)|md5)sums *= *\((.*)$/, o)) {
            is_sum = 1
            if (check_sum(o[3]) == 1)
                next
        }
    }
    if (is_sum) {
        if (check_sum($0) == 1)
            next
    }
    print
}
