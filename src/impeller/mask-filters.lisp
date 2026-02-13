;;;; flutter-render-stack/impeller/mask-filters.lisp
;;;; Mask filter effects for blur, shadows, and glow

(in-package :flutter-render-stack)

;;; Blur style enum converter

(rs-internals:define-case-converter (:blur-style-keyword :blur-style-int)
  (:normal 0)   ; Gaussian blur with source included
  (:solid 1)    ; Gaussian blur with solid color (ignores source alpha)
  (:outer 2)    ; Gaussian blur outside the source shape only
  (:inner 3))   ; Gaussian blur inside the source shape only

;;; Mask filter creation and management

(defun make-blur-mask-filter (style sigma)
  "Create a blur mask filter for drop shadows, glow effects, and blur.

Arguments:
  style - Blur style keyword:
          :normal - Full Gaussian blur including the source
          :solid  - Solid color blur (ignores source alpha, good for shadows)
          :outer  - Blur only outside the shape (halo/glow effect)
          :inner  - Blur only inside the shape (inner shadow/glow)
  sigma - Blur radius in logical pixels (float). Higher = more blur.

Returns a mask filter object, or NIL if creation fails.

The returned filter must be released via release-mask-filter when no
longer needed.

Example:
  ;; Drop shadow effect
  (let ((shadow (make-blur-mask-filter :solid 8.0)))
    (unwind-protect
         (progn
           (paint-set-mask-filter paint shadow)
           (draw-rect builder paint 10 10 100 100))
      (release-mask-filter shadow)))

  ;; Inner glow effect
  (let ((glow (make-blur-mask-filter :inner 5.0)))
    ...)

Note: Mask filters are applied to the alpha channel of the paint.
For colored shadows, set the paint color before applying the filter."
  (declare (type float sigma))
  (let ((filter (impeller-ffi:mask-filter-create-blur-new
                 (blur-style-keyword->blur-style-int style)
                 (float sigma 1.0f0))))
    (unless (cffi:null-pointer-p filter)
      filter)))

(defun release-mask-filter (mask-filter)
  "Release a mask filter and free its resources.

Arguments:
  mask-filter - Mask filter from make-blur-mask-filter

Must be called exactly once per mask filter created."
  (unless (cffi:null-pointer-p mask-filter)
    (impeller-ffi:mask-filter-release mask-filter)))

(defun paint-set-mask-filter (paint mask-filter)
  "Apply a mask filter to a paint.

Arguments:
  paint       - Paint object from make-paint
  mask-filter - Mask filter from make-blur-mask-filter, or NIL to clear

The mask filter affects how the paint's alpha channel is rendered,
creating blur, shadow, or glow effects.

Example:
  ;; Apply drop shadow
  (let ((shadow (make-blur-mask-filter :solid 10.0))
        (paint (make-paint)))
    (unwind-protect
         (progn
           (paint-set-color paint #xFF000000)  ; Black shadow
           (paint-set-mask-filter paint shadow)
           ;; Now draw with this paint creates a shadow
           (draw-rect builder paint 50 50 200 100))
      (release-mask-filter shadow)
      (release-paint paint)))"
  (impeller-ffi:paint-set-mask-filter paint mask-filter))

;;; Convenience functions for common effects

(defun make-drop-shadow-filter (sigma &optional (color #xFF000000))
  "Create a mask filter for drop shadows.

Arguments:
  sigma - Blur radius for the shadow (float)
  color - Shadow color as integer (default: black #xFF000000)

Returns a mask filter configured for drop shadow effects.

Example:
  (let ((shadow (make-drop-shadow-filter 8.0 #x80000000)))  ; Semi-transparent black
    (paint-set-mask-filter paint shadow)
    (draw-text ...))"
  (declare (ignore color))
  (make-blur-mask-filter :solid sigma))

(defun make-outer-glow-filter (sigma)
  "Create a mask filter for outer glow effects.

Arguments:
  sigma - Glow radius (float)

Returns a mask filter for halo/glow outside shapes."
  (make-blur-mask-filter :outer sigma))

(defun make-inner-shadow-filter (sigma)
  "Create a mask filter for inner shadow effects.

Arguments:
  sigma - Shadow radius (float)

Returns a mask filter for shadows inside shapes."
  (make-blur-mask-filter :inner sigma))
