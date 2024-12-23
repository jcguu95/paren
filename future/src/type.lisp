(in-package :paren)

;; TODO Redo for the type system: Basic types are represented as keywords,
;; while composed types are represented as lists whose cars are of the
;; following: :pointer, :function, :struct, :array.

;; TODO The users can write instead :pointer, :function, :(), :{}, :[]
;; respectively, but a normalizer will transform it into the canonical, longer
;; forms. Write util functions to handle and inspect types. Allow users to
;; define more type operators (e.g. :pointer :function as above).

;; TODO Finally, write a printer, and integrate that with SET and DECLARE.
;; Mention that the type system is by no means complete, yet the user can
;; inline any C codes so that's not a problem.

;; TODO Change syntax from (:array () :int) to (:array :int)

;; TODO Support `volatile pointer`. (an example from https://cdecl.org/):
;; declare bar as volatile pointer to array 64 of const int
;;
;; const int (* volatile bar)[64]

;; TODO Support `cast`. An example from https://cdecl.org/: cast foo into
;; block(int, long long) returning double
;;
;; (double (^)(int , long long ))foo

(defun type? (form)
  (if (keywordp form)
      form
      (let ((kind (car form)))
        (case kind
          (:pointer
           (let ((subtype (nth 1 form))
                 (pointer-count (nth 2 form)))
             (and (<= 2 (length form) 3)
                  (or (null pointer-count)
                      (and
                       (integerp pointer-count)
                       (> pointer-count 0)))
                  (type? subtype)
                  kind)))
          (:function
           (let ((to-type (nth 1 form))
                 (from-types (nth 2 form)))
             (and (= 3 (length form))
                  (type? to-type)
                  (every #'type? from-types)
                  kind)))
          (:struct
           (let ((name (nth 1 form)))
             (and (= 2 (length form))
                  (or (stringp name)
                      (keywordp name)) ; TODO better error message for failure
                  kind)))
          (:array
           (let ((length (nth 1 form))
                 (subtype (nth 2 form)))
             (and (= 3 (length form))
                  (or (null length)
                      (and (> length 0)
                           (integerp length)))
                  (type? subtype)
                  kind)))))))

(defun fmt-string<-type (type &optional no-filler)
  (assert (type? type))
  (let ((kind (type? type)))
    (case kind
      (:pointer
       (let ((subtype (nth 1 type))
             (pointer-count (nth 2 type)))
         (unless pointer-count
           (setf pointer-count 1))
         (format nil
                 (fmt-string<-type subtype)
                 (if no-filler
                     (format nil "~{~a~}"
                             (make-list pointer-count :initial-element '*))
                     (format nil "~{~a~}(~~a)"
                             (make-list pointer-count :initial-element '*))))))
      (:function
          (let ((to-type (nth 1 type))
                (from-types (nth 2 type)))
            (format nil
                    (fmt-string<-type to-type)
                    (if no-filler
                        (format nil "(~{~a,~})"
                                (loop :for type :in from-types
                                      :collect (fmt-string<-type type t)))
                        (format nil "(~~a)(~{~a~^,~})"
                                (loop :for type :in from-types
                                      :collect (fmt-string<-type type t)))))))
      (:struct
       (let ((name (nth 1 type)))
         (if no-filler
             (format nil "struct ~a" name)
             (format nil "struct ~a (~~a)" name))))
      (:array
       (let ((length (nth 1 type))
             (subtype (nth 2 type)))
         (unless length (setf length ""))
         (format nil
                 (fmt-string<-type subtype)
                 (if no-filler
                     (format nil "[~a]" length)
                     (format nil "(~~a)[~a]" length)))))
      (t
       (format nil
               (if no-filler
                   "~a"
                   "~a (~~a)")
               (string-downcase (symbol-name kind)))))
    ))
