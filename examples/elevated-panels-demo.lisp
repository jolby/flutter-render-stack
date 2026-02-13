;;;; flutter-render-stack/examples/elevated-panels-demo.lisp
;;;; Demo of Material Design style elevated panels
;;;; 
;;;; Note: This demo shows API usage. The elevated panel functions themselves
;;;; work correctly (tested), but rendering requires an OpenGL context which
;;;; is not available in headless/test environments.

(defpackage :elevated-panels-demo
  (:use :cl)
  (:local-nicknames (:frs :flutter-render-stack))
  (:export #:run
            #:show-usage))

(in-package :elevated-panels-demo)

(defun show-usage ()
  "Show API usage examples for elevated panels."
  (format t "~%=== Elevated Panels API Usage ===~%~%")
  
  (format t ";; Draw a Material Design card at 4dp elevation~%")
  (format t "(frs:draw-card builder 50 50 300 200~%")
  (format t "               :elevation 4~%")
  (format t "               :corner-radius 8.0~%")
  (format t "               :panel-color '(1.0 1.0 1.0 1.0))~%~%")
  
  (format t ";; Draw a Floating Action Button~%")
  (format t "(frs:draw-fab builder 350 550 56~%")
  (format t "             :elevation 6~%")
  (format t "             :fab-color '(0.2 0.6 1.0 1.0))~%~%")
  
  (format t ";; Draw a dialog (modal surface)~%")
  (format t "(frs:draw-dialog builder 100 100 300 200~%")
  (format t "                :elevation 24~%")
  (format t "                :corner-radius 28.0)~%~%")
  
  (format t ";; Draw custom elevated panel~%")
  (format t "(frs:draw-elevated-panel builder 100 100 200 150 8.0~%")
  (format t "                           :corner-radius 12.0~%")
  (format t "                           :panel-color '(0.9 0.95 1.0 1.0)~%")
  (format t "                           :shadow-opacity 0.4)~%~%")
  
  (format t ";; Draw shadow only (for custom content)~%")
  (format t "(frs:draw-elevation-shadow builder 50 50 200 100 4.0~%")
  (format t "                            :corner-radius 8.0)~%~%")
  
  (format t "Elevation levels (Material Design 3):~%")
  (format t "  0dp   - Flat (no shadow)~%")
  (format t "  1-2dp - Cards at rest~%")
  (format t "  4-8dp - Raised/hovered~%")
  (format t "  16dp  - Navigation drawer~%")
  (format t "  24dp  - Modal dialogs~%~%"))

(defun run ()
  "Show elevated panels API usage."
  (show-usage)
  (format t "To use in your application:~%")
  (format t "1. Create a display list builder with (frs:with-display-list-builder (builder) ...)~%")
  (format t "2. Call elevated panel functions within the builder scope~%")
  (format t "3. Create and execute the display list~%~%"))
