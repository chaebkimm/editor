(defpackage my-tree
  (:use :common-lisp :my-utils :defobj))

(in-package :my-tree)

(defobj tree-node!
  (data nil)
  (level 1 :type integer)
  (num-left 0 :type integer)
  (parent-node nil :type (or tree-node! null))
  (left-node nil :type (or tree-node! null))
  (right-node nil :type (or tree-node! null)))

(defmethod print-object ((node tree-node!) out)
  (print-unreadable-object (node out :type t)
    (format out "(data = ~s" (tree-node!-data node))
    (format out ", level = ~d, num-left = ~d)" (tree-node!-level node) (tree-node!-num-left node))))

(defobjfun set-left-node (p-tree-node! l-tree-node!)
  (setf p-left-node l)
  (if (not-eq l-tree-node! nil)
      (setf l-parent-node p)))

(defobjfun set-right-node (p-tree-node! r-tree-node!)
  (setf p-right-node r)
  (if (not-eq r nil)
      (setf r-parent-node p)))

(defobjfun unset-left-node (p-tree-node!)
  (objlet* ((curr-l-tree-node! p-left-node))
    (setf p-left-node nil)
    (if (not-eq curr-l nil)
        (setf curr-l-parent-node nil))))

(defobjfun unset-right-node (p-tree-node!)
  (objlet* ((curr-r-tree-node! p-right-node))
    (setf p-right-node nil)
    (if (not-eq curr-r nil)
        (setf curr-r-parent-node nil))))

(export 'cursor!)
(export 'curr-index)
(defobj cursor!
  (curr-index nil :type (or integer null))
  (curr-node nil :type (or tree-node! null)))

(declaim (inline cursor!-<=))
(defobjfun cursor!-<= (cursor!-1 cursor!-2)
  (<= curr-index-1 curr-index-2))

(export 'multi-cursor-tree!)
(export 'cursors)
(defobj multi-cursor-tree!
  (size 0 :type integer)
  (head nil :type (or tree-node! null))
  (tail nil :type (or tree-node! null))
  (root nil :type (or tree-node! null))
  (iter-cursor nil :type (or null cursor!))
  (cursors nil :type (or null cons)))

(defobjfun get-node-by-index (t-multi-cursor-tree! index)
  (objdo* ((x-tree-node! t-root
                         (cond ((> x-num-left index) x-left-node)
                               ((< x-num-left index) (progn (decf index (+ x-num-left 1))
                                                            x-right-node)))))
      ((= x-num-left index) x)))


(export 'create-cursor!)
(defobjfun create-cursor! (t-multi-cursor-tree! index)
  (if (and (<= index t-size) (>= index 0))
      (make-cursor! :curr-index index :curr-node (get-node-by-index t index))
      (error "my-tree:create-cursor! index out of bound.~%")))

(export 'create-multi-cursor-tree!)
(defun create-multi-cursor-tree! ()
  (objlet* ((multi-cursor-tree! (make-multi-cursor-tree!)))
    (setf head (make-tree-node! :data "head"))
    (setf tail (make-tree-node! :data "tail"))
    (set-right-node head tail)
    (setf root head)
    (objlet* ((cursor! (make-cursor! :curr-index 0 :curr-node head)))
      (setf iter-cursor cursor!)
      (sorted-push cursor! cursors #'cursor!-<=))
    multi-cursor-tree!))

(defmethod print-object ((tree multi-cursor-tree!) out)
  (let ((root (multi-cursor-tree!-root tree)))
    (print-unreadable-object (tree out :type t)
      (format out "(size = ~d, cursors at" (multi-cursor-tree!-size tree))
      (objdolist (cursor! (multi-cursor-tree!-cursors tree))
        (format out " ~a" curr-index))
      (format out ")")

      ;; (labels ((print-node-recursive (node)
      ;;            (if (eq node nil)
      ;;                (format out ".")
      ;;                (progn
      ;;                  (format out "(")
      ;;                  (print-object node out)
      ;;                  (format out " ")
      ;;                  (if (eq node root)
      ;;                      (format out "^r"))
      ;;                  (maphash #'(lambda (user-name cursors)
      ;;                               (dolist (cursor cursors)
      ;;                                 (if (eq node (curr-node cursor))
      ;;                                     (format out " ^~a" user-name))))
      ;;                           (cursors tree))
      ;;                  (format out ", l = ")
      ;;                  (print-node-recursive (left-node node))
      ;;                  (format out ", r = ")
      ;;                  (print-node-recursive (right-node node))
      ;;                  (format out ")")))))
      ;;   (print-node-recursive root))
      )

    (do ((index 0 (+ index 1)))
        ((> index (+ (multi-cursor-tree!-size tree) 1)))
      (let ((node (get-node-by-index tree index)))
        (format out "~%")
        (print-object node out)
        (format out "~%")
        (if (eq node root) (format out "^r"))
        (dolist (cursor (multi-cursor-tree!-cursors tree))
          (if (eq node (cursor!-curr-node cursor))
              (progn
                (format out " ^")
                (if (eq (multi-cursor-tree!-iter-cursor tree) cursor)
                    (format out "t-iter")
                    (format out "t-user")))))
	(format out "~%")))))

(defobjfun skew (t-multi-cursor-tree! x-tree-node!)
  (objlet* ((y-tree-node! x-left-node))
    (if (and (not-eq y nil) (eq x-level y-level))
        (objlet* ((b-tree-node! y-right-node)
                  (p-tree-node! x-parent-node))
          (set-left-node x b)
          (set-right-node y x)
          (cond ((eq p nil) (progn (setf t-root y)
                                   (setf y-parent-node nil)))
                ((eq p-left-node x) (set-left-node p y))
                ((eq p-right-node x) (set-right-node p y)))
          (decf x-num-left (+ y-num-left 1))
          (return-from skew y)))
    (return-from skew x)))

(defobjfun split (t-multi-cursor-tree! x-tree-node!)
  (objlet* ((y-tree-node! x-right-node))
    (if (and (not-eq y nil) (eq x-level y-level))
        (objlet* ((z-tree-node! y-right-node))
          (if (and (not-eq z nil) (eq y-level z-level))
              (objlet* ((b-tree-node! y-left-node)
                        (p-tree-node! x-parent-node))
                (set-left-node y x)
                (set-right-node y z)
                (set-right-node x b)
                (incf y-num-left (+ x-num-left 1))
                (incf y-level)
                (cond ((eq p nil) (progn (setf t-root y)
                                         (setf y-parent-node nil)))
                      ((eq p-left-node x) (set-left-node p y))
                      ((eq p-right-node x) (set-right-node p y)))
                (return-from split y)))))
    (return-from split x)))

(export 'insert-data-after-cursor)
(defobjfun insert-data-after-cursor (t-multi-cursor-tree! cursor! data)
  (objlet* ((curr-right-tree-node! (tree-node!-right-node curr-node))
            (new-tree-node! (make-tree-node! :data data)))
    ; insert new-node as left child of left-most of right node of curr-node while updating num-left
    (if (eq curr-right nil)
        (set-right-node curr-node new)
        (objlet* ((left-most-tree-node! (objdo* ((i-tree-node! curr-right i-left-node))
                                                ((eq i-left-node nil) i)
                                          (incf i-num-left))))
          (set-left-node left-most new)
          (incf left-most-num-left)))
    (incf t-size)
    ; increase num-left for all the right parents in the way from curr-node to root
    (objdo* ((x-tree-node! curr-node x-parent-node))
            ((eq x-parent-node nil))
      (objlet* ((p-tree-node! x-parent-node))
        (if (eq p-left-node x)
            (incf p-num-left))))
    ; skew and split going to root from new-node
    (objdo* ((i-tree-node! new-parent-node i-parent-node))
            ((eq i nil))
      (setf i (skew t i))
      (setf i (split t i)))
    ;; update all cursors greater than current cursor
    (dolist (cursor t-cursors)
      (objlet* ((iter-cursor! cursor))
        (if (> iter-curr-index curr-index)
            (incf iter-curr-index))))
    ;; update current cursor
    (move-cursor-to-next t cursor!)))

(defobjfun adjust (t-multi-cursor-tree! x-tree-node!)
  (objlet* ((l-tree-node! x-left-node)
            (r-tree-node! x-right-node)
            (p-tree-node! x-parent-node)
            (rep-tree-node! nil))
    (if (eq l nil)
        (if (eq r nil)
            (setf rep x)
            (objlet* ((a-tree-node! r-left-node) ; r != nil
                      (b-tree-node! r-right-node))
              (if (eq x-level r-level)
                  (progn ; lvl x == lvl r
                    (setf x-level 1)
                    (setf a-level 2)
                    (setf r-level 1)
                    (setf a-num-left 1)
                    (setf r-num-left 0)
                    (set-left-node a x)
                    (set-right-node a r)
                    (set-right-node x nil)
                    (setf rep a))
                  (progn ; lvl x != lvl r
                    (if (and (not-eq b nil) (eq r-level b-level))
                        (progn
                          (setf x-level 1)
                          (setf r-level 2)
                          (setf r-num-left 1)
                          (set-left-node r x)
                          (set-right-node x nil)
                          (setf rep r))
                        (progn
                          (setf x-level 1)
                          (setf rep x)))))))
        (if (eq r nil) ; l != nil
            (objlet* ((b-tree-node! l-right-node)) ; r == nil
              (if (and (not-eq b nil) (eq l-level b-level))
                  (progn
                    (setf b-level 2)
                    (setf x-level 1)
                    (setf b-num-left 1)
                    (setf x-num-left 0)
                    (set-left-node b l)
                    (set-right-node b x)
                    (set-left-node x nil)
                    (setf rep b))
                  (progn
                    (setf x-level 1)
                    (setf x-num-left 0)
                    (set-right-node l x)
                    (set-left-node x nil)
                    (setf rep l))))
            (objlet* ((a-tree-node! l-left-node) ; r != nil
                      (b-tree-node! l-right-node)
                      (c-tree-node! r-left-node)
                      (d-tree-node! r-right-node))
              (cond ((and (>= l-level (- x-level 1)) (>= r-level (- x-level 1)))
                     (setf rep x))
                    ((< r-level (- x-level 1))
                     (if (and (not-eq b nil) (eq b-level l-level))
                         (objlet* ((lb-tree-node! b-left-node) ; l is double
                                   (rb-tree-node! b-right-node))
                           (incf b-level)
                           (decf x-level)
                           (incf b-num-left (+ l-num-left 1))
                           (decf x-num-left (+ b-num-left 1))
                           (set-left-node b l)
                           (set-right-node b x)
                           (set-right-node l lb)
                           (set-left-node x rb)
                           (setf rep b))
                         (progn ; l is single
                           (decf x-level)
                           (decf x-num-left (+ l-num-left 1))
                           (set-right-node l x)
                           (set-left-node x b)
                           (setf rep l))))
                    ((< r-level x-level)
                     (decf x-level)
                     (return-from adjust (split t x)))
                    (t
                     (objlet* ((e-tree-node! c-left-node)
                               (f-tree-node! c-right-node))
                       (incf c-level)
                       (decf r-num-left (+ c-num-left 1))
                       (incf c-num-left (+ x-num-left 1))
                       (set-right-node x e)
                       (set-left-node c x)
                       (set-right-node c r)
                       (set-left-node r f)
                       (if (or (eq f nil) (not-eq f-level c-level)) ; c is single
                           (decf r-level)
                           (progn
                             (decf x-level)
                             (setf rep c)))))))))
    ; set parent of rep as p
    (cond ((eq p nil) (progn (setf t-root rep)
                             (setf rep-parent-node nil)))
          ((eq p-right-node x) (set-right-node p rep))
          ((eq p-left-node x) (set-left-node p rep)))
    (return-from adjust rep)))

(export 'delete-data-at-cursor)
(defobjfun delete-data-at-cursor (t-multi-cursor-tree! cursor!)
  (objlet* ((x-tree-node! curr-node)
            (head-tree-node! t-head)
            (root-tree-node! t-root))
    ;; return if curr node is head
    (if (eq x head)
        (return-from delete-data-at-cursor nil))
    ;; update all cursors greater than or equal to current cursor
    (dolist (cursor t-cursors)
      (objlet* ((iter-cursor! cursor))
        (cond ((> iter-curr-index curr-index)
               (decf iter-curr-index))
              ((= iter-curr-index curr-index)
               (move-cursor-to-prev t iter)))))
    ;; delete data before current cursor
    (objlet* ((l-tree-node! x-left-node)
              (r-tree-node! x-right-node)
              (p-tree-node! x-parent-node)
              (rep-tree-node! nil)
              (z-tree-node! nil))
      ;;  x -> nil
      (unset-left-node x)
      (unset-right-node x)
      (decf t-size)
      ;; set rep (node to replace curr node) and z (node to start adjust)
      (if (eq l nil)
          (progn ; l == nil
            (setf rep r)
            (if (eq rep nil)
                (progn ; l == nil, r == nil -> p != nil
                  (if (eq p-left-node x) (decf p-num-left))
                  (setf z p))
                (progn ; l == nil, r != nil
                  (setf rep-level x-level)
                  (setf z rep))))
          (progn ; l != nil
            (setf rep (objdo* ((lrg-tree-node! l lrg-right-node))
                              ((eq lrg-right-node nil) lrg)))
            (setf rep-level x-level)
            (setf z rep)
            (if (eq rep l)
                (progn ; rep == l
                  (set-right-node rep r))
                (progn ; rep != l
                  (objlet* ((prep-tree-node! rep-parent-node))
                    (unset-right-node prep)
                    (set-right-node prep rep-left-node))
                  (setf rep-num-left (- x-num-left 1))
                  (set-left-node rep l)
                  (set-right-node rep r)))))
      ;; set parent of rep as p
      (cond ((eq p nil) (progn (setf t-root rep)
                               (setf rep-parent-node nil)))
            ((eq p-right-node x) (set-right-node p rep))
            ((eq p-left-node x) (set-left-node p rep)))
      ;; decrease num-left for all left parents in the way from z to root
      (objdo* ((x-tree-node! z x-parent-node))
        ((eq x-parent-node nil))
        (objlet* ((p-tree-node! x-parent-node))
          (if (eq p-left-node x)
              (decf p-num-left))))
      ; adjust from z to root
      (objdo* ((i-tree-node! z i-parent-node))
        ((eq i nil))
        (setf i (adjust t i)))
      t)))

(export 'move-cursor-to-prev)
(defobjfun move-cursor-to-prev (t-multi-cursor-tree! cursor!)
  (let ((prev-index (- curr-index 1)))
    (when (>= prev-index 0)
      (setf curr-node (get-node-by-index t prev-index))
      (setf curr-index prev-index)))
  t)

(export 'move-cursor-to-next)
(defobjfun move-cursor-to-next (t-multi-cursor-tree! cursor!)
  (let ((next-index (+ curr-index 1)))
    (when (<= next-index t-size)
      (setf curr-node (get-node-by-index t next-index))
      (setf curr-index next-index)))
  t)

(export 'move-cursor-to-head)
(defobjfun move-cursor-to-head (t-multi-cursor-tree! cursor!)
  (setf curr-node t-head)
  (setf curr-index 0)
  t)

(export 'move-cursor-to-last)
(defobjfun move-cursor-to-last (t-multi-cursor-tree! cursor!)
  (setf curr-node (get-node-by-index t t-size))
  (setf curr-index t-size)
  t)

(export 'move-cursor-to-index)
(defobjfun move-cursor-to-index (tree-multi-cursor-tree! cursor! index)
  (let ((new-index (cond ((< index 0) 0)
                         ((> index tree-size) tree-size)
                         (t index))))
    (setf curr-node (get-node-by-index tree new-index))
    (setf curr-index new-index))
  tree)

(export 'get-data)
(defobjmacro get-data (cursor!)
  `(tree-node!-data ,curr-node))

(export 'is-cursor-last)
(defobjmacro is-cursor-last (multi-cursor-tree! cursor!)
  `(eq ,size ,curr-index))

(export 'index-of)
(defobjmacro index-of (cursor!)
  `,curr-index)

(export 'is-empty)
(defobjmacro is-empty (multi-cursor-tree!)
  `(eq ,size 0))

(export 'get-default-cursor)
(declaim (inline get-default-cursor))
(defobjfun get-default-cursor (multi-cursor-tree!)
  iter-cursor)

(export 'push-cursor!)
(declaim (inline push-cursor!))
(defobjfun push-cursor! (t-multi-cursor-tree! cursor!)
  (sorted-push cursor! t-cursors #'cursor!-<=))

(export 'remove-cursor!)
(declaim (inline remove-cursor!))
(defobjfun remove-cursor! (t-multi-cursor-tree! cursor!)
  (remove-el cursor! t-cursors))

(export 'get-size)
(defobjmacro get-size (multi-cursor-tree!)
  `,size)

(export 'tree-multi-cursor-tree!)
(export 't-multi-cursor-tree!)
