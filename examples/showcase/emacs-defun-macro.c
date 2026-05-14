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
  printf("scar: min=%d max=%d doc=%s\n", p->min_args, p->max_args, p->doc);
  p = &scdr;
  printf("scdr: min=%d max=%d doc=%s\n", p->min_args, p->max_args, p->doc);
  printf("fcar(7)=%d\n", fcar(7));
  printf("fcdr(9)=%d\n", fcdr(9));
  return (0);
}


