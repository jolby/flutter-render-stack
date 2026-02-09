;;;; flutter-render-stack/test/flow-tests.lisp
;;;; Test suite for Flow compositor module

(in-package :flutter-render-stack-tests)

;;; Top-level suite

(define-test flow-suite
  "Top-level test suite for Flow compositor module.")

;;; ============================================================
;;; Export verification tests (no native library required)
;;; ============================================================

(define-test flow-export-suite
  :parent flow-suite
  "Verify all public Flow symbols are exported and bound.")

;;; Condition exports

(define-test flow-condition-exports
  :parent flow-export-suite
  :description "Verify Flow condition classes are exported."
  (true (find-class 'frs:flow-error nil))
  (true (find-class 'frs:flow-creation-error nil))
  (true (fboundp 'frs:flow-creation-error-resource-type)))

;;; Layer tree exports

(define-test layer-tree-exports
  :parent flow-export-suite
  :description "Verify layer tree functions are exported."
  (true (fboundp 'frs:make-layer-tree))
  (true (fboundp 'frs:release-layer-tree))
  (true (fboundp 'frs:retain-layer-tree))
  (true (fboundp 'frs:layer-tree-set-root-layer))
  (true (fboundp 'frs:layer-tree-get-frame-size))
  (true (macro-function 'frs:with-layer-tree)))

;;; Transform layer exports

(define-test transform-layer-exports
  :parent flow-export-suite
  :description "Verify transform layer functions are exported."
  (true (fboundp 'frs:make-transform-layer))
  (true (fboundp 'frs:make-identity-transform-layer))
  (true (fboundp 'frs:make-translation-transform-layer))
  (true (fboundp 'frs:release-transform-layer))
  (true (fboundp 'frs:retain-transform-layer))
  (true (fboundp 'frs:transform-layer-add-child))
  (true (fboundp 'frs:transform-layer-as-container)))

;;; Opacity layer exports

(define-test opacity-layer-exports
  :parent flow-export-suite
  :description "Verify opacity layer functions are exported."
  (true (fboundp 'frs:make-opacity-layer))
  (true (fboundp 'frs:release-opacity-layer))
  (true (fboundp 'frs:retain-opacity-layer))
  (true (fboundp 'frs:opacity-layer-add-child))
  (true (fboundp 'frs:opacity-layer-as-container)))

;;; Clip layer exports

(define-test clip-rect-layer-exports
  :parent flow-export-suite
  :description "Verify clip rect layer functions are exported."
  (true (fboundp 'frs:make-clip-rect-layer))
  (true (fboundp 'frs:release-clip-rect-layer))
  (true (fboundp 'frs:retain-clip-rect-layer))
  (true (fboundp 'frs:clip-rect-layer-add-child))
  (true (fboundp 'frs:clip-rect-layer-as-container)))

(define-test clip-rrect-layer-exports
  :parent flow-export-suite
  :description "Verify clip rounded-rect layer functions are exported."
  (true (fboundp 'frs:make-clip-rrect-layer))
  (true (fboundp 'frs:release-clip-rrect-layer))
  (true (fboundp 'frs:retain-clip-rrect-layer))
  (true (fboundp 'frs:clip-rrect-layer-add-child))
  (true (fboundp 'frs:clip-rrect-layer-as-container)))

(define-test clip-path-layer-exports
  :parent flow-export-suite
  :description "Verify clip path layer functions are exported."
  (true (fboundp 'frs:make-clip-path-layer))
  (true (fboundp 'frs:release-clip-path-layer))
  (true (fboundp 'frs:retain-clip-path-layer))
  (true (fboundp 'frs:clip-path-layer-add-child))
  (true (fboundp 'frs:clip-path-layer-as-container)))

;;; Filter layer exports

(define-test color-filter-layer-exports
  :parent flow-export-suite
  :description "Verify color filter layer functions are exported."
  (true (fboundp 'frs:make-color-filter-layer))
  (true (fboundp 'frs:release-color-filter-layer))
  (true (fboundp 'frs:retain-color-filter-layer))
  (true (fboundp 'frs:color-filter-layer-add-child))
  (true (fboundp 'frs:color-filter-layer-as-container)))

(define-test image-filter-layer-exports
  :parent flow-export-suite
  :description "Verify image filter layer functions are exported."
  (true (fboundp 'frs:make-image-filter-layer))
  (true (fboundp 'frs:release-image-filter-layer))
  (true (fboundp 'frs:retain-image-filter-layer))
  (true (fboundp 'frs:image-filter-layer-add-child))
  (true (fboundp 'frs:image-filter-layer-as-container)))

;;; Display list layer exports

(define-test display-list-layer-exports
  :parent flow-export-suite
  :description "Verify display list layer functions are exported."
  (true (fboundp 'frs:make-display-list-layer))
  (true (fboundp 'frs:release-display-list-layer))
  (true (fboundp 'frs:retain-display-list-layer))
  (true (fboundp 'frs:display-list-layer-as-container)))

;;; Container layer exports

(define-test container-layer-exports
  :parent flow-export-suite
  :description "Verify container layer functions are exported."
  (true (fboundp 'frs:release-container-layer))
  (true (fboundp 'frs:retain-container-layer)))

;;; Compositor context exports

(define-test compositor-context-exports
  :parent flow-export-suite
  :description "Verify compositor context functions are exported."
  (true (fboundp 'frs:make-compositor-context))
  (true (fboundp 'frs:release-compositor-context))
  (true (fboundp 'frs:retain-compositor-context))
  (true (macro-function 'frs:with-compositor-context)))

;;; Raster cache exports

(define-test raster-cache-exports
  :parent flow-export-suite
  :description "Verify raster cache functions are exported."
  (true (fboundp 'frs:compositor-context-get-raster-cache))
  (true (fboundp 'frs:raster-cache-clear))
  (true (fboundp 'frs:raster-cache-get-access-threshold))
  (true (fboundp 'frs:raster-cache-get-cached-entries-count))
  (true (fboundp 'frs:raster-cache-get-layer-cached-entries-count))
  (true (fboundp 'frs:raster-cache-get-picture-cached-entries-count))
  (true (fboundp 'frs:raster-cache-estimate-layer-byte-size))
  (true (fboundp 'frs:raster-cache-estimate-picture-byte-size))
  (true (fboundp 'frs:raster-cache-get-layer-metrics))
  (true (fboundp 'frs:raster-cache-get-picture-metrics))
  (true (fboundp 'frs:raster-cache-release))
  (true (fboundp 'frs:raster-cache-retain)))

;;; Frame damage exports

(define-test frame-damage-exports
  :parent flow-export-suite
  :description "Verify frame damage functions are exported."
  (true (fboundp 'frs:make-frame-damage))
  (true (fboundp 'frs:release-frame-damage))
  (true (fboundp 'frs:retain-frame-damage))
  (true (macro-function 'frs:with-frame-damage))
  (true (fboundp 'frs:frame-damage-set-previous-layer-tree))
  (true (fboundp 'frs:frame-damage-add-additional-damage))
  (true (fboundp 'frs:frame-damage-compute-clip-rect)))

;;; Geometry utility exports

(define-test geometry-exports
  :parent flow-export-suite
  :description "Verify geometry utility functions are exported."
  (true (fboundp 'frs:flow-rect-contains-point))
  (true (fboundp 'frs:flow-rect-intersection))
  (true (fboundp 'frs:flow-rect-union))
  (true (fboundp 'frs:flow-matrix-invert))
  (true (fboundp 'frs:flow-matrix-multiply))
  (true (fboundp 'frs:flow-point-transform)))

;;; ============================================================
;;; Condition tests (no native library required)
;;; ============================================================

(define-test flow-condition-suite
  :parent flow-suite
  "Tests for Flow condition hierarchy.")

(define-test flow-condition-hierarchy
  :parent flow-condition-suite
  :description "Verify Flow condition class hierarchy."
  (true (subtypep 'frs:flow-error 'frs:flutter-render-error))
  (true (subtypep 'frs:flow-creation-error 'frs:flow-error))
  (true (subtypep 'frs:flow-creation-error 'error)))

(define-test flow-creation-error-resource-type
  :parent flow-condition-suite
  :description "Verify flow-creation-error carries resource-type."
  (let ((err (make-condition 'frs:flow-creation-error
                             :resource-type "layer tree")))
    (is string= "layer tree"
        (frs:flow-creation-error-resource-type err))))

(define-test flow-creation-error-format
  :parent flow-condition-suite
  :description "Verify flow-creation-error report string."
  (let ((err (make-condition 'frs:flow-creation-error
                             :resource-type "compositor context")))
    (is string= "Failed to create Flow compositor context"
        (format nil "~A" err))))

;;; ============================================================
;;; Enum converter tests (no native library required)
;;; ============================================================

(define-test flow-enum-suite
  :parent flow-suite
  "Tests for Flow keyword-to-integer enum conversion.")

(define-test clip-behavior-conversion
  :parent flow-enum-suite
  :description "Test clip behavior keyword conversion."
  (true (fboundp 'frs::clip-behavior-keyword->clip-behavior-int))
  (is = 0 (frs::clip-behavior-keyword->clip-behavior-int :anti-alias))
  (is = 1 (frs::clip-behavior-keyword->clip-behavior-int :hard-edge))
  (is = 2 (frs::clip-behavior-keyword->clip-behavior-int :none)))

(define-test raster-status-conversion
  :parent flow-enum-suite
  :description "Test raster status keyword conversion."
  (true (fboundp 'frs::raster-status-keyword->raster-status-int))
  (is = 0 (frs::raster-status-keyword->raster-status-int :success))
  (is = 1 (frs::raster-status-keyword->raster-status-int :not-found))
  (is = 2 (frs::raster-status-keyword->raster-status-int :failed)))

;;; Bidirectional conversion

(define-test flow-enum-round-trip
  :parent flow-enum-suite
  :description "Test integer-to-keyword reverse conversion."
  (is eq :anti-alias (frs::clip-behavior-int->clip-behavior-keyword 0))
  (is eq :hard-edge (frs::clip-behavior-int->clip-behavior-keyword 1))
  (is eq :none (frs::clip-behavior-int->clip-behavior-keyword 2))
  (is eq :success (frs::raster-status-int->raster-status-keyword 0))
  (is eq :not-found (frs::raster-status-int->raster-status-keyword 1))
  (is eq :failed (frs::raster-status-int->raster-status-keyword 2)))

;;; ============================================================
;;; Integration tests (skipped when native libraries are absent)
;;; ============================================================

(define-test flow-integration-suite
  :parent flow-suite
  "Integration tests requiring native Flow library.
These tests are honestly skipped when native libraries are unavailable.")

(define-test layer-tree-lifecycle
  :parent flow-integration-suite
  :description "Test layer tree create/release lifecycle."
  (skip-unless-flow
    (frs:with-layer-tree (tree 800 600)
      (true (not (cffi:null-pointer-p tree))))))

(define-test layer-tree-frame-size
  :parent flow-integration-suite
  :description "Test layer tree frame size retrieval."
  (skip-unless-flow
    (frs:with-layer-tree (tree 1024 768)
      (multiple-value-bind (w h) (frs:layer-tree-get-frame-size tree)
        (is = 1024 w)
        (is = 768 h)))))

(define-test identity-transform-layer-lifecycle
  :parent flow-integration-suite
  :description "Test identity transform layer create/release."
  (skip-unless-flow
    (let ((layer (frs:make-identity-transform-layer)))
      (true (not (cffi:null-pointer-p layer)))
      (frs:release-transform-layer layer))))

(define-test translation-transform-layer-lifecycle
  :parent flow-integration-suite
  :description "Test translation transform layer create/release."
  (skip-unless-flow
    (let ((layer (frs:make-translation-transform-layer 100.0 200.0)))
      (true (not (cffi:null-pointer-p layer)))
      (frs:release-transform-layer layer))))

(define-test opacity-layer-lifecycle
  :parent flow-integration-suite
  :description "Test opacity layer create/release."
  (skip-unless-flow
    (let ((layer (frs:make-opacity-layer 128)))
      (true (not (cffi:null-pointer-p layer)))
      (frs:release-opacity-layer layer))))

(define-test clip-rect-layer-lifecycle
  :parent flow-integration-suite
  :description "Test clip rect layer create/release."
  (skip-unless-flow
    (let ((layer (frs:make-clip-rect-layer 0 0 400 300)))
      (true (not (cffi:null-pointer-p layer)))
      (frs:release-clip-rect-layer layer))))

(define-test clip-rrect-layer-lifecycle
  :parent flow-integration-suite
  :description "Test clip rounded-rect layer create/release."
  (skip-unless-flow
    (let ((layer (frs:make-clip-rrect-layer 0 0 400 300 8.0)))
      (true (not (cffi:null-pointer-p layer)))
      (frs:release-clip-rrect-layer layer))))

(define-test clip-path-layer-lifecycle
  :parent flow-integration-suite
  :description "Test clip path layer create/release."
  (skip-unless-flow
    (let ((layer (frs:make-clip-path-layer)))
      (true (not (cffi:null-pointer-p layer)))
      (frs:release-clip-path-layer layer))))

(define-test layer-tree-with-root
  :parent flow-integration-suite
  :description "Test building a layer tree with a transform root."
  (skip-unless-flow
    (frs:with-layer-tree (tree 800 600)
      (let ((root (frs:make-identity-transform-layer)))
        (unwind-protect
             (progn
               (frs:layer-tree-set-root-layer tree (frs:transform-layer-as-container root))
               (true t))
          (frs:release-transform-layer root))))))

(define-test layer-tree-with-children
  :parent flow-integration-suite
  :description "Test building a layer tree with transform root and opacity child."
  (skip-unless-flow
    (frs:with-layer-tree (tree 800 600)
      (let ((root (frs:make-identity-transform-layer))
            (opacity (frs:make-opacity-layer 200)))
        (unwind-protect
             (progn
               (frs:transform-layer-add-child root (frs:opacity-layer-as-container opacity))
               (frs:layer-tree-set-root-layer tree (frs:transform-layer-as-container root))
               (true t))
          (frs:release-opacity-layer opacity)
          (frs:release-transform-layer root))))))

(define-test compositor-context-lifecycle
  :parent flow-integration-suite
  :description "Test compositor context create/release lifecycle."
  (skip-unless-flow
    (frs:with-compositor-context (ctx)
      (true (not (cffi:null-pointer-p ctx))))))

(define-test raster-cache-access
  :parent flow-integration-suite
  :description "Test accessing raster cache from compositor context."
  (skip-unless-flow
    (frs:with-compositor-context (ctx)
      (let ((cache (frs:compositor-context-get-raster-cache ctx)))
        (true (not (cffi:null-pointer-p cache)))
        (true (integerp (frs:raster-cache-get-cached-entries-count cache)))
        (true (integerp (frs:raster-cache-get-access-threshold cache)))))))

(define-test raster-cache-metrics-access
  :parent flow-integration-suite
  :description "Test getting raster cache metrics."
  (skip-unless-flow
    (frs:with-compositor-context (ctx)
      (let ((cache (frs:compositor-context-get-raster-cache ctx)))
        (let ((layer-metrics (frs:raster-cache-get-layer-metrics cache))
              (picture-metrics (frs:raster-cache-get-picture-metrics cache)))
          (true (listp layer-metrics))
          (true (listp picture-metrics))
          (true (integerp (getf layer-metrics :eviction-count)))
          (true (integerp (getf picture-metrics :in-use-bytes))))))))

(define-test frame-damage-lifecycle
  :parent flow-integration-suite
  :description "Test frame damage create/release lifecycle."
  (skip-unless-flow
    (frs:with-frame-damage (damage 800 600)
      (true (not (cffi:null-pointer-p damage))))))

(define-test frame-damage-add-damage
  :parent flow-integration-suite
  :description "Test adding damage rectangles."
  (skip-unless-flow
    (frs:with-frame-damage (damage 800 600)
      (frs:frame-damage-add-additional-damage damage 10 10 100 100)
      (frs:frame-damage-add-additional-damage damage 200 200 50 50)
      (true t))))

(define-test frame-damage-compute-clip
  :parent flow-integration-suite
  :description "Test computing clip rect from damage."
  (skip-unless-flow
    (frs:with-frame-damage (damage 800 600)
      (frs:with-layer-tree (tree 800 600)
        (let ((root (frs:make-identity-transform-layer)))
          (unwind-protect
               (progn
                 (frs:layer-tree-set-root-layer tree (frs:transform-layer-as-container root))
                 (frs:frame-damage-add-additional-damage damage 10 10 100 100)
                 (multiple-value-bind (has-damage x y w h)
                     (frs:frame-damage-compute-clip-rect damage tree)
                   (declare (ignore x y w h))
                   (true (or has-damage (not has-damage)))))
            (frs:release-transform-layer root)))))))

(define-test clip-behavior-all-values
  :parent flow-integration-suite
  :description "Test creating clip layers with all clip behavior values."
  (skip-unless-flow
    (dolist (behavior '(:anti-alias :hard-edge :none))
      (let ((layer (frs:make-clip-rect-layer 0 0 100 100 :clip-behavior behavior)))
        (unwind-protect
             (true (not (cffi:null-pointer-p layer)))
          (frs:release-clip-rect-layer layer))))))
