#lang racket

(define (null-ld? obj)
  (if (and (ld? obj) (eq? (car obj) (cdr obj)))    ; if car listdiff and cdr listdiff are same obj in memory
      #t
      #f))

(define (ld? obj)
  (if (pair? obj)
      (if (eq? (car obj) (cdr obj))      ; car listdiff must eq? cdr listdiff
          #t
          (if (pair? (car obj))           ; or be a pair
              (ld? (cons (cdr (car obj)) (cdr obj)))
              #f))
      #f))


; the listdiff must be a list s.t. cons obj and the ld of listdiff returns the same thing
; piazza example cons-ld 'o '((a e i o u . y) i o u .y) -> '((o a e i o u . y) i o u . y)
(define (cons-ld obj listdiff)
  (cons (cons obj (car listdiff)) (cdr listdiff)))

(define (car-ld listdiff)
  (if (or (not (ld? listdiff)) (null-ld? listdiff))
      'error
      (car (car listdiff))))

(define (cdr-ld listdiff)
  (if (or (not (ld? listdiff)) (null-ld? listdiff))
      'error
      (if (ld? (cons (cdr (car listdiff)) (cdr listdiff)))  ; need to check that returned obj is listdiff
          (cons (cdr (car listdiff)) (cdr listdiff))
          'error)))

; construct a listdiff from the arguments
; use fewest number of cons cells possible
(define (ld . args)
  (cons args empty))

; length of the list listdiff represents
(define (length-ld listdiff)
  (if (not (ld? listdiff))
      'error
      (length-ld-helper listdiff 0)))

(define (append-ld . args)
  (if (not (equal? args empty))
      (append-ld-helper args '())
      (ld)))

(define (append-ld-helper args l)
  (if (not (equal? (cdr args) empty))
      (append-ld-helper (cdr args) (append l (ld->list (first args))))   ; get all list representations of first n-1 listdiffs
      (cons (append l (car (first args))) (cdr (first args)))))         ;; append listdiffs into big listdiff with same ending structure as last (nth) listdiff


(define (length-ld-helper listdiff n)
  (if (or (null-ld? listdiff) (not (ld? listdiff)))
      n
      (length-ld-helper (cons (cdr (car listdiff)) (cdr listdiff)) (+ 1 n))))


(define (ld-tail listdiff k)
  (if (ld? listdiff)
      (if (= k 0)
          listdiff       ; reached removed all elements needed to be removed in listdiff
          (if (null-ld? listdiff)
              'error    ; k != 0, but there's no more elements to remove in the listdiff since null-ld is true
              (ld-tail (cons (cdr (car listdiff)) (cdr listdiff)) (- k 1))))    ; we can safely remove an element
      'error))   ; if not a listdiff

(define (list->ld l)
  (if (equal? l empty)
      (ld)         ; if list is empty, generate random equivalent ld
      (cons l empty)))


; convert ld to list
(define (ld->list listdiff)
  (ld->list-helper listdiff empty))
  
(define (ld->list-helper listdiff l)
  (if (ld? listdiff)
      (if (null-ld? listdiff)
          l
          (ld->list-helper (cons (cdr (car listdiff)) (cdr listdiff)) (append l (list (car (car listdiff))))))
      l))



;; map-ld
(define (map-ld proc . args)
  (map-ld-helper proc args empty))


(define (map-ld-helper proc args res)
  (if (map-list-empty-listdiffs? args)
      res
      (map-ld-helper proc (map cdr-ld args) (append res (list (apply proc (map car-ld args)))))))  ; get the first of each listdiff in list, apply proc to them, then run recursively on cdr-ld of each listdiff

(define (map-list-empty-listdiffs? l)
  (if (or (empty? l) (null-ld? (car l)))
      #t
      #f))


; expr2ld takes in expr in list form
(define (expr2ld expr)
  (expr2ld-helper expr empty))

; pattern match against procedures that need translation
(define (expr2ld-helper expr res)
  (if (not (equal? expr empty))
      (cond
        [(equal? (car expr) 'null?) (expr2ld-helper (cdr expr) (append res (list 'null-ld?)))]
        [(equal? (car expr) 'list?) (expr2ld-helper (cdr expr) (append res (list 'ld?)))]
        [(equal? (car expr) 'cons) (expr2ld-helper (cdr expr) (append res (list 'cons-ld)))]
        [(equal? (car expr) 'car) (expr2ld-helper (cdr expr) (append res (list 'car-ld)))]
        [(equal? (car expr) 'cdr) (expr2ld-helper (cdr expr) (append res (list 'cdr-ld)))]
        [(equal? (car expr) 'list) (expr2ld-helper (cdr expr) (append res (list 'ld)))]
        [(equal? (car expr) 'length) (expr2ld-helper (cdr expr) (append res (list 'length-ld)))]
        [(equal? (car expr) 'append) (expr2ld-helper (cdr expr) (append res (list 'append-ld)))]
        [(equal? (car expr) 'list-tail) (expr2ld-helper (cdr expr) (append res (list 'ld-tail)))]
        [(equal? (car expr) 'map) (expr2ld-helper (cdr expr) (append res (list 'map-ld)))]
        [(list? (car expr)) (expr2ld-helper (cdr expr) (append res (list (expr2ld-helper (car expr) empty))))]   ;;; need to iterate through inside lists
        [else (expr2ld-helper (cdr expr) (append res (list (car expr))))]    ; don't do anything
        )
      res)
  )