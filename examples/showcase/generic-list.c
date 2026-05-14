#include <stdlib.h>

#include <stdio.h>

struct int_node {
  int value;
  struct int_node *(next);
};

struct int_node *(int_push) (struct int_node *(head), int value) {
  struct int_node *(n) = malloc(sizeof(struct int_node));
  n->value = value;
  n->next = head;
  return (n);
}

void int_free (struct int_node *(head)) {
  while (head) {
    struct int_node *(tmp) = head->next;
    free(head);
    head = tmp;
  }
}

struct float_node {
  float value;
  struct float_node *(next);
};

struct float_node *(float_push) (struct float_node *(head), float value) {
  struct float_node *(n) = malloc(sizeof(struct float_node));
  n->value = value;
  n->next = head;
  return (n);
}

void float_free (struct float_node *(head)) {
  while (head) {
    struct float_node *(tmp) = head->next;
    free(head);
    head = tmp;
  }
}

struct double_node {
  double value;
  struct double_node *(next);
};

struct double_node *(double_push) (struct double_node *(head), double value) {
  struct double_node *(n) = malloc(sizeof(struct double_node));
  n->value = value;
  n->next = head;
  return (n);
}

void double_free (struct double_node *(head)) {
  while (head) {
    struct double_node *(tmp) = head->next;
    free(head);
    head = tmp;
  }
}

int main () {
  struct int_node *(head) = 0;
  head = int_push(head, 1);
  head = int_push(head, 2);
  head = int_push(head, 3);
  printf("list: %d %d %d\n", head->value, head->next->value, head->next->next->value);
  int_free(head);
  return (0);
}


