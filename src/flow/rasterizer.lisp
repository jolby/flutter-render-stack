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
