/* Execute user commands for managing VMs */
#include <unistd.h>
#include <stdio.h>
#include <string.h>

#define NCDIR		"/var/nc"
#define VMDIR		NCDIR "/vms"

static char *cmds[] = {"vncs", "sshs", "poff", "reboot", "quit", "exec", NULL};

static int allowed(char *cmd)
{
	int i;
	for (i = 0; cmds[i]; i++)
		if (strstr(cmds[i], cmd))
			return 1;
	return 0;
}

int main(int argc, char *argv[])
{
	char user[4096];
	FILE *fp;
	char *cmd = argv[1];
	char **args = argv + 2;
	int uid;
	if (argc < 3) {
		printf("Usage: %s command vmname [args]\n", argv[0]);
		return 1;
	}
	if (!allowed(cmd)) {
		fprintf(stderr, "ncuser: unknown command\n");
		return 1;
	}
	if (getuid() != 0) {
		snprintf(user, sizeof(user), VMDIR "/%s/USER", args[0]);
		fp = fopen(user, "r");
		if (!fp) {
			fprintf(stderr, "ncuser: USER file is missing\n");
			return 1;
		}
		if (fscanf(fp, "%d", &uid) != 1) {
			fprintf(stderr, "ncuser: USER should contain user ID\n");
			return 1;
		}
		fclose(fp);
		if (getuid() != uid) {
			fprintf(stderr, "ncuser: user ID does not match VM owner\n");
			return 1;
		}
		if (setuid(0)) {
			fprintf(stderr, "ncuser: failed to change user ID\n");
			return 1;
		}
	}
	execl(NCDIR "/nc", NCDIR "/nc", cmd, args[0], args[1], NULL);
	return 0;
}
