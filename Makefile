ALL_CFLAGS=$(CFLAGS) -Wall -Wextra -Wshadow -Wconversion -Wpedantic -pedantic -std=gnu11 \
	-Wno-unused-function -Wno-fixed-enum-extension -Wimplicit-fallthrough -Wno-format-truncation -Wno-unknown-warning-option
LIBS=-lSDL2 -lGL -ldl -lm
DEBUG_CFLAGS=$(ALL_CFLAGS) -DDEBUG -O0 -g
RELEASE_CFLAGS=$(ALL_CFLAGS) -O3 -g
PROFILE_CFLAGS=$(ALL_CFLAGS) -O3 -g -DPROFILE=1
shaders: *.[ch]
	$(CC) main.c -o $@ $(DEBUG_CFLAGS) $(LIBS)
release: *.[ch]
	$(CC) main.c -o shaders $(RELEASE_CFLAGS) $(LIBS)
profile: *.[ch]
	$(CC) main.c -o shaders $(PROFILE_CFLAGS) $(LIBS)
clean:
	rm -f shaders
