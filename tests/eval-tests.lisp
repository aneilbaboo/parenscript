;;;; -*- encoding:utf-8 -*-

;;; Copyright 2011-2012 Vladimir Sedach

;;; SPDX-License-Identifier: BSD-3-Clause

;;; Redistribution and use in source and binary forms, with or
;;; without modification, are permitted provided that the following
;;; conditions are met:

;;; 1. Redistributions of source code must retain the above copyright
;;; notice, this list of conditions and the following disclaimer.

;;; 2. Redistributions in binary form must reproduce the above
;;; copyright notice, this list of conditions and the following
;;; disclaimer in the documentation and/or other materials provided
;;; with the distribution.

;;; 3. Neither the name of the copyright holder nor the names of its
;;; contributors may be used to endorse or promote products derived
;;; from this software without specific prior written permission.

;;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
;;; CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
;;; INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
;;; MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
;;; DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
;;; BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
;;; TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
;;; DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
;;; ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
;;; OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
;;; OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
;;; POSSIBILITY OF SUCH DAMAGE.

(in-package #:parenscript.eval-tests)
(named-readtables:in-readtable :parenscript)

#+sbcl (declaim (sb-ext:muffle-conditions sb-ext:compiler-note))

(fiveam:in-suite parenscript.tests::eval-tests)

(test-js-eval number
  3
  3)

(test-js-eval float
  (< 123.12 123.123 123.124)
  t)

(test-js-eval string
  "foobar"
  "foobar")

(test-js-eval statements-and-expressions-2
  ((lambda () (if 1 2 3)))
  2)

(test-js-eval statements-and-expressions-1
  ((lambda () (+ 2 (if 1 2 3))))
  4)

(test-js-eval empty-array
  (array)
  #())

(test-js-eval funargs-let1
  ((lambda (x)
     (let ((x 10))
       (incf x))
     (incf x))
   0)
  1)

(test-js-eval times-rem
  (* 12 (rem 10 3))
  12)

(test-js-eval divide-rem
  (rem 10 (/ 12 4))
  1)

(test-js-eval rem-divide
  (/ 9 (rem 11 4))
  3)

(test-js-eval rem-multiply
  (* 5 (rem 4 3))
  5)

(test-js-eval case-return-break-null
  ((lambda (x) (case x
                 (1)
                 (2 3)))
   1)
  :null)

(test-js-eval defun-return1
  (progn (defun bar (x) (1+ x))
         (bar 1))
  2)

(test-js-eval defun-return2
  (progn (defun bar (fn)
           (funcall fn))

         (defun foo ()
           (bar (lambda () (return-from foo 123))))

         (foo))
  123)

(test-js-eval defvar
  (progn (defvar foo 1)
         foo)
  1)

(test-js-eval block-dynamic-lambda
  ((lambda () (block nil (return 4) (+ 1 2))))
  4)

(test-js-eval block-dynamic-lambda1
  ((lambda () (block nil (return 4) (+ 1 2)) 5))
  5)

(test-js-eval loop-sum
  (+ 1 (loop for i from 0 to 10 sum i))
  56)

(test-js-eval loop-funcall-sum
  ((lambda (x) (1+ x)) (loop for i from 0 to 10 sum i))
  56)

(test-js-eval loop-funcall-if-sum
  (progn (defun one-plus (x)
           (1+ x))

         (one-plus (if false 1 (loop for i from 0 to 10 sum i))))
  56)

(test-js-eval case-return-break1-broken-return
  (progn (defun foo (x y)
           (case x
             ("bar" (if y (return-from foo 1)))
             ("baz" 2)))
         (list (foo "bar" t) (foo "bar" nil) (foo "baz" nil)))
  '(1 :null 2))

(test-js-eval funcall-loop-doing
  ((lambda (x) x)
   (loop for i from 0 to 10 do (1+ i)))
  :undefined)

(test-js-eval block-dynamic-lambda2
  ((lambda () (1+ (block nil (return 4) (+ 1 2)))))
  5)

(test-js-eval block-dynamic-setf
  (progn (defvar foo (block nil (return 4) (+ 1 2)))
         foo)
  4)

(test-js-eval block-dynamic-return1
  (progn (defvar foo ((lambda ()
                        (block nil
                          ((lambda () (return 6)))
                          (+ 1 2)))))
         foo)
  6)

(test-js-eval block-lambda-dynamic-setf
  (progn (defvar foo (block nil ((lambda () (return 4))) (+ 1 2)))
         foo)
  4)

(test-js-eval block-lambda-dynamic-lambda
  ((lambda () (block nil ((lambda () (return 4))) (+ 1 2))))
  4)

(test-js-eval return-from-flet
  (progn (defun foo ()
           (flet ((bar () (return-from foo 42)))
             (bar)))
         (foo))
  42)

(test-js-eval plus-block
  (1+ (block nil (return 4) (+ 1 2)))
  5)

(test-js-eval let-closures-rename
  (progn (defun make-closures ()
           (list
            (let ((x 1)) (lambda () (1+ x)))
            (let ((x 2)) (lambda () (1+ x)))))

         (defvar foo (make-closures))

         (list (funcall (aref foo 0))
               (funcall (aref foo 1))))
  '(2 3))

(test-js-eval labels-return
  ((lambda ()
     (labels ((bar (x)
                (when (evenp x)
                  (return-from bar "even"))
                1))
       (bar 9))))
  1)

(test-js-eval labels-return1
  (progn (defun foo ()
           (labels ((bar (x)
                      (when (evenp x)
                        (return-from foo "even"))
                      1))
             (bar 8)
             2))
         (foo))
  "even")

(test-js-eval labels-return2
  (progn (defun foo ()
           (labels ((bar (x)
                      (flet ((foo (y)
                               (when (evenp (+ x y))
                                 (return-from bar "even"))))
                        (foo 4)
                        5)
                      1))
             (bar 8)))
         (foo))
  "even")

(test-js-eval labels-return3
  (progn (defun foo ()
           (labels ((bar (x)
                      (flet ((baz (y)
                               (when (evenp (+ x y))
                                 (return-from foo "even"))))
                        (baz 4)
                        5)
                      1))
             (bar 8)
             2))
         (foo))
  "even")

(test-js-eval toplevel-local-scope
  (progn (defvar foo (create "fn" (let ((x 5)) (lambda () x))))
         (funcall (getprop foo "fn")))
  5)

(test-js-eval special-var2
  (progn (defvar *foo*)
         (let* ((*baz* 3)
                (*foo* 2))
           (* *foo* 2 *baz*)))
  12)

(test-js-eval special-var3
  (progn (defvar *foo* 1)
         (+ *foo* (let* ((*baz* 3)
                         (*foo* 2))
                    (* *foo* 2 *baz*))))
  13)

(test-js-eval let3
  (let ((x 3)
        (y 2))
    (+ x x))
  6)

(test-js-eval operator-expressions-array-nested-let
  (list (let ((y 1)) y) 2)
  '(1 2))

(test-js-eval block-return-plus
  (+ 1 (block foobar (return-from foobar 2) 1))
  3)

(test-js-eval block-return-plus1
  (+ 1 (block foobar (+ 4 ((lambda (x) (return-from foobar x)) 2)) 1))
  3)

(test-js-eval block-let
  (block foobar
    (let ((x 1))
      (return-from foobar x)
      2))
  1)

(test-js-eval block-dynamic-return
  (block nil (return 4) (+ 1 2))
  4)

(test-js-eval block-lambda-dynamic-return
  (block nil ((lambda () (return 4))) (+ 1 2))
  4)

(test-js-eval nil-block-return-1
  (block nil (return 1) 2)
  1)

(test-js-eval dolist-return
  (dolist (x '(5 2 3))
    (return (1+ x)))
  6)

(test-js-eval let-defun-toplevel
  (progn (let ((foo 0))
           (defun bar () foo))
         (bar))
  0)

(test-js-eval let-defvar-toplevel
  (progn (let ((foo 0))
           (defvar bar (1+ foo)))
         bar)
  1)

(test-js-eval values-not-returned
  (let ((x 1))
    (setf x (+ x (values 2 (incf x))))
    x)
  3)

(test-js-eval equality-nary1
  (let ((x 10) (y 10) (z 10))
    (= x y z))
  t)

(test-js-eval values-not-returned1
  (let ((x 1))
    (incf x (+ x (values 1 (incf x))))
    x)
  4)

(test-js-eval incf-incf
  (let ((x 1))
    (incf x (incf x))
    x)
  4)

(test-js-eval incf-setf
  (let ((x 1))
    (incf x (setf x 4))
    x)
  8)

(test-js-eval values0
  ((lambda () (values)))
  :undefined)

(test-js-eval mv-return1
  (progn (defun foo ()
           (values 1 2 3))
         (multiple-value-bind (a b c) (foo)
           (list a b c)))
  '(1 2 3))

(test-js-eval dynamic-extent-function-return-values
  (progn (defun foo ()
           ((lambda ()
              (return-from foo (values 1 2 3)))))
         (multiple-value-bind (a b c) (foo)
           (list a b c)))
  '(1 2 3))

(test-js-eval plus-not-associative
  (let ((str "a")
        (n 1))
    (+ str (+ n 1)))
  "a2")

(test-js-eval loop-return
  (progn (defun foo ()
           (* 10 (loop for i from 0 below 10 do
                      (when (> i 3)
                        (return i)))))
         (foo))
  40)

(test-js-eval for-arr-place-in
  (loop :for (a b) :in '((2 3) (4 5)) :sum (+ a b))
  14)

(test-js-eval for-obj-place-in
  (loop :for (:a :b) :in (list (create :a 2 :b 3)
                               (create :a 4 :b 5))
    :summing (+ a b))
  14)

(test-js-eval for-arr-place-=
  (flet ((foo () '(2 3)))
    (loop :repeat 3 :for (a b) = (foo) :sum (+ a b)))
  15)

(test-js-eval for-obj-place-=
  (flet ((foo () (create :a 2 :b 3)))
    (loop :repeat 3 :for (:a :b) = (foo) :sum (+ a b)))
  15)

(test-js-eval loop-until1
   (let ((x 0))
     (loop :doing (incf x) :until t)
     x)
   1)

(test-js-eval loop-until2
  (let ((b nil) (c nil))
    (loop :for a :in '(4 9 10) :do (setf b a) :until (> a 5))
    (loop :for a :in '(4 9 10) :until (> a 5) :do (setf c a))
    (list b c))
  '(9 4))

(test-js-eval loop-until3
   (let ((x 0) (y 0))
     (loop :do (incf x) :until (= x 5)
       :do (incf y) :until (= y 3))
     (list x y))
   '(3 3))

(test-js-eval loop-with-clause
  (loop for i :from 0 :to 5
        with x
        unless (< i 3)
     do (return (setf x i)))
  3)

(test-js-eval loop-append
   (loop :for i :from 0 :below 10 :by 3 :append (list i (* i 100)))
   '(0 0 3 300 6 600 9 900))

(test-js-eval loop-appending
   (loop :for i :from 0 :below 10 :by 3 :appending (list i (* i 100)))
   '(0 0 3 300 6 600 9 900))

(test-js-eval loop-maximize
   (loop :for i :in (list 1 5 3 2) :maximize i)
   5)

(test-js-eval loop-maximizing
   (loop :for i :in (list 1 5 3 7) :maximizing i)
   7)

(test-js-eval loop-minimize
   (loop :for i :in (list 1 5 3 2) :minimize i)
   1)

(test-js-eval loop-minimizing
   (loop :for i :in (list 3 5 3 2) :minimizing i)
   2)

(test-js-eval loop-for-on
   (loop :for (a b) :on '(10 20 30 40 50 60) :by 2 :collect (list b a))
   '((20 10) (40 30) (60 50)))

(test-js-eval loop-parallel-clauses-with-return
   (loop :for i :from 0 :below 10 :for x = (* i 10)
     :when (> i 5) :do (return x)
     :collecting i)
   60)

(test-js-eval loop-extended-conditional-clauses
  (loop for i :from 0 :to 5
     for x := (1+ i)
     when x
       collect x
       and if (oddp x)
         collect (1+ x)
       else
         collect (/ x 2)
       end)
  '(1 2 2 1 3 4 4 2 5 6 6 3))

(test-js-eval loop-extended-conditional-clauses1
  (let* ((foo 0)
         (bar (loop for i :from 0 :to 5
                 for x := (1+ i)
                 when x
                   collect x
                   and if (oddp x)
                     collect (1+ x)
                   else
                     collect (/ x 2)
                   end
                   and do (incf foo x))))
    (funcall (@ bar push) foo)
    bar)
  '(1 2 2 1 3 4 4 2 5 6 6 3 21))

(test-js-eval for-loop-downfrom-to
  (loop for i :downfrom 5 :to 0
    collect i)
  '(5 4 3 2 1 0))

(test-js-eval for-loop-downfrom-above
  (loop for i :downfrom 5 :above 0
    collect i)
  '(5 4 3 2 1))

(test-js-eval loop-conditional-return-works
  (block nil
    (dotimes (i 10)
      (if (< 10 i) (return i)))
    (return -1))
  -1)

(test-js-eval return-from-loop
  (let ((a 0))
    (dolist (x '(2 1 3))
      (when (= x 1)
        (return))
      (incf a))
    a)
  1)

(test-js-eval for-loop-var-init-exp
  ((lambda (x)
     (do* ((y (if x 0 1) (1+ y))
           (z 0 (1+ z)))
          ((= y 3) z)))
   true)
  3)

(test-js-eval dolist-return1
  (dolist (x '(5 2 3))
    (return (1+ x)))
  6)

(test-js-eval lambda-nil-return-implicit-nested
  (progn (defun foo (x)
           (block nil
             (if x
                 (return 1)
                 (dotimes (i 4)
                   (return 1)))
             2))

         (list (foo t) (foo nil)))
  '(1 2))

(test-js-eval case-clauses0
  (let* ((foo :bar)
         (bar :baz)
         (x bar))
    (case x
      ((:foo) 1)
      ((:bar :baz) 2)))
  2)

(test-js-eval case-clauses-false
  (* 2 (case (= 1 2)
         (1 1)
         (false 3)
         (2 5)
         (otherwise 7)))
  6)

(test-js-eval case-clauses-false-nil
  (* 2 (case (= 1 2)
         (1 1)
         ((nil) 3)
         (2 5)
         (otherwise 7)))
  6)

(test-js-eval case-clauses-true
  (* 2 (case (= 2 2)
         (1 1)
         ((t) 3)
         (otherwise 7)))
  6)

(test-js-eval recursive-values
  (progn
    (defun foo (x)
      (if (= 0 x)
          (values 1 2 3 4)
          (progn
            (foo 0)
            23)))

    (defun bar ()
      (foo 1))

    (multiple-value-bind (a b c d) (bar)
      (list a b c d)))
  '(23 :undefined :undefined :undefined))

(test-js-eval recursive-values1
  (progn
    (defun foo (x)
      (if (= 0 x)
          (values 1 2 3)
          (baz)))

    (defun baz (x)
      (foo 0)
      23)

    (defun bar ()
      (foo 1))

    (multiple-value-bind (a b c d) (bar)
      (list a b c d)))
  '(23 :undefined :undefined :undefined))

(test-js-eval values-nonlocal-return
  (progn
    (defun foo (x)
      (if (= 0 x)
          (values 1 2 3)
          (progn
            (foo 0)
            (throw 23))))

    (defun bar ()
      (try (foo 1)
           (:catch (e)
             27)))

    (multiple-value-bind (a b c) (bar)
      (list a b c)))
  '(27 :undefined :undefined))

(test-js-eval values-nonlocal-return1
  (progn
    (defun foo (x)
      (if (= 0 x)
          (values 1 2 3)
          (bar 0)))

    (defun bar (x)
      (try
       (if (= x 0)
           (progn
             (foo 0)
             (throw 11))
           (foo x))
       (:catch (e)
         27)))

    (multiple-value-bind (a b c) (bar 1)
      (list a b c)))
  '(27 :undefined :undefined))

(test-js-eval values-nonlocal-return2
  (progn
    (defun foo (x)
      (try
       (if (= 0 x)
           (values 1 2 3)
           (bar))
       (:catch (e) 27)))

    (defun bar ()
      (foo 0)
      (throw 13))

    (multiple-value-bind (a b c) (foo 1)
      (list a b c)))
  '(27 :undefined :undefined))

(test-js-eval case-symbol-macro-key
  (symbol-macrolet ((x 1))
    (let ((blah 1))
      (case blah
        (0 3)
        (x 7)
        (t 13))))
  13)

(test-js-eval case-symbol
  (let ((blah 'x))
    (case blah
      (0 3)
      (x 7)
      (t 13)))
  7)

(test-js-eval symbol-macro-funcall
  (symbol-macrolet ((bar (getprop Math 'min)))
    (funcall bar -1 2))
  -1)

(test-js-eval negative-mod
  (mod -12 7)
  2)

(test-js-eval negative-mod1
  (mod -12 (funcall (@ Math floor) 7.5))
  2)

(test-js-eval negative-mod2
  (1+ (mod -12 7))
  3)

(test-js-eval negative-rem
  (rem -12 7)
  -5)

(test-js-eval negative-rem1
  (rem -12 (funcall (@ Math floor) 7.5))
  -5)

(test-js-eval-epsilon trig1
  (sinh 3.14)
  11.530293)

(test-js-eval-epsilon trig2
  (sinh (floor 3.14))
  10.017875)

(test-js-eval-epsilon trig3
  (cosh 3.14)
  11.573576)

(test-js-eval-epsilon trig4
  (cosh (floor 3.14))
  10.067662)

(test-js-eval-epsilon trig5
  (tanh 3.14)
  0.9962602)

(test-js-eval-epsilon trig6
  (tanh (floor 3.14))
  0.9950548)

(test-js-eval-epsilon trig7
  (asinh 3.14)
  1.8618126)

(test-js-eval-epsilon trig8
  (asinh (floor 3.14))
  1.8184465)

(test-js-eval-epsilon trig7
  (acosh 3.14)
  1.8109914)

(test-js-eval-epsilon trig8
  (acosh (floor 3.14))
  1.7627472)

(test-js-eval-epsilon trig7
  (atanh 0.71)
  0.88718385)

(test-js-eval-epsilon trig8
  (atanh (expt -0.71 3))
  -0.37448788)

(test-js-eval let-let
  (let ((x (let ((y 12))
             (+ 1 2)
             y)))
    (1+ x))
  13)

(test-js-eval let-let1
  (let ((x (let ((y 12))
             (dolist (x '(1 2 3))
               (* x x))
             y)))
    (1+ x))
  13)

(test-js-eval array-init-1
  (make-array 2 :initial-contents '(10 20))
  '(10 20))

(test-js-eval array-init-2
  (make-array 5 :initial-element 10)
  '(10 10 10 10 10))

(test-js-eval dotimes-block-return
  (1+ (dotimes (x 3) (if (= x 2) (return (+ x x)))))
  5)

(test-js-eval labels-factorial
  (progn
    (defun fac (n)
      (labels ((f (n a)
                 (if (< n 2)
                     a
                     (f (- n 1) (* n a)))))
        (f n 1)))
    (fac 5))
  120)

(test-js-eval destructuring-bind1
  ((lambda (a)
     (when a
       (destructuring-bind (b . c)
           a
         (list b c))))
   '(1 2 3))
  '(1 (2 3)))

(test-js-eval defun-not-a-docstring
  (progn
    (defun foo ()
      "bar")
    (foo))
  "bar")

(test-js-eval lambda-not-a-docstring
  ((lambda () "bar"))
  "bar")

(test-js-eval loop-variable-capture1
  (let ((x (make-array 10)))
    (dotimes (i 10) (setf (aref x i) (lambda () i)))
    (loop for x across x sum (funcall x)))
  100)

(test-js-eval loop-variable-capture2
  (let ((x (make-array 10)))
    (dotimes (i 10)
      (let ((y i))
        (setf (aref x i) (lambda () y))))
    (loop for x across x sum (funcall x)))
  45)

(test-js-eval loop-variable-capture3
  (let ((x (make-array 10)))
    (dotimes (i 10)
      (let ((i i))
        (setf (aref x i) (lambda () i))))
    (loop for x across x sum (funcall x)))
  45)

(test-js-eval loop-variable-capture4
  (let ((x (make-array 10 :initial-element (lambda () 0))))
    (dotimes (i 10)
      (let ((i i))
        (setf (aref x i) (lambda () i))
        (when (= i 5) (return))))
    (loop for x across x sum (funcall x)))
  15)

(test-js-eval loop-variable-capture5
  (let ((A (make-array 10)))
    (dotimes (i 10)
      (flet ((foo (x) (+ i x)))
        (setf (aref A i) (lambda () (foo i)))))
    (loop for x across A sum (funcall x)))
  200)

(test-js-eval loop-variable-capture6
  (labels ((make-cl (i) (lambda () (* i 10))))
    (let ((closures (loop :for i :from 1 :to 3
                       :collect (make-cl i))))
      (loop :for fn :in closures :collect (funcall fn))))
  '(10 20 30))

(test-js-eval loop-variable-capture7
  (let ((closures (loop :for i :from 1 :to 3
                     :collect (let* ((j i)
                                     (cl (lambda () (* j 10))))
                                cl))))
    (loop :for fn :in closures :collect (funcall fn)))
  '(10 20 30))

(test-js-eval nested-let
  (let ((x (let ((y 94))
             y)))
    x)
  94)

(test-js-eval lambda-apply
  ((lambda (x)
     (apply (lambda (y) (1+ y))
            x))
   (list 6))
  7)

(test-js-eval subtract-associative
  (list (- 1 2 3)
        (- 1 (- 2 3)))
  '(-4 2))

(test-js-eval logand1
  (let ((x 4583))
    (setf x (logand x 947))
    x)
  419)

(test-js-eval cons-cdr-clause-empty
  ((lambda () (cond (923))))
  923)

(test-js-eval labels-return-from
  (labels ((bar (x)
             (when (evenp x)
               (return-from bar "even"))
             "odd"))
    (bar 9))
  "odd")

(test-js-eval random-float-const
  (< 0 (rem (random 123.456) 1) 1)
  t)

(test-js-eval random-int-const
  (rem (random 234) 1)
  0)

(test-js-eval random-float-fun-once-only
  (let ((x t))
    (flet ((foo ()
             (prog1 (if x
                        123.123
                        (throw "foobar"))
               (setf x nil))))
      (< 0 (rem (random (foo)) 1) 1)))
  t)

(test-js-eval let-setf-side-effects
  (let ((x 10))
    (defun side-effect()
      (setf x 4)
      3)
    (setf x (+ 2 (side-effect) x 5)))
  14)

(test-js-eval dolist-result-bind-nil
  (dolist (i '(1 2 3) (list i 9))
    (list i))
  '(nil 9))

(test-js-eval dotimes-result-bind-nil
  (dotimes (i '(1 2 3) (list 9 i))
    (list i))
  '(9 nil))

(test-js-eval progn-of-block-closure
  ((lambda ()
     (progn
       (block nil
         ((lambda ()
            ((lambda ()
               (return 1)))
            2))))))
  1)

(test-js-eval progn-of-block-closure1
  ((lambda ()
     (progn
       (block X
         ((lambda ()
            ((lambda ()
               (return-from X 1)))
            2))))))
  1)

(test-js-eval progn-of-block-closure2
  ((lambda ()
     (1+
       (block X
         ((lambda ()
            ((lambda ()
               (return-from X 1)))
            3))))))
  2)

(test-js-eval progn-of-block-closure3
  ((lambda ()
     (1+
       (block nil
         ((lambda ()
            ((lambda ()
               (return 1)))
            3))))))
  2)

(test-js-eval block-closure-no-progn
  ((lambda ()
     (block nil
       ((lambda ()
          ((lambda ()
             (return 1)))
          2)))))
  1)

(test-js-eval function-clears-current-block-tag
  ((lambda ()
     (block X
       ((lambda ()
          ((lambda ()
             (return-from X 1)))
          2)))
     5))
  5)

(test-js-eval defvar-dynamic-return
  (progn
    (defvar foo ((lambda ()
                   (block nil
                     ((lambda () (return 6)))
                     (+ 1 2)))))
    foo)
  6)

(test-js-eval defvar-dynamic-return1
  (progn
    (defvar foo ((lambda ()
                   (block nil
                     ((lambda () (return 6)))
                     (+ 1 2))
                   (+ 4 5))))
    foo)
  9)

(test-js-eval defvar-dynamic-return-expression
  (progn
    (defvar foo ((lambda ()
                   (+ 1 (block nil
                          ((lambda () (return 6)))
                          (+ 1 2))))))
    foo)
  7)

(test-js-eval defun-when-if-return
  (progn
    (defun foobar ()
      (when t
        (loop if t return 10)))
    (foobar))
  10)

(test-js-eval this-passthrough-generated-lambdas
  (let ((obj (ps:create x 3)))
    (setf (ps:getprop obj 'foo)
          (lambda ()
            (1+ (loop repeat 10 return (ps:getprop ps:this 'x)))))
    (funcall (ps:getprop obj 'foo)))
  4)

(test-js-eval arrayp1
  (arrayp '(1 2 3))
  t
  :js-target-version "1.3")

(test-js-eval arrayp2
  (arrayp '(1 2 3))
  t
  :js-target-version "1.8.5")

(test-js-eval multiple-value-bind-values
  (multiple-value-bind (x y)
      (values 1 2)
    y)
  2)

(test-js-eval multiple-value-passthrough
  (progn
    (defun foo ()
      (values 1 2))
    (defun bar ()
      (foo))
    (multiple-value-bind (x y)
        (bar)
      y))
  2)

(test-js-eval multiple-value-call-twice
  (progn
    (defun foo (x &optional y z)
      (if z
          (values x y z)
          (values x y)))

    (defun bar ()
      (foo 1 2 3)
      (foo 4 5))

    (multiple-value-bind (a b c) (bar)
      (list a b c)))
  '(4 5 :undefined))

(test-js-eval multiple-value-bind-nested
  (multiple-value-bind (x y)
      ((lambda ()
         (multiple-value-bind (a b)
             (values 1 2)
           (values b a))))
    (list x y))
  '(2 1))
