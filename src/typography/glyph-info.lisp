;;;; flutter-render-stack/typography/glyph-info.lisp
;;;; Impeller glyph information for text hit testing and selection

(in-package :flutter-render-stack)

;;; Text direction enum converter

(rs-internals:define-case-converter (:text-direction-keyword :text-direction-int)
  (:rtl 0) (:ltr 1))

;;; Glyph info structure and management

(defstruct (glyph-info (:constructor %make-glyph-info))
  "Information about a single grapheme cluster (glyph) in a paragraph.
   
This structure wraps an ImpellerGlyphInfo pointer and provides
access to glyph bounds, text indices, and rendering properties.
Used for text hit testing, selection, and cursor positioning."
  (pointer (cffi:null-pointer) :type cffi:foreign-pointer))

(defun paragraph-glyph-info-at-code-unit-index (paragraph code-unit-index)
  "Get glyph information at a specific UTF-16 code unit index.

Arguments:
  paragraph       - Paragraph from paragraph-builder-build
  code-unit-index - UTF-16 code unit index in the paragraph text (integer)

Returns a glyph-info object containing information about the grapheme
cluster at that position. Returns NIL if the index is out of bounds.

The returned object must be released via release-glyph-info.

Example:
  (let ((glyph (paragraph-glyph-info-at-code-unit-index paragraph 10)))
    (when glyph
      (unwind-protect
           (format t \"Glyph bounds: ~A\" (glyph-info-grapheme-cluster-bounds glyph))
        (release-glyph-info glyph))))"
  (declare (type fixnum code-unit-index))
  (let ((glyph-ptr (impeller-ffi:paragraph-create-glyph-info-at-code-unit-index-new
                    paragraph code-unit-index)))
    (unless (cffi:null-pointer-p glyph-ptr)
      (%make-glyph-info :pointer glyph-ptr))))

(defun paragraph-glyph-info-at-coordinate (paragraph x y)
  "Get glyph information at a specific paragraph coordinate (hit testing).

Arguments:
  paragraph - Paragraph from paragraph-builder-build
  x         - X coordinate in paragraph space (float)
  y         - Y coordinate in paragraph space (float)

Returns a glyph-info object for the glyph at the specified coordinates,
or NIL if the coordinates are outside the paragraph bounds.

This is the primary function for implementing text selection and
clickable text regions.

The returned object must be released via release-glyph-info.

Example:
  ;; Get glyph info at mouse click position
  (let ((glyph (paragraph-glyph-info-at-coordinate paragraph mouse-x mouse-y)))
    (when glyph
      (unwind-protect
           (format t \"Clicked on glyph at indices ~D-~D\"
                   (glyph-info-grapheme-cluster-code-unit-range-begin glyph)
                   (glyph-info-grapheme-cluster-code-unit-range-end glyph))
        (release-glyph-info glyph))))"
  (declare (type float x y))
  (let ((glyph-ptr (impeller-ffi:paragraph-create-glyph-info-at-paragraph-coordinates-new
                    paragraph (float x 1.0d0) (float y 1.0d0))))
    (unless (cffi:null-pointer-p glyph-ptr)
      (%make-glyph-info :pointer glyph-ptr))))

(defun release-glyph-info (glyph-info)
  "Release an Impeller glyph info object.

Arguments:
  glyph-info - Glyph info object from paragraph-glyph-info-at-* functions

Frees all resources associated with the glyph info. Must be called
exactly once per glyph-info object."
  (declare (type glyph-info glyph-info))
  (unless (cffi:null-pointer-p (glyph-info-pointer glyph-info))
    (impeller-ffi:glyph-info-release (glyph-info-pointer glyph-info))
    (setf (glyph-info-pointer glyph-info) (cffi:null-pointer))))

;;; Glyph info accessors

(defun glyph-info-grapheme-cluster-code-unit-range-begin (glyph-info)
  "Get the starting UTF-16 code unit index of the grapheme cluster.

Arguments:
  glyph-info - Glyph info object

Returns the starting index (integer) in UTF-16 code units of the
text range covered by this glyph."
  (declare (type glyph-info glyph-info))
  (impeller-ffi:glyph-info-get-grapheme-cluster-code-unit-range-begin
   (glyph-info-pointer glyph-info)))

(defun glyph-info-grapheme-cluster-code-unit-range-end (glyph-info)
  "Get the ending UTF-16 code unit index of the grapheme cluster.

Arguments:
  glyph-info - Glyph info object

Returns the ending index (integer) in UTF-16 code units of the
text range covered by this glyph."
  (declare (type glyph-info glyph-info))
  (impeller-ffi:glyph-info-get-grapheme-cluster-code-unit-range-end
   (glyph-info-pointer glyph-info)))

(defun glyph-info-grapheme-cluster-bounds (glyph-info)
  "Get the bounding rectangle of the grapheme cluster in paragraph coordinates.

Arguments:
  glyph-info - Glyph info object

Returns a list (x y width height) representing the glyph bounds in
logical pixels, relative to the paragraph origin.

Example:
  (destructuring-bind (x y w h) (glyph-info-grapheme-cluster-bounds glyph)
    (format t \"Glyph at (~F,~F) size ~Fx~F\" x y w h))"
  (declare (type glyph-info glyph-info))
  (cffi-c-ref:c-with ((rect (:struct impeller-ffi:rect)))
    (impeller-ffi:glyph-info-get-grapheme-cluster-bounds
     (glyph-info-pointer glyph-info) (rect &))
    (list (rect :x) (rect :y) (rect :width) (rect :height))))

(defun glyph-info-is-ellipsis (glyph-info)
  "Return T if this glyph represents an ellipsis (truncation indicator).

Arguments:
  glyph-info - Glyph info object

Returns T if the glyph is an ellipsis character indicating text was
truncated due to max-lines constraints, NIL otherwise."
  (declare (type glyph-info glyph-info))
  (impeller-ffi:glyph-info-is-ellipsis (glyph-info-pointer glyph-info)))

(defun glyph-info-text-direction (glyph-info)
  "Get the text direction for this glyph.

Arguments:
  glyph-info - Glyph info object

Returns a keyword: :rtl for right-to-left text, :ltr for left-to-right.

This is useful for determining cursor positioning and selection direction."
  (declare (type glyph-info glyph-info))
  (text-direction-int->text-direction-keyword
   (impeller-ffi:glyph-info-get-text-direction (glyph-info-pointer glyph-info))))
