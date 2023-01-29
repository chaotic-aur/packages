#! /usr/bin/env sh

FILE="/tmp/nightly.new"

if (test -e $FILE); then
    echo "cleaning $FILE"
    rm $FILE
fi
echo "## KF5" >> $FILE
sort _kf5.txt >> $FILE
echo "--" >> $FILE
echo "## PLASMA" >> $FILE
sort _plasma.txt >> $FILE
echo "## KDE APPS" >> $FILE
sort _kde_apps.txt >> $FILE
echo "## OTHERS" >> $FILE
cat _others.txt >> $FILE

echo $FILE generated

cat nightly.txt | sort > /tmp/nightly.txt.sorted
cat $FILE | sort > /tmp/nightly.new.sorted

diff -y --suppress-common-lines --suppress-blank-empty /tmp/nightly.txt.sorted /tmp/nightly.new.sorted


if [ "$1" == "update" ]; then
    echo updating nightly.txt with $FILE
    cp -av $FILE nightly.txt
fi
