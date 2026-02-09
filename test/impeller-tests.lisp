;;;; flutter-render-stack/test/impeller-tests.lisp
;;;; Test suite for Impeller wrapper module

(in-package :flutter-render-stack-tests)

;;; Top-level suite

(define-test impeller-suite
  "Top-level test suite for Impeller wrapper module.")

;;; ============================================================
;;; Export verification tests (no native library required)
;;; ============================================================

(define-test export-suite
  :parent impeller-suite
  "Verify all public symbols are exported and bound.")

;;; Context exports

(define-test context-exports
  :parent export-suite
  :description "Verify context management functions are exported."
  (true (fboundp 'frs:make-context))
  (true (fboundp 'frs:release-context)))

;;; Paint exports

(define-test paint-exports
  :parent export-suite
  :description "Verify paint functions are exported."
  (true (fboundp 'frs:make-paint))
  (true (fboundp 'frs:release-paint))
  (true (fboundp 'frs:paint-set-color))
  (true (fboundp 'frs:paint-set-draw-style))
  (true (fboundp 'frs:paint-set-stroke-width))
  (true (fboundp 'frs:paint-set-stroke-cap))
  (true (fboundp 'frs:paint-set-stroke-join))
  (true (fboundp 'frs:paint-set-stroke-miter))
  (true (fboundp 'frs:paint-set-color-source)))

;;; Path exports

(define-test path-exports
  :parent export-suite
  :description "Verify path building functions are exported."
  (true (macro-function 'frs:with-path-builder))
  (true (fboundp 'frs:path-move-to))
  (true (fboundp 'frs:path-line-to))
  (true (fboundp 'frs:path-add-rect))
  (true (fboundp 'frs:path-add-oval))
  (true (fboundp 'frs:path-add-rounded-rect))
  (true (fboundp 'frs:path-close))
  (true (fboundp 'frs:build-path))
  (true (fboundp 'frs:release-path)))

;;; Display list exports

(define-test display-list-exports
  :parent export-suite
  :description "Verify display list functions are exported."
  ;; Macro
  (true (macro-function 'frs:with-display-list-builder))
  ;; Drawing ops
  (true (fboundp 'frs:draw-paint))
  (true (fboundp 'frs:draw-rect))
  (true (fboundp 'frs:draw-oval))
  (true (fboundp 'frs:draw-path))
  (true (fboundp 'frs:draw-rounded-rect))
  (true (fboundp 'frs:draw-shadow))
  ;; State management
  (true (fboundp 'frs:display-list-builder-set-transform))
  (true (fboundp 'frs:display-list-builder-save))
  (true (fboundp 'frs:display-list-builder-restore))
  (true (fboundp 'frs:display-list-builder-get-save-count))
  (true (fboundp 'frs:display-list-builder-translate))
  (true (fboundp 'frs:display-list-builder-scale))
  (true (fboundp 'frs:display-list-builder-clip-rect))
  ;; Composition
  (true (fboundp 'frs:display-list-builder-draw-display-list))
  ;; Lifecycle
  (true (fboundp 'frs:create-display-list))
  (true (fboundp 'frs:release-display-list))
  (true (fboundp 'frs:retain-display-list))
  (true (fboundp 'frs:execute-display-list))
  ;; Surface
  (true (fboundp 'frs:make-wrapped-fbo-surface))
  (true (fboundp 'frs:release-surface))
  ;; Gradients
  (true (fboundp 'frs:make-linear-gradient-color-source))
  (true (fboundp 'frs:make-radial-gradient-color-source))
  (true (fboundp 'frs:release-color-source)))

;;; Typography exports

(define-test typography-context-exports
  :parent export-suite
  :description "Verify typography context functions are exported."
  (true (fboundp 'frs:make-typography-context))
  (true (fboundp 'frs:release-typography-context))
  (true (fboundp 'frs:register-font-from-memory))
  (true (fboundp 'frs:register-font-from-file)))

(define-test paragraph-style-exports
  :parent export-suite
  :description "Verify paragraph style functions are exported."
  (true (fboundp 'frs:make-paragraph-style))
  (true (fboundp 'frs:release-paragraph-style))
  (true (fboundp 'frs:paragraph-style-set-font-family))
  (true (fboundp 'frs:paragraph-style-set-font-size))
  (true (fboundp 'frs:paragraph-style-set-font-weight))
  (true (fboundp 'frs:paragraph-style-set-font-style))
  (true (fboundp 'frs:paragraph-style-set-foreground))
  (true (fboundp 'frs:paragraph-style-set-text-alignment)))

(define-test paragraph-builder-exports
  :parent export-suite
  :description "Verify paragraph builder functions are exported."
  (true (macro-function 'frs:with-paragraph-builder))
  (true (fboundp 'frs:paragraph-builder-push-style))
  (true (fboundp 'frs:paragraph-builder-pop-style))
  (true (fboundp 'frs:paragraph-builder-add-text))
  (true (fboundp 'frs:paragraph-builder-build))
  (true (fboundp 'frs:release-paragraph)))

(define-test paragraph-metrics-exports
  :parent export-suite
  :description "Verify paragraph metrics functions are exported."
  (true (fboundp 'frs:paragraph-get-height))
  (true (fboundp 'frs:paragraph-get-max-width))
  (true (fboundp 'frs:paragraph-get-longest-line-width))
  (true (fboundp 'frs:paragraph-get-alphabetic-baseline)))

(define-test draw-paragraph-export
  :parent export-suite
  :description "Verify draw-paragraph function is exported."
  (true (fboundp 'frs:draw-paragraph)))

;;; Rounded rect export

(define-test rounded-rect-export
  :parent export-suite
  :description "Verify rounded rectangle function is exported."
  (true (fboundp 'frs:draw-rounded-rect)))

;;; ============================================================
;;; Condition tests (no native library required)
;;; ============================================================

(define-test condition-suite
  :parent impeller-suite
  "Tests for condition hierarchy.")

(define-test condition-hierarchy
  :parent condition-suite
  :description "Verify condition class hierarchy."
  (true (subtypep 'frs:impeller-error 'frs:flutter-render-error))
  (true (subtypep 'frs:flow-error 'frs:flutter-render-error))
  (true (subtypep 'frs:impeller-creation-error 'frs:impeller-error))
  (true (subtypep 'frs:flutter-render-error 'error)))

(define-test creation-error-resource-type
  :parent condition-suite
  :description "Verify impeller-creation-error carries resource-type."
  (let ((err (make-condition 'frs:impeller-creation-error
                             :resource-type "test resource")))
    (is string= "test resource"
        (frs:impeller-creation-error-resource-type err))))

;;; ============================================================
;;; Enum converter tests (no native library required)
;;; ============================================================

(define-test enum-suite
  :parent impeller-suite
  "Tests for keyword-to-integer enum conversion.")

(define-test draw-style-conversion
  :parent enum-suite
  :description "Test draw style keyword conversion."
  (true (fboundp 'frs::draw-style-keyword->draw-style-int))
  (is = 0 (frs::draw-style-keyword->draw-style-int :fill))
  (is = 1 (frs::draw-style-keyword->draw-style-int :stroke))
  (is = 2 (frs::draw-style-keyword->draw-style-int :stroke-and-fill)))

(define-test stroke-cap-conversion
  :parent enum-suite
  :description "Test stroke cap keyword conversion."
  (is = 0 (frs::stroke-cap-keyword->stroke-cap-int :butt))
  (is = 1 (frs::stroke-cap-keyword->stroke-cap-int :round))
  (is = 2 (frs::stroke-cap-keyword->stroke-cap-int :square)))

(define-test stroke-join-conversion
  :parent enum-suite
  :description "Test stroke join keyword conversion."
  (is = 0 (frs::stroke-join-keyword->stroke-join-int :miter))
  (is = 1 (frs::stroke-join-keyword->stroke-join-int :round))
  (is = 2 (frs::stroke-join-keyword->stroke-join-int :bevel)))

(define-test fill-type-conversion
  :parent enum-suite
  :description "Test fill type keyword conversion."
  (is = 0 (frs::fill-type-keyword->fill-type-int :non-zero))
  (is = 1 (frs::fill-type-keyword->fill-type-int :odd)))

(define-test font-weight-conversion
  :parent enum-suite
  :description "Test font weight keyword conversion."
  (is = 0 (frs::font-weight-keyword->font-weight-int :weight100))
  (is = 3 (frs::font-weight-keyword->font-weight-int :weight400))
  (is = 6 (frs::font-weight-keyword->font-weight-int :weight700))
  (is = 8 (frs::font-weight-keyword->font-weight-int :weight900)))

(define-test font-style-conversion
  :parent enum-suite
  :description "Test font style keyword conversion."
  (is = 0 (frs::font-style-keyword->font-style-int :normal))
  (is = 1 (frs::font-style-keyword->font-style-int :italic)))

(define-test text-alignment-conversion
  :parent enum-suite
  :description "Test text alignment keyword conversion."
  (is = 0 (frs::text-alignment-keyword->text-alignment-int :left))
  (is = 1 (frs::text-alignment-keyword->text-alignment-int :right))
  (is = 2 (frs::text-alignment-keyword->text-alignment-int :center))
  (is = 3 (frs::text-alignment-keyword->text-alignment-int :justify))
  (is = 4 (frs::text-alignment-keyword->text-alignment-int :start))
  (is = 5 (frs::text-alignment-keyword->text-alignment-int :end)))

(define-test tile-mode-conversion
  :parent enum-suite
  :description "Test tile mode keyword conversion."
  (is = 0 (frs::tile-mode-keyword->tile-mode-int :clamp))
  (is = 1 (frs::tile-mode-keyword->tile-mode-int :repeat))
  (is = 2 (frs::tile-mode-keyword->tile-mode-int :mirror))
  (is = 3 (frs::tile-mode-keyword->tile-mode-int :decal)))

(define-test clip-operation-conversion
  :parent enum-suite
  :description "Test clip operation keyword conversion."
  (is = 0 (frs::clip-op-keyword->clip-op-int :intersect))
  (is = 1 (frs::clip-op-keyword->clip-op-int :difference)))

;;; Bidirectional conversion

(define-test enum-round-trip
  :parent enum-suite
  :description "Test integer-to-keyword reverse conversion."
  (is eq :fill (frs::draw-style-int->draw-style-keyword 0))
  (is eq :stroke (frs::draw-style-int->draw-style-keyword 1))
  (is eq :weight400 (frs::font-weight-int->font-weight-keyword 3))
  (is eq :italic (frs::font-style-int->font-style-keyword 1))
  (is eq :center (frs::text-alignment-int->text-alignment-keyword 2)))

;;; ============================================================
;;; Integration tests (skipped when native libraries are absent)
;;; ============================================================

(define-test integration-suite
  :parent impeller-suite
  "Integration tests requiring native Impeller library.
These tests are honestly skipped when native libraries are unavailable.")

(define-test typography-context-lifecycle
  :parent integration-suite
  :description "Test typography context create/release lifecycle."
  (skip-unless-impeller
    (let ((ctx (frs:make-typography-context)))
      (true (not (cffi:null-pointer-p ctx)))
      (frs:release-typography-context ctx))))

(define-test paragraph-style-lifecycle
  :parent integration-suite
  :description "Test paragraph style create/release lifecycle."
  (skip-unless-impeller
    (let ((style (frs:make-paragraph-style)))
      (true (not (cffi:null-pointer-p style)))
      (frs:release-paragraph-style style))))

(define-test paragraph-style-font-weight-all-values
  :parent integration-suite
  :description "Test setting all font weight values on paragraph style."
  (skip-unless-impeller
    (let ((style (frs:make-paragraph-style)))
      (unwind-protect
           (progn
             (dolist (weight '(:weight100 :weight200 :weight300 :weight400
                               :weight500 :weight600 :weight700 :weight800 :weight900))
               (frs:paragraph-style-set-font-weight style weight))
             (true t))
        (frs:release-paragraph-style style)))))

(define-test paragraph-style-text-alignment-all-values
  :parent integration-suite
  :description "Test setting all text alignment values."
  (skip-unless-impeller
    (let ((style (frs:make-paragraph-style)))
      (unwind-protect
           (progn
             (dolist (align '(:left :right :center :justify :start :end))
               (frs:paragraph-style-set-text-alignment style align))
             (true t))
        (frs:release-paragraph-style style)))))

(define-test paragraph-builder-with-typography-context
  :parent integration-suite
  :description "Test paragraph builder creation with typography context."
  (skip-unless-impeller
    (let ((typo-ctx (frs:make-typography-context)))
      (unwind-protect
           (frs:with-paragraph-builder (builder typo-ctx)
             (true (not (cffi:null-pointer-p builder))))
        (frs:release-typography-context typo-ctx)))))

(define-test paragraph-builder-add-text-test
  :parent integration-suite
  :description "Test adding text to paragraph builder."
  (skip-unless-impeller
    (let ((typo-ctx (frs:make-typography-context)))
      (unwind-protect
           (frs:with-paragraph-builder (builder typo-ctx)
             (frs:paragraph-builder-add-text builder "Hello, World!")
             (true t))
        (frs:release-typography-context typo-ctx)))))

(define-test paragraph-build-and-release
  :parent integration-suite
  :description "Test building and releasing a paragraph."
  (skip-unless-impeller
    (let ((typo-ctx (frs:make-typography-context))
          (style (frs:make-paragraph-style)))
      (unwind-protect
           (frs:with-paragraph-builder (builder typo-ctx)
             (frs:paragraph-builder-push-style builder style)
             (frs:paragraph-builder-add-text builder "Test paragraph")
             (frs:paragraph-builder-pop-style builder)
             (let ((paragraph (frs:paragraph-builder-build builder 200.0)))
               (true (not (cffi:null-pointer-p paragraph)))
               (frs:release-paragraph paragraph)))
        (frs:release-paragraph-style style)
        (frs:release-typography-context typo-ctx)))))

(define-test paragraph-metrics-access
  :parent integration-suite
  :description "Test accessing paragraph metrics after build."
  (skip-unless-impeller
    (let ((typo-ctx (frs:make-typography-context))
          (style (frs:make-paragraph-style)))
      (unwind-protect
           (frs:with-paragraph-builder (builder typo-ctx)
             (frs:paragraph-style-set-font-size style 16.0)
             (frs:paragraph-builder-push-style builder style)
             (frs:paragraph-builder-add-text builder "Test")
             (frs:paragraph-builder-pop-style builder)
             (let ((paragraph (frs:paragraph-builder-build builder 100.0)))
               (unwind-protect
                    (progn
                      (true (numberp (frs:paragraph-get-height paragraph)))
                      (true (numberp (frs:paragraph-get-max-width paragraph)))
                      (true (numberp (frs:paragraph-get-longest-line-width paragraph)))
                      (true (numberp (frs:paragraph-get-alphabetic-baseline paragraph))))
                 (frs:release-paragraph paragraph))))
        (frs:release-paragraph-style style)
        (frs:release-typography-context typo-ctx)))))
