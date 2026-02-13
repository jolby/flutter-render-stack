;;;; flutter-render-stack/impeller/color-filters.lisp
;;;; Color filters for tinting, blending, and color matrix transformations

(in-package :flutter-render-stack)

;;; Blend mode enum converter

(rs-internals:define-case-converter (:blend-mode-keyword :blend-mode-int)
  (:clear 0)
  (:source 1)
  (:destination 2)
  (:source-over 3)
  (:destination-over 4)
  (:source-in 5)
  (:destination-in 6)
  (:source-out 7)
  (:destination-out 8)
  (:source-atop 9)
  (:destination-atop 10)
  (:xor 11)
  (:plus 12)
  (:modulate 13)
  (:screen 14)
  (:overlay 15)
  (:darken 16)
  (:lighten 17)
  (:color-dodge 18)
  (:color-burn 19)
  (:hard-light 20)
  (:soft-light 21)
  (:difference 22)
  (:exclusion 23)
  (:multiply 24)
  (:hue 25)
  (:saturation 26)
  (:color 27)
  (:luminosity 28))

;;; Color filter creation and management

(defun make-blend-color-filter (color blend-mode)
  "Create a blend color filter.

Arguments:
  color      - Color as integer (e.g., #xFFFF0000 for red)
  blend-mode - Blend mode keyword:
               :clear, :source, :destination, :source-over, :destination-over,
               :source-in, :destination-in, :source-out, :destination-out,
               :source-atop, :destination-atop, :xor, :plus, :modulate,
               :screen, :overlay, :darken, :lighten, :color-dodge, :color-burn,
               :hard-light, :soft-light, :difference, :exclusion, :multiply,
               :hue, :saturation, :color, :luminosity

Returns a color filter object, or NIL if creation fails.

The blend filter applies the blend mode between the source color
and the destination (the drawn content).

Example:
  ;; Tint everything red with 50% opacity
  (let ((tint (make-blend-color-filter #x80FF0000 :source-over)))
    (paint-set-color-filter paint tint)
    (draw-rect builder paint 0 0 100 100)
    (release-color-filter tint))

  ;; Invert colors using difference blend
  (let ((invert (make-blend-color-filter #xFFFFFFFF :difference)))
    ...)"
  (cffi-c-ref:c-with ((col (:struct impeller-ffi:color)))
    (setf (col :red) (logand (ash color -16) #xFF)
          (col :green) (logand (ash color -8) #xFF)
          (col :blue) (logand color #xFF)
          (col :alpha) (logand (ash color -24) #xFF))
    (let ((filter (impeller-ffi:color-filter-create-blend-new
                   (col &)
                   (blend-mode-keyword->blend-mode-int blend-mode))))
      (unless (cffi:null-pointer-p filter)
        filter))))

(defun make-color-matrix-filter (matrix)
  "Create a color matrix filter.

Arguments:
  matrix - 4x5 color matrix as a flat list of 20 floats:
           [r r r r r-offset    (red channel)
            g g g g g-offset    (green channel)
            b b b b b-offset    (blue channel)
            a a a a a-offset]   (alpha channel)

The matrix transforms colors as:
  R' = r[0]*R + r[1]*G + r[2]*B + r[3]*A + r[4]
  G' = g[0]*R + g[1]*G + g[2]*B + g[3]*A + g[4]
  B' = b[0]*R + b[1]*G + b[2]*B + b[3]*A + b[4]
  A' = a[0]*R + a[1]*G + a[2]*B + a[3]*A + a[4]

Common matrices:
  - Identity:     [1 0 0 0 0, 0 1 0 0 0, 0 0 1 0 0, 0 0 0 1 0]
  - Grayscale:    [0.33 0.33 0.33 0 0, ...]
  - Sepia:        [0.393 0.769 0.189 0 0, 0.349 0.686 0.168 0 0, ...]
  - Invert:       [-1 0 0 0 255, 0 -1 0 0 255, 0 0 -1 0 255, 0 0 0 1 0]

Returns a color filter object, or NIL if creation fails."
  (declare (type list matrix))
  (unless (= (length matrix) 20)
    (error "Color matrix must have exactly 20 elements (4x5)"))
  (cffi-c-ref:c-with ((mat (:struct impeller-ffi:color-matrix)))
    (loop for i from 0 below 20
          do (setf (cffi:mem-aref (mat &) :float i)
                   (float (nth i matrix) 1.0f0)))
    (let ((filter (impeller-ffi:color-filter-create-color-matrix-new (mat &))))
      (unless (cffi:null-pointer-p filter)
        filter))))

(defun release-color-filter (color-filter)
  "Release a color filter and free its resources.

Arguments:
  color-filter - Color filter from make-blend-color-filter or make-color-matrix-filter

Must be called exactly once per color filter created."
  (unless (cffi:null-pointer-p color-filter)
    (impeller-ffi:color-filter-release color-filter)))

(defun paint-set-color-filter (paint color-filter)
  "Apply a color filter to a paint.

Arguments:
  paint        - Paint object from make-paint
  color-filter - Color filter, or NIL to clear

The color filter transforms the colors of everything drawn with the paint.

Example:
  ;; Grayscale effect
  (let ((gray (make-grayscale-filter)))
    (paint-set-color-filter paint gray)
    ;; Everything drawn with this paint will be grayscale
    (draw-image builder paint image 0 0)
    (release-color-filter gray)))"
  (impeller-ffi:paint-set-color-filter paint color-filter))

;;; Convenience functions for common color effects

(defun make-grayscale-filter ()
  "Create a grayscale color filter.

Returns a filter that converts colors to grayscale using luminance weights."
  (make-color-matrix-filter
   '(0.33 0.33 0.33 0.0 0.0   ; Red channel
     0.33 0.33 0.33 0.0 0.0   ; Green channel
     0.33 0.33 0.33 0.0 0.0   ; Blue channel
     0.0  0.0  0.0  1.0 0.0)) ; Alpha channel (unchanged)
)

(defun make-sepia-filter ()
  "Create a sepia (vintage photo) color filter."
  (make-color-matrix-filter
   '(0.393 0.769 0.189 0.0 0.0
     0.349 0.686 0.168 0.0 0.0
     0.272 0.534 0.131 0.0 0.0
     0.0   0.0   0.0   1.0 0.0)))

(defun make-invert-filter ()
  "Create a color inversion filter."
  (make-color-matrix-filter
   '(-1.0 0.0  0.0  0.0  255.0
      0.0 -1.0 0.0  0.0  255.0
      0.0 0.0  -1.0 0.0  255.0
      0.0 0.0  0.0  1.0  0.0)))

(defun make-brightness-filter (amount)
  "Create a brightness adjustment filter.

Arguments:
  amount - Brightness adjustment (-1.0 to 1.0, where 0.0 is unchanged)"
  (let ((offset (* amount 255)))
    (make-color-matrix-filter
     `(1.0 0.0 0.0 0.0 ,offset
       0.0 1.0 0.0 0.0 ,offset
       0.0 0.0 1.0 0.0 ,offset
       0.0 0.0 0.0 1.0 0.0))))

(defun make-contrast-filter (amount)
  "Create a contrast adjustment filter.

Arguments:
  amount - Contrast multiplier (1.0 is unchanged, 0.0 is gray, >1.0 more contrast)"
  (let ((offset (* (- 1.0 amount) 0.5 255)))
    (make-color-matrix-filter
     `(,amount 0.0     0.0     0.0 ,offset
       0.0     ,amount 0.0     0.0 ,offset
       0.0     0.0     ,amount 0.0 ,offset
       0.0     0.0     0.0     1.0 0.0))))

(defun make-saturation-filter (amount)
  "Create a saturation adjustment filter.

Arguments:
  amount - Saturation multiplier (1.0 is unchanged, 0.0 is grayscale)"
  (let* ((inv (- 1.0 amount))
         (r (* inv 0.299))
         (g (* inv 0.587))
         (b (* inv 0.114)))
    (make-color-matrix-filter
     `(,(+ r amount) ,g           ,b           0.0 0.0
       ,r           ,(+ g amount) ,b           0.0 0.0
       ,r           ,g           ,(+ b amount) 0.0 0.0
       0.0          0.0          0.0          1.0 0.0))))

(defun make-tint-filter (color &optional (blend-mode :source-over))
  "Create a color tint filter.

Arguments:
  color       - Tint color as integer
  blend-mode  - How to blend the tint (default: :source-over)

Returns a filter that tints content with the specified color."
  (make-blend-color-filter color blend-mode))
