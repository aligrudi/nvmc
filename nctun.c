/* Start VNC for a nevuc VM */
#include <unistd.h>
#include <stdio.h>
#include <string.h>

#define NCDIR		"/var/nc"
#define VMDIR		NCDIR "/vms"

int main(int argc, char *argv[])
{
	char user[4096];
	FILE *fp;
	char *cmd = "sshs";
	int uid;
	if (argc < 3) {
		printf("Usage: %s vm sock\n", argv[0]);
		return 1;
	}
	if (getuid() != 0) {
		snprintf(user, sizeof(user), VMDIR "/%s/USER", argv[1]);
		fp = fopen(user, "r");
		if (!fp) {
			fprintf(stderr, "ncvnc: USER file is missing\n");
			return 1;
		}
		if (fscanf(fp, "%d", &uid) != 1) {
			fprintf(stderr, "ncvnc: USER should contain user ID\n");
			return 1;
		}
		fclose(fp);
		if (getuid() != uid) {
			fprintf(stderr, "ncvnc: user ID does not match VM owner\n");
			return 1;
		}
		if (setuid(0)) {
			fprintf(stderr, "ncvnc: failed to change user ID\n");
			return 1;
		}
	}
	if (!!strstr(argv[0], "vnc"))
		cmd = "vncs";
	execl(NCDIR "/nc", NCDIR "/nc", cmd, argv[1], argv[2], NULL);
	return 0;
}
