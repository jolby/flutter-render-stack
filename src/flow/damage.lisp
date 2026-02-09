;;;; flutter-render-stack/flow/damage.lisp
;;;; Flow frame damage tracking for partial repainting

(in-package :flutter-render-stack)

;;; ============================================================
;;; Frame damage lifecycle
;;; ============================================================

(defun make-frame-damage (width height)
  "Create a frame damage tracker for a given frame size.

Arguments:
  width  - Frame width in pixels (integer)
  height - Frame height in pixels (integer)

Returns a frame damage pointer. Must be released via release-frame-damage."
  (cffi-c-ref:c-with ((size (:struct flow-ffi:i-size)))
    (setf (size :width) width
          (size :height) height)
    (let ((damage (flow-ffi:frame-damage-new flow-ffi:+version+ (size &))))
      (when (cffi:null-pointer-p damage)
        (error 'flow-creation-error :resource-type "frame damage"))
      damage)))

(defun release-frame-damage (damage)
  "Release a frame damage tracker."
  (flow-ffi:frame-damage-release damage)
  nil)

(defun retain-frame-damage (damage)
  "Increment the reference count of a frame damage tracker."
  (flow-ffi:frame-damage-retain damage)
  nil)

(defmacro with-frame-damage ((damage-var width height) &body body)
  "Create a frame damage tracker, execute body, and release on exit.

Syntax: (with-frame-damage (damage width height) ...)"
  `(let ((,damage-var (make-frame-damage ,width ,height)))
     (unwind-protect
          (progn ,@body)
       (release-frame-damage ,damage-var))))

;;; ============================================================
;;; Frame damage operations
;;; ============================================================

(defun frame-damage-set-previous-layer-tree (damage tree)
  "Set the previous frame's layer tree for damage comparison.

Arguments:
  damage - Frame damage tracker
  tree   - Layer tree from the previous frame"
  (flow-ffi:frame-damage-set-previous-layer-tree damage tree)
  nil)

(defun frame-damage-add-additional-damage (damage x y width height)
  "Add an additional damage rectangle (integer pixel coordinates).

Arguments:
  damage        - Frame damage tracker
  x, y          - Top-left corner of damaged region (integer)
  width, height - Dimensions of damaged region (integer)"
  (cffi-c-ref:c-with ((rect (:struct flow-ffi:i-rect)))
    (setf (rect :x) x
          (rect :y) y
          (rect :width) width
          (rect :height) height)
    (flow-ffi:frame-damage-add-additional-damage damage (rect &)))
  nil)

(defun frame-damage-compute-clip-rect (damage tree)
  "Compute the minimal clip rectangle covering all damage.

Arguments:
  damage - Frame damage tracker
  tree   - Current frame's layer tree

Returns (values has-damage-p x y width height).
If has-damage-p is NIL, no repaint is needed."
  (cffi-c-ref:c-with ((clip-rect (:struct flow-ffi:i-rect)))
    (let ((has-damage (flow-ffi:frame-damage-compute-clip-rect
                       damage tree (clip-rect &))))
      (if has-damage
          (values t
                  (clip-rect :x)
                  (clip-rect :y)
                  (clip-rect :width)
                  (clip-rect :height))
          (values nil 0 0 0 0)))))

;;; ============================================================
;;; Geometry utilities (rect, point, matrix)
;;; ============================================================

(defun flow-rect-contains-point (rx ry rw rh px py)
  "Test whether a point is inside a rectangle.

Arguments:
  rx, ry - Rectangle position (float)
  rw, rh - Rectangle dimensions (float)
  px, py - Point to test (float)

Returns T or NIL."
  (cffi-c-ref:c-with ((rect (:struct flow-ffi:rect))
                       (point (:struct flow-ffi:point)))
    (setf (rect :x) (float rx 1.0f0)
          (rect :y) (float ry 1.0f0)
          (rect :width) (float rw 1.0f0)
          (rect :height) (float rh 1.0f0))
    (setf (point :x) (float px 1.0f0)
          (point :y) (float py 1.0f0))
    (flow-ffi:rect-contains-point (rect &) (point &))))

(defun flow-rect-intersection (r1x r1y r1w r1h r2x r2y r2w r2h)
  "Compute the intersection of two rectangles.

Returns (values intersects-p x y width height).
If intersects-p is NIL, the rectangles do not overlap."
  (cffi-c-ref:c-with ((rect1 (:struct flow-ffi:rect))
                       (rect2 (:struct flow-ffi:rect))
                       (out (:struct flow-ffi:rect)))
    (setf (rect1 :x) (float r1x 1.0f0)
          (rect1 :y) (float r1y 1.0f0)
          (rect1 :width) (float r1w 1.0f0)
          (rect1 :height) (float r1h 1.0f0))
    (setf (rect2 :x) (float r2x 1.0f0)
          (rect2 :y) (float r2y 1.0f0)
          (rect2 :width) (float r2w 1.0f0)
          (rect2 :height) (float r2h 1.0f0))
    (let ((intersects (flow-ffi:rect-intersection (rect1 &) (rect2 &) (out &))))
      (if intersects
          (values t (out :x) (out :y) (out :width) (out :height))
          (values nil 0.0f0 0.0f0 0.0f0 0.0f0)))))

(defun flow-rect-union (r1x r1y r1w r1h r2x r2y r2w r2h)
  "Compute the union of two rectangles.

Returns (values x y width height)."
  (cffi-c-ref:c-with ((rect1 (:struct flow-ffi:rect))
                       (rect2 (:struct flow-ffi:rect))
                       (out (:struct flow-ffi:rect)))
    (setf (rect1 :x) (float r1x 1.0f0)
          (rect1 :y) (float r1y 1.0f0)
          (rect1 :width) (float r1w 1.0f0)
          (rect1 :height) (float r1h 1.0f0))
    (setf (rect2 :x) (float r2x 1.0f0)
          (rect2 :y) (float r2y 1.0f0)
          (rect2 :width) (float r2w 1.0f0)
          (rect2 :height) (float r2h 1.0f0))
    (flow-ffi:rect-union (rect1 &) (rect2 &) (out &))
    (values (out :x) (out :y) (out :width) (out :height))))

(defun flow-matrix-invert (matrix-ptr out-ptr)
  "Invert a 4x4 matrix.

Arguments:
  matrix-ptr - Pointer to input FlowMatrix
  out-ptr    - Pointer to output FlowMatrix for the inverse

Returns T if the matrix was invertible, NIL otherwise."
  (flow-ffi:matrix-invert matrix-ptr out-ptr))

(defun flow-matrix-multiply (a-ptr b-ptr out-ptr)
  "Multiply two 4x4 matrices (out = a * b).

Arguments:
  a-ptr   - Pointer to first FlowMatrix
  b-ptr   - Pointer to second FlowMatrix
  out-ptr - Pointer to output FlowMatrix"
  (flow-ffi:matrix-multiply a-ptr b-ptr out-ptr)
  nil)

(defun flow-point-transform (px py matrix-ptr)
  "Transform a point by a 4x4 matrix.

Arguments:
  px, py     - Point coordinates (float)
  matrix-ptr - Pointer to a FlowMatrix

Returns (values out-x out-y)."
  (cffi-c-ref:c-with ((point (:struct flow-ffi:point))
                       (out-point (:struct flow-ffi:point)))
    (setf (point :x) (float px 1.0f0)
          (point :y) (float py 1.0f0))
    (flow-ffi:point-transform (point &) matrix-ptr (out-point &))
    (values (out-point :x) (out-point :y))))
