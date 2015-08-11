(defun range (start stop)
    "Returns a list containing numbers in the interval (start, stop)"
    (if (< stop start)
        nil
        (append
            (list start)
            (range
                (+ start 1)
                stop))
    )
)