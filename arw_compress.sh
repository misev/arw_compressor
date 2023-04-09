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
	DST="$SRC.jxlraw"
fi

if [ -e "$DST" ]
then
	echo "Destination $DST already exists, refusing to overwrite"
	exit 1
fi

DIR=$(mktemp -d "$DST.XXXXXX")

cat <<EOL > "$DIR"/file.list
$DIR/alarms.bin
$DIR/begin
$DIR/orig.sha256
EOL

sha256sum - < "$SRC" > "$DIR"/orig.sha256
dcraw_hack "$SRC" > "$DIR"/temp.rgba 2> "$DIR"/err
HALF_SIZE=$(head -n1 "$DIR"/err | sed -e 's/^.*, half=\([0-9]*x[0-9]*\)$/\1/')
convert -depth 16 -size $HALF_SIZE rgba:"$DIR"/temp.rgba png:"$DIR"/temp.png
grep ALARM "$DIR"/err | cut -c 8- | xxd -r -ps > "$DIR"/alarms.bin
LAST_LINE=$(tail -n1 "$DIR"/err)
PADDING_BYTE=00
if (echo "$LAST_LINE" | grep -q PADDING "$DIR"/err)
then
	PADDING_BYTE=$(echo "$LAST_LINE" | cut -c 10-)
	echo $PADDING_BYTE | xxd -r -ps > "$DIR"/padding
	echo "$DIR"/padding >> "$DIR"/file.list
fi

START=$(head -n1 "$DIR"/err | sed -e 's/^.*data_at=//' -e 's/, .*$//')
HALF_WIDTH=$(echo $HALF_SIZE | sed -e 's/x.*$//')

cjxl -q 100 "$DIR"/temp.png "$DIR"/result.jxl

djxl "$DIR"/result.jxl "$DIR"/result.jxl.png
head -c $START "$SRC" > "$DIR"/begin

# if (cat "$DIR"/begin; convert "$DIR"/result.jxl.png -depth 16 rgba:- | arw_encode $HALF_WIDTH $START "$DIR"/alarms.bin $PADDING_BYTE) | cmp - "$SRC"
# then
	cat "$DIR"/file.list | xargs tar --transform 's=^.*/==' -Jcf "$DIR"/extra.tar.xz
	tar --transform 's=^.*/==' -cf "$DST" "$DIR"/extra.tar.xz "$DIR"/result.jxl
	cat "$DIR"/file.list | xargs rm "$DIR"/{extra.tar.xz,result.jxl,err,result.jxl.png,temp.png,temp.rgba,file.list}
	rmdir "$DIR"
# else
# 	echo data mismatch, temp stuff left in $DIR
# 	exit 1
# fi
