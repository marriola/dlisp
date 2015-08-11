(defun quicksort (x)
    (cond
        ((null x) nil)
        ((= (length x) 1) x)
        (t
            (let*
                ((pivot (first x))
                (remaining (rest x))
                (smaller (quicksort
                            (remove-if-not
                                (lambda (n)
                                    (<= n pivot))
                                remaining)))
                (bigger (quicksort
                            (remove-if-not
                                (lambda (n)
                                    (> n pivot))
                                remaining))))

                (append smaller (list pivot) bigger)
            )
        )
    )
)