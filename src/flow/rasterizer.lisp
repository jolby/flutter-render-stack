;;;; flutter-render-stack/flow/rasterizer.lisp
;;;; Flow compositor context and raster cache management

(in-package :flutter-render-stack)

;;; ============================================================
;;; Compositor context lifecycle
;;; ============================================================

(defun make-compositor-context ()
  "Create a Flow compositor context.

Returns a compositor context pointer. Must be released via release-compositor-context."
  (let ((ctx (flow-ffi:compositor-context-new flow-ffi:+version+)))
    (when (cffi:null-pointer-p ctx)
      (error 'flow-creation-error :resource-type "compositor context"))
    ctx))

(defun release-compositor-context (context)
  "Release a Flow compositor context."
  (flow-ffi:compositor-context-release context)
  nil)

(defun retain-compositor-context (context)
  "Increment the reference count of a compositor context."
  (flow-ffi:compositor-context-retain context)
  nil)

(defmacro with-compositor-context ((ctx-var) &body body)
  "Create a compositor context, execute body, and release on exit.

Syntax: (with-compositor-context (ctx) ...)"
  `(let ((,ctx-var (make-compositor-context)))
     (unwind-protect
          (progn ,@body)
       (release-compositor-context ,ctx-var))))

;;; ============================================================
;;; Raster cache
;;; ============================================================

(defun compositor-context-get-raster-cache (context)
  "Get the raster cache from a compositor context.

The returned cache is owned by the context; do NOT release it separately."
  (flow-ffi:compositor-context-get-raster-cache context))

(defun raster-cache-clear (cache)
  "Clear all entries in a raster cache."
  (flow-ffi:raster-cache-clear cache)
  nil)

(defun raster-cache-get-access-threshold (cache)
  "Get the access threshold for raster cache entries.

Returns the number of accesses before an entry is cached (integer)."
  (flow-ffi:raster-cache-get-access-threshold cache))

(defun raster-cache-get-cached-entries-count (cache)
  "Get the total number of cached entries."
  (flow-ffi:raster-cache-get-cached-entries-count cache))

(defun raster-cache-get-layer-cached-entries-count (cache)
  "Get the number of cached layer entries."
  (flow-ffi:raster-cache-get-layer-cached-entries-count cache))

(defun raster-cache-get-picture-cached-entries-count (cache)
  "Get the number of cached picture entries."
  (flow-ffi:raster-cache-get-picture-cached-entries-count cache))

(defun raster-cache-estimate-layer-byte-size (cache)
  "Estimate the total byte size of cached layer entries."
  (flow-ffi:raster-cache-estimate-layer-byte-size cache))

(defun raster-cache-estimate-picture-byte-size (cache)
  "Estimate the total byte size of cached picture entries."
  (flow-ffi:raster-cache-estimate-picture-byte-size cache))

(defun raster-cache-get-layer-metrics (cache)
  "Get layer cache metrics.

Returns a plist with :eviction-count, :eviction-bytes,
:in-use-count, :in-use-bytes."
  (cffi-c-ref:c-with ((metrics (:struct flow-ffi:raster-cache-metrics)))
    (flow-ffi:raster-cache-get-layer-metrics cache (metrics &))
    (list :eviction-count (metrics :eviction-count)
          :eviction-bytes (metrics :eviction-bytes)
          :in-use-count (metrics :in-use-count)
          :in-use-bytes (metrics :in-use-bytes))))

(defun raster-cache-get-picture-metrics (cache)
  "Get picture cache metrics.

Returns a plist with :eviction-count, :eviction-bytes,
:in-use-count, :in-use-bytes."
  (cffi-c-ref:c-with ((metrics (:struct flow-ffi:raster-cache-metrics)))
    (flow-ffi:raster-cache-get-picture-metrics cache (metrics &))
    (list :eviction-count (metrics :eviction-count)
          :eviction-bytes (metrics :eviction-bytes)
          :in-use-count (metrics :in-use-count)
          :in-use-bytes (metrics :in-use-bytes))))

(defun raster-cache-release (cache)
  "Release a raster cache."
  (flow-ffi:raster-cache-release cache)
  nil)

(defun raster-cache-retain (cache)
  "Increment the reference count of a raster cache."
  (flow-ffi:raster-cache-retain cache)
  nil)

;;; ============================================================
;;; Scoped frame lifecycle (for rasterization)
;;; ============================================================

(defun compositor-context-acquire-frame (context impeller-context frame-size)
  "Acquire a scoped frame for rasterization.

CONTEXT is a Flow compositor context.
IMPELLER-CONTEXT is an Impeller context (can be NULL for CPU-only rendering).
FRAME-SIZE is a cons (width . height) specifying frame dimensions.

Returns a scoped frame pointer. Must be released via release-scoped-frame.
Signals impeller-creation-error if frame cannot be acquired."
  (when (cffi:null-pointer-p context)
    (error 'flow-creation-error :resource-type "compositor context is NULL"))
  
  (destructuring-bind (width . height) frame-size
    (cffi-c-ref:c-with ((isize (:struct flow-ffi:i-size)))
      (setf (isize :width) (round width)
            (isize :height) (round height))
      (let ((frame (flow-ffi:compositor-context-acquire-frame context impeller-context (isize &))))
        (when (cffi:null-pointer-p frame)
          (error 'impeller-creation-error :resource-type "scoped frame"))
        frame))))

(defun release-scoped-frame (frame)
  "Release a scoped frame.

Must be called to free the frame resources."
  (flow-ffi:scoped-frame-release frame)
  nil)

(defun retain-scoped-frame (frame)
  "Increment the reference count of a scoped frame."
  (flow-ffi:scoped-frame-retain frame)
  nil)

(defmacro with-scoped-frame ((frame-var context impeller-context frame-size) &body body)
  "Acquire a scoped frame, execute body, and release on exit.

Syntax: (with-scoped-frame (frame ctx impeller-ctx '(800 . 600)) ...)"
  `(let ((,frame-var (compositor-context-acquire-frame ,context ,impeller-context ,frame-size)))
     (unwind-protect
          (progn ,@body)
       (release-scoped-frame ,frame-var))))

;;; ============================================================
;;; Display list building from layer tree
;;; ============================================================

(defun scoped-frame-build-display-list (frame)
  "Build a display list from the layer tree in a scoped frame.

FRAME is a scoped frame acquired via compositor-context-acquire-frame.
CRITICAL: Must be called AFTER scoped-frame-raster on the same frame.

Returns an Impeller display list pointer. The display list can be rendered
to a surface using execute-display-list.

NOTE: Can only be called once per frame. Subsequent calls return NULL."
  (let ((dl (flow-ffi:scoped-frame-build-display-list-new frame)))
    (when (cffi:null-pointer-p dl)
      (error 'impeller-creation-error :resource-type "display list from layer tree"))
    dl))

(defmacro with-rasterized-display-list ((dl-var frame layer-tree &key frame-damage ignore-raster-cache) &body body)
  "Rasterize a layer tree to a scoped frame, build display list, execute body, and release.

Enforces the correct API sequence:
  1. Rasterize layer tree to frame
  2. Build display list from frame
  3. Execute body with display list
  4. Auto-release display list on exit

The display list must not be used after the macro exits.

Rasterization can fail if:
  - Frame is invalid or NULL
  - Layer tree is invalid or NULL
  - Impeller context was NULL/incompatible
  - Frame damage calculation failed
  - Internal canvas setup failed

Syntax: (with-rasterized-display-list (dl frame tree) (execute-display-list surface dl))"
  `(let ((raster-status (scoped-frame-raster ,frame ,layer-tree 
                                             :frame-damage ,frame-damage
                                             :ignore-raster-cache ,ignore-raster-cache)))
     (unless (eq raster-status :success)
       (error 'flow-error :message (format nil "Failed to rasterize layer tree to frame (status: ~A). Possible causes: frame invalid, layer-tree invalid, impeller-context incompatible, or internal paint failure." raster-status)))
     (let ((,dl-var (scoped-frame-build-display-list ,frame)))
       (unwind-protect
            (progn ,@body)
         (release-display-list ,dl-var)))))

;;; ============================================================
;;; Rasterization
;;; ============================================================

(defun scoped-frame-raster (frame layer-tree &key (frame-damage (cffi:null-pointer)) (ignore-raster-cache nil))
  "Rasterize a layer tree directly to the scoped frame.

FRAME is a scoped frame.
LAYER-TREE is a Flow layer tree.
FRAME-DAMAGE is optional damage information (defaults to NULL).
IGNORE-RASTER-CACHE is a boolean (default nil).

Returns one of: :success, :not-found, :failed"
  ;; flow-ffi:scoped-frame-raster returns a CFFI enum keyword
  ;; (:success, :not-found, :failed), not an integer.
  (let ((status (flow-ffi:scoped-frame-raster frame layer-tree frame-damage ignore-raster-cache)))
    (case status
      (:success :success)
      (:not-found :not-found)
      (:failed :failed)
      (otherwise (error 'flow-error :message (format nil "Unknown raster status: ~A" status))))))

