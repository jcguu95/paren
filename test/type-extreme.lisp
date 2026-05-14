(in-package :paren.test)

;;;
;;; Extreme type system tests + auto-generated cases
;;;
;;; 這個檔案做三件事：
;;;   1. 記錄發現的 bugs（各有對應 test）
;;;   2. 極端的 nested type 測試
;;;   3. 自動產生深層 type 組合，驗證不會 crash
;;;

(def-suite paren.type-extreme :in paren.test)
(in-suite paren.type-extreme)

;;; ─────────────────────────────────────────────────────
;;; BUG #1: fmt-string<-type 對 (:struct "name") 會 crash
;;;
;;; type? 允許 struct name 是 string，
;;; 但 fmt-string<-type 對它呼叫 (symbol-name name)，
;;; 而 string 不是 symbol → 會 error。
;;;
;;; 同樣問題存在於 :type-of。
;;; ─────────────────────────────────────────────────────

(test bug/struct-string-name
  ;; type? 承認這個 type 合法
  (is (paren::type? '(:struct "MyStruct")))
  ;; 但 fmt-string<-type 會 crash，因為 (symbol-name "MyStruct") 不合法
  ;; 修完後這個測試應該通過：
  (is (equal "struct MyStruct ~a"
             (paren::fmt-string<-type '(:struct "MyStruct")))))

(test bug/type-of-string-name
  (is (paren::type? '(:type-of "some_var")))
  ;; 同上，修完後：
  (is (equal "typeof(some_var) ~a"
             (paren::fmt-string<-type '(:type-of "some_var")))))

;;; ─────────────────────────────────────────────────────
;;; BUG #2: 測試檔案引用 compile-lsp-forms 和 .lsp 副檔名
;;;
;;; 在 paren.test.lisp 第 1051 行呼叫 paren::compile-lsp-forms，
;;; 但這個函數在 compile.lisp 裡已改名為 compile-parenc-forms。
;;; 同樣，compilation-difference? 測試引用 .lsp 檔案，
;;; 但 examples/ 下現在是 .parenc。
;;; ─────────────────────────────────────────────────────

(test bug/compile-fn-name
  ;; compile-parenc-forms 應該存在
  (is (fboundp 'paren::compile-parenc-forms))
  ;; compile-lsp-forms 不應該存在（已刪除），但目前 test 還在引用它
  ;; 如果你修了，把這個 is 改成 (is (not (fboundp 'paren::compile-lsp-forms)))
  )

;;; ─────────────────────────────────────────────────────
;;; 極端 nested types（全部來自 cdecl.org 或 C 書籍）
;;; ─────────────────────────────────────────────────────

(test extreme/function-pointer-returning-function-pointer
  ;; C: int (*(*foo)(int))(char)
  ;; foo is pointer to function(int) returning pointer to function(char) returning int
  (is (equal
       "int (*((*(~a)) (int))) (char)"
       (paren::fmt-string<-type
        '(:pointer
          (:function
           (:pointer (:function :int (:char)))
           (:int))))))
  ;; 用在宣告裡
  (is (equal
       "int (*((*(foo)) (int))) (char)"
       (format nil
               (paren::fmt-string<-type
                '(:pointer
                  (:function
                   (:pointer (:function :int (:char)))
                   (:int))))
               "foo"))))

(test extreme/array-of-funcptrs
  ;; C: void (*callbacks[16])(int, void*)
  ;; callbacks is array[16] of pointer to function(int, void*) returning void
  (is (equal
       "void (*((~a)[16])) (int,void *)"
       (paren::fmt-string<-type
        '(:array 16 (:pointer (:function :void (:int (:pointer :void))))))))
  (is (equal
       "void (*((callbacks)[16])) (int,void *)"
       (format nil
               (paren::fmt-string<-type
                '(:array 16 (:pointer (:function :void (:int (:pointer :void))))))
               "callbacks"))))

;; NOTE: 上面兩個 is 已確認與 compiler 輸出一致。

(test extreme/pointer-to-array-of-funcptrs
  ;; C: int (**(*foo)[8])(double)
  ;; foo is pointer to array[8] of pointer to pointer to function(double) returning int
  (is (equal
       "int (*(*((*(~a))[8]))) (double)"
       (paren::fmt-string<-type
        '(:pointer
          (:array 8
           (:pointer
            (:pointer
             (:function :int (:double))))))))))

(test extreme/const-volatile-funcptr
  ;; C: const volatile int (* const volatile (*foo)())[3]
  ;; foo is pointer to function() returning const volatile pointer to array[3] of const volatile int
  (is (equal
       "const volatile int (*const volatile ((*(~a)) ()))[3]"
       (paren::fmt-string<-type
        '(:pointer
          (:function
           (:cv-pointer (:array 3 :cv-int))
           ()))))))

(test extreme/deeply-nested-5-levels
  ;; array of pointer to array of pointer to function returning pointer to int
  ;; C: int *((*((*((*(foo)[]))[])))())
  (is (equal
       "int *((*((*((~a)[]))[])) ())"
       (paren::fmt-string<-type
        '(:array ()
          (:pointer
           (:array ()
            (:pointer
             (:function
              (:pointer :int)
              ())))))))))

(test extreme/signal-function-type
  ;; The famous signal() function type:
  ;; void (*signal(int, void (*)(int)))(int)
  ;;
  ;; signal is function(int, pointer-to-function(int) returning void)
  ;;         returning pointer-to-function(int) returning void
  ;;
  ;; In parenc:
  (is (equal
       "void (*((~a) (int,void (*) (int)))) (int)"
       (paren::fmt-string<-type
        '(:function
          (:pointer (:function :void (:int)))
          (:int (:pointer (:function :void (:int)))))))))

;;; ─────────────────────────────────────────────────────
;;; 自動產生的 type 組合測試
;;;
;;; 這裡用 CL 在執行期生成大量 type，驗證：
;;;   1. type? 回傳真
;;;   2. fmt-string<-type 不 crash
;;;   3. 結果是包含 "~a" 的 string
;;; ─────────────────────────────────────────────────────

(defun gen-all-types (max-depth)
  "Generate all type S-expressions up to MAX-DEPTH nesting.
   Returns a list of (type description) pairs."
  (let ((base-types '(:int :char :float :double :void :uint :uchar :short))
        (result '()))

    (labels
        ((gen (depth)
           (when (= depth 0)
             (return-from gen base-types))
           (let ((subtypes (gen (1- depth))))
             (append
              base-types
              ;; pointer
              (mapcar (lambda (t1) `(:pointer ,t1))   subtypes)
              ;; pointer with count
              (mapcar (lambda (t1) `(:pointer ,t1 2)) subtypes)
              (mapcar (lambda (t1) `(:pointer ,t1 3)) subtypes)
              ;; array (no length)
              (mapcar (lambda (t1) `(:array () ,t1))  subtypes)
              ;; array (fixed length)
              (mapcar (lambda (t1) `(:array 4 ,t1))   subtypes)
              ;; function returning subtype, no args
              (mapcar (lambda (t1) `(:function ,t1 ())) subtypes)
              ;; function returning subtype, one int arg
              (mapcar (lambda (t1) `(:function ,t1 (:int))) subtypes)
              ;; function with subtype arg, returning int
              (mapcar (lambda (t1) `(:function :int (,t1))) subtypes)))))

      (loop :for type :in (gen max-depth)
            :do (push type result)))
    result))

(test auto/type?-never-crashes
  "Every generated type should pass type?."
  (loop :for type :in (gen-all-types 2)
        :do (is (paren::type? type)
                "type? failed for: ~s" type)))

(test auto/fmt-string-never-crashes
  "Every generated type should produce a string containing ~~a."
  (loop :for type :in (gen-all-types 2)
        :do (let ((result (paren::fmt-string<-type type)))
              (is (stringp result)
                  "fmt-string<-type returned non-string for: ~s" type)
              (is (search "~a" result)
                  "fmt-string<-type result missing ~~a for: ~s → ~s" type result))))

(test auto/resolve-declaration-never-crashes
  "Every generated type should work in a declaration."
  (loop :for type :in (gen-all-types 2)
        :do (let ((result (paren::resolve-declaration `(foo ,type))))
              (is (stringp result)
                  "resolve-declaration crashed for: ~s" type)
              (is (search "foo" result)
                  "resolve-declaration missing var name for: ~s → ~s" type result))))

(test auto/depth-3-spot-check
  "Depth-3 types: just verify no crashes, too many to enumerate."
  (let ((types (gen-all-types 3)))
    (format t "~%Testing ~a depth-3 type combinations...~%" (length types))
    (loop :for type :in types
          :do (handler-case
                  (paren::fmt-string<-type type)
                (error (e)
                  (fail "fmt-string<-type crashed on ~s:~%~a" type e))))))
