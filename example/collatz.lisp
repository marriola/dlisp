(defun collatz (n)
    (if (= n 1)
        (list 1)
        (let
            ((next-term
                (if (even n)
                    (/ n 2)
                    (+ (* n 3) 1)
                )
            ))
            (append (list n) (collatz next-term))
        )
    )
)