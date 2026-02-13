;;;; flutter-render-stack/examples/line-metrics-demo.lisp
;;;; Demo of detailed line metrics for typography

(defpackage :line-metrics-demo
  (:use :cl)
  (:local-nicknames (:frs :flutter-render-stack))
  (:export #:run))

(in-package :line-metrics-demo)

(defun run (&optional (font-path "/usr/share/fonts/truetype/DejaVuSans.ttf"))
  "Run the line metrics demo.

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
                    (frs:paragraph-style-set-font-size style 18.0)
                    (frs:paragraph-style-set-font-weight style :weight400)
                    
                    ;; Build a paragraph with multiple lines
                    (frs:with-paragraph-builder (builder typo-ctx)
                      (frs:paragraph-builder-push-style builder style)
                      (frs:paragraph-builder-add-text 
                       builder 
                       "This is a demonstration of line metrics in Impeller.\n")
                      (frs:paragraph-builder-add-text
                       builder
                       "This text spans multiple lines with different content.\n")
                      (frs:paragraph-builder-add-text
                       builder
                       "Some lines are long enough to wrap automatically when they exceed the width.")
                      (frs:paragraph-builder-pop-style builder)
                      
                      ;; Build with a constrained width to force wrapping
                      (let* ((paragraph (frs:paragraph-builder-build builder 300.0))
                             (height (frs:paragraph-get-height paragraph))
                             (line-count (frs:paragraph-get-line-count paragraph)))
                        
                        (unwind-protect
                             (progn
                               (format t "~%=== Line Metrics Demo ===~%~%")
                               (format t "Paragraph Height: ~,2F pixels~%" height)
                               (format t "Paragraph Line Count: ~D~%" line-count)
                               (format t "Max Intrinsic Width: ~,2F pixels~%"
                                       (frs:paragraph-get-max-intrinsic-width paragraph))
                               (format t "Min Intrinsic Width: ~,2F pixels~%"
                                       (frs:paragraph-get-min-intrinsic-width paragraph))
                               (format t "Longest Line Width: ~,2F pixels~%"
                                       (frs:paragraph-get-longest-line-width paragraph))
                               (format t "Alphabetic Baseline: ~,2F pixels~%"
                                       (frs:paragraph-get-alphabetic-baseline paragraph))
                               (format t "Ideographic Baseline: ~,2F pixels~%"
                                       (frs:paragraph-get-ideographic-baseline paragraph))
                               
                               ;; Get detailed line metrics
                               (let ((metrics (frs:paragraph-get-line-metrics paragraph)))
                                 (unwind-protect
                                      (progn
                                        (format t "~%--- Per-Line Metrics ---~%")
                                        (loop for i from 0 below (frs:line-metrics-count metrics)
                                              do (format t "~%Line ~D:~%" i)
                                                 (format t "  Width: ~,2F pixels~%"
                                                         (frs:line-metrics-width metrics i))
                                                 (format t "  Height: ~,2F pixels~%"
                                                         (frs:line-metrics-height metrics i))
                                                 (format t "  Ascent: ~,2F pixels~%"
                                                         (frs:line-metrics-ascent metrics i))
                                                 (format t "  Descent: ~,2F pixels~%"
                                                         (frs:line-metrics-descent metrics i))
                                                 (format t "  Baseline Y: ~,2F pixels~%"
                                                         (frs:line-metrics-baseline metrics i))
                                                 (format t "  Left: ~,2F pixels~%"
                                                         (frs:line-metrics-left metrics i))
                                                 (format t "  Unscaled Ascent: ~,2F pixels~%"
                                                         (frs:line-metrics-unscaled-ascent metrics i))
                                                 (format t "  Hard Break: ~A~%"
                                                         (if (frs:line-metrics-hardbreak-p metrics i)
                                                             "Yes"
                                                             "No (wrapped)"))
                                                 (format t "  Code Unit Start: ~D~%"
                                                         (frs:line-metrics-code-unit-start-index metrics i))
                                                 (format t "  Code Unit End: ~D~%"
                                                         (frs:line-metrics-code-unit-end-index metrics i))
                                                 (format t "  End (excl. whitespace): ~D~%"
                                                         (frs:line-metrics-code-unit-end-index-excluding-whitespace 
                                                          metrics i))
                                                 (format t "  End (incl. newline): ~D~%"
                                                         (frs:line-metrics-code-unit-end-index-including-newline 
                                                          metrics i))))
                                   (frs:release-line-metrics metrics))))
                          (frs:release-paragraph paragraph))))
               (frs:release-paragraph-style style))))
      (frs:release-typography-context typo-ctx)))
  
  (format t "~%=== Demo Complete ===~%")))

;; Run the demo if this file is loaded directly
(eval-when (:load-toplevel :execute)
  (format t "~%To run the demo, execute: (line-metrics-demo:run)~%"))
