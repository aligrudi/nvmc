CC = cc
CFLAGS = -Wall -O2
LDFLAGS =
BINDIR = /bin

all: nctun

.c.o:
	$(CC) -c $(CFLAGS) $<
nctun: nctun.o
	$(CC) -o $@ nctun.o $(LDFLAGS)
install: nctun
	@mkdir -p /var/nc
	@cp QEMU nc ncvm nclogin /var/nc/
	@cp nctun /var/nc/ncssh
	@cp nctun /var/nc/ncvnc
	@chmod +s /var/nc/ncvnc /var/nc/ncssh
	@cp nc nc_*.sh $(BINDIR)
clean:
	rm -f *.o nctun
