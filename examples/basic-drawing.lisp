;;;; examples/basic-drawing.lisp
;;;; Demonstrates core Impeller drawing operations via flutter-render-stack.
;;;;
;;;; NOTE: These examples assume an Impeller context and surface have already
;;;; been set up (e.g., via render-stack-sdl3 window initialization). Each
;;;; example is a standalone function you can call from a render loop.

(defpackage :frs-examples
  (:use :cl)
  (:local-nicknames (:frs :flutter-render-stack)))

(in-package :frs-examples)

;;; ---------------------------------------------------------------------------
;;; Example 1: Colored rectangles
;;; ---------------------------------------------------------------------------

(defun draw-colored-rectangles (surface)
  "Draw overlapping filled and stroked rectangles."
  (let ((fill-paint (frs:make-paint))
        (stroke-paint (frs:make-paint)))
    (unwind-protect
         (progn
           ;; Red filled rectangle
           (frs:paint-set-color fill-paint 1.0 0.2 0.2 1.0)
           (frs:paint-set-draw-style fill-paint :fill)

           ;; White stroked rectangle
           (frs:paint-set-color stroke-paint 1.0 1.0 1.0 1.0)
           (frs:paint-set-draw-style stroke-paint :stroke)
           (frs:paint-set-stroke-width stroke-paint 3.0)

           (frs:with-display-list-builder (builder)
             (frs:draw-rect builder 50 50 200 120 fill-paint)
             (frs:draw-rect builder 40 40 220 140 stroke-paint)
             (frs:execute-display-list surface builder)))
      (frs:release-paint fill-paint)
      (frs:release-paint stroke-paint))))

;;; ---------------------------------------------------------------------------
;;; Example 2: Custom path (triangle)
;;; ---------------------------------------------------------------------------

(defun draw-triangle (surface)
  "Draw a filled triangle using a custom path."
  (let ((paint (frs:make-paint)))
    (unwind-protect
         (progn
           (frs:paint-set-color paint 0.2 0.8 0.4 1.0) ; green
           (frs:paint-set-draw-style paint :fill)

           (frs:with-path-builder (pb)
             (frs:path-move-to pb 160 40)
             (frs:path-line-to pb 280 200)
             (frs:path-line-to pb 40 200)
             (frs:path-close pb)
             (let ((path (frs:build-path pb)))
               (unwind-protect
                    (frs:with-display-list-builder (builder)
                      (frs:draw-path builder path paint)
                      (frs:execute-display-list surface builder))
                 (frs:release-path path)))))
      (frs:release-paint paint))))

;;; ---------------------------------------------------------------------------
;;; Example 3: Rounded rectangle with shadow
;;; ---------------------------------------------------------------------------

(defun draw-card-with-shadow (surface)
  "Draw a Material Design style card: shadow + rounded rect."
  (let ((paint (frs:make-paint)))
    (unwind-protect
         (progn
           (frs:paint-set-color paint 1.0 1.0 1.0 1.0) ; white card
           (frs:paint-set-draw-style paint :fill)

           ;; Build a rounded-rect path for the shadow shape
           (frs:with-path-builder (pb)
             (frs:path-add-rounded-rect pb 60 80 240 160 :radius 12.0)
             (let ((shadow-path (frs:build-path pb)))
               (unwind-protect
                    (frs:with-display-list-builder (builder)
                      ;; Shadow first (behind the card)
                      (frs:draw-shadow builder shadow-path
                                       0.0 0.0 0.0 0.3  ; dark semi-transparent
                                       4.0)              ; elevation in dp
                      ;; Card on top
                      (frs:draw-rounded-rect builder 60 80 240 160 paint
                                             :radius 12.0)
                      (frs:execute-display-list surface builder))
                 (frs:release-path shadow-path)))))
      (frs:release-paint paint))))

;;; ---------------------------------------------------------------------------
;;; Example 4: Linear gradient
;;; ---------------------------------------------------------------------------

(defun draw-gradient-rect (surface)
  "Draw a rectangle filled with a horizontal red-to-blue gradient."
  (let ((paint (frs:make-paint))
        (gradient (frs:make-linear-gradient-color-source
                   0 0 300 0                                ; left to right
                   '((1.0 0.0 0.0 1.0) (0.0 0.0 1.0 1.0)) ; red -> blue
                   '(0.0 1.0))))                            ; stop positions
    (unwind-protect
         (progn
           (frs:paint-set-color-source paint gradient)
           (frs:with-display-list-builder (builder)
             (frs:draw-rect builder 20 20 300 180 paint)
             (frs:execute-display-list surface builder)))
      (frs:release-color-source gradient)
      (frs:release-paint paint))))

;;; ---------------------------------------------------------------------------
;;; Example 5: Transform state (save/restore)
;;; ---------------------------------------------------------------------------

(defun draw-transformed-shapes (surface)
  "Draw a grid of circles using translate + save/restore."
  (let ((paint (frs:make-paint)))
    (unwind-protect
         (progn
           (frs:paint-set-draw-style paint :fill)
           (frs:with-display-list-builder (builder)
             ;; 3x3 grid of circles with varying colors
             (dotimes (row 3)
               (frs:display-list-builder-save builder)
               (frs:display-list-builder-translate builder 20.0 (+ 20.0 (* row 70.0)))
               (dotimes (col 3)
                 (frs:paint-set-color paint
                                      (/ col 2.0)     ; red ramp
                                      (/ row 2.0)     ; green ramp
                                      0.6 1.0)
                 (frs:draw-oval builder (* col 70) 0 50 50 paint))
               (frs:display-list-builder-restore builder))
             (frs:execute-display-list surface builder)))
      (frs:release-paint paint))))

;;; ---------------------------------------------------------------------------
;;; Example 6: Retained display list (caching)
;;; ---------------------------------------------------------------------------

(defun draw-with-cached-display-list (surface)
  "Build a display list once, draw it multiple times at different opacities."
  (let ((paint (frs:make-paint)))
    (frs:paint-set-color paint 0.0 0.5 1.0 1.0) ; blue
    (frs:paint-set-draw-style paint :fill)

    ;; Build a cached display list containing a star pattern
    (let ((cached-dl
            (frs:with-display-list-builder (builder)
              (frs:with-path-builder (pb)
                (frs:path-move-to pb 50 0)
                (frs:path-line-to pb 65 35)
                (frs:path-line-to pb 100 35)
                (frs:path-line-to pb 72 57)
                (frs:path-line-to pb 82 95)
                (frs:path-line-to pb 50 72)
                (frs:path-line-to pb 18 95)
                (frs:path-line-to pb 28 57)
                (frs:path-line-to pb 0 35)
                (frs:path-line-to pb 35 35)
                (frs:path-close pb)
                (let ((star (frs:build-path pb)))
                  (unwind-protect
                       (frs:draw-path builder star paint)
                    (frs:release-path star))))
              (frs:create-display-list builder))))
      (unwind-protect
           ;; Draw the same star 3 times at different positions and opacities
           (frs:with-display-list-builder (builder)
             (frs:display-list-builder-save builder)
             (frs:display-list-builder-translate builder 20.0 20.0)
             (frs:display-list-builder-draw-display-list builder cached-dl 1.0)
             (frs:display-list-builder-restore builder)

             (frs:display-list-builder-save builder)
             (frs:display-list-builder-translate builder 140.0 20.0)
             (frs:display-list-builder-draw-display-list builder cached-dl 0.5)
             (frs:display-list-builder-restore builder)

             (frs:display-list-builder-save builder)
             (frs:display-list-builder-translate builder 260.0 20.0)
             (frs:display-list-builder-draw-display-list builder cached-dl 0.2)
             (frs:display-list-builder-restore builder)

             (frs:execute-display-list surface builder))
        (frs:release-display-list cached-dl)))
    (frs:release-paint paint)))
