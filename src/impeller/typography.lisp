;;;; flutter-render-stack/impeller/typography.lisp
;;;; Impeller typography and text rendering

(in-package :flutter-render-stack)

;;; Enum converters for typography properties

(rs-internals:define-case-converter (:font-weight-keyword :font-weight-int)
  (:weight100 0) (:weight200 1) (:weight300 2) (:weight400 3)
  (:weight500 4) (:weight600 5) (:weight700 6) (:weight800 7)
  (:weight900 8))

(rs-internals:define-case-converter (:font-style-keyword :font-style-int)
  (:normal 0) (:italic 1))

(rs-internals:define-case-converter (:text-alignment-keyword :text-alignment-int)
  (:left 0) (:right 1) (:center 2) (:justify 3) (:start 4) (:end 5))

(rs-internals:define-case-converter (:text-direction-keyword :text-direction-int)
  (:rtl 0) (:ltr 1))

(rs-internals:define-case-converter (:text-decoration-keyword :text-decoration-int)
  (:none 0) (:underline 1) (:overline 2) (:line-through 3))

;;; Typography context management

(defun make-typography-context ()
  "Create an Impeller typography context for managing fonts and text.

Returns a pointer to an ImpellerTypographyContext object. Raises
impeller-creation-error if context creation fails.

The returned context must be released via release-typography-context."
  (let ((ctx (impeller-ffi:typography-context-new)))
    (when (cffi:null-pointer-p ctx)
      (error 'impeller-creation-error :resource-type "typography context"))
    ctx))

(defun release-typography-context (context)
  "Release an Impeller typography context.

Frees all resources associated with the typography context including
registered fonts. Must be called exactly once per context created
via make-typography-context."
  (impeller-ffi:typography-context-release context))

;;; Font loading

(cffi:defcallback font-data-release-callback :void ((user-data :pointer))
  "Callback invoked by Impeller when font data is no longer needed.
user-data is the pointer to the mapping struct allocated in register-font-from-memory."
  (unless (cffi:null-pointer-p user-data)
    (let ((data-ptr (cffi:foreign-slot-value user-data
                                              '(:struct impeller-ffi:mapping)
                                              '%impeller::data)))
      (log:debug :frs "font-data-release: freeing data ~S and mapping ~S"
                 data-ptr user-data)
      (unless (cffi:null-pointer-p data-ptr)
        (cffi:foreign-free data-ptr))
      (cffi:foreign-free user-data))))

(defun register-font-from-memory (typography-context font-data family-name)
  "Register a font from memory data with the typography context.

Arguments:
  typography-context - Typography context from make-typography-context
  font-data          - Byte vector containing font file data (TTF/OTF)
  family-name        - Family name alias for the font (string)

Returns T on success, NIL on failure.

The font-data should be a (vector (unsigned-byte 8)). The data is
copied to foreign memory. The foreign memory is freed via on-release
callback when the typography context is released."
  (let* ((length (length font-data))
         (foreign-data (cffi:foreign-alloc :uint8 :count length))
         (mapping (cffi:foreign-alloc '(:struct impeller-ffi:mapping))))
    (loop for i from 0 below length
          do (setf (cffi:mem-aref foreign-data :uint8 i)
                   (aref font-data i)))
    (setf (cffi:foreign-slot-value mapping '(:struct impeller-ffi:mapping) '%impeller::data)
          foreign-data
          (cffi:foreign-slot-value mapping '(:struct impeller-ffi:mapping) '%impeller::length)
          length
          (cffi:foreign-slot-value mapping '(:struct impeller-ffi:mapping) '%impeller::on-release)
          (cffi:callback font-data-release-callback))
    (let ((result (impeller-ffi:typography-context-register-font
                   typography-context
                   mapping
                   mapping ;; user-data for callback
                   family-name)))
      (log:debug :frs "register-font-from-memory: result=~S family=~S length=~D"
                 result family-name length)
      result)))

(defun register-font-from-file (typography-context pathname family-name)
  "Register a font from a file with the typography context.

Arguments:
  typography-context - Typography context from make-typography-context
  pathname           - Path to font file (TTF/OTF)
  family-name        - Family name alias for the font (string)

Returns T on success, signals error on failure."
  (let ((font-data (a:read-file-into-byte-vector pathname)))
    (unless (register-font-from-memory typography-context font-data family-name)
      (error 'impeller-creation-error :resource-type "font registration"))
    t))

;;; Paragraph style management

(defun make-paragraph-style ()
  "Create an Impeller paragraph style for text formatting.

Returns a pointer to an ImpellerParagraphStyle object. Raises
impeller-creation-error if style creation fails.

The returned style must be released via release-paragraph-style."
  (let ((style (impeller-ffi:paragraph-style-new)))
    (when (cffi:null-pointer-p style)
      (error 'impeller-creation-error :resource-type "paragraph style"))
    style))

(defun release-paragraph-style (style)
  "Release an Impeller paragraph style.

Frees all resources associated with the style. Must be called exactly
once per style created via make-paragraph-style."
  (impeller-ffi:paragraph-style-release style))

(defun paragraph-style-set-font-family (style family-name)
  "Set the font family for a paragraph style.

Arguments:
  style       - Paragraph style from make-paragraph-style
  family-name - Font family name (must match a registered font)"
  (impeller-ffi:paragraph-style-set-font-family style family-name))

(defun paragraph-style-set-font-size (style size)
  "Set the font size for a paragraph style.

Arguments:
  style - Paragraph style from make-paragraph-style
  size  - Font size in logical pixels (float)"
  (impeller-ffi:paragraph-style-set-font-size style (float size 1.0f0)))

(defun paragraph-style-set-font-weight (style weight)
  "Set the font weight for a paragraph style.

Arguments:
  style  - Paragraph style from make-paragraph-style
  weight - Font weight keyword:
           :weight100 (thin), :weight200, :weight300, :weight400 (normal),
           :weight500, :weight600, :weight700 (bold), :weight800, :weight900"
  (impeller-ffi:paragraph-style-set-font-weight
   style (font-weight-keyword->font-weight-int weight)))

(defun paragraph-style-set-font-style (style font-style)
  "Set the font style (normal/italic) for a paragraph style.

Arguments:
  style      - Paragraph style from make-paragraph-style
  font-style - :normal or :italic"
  (impeller-ffi:paragraph-style-set-font-style
   style (font-style-keyword->font-style-int font-style)))

(defun paragraph-style-set-foreground (style paint)
  "Set the foreground paint (text color) for a paragraph style.

Arguments:
  style - Paragraph style from make-paragraph-style
  paint - Paint object from make-paint (with color set)"
  (impeller-ffi:paragraph-style-set-foreground style paint))

(defun paragraph-style-set-text-alignment (style alignment)
  "Set the text alignment for a paragraph style.

Arguments:
  style     - Paragraph style from make-paragraph-style
  alignment - :left, :right, :center, :justify, :start, or :end"
  (impeller-ffi:paragraph-style-set-text-alignment
   style (text-alignment-keyword->text-alignment-int alignment)))

(defun paragraph-style-set-text-direction (style direction)
  "Set the text direction for a paragraph style.

Arguments:
  style     - Paragraph style from make-paragraph-style
  direction - :ltr (left-to-right) or :rtl (right-to-left)"
  (impeller-ffi:paragraph-style-set-text-direction
   style (text-direction-keyword->text-direction-int direction)))

(defun paragraph-style-set-background (style paint)
  "Set the background paint for a paragraph style.

Arguments:
  style - Paragraph style from make-paragraph-style
  paint - Paint object from make-paint (with color set)"
  (impeller-ffi:paragraph-style-set-background style paint))

(defun paragraph-style-set-height (style height)
  "Set the line height multiplier for a paragraph style.

Arguments:
  style  - Paragraph style from make-paragraph-style
  height - Line height multiplier (float, 1.0 = normal)"
  (impeller-ffi:paragraph-style-set-height style (float height 1.0f0)))

(defun paragraph-style-set-max-lines (style max-lines)
  "Set the maximum number of lines for a paragraph.

Arguments:
  style     - Paragraph style from make-paragraph-style
  max-lines - Maximum number of lines (integer), or 0 for unlimited"
  (impeller-ffi:paragraph-style-set-max-lines style max-lines))

(defun paragraph-style-set-locale (style locale)
  "Set the locale for a paragraph style.

Arguments:
  style  - Paragraph style from make-paragraph-style
  locale - Locale string (e.g., \"en_US\", \"ja_JP\")"
  (impeller-ffi:paragraph-style-set-locale style locale))

(defun paragraph-style-set-ellipsis (style ellipsis)
  "Set the ellipsis string for truncated text.

Arguments:
  style    - Paragraph style from make-paragraph-style
  ellipsis - Ellipsis string (e.g., \"...\", \"…\")"
  (impeller-ffi:paragraph-style-set-ellipsis style ellipsis))

(defun paragraph-style-set-text-decoration (style decoration)
  "Set the text decoration for a paragraph style.

Arguments:
  style      - Paragraph style from make-paragraph-style
  decoration - :none, :underline, :overline, or :line-through"
  (impeller-ffi:paragraph-style-set-text-decoration
   style (text-decoration-keyword->text-decoration-int decoration)))

;;; Paragraph builder and rendering

(defmacro with-paragraph-builder ((builder-var typography-context) &body body)
  "Allocate and manage a paragraph builder.

Syntax: (with-paragraph-builder (builder typo-ctx) ...)

The builder variable is bound to a paragraph builder pointer for use
with paragraph-builder-* functions. The builder is automatically
released upon exit (success or error).

Returns the result of body."
  `(let ((,builder-var (impeller-ffi:paragraph-builder-new ,typography-context)))
     (when (cffi:null-pointer-p ,builder-var)
       (error 'impeller-creation-error :resource-type "paragraph builder"))
     (unwind-protect
          (progn ,@body)
       (impeller-ffi:paragraph-builder-release ,builder-var))))

(defun paragraph-builder-push-style (builder style)
  "Push a paragraph style onto the builder's style stack.

Arguments:
  builder - Paragraph builder from with-paragraph-builder
  style   - Paragraph style from make-paragraph-style

Text added after this call will use this style until pop-style is called."
  (impeller-ffi:paragraph-builder-push-style builder style))

(defun paragraph-builder-pop-style (builder)
  "Pop the current style from the builder's style stack.

Arguments:
  builder - Paragraph builder from with-paragraph-builder

Reverts to the previous style on the stack."
  (impeller-ffi:paragraph-builder-pop-style builder))

(defun paragraph-builder-add-text (builder text)
  "Add text to a paragraph builder.

Arguments:
  builder - Paragraph builder from with-paragraph-builder
  text    - String to add (will be UTF-8 encoded)"
  (cffi:with-foreign-string ((str-ptr length) text :encoding :utf-8)
    (impeller-ffi:paragraph-builder-add-text builder str-ptr (1- length))))

(defun paragraph-builder-build (builder width)
  "Build a paragraph from the builder's accumulated text and styles.

Arguments:
  builder - Paragraph builder from with-paragraph-builder
  width   - Maximum paragraph width for line wrapping (float)

Returns a paragraph object. The returned paragraph must be released
via release-paragraph when no longer needed."
  (rs-internals:without-float-traps
    (let ((paragraph (impeller-ffi:paragraph-builder-build-paragraph-new
                      builder (float width 1.0f0))))
      (when (cffi:null-pointer-p paragraph)
        (error 'impeller-creation-error :resource-type "paragraph"))
      paragraph)))

(defun release-paragraph (paragraph)
  "Release an Impeller paragraph.

Frees all resources associated with the paragraph. Must be called
exactly once per paragraph created via paragraph-builder-build."
  (impeller-ffi:paragraph-release paragraph))

;;; Paragraph metrics

(defun paragraph-get-height (paragraph)
  "Get the height of a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns the total height in logical pixels (float)."
  (rs-internals:without-float-traps
    (impeller-ffi:paragraph-get-height paragraph)))

(defun paragraph-get-max-width (paragraph)
  "Get the maximum width used by a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns the layout width constraint that was passed to build (float)."
  (rs-internals:without-float-traps
    (impeller-ffi:paragraph-get-max-width paragraph)))

(defun paragraph-get-longest-line-width (paragraph)
  "Get the width of the longest line in a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns the actual longest line width in logical pixels (float)."
  (rs-internals:without-float-traps
    (impeller-ffi:paragraph-get-longest-line-width paragraph)))

(defun paragraph-get-alphabetic-baseline (paragraph)
  "Get the alphabetic baseline of a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns the baseline offset from the top in logical pixels (float)."
  (rs-internals:without-float-traps
    (impeller-ffi:paragraph-get-alphabetic-baseline paragraph)))

(defun paragraph-get-ideographic-baseline (paragraph)
  "Get the ideographic baseline of a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns the ideographic baseline offset from the top in logical pixels (float).
This is used for CJK (Chinese, Japanese, Korean) fonts."
  (rs-internals:without-float-traps
    (impeller-ffi:paragraph-get-ideographic-baseline paragraph)))

(defun paragraph-get-line-count (paragraph)
  "Get the number of lines in a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns the total number of lines as an integer."
  (impeller-ffi:paragraph-get-line-count paragraph))

(defun paragraph-get-max-intrinsic-width (paragraph)
  "Get the maximum intrinsic width of a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns the width the paragraph would have if no line breaking constraints
were applied (float)."
  (rs-internals:without-float-traps
    (impeller-ffi:paragraph-get-max-intrinsic-width paragraph)))

(defun paragraph-get-min-intrinsic-width (paragraph)
  "Get the minimum intrinsic width of a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns the minimum width required to layout the paragraph without
overflow (float)."
  (rs-internals:without-float-traps
    (impeller-ffi:paragraph-get-min-intrinsic-width paragraph)))

;;; Drawing paragraphs

(defun draw-paragraph (builder paragraph x y)
  "Draw a paragraph to a display list builder.

Arguments:
  builder   - Display list builder from with-display-list-builder
  paragraph - Paragraph from paragraph-builder-build
  x         - X coordinate of paragraph origin (float)
  y         - Y coordinate of paragraph origin (float)

Returns nil. Records the paragraph drawing operation in the builder."
  (cffi-c-ref:c-with ((point (:struct impeller-ffi:point)))
    (setf (point :x) (float x 1.0f0)
          (point :y) (float y 1.0f0))
    (impeller-ffi:display-list-builder-draw-paragraph builder paragraph (point &)))
  nil)
