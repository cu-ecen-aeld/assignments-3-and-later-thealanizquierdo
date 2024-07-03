CC = gcc
CFLAGS = -Wall -Werror
LDFLAGS =
TARGET = writer

.PHONY: all clean

all: $(TARGET)

$(TARGET): finder-app/writer.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGET)
