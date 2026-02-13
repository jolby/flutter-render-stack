;;;; flutter-render-stack/typography/line-metrics.lisp
;;;; Impeller line metrics for detailed text layout information

(in-package :flutter-render-stack)

;;; Line metrics structure and management

(defstruct (line-metrics (:constructor %make-line-metrics))
  "Detailed metrics for a single line of text in a paragraph.
   
This structure wraps an ImpellerLineMetrics pointer and provides
access to per-line typographic metrics including ascent, descent,
baseline position, width, height, and text indices."
  (pointer (cffi:null-pointer) :type cffi:foreign-pointer)
  (line-count 0 :type fixnum))

(defun paragraph-get-line-metrics (paragraph)
  "Get detailed line metrics for a laid-out paragraph.

Arguments:
  paragraph - Paragraph from paragraph-builder-build

Returns a line-metrics object that provides access to per-line metrics.
The returned object must be released via release-line-metrics when no
longer needed.

Example:
  (let ((metrics (paragraph-get-line-metrics paragraph)))
    (unwind-protect
         (loop for i from 0 below (line-metrics-count metrics)
               do (format t \"Line ~D: width=~F, height=~F\"
                          i
                          (line-metrics-width metrics i)
                          (line-metrics-height metrics i)))
      (release-line-metrics metrics)))"
  (let ((metrics-ptr (impeller-ffi:paragraph-get-line-metrics paragraph)))
    (when (cffi:null-pointer-p metrics-ptr)
      (error 'impeller-creation-error :resource-type "line metrics"))
    (%make-line-metrics 
     :pointer metrics-ptr
     :line-count (paragraph-get-line-count paragraph))))

(defun release-line-metrics (line-metrics)
  "Release an Impeller line metrics object.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics

Frees all resources associated with the line metrics. Must be called
exactly once per line-metrics object created via paragraph-get-line-metrics."
  (declare (type line-metrics line-metrics))
  (unless (cffi:null-pointer-p (line-metrics-pointer line-metrics))
    (impeller-ffi:line-metrics-release (line-metrics-pointer line-metrics))
    (setf (line-metrics-pointer line-metrics) (cffi:null-pointer))
    (setf (line-metrics-line-count line-metrics) 0)))

(defun line-metrics-count (line-metrics)
  "Get the number of lines in the line metrics.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics

Returns the total number of lines as a fixnum."
  (declare (type line-metrics line-metrics))
  (line-metrics-line-count line-metrics))

;;; Individual line metric accessors

(declaim (inline %check-line-index))

(defun %check-line-index (line-metrics line-index)
  "Check if LINE-INDEX is within bounds for LINE-METRICS.
Signals an error if out of bounds."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (when (or (< line-index 0)
            (>= line-index (line-metrics-line-count line-metrics)))
    (error "Line index ~D out of bounds (0-~D)"
           line-index (1- (line-metrics-line-count line-metrics)))))

(defun line-metrics-unscaled-ascent (line-metrics line-index)
  "Get the unscaled (font-based) ascent for a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the unscaled ascent in logical pixels (double-float).
This is the font's native ascent before any scaling is applied."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (rs-internals:without-float-traps
    (impeller-ffi:line-metrics-get-unscaled-ascent 
     (line-metrics-pointer line-metrics) line-index)))

(defun line-metrics-ascent (line-metrics line-index)
  "Get the final ascent for a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the ascent in logical pixels (double-float).
This is the distance from the baseline to the top of the line."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (rs-internals:without-float-traps
    (impeller-ffi:line-metrics-get-ascent 
     (line-metrics-pointer line-metrics) line-index)))

(defun line-metrics-descent (line-metrics line-index)
  "Get the descent for a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the descent in logical pixels (double-float).
This is the distance from the baseline to the bottom of the line."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (rs-internals:without-float-traps
    (impeller-ffi:line-metrics-get-descent 
     (line-metrics-pointer line-metrics) line-index)))

(defun line-metrics-baseline (line-metrics line-index)
  "Get the baseline Y coordinate for a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the Y coordinate of the baseline in logical pixels (double-float),
relative to the top of the paragraph."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (rs-internals:without-float-traps
    (impeller-ffi:line-metrics-get-baseline 
     (line-metrics-pointer line-metrics) line-index)))

(defun line-metrics-width (line-metrics line-index)
  "Get the width of a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the line width in logical pixels (double-float)."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (rs-internals:without-float-traps
    (impeller-ffi:line-metrics-get-width 
     (line-metrics-pointer line-metrics) line-index)))

(defun line-metrics-height (line-metrics line-index)
  "Get the height of a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the line height in logical pixels (double-float)."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (rs-internals:without-float-traps
    (impeller-ffi:line-metrics-get-height 
     (line-metrics-pointer line-metrics) line-index)))

(defun line-metrics-left (line-metrics line-index)
  "Get the left edge X coordinate for a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the X coordinate of the left edge in logical pixels (double-float),
relative to the left of the paragraph."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (rs-internals:without-float-traps
    (impeller-ffi:line-metrics-get-left 
     (line-metrics-pointer line-metrics) line-index)))

(defun line-metrics-hardbreak-p (line-metrics line-index)
  "Return T if the line ends with a hard line break.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns T if the line was terminated by an explicit newline character,
NIL if the line wrapped due to width constraints."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (impeller-ffi:line-metrics-is-hardbreak 
   (line-metrics-pointer line-metrics) line-index))

(defun line-metrics-code-unit-start-index (line-metrics line-index)
  "Get the UTF-16 code unit start index for a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the starting UTF-16 code unit index (integer) of the line
in the original text."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (impeller-ffi:line-metrics-get-code-unit-start-index 
   (line-metrics-pointer line-metrics) line-index))

(defun line-metrics-code-unit-end-index (line-metrics line-index)
  "Get the UTF-16 code unit end index for a specific line.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the ending UTF-16 code unit index (integer) of the line
in the original text. This includes trailing whitespace."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (impeller-ffi:line-metrics-get-code-unit-end-index 
   (line-metrics-pointer line-metrics) line-index))

(defun line-metrics-code-unit-end-index-excluding-whitespace (line-metrics line-index)
  "Get the UTF-16 code unit end index excluding trailing whitespace.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the ending UTF-16 code unit index (integer) of the line,
excluding any trailing whitespace characters."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (impeller-ffi:line-metrics-get-code-unit-end-index-excluding-whitespace 
   (line-metrics-pointer line-metrics) line-index))

(defun line-metrics-code-unit-end-index-including-newline (line-metrics line-index)
  "Get the UTF-16 code unit end index including the newline character.

Arguments:
  line-metrics - Line metrics object from paragraph-get-line-metrics
  line-index   - Zero-based line index (fixnum)

Returns the ending UTF-16 code unit index (integer) of the line,
including the newline character if present."
  (declare (type line-metrics line-metrics)
           (type fixnum line-index))
  (%check-line-index line-metrics line-index)
  (impeller-ffi:line-metrics-get-code-unit-end-index-including-newline 
   (line-metrics-pointer line-metrics) line-index))
