(in-package :paren)

(defun read-file-into-list (file-path)
  "Reads a string from a file and parses it into a Lisp list."
  (with-open-file (stream file-path :direction :input)
    (let ((file-contents (make-string (file-length stream))))
      (read-sequence file-contents stream)
      (read-from-string (format nil "(~a)" file-contents)))))

(defun replace-file-extension (file-path new-extension)
  "Replaces the file extension of FILE-PATH with NEW-EXTENSION."
  (let* ((pathname (parse-namestring file-path))
         (new-pathname (make-pathname :name (pathname-name pathname)
                                      :type new-extension
                                      :defaults pathname)))
    (namestring new-pathname)))

(defun compile-lsp-file (file-path)
  (with-open-file
      (out-stream (replace-file-extension file-path "c")
                  :direction :output
                  :if-exists :supersede)
    (write-line
     (format nil "// Paren autogenerated this file on ~A.~%" (local-time:now))
     out-stream)
    (write-line
     (with-output-to-string (stream)
       (let ((forms (read-file-into-list file-path)))
         (loop :for form :in forms
               :for k :from 1
               :do (format stream "~a" (c form))
               :do (when (< k (length forms))
                     (format stream "~%~%")))))
     out-stream
     )))

(compile-lsp-file "./examples/hello-world.lsp")
(compile-lsp-file "./examples/switch.lsp")
(compile-lsp-file "./examples/cond.lsp")
(compile-lsp-file "./examples/control-flow.lsp")
(compile-lsp-file "./examples/macro-example.lsp")
(compile-lsp-file "./examples/type-struct-example.lsp")
(compile-lsp-file "./examples/higher-order-function.lsp")

;; NOTE TODO Need to first implement preprocessor directives, and then the cop
;; `let` in the file.
;;
(compile-lsp-file "./examples/c-macro.lsp")

;; NOTE TODO Need to implement lisp interopt first:
;; (compile-lsp-file "./examples/nested-loops.lsp")
;; (compile-lsp-file "./examples/macro-example.lsp")
