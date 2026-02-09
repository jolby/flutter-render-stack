;;;; flutter-render-stack/flow/layer-tree.lisp
;;;; Flow layer tree construction and layer types

(in-package :flutter-render-stack)

;;; Enum converters

(rs-internals:define-case-converter (:clip-behavior-keyword :clip-behavior-int)
  (:anti-alias 0) (:hard-edge 1) (:none 2))

(rs-internals:define-case-converter (:raster-status-keyword :raster-status-int)
  (:success 0) (:not-found 1) (:failed 2))

;;; ============================================================
;;; Layer tree lifecycle
;;; ============================================================

(defun make-layer-tree (width height)
  "Create a new Flow layer tree with the given frame size.

Arguments:
  width  - Frame width in pixels (integer)
  height - Frame height in pixels (integer)

Returns a layer tree pointer. Must be released via release-layer-tree."
  (cffi-c-ref:c-with ((size (:struct flow-ffi:i-size)))
    (setf (size :width) width
          (size :height) height)
    (let ((tree (flow-ffi:layer-tree-new flow-ffi:+version+ (size &))))
      (when (cffi:null-pointer-p tree)
        (error 'flow-creation-error :resource-type "layer tree"))
      tree)))

(defun release-layer-tree (tree)
  "Release a Flow layer tree."
  (flow-ffi:layer-tree-release tree)
  nil)

(defun retain-layer-tree (tree)
  "Increment the reference count of a layer tree."
  (flow-ffi:layer-tree-retain tree)
  nil)

(defun layer-tree-set-root-layer (tree root-layer)
  "Set the root container layer of a layer tree.

Arguments:
  tree       - Layer tree from make-layer-tree
  root-layer - Container layer (e.g., from transform-layer-as-container)"
  (flow-ffi:layer-tree-set-root-layer tree root-layer)
  nil)

(defun layer-tree-get-frame-size (tree)
  "Get the frame size of a layer tree.

Returns (values width height) as integers."
  (cffi-c-ref:c-with ((size (:struct flow-ffi:i-size)))
    (flow-ffi:layer-tree-get-frame-size tree (size &))
    (values (size :width) (size :height))))

;;; ============================================================
;;; Transform layer
;;; ============================================================

(defun make-transform-layer (matrix-ptr)
  "Create a transform layer with a 4x4 matrix.

Arguments:
  matrix-ptr - Pointer to a FlowMatrix (4x4, column-major)

Returns a transform layer pointer. Must be released via release-transform-layer."
  (let ((layer (flow-ffi:transform-layer-new matrix-ptr)))
    (when (cffi:null-pointer-p layer)
      (error 'flow-creation-error :resource-type "transform layer"))
    layer))

(defun make-identity-transform-layer ()
  "Create a transform layer with an identity matrix."
  (cffi:with-foreign-object (matrix '(:struct flow-ffi:matrix))
    (let ((m-ptr (cffi:foreign-slot-pointer matrix '(:struct flow-ffi:matrix) '%flow::m)))
      (dotimes (i 16)
        (setf (cffi:mem-aref m-ptr :float i) 0.0f0))
      (setf (cffi:mem-aref m-ptr :float 0) 1.0f0
            (cffi:mem-aref m-ptr :float 5) 1.0f0
            (cffi:mem-aref m-ptr :float 10) 1.0f0
            (cffi:mem-aref m-ptr :float 15) 1.0f0))
    (make-transform-layer matrix)))

(defun make-translation-transform-layer (x y)
  "Create a transform layer with a translation matrix.

Arguments:
  x - X translation (float)
  y - Y translation (float)"
  (cffi:with-foreign-object (matrix '(:struct flow-ffi:matrix))
    (let ((m-ptr (cffi:foreign-slot-pointer matrix '(:struct flow-ffi:matrix) '%flow::m)))
      (dotimes (i 16)
        (setf (cffi:mem-aref m-ptr :float i) 0.0f0))
      (setf (cffi:mem-aref m-ptr :float 0) 1.0f0
            (cffi:mem-aref m-ptr :float 5) 1.0f0
            (cffi:mem-aref m-ptr :float 10) 1.0f0
            (cffi:mem-aref m-ptr :float 15) 1.0f0
            (cffi:mem-aref m-ptr :float 12) (float x 1.0f0)
            (cffi:mem-aref m-ptr :float 13) (float y 1.0f0)))
    (make-transform-layer matrix)))

(defun release-transform-layer (layer)
  "Release a transform layer."
  (flow-ffi:transform-layer-release layer)
  nil)

(defun retain-transform-layer (layer)
  "Increment the reference count of a transform layer."
  (flow-ffi:transform-layer-retain layer)
  nil)

(defun transform-layer-add-child (parent child)
  "Add a child container layer to a transform layer.

Arguments:
  parent - Transform layer
  child  - Container layer"
  (flow-ffi:transform-layer-add-child parent child)
  nil)

(defun transform-layer-as-container (layer)
  "Get the container-layer interface for a transform layer."
  (flow-ffi:transform-layer-as-container layer))

;;; ============================================================
;;; Opacity layer
;;; ============================================================

(defun make-opacity-layer (alpha &key (offset-x 0.0) (offset-y 0.0))
  "Create an opacity layer.

Arguments:
  alpha    - Opacity value (integer 0-255)
  offset-x - X offset (float, default 0.0)
  offset-y - Y offset (float, default 0.0)

Returns an opacity layer pointer. Must be released via release-opacity-layer."
  (cffi-c-ref:c-with ((offset (:struct flow-ffi:point)))
    (setf (offset :x) (float offset-x 1.0f0)
          (offset :y) (float offset-y 1.0f0))
    (let ((layer (flow-ffi:opacity-layer-new alpha (offset &))))
      (when (cffi:null-pointer-p layer)
        (error 'flow-creation-error :resource-type "opacity layer"))
      layer)))

(defun release-opacity-layer (layer)
  "Release an opacity layer."
  (flow-ffi:opacity-layer-release layer)
  nil)

(defun retain-opacity-layer (layer)
  "Increment the reference count of an opacity layer."
  (flow-ffi:opacity-layer-retain layer)
  nil)

(defun opacity-layer-add-child (parent child)
  "Add a child container layer to an opacity layer."
  (flow-ffi:opacity-layer-add-child parent child)
  nil)

(defun opacity-layer-as-container (layer)
  "Get the container-layer interface for an opacity layer."
  (flow-ffi:opacity-layer-as-container layer))

;;; ============================================================
;;; Clip rect layer
;;; ============================================================

(defun make-clip-rect-layer (x y width height &key (clip-behavior :anti-alias))
  "Create a rectangular clip layer.

Arguments:
  x, y          - Top-left corner of clip rectangle (float)
  width, height - Dimensions of clip rectangle (float)
  clip-behavior - :anti-alias (default), :hard-edge, or :none"
  (cffi-c-ref:c-with ((rect (:struct flow-ffi:rect)))
    (setf (rect :x) (float x 1.0f0)
          (rect :y) (float y 1.0f0)
          (rect :width) (float width 1.0f0)
          (rect :height) (float height 1.0f0))
    (let ((layer (flow-ffi:clip-rect-layer-new
                  (rect &)
                  (clip-behavior-keyword->clip-behavior-int clip-behavior))))
      (when (cffi:null-pointer-p layer)
        (error 'flow-creation-error :resource-type "clip rect layer"))
      layer)))

(defun release-clip-rect-layer (layer)
  "Release a clip rect layer."
  (flow-ffi:clip-rect-layer-release layer)
  nil)

(defun retain-clip-rect-layer (layer)
  "Increment the reference count of a clip rect layer."
  (flow-ffi:clip-rect-layer-retain layer)
  nil)

(defun clip-rect-layer-add-child (parent child)
  "Add a child container layer to a clip rect layer."
  (flow-ffi:clip-rect-layer-add-child parent child)
  nil)

(defun clip-rect-layer-as-container (layer)
  "Get the container-layer interface for a clip rect layer."
  (flow-ffi:clip-rect-layer-as-container layer))

;;; ============================================================
;;; Clip rounded-rect layer
;;; ============================================================

(defun make-clip-rrect-layer (x y width height corner-radius
                              &key (clip-behavior :anti-alias))
  "Create a rounded-rectangle clip layer.

Arguments:
  x, y           - Top-left corner of bounds (float)
  width, height  - Dimensions of bounds (float)
  corner-radius  - Corner radius (float)
  clip-behavior  - :anti-alias (default), :hard-edge, or :none"
  (cffi-c-ref:c-with ((bounds (:struct flow-ffi:rect)))
    (setf (bounds :x) (float x 1.0f0)
          (bounds :y) (float y 1.0f0)
          (bounds :width) (float width 1.0f0)
          (bounds :height) (float height 1.0f0))
    (let ((layer (flow-ffi:clip-r-rect-layer-new
                  (bounds &)
                  (float corner-radius 1.0f0)
                  (clip-behavior-keyword->clip-behavior-int clip-behavior))))
      (when (cffi:null-pointer-p layer)
        (error 'flow-creation-error :resource-type "clip rrect layer"))
      layer)))

(defun release-clip-rrect-layer (layer)
  "Release a clip rounded-rect layer."
  (flow-ffi:clip-r-rect-layer-release layer)
  nil)

(defun retain-clip-rrect-layer (layer)
  "Increment the reference count of a clip rounded-rect layer."
  (flow-ffi:clip-r-rect-layer-retain layer)
  nil)

(defun clip-rrect-layer-add-child (parent child)
  "Add a child container layer to a clip rounded-rect layer."
  (flow-ffi:clip-r-rect-layer-add-child parent child)
  nil)

(defun clip-rrect-layer-as-container (layer)
  "Get the container-layer interface for a clip rounded-rect layer."
  (flow-ffi:clip-r-rect-layer-as-container layer))

;;; ============================================================
;;; Clip path layer
;;; ============================================================

(defun make-clip-path-layer (&key (clip-behavior :anti-alias))
  "Create a clip path layer.

Arguments:
  clip-behavior - :anti-alias (default), :hard-edge, or :none"
  (let ((layer (flow-ffi:clip-path-layer-new
                (clip-behavior-keyword->clip-behavior-int clip-behavior))))
    (when (cffi:null-pointer-p layer)
      (error 'flow-creation-error :resource-type "clip path layer"))
    layer))

(defun release-clip-path-layer (layer)
  "Release a clip path layer."
  (flow-ffi:clip-path-layer-release layer)
  nil)

(defun retain-clip-path-layer (layer)
  "Increment the reference count of a clip path layer."
  (flow-ffi:clip-path-layer-retain layer)
  nil)

(defun clip-path-layer-add-child (parent child)
  "Add a child container layer to a clip path layer."
  (flow-ffi:clip-path-layer-add-child parent child)
  nil)

(defun clip-path-layer-as-container (layer)
  "Get the container-layer interface for a clip path layer."
  (flow-ffi:clip-path-layer-as-container layer))

;;; ============================================================
;;; Color filter layer
;;; ============================================================

(defun make-color-filter-layer (color-filter)
  "Create a color filter layer.

Arguments:
  color-filter - Pointer to a color filter object (void*)"
  (let ((layer (flow-ffi:color-filter-layer-new color-filter)))
    (when (cffi:null-pointer-p layer)
      (error 'flow-creation-error :resource-type "color filter layer"))
    layer))

(defun release-color-filter-layer (layer)
  "Release a color filter layer."
  (flow-ffi:color-filter-layer-release layer)
  nil)

(defun retain-color-filter-layer (layer)
  "Increment the reference count of a color filter layer."
  (flow-ffi:color-filter-layer-retain layer)
  nil)

(defun color-filter-layer-add-child (parent child)
  "Add a child container layer to a color filter layer."
  (flow-ffi:color-filter-layer-add-child parent child)
  nil)

(defun color-filter-layer-as-container (layer)
  "Get the container-layer interface for a color filter layer."
  (flow-ffi:color-filter-layer-as-container layer))

;;; ============================================================
;;; Image filter layer
;;; ============================================================

(defun make-image-filter-layer (image-filter)
  "Create an image filter layer.

Arguments:
  image-filter - Pointer to an image filter object (void*)"
  (let ((layer (flow-ffi:image-filter-layer-new image-filter)))
    (when (cffi:null-pointer-p layer)
      (error 'flow-creation-error :resource-type "image filter layer"))
    layer))

(defun release-image-filter-layer (layer)
  "Release an image filter layer."
  (flow-ffi:image-filter-layer-release layer)
  nil)

(defun retain-image-filter-layer (layer)
  "Increment the reference count of an image filter layer."
  (flow-ffi:image-filter-layer-retain layer)
  nil)

(defun image-filter-layer-add-child (parent child)
  "Add a child container layer to an image filter layer."
  (flow-ffi:image-filter-layer-add-child parent child)
  nil)

(defun image-filter-layer-as-container (layer)
  "Get the container-layer interface for an image filter layer."
  (flow-ffi:image-filter-layer-as-container layer))

;;; ============================================================
;;; Display list layer (leaf node)
;;; ============================================================

(defun make-display-list-layer (display-list &key (offset-x 0.0) (offset-y 0.0))
  "Create a display list layer (leaf node in the layer tree).

Arguments:
  display-list - Impeller display list pointer
  offset-x     - X offset for the display list (float, default 0.0)
  offset-y     - Y offset for the display list (float, default 0.0)

Returns a display list layer. Must be released via release-display-list-layer."
  (cffi-c-ref:c-with ((offset (:struct flow-ffi:point)))
    (setf (offset :x) (float offset-x 1.0f0)
          (offset :y) (float offset-y 1.0f0))
    (let ((layer (flow-ffi:display-list-layer-new (offset &) display-list)))
      (when (cffi:null-pointer-p layer)
        (error 'flow-creation-error :resource-type "display list layer"))
      layer)))

(defun release-display-list-layer (layer)
  "Release a display list layer."
  (flow-ffi:display-list-layer-release layer)
  nil)

(defun retain-display-list-layer (layer)
  "Increment the reference count of a display list layer."
  (flow-ffi:display-list-layer-retain layer)
  nil)

(defun display-list-layer-as-container (layer)
  "Get the container-layer interface for a display list layer."
  (flow-ffi:display-list-layer-as-container layer))

;;; ============================================================
;;; Container layer (base type)
;;; ============================================================

(defun release-container-layer (layer)
  "Release a container layer."
  (flow-ffi:container-layer-release layer)
  nil)

(defun retain-container-layer (layer)
  "Increment the reference count of a container layer."
  (flow-ffi:container-layer-retain layer)
  nil)

;;; ============================================================
;;; Convenience macro for layer tree construction
;;; ============================================================

(defmacro with-layer-tree ((tree-var width height) &body body)
  "Create a layer tree, execute body, and release on exit.

Syntax: (with-layer-tree (tree width height) ...)

The tree is automatically released upon exit."
  `(let ((,tree-var (make-layer-tree ,width ,height)))
     (unwind-protect
          (progn ,@body)
       (release-layer-tree ,tree-var))))
