// Paren autogenerated this file on 2024-12-24T10:47:47.828319-07:00.

#define EQUAL? (a,b) \
((a) == (b));

#undef EQUAL?

#define SWAP (a,b) \
do {
  typeof(A) = a;
  a = b;
  b = temp;
} while (0);

#undef SWAP

#define EQUAL? (a,b) \
((a) == (b));;
#define SWAP (a,b) \
do {
  typeof(A) = a;
  a = b;
  b = temp;
} while (0);;
int main () {
  int x = 5;
  int y = 10;
  SWAP(x, y);
  printf("x = %d, y = %d\n", x, y);
  return (0);
};
#undef EQUAL?;
#undef SWAP;
