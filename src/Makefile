# LINK_FLAGS = -lm
# CCFLAGS = -O2 -finline-functions -pipe -march=native -fomit-frame-pointer -DNDEBUG 
# #CCFLAGS = -g3 -Wall
# CC = gcc

# all: compressor 

# iris_compression.o: iris_compression.c ../inc/iris_entropy_encoder.h ../inc/iris_predictor.h Makefile
# 	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o iris_compression.o iris_compression.c

# iris_entropy_encoder.o: iris_entropy_encoder.c ../inc/iris_entropy_encoder.h ../inc/iris_predictor.h ../inc/iris_utils.h Makefile
# 	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o iris_entropy_encoder.o iris_entropy_encoder.c

# iris_predictor.o: iris_predictor.c ../inc/iris_predictor.h ../inc/iris_utils.h Makefile
# 	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o iris_predictor.o iris_predictor.c

# iris_utils.o: iris_utils.c ../inc/iris_utils.h Makefile
# 	$(CC) $(CCFLAGS) -c -o iris_utils.o iris_utils.c

# compressor: iris_compression.o iris_entropy_encoder.o iris_predictor.o iris_utils.o Makefile
# 	$(CC) $(CCFLAGS) -o compressor iris_compression.o iris_entropy_encoder.o iris_predictor.o iris_utils.o $(LINK_FLAGS)
    
# clean:
# 	rm -rf compressor *.o *~ ../*~


LINK_FLAGS = -lm
CCFLAGS = -O2 -finline-functions -pipe -march=native -fomit-frame-pointer -DNDEBUG 
#CCFLAGS = -g3 -Wall
CC = gcc

all: main main2

main.o: main.c Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o main.o main.c
	
buffer.o: iris_buffer.c Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o buffer.o iris_buffer.c

heuristic.o: iris_heuristic.c iris_cloud_detection.c Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o heuristic.o iris_heuristic.c

compression.o: iris_compression.c Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o compression.o iris_compression.c

encoder.o: iris_entropy_encoder.c Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o encoder.o iris_entropy_encoder.c

predictor.o: iris_predictor.c Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o predictor.o iris_predictor.c

utils.o: iris_utils.c Makefile
	$(CC) $(CCFLAGS) -DNO_COMPUTE_LOCAL -c -o utils.o iris_utils.c

main: main.o buffer.o heuristic.o compression.o encoder.o predictor.o utils.o Makefile
	$(CC) $(CCFLAGS) -o main main.o buffer.o compression.o encoder.o predictor.o utils.o $(LINK_FLAGS)

clean:
	rm -rf main *.o *~ ../*~

