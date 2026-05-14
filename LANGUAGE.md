# PAREN/C Language Reference

S-expressions that compile to C. Every form is either a literal, a symbol, or `(operator arg...)`. The canonical test for this document is [`test/spec.lisp`](test/spec.lisp) — if a test passes, the behaviour described here is correct.

---

## 1. Symbols and Case

The CL reader uppercases all unquoted symbols by default. PAREN/C then applies `invert-case`: all-uppercase → lowercase, all-lowercase → uppercase, mixed → unchanged. Hyphens become underscores.

| Source | CL reads | C output |
|--------|----------|----------|
| `hello-world` | `HELLO-WORLD` | `hello_world` |
| `MY-VAR` | `MY-VAR` | `my_var` |
| `\|kT\|` | `kT` | `kT` |
| `\|myFunc\|` | `myFunc` | `myFunc` |
| `\|INT_NODE\|` | `INT_NODE` | `int_node` |
| `\|err_ok\|` | `err_ok` | `ERR_OK` |

**Practical rule:** write lowercase in `.parenc`; use `|bars|` when you need exact case.

---

## 2. Types

Types appear wherever C needs a type: `declare`, `defun` parameters, `defstruct` fields, etc.

| PAREN/C type | C type |
|---|---|
| `:int` | `int` |
| `:char` | `char` |
| `:float` | `float` |
| `:double` | `double` |
| `:void` | `void` |
| `(:pointer :int)` | `int *` |
| `(:pointer :int 2)` | `int **` |
| `(:pointer :int 3)` | `int ***` |
| `(:array 10 :int)` | `int [10]` |
| `(:array () :int)` | `int []` (unsized) |
| `(:struct :point)` | `struct point` |
| `(:pointer (:function :int (:int :char)))` | `int (*)(int, char)` |

```lisp
(declare () (p  (:pointer :int))   ())   ; int *(p);
(declare () (a  (:array 10 :int))  ())   ; int (a)[10];
(declare () (fn (:pointer (:function :int (:int :char)))) ())
                                         ; int (*(fn)) (int,char);
```

---

## 3. Literals

```lisp
42          →  42
3.14        →  3.14
-1          →  -1

(str "hello")    →  "hello"
(str "%d\n")     →  "%d\n"

(char " ")       →  ' '
(char ")")       →  ')'

(octal-int 100000)  →  0100000
```

---

## 4. Arithmetic and Comparison

All operators wrap both operands in parentheses to avoid C precedence surprises.

```lisp
(+ a b)   →  ((a) + (b))
(- a b)   →  ((a) - (b))
(* a b)   →  ((a) * (b))
(/ a b)   →  ((a) / (b))
(== a b)  →  ((a) == (b))
(!= a b)  →  ((a) != (b))
(< a b)   →  ((a) < (b))
(> a b)   →  ((a) > (b))
(<= a b)  →  ((a) <= (b))
(>= a b)  →  ((a) >= (b))
(and a b) →  ((a) && (b))
(or  a b) →  ((a) || (b))
(not a)   →  (!(a))

(++ x :pre)  →  (++(x))    ; prefix
(++ x)       →  ((x)++)    ; postfix
(-- x :pre)  →  (--(x))
(-- x)       →  ((x)--)

(? (> a b) a b)  →  ((((a) > (b))) ? (a) : (b))

(set x 42)  →  x = 42
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
(@printf (str "%d") x)  →  printf("%d", x)
(@malloc 10)            →  malloc(10)
(@sizeof x)             →  sizeof(x)
(sizeof :int)           →  sizeof(int)          ; PAREN/C type
(sizeof (:struct :foo)) →  sizeof(struct foo)
```

---

## 7. Control Flow

### return
```lisp
(return 0)  →  return (0);
(return)    →  return;
```

### if
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

### cond
```lisp
(cond ((> x 0) (return 1))
      (t       (return 0)))
```
```c
if (((x) > (0))) {
  return (1);
} else {
  return (0);
}
```

### while
```lisp
(while (> n 0) (-- n :pre))
```
```c
while (((n) > (0))) {
  (--(n));
}
```

### for
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

### break
```lisp
(break)  →  break;
```

---

## 8. Declarations

```
(declare storage-class (name type) init  ...)
```

`storage-class` is `()` for auto, or `:static`, `:extern`, etc.  
`init` is `()` to declare without initialising.

```lisp
(declare () (x :int) 0)         →  int x = 0;
(declare () (x :int) ())        →  int x;
(declare :static (n :int) 0)    →  static int n = 0;

;; Multiple pairs in one form:
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
(enum () (a b c))       →  enum { a, b, c };
```
Named enum: `(enum |Color| (red green blue))` → `enum Color { red, green, blue };`

```lisp
(deftype (:keyword :int) my-int)  →  typedef int my_int;
```

---

## 11. Preprocessor

```lisp
(include :system ("stdio.h"))   →  #include <stdio.h>
(include :local  ("mylib.h"))   →  #include "mylib.h"

(define foo 42 bar 100)
```
```c
#define foo 42
#define bar 100
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

`(lisp expr)` evaluates `expr` as Common Lisp at compile time and splices the result back as a PAREN/C form. This is the primary metaprogramming mechanism.

```lisp
(lisp (list 'return 42))   →  return (42);
```

Generate repetitive code with a CL loop:
```lisp
(lisp
  (cons 'progn
        (loop :for i :from 1 :to 3
              :collect `(declare () (,(intern (format nil "X~a" i)) :int) ,i))))
```
```c
int x1 = 1;

int x2 = 2;

int x3 = 3;
```

### progn

`(progn form...)` compiles multiple forms and joins them with blank lines. Typically used as the return value of a `lisp` block.

```lisp
(progn
  (declare () (a :int) 1)
  (declare () (b :int) 2))
```
```c
int a = 1;

int b = 2;
```
