(in-package :new-my-text)

(defobj a!
  (a nil))

(defobjfun change-a (a!)
  (setf a 1))

(defobjfun print-text-stdout (text!)  
  (my-tree:move-cursor-to-index line-tree text-iter-cursor 0)
  (until (my-tree:is-cursor-last line-tree text-iter-cursor)
    ;; skip head
    (my-tree:move-cursor-to-next line-tree text-iter-cursor)
    (objlet* ((line! (my-tree:get-data text-iter-cursor)))
      (my-list:move-cursor-to-index char-list line-iter-cursor 0)
      (until (my-list:is-cursor-last char-list line-iter-cursor)
	(my-list:move-cursor-to-next char-list line-iter-cursor)
	(objlet* ((char! (my-list:get-data line-iter-cursor)))
	  (format t "~a" char))
	)
      (format t "~%" )
      )
    )
)

(defparameter *user* nil)
(defparameter *text* nil)

(export 'test)
(defmacro test ()
  `(progn
     (format t "~a~%" (create-line!))
     (format t "~a~%" (make-cursor!))
     (format t "~a~%" (create-text!))

     (setf *user* (make-user! :font (gethash "UbuntuMono-R" *font-table*) :connect 1))
     (setf *text* (create-text!))

     (objlet* ((user! *user*)
	       (user!2 (make-user! :font (gethash "UbuntuMono-R" *font-table*) :connect 2))
	       (text! *text*))       
       (load-text text! "/home/chaewon/Desktop/chae1/github/editor/server/src/multi-cursor-list.lisp")
       (link-user user! text!)
       
       (add-primary-cursor user! text! 1 0)
       (add-primary-cursor user! text! 2 0)
       (get-text user! text!)

       (objdolist (u-user! (hash-table-values user-table))
	 (print u-cursor-list))

       (remove-except-primary-cursor user! text!)
       (print cursor-list)

       (link-user user!2 text!)
       (add-primary-cursor user!2 text! 2 0)
       (add-primary-cursor user!2 text! 3 0)
       (print cursor-list2)
       
       (let ((l '()))
	 (objdolist (user! (hash-table-values user-table))
	   (objdolist (cursor! cursor-list)
	     (objlet* ((char! (my-list:get-data line-cursor)))
	       (print line-cursor)
	       (push line-cursor l))))

	 
	 (print (eq (my-list:get-multi-cursor-list (car l))
		    (my-list:get-multi-cursor-list (cadr l))))
	 (print (eq (my-list:get-multi-cursor-list (car l))
		    (my-list:get-multi-cursor-list (caddr l))))
	  
	 (print (equal (car l) (cadr l)))
	 (print (equal (car l) (caddr l)))
	 )
       )))
