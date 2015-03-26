(setq fibcache (make-array 100))

(defun fib (n)
    (if (null (elt fibcache n))
        (setf (elt fibcache n)
            (if (<= n 2)
                1
                (+
                    (fib (- n 2))
                    (fib (- n 1))
                )
            )
        )
        (elt fibcache n)
    )
)