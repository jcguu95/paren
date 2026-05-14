#include <stdio.h>

enum { err_ok, err_timeout, err_noconn, err_denied, err_corrupt };

static char *((error_messages)[5]) = {"success", "timeout", "no connection", "access denied", "data corrupt"};

int main () {
  int i = 0;
  for (i = 0; ((i) < (5)); ((i)++)) {
    printf("%d: %s\n", i, error_messages[i]);
  }
  printf("err_ok=%d\n", err_ok);
  printf("err_corrupt=%d\n", err_corrupt);
  return (0);
}


