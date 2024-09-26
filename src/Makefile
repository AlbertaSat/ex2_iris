LINK_FLAGS = -lm
CCFLAGS = -O2 -finline-functions -pipe -march=native -fomit-frame-pointer -DNDEBUG 
#CCFLAGS = -g3 -Wall
CC = gcc

all: compressor 

iris_compression.o: iris_compression.c ../inc/iris_entropy_encoder.h ../inc/iris_predictor.h Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o iris_compression.o iris_compression.c

iris_entropy_encoder.o: iris_entropy_encoder.c ../inc/iris_entropy_encoder.h ../inc/iris_predictor.h ../inc/iris_utils.h Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o iris_entropy_encoder.o iris_entropy_encoder.c

iris_predictor.o: iris_predictor.c ../inc/iris_predictor.h ../inc/iris_utils.h Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o iris_predictor.o iris_predictor.c

iris_utils.o: iris_utils.c ../inc/iris_utils.h Makefile
	$(CC) $(CCFLAGS) -c -o iris_utils.o iris_utils.c

compressor: iris_compression.o iris_entropy_encoder.o iris_predictor.o iris_utils.o Makefile
	$(CC) $(CCFLAGS) -o compressor iris_compression.o iris_entropy_encoder.o iris_predictor.o iris_utils.o $(LINK_FLAGS)
    
clean:
	rm -rf compressor *.o *~ ../*~


