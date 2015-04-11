(defun range (start stop &optional out)
    "Returns a list containing numbers in the interval (start, stop]"
    (if (= start stop)
        out
        (append
            (list start)
            (range
                (+ start 1)
                stop))
    )
)