# PAREN/C Language Reference

S-expressions that compile to C. Every form is either a literal, a symbol, or `(operator arg...)`. The canonical test for this document is [`test/spec.lisp`](test/spec.lisp) — if a test passes, the behaviour described here is correct.

A minimal complete program:

```lisp
(include :system ("stdio.h"))

(defun (main :int) ()
  (@printf (str "hello, world\n"))
  (return 0))
```
```c
#include <stdio.h>

int main () {
  printf("hello, world\n");
  return (0);
}
```

---

## 1. Symbols and Case

The CL reader uppercases all unquoted symbols by default. PAREN/C then applies `invert-case`: all-uppercase → lowercase, all-lowercase → uppercase, mixed → unchanged. Hyphens become underscores.

| Source | C output | Note |
|--------|----------|------|
| `hello-world` | `hello_world` | normal case |
| `\|kT\|` | `kT` | mixed → exact |
| `\|INT_NODE\|` | `int_node` | all-upper → lower |
| `\|err_ok\|` | `ERR_OK` | all-lower → upper |

**Practical rule:** write lowercase in `.parenc`; use `|bars|` for exact case.

---

## 2. Types

Types appear wherever C needs a type: `declare`, `defun` parameters, `defstruct` fields.

| PAREN/C | C |
|---|---|
| `:int` `:char` `:float` `:double` `:void` | `int` `char` `float` `double` `void` |
| `(:pointer :int)` | `int *` |
| `(:pointer :int 2)` | `int **` |
| `(:array 10 :int)` | `int [10]` |
| `(:array () :int)` | `int []` (unsized) |
| `(:struct :point)` | `struct point` |
| `(:pointer (:function :int (:int :char)))` | `int (*)(int, char)` |

---

## 3. Literals

```lisp
42                  →  42
3.14                →  3.14
-1                  →  -1
(str "hello")       →  "hello"
(char " ")          →  ' '
(octal-int 100000)  →  0100000
```

---

## 4. Arithmetic and Comparison

All operators wrap both operands in parentheses to eliminate C precedence surprises.

```lisp
(+ a b)   →  ((a) + (b))       (- a b)  →  ((a) - (b))
(* a b)   →  ((a) * (b))       (/ a b)  →  ((a) / (b))
(== a b)  →  ((a) == (b))      (!= a b) →  ((a) != (b))
(< a b)   →  ((a) < (b))       (> a b)  →  ((a) > (b))
(and a b) →  ((a) && (b))      (or a b) →  ((a) || (b))
(not a)   →  (!(a))

(++ x :pre)  →  (++(x))     ; prefix
(++ x)       →  ((x)++)     ; postfix
(-- x :pre)  →  (--(x))
(-- x)       →  ((x)--)

(? (> a b) a b)  →  ((((a) > (b))) ? (a) : (b))
(set x 42)       →  x = 42
```

---

## 5. Memory and Pointers

```lisp
(& x)        →  &x
(deref p)    →  *p
(@ arr i)    →  arr[i]
(-> p field) →  p->field
```

---

## 6. Function Calls

Prefix the function name with `@` to call a C function.

```lisp
(@printf (str "%d\n") x)  →  printf("%d\n", x)
(@malloc 10)              →  malloc(10)
(sizeof :int)             →  sizeof(int)
(sizeof (:struct :foo))   →  sizeof(struct foo)
```

---

## 7. Control Flow

### return / break
```lisp
(return 0)  →  return (0);
(return)    →  return;
(break)     →  break;
```

### if / cond
```lisp
(if (> x 0) (return 1) (return -1))
```
```c
if (((x) > (0))) {
  return (1);
} else {
  return (-1);
}
```

`cond` chains multiple branches; use `t` for the default:
```lisp
(cond ((> x 0) (return 1))
      ((< x 0) (return -1))
      (t        (return 0)))
```
```c
if (((x) > (0))) {
  return (1);
} else if (((x) < (0))) {
  return (-1);
} else {
  return (0);
}
```

### while / for
```lisp
(while (> n 0) (-- n :pre))
```
```c
while (((n) > (0))) {
  (--(n));
}
```

```lisp
(for ((declare () (i :int) 0) (< i 10) (++ i :pre))
     (@printf (str "%d") i))
```
```c
for (int i = 0; ((i) < (10)); (++(i))) {
  printf("%d", i);
}
```

### case (switch)
Use `t` for the default branch.
```lisp
(case x
  (0 (return 1))
  (t (return 0)))
```
```c
switch (x) {
  case 0:
    return (1);
    break;
  default:
    return (0);
    break;
}
```

---

## 8. Declarations

```
(declare storage-class (name type) init ...)
```

`storage-class`: `()` = auto, `:static`, `:extern`, `:register`.  
`init`: `()` = declare without initialising.

```lisp
(declare () (x :int) 0)           →  int x = 0;
(declare () (x :int) ())          →  int x;
(declare :static (n :int) 0)      →  static int n = 0;
(declare :extern (buf (:array () :char)) ())  →  extern char (buf)[];
```

Multiple pairs expand into separate declarations:
```lisp
(declare () (a :int) 0 (b :float) 1.0)
```
```c
int a = 0;
float b = 1.0;
```

---

## 9. Function Definitions

```
(defun (name return-type) ((param type) ...) body...)
```

```lisp
(defun (add :int) ((a :int) (b :int))
  (return (+ a b)))
```
```c
int add (int a, int b) {
  return (((a) + (b)));
}
```

Pointer return and pointer parameters:
```lisp
(defun (next (:pointer :int)) ((p (:pointer :int)))
  (return (+ p 1)))
```
```c
int *(next) (int *(p)) {
  return (((p) + (1)));
}
```

---

## 10. struct, enum, typedef

```lisp
(defstruct point ((x :int) (y :int)))
```
```c
struct point {
  int x;
  int y;
};
```

```lisp
(enum () (red green blue))          →  enum { red, green, blue };
(enum |Color| (red green blue))     →  enum Color { red, green, blue };
```

```lisp
(deftype (:keyword :int) my-int)    →  typedef int my_int;
```

---

## 11. Preprocessor

```lisp
(include :system ("stdio.h"))   →  #include <stdio.h>
(include :local  ("mylib.h"))   →  #include "mylib.h"

(define MAX 100 PI 3)
```
```c
#define MAX 100
#define PI 3
```

```lisp
(defmacro square (x) (* x x))
```
```c
#define square(x) \
((x) * (x));
```

```lisp
(undefmacro square)  →  #undef square
```

---

## 12. The LISP Operator

`(lisp expr)` evaluates `expr` as Common Lisp **at compile time** and splices the result back as a PAREN/C form. This is the primary metaprogramming mechanism — not a macro system bolted on, but full Common Lisp available during compilation.

Simple use: compute something at compile time.
```lisp
(lisp (list 'return 42))   →   return (42);
```

Generate a family of functions from a loop:
```lisp
(include :system ("stdio.h"))

(lisp
  (defun def-printer (type fmt)
    `(defun (,(intern (format nil "PRINT-~a" type)) :void)
            ((x ,type))
       (@printf (str ,fmt) x)))
  `(progn
     ,(def-printer :int  "%d\n")
     ,(def-printer :float "%f\n")))

(defun (main :int) ()
  (@print-int   42)
  (@print-float 3.14)
  (return 0))
```
```c
#include <stdio.h>

void print_int (int x) {
  printf("%d\n", x);
}

void print_float (float x) {
  printf("%f\n", x);
}

int main () {
  print_int(42);
  print_float(3.14);
  return (0);
}
```

The `lisp` block returns a single PAREN/C form. To emit multiple top-level forms, return a `progn`:

```lisp
(lisp `(progn
         (declare () (a :int) 1)
         (declare () (b :int) 2)))
```
```c
int a = 1;

int b = 2;
```

See [`examples/showcase/`](examples/showcase/) for larger examples: generic containers, state machines, Emacs-style DEFUN.
