(defvar zpb-path #p"/home/chaewon/Downloads/bin/zpb-ttf-1.0.6/")
(unless (member zpb-path asdf:*central-registry* :test #'equal)
  (push zpb-path asdf:*central-registry*))
(asdf:load-system "zpb-ttf")

(ql:quickload :cl-ppcre)

(defpackage my-font
  (:use :common-lisp :my-utils :defobj :zpb-ttf))

(in-package :my-font)

(defvar *char->name* (make-hash-table :test #'equal))

(defparameter *small-chars* '(#\a #\b #\c #\d #\e #\f #\g #\h #\i #\j #\k #\l #\m #\n #\o #\p #\q #\r #\s #\t #\u #\v #\w #\x #\y #\z))

(defun add-small-chars ()
  (mapc #'(lambda (c) (setf (gethash c *char->name*) (concatenate 'string "small_" (coerce `(,c) 'string)))) *small-chars*))

(defparameter *big-chars* '(#\A #\B #\C #\D #\E #\F #\G #\H #\I #\J #\K #\L #\M #\N #\O #\P #\Q #\R #\S #\T #\U #\V #\W #\X #\Y #\Z))

(defun add-big-chars ()
  (mapc #'(lambda (c) (setf (gethash c *char->name*) (concatenate 'string "big_" (coerce `(,c) 'string)))) *big-chars*))

(defun add-char-str (char-str)
  (setf (gethash (car char-str) *char->name*) (cdr char-str)))

(defparameter *other-chars* '((#\` . "backquote") (#\~ . "tilde") (#\! . "exclamation_mark") (#\@ . "ampersat") (#\# . "sharp") (#\$ . "dollar") (#\% . "percent") (#\^ . "caret") (#\& . "ampersand") (#\* . "asterisk") (#\( . "open_parenthesis") (#\) . "close_parenthesis") (#\- . "hyphen") (#\_ . "underscore") (#\+ . "plus") (#\= . "equal") (#\{ . "open_brace") (#\} . "close_brace") (#\[ . "open_bracket") (#\] . "close_bracket") (#\| . "pipe") (#\\ . "backslash") (#\; . "semicolon") (#\: . "colon") (#\' . "single_quote") (#\" . "quote") (#\, . "comma") (#\. . "period") (#\< . "less_than") (#\> . "greater_than") (#\? . "question_mark") (#\/ . "slash") (#\0 . "zero") (#\1 . "one") (#\2 . "two") (#\3 . "three") (#\4 . "four") (#\5 . "five") (#\6 . "six") (#\7 . "seven") (#\8 . "eight") (#\9 . "nine")))

(defun init-map-char->name ()
  (add-small-chars)
  (add-big-chars)
  (mapc #'add-char-str *other-chars*))

(init-map-char->name)

(defun print-hash-entry (key value)
    (format t "~S -> ~S~%" key value))

(defun print-char->name ()
  (maphash #'print-hash-entry *char->name*))

(defobj font-info!
  (font-loader nil)
  (font-path nil)
  (font-name nil)
  (add-x 0)
  (add-y 0)
  (mono-render-box #(0 0 0 0))
  (line-height))

(defun create-font-info! (ttf-path)
  (objlet* ((font-info! (make-font-info!)))
    (setf font-loader (open-font-loader ttf-path))
    (setf font-path ttf-path)
    (setf font-name (car (cl-ppcre:split "\\." (car (last (cl-ppcre:split "/" ttf-path))))))
    (let* ((b (bounding-box (find-glyph #\a font-loader)))
	   (x-min (aref b 0))
	   (y-min (aref b 1))
	   (x-max (aref b 2))
	   (y-max (aref b 3)))
      (loop for c in '(#\a #\b #\c #\d #\e #\f #\g #\h #\i #\j #\k #\l #\m #\n #\o #\p #\q #\r #\s #\t #\u #\v #\w #\x #\y #\z #\A #\B #\C #\D #\E #\F #\G #\H #\I #\J #\K #\L #\M #\N #\O #\P #\Q #\R #\S #\T #\U #\V #\W #\X #\Y #\Z #\` #\~ #\! #\@ #\# #\$ #\% #\^ #\& #\* #\( #\) #\- #\_ #\+ #\= #\{ #\} #\[ #\] #\| #\\ #\; #\: #\' #\" #\, #\. #\< #\> #\? #\/ #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9 #\0) do
	(setf b (bounding-box (find-glyph c font-loader)))
	(if (> x-min (aref b 0)) (setf x-min (aref b 0)))
	(if (> y-min (aref b 1)) (setf y-min (aref b 1)))
	(if (< x-max (aref b 2)) (setf x-max (aref b 2)))
	(if (< y-max (aref b 3)) (setf y-max (aref b 3))))
      ;; (format t "~a ~a ~a ~a~%" x-min y-min x-max y-max) 
      (setf add-x (- 8 x-min))
      (setf add-y (- 10 y-min))
      ;; (format t "~a ~a~%" add-x add-y)
      (setf (aref mono-render-box 0) (- (+ x-min add-x) 8))
      (setf (aref mono-render-box 1) (- (+ y-min add-y) 10))
      (setf (aref mono-render-box 2) (+ (+ x-max add-x) 8))
      (setf (aref mono-render-box 3) (+ (+ y-max add-y) 9))
      ;; (format t "~a~%" mono-render-box)
      (setf line-height (aref mono-render-box 3))
      ;; (format t "~a~%" line-height)
      font-info!)))

(defparameter *ubuntumono-r* (create-font-info! "/home/chaewon/Desktop/chae1/github/editor/font/ttf/UbuntuMono-R.ttf"))

(defobjfun generate-font-info (font-info!)
  (flet ((generate-char-info (c file)
           (let* ((glyph (find-glyph c font-loader))
		  (total-curve-num (length (contours glyph))))
	     (format file "glyph~%~a~%" c)
             (format file "~%curves p1x p1y p2x p2y p3x p3y~%")
             (dotimes (curve-num total-curve-num)
	       (let ((points (explicit-contour-points (contour glyph curve-num))))
		 (let ((point-state 0))
		   (do ((i 0 (1+ i)))
		       ((eq i (length points)))
		     (let* ((point (aref points i))
			    (curr-x (+ (x point) add-x))
			    (curr-y (+ (y point) add-y)))
		       (if (on-curve-p point)
			   (ccase point-state
			     (0 (progn
				  (format file "~,2f ~,2f " curr-x curr-y)
				  (setf point-state 1)))
			     (1 (let* ((prev-point (aref points (1- i)))
				       (prev-x (+ (x prev-point) add-x))
				       (prev-y (+ (y prev-point) add-y)))
				  (format file "~,2f ~,2f " (/ (+ curr-x prev-x) 2) (/ (+ curr-y prev-y) 2))
				  (format file "~,2f ~,2f~%" curr-x curr-y)
				  (format file "~,2f ~,2f " curr-x curr-y)
				  (setf point-state 1)))
			     (2 (progn
				  (format file "~,2f ~,2f~%" curr-x curr-y)
				  (format file "~,2f ~,2f " curr-x curr-y)
				  (setf point-state 1))))
			   (ccase point-state
			     (1 (progn
				  (format file "~,2f ~,2f " curr-x curr-y)
				  (setf point-state 2)))))))

		   (let* ((point (aref points 0))
			  (curr-x (+ (x point) add-x))
			  (curr-y (+ (y point) add-y)))
		     (if (on-curve-p point)
			 (ccase point-state
			   (1 (let* ((prev-point (aref points (1- (length points))))
				     (prev-x (+ (x prev-point) add-x))
				     (prev-y (+ (y prev-point) add-y)))
				(format file "~,2f ~,2f " (/ (+ curr-x prev-x) 2) (/ (+ curr-y prev-y) 2))
				(format file "~,2f ~,2f~%" curr-x curr-y)
				(setf point-state 3)))
			   (2 (progn
				(format file "~,2f ~,2f~%" curr-x curr-y)
				(setf point-state 3))))
			 (cerror "first point is off curve" ""))))))

	     (format file "~%advance-width~%~,2f~%" (advance-width glyph))
	     (format file "~%render-box x-min y-min x-max y-max~%~,2f ~,2f ~,2f ~,2f~%" (aref mono-render-box 0) (aref mono-render-box 1) (aref mono-render-box 2) (aref mono-render-box 3))
	     (format file "~%glyph-info-end~%"))))

    (let ((dir-path (concatenate 'string "/home/chaewon/Desktop/chae1/github/editor/font/txt/" font-name "/")))
      (ensure-directories-exist dir-path)
      (loop for c in '(#\a #\b #\c #\d #\e #\f #\g #\h #\i #\j #\k #\l #\m #\n #\o #\p #\q #\r #\s #\t #\u #\v #\w #\x #\y #\z #\A #\B #\C #\D #\E #\F #\G #\H #\I #\J #\K #\L #\M #\N #\O #\P #\Q #\R #\S #\T #\U #\V #\W #\X #\Y #\Z #\` #\~ #\! #\@ #\# #\$ #\% #\^ #\& #\* #\( #\) #\- #\_ #\+ #\= #\{ #\} #\[ #\] #\| #\\ #\; #\: #\' #\" #\, #\. #\< #\> #\? #\/ #\1 #\2 #\3 #\4 #\5 #\6 #\7 #\8 #\9 #\0) do
        (let ((path (concatenate 'string (concatenate 'string dir-path (gethash c *char->name*)) ".txt")))
          (with-open-file (file path :direction :output :if-exists :supersede :if-does-not-exist :create)
            (generate-char-info c file))))
      (let ((path (concatenate 'string (concatenate 'string dir-path "font-txt.info"))))
	(with-open-file (file path :direction :output :if-exists :supersede :if-does-not-exist :create)
	  (format file "font~%~a~%" font-name)
	  (format file "~%ttf-path~%~,2f~%" font-path)
	  (format file "~%em~%~,2f~%" (units/em font-loader))
          (format file "~%line-height~%~,2f~%" line-height)
	  (format file "~%font-info-end~%"))))))

(generate-font-info *ubuntumono-r*)
