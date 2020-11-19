CC = cc
CFLAGS = -Wall -O2
LDFLAGS =
BINDIR = /bin

all: ncuser

.c.o:
	$(CC) -c $(CFLAGS) $<
ncuser: ncuser.o
	$(CC) -o $@ ncuser.o $(LDFLAGS)
install: ncuser
	@mkdir -p /var/nc
	@cp QEMU nc ncvm nclogin /var/nc/
	@chmod +s /var/nc/ncuser
	@cp nc nc_*.sh $(BINDIR)
clean:
	rm -f *.o ncuser
