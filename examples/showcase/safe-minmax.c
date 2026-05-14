#include <stdio.h>

int int_max (int a, int b) {
  return (((((a) > (b))) ? (a) : (b)));
}

int int_min (int a, int b) {
  return (((((a) < (b))) ? (a) : (b)));
}

int int_clamp (int val, int lo, int hi) {
  return (((((val) < (lo))) ? (lo) : (((((val) > (hi))) ? (hi) : (val)))));
}

float float_max (float a, float b) {
  return (((((a) > (b))) ? (a) : (b)));
}

float float_min (float a, float b) {
  return (((((a) < (b))) ? (a) : (b)));
}

float float_clamp (float val, float lo, float hi) {
  return (((((val) < (lo))) ? (lo) : (((((val) > (hi))) ? (hi) : (val)))));
}

double double_max (double a, double b) {
  return (((((a) > (b))) ? (a) : (b)));
}

double double_min (double a, double b) {
  return (((((a) < (b))) ? (a) : (b)));
}

double double_clamp (double val, double lo, double hi) {
  return (((((val) < (lo))) ? (lo) : (((((val) > (hi))) ? (hi) : (val)))));
}

int main () {
  printf("int_max(3,5)=%d\n", int_max(3, 5));
  printf("float_min(1.0,2.0)=%g\n", float_min(1.0, 2.0));
  printf("int_clamp(10,0,5)=%d\n", int_clamp(10, 0, 5));
  return (0);
}


