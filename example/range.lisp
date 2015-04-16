(defun range (start stop &optional out)
    "Returns a list containing numbers in the interval (start, stop]"
    (if (<= stop start)
        out
        (append
            (list start)
            (range
                (+ start 1)
                stop))
    )
)