# PAREN/C

**S-expressions that compile to C — with Common Lisp as the macro engine.**

Write C with Lisp syntax. Use full Common Lisp at compile time to generate, transform, and abstract over any C pattern. No preprocessor tricks, no UB, no separate build step.

```lisp
;; This IS the program. The LISP block runs at compile time.
(LISP
  (defun def-safe-minmax (type)
    (let ((s (symbol-name type)))
      `(progn
         (defun (,(intern (format nil "~a_MAX" s)) ,type) ((a ,type) (b ,type))
           (return (? (> a b) a b)))
         (defun (,(intern (format nil "~a_MIN" s)) ,type) ((a ,type) (b ,type))
           (return (? (< a b) a b))))))
  `(progn
     ,(def-safe-minmax :int)
     ,(def-safe-minmax :float)
     ,(def-safe-minmax :double)))
```

Generates nine correct, type-safe C functions. No `#define MAX(a,b)`, no `x++` evaluated twice, no `typeof` extension.

See [`examples/showcase/`](examples/showcase/) for more: generic containers, state machines from a transition table, X-Macro replacement, Emacs-style DEFUN, auto-serialization.

The [`examples/sectorlisp.parenc`](examples/sectorlisp.parenc) ports the complete [SectorLisp](https://justine.lol/sectorlisp/) interpreter — a Turing-complete LISP that fits in a boot sector — and [`examples/sectorlisp-macro.parenc`](examples/sectorlisp-macro.parenc) rebuilds it so a single data table drives both the `#define` constants and the entire dispatch function.

All examples are compiled and run as part of the test suite (3163 checks, 100% pass).

---

## Symbol Case Rules

PAREN/C inherits Common Lisp's reader, which **uppercases all unquoted symbols by default**. The compiler then applies `invert-case`:

| Rule | Example in `.parenc` | C output |
|------|----------------------|----------|
| All-lowercase source → CL upcases → invert-case lowercases | `hello-world` | `hello_world` |
| All-uppercase source → CL keeps uppercase → invert-case lowercases | `HELLO_WORLD` | `hello_world` |
| Mixed-case with `\|bars\|` → exact, no conversion | `\|myFunc\|` | `myFunc` |
| `-` always becomes `_` | `my-var` | `my_var` |

**The practical rule:** write lowercase in `.parenc` source; use `|bars|` when you need a specific case (e.g., `|kT|` → `kT`, `|INT_NODE|` → `int_node`).

```lisp
;; These all produce "my_function" in C:
my-function         ; CL reader: MY-FUNCTION → invert-case → my_function
MY-FUNCTION         ; CL reader: MY-FUNCTION → invert-case → my_function

;; Use bars for exact control:
|myFunction|        ; CL reader: myFunction  → invert-case → myFunction (mixed = unchanged)
|MY_FUNCTION|       ; CL reader: MY_FUNCTION → invert-case → my_function
```

---

## Usage

```common-lisp
CL-USER> (asdf:test-system "paren" :force t)  ; loads, compiles, tests

CL-USER> (in-package :paren)
PAREN> (c '(defun (main :int) ()
             (@printf (str "Hello, world!"))
             (return 0)))
;=> "int main () {
;     printf(\"Hello, world!\");
;     return (0);
;   }"
```

The `LISP` operator runs arbitrary Common Lisp at compile time and splices the result back as PAREN/C:

```lisp
;; examples/nested-loops.parenc
(include :system ("stdio.h"))

(defun (main :int) ()
  (LISP
    (defun multi-for (bindings body)
      (loop :for binding :in (reverse bindings)
            :do (setf body `((for ((declare () (,(nth 0 binding) :int) 0)
                                   (< ,(nth 0 binding) ,(nth 1 binding))
                                   (++ ,(nth 0 binding)))
                              ,@body))))
      (car body))
    (multi-for '((i 3) (j 2) (k 2))
               '((@printf (str "%d ") (+ i j k)))))
  (return 0))
```

---

## State of the Project

Active development. Not production-ready. Contributions welcome — see `TODO.md`.
