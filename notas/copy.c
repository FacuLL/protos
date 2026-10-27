#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>

#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>
// #include <sys/sendfile.h>

enum errors {
  INVALID_ARGUMENTS,
  MISSING_TO_OPEN
};

void 
copy_sendfile(const int fromfd, const int tofd) {
    int n;
    struct stat s;
    off_t offset = 0;

    fstat(fromfd, &s); 
    n = s.st_size;

    while(n > 0) {
        const int sb = sendfile(tofd, fromfd, &offset, n);
        if(sb <= -1) {
            break;
        } else if(sb == 0) {
            break;
        } else {
           n -= sb;
        }
    }
}

void 
copy_rw(const int fromfd, const int tofd, unsigned int buffsize) {
    char buf[4096];
    ssize_t nread;

    if(buffsize > sizeof(buf)) {
        fprintf(stderr, "buffsize should be <= : %lu\n", sizeof(buf));
        return;
    }

    while (nread = read(fromfd, buf, buffsize), nread > 0) {
        char *out_ptr = buf;
        ssize_t nwritten;

        do {
            nwritten = write(tofd, out_ptr, nread);

            if (nwritten >= 0) {
                nread -= nwritten;
                out_ptr += nwritten;
            } else if (errno != EINTR) {
                goto error;
            }
        } while (nread > 0);
    }
    error:
        if(errno != 0) {
           fprintf(stderr, "Failed to copy: %s\n", strerror(errno));
        }

}

void
usage(const char *name) {
    fprintf(stderr, "Usage: %s source destination buffer_size\n", name);
}

int 
main(const int argc, const char **argv) {
    int ret = 0;

    if(argc < 4) {
        usage(argv[0]);
        ret = INVALID_ARGUMENTS;
    } else {
        const int source = open(argv[1], O_RDONLY);
        if(-1 == source) { 
            fprintf(stderr, "Unable to open file `%s': %s\n", argv[1], 
                    strerror(errno));
            ret = MISSING_TO_OPEN;
        } else {
            const int dest = open(argv[2], O_WRONLY | O_CREAT | O_TRUNC, 0660);
            if(-1 == dest) {
                fprintf(stderr, "Unable to open file `%s': %s\n", argv[1], 
                        strerror(errno));
                ret = MISSING_TO_OPEN;
            } else {
                const int buffsize = atoi(argv[3]);
                if(buffsize == 0) {
                     copy_sendfile(source, dest);
                } else if(buffsize > 0) {
                     copy_rw(source, dest, buffsize);
                }
            }
        }
    }
    return ret;
}

