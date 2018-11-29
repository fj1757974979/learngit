SRC=pb.c

TARGET=pb.so
CFLAGS=`pkg-config --cflags lua` -std=gnu99
LDFLAGS=`pkg-config --libs lua`

all:$(TARGET)

$(TARGET):$(SRC)
	gcc -O3 -shared -fPIC $(SRC) $(CFLAGS) $(LDFLAGS) -o $@
