;;;; flutter-render-stack/typography/word-boundaries.lisp
;;;; Word boundary detection for text selection and navigation

(in-package :flutter-render-stack)

;;; Range structure for word boundaries

(defstruct (text-range (:constructor %make-text-range))
  "A range of UTF-16 code units representing a word or text segment.
   
START and END are indices into the UTF-16 code unit array of the
text. START is inclusive, END is exclusive.

Used primarily with word-boundary to identify the extent of a word
at a given text position."
  (start 0 :type integer)
  (end 0 :type integer))

(defun word-boundary (paragraph code-unit-index)
  "Get the word boundary containing the specified code unit index.

Arguments:
  paragraph       - Paragraph from paragraph-builder-build
  code-unit-index - UTF-16 code unit position in the paragraph text (integer)

Returns a text-range object containing the start and end indices of
the word at the specified position. Uses Unicode Standard Annex #29
for word boundary detection.

Example:
  ;; Double-click to select word
  (let ((range (word-boundary paragraph click-index)))
    (format t \"Selected word spans indices ~D to ~D\"
            (text-range-start range)
            (text-range-end range)))

  ;; Navigate to next word
  (let ((range (word-boundary paragraph cursor-index)))
    (setf cursor-index (text-range-end range)))

Note: Word boundaries are determined by Unicode word break rules,
which handle punctuation, whitespace, and various scripts correctly."
  (declare (type fixnum code-unit-index))
  (cffi-c-ref:c-with ((range (:struct impeller-ffi:range)))
    (impeller-ffi:paragraph-get-word-boundary 
     paragraph code-unit-index (range &))
    (%make-text-range 
     :start (range :start)
     :end (range :end))))

(defun word-at-index (paragraph code-unit-index)
  "Convenience function to get the text of the word at a position.

Arguments:
  paragraph       - Paragraph from paragraph-builder-build
  code-unit-index - UTF-16 code unit position in the paragraph text (integer)

Returns the text string of the word at the specified position.
Note: This function would require access to the original text string,
which is not stored in the paragraph. For a full implementation,
you would need to track the original text alongside the paragraph."
  (declare (ignore paragraph code-unit-index))
  ;; Placeholder - full implementation would require storing original text
  (error "word-at-index requires original text storage. Use word-boundary instead."))

(defun select-word-at (paragraph code-unit-index original-text)
  "Select the word at the specified position from original text.

Arguments:
  paragraph       - Paragraph from paragraph-builder-build
  code-unit-index - UTF-16 code unit position (integer)
  original-text   - The original string used to build the paragraph

Returns the substring corresponding to the word at that position.

Example:
  (let ((text \"Hello world\"))
    (with-paragraph-builder (builder typo-ctx)
      ...build paragraph from text...
      (let ((paragraph (paragraph-builder-build builder 500.0)))
        (select-word-at paragraph 7 text))))"
  (declare (type fixnum code-unit-index)
           (type string original-text))
  (let ((range (word-boundary paragraph code-unit-index)))
    (subseq original-text 
            (text-range-start range) 
            (text-range-end range))))
