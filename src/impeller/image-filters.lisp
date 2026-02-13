;;;; flutter-render-stack/impeller/image-filters.lisp
;;;; Image filters for blur, morphological operations, and transformations

(in-package :flutter-render-stack)

;;; Enum converters

(rs-internals:define-case-converter (:tile-mode-keyword :tile-mode-int)
  (:clamp 0)   ; Edge pixels extend to infinity
  (:repeat 1)  ; Texture repeats
  (:mirror 2)  ; Texture mirrors/reverses
  (:decal 3))  ; Transparent outside bounds

(rs-internals:define-case-converter (:texture-sampling-keyword :texture-sampling-int)
  (:nearest-neighbor 0)  ; Sharp, pixelated
  (:linear 1))           ; Smooth, interpolated

;;; Image filter creation and management

(defun make-blur-image-filter (x-sigma y-sigma &optional (tile-mode :clamp))
  "Create a Gaussian blur image filter.

Arguments:
  x-sigma   - Horizontal blur radius (float)
  y-sigma   - Vertical blur radius (float)
  tile-mode - How to handle edges: :clamp, :repeat, :mirror, :decal

Returns an image filter object, or NIL if creation fails.

The returned filter must be released via release-image-filter.

Example:
  ;; Horizontal motion blur
  (let ((blur (make-blur-image-filter 20.0 0.0)))
    (unwind-protect
         (progn
           (paint-set-image-filter paint blur)
           (draw-rect builder paint 0 0 100 100))
      (release-image-filter blur)))

  ;; Soft shadow effect
  (let ((shadow (make-blur-image-filter 10.0 10.0 :decal)))
    ...)"
  (declare (type float x-sigma y-sigma))
  (let ((filter (impeller-ffi:image-filter-create-blur-new
                 (float x-sigma 1.0f0)
                 (float y-sigma 1.0f0)
                 (tile-mode-keyword->tile-mode-int tile-mode))))
    (unless (cffi:null-pointer-p filter)
      filter)))

(defun make-dilate-image-filter (x-radius y-radius)
  "Create a dilation (morphological max) image filter.

Arguments:
  x-radius - Horizontal dilation radius (float)
  y-radius - Vertical dilation radius (float)

Dilation expands bright areas and thickens shapes. Useful for creating
outline/glow effects around dark objects on light backgrounds.

Returns an image filter object, or NIL if creation fails."
  (declare (type float x-radius y-radius))
  (let ((filter (impeller-ffi:image-filter-create-dilate-new
                 (float x-radius 1.0f0)
                 (float y-radius 1.0f0))))
    (unless (cffi:null-pointer-p filter)
      filter)))

(defun make-erode-image-filter (x-radius y-radius)
  "Create an erosion (morphological min) image filter.

Arguments:
  x-radius - Horizontal erosion radius (float)
  y-radius - Vertical erosion radius (float)

Erosion shrinks bright areas and thins shapes. Useful for creating
inner outlines or sharpening effects.

Returns an image filter object, or NIL if creation fails."
  (declare (type float x-radius y-radius))
  (let ((filter (impeller-ffi:image-filter-create-erode-new
                 (float x-radius 1.0f0)
                 (float y-radius 1.0f0))))
    (unless (cffi:null-pointer-p filter)
      filter)))

(defun compose-image-filters (outer-filter inner-filter)
  "Compose two image filters together.

Arguments:
  outer-filter - The outer image filter (applied second)
  inner-filter - The inner image filter (applied first)

Returns a new composed filter that applies inner-filter first,
then outer-filter. The original filters remain valid and must
still be released separately.

Example:
  ;; Blur then dilate (creates expanded blur)
  (let* ((blur (make-blur-image-filter 5.0 5.0))
         (dilate (make-dilate-image-filter 3.0 3.0))
         (composed (compose-image-filters dilate blur)))
    (unwind-protect
         (paint-set-image-filter paint composed)
      (release-image-filter composed)
      (release-image-filter dilate)
      (release-image-filter blur)))"
  (let ((filter (impeller-ffi:image-filter-create-compose-new
                 outer-filter inner-filter)))
    (unless (cffi:null-pointer-p filter)
      filter)))

(defun make-matrix-image-filter (matrix-3x3 &optional (sampling :linear))
  "Create a matrix transformation image filter.

Arguments:
  matrix-3x3 - 3x3 transformation matrix as a flat list of 9 floats:
               [m0 m1 m2    (maps to: m00 m01 m02)
                m3 m4 m5    (maps to: m10 m11 m12)
                m6 m7 m8]   (maps to: m20 m21 m22)
  sampling   - :nearest-neighbor or :linear (default)

The matrix transforms source image coordinates to destination.
Common transformations:
  - Translation: [1 0 tx, 0 1 ty, 0 0 1]
  - Scale:       [sx 0 0, 0 sy 0, 0 0 1]
  - Rotate:      [cos -sin 0, sin cos 0, 0 0 1]

Returns an image filter object, or NIL if creation fails."
  (declare (type list matrix-3x3))
  (unless (= (length matrix-3x3) 9)
    (error "Matrix must have exactly 9 elements (3x3)"))
  ;; Convert 3x3 to 4x4 matrix for Impeller
  (cffi-c-ref:c-with ((mat (:struct impeller-ffi:matrix)))
    ;; Initialize to identity
    (loop for i from 0 below 16
          do (setf (cffi:mem-aref (mat &) :float i) 
                   (if (or (= i 0) (= i 5) (= i 10) (= i 15)) 1.0 0.0)))
    ;; Fill in 3x3 portion
    (let ((src-idx 0))
      (loop for row from 0 below 3
            do (loop for col from 0 below 3
                     do (setf (cffi:mem-aref (mat &) :float (+ (* row 4) col))
                              (float (nth src-idx matrix-3x3) 1.0f0))
                        (incf src-idx))))
    (let ((filter (impeller-ffi:image-filter-create-matrix-new
                   (mat &)
                   (texture-sampling-keyword->texture-sampling-int sampling))))
      (unless (cffi:null-pointer-p filter)
        filter))))

(defun release-image-filter (image-filter)
  "Release an image filter and free its resources.

Arguments:
  image-filter - Image filter from make-*-image-filter functions

Must be called exactly once per image filter created."
  (unless (cffi:null-pointer-p image-filter)
    (impeller-ffi:image-filter-release image-filter)))

(defun paint-set-image-filter (paint image-filter)
  "Apply an image filter to a paint.

Arguments:
  paint         - Paint object from make-paint
  image-filter  - Image filter, or NIL to clear

The image filter is applied to the entire rendered output of the paint.

Example:
  (let ((blur (make-blur-image-filter 5.0 5.0))
        (paint (make-paint)))
    (unwind-protect
         (progn
           (paint-set-image-filter paint blur)
           (paint-set-color paint #xFFFF0000)
           ;; Everything drawn with this paint will be blurred
           (draw-rect builder paint 0 0 100 100))
      (release-image-filter blur)
      (release-paint paint)))"
  (impeller-ffi:paint-set-image-filter paint image-filter))

;;; Convenience functions for common effects

(defun make-drop-shadow-image-filter (dx dy sigma &optional (color #xFF000000))
  "Create an image filter for drop shadows.

Arguments:
  dx     - Horizontal shadow offset (float)
  dy     - Vertical shadow offset (float)
  sigma  - Shadow blur radius (float)
  color  - Shadow color (default: black)

Returns an image filter that creates a drop shadow effect.
Note: This is a simplified version. Full implementation would
require composing a blur with a color filter."
  (declare (ignore dx dy color))
  (make-blur-image-filter sigma sigma :decal))

(defun make-outline-image-filter (radius)
  "Create an image filter that outlines shapes using dilation.

Arguments:
  radius - Outline thickness (float)

Returns an image filter that dilates the source, creating an outline effect."
  (make-dilate-image-filter radius radius))
