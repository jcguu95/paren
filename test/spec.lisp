(in-package :paren.test)

;;; PAREN/C Language Specification
;;;
;;; 每一個 (is (equal (c '...) "...")) 同時是規格說明和可執行測試。
;;; 如果測試通過，規格就是正確的。如果語言行為改變，測試會失敗。
;;;
;;; 執行方式：(asdf:test-system :paren)

(def-suite paren.spec :in paren.test)
(in-suite paren.spec)

;;; ── 1. 符號與大小寫 ────────────────────────────────────────────────────────
;;;
;;; 規則：CL reader 預設把所有符號轉大寫；invert-case 再把全大寫轉小寫。
;;; 實際效果：在 .parenc 裡寫小寫 → C 輸出小寫；-  → _。

(test spec/symbols
  ;; 一般小寫符號（CL reader 轉大寫後 invert-case 再轉回小寫）
  (is (equal (c 'hello)      "hello"))
  (is (equal (c 'hello-world) "hello_world"))
  (is (equal (c 'my-var)     "my_var"))

  ;; 用 |bars| 精確控制大小寫
  (is (equal (c '|kT|)        "kT"))        ; 混合 → 原樣
  (is (equal (c '|myFunc|)    "myFunc"))    ; 混合 → 原樣
  (is (equal (c '|INT_NODE|)  "int_node"))  ; 全大寫 → 小寫
  (is (equal (c '|err_ok|)    "ERR_OK")))   ; 全小寫 → 大寫

;;; ── 2. 型別系統 ────────────────────────────────────────────────────────────
;;;
;;; 型別用 keyword 表示，複合型別用 list。
;;; 在 declare、defun 參數等需要型別的地方直接寫：
;;;
;;;   :int                      →  int
;;;   (:pointer :int)           →  int *
;;;   (:pointer :int 3)         →  int ***（三層指標）
;;;   (:array 10 :int)          →  int [10]
;;;   (:array () :int)          →  int []（不定長）
;;;   (:struct :point)          →  struct point
;;;   (:function :int (:int :char))  →  回傳 int、接受 (int, char) 的函數型別

(test spec/types
  ;; 基本型別：(declare () (變數名 型別) 初始值)
  (is (equal (c '(declare () (x :int)    0))  "int x = 0;"))
  (is (equal (c '(declare () (c :char)   0))  "char c = 0;"))
  (is (equal (c '(declare () (f :float)  0))  "float f = 0;"))
  (is (equal (c '(declare () (d :double) 0))  "double d = 0;"))

  ;; 指標
  (is (equal (c '(declare () (p  (:pointer :int))   ()))  "int *(p);"))
  (is (equal (c '(declare () (pp (:pointer :int 2)) ()))  "int **(pp);"))
  (is (equal (c '(declare () (ppp (:pointer :int 3)) ())) "int ***(ppp);"))

  ;; 陣列
  (is (equal (c '(declare () (a  (:array 10 :int)) ())) "int (a)[10];"))
  (is (equal (c '(declare () (a  (:array () :int)) ())) "int (a)[];"))

  ;; struct
  (is (equal (c '(declare () (pt (:struct :point)) ())) "struct point pt;"))

  ;; 函數指標：(:pointer (:function 回傳型別 (參數型別...)))
  (is (equal (c '(declare () (fn (:pointer (:function :int (:int :char)))) ()))
             "int (*(fn)) (int,char);"))

  ;; defun 參數中的型別用法（函數簽名即文件）
  (is (equal (c '(defun (scale (:pointer :int)) ((p (:pointer :int)) (n :int))
                    (return p)))
             "int *(scale) (int *(p), int n) {
  return (p);
}")))

;;; ── 3. 字面值 ──────────────────────────────────────────────────────────────

(test spec/literals
  ;; 數字直接輸出
  (is (equal (c 42)    "42"))
  (is (equal (c 3.14)  "3.14"))
  (is (equal (c -1)    "-1"))

  ;; 字串（str 加引號）
  (is (equal (c '(str "hello"))   "\"hello\""))
  (is (equal (c '(str "%d\\n"))   "\"%d\\n\""))

  ;; 字元
  (is (equal (c '(char " "))  "' '"))
  (is (equal (c '(char ")"))  "')'"))

  ;; 八進位整數
  (is (equal (c '(octal-int 100000)) "0100000")))

;;; ── 4. 算術與比較運算子 ───────────────────────────────────────────────────
;;;
;;; 所有運算子都加括號保護，避免 precedence 問題。

(test spec/arithmetic
  (is (equal (c '(+ a b))   "((a) + (b))"))
  (is (equal (c '(- a b))   "((a) - (b))"))
  (is (equal (c '(* a b))   "((a) * (b))"))
  (is (equal (c '(/ a b))   "((a) / (b))"))
  (is (equal (c '(== a b))  "((a) == (b))"))
  (is (equal (c '(!= a b))  "((a) != (b))"))
  (is (equal (c '(< a b))   "((a) < (b))"))
  (is (equal (c '(> a b))   "((a) > (b))"))
  (is (equal (c '(<= a b))  "((a) <= (b))"))
  (is (equal (c '(>= a b))  "((a) >= (b))"))
  (is (equal (c '(and a b)) "((a) && (b))"))
  (is (equal (c '(or a b))  "((a) || (b))"))
  (is (equal (c '(not a))   "(!(a))"))

  ;; 前置 ++/--（:pre 表示前置）
  (is (equal (c '(++ x :pre)) "(++(x))"))
  (is (equal (c '(-- x :pre)) "(--(x))"))
  ;; 後置 ++/--（無 :pre）
  (is (equal (c '(++ x))     "((x)++)"))
  (is (equal (c '(-- x))     "((x)--)"))

  ;; 三元運算子
  (is (equal (c '(? (> a b) a b)) "((((a) > (b))) ? (a) : (b))"))

  ;; 賦值（set）— 同時是 expression，會自動加分號
  (is (equal (c '(set x 42)) "x = 42")))

;;; ── 5. 記憶體與指標 ───────────────────────────────────────────────────────

(test spec/pointers
  ;; 取址
  (is (equal (c '(& x))       "&x"))
  ;; 解參考
  (is (equal (c '(deref p))   "*p"))
  ;; 陣列索引
  (is (equal (c '(@ arr i))   "arr[i]"))
  ;; struct 成員（->）
  (is (equal (c '(-> p field)) "p->field")))

;;; ── 6. 函數呼叫 ────────────────────────────────────────────────────────────
;;;
;;; @name 前綴：呼叫 C 函數（去掉 @ 後就是函數名）。

(test spec/function-calls
  (is (equal (c '(@printf (str "%d") x))  "printf(\"%d\", x)"))
  (is (equal (c '(@malloc 10))            "malloc(10)"))
  (is (equal (c '(@sizeof x))             "sizeof(x)"))
  ;; sizeof 型別（新增的 cop）
  (is (equal (c '(sizeof :int))            "sizeof(int)"))
  (is (equal (c '(sizeof (:struct :foo)))  "sizeof(struct foo)")))

;;; ── 7. 流程控制 ────────────────────────────────────────────────────────────

(test spec/control-flow
  ;; return
  (is (equal (c '(return 0))   "return (0);"))
  (is (equal (c '(return))     "return;"))

  ;; if（展開成 cond）
  (is (equal (c '(if (> x 0) (return 1) (return -1)))
             "if (((x) > (0))) {
  return (1);
} else {
  return (-1);
}"))

  ;; cond（if/else if/else 鏈）
  (is (equal (c '(cond ((> x 0) (return 1))
                       (t       (return 0))))
             "if (((x) > (0))) {
  return (1);
} else {
  return (0);
}"))

  ;; while
  (is (equal (c '(while (> n 0) (-- n :pre)))
             "while (((n) > (0))) {
  (--(n));
}"))

  ;; break
  (is (equal (c '(break)) "break;"))

  ;; case（switch）
  (is (equal (c '(case x
                   (0 (return 1))
                   (t (return 0))))
             "switch (x) {
  case 0:
    return (1);
    break;
  default:
    return (0);
    break;
}"))

  ;; for
  (is (equal (c '(for ((declare () (i :int) 0) (< i 10) (++ i :pre))
                      (@printf (str "%d") i)))
             "for (int i = 0; ((i) < (10)); (++(i))) {
  printf(\"%d\", i);
}")))

;;; ── 8. 宣告 ────────────────────────────────────────────────────────────────

(test spec/declare
  ;; 單一變數宣告（storage-class 為 nil/() 表示 auto）
  (is (equal (c '(declare () (x :int) 0))       "int x = 0;"))
  (is (equal (c '(declare () (x :int) ()))      "int x;"))
  (is (equal (c '(declare :static (n :int) 0))  "static int n = 0;"))

  ;; 多變數（每對展開成獨立宣告）
  (is (equal (c '(declare () (a :int) 0 (b :float) 1.0))
             "int a = 0;
float b = 1.0;")))

;;; ── 9. 函數定義 ────────────────────────────────────────────────────────────
;;;
;;; (defun (name return-type) ((param1 type1) ...) body...)

(test spec/defun
  (is (equal (c '(defun (add :int) ((a :int) (b :int))
                    (return (+ a b))))
             "int add (int a, int b) {
  return (((a) + (b)));
}"))

  ;; void 函數
  (is (equal (c '(defun (greet :void) ()
                    (@printf (str "hi"))))
             "void greet () {
  printf(\"hi\");
}"))

  ;; 回傳指標型別
  (is (equal (c '(defun (next (:pointer :int)) ((p (:pointer :int)))
                    (return (+ p 1))))
             "int *(next) (int *(p)) {
  return (((p) + (1)));
}")))

;;; ── 10. struct / enum 定義 ─────────────────────────────────────────────────

(test spec/struct-enum
  ;; defstruct
  (is (equal (c '(defstruct point ((x :int) (y :int))))
             "struct point {
  int x;
  int y;
};"))

  ;; enum（匿名 — 第一個引數是名稱，用 () 表示匿名）
  (is (equal (c '(enum () (a b c)))
             "enum { a, b, c };"))

  ;; typedef
  (is (equal (c '(deftype (:keyword :int) my-int))
             "typedef int my_int;")))

;;; ── 11. 前置處理器 ─────────────────────────────────────────────────────────

(test spec/preprocessor
  ;; #include
  (is (equal (c '(include :system ("stdio.h")))
             "#include <stdio.h>"))
  (is (equal (c '(include :local ("mylib.h")))
             "#include \"mylib.h\""))

  ;; #define（define 接受 key-value 對）
  (is (equal (c '(define foo 42 bar 100))
             (format nil "#define foo 42~%#define bar 100~%")))

  ;; #define macro（展開成帶 backslash continuation 的 C macro）
  (is (equal (c '(defmacro square (x) (* x x)))
             (format nil "#define square(x) \\~%((x) * (x));")))

  ;; #undef
  (is (equal (c '(undefmacro square))
             "#undef square")))

;;; ── 12. LISP 運算子（編譯期展開）─────────────────────────────────────────
;;;
;;; LISP 運算子讓 Common Lisp 在編譯期執行並回傳 PAREN/C form。
;;; 回傳的 form 再被編譯成 C。

(test spec/lisp-operator
  ;; 直接回傳一個 PAREN/C form
  (is (equal (c '(lisp (list 'return 42)))
             "return (42);"))

  ;; 用 CL 生成重複程式碼
  (is (equal (c '(lisp
                  (cons 'progn
                        (loop :for i :from 1 :to 3
                              :collect `(declare () (,(intern (format nil "X~a" i)) :int) ,i)))))
             (format nil "int x1 = 1;~%~%int x2 = 2;~%~%int x3 = 3;")))

  ;; progn：多個 form 並列
  (is (equal (c '(progn
                   (declare () (a :int) 1)
                   (declare () (b :int) 2)))
             (format nil "int a = 1;~%~%int b = 2;"))))
