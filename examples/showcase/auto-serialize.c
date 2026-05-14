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
  struct entity *(src) = malloc(sizeof(struct entity));
  struct entity *(dst) = malloc(sizeof(struct entity));
  char *(buf) = malloc(12);
  src->id = 42;
  src->x = 1.5;
  src->y = 2.5;
  entity_serialize(src, buf);
  entity_deserialize(dst, buf);
  printf("id:  src=%d dst=%d match=%d\n", src->id, dst->id, ((src->id) == (dst->id)));
  printf("x:   src=%.1f dst=%.1f match=%d\n", src->x, dst->x, ((src->x) == (dst->x)));
  printf("y:   src=%.1f dst=%.1f match=%d\n", src->y, dst->y, ((src->y) == (dst->y)));
  src->id = -1;
  src->x = 0.0;
  src->y = -3.14;
  entity_serialize(src, buf);
  entity_deserialize(dst, buf);
  printf("neg_id:  src=%d dst=%d match=%d\n", src->id, dst->id, ((src->id) == (dst->id)));
  printf("zero_x:  src=%.1f dst=%.1f match=%d\n", src->x, dst->x, ((src->x) == (dst->x)));
  printf("neg_y:   src=%.2f dst=%.2f match=%d\n", src->y, dst->y, ((src->y) == (dst->y)));
  src->id = 2147483647;
  src->x = 0.0;
  src->y = 0.0;
  entity_serialize(src, buf);
  entity_deserialize(dst, buf);
  printf("max_id:  src=%d dst=%d match=%d\n", src->id, dst->id, ((src->id) == (dst->id)));
  free(src);
  free(dst);
  free(buf);
  return (0);
}


