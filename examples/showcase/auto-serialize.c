#include <stdlib.h>

#include <string.h>

#include <stdio.h>

struct entity {
  int id;
  float x;
  float y;
};

void entity_serialize (struct entity *(src), char *(buf)) {
  memcpy(((buf) + (0)), &src->id, 4);
  memcpy(((buf) + (4)), &src->x, 4);
  memcpy(((buf) + (8)), &src->y, 4);
}

void entity_deserialize (struct entity *(dst), char *(buf)) {
  memcpy(&dst->id, ((buf) + (0)), 4);
  memcpy(&dst->x, ((buf) + (4)), 4);
  memcpy(&dst->y, ((buf) + (8)), 4);
}

int main () {
  struct entity *(e) = malloc(sizeof(struct entity));
  e->id = 42;
  e->x = 1.5;
  e->y = 2.5;
  printf("entity: id=%d x=%.1f y=%.1f\n", e->id, e->x, e->y);
  return (0);
}


