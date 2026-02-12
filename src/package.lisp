;;;; flutter-render-stack/package.lisp
;;;; Package definition for Flutter rendering stack wrappers (Impeller + Flow)

(defpackage :flutter-render-stack
  (:use :cl)
  (:nicknames :frs)
  (:local-nicknames (:a :alexandria)
                    (:log :org.shirakumo.verbose)
                    (:rs-internals :render-stack-internals)
                    (:impeller-ffi :%impeller)
                    (:flow-ffi :%flow))
  (:documentation
   "Lispy wrappers for Flutter's rendering stack (Impeller + Flow).
    Provides idiomatic Common Lisp interfaces for GPU-accelerated 2D graphics
    via Impeller and retained-mode compositing via Flow.")
  (:export
   ;; Conditions
   #:flutter-render-error
   #:flutter-render-error-message
   #:impeller-error
   #:flow-error
   #:impeller-creation-error
   #:impeller-creation-error-resource-type

   ;; === IMPELLER: Context management ===
   #:make-context
   #:release-context

   ;; === IMPELLER: Paint management ===
   #:make-paint
   #:release-paint
   #:paint-set-color
   #:paint-set-draw-style
   #:paint-set-stroke-width
   #:paint-set-stroke-cap
   #:paint-set-stroke-join
   #:paint-set-stroke-miter
   #:paint-set-color-source

   ;; === IMPELLER: Color sources (gradients) ===
   #:make-linear-gradient-color-source
   #:make-radial-gradient-color-source
   #:release-color-source

   ;; === IMPELLER: Display list building ===
   #:with-display-list-builder
   #:draw-paint
   #:draw-rect
   #:draw-oval
   #:draw-line
   #:draw-path
   #:execute-display-list
   #:surface-draw-display-list
   #:display-list-builder-set-transform

   ;; === IMPELLER: Display list state management ===
   #:display-list-builder-save
   #:display-list-builder-restore
   #:display-list-builder-get-save-count
   #:display-list-builder-translate
   #:display-list-builder-scale
   #:display-list-builder-clip-rect

   ;; === IMPELLER: Display list composition ===
   #:display-list-builder-draw-display-list

   ;; === IMPELLER: Display list lifecycle ===
   #:create-display-list
   #:release-display-list
   #:retain-display-list

   ;; === IMPELLER: Path building ===
   #:with-path-builder
   #:path-move-to
   #:path-line-to
   #:path-add-rect
   #:path-add-oval
   #:path-add-rounded-rect
   #:path-close
   #:build-path
   #:release-path

   ;; === IMPELLER: Rounded rectangles ===
   #:draw-rounded-rect

   ;; === IMPELLER: Shadows ===
   #:draw-shadow

   ;; === IMPELLER: Surface management ===
   #:make-wrapped-fbo-surface
   #:release-surface

   ;; === IMPELLER: Typography context ===
   #:make-typography-context
   #:release-typography-context
   #:register-font-from-memory
   #:register-font-from-file

   ;; === IMPELLER: Paragraph style ===
   #:make-paragraph-style
   #:release-paragraph-style
   #:paragraph-style-set-font-family
   #:paragraph-style-set-font-size
   #:paragraph-style-set-font-weight
   #:paragraph-style-set-font-style
   #:paragraph-style-set-foreground
   #:paragraph-style-set-text-alignment

   ;; === IMPELLER: Paragraph building ===
   #:with-paragraph-builder
   #:paragraph-builder-push-style
   #:paragraph-builder-pop-style
   #:paragraph-builder-add-text
   #:paragraph-builder-build
   #:release-paragraph

   ;; === IMPELLER: Paragraph metrics ===
   #:paragraph-get-height
   #:paragraph-get-max-width
   #:paragraph-get-longest-line-width
   #:paragraph-get-alphabetic-baseline

   ;; === IMPELLER: Drawing paragraphs ===
   #:draw-paragraph

   ;; === FLOW: Conditions ===
   #:flow-creation-error
   #:flow-creation-error-resource-type

   ;; === FLOW: Enum converters ===
   ;; (internal, but tested — clip-behavior-keyword->clip-behavior-int, etc.)

   ;; === FLOW: Layer tree ===
   #:make-layer-tree
   #:release-layer-tree
   #:retain-layer-tree
   #:layer-tree-set-root-layer
   #:layer-tree-get-frame-size
   #:with-layer-tree

   ;; === FLOW: Transform layer ===
   #:make-transform-layer
   #:make-identity-transform-layer
   #:make-translation-transform-layer
   #:release-transform-layer
   #:retain-transform-layer
   #:transform-layer-add-child
   #:transform-layer-as-container

   ;; === FLOW: Opacity layer ===
   #:make-opacity-layer
   #:release-opacity-layer
   #:retain-opacity-layer
   #:opacity-layer-add-child
   #:opacity-layer-as-container

   ;; === FLOW: Clip rect layer ===
   #:make-clip-rect-layer
   #:release-clip-rect-layer
   #:retain-clip-rect-layer
   #:clip-rect-layer-add-child
   #:clip-rect-layer-as-container

   ;; === FLOW: Clip rounded-rect layer ===
   #:make-clip-rrect-layer
   #:release-clip-rrect-layer
   #:retain-clip-rrect-layer
   #:clip-rrect-layer-add-child
   #:clip-rrect-layer-as-container

   ;; === FLOW: Clip path layer ===
   #:make-clip-path-layer
   #:release-clip-path-layer
   #:retain-clip-path-layer
   #:clip-path-layer-add-child
   #:clip-path-layer-as-container

   ;; === FLOW: Color filter layer ===
   #:make-color-filter-layer
   #:release-color-filter-layer
   #:retain-color-filter-layer
   #:color-filter-layer-add-child
   #:color-filter-layer-as-container

   ;; === FLOW: Image filter layer ===
   #:make-image-filter-layer
   #:release-image-filter-layer
   #:retain-image-filter-layer
   #:image-filter-layer-add-child
   #:image-filter-layer-as-container

   ;; === FLOW: Display list layer ===
   #:make-display-list-layer
   #:release-display-list-layer
   #:retain-display-list-layer
   #:display-list-layer-as-container

   ;; === FLOW: Container layer ===
   #:release-container-layer
   #:retain-container-layer

   ;; === FLOW: Compositor context ===
   #:make-compositor-context
   #:release-compositor-context
   #:retain-compositor-context
   #:with-compositor-context
   
   ;; === FLOW: Scoped frame (rasterization) ===
   #:compositor-context-acquire-frame
   #:release-scoped-frame
   #:retain-scoped-frame
   #:with-scoped-frame
   #:scoped-frame-build-display-list
   #:with-rasterized-display-list
   #:scoped-frame-raster

   ;; === FLOW: Raster cache ===
   #:compositor-context-get-raster-cache
   #:raster-cache-clear
   #:raster-cache-get-access-threshold
   #:raster-cache-get-cached-entries-count
   #:raster-cache-get-layer-cached-entries-count
   #:raster-cache-get-picture-cached-entries-count
   #:raster-cache-estimate-layer-byte-size
   #:raster-cache-estimate-picture-byte-size
   #:raster-cache-get-layer-metrics
   #:raster-cache-get-picture-metrics
   #:raster-cache-release
   #:raster-cache-retain

   ;; === FLOW: Frame damage ===
   #:make-frame-damage
   #:release-frame-damage
   #:retain-frame-damage
   #:with-frame-damage
   #:frame-damage-set-previous-layer-tree
   #:frame-damage-add-additional-damage
   #:frame-damage-compute-clip-rect

   ;; === FLOW: Geometry utilities ===
   #:flow-rect-contains-point
   #:flow-rect-intersection
   #:flow-rect-union
   #:flow-matrix-invert
   #:flow-matrix-multiply
   #:flow-point-transform
   ))
