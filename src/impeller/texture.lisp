;;;; flutter-render-stack/impeller/texture.lisp
;;;; Texture creation and management for image data

(in-package :flutter-render-stack)

;;; Pixel format enum converter

(rs-internals:define-case-converter (:pixel-format-keyword :pixel-format-int)
  (:rgba8888 0))

;;; Texture data release callback

(cffi:defcallback texture-data-release-callback :void ((user-data :pointer))
  "Callback invoked by Impeller when texture data is no longer needed."
  (unless (cffi:null-pointer-p user-data)
    (let ((data-ptr (cffi:foreign-slot-value user-data
                                              '(:struct impeller-ffi:mapping)
                                              '%impeller::data)))
      (log:debug :frs "texture-data-release: freeing data ~S" data-ptr)
      (unless (cffi:null-pointer-p data-ptr)
        (cffi:foreign-free data-ptr))
      (cffi:foreign-free user-data))))

;;; Texture creation and management

(defun make-texture-from-bytes (context width height pixel-bytes &optional (pixel-format :rgba8888))
  "Create a texture from raw byte data.

Arguments:
  context     - Impeller context from make-context
  width       - Texture width in pixels (integer)
  height      - Texture height in pixels (integer)
  pixel-bytes - Byte vector containing raw pixel data (vector (unsigned-byte 8))
  pixel-format - Pixel format keyword (default: :rgba8888)

Returns a texture object, or NIL if creation fails.

The pixel data should be in the format specified by pixel-format.
For :rgba8888, each pixel is 4 bytes (R, G, B, A) and the total
size should be width * height * 4 bytes.

The returned texture must be released via release-texture when no
longer needed.

Example:
  ;; Create a 100x100 red texture
  (let* ((pixels (make-array (* 100 100 4) :element-type '(unsigned-byte 8)))
         (texture (make-texture-from-bytes ctx 100 100 pixels)))
    (when texture
      (unwind-protect
           (draw-texture builder texture 0 0)
        (release-texture texture))))"
  (declare (type fixnum width height)
           (type (vector (unsigned-byte 8)) pixel-bytes))
  (let* ((data-length (length pixel-bytes))
         (expected-length (* width height 4))  ; RGBA8888 = 4 bytes per pixel
         (foreign-data (cffi:foreign-alloc :uint8 :count data-length))
         (mapping (cffi:foreign-alloc '(:struct impeller-ffi:mapping))))
    ;; Validate size for RGBA8888
    (when (and (eq pixel-format :rgba8888)
               (/= data-length expected-length))
      (cffi:foreign-free foreign-data)
      (cffi:foreign-free mapping)
      (error "Pixel data size mismatch: expected ~D bytes for ~Dx~D RGBA, got ~D"
             expected-length width height data-length))
    ;; Copy data to foreign memory
    (loop for i from 0 below data-length
          do (setf (cffi:mem-aref foreign-data :uint8 i)
                   (aref pixel-bytes i)))
    ;; Set up mapping structure
    (setf (cffi:foreign-slot-value mapping '(:struct impeller-ffi:mapping) '%impeller::data)
          foreign-data
          (cffi:foreign-slot-value mapping '(:struct impeller-ffi:mapping) '%impeller::length)
          data-length
          (cffi:foreign-slot-value mapping '(:struct impeller-ffi:mapping) '%impeller::on-release)
          (cffi:callback texture-data-release-callback))
    ;; Create texture descriptor
    (cffi-c-ref:c-with ((descriptor (:struct impeller-ffi:texture-descriptor)))
      (setf (descriptor :pixel-format) (pixel-format-keyword->pixel-format-int pixel-format)
            (descriptor :size :width) width
            (descriptor :size :height) height
            (descriptor :mip-count) 1)  ; No mipmaps for now
      ;; Create texture
      (let ((texture (impeller-ffi:texture-create-with-contents-new
                      context
                      (descriptor &)
                      mapping
                      mapping)))
        (unless (cffi:null-pointer-p texture)
          texture)))))

(defun release-texture (texture)
  "Release a texture and free its resources.

Arguments:
  texture - Texture from make-texture-from-bytes or related functions

Must be called exactly once per texture created."
  (unless (cffi:null-pointer-p texture)
    (impeller-ffi:texture-release texture)))

;;; Convenience functions for common texture operations

(defun make-solid-color-texture (context width height color)
  "Create a texture filled with a solid color.

Arguments:
  context - Impeller context from make-context
  width   - Texture width in pixels
  height  - Texture height in pixels
  color   - Color as integer (RGBA)

Returns a texture filled with the specified color."
  (declare (type fixnum width height)
           (type integer color))
  (let* ((pixel-count (* width height))
         (pixel-bytes (make-array (* pixel-count 4) :element-type '(unsigned-byte 8)))
         (r (logand (ash color -16) #xFF))
         (g (logand (ash color -8) #xFF))
         (b (logand color #xFF))
         (a (logand (ash color -24) #xFF)))
    ;; Fill with solid color
    (loop for i from 0 below pixel-count
          for base = (* i 4)
          do (setf (aref pixel-bytes base) r
                   (aref pixel-bytes (+ base 1)) g
                   (aref pixel-bytes (+ base 2)) b
                   (aref pixel-bytes (+ base 3)) a))
    (make-texture-from-bytes context width height pixel-bytes)))

(defun make-checkerboard-texture (context size square-size color1 color2)
  "Create a checkerboard pattern texture.

Arguments:
  context     - Impeller context from make-context
  size        - Texture size (width and height, must be power of 2 for square textures)
  square-size - Size of each checkerboard square
  color1      - First color as integer
  color2      - Second color as integer

Returns a checkerboard texture useful for debugging transparency."
  (declare (type fixnum size square-size)
           (type integer color1 color2))
  (let ((pixel-bytes (make-array (* size size 4) :element-type '(unsigned-byte 8)))
        (r1 (logand (ash color1 -16) #xFF))
        (g1 (logand (ash color1 -8) #xFF))
        (b1 (logand color1 #xFF))
        (a1 (logand (ash color1 -24) #xFF))
        (r2 (logand (ash color2 -16) #xFF))
        (g2 (logand (ash color2 -8) #xFF))
        (b2 (logand color2 #xFF))
        (a2 (logand (ash color2 -24) #xFF)))
    (loop for y from 0 below size
          do (loop for x from 0 below size
                   for checker-x = (floor x square-size)
                   for checker-y = (floor y square-size)
                   for use-color1 = (evenp (+ checker-x checker-y))
                   for idx = (* (+ (* y size) x) 4)
                   do (if use-color1
                          (setf (aref pixel-bytes idx) r1
                                (aref pixel-bytes (+ idx 1)) g1
                                (aref pixel-bytes (+ idx 2)) b1
                                (aref pixel-bytes (+ idx 3)) a1)
                          (setf (aref pixel-bytes idx) r2
                                (aref pixel-bytes (+ idx 1)) g2
                                (aref pixel-bytes (+ idx 2)) b2
                                (aref pixel-bytes (+ idx 3)) a2))))
    (make-texture-from-bytes context size size pixel-bytes)))

(defun texture-get-size (texture)
  "Get the dimensions of a texture.

Arguments:
  texture - Texture object

Returns a list (width height) of the texture dimensions.
Note: Impeller doesn't expose texture size queries directly,
so this returns nil for now. Applications should track sizes separately."
  (declare (ignore texture))
  ;; Impeller doesn't provide a texture size query API
  ;; Applications should track this themselves
  nil)
