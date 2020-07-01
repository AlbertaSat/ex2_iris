LINK_FLAGS = -lm
CCFLAGS = -O2 -finline-functions -pipe -march=native -fomit-frame-pointer -DNDEBUG 
#CCFLAGS = -g3 -Wall
CC = gcc

all: buffer

main.o: main.c buffer.h Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o main.o main.c

buffer.o: buffer.c buffer.h Makefile
	$(CC) $(CCFLAGS) -c -o buffer.o buffer.c

buffer: main.o buffer.o Makefile
	$(CC) $(CCFLAGS) -o buffer main.o buffer.o $(LINK_FLAGS)
    
clean:
	rm -rf buffer *.o *~ ../*~