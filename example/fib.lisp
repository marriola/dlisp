(setq fibcache (make-array 1000))

(defun fib (n)
    (let ((cached-number (elt fibcache n)))
        (if (null cached-number)
            (setf cached-number
                (if (<= n 2)
                    1
                    (+
                        (fib (- n 2))
                        (fib (- n 1))
                    )
                )
            )
            cached-number
        )
    )
)