#include <stdio.h>

struct subr {
  int min_args;
  int max_args;
  char *(doc);
};

static struct subr scar = {1, 1, "Return the car."};

int fcar (int x) {
  return (x);
}

static struct subr scdr = {1, 1, "Return the cdr."};

int fcdr (int x) {
  return (x);
}

int main () {
  struct subr *(p) = &scar;
  printf("scar.doc = %s\n", p->doc);
  p = &scdr;
  printf("scdr.doc = %s\n", p->doc);
  return (0);
}


