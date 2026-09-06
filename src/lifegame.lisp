;;; Copyright (c) 2026 Chez Naijamn
;;;
;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use, copy,
;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;; DEALINGS IN THE SOFTWARE.

(defpackage :lifegame
  (:use :cl)
  (:export #:run))

(in-package :lifegame)

(defparameter *alive-num*    0)
(defparameter *board-width*  0)
(defparameter *board-height* 0)
(defparameter *cells*        nil)



(defstruct cell
  state
  next)

(defun init-cell-status (rate)
  (if (< (random 1.0) rate)
      :born
      :dead))



(defun init-board (rate)
  (setf *alive-num* 0)
  (dotimes (i *board-height*)
    (dotimes (j *board-width*)
      (let* ((idx (+ (* i *board-width*) j))
             (state (init-cell-status rate))
             (cell (aref *cells* idx)))
        (setf (cell-state cell) state
              (cell-next  cell) :dead)
        (unless (eql state :dead)
          (incf *alive-num*))))))

(defun count-non-dead-around (i j)
  (let ((count 0))
    (loop for ii from (1- i) to (1+ i)
          do (loop for jj from (1- j) to (1+ j)
                   unless (or (< ii 0)
                              (>= ii *board-height*)
                              (< jj 0)
                              (>= jj *board-width*)
                              (and (= ii i) (= jj j)))
                   do (let ((cell (aref *cells* (+ (* ii *board-width*) jj))))
                        (unless (eql (cell-state cell) :dead)
                          (incf count)))))
    count))

(defun update-board ()
  ;; Calculate next state
  (dotimes (i *board-height*)
    (dotimes (j *board-width*)
      (let* ((cell (aref *cells* (+ (* i *board-width*) j)))
             (state (cell-state cell))
             (neighbors (count-non-dead-around i j)))
        (setf (cell-next cell)
              (cond
                ((and (= neighbors 3) (eql state :dead))
                 :born)
                ((and (or (= neighbors 2)
                          (= neighbors 3))
                      (not (eql state :dead)))
                 :alive)
                (t :dead))))))

  (setf *alive-num* 0)

  ;; Commit next state.
  (dotimes (i *board-height*)
    (dotimes (j *board-width*)
      (let ((cell (aref *cells* (+ (* i *board-width*) j))))
        (setf (cell-state cell) (cell-next cell))
        (unless (eql (cell-state cell) :dead)
          (incf *alive-num*))))))



(defparameter +cell-born+  #\.)
(defparameter +cell-alive+ #\*)
(defparameter +cell-dead+  #\Space)

(defun cell-character (cell)
  (case (cell-state cell)
    (:born  +cell-born+)
    (:alive +cell-alive+)
    (:dead  +cell-dead+)))

(defun print-cell (cell i j)
  (charms:write-char-at-point charms:*standard-window*
                              (cell-character cell)
                              j
                              i))

(defun print-board ()
  (dotimes (i *board-height*)
    (dotimes (j *board-width*)
      (print-cell (aref *cells* (+ (* i *board-width*) j))
                  i
                  j))))

(defun print-summary (gen cycles)
  (charms:write-string-at-point charms:*standard-window*
                                (format nil
                                        "GENERATION: ~D/~D ALIVE: ~D"
                                        gen
                                        cycles
                                        *alive-num*)
                                0
                                (1+ *board-height*)))



(defun run (&key (cycles 800) (rate 0.3) (delay 0.05))
  (charms:with-curses ()
    (charms:disable-echoing)
    (charms:enable-raw-input :interpret-control-characters t)
    (charms:enable-non-blocking-mode charms:*standard-window*)

    (multiple-value-bind (width height)
        (charms:window-dimensions charms:*standard-window*)
      (progn
        (setf *board-width* width
              *board-height* (- height 2)
              *cells* (make-array (* *board-width* *board-height*)))

        (dotimes (i (array-total-size *cells*))
          (setf (aref *cells* i) (make-cell :state :dead :next :dead)))

        (init-board rate)
        (print-board)
        (print-summary 0 cycles)
        (charms:refresh-window charms:*standard-window*)

        (loop named driver-loop
              with i = 0
              for c = (charms:get-char charms:*standard-window*
                                       :ignore-error t)
              do (case c
                   ((#\q #\Q) (return-from driver-loop)))
                 (sleep delay)
              if (< i cycles)
                do (charms:clear-window charms:*standard-window*)
                   (update-board)
                   (print-board)
                   (print-summary (1+ i) cycles)
                   (charms:refresh-window charms:*standard-window*)
                   (incf i))))))
