(defun random-list (n limit &optional out)
    (if (= n 0)
        out
        (random-list
            (1- n)
            limit
            (append out (list (random limit)))
        )
    )
)

(defun test-sort (f n limit)
    "Sorts a list of n random numbers in the range (0, limit] with function f"
    (funcall f (random-list n limit))
)

(load :example/quicksort.lisp)