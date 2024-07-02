#include <stdio.h>
#include <stdlib.h>
#include <syslog.h>

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <string> <filename>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    openlog(NULL, LOG_PID, LOG_USER);

    char *string = argv[1];
    char *filename = argv[2];

    FILE *fp = fopen(filename, "w");
    if (fp == NULL) {
        syslog(LOG_ERR, "Failed to open %s for writing", filename);
        perror("fopen");
        exit(EXIT_FAILURE);
    }

    fprintf(fp, "%s\n", string);
    fclose(fp);

    syslog(LOG_DEBUG, "Writing %s to %s", string, filename);

    closelog();

    return 0;
}
