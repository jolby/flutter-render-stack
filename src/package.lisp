(defpackage :flutter-render-stack
  (:use :cl)
  (:nicknames :frs)
  (:export
   ;; Impeller - Context
   #:make-context
   #:destroy-context
   #:with-context
   
   ;; Impeller - Paint
   #:make-paint
   #:paint-set-color
   #:paint-set-stroke-width
   #:paint-set-style
   
   ;; Impeller - Path
   #:make-path-builder
   #:path-move-to
   #:path-line-to
   #:path-cubic-to
   #:path-close
   #:path-build
   
   ;; Impeller - Display List
   #:make-display-list-builder
   #:display-list-draw-rect
   #:display-list-draw-path
   #:display-list-draw-text
   #:display-list-build
   
   ;; Impeller - Typography
   #:make-typography-context
   #:make-paragraph-builder
   #:paragraph-add-text
   #:paragraph-build
   
   ;; Flow - Layer Tree
   #:make-layer-tree
   #:add-container-layer
   #:add-picture-layer
   #:layer-tree-root
   
   ;; Flow - Rasterizer
   #:rasterize-layer-tree
   
   ;; Flow - Damage
   #:compute-damage-region
   #:merge-damage))
