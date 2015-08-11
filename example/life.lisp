(defun generate-row (width &optional row)
    (if (= width 0)
        row
        (generate-row
            (1- width)
            (append row
                (list (if (= (random 3) 0)
                    t
                    nil
                ))
            )
        )
    )
)

(defun generate-matrix (height width &optional matrix)
    (if (= height 0)
        matrix
        (generate-matrix
            (1- height)
            width
            (append
                matrix
                (list (generate-row width))
            )
        )
    )
)

(defun row-to-string (row &optional (out ""))
    "Converts a life matrix row to a string to pass to format"
    (if (null row)
        (concatenate 'string out "~%")
        (row-to-string
            (rest row)
            (concatenate 'string out (if (first row) "#" " "))
        )
    )
)

(defun matrix-to-string (matrix &optional (out "") (width 0))
    "Converts a life matrix to a string to pass to format"
    (if (null matrix)
        (concatenate 'string out (make-string width :initial-element #\=) "~%")
        (matrix-to-string
            (rest matrix)
            (concatenate 'string out (row-to-string (first matrix)))
            (1+ width)
        )
    )
)

(defun print-matrix (matrix &optional (out-stream t))
    (format out-stream (matrix-to-string matrix))
)

(defun get-cell (row col matrix)
    "Returns a 1 if the cell at (row, col) is alive, 0 otherwise. Coordinates outside the matrix are considered dead."
    (let
        ((height (length matrix))
        (width (length (first matrix))))

        (if (or (< row 0) (>= row height) (< col 0) (>= col width))
            0
            (if (elt (elt matrix row) col) 1 0)
        )
    )
)

(defun count-row-neighbors (row col matrix &optional (total 0) (left 3))
    "Sums the three cells from (row, col - 1) to (row, col + 1)"
    (let*
        (
            (first-cell (get-cell row (1- col) matrix))
            (second-cell (get-cell row col matrix))
            (third-cell (get-cell row (1+ col) matrix))
        )

        (+ first-cell second-cell third-cell)
    )
)

(defun count-neighbors (row col matrix)
    "Sums all alive cells from (row - 1, col - 1) to (row + 1, col + 1), subtracting 1 if the cell at (row, col) is alive to give the neighbor count."
    (let*
        (
            (first-row (count-row-neighbors (1- row) col matrix))
            (second-row (count-row-neighbors row col matrix))
            (third-row (count-row-neighbors (1+ row) col matrix))
        )

        (- (+ first-row second-row third-row) (get-cell row col matrix))
    )
)

(defun generate-row-coordinates (row width &optional (col 0) out)
    "Generates the coordinates for each cell in a matrix row."
    (if (= col width)
        out
        (generate-row-coordinates
            row
            width
            (1+ col)
            (append out (list (list row col)))
        )
    )
)

(defun generate-matrix-coordinates (height width &optional (row 0) out)
    "Generates the coordinates for each cell in a matrix."
    (if (= row height)
        out
        (generate-matrix-coordinates
            height
            width
            (1+ row)
            (append out (list (generate-row-coordinates row width)))
        )
    )
)

(defun advance-row (width row-coordinates matrix &optional out (col 0))
    (if (= col width)
        out
        (let*
            (
                (cell-row (caar row-coordinates))
                (cell-col (cadar row-coordinates))
                (cell (get-cell cell-row cell-col matrix))
                (cell-neighbors (count-neighbors cell-row cell-col matrix))
                (next-cell
                    (if (= 1 cell)
                        (or (= cell-neighbors 2)    ; live cells stay alive if they have 2 or 3 neighbors, otherwise they die
                            (= cell-neighbors 3))
                        (= cell-neighbors 3)        ; dead cells become alive if they have 3 neighbors, otherwise they stay dead
                    )
                )
            )

            (advance-row
                width
                (rest row-coordinates)
                matrix
                (append out (list next-cell))
                (1+ col)
            )
        )
    )
)

(defun advance-matrix (height width matrix matrix-coordinates &optional out (row 0))
    (if (= row height)
        out
        (advance-matrix
            height width matrix matrix-coordinates
            (append out (list (advance-row width (elt matrix-coordinates row) matrix)))
            (1+ row)
        )
    )
)

(defun print-and-advance (&optional (times 1) (out-stream t))
    (dotimes (i times nil)
        (setq matrix (advance-matrix matrix-width matrix-height matrix matrix-coordinates))
        (print-matrix matrix out-stream)
    )
)

(defun start-life (height width)
    (setq matrix-width width)
    (setq matrix-height height)
    (setq matrix-coordinates (generate-matrix-coordinates height width))
    (setq matrix (generate-matrix height width))
)

; The following function is a convenient way to watch the game of life unfold,
; but it only works in CLISP. I honestly don't feel like going to the trouble
; of implementing CLISP's random screen access and keyboard facilities for what
; is essentially a toy project.

(defun life-loop (&optional (height 30) (width 30) (delay 0.05))
    "Starts a game of life with the specified dimensions and delay between generations. To exit, press escape. To restart with a new matrix, press enter."
    (start-life height width)
    (screen:with-window
        (loop
            (let ((key (ext:with-keyboard (read-char-no-hang ext:*keyboard-input*))))
                (if (not (null key))
                    (cond
                        ((eq (sys::input-character-char key) #\Escape)
                            (return))
                        ((eq (sys::input-character-char key) #\Return)
                            (start-life height width))
                    )
                )
            )
            (screen:set-window-cursor-position screen:*window* 0 0)
            (print-and-advance 1 screen:*window*)
            (sleep delay)
        )
    )
)