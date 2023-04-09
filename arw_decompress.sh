#! /bin/bash

set -e

SRC="$1"
DST="$2"

if [ "x$SRC" == "x" ]
then
	echo "Need a source file!"
	exit 1
fi

if [ "x$DST" == "x" ]
then
	DST=$(echo "$SRC" | sed -e 's/\.jxlraw$//')
fi

if [ -e "$DST" ]
then
	echo "Destination $DST already exists, refusing to overwrite"
	exit 1
fi

DIR=$(mktemp -d "$DST.XXXXXX")

tar -C "$DIR" -xf "$SRC"
tar -C "$DIR" -Jxf "$DIR"/extra.tar.xz
START=$(stat -c '%s' "$DIR"/begin)
HALF_WIDTH=$(jxlinfo "$DIR"/result.jxl | grep 'JPEG XL image' | sed -e 's/^JPEG XL image, \([0-9]*\)x.*$/\1/')
PADDING=00
if [ -e "$DIR"/padding ]
then
	PADDING=$(head -c1 "$DIR/padding" | xxd -ps)
	rm "$DIR"/padding
fi

djxl "$DIR"/result.jxl "$DIR"/result.jxl.png
(cat "$DIR"/begin; convert "$DIR"/result.jxl.png -depth 16 rgba:- | arw_encode $HALF_WIDTH $START "$DIR"/alarms.bin $PADDING) > "$DST"
if ! sha256sum --quiet -c "$DIR"/orig.sha256 < "$DST"
then
	echo "SHA mismatch, $DST broken, stuff left in $DIR :-("
	exit 1
fi
rm "$DIR"/{extra.tar.xz,result.jxl,result.jxl.png,begin,orig.sha256,alarms.bin}
rmdir "$DIR"
