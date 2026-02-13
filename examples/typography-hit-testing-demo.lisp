;;;; flutter-render-stack/examples/typography-hit-testing-demo.lisp
;;;; Demo of glyph info and hit testing for text selection

(defpackage :typography-hit-testing-demo
  (:use :cl)
  (:local-nicknames (:frs :flutter-render-stack))
  (:export #:run))

(in-package :typography-hit-testing-demo)

(defun run (&optional (font-path "/usr/share/fonts/truetype/DejaVuSans.ttf"))
  "Run the typography hit testing demo.

Arguments:
  font-path - Path to a TTF font file (defaults to DejaVu Sans)"
  
  ;; Create a typography context and register a font
  (let ((typo-ctx (frs:make-typography-context)))
    (unwind-protect
         (progn
           ;; Register font
           (unless (probe-file font-path)
             (error "Font not found: ~A" font-path))
           (frs:register-font-from-file typo-ctx font-path "DemoFont")
           
           ;; Create a paragraph style
           (let ((style (frs:make-paragraph-style)))
             (unwind-protect
                  (progn
                    (frs:paragraph-style-set-font-family style "DemoFont")
                    (frs:paragraph-style-set-font-size style 20.0)
                    (frs:paragraph-style-set-font-weight style :weight400)
                    
                    ;; Build a paragraph with interesting text
                    (frs:with-paragraph-builder (builder typo-ctx)
                      (frs:paragraph-builder-push-style builder style)
                      (frs:paragraph-builder-add-text 
                       builder 
                       "Click anywhere on this text to see glyph information. ")
                      (frs:paragraph-builder-add-text
                       builder
                       "Each character belongs to a grapheme cluster ")
                      (frs:paragraph-builder-add-text
                       builder
                       "with specific bounds and text indices.")
                      (frs:paragraph-builder-pop-style builder)
                      
                      ;; Build with a constrained width
                      (let* ((paragraph (frs:paragraph-builder-build builder 400.0))
                             (height (frs:paragraph-get-height paragraph))
                             (line-count (frs:paragraph-get-line-count paragraph)))
                        
                        (unwind-protect
                             (progn
                               (format t "~%=== Typography Hit Testing Demo ===~%~%")
                               (format t "Paragraph Height: ~,2F pixels~%" height)
                               (format t "Paragraph Line Count: ~D~%" line-count)
                               
                               ;; Demo: Get glyph info at various positions
                               (format t "~%--- Glyph Info at Code Unit Index 10 ---~%")
                               (let ((glyph (frs:paragraph-glyph-info-at-code-unit-index 
                                            paragraph 10)))
                                 (if glyph
                                     (unwind-protect
                                          (progn
                                            (format t "Text range: ~D to ~D~%"
                                                    (frs:glyph-info-grapheme-cluster-code-unit-range-begin glyph)
                                                    (frs:glyph-info-grapheme-cluster-code-unit-range-end glyph))
                                            (destructuring-bind (x y w h)
                                                (frs:glyph-info-grapheme-cluster-bounds glyph)
                                              (format t "Bounds: x=~,2F, y=~,2F, w=~,2F, h=~,2F~%"
                                                      x y w h))
                                            (format t "Is ellipsis: ~A~%"
                                                    (if (frs:glyph-info-is-ellipsis glyph) "Yes" "No"))
                                            (format t "Text direction: ~A~%"
                                                    (frs:glyph-info-text-direction glyph)))
                                       (frs:release-glyph-info glyph))
                                     (format t "No glyph found at index 10~%")))
                               
                               ;; Demo: Hit testing at various coordinates
                               (format t "~%--- Hit Testing at Various Coordinates ---~%")
                               (dolist (coords '((10.0 15.0) (50.0 25.0) (100.0 50.0) (200.0 100.0)))
                                 (destructuring-bind (x y) coords
                                   (format t "~%Coordinate (~,1F, ~,1F):~%" x y)
                                   (let ((glyph (frs:paragraph-glyph-info-at-coordinate paragraph x y)))
                                     (if glyph
                                         (unwind-protect
                                              (let ((start (frs:glyph-info-grapheme-cluster-code-unit-range-begin glyph))
                                                    (end (frs:glyph-info-grapheme-cluster-code-unit-range-end glyph)))
                                                (format t "  Hit glyph at text indices ~D-~D~%" start end)
                                                (destructuring-bind (gx gy gw gh)
                                                    (frs:glyph-info-grapheme-cluster-bounds glyph)
                                                  (format t "  Glyph bounds: (~,1F,~,1F) ~,1Fx~,1F~%"
                                                          gx gy gw gh)))
                                           (frs:release-glyph-info glyph))
                                         (format t "  No glyph at this coordinate~%")))))
                               
                               ;; Demo: Iterate through all glyphs in paragraph
                               (format t "~%--- Iterating All Glyphs ---~%")
                               (format t "Getting glyph info at every 5th code unit index:~%")
                               (loop for i from 0 below 50 by 5
                                     do (let ((glyph (frs:paragraph-glyph-info-at-code-unit-index 
                                                      paragraph i)))
                                          (when glyph
                                            (unwind-protect
                                                 (format t "  Index ~2D: glyph range ~D-~D~%"
                                                         i
                                                         (frs:glyph-info-grapheme-cluster-code-unit-range-begin glyph)
                                                         (frs:glyph-info-grapheme-cluster-code-unit-range-end glyph))
                                              (frs:release-glyph-info glyph))))))
                          (frs:release-paragraph paragraph))))
               (frs:release-paragraph-style style))))
      (frs:release-typography-context typo-ctx)))
  
  (format t "~%=== Demo Complete ===~%")))

;; Run the demo if this file is loaded directly
(eval-when (:load-toplevel :execute)
  (format t "~%To run the demo, execute: (typography-hit-testing-demo:run)~%"))
