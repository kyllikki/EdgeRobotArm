


edgerbtarm:edgerbtarm.vala libedgerbtarm.so
	valac --pkg libedgerbtarm --vapidir . --pkg gtk+-2.0 -X -I. -X -L. -X -ledgerbtarm edgerbtarm.vala

libedgerbtarm.so:libedgerbtarm.c libedgerbtarm.h
	gcc -Wall -I/usr/include/libusb-1.0/ -lusb-1.0 --shared -fPIC -o libedgerbtarm.so libedgerbtarm.c

rbtarm:rbtarm.c
	gcc -I/usr/include/libusb-1.0/ -lusb-1.0 -o rbtarm rbtarm.c

clean:
	${RM} edgerbtarm libedgerbtarm.so rbtarm