/*═════════════════════════════════════════════════════════════════════════════╡
│ Copyright 2020 Justine Alexandra Roberts Tunney                              │
│                                                                              │
│ Permission to use, copy, modify, and/or distribute this software for         │
│ any purpose with or without fee is hereby granted, provided that the         │
│ above copyright notice and this permission notice appear in all copies.      │
│                                                                              │
│ THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL                │
│ WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED                │
│ WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE             │
│ AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL         │
│ DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR        │
│ PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER               │
│ TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR             │
│ PERFORMANCE OF THIS SOFTWARE.                                                │
╚─────────────────────────────────────────────────────────────────────────────*/

// NOTE [2024-12-27] Jin modified the original file by removing the dependency
// on "bestline.h," ensuring compliance with modern C standards (e.g.,
// declaring function types before use), and commenting out prompt line
// printing.

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <locale.h>
#include <limits.h>

/*───────────────────────────────────────────────────────────────────────────│─╗
│ The LISP Challenge § LISP Machine                                        ─╬─│┼
╚────────────────────────────────────────────────────────────────────────────│*/

#define kT          4
#define kQuote      6
#define kCond       12
#define kRead       17
#define kPrint      22
#define kAtom       28
#define kCar        33
#define kCdr        37
#define kCons       41
#define kEq         46

#define M (RAM + sizeof(RAM) / sizeof(RAM[0]) / 2)
#define S "NIL\0T\0QUOTE\0COND\0READ\0PRINT\0ATOM\0CAR\0CDR\0CONS\0EQ"

int cx; /* stores negative memory use */
int dx; /* stores lookahead character */
int RAM[0100000]; /* your own ibm7090 */

int AddList(int);
int GetObject(int);
int Cons(int, int);
int Car(int);
int Cdr(int);
int PrintObject(int);
int Eval(int, int);

int Intern() {
  int i, j, x;
  for (i = 0; (x = M[i++]);) {
    for (j = 0;; ++j) {
      if (x != RAM[j]) break;
      if (!x) return i - j - 1;
      x = M[i++];
    }
    while (x)
      x = M[i++];
  }
  j = 0;
  x = --i;
  while ((M[i++] = RAM[j++]));
  return x;
}

char *GetLine(const char *prompt) {
    static char buffer[1024];
    printf("%s", prompt);
    fflush(stdout);
    if (fgets(buffer, sizeof(buffer), stdin)) {
        // Strip newline character
        size_t len = strlen(buffer);
        if (len > 0 && buffer[len - 1] == '\n') {
            buffer[len - 1] = '\0';
        }
        return buffer;
    }
    return NULL;
}

void PrintChar(int b) {
    fputc(b, stdout);
}

int GetChar() {
    static char *line = NULL;
    static char *ptr = NULL;

    if (!line || !*ptr) {
        // line = GetLine("* ");
        line = GetLine("");
        if (!line) {
            // PrintChar('\n');
            exit(0);
        }
        ptr = line;
    }

    int c = *ptr++;
    int t = dx;
    dx = c;
    return t;
}

int GetToken() {
  int c, i = 0;
  do if ((c = GetChar()) > ' ') RAM[i++] = c;
  while (c <= ' ' || (c > ')' && dx > ')'));
  RAM[i] = 0;
  return c;
}

int GetList() {
  int c = GetToken();
  if (c == ')') return 0;
  return AddList(GetObject(c));
}

int GetObject(int c) {
  if (c == '(') return GetList();
  return Intern();
}

int AddList(int x) {
  return Cons(x, GetList());
}

int Read() {
  return GetObject(GetToken());
}

int PrintAtom(int x) {
  int c;
  for (;;) {
    if (!(c = M[x++])) break;
    PrintChar(c);
  }
}

int PrintList(int x) {
  PrintChar('(');
  PrintObject(Car(x));
  while ((x = Cdr(x))) {
    if (x < 0) {
      PrintChar(' ');
      PrintObject(Car(x));
    } else {
      PrintChar(L'∙');
      PrintObject(x);
      break;
    }
  }
  PrintChar(')');
}

int PrintObject(int x) {
  if (x < 0) {
    PrintList(x);
  } else {
    PrintAtom(x);
  }
}

int Print(int e) {
  PrintObject(e);
}

int PrintNewLine() {
  PrintChar('\n');
}

/*───────────────────────────────────────────────────────────────────────────│─╗
│ The LISP Challenge § Bootstrap John McCarthy's Metacircular Evaluator    ─╬─│┼
╚────────────────────────────────────────────────────────────────────────────│*/

int Car(int x) {
  return M[x];
}

int Cdr(int x) {
  return M[x + 1];
}

int Cons(int car, int cdr) {
  M[--cx] = cdr;
  M[--cx] = car;
  return cx;
}

int Gc(int x, int m, int k) {
  return x < m ? Cons(Gc(Car(x), m, k),
                      Gc(Cdr(x), m, k)) + k : x;
}

int Evlis(int m, int a) {
  if (m) {
    int x = Eval(Car(m), a);
    return Cons(x, Evlis(Cdr(m), a));
  } else {
    return 0;
  }
}

int Pairlis(int x, int y, int a) {
  return x ? Cons(Cons(Car(x), Car(y)),
                  Pairlis(Cdr(x), Cdr(y), a)) : a;
}

int Assoc(int x, int y) {
  if (!y) return 0;
  if (x == Car(Car(y))) return Cdr(Car(y));
  return Assoc(x, Cdr(y));
}

int Evcon(int c, int a) {
  if (Eval(Car(Car(c)), a)) {
    return Eval(Car(Cdr(Car(c))), a);
  } else {
    return Evcon(Cdr(c), a);
  }
}

int Apply(int f, int x, int a) {
  if (f < 0)       return Eval(Car(Cdr(Cdr(f))), Pairlis(Car(Cdr(f)), x, a));
  if (f > kEq)     return Apply(Eval(f, a), x, a);
  if (f == kEq)    return Car(x) == Car(Cdr(x)) ? kT : 0;
  if (f == kCons)  return Cons(Car(x), Car(Cdr(x)));
  if (f == kAtom)  return Car(x) < 0 ? 0 : kT;
  if (f == kCar)   return Car(Car(x));
  if (f == kCdr)   return Cdr(Car(x));
  if (f == kRead)  return Read();
  if (f == kPrint) return (x ? Print(Car(x)) : PrintNewLine()), 0;
}

int Eval(int e, int a) {
  int A, B, C;
  if (e >= 0)
    return Assoc(e, a);
  if (Car(e) == kQuote)
    return Car(Cdr(e));
  A = cx;
  if (Car(e) == kCond) {
    e = Evcon(Cdr(e), a);
  } else {
    e = Apply(Car(e), Evlis(Cdr(e), a), a);
  }
  B = cx;
  e = Gc(e, A, A - B);
  C = cx;
  while (C < B)
    M[--A] = M[--B];
  cx = A;
  return e;
}

/*───────────────────────────────────────────────────────────────────────────│─╗
│ The LISP Challenge § User Interface                                      ─╬─│┼
╚────────────────────────────────────────────────────────────────────────────│*/

int main() {
    int i;
    setlocale(LC_ALL, "");

    for (i = 0; i < sizeof(S); ++i) M[i] = S[i];
    for (;;) {
        cx = 0;
        Print(Eval(Read(), 0));
        PrintNewLine();
    }
}
