;;;; flutter-render-stack/impeller/paint.lisp
;;;; Impeller paint object management

(in-package :flutter-render-stack)

;;; Enum converters for paint properties

(rs-internals:define-case-converter (:draw-style-keyword :draw-style-int)
  (:fill 0) (:stroke 1) (:stroke-and-fill 2))

(rs-internals:define-case-converter (:stroke-cap-keyword :stroke-cap-int)
  (:butt 0) (:round 1) (:square 2))

(rs-internals:define-case-converter (:stroke-join-keyword :stroke-join-int)
  (:miter 0) (:round 1) (:bevel 2))

;;; Paint lifecycle

(defun make-paint ()
  "Create an Impeller paint object.

Returns a pointer to an ImpellerPaint object. Raises
impeller-creation-error if paint creation fails.

The returned paint must be released via release-paint."
  (let ((paint (impeller-ffi:paint-new)))
    (when (cffi:null-pointer-p paint)
      (error 'impeller-creation-error :resource-type "paint"))
    paint))

(defun release-paint (paint)
  "Release an Impeller paint object.

Frees all resources associated with the paint. Must be called
exactly once per paint created via make-paint."
  (impeller-ffi:paint-release paint))

;;; Paint properties

(defun paint-set-color (paint red green blue alpha)
  "Set the color of an Impeller paint object.

Arguments:
  paint  - Paint object from make-paint
  red    - Red component (0.0 to 1.0)
  green  - Green component (0.0 to 1.0)
  blue   - Blue component (0.0 to 1.0)
  alpha  - Alpha component (0.0 to 1.0)

Returns nil. Modifies paint in place."
  (cffi-c-ref:c-with ((color (:struct impeller-ffi:color)))
    (setf (color :red) (float red 1.0f0)
          (color :green) (float green 1.0f0)
          (color :blue) (float blue 1.0f0)
          (color :alpha) (float alpha 1.0f0))
    (impeller-ffi:paint-set-color paint (color &)))
  nil)

(defun paint-set-draw-style (paint style)
  "Set the draw style of an Impeller paint object.

Arguments:
  paint  - Paint object from make-paint
  style  - :fill (default), :stroke, or :stroke-and-fill

Returns nil. Modifies paint in place."
  (impeller-ffi:paint-set-draw-style paint (draw-style-keyword->draw-style-int style))
  nil)

(defun paint-set-stroke-width (paint width)
  "Set the stroke width of an Impeller paint object.

Arguments:
  paint  - Paint object from make-paint
  width  - Width in logical pixels (float)

Returns nil. Modifies paint in place."
  (impeller-ffi:paint-set-stroke-width paint (float width 1.0f0))
  nil)

(defun paint-set-stroke-cap (paint cap)
  "Set the stroke cap style of an Impeller paint object.

Arguments:
  paint  - Paint object from make-paint
  cap    - :butt (default), :round, or :square

Returns nil. Modifies paint in place."
  (impeller-ffi:paint-set-stroke-cap paint (stroke-cap-keyword->stroke-cap-int cap))
  nil)

(defun paint-set-stroke-join (paint join)
  "Set the stroke join style of an Impeller paint object.

Arguments:
  paint  - Paint object from make-paint
  join   - :miter (default), :round, or :bevel

Returns nil. Modifies paint in place."
  (impeller-ffi:paint-set-stroke-join paint (stroke-join-keyword->stroke-join-int join))
  nil)

(defun paint-set-stroke-miter (paint miter)
  "Set the stroke miter limit of an Impeller paint object.

Arguments:
  paint  - Paint object from make-paint
  miter  - Miter limit (float)

Returns nil. Modifies paint in place."
  (impeller-ffi:paint-set-stroke-miter paint (float miter 1.0f0))
  nil)

(defun paint-set-color-source (paint color-source)
  "Set a color source (gradient, image, etc.) on a paint.

Arguments:
  paint        - Paint object from make-paint
  color-source - Color source, or nil/null-pointer to clear

Returns nil. Modifies paint in place."
  (impeller-ffi:paint-set-color-source
   paint
   (if (or (null color-source) (cffi:null-pointer-p color-source))
       (cffi:null-pointer)
       color-source))
  nil)
