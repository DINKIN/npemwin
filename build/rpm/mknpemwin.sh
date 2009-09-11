#!/bin/sh

name=npemwin

tgzfile=${name}.tgz

rm -rf $name
tar -xzf $tgzfile

. $name/VERSION

rm -rf $name-${version}

cp -r $name $name-${version}
tar -czf $name-$version.tgz $name-$version
cp $name-$version.tgz /usr/src/redhat/SOURCES
cd $name/rpm
make package
