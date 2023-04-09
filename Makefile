all: arw_encode dcraw_hack

arw_encode: arw_encode.c
	gcc -O3 -march=native -o arw_encode arw_encode.c

dcraw_hack: dcraw.c
	gcc -O3 -march=native -o dcraw_hack dcraw.c -lm