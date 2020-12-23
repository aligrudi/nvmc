CC = cc
CFLAGS = -Wall -O2
LDFLAGS =
BINDIR = /usr/bin

all: ncuser

.c.o:
	$(CC) -c $(CFLAGS) $<
ncuser: ncuser.o
	$(CC) -o $@ ncuser.o $(LDFLAGS)
install: ncuser
	@echo "Copying files to /var/nc"
	@mkdir -p /var/nc
	@cp QEMU nc ncx ncvm nclogin /var/nc/
	@chmod +s /var/nc/ncuser
	@echo "Copying binaries"
	@cp nc ncx $(BINDIR)
clean:
	rm -f *.o ncuser
