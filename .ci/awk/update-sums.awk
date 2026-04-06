# Variables provided:
# sumtypes: e.g. "sha256|sha512|md5|sha1|sha224|sha384|b2"
# newsums: the output of makepkg -g

BEGIN {
  w = 0
}

$0 ~ "^[[:blank:]]*(" sumtypes ")sums(_[^=]+)?\\+?=", $0 ~ "\\)[[:blank:]]*(#.*)?$" {
  if (!w) {
    print newsums
    w = 1
  }
  next
}

{
  print
}

END {
  if (!w) {
    print newsums
  }
}
