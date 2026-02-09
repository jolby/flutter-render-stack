;;;; flutter-render-stack/impeller/path.lisp
;;;; Impeller path building and rounded rectangle support

(in-package :flutter-render-stack)

;;; Enum converters for path properties

(rs-internals:define-case-converter (:fill-type-keyword :fill-type-int)
  (:non-zero 0) (:odd 1))

;;; Path builder lifecycle

(defmacro with-path-builder ((builder-var) &body body)
  "Allocate and manage a path builder.

Syntax: (with-path-builder (builder) ...)

The builder variable is bound to a path builder pointer for use with
path-move-to, path-line-to, path-add-rect, etc. The builder is
automatically released upon exit (success or error).

Returns the result of body."
  `(let ((,builder-var (impeller-ffi:path-builder-new)))
     (when (cffi:null-pointer-p ,builder-var)
       (error 'impeller-creation-error :resource-type "path builder"))
     (unwind-protect
          (progn ,@body)
       (impeller-ffi:path-builder-release ,builder-var))))

;;; Path operations

(defun path-move-to (builder x y)
  "Move the path cursor to a new position without drawing.

Arguments:
  builder - Path builder from with-path-builder
  x       - X coordinate (float)
  y       - Y coordinate (float)

Returns nil."
  (cffi-c-ref:c-with ((point (:struct impeller-ffi:point)))
    (setf (point :x) (float x 1.0f0)
          (point :y) (float y 1.0f0))
    (impeller-ffi:path-builder-move-to builder (point &)))
  nil)

(defun path-line-to (builder x y)
  "Draw a line from current position to a new position.

Arguments:
  builder - Path builder from with-path-builder
  x       - X coordinate (float)
  y       - Y coordinate (float)

Returns nil."
  (cffi-c-ref:c-with ((point (:struct impeller-ffi:point)))
    (setf (point :x) (float x 1.0f0)
          (point :y) (float y 1.0f0))
    (impeller-ffi:path-builder-line-to builder (point &)))
  nil)

(defun path-add-rect (builder x y width height)
  "Add a rectangle to the path.

Arguments:
  builder - Path builder from with-path-builder
  x       - Left edge coordinate (float)
  y       - Top edge coordinate (float)
  width   - Rectangle width (float)
  height  - Rectangle height (float)

Returns nil."
  (cffi-c-ref:c-with ((rect (:struct impeller-ffi:rect)))
    (setf (rect :x) (float x 1.0f0)
          (rect :y) (float y 1.0f0)
          (rect :width) (float width 1.0f0)
          (rect :height) (float height 1.0f0))
    (impeller-ffi:path-builder-add-rect builder (rect &)))
  nil)

(defun path-add-oval (builder x y width height)
  "Add an oval (ellipse) to the path.

Arguments:
  builder - Path builder from with-path-builder
  x       - Left edge of bounding rectangle (float)
  y       - Top edge of bounding rectangle (float)
  width   - Bounding rectangle width (float)
  height  - Bounding rectangle height (float)

Returns nil."
  (cffi-c-ref:c-with ((rect (:struct impeller-ffi:rect)))
    (setf (rect :x) (float x 1.0f0)
          (rect :y) (float y 1.0f0)
          (rect :width) (float width 1.0f0)
          (rect :height) (float height 1.0f0))
    (impeller-ffi:path-builder-add-oval builder (rect &)))
  nil)

(defun path-close (builder)
  "Close the current path contour.

Arguments:
  builder - Path builder from with-path-builder

Returns nil."
  (impeller-ffi:path-builder-close builder)
  nil)

(defun build-path (builder &key (fill-type :non-zero))
  "Create a path object from the current path builder state.

Arguments:
  builder   - Path builder from with-path-builder
  fill-type - Fill rule (:non-zero or :odd), default :non-zero

Returns a path object. The path must be released via release-path."
  (let ((path (impeller-ffi:path-builder-copy-path-new
               builder (fill-type-keyword->fill-type-int fill-type))))
    (when (cffi:null-pointer-p path)
      (error 'impeller-creation-error :resource-type "path"))
    path))

(defun release-path (path)
  "Release an Impeller path object.

Arguments:
  path - Path object from build-path

Returns nil."
  (impeller-ffi:path-release path)
  nil)

;;; Rounded rectangle helper

(defun %make-rounding-radii (radii-ptr radius)
  "Initialize a rounding-radii struct with uniform or per-corner radii.

Arguments:
  radii-ptr - Pointer to rounding-radii struct
  radius    - Either a single number (uniform radius) or a plist with
              :top-left, :top-right, :bottom-left, :bottom-right keys,
              each being a number or (rx . ry) cons for elliptical corners.

Returns nil. Modifies radii-ptr in place."
  (flet ((set-corner (slot rx ry)
           (let ((corner-ptr (cffi:foreign-slot-pointer
                             radii-ptr
                             '(:struct impeller-ffi:rounding-radii)
                             slot)))
             (setf (cffi:foreign-slot-value corner-ptr
                                            '(:struct impeller-ffi:point)
                                            '%impeller::x)
                   (float rx 1.0f0))
             (setf (cffi:foreign-slot-value corner-ptr
                                            '(:struct impeller-ffi:point)
                                            '%impeller::y)
                   (float ry 1.0f0)))))
    (cond
      ;; Single number = uniform radius
      ((numberp radius)
       (let ((r (float radius 1.0f0)))
         (set-corner '%impeller::top-left r r)
         (set-corner '%impeller::top-right r r)
         (set-corner '%impeller::bottom-left r r)
         (set-corner '%impeller::bottom-right r r)))
      ;; Plist with per-corner values
      ((listp radius)
       (flet ((corner-value (key default)
                (let ((val (getf radius key default)))
                  (if (consp val)
                      (values (float (car val) 1.0f0) (float (cdr val) 1.0f0))
                      (values (float val 1.0f0) (float val 1.0f0))))))
         (multiple-value-bind (rx ry) (corner-value :top-left 0)
           (set-corner '%impeller::top-left rx ry))
         (multiple-value-bind (rx ry) (corner-value :top-right 0)
           (set-corner '%impeller::top-right rx ry))
         (multiple-value-bind (rx ry) (corner-value :bottom-left 0)
           (set-corner '%impeller::bottom-left rx ry))
         (multiple-value-bind (rx ry) (corner-value :bottom-right 0)
           (set-corner '%impeller::bottom-right rx ry))))
      (t
       (error "Invalid radius format: ~S (expected number or plist)" radius))))
  nil)

(defun path-add-rounded-rect (builder x y width height &key (radius 0.0))
  "Add a rounded rectangle to a path builder.

Arguments:
  builder - Path builder from with-path-builder
  x       - Left edge coordinate (float)
  y       - Top edge coordinate (float)
  width   - Rectangle width (float)
  height  - Rectangle height (float)
  radius  - Corner radius (see draw-rounded-rect for format options)

Returns nil."
  (cffi:with-foreign-objects ((rect '(:struct impeller-ffi:rect))
                              (radii '(:struct impeller-ffi:rounding-radii)))
    (setf (cffi:foreign-slot-value rect '(:struct impeller-ffi:rect) '%impeller::x)
          (float x 1.0f0))
    (setf (cffi:foreign-slot-value rect '(:struct impeller-ffi:rect) '%impeller::y)
          (float y 1.0f0))
    (setf (cffi:foreign-slot-value rect '(:struct impeller-ffi:rect) '%impeller::width)
          (float width 1.0f0))
    (setf (cffi:foreign-slot-value rect '(:struct impeller-ffi:rect) '%impeller::height)
          (float height 1.0f0))
    (%make-rounding-radii radii radius)
    (impeller-ffi:path-builder-add-rounded-rect builder rect radii))
  nil)
