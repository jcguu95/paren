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
  head = int_push(head, 10);
  head = int_push(head, 20);
  head = int_push(head, 30);
  struct int_node *(p) = head;
  while (p) {
    printf("int: %d\n", p->value);
    p = p->next;
  }
  int_free(head);
  struct float_node *(fhead) = 0;
  fhead = float_push(fhead, 1.5);
  fhead = float_push(fhead, 2.5);
  struct float_node *(fp) = fhead;
  while (fp) {
    printf("float: %.1f\n", fp->value);
    fp = fp->next;
  }
  float_free(fhead);
  return (0);
}


