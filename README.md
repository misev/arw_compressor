These tools can losslessly compress and decompress a Sony ARW (RAW) image file.

## INSTALLATION

First, compile the binaries:

    make

Then, ensure that you have [JPEG XL](https://jpeg.org/jpegxl/) and the binaries
above in your $PATH. You'll also need ImageMagick's convert, as well as some
standard tools like sha256sum and tar (see *.sh for details).

## USAGE

To compress, use
 $ arw_compress.sh filename.ARW

This should create a filename.ARW.jxlraw that's generally 50-75% the size
of the .ARW file.

To recover your original .ARW file:
 $ arw_decompress.sh filename.ARW.jxlraw

## LICENSE

For *.sh and arw_encode.c: choose one of: 1. GPLv3 or later or 2. Apache 2.0,
whichever fits best. However, this project includes modified code of dcraw,
so check the header of dcraw.c for details on that one.

## TECHNICAL INFO

These tools create a .tar.xz file which contains the ARW header (which
usually includes a lossy JPG preview - this is untouched), a JPEG XL-compressed
image of the raw sensor data (in 16 bits per channel), and a list of "alarms",
ie. some sony-specific fixup data that allows us to recreate the original ARW
perfectly.

arw_encode then reads this list of "alarms" and recreates the ARW file.

The need for those "alarms" arises from a funny encoding that Sony uses
in their RAW files. The original sensor data is about 11-bits per pixel,
but it is compressed into 8 bits, sometimes losing some detail. The
compression is pretty simple: it takes 16 pixel values, encodes the
minimum and the maximum value of those 16, and then encodes the remaining 14
values as 8-bit differences from the minimum. There's also a "shift" amount
applied in case the range of those 16 pixels is larger than 255 (that's when
data loss happens). Because sometimes there's more than one "minimum" or
"maximum" value pixel, there can be multiple ways that Sony can encode these.
I couldn't find a consistent way in which this is encoded, so if the ARW
differs from the simple heuristic I used, an "alarm" is raised and stored in
an exceptions file.

This exceptions file could probably be ignored and the resulting ARW file
would be pixel-for-pixel identical with the original, but I wanted to make
sure the compression scheme is truly lossless and preserves the file
perfectly.
