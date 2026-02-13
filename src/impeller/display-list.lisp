;;;; flutter-render-stack/impeller/display-list.lisp
;;;; Impeller display list building, drawing operations, surfaces, and gradients

(in-package :flutter-render-stack)

;;; Constants for color source creation

(defconstant +color-space-srgb+ 0)

;;; Enum converters

(rs-internals:define-case-converter (:tile-mode-keyword :tile-mode-int)
  (:clamp 0) (:repeat 1) (:mirror 2) (:decal 3))

(rs-internals:define-case-converter (:clip-op-keyword :clip-op-int)
  (:intersect 0) (:difference 1))

;;; Display list builder lifecycle

(defmacro with-display-list-builder ((builder-var) &body body)
  "Allocate and manage a display list builder.

Syntax: (with-display-list-builder (builder) ...)

The builder variable is bound to a display list builder pointer
for use with draw-paint, draw-rect, etc. The builder is automatically
released upon exit (success or error).

Returns the result of body."
  `(let ((,builder-var (impeller-ffi:display-list-builder-new
                       (cffi:null-pointer))))
     (when (cffi:null-pointer-p ,builder-var)
       (error 'impeller-creation-error :resource-type "display list builder"))
     (unwind-protect
          (progn ,@body)
       (impeller-ffi:display-list-builder-release ,builder-var))))

;;; Drawing operations

(defun draw-paint (builder paint)
  "Draw paint (fill/clear) to a display list builder.

Arguments:
  builder - Display list builder from with-display-list-builder
  paint   - Paint object from make-paint (with color set)

Returns nil."
  (impeller-ffi:display-list-builder-draw-paint builder paint)
  nil)

(defun draw-rect (builder x y width height paint)
  "Draw a rectangle to a display list builder.

Arguments:
  builder - Display list builder from with-display-list-builder
  x       - Left edge coordinate (float)
  y       - Top edge coordinate (float)
  width   - Rectangle width (float)
  height  - Rectangle height (float)
  paint   - Paint object from make-paint

Returns nil."
  (cffi-c-ref:c-with ((rect (:struct impeller-ffi:rect)))
    (setf (rect :x) (float x 1.0f0)
          (rect :y) (float y 1.0f0)
          (rect :width) (float width 1.0f0)
          (rect :height) (float height 1.0f0))
    (impeller-ffi:display-list-builder-draw-rect builder (rect &) paint))
  nil)

(defun draw-oval (builder x y width height paint)
  "Draw an oval (ellipse) to a display list builder.

Arguments:
  builder - Display list builder from with-display-list-builder
  x       - Left edge of bounding rectangle (float)
  y       - Top edge of bounding rectangle (float)
  width   - Bounding rectangle width (float)
  height  - Bounding rectangle height (float)
  paint   - Paint object from make-paint

Returns nil."
  (cffi-c-ref:c-with ((rect (:struct impeller-ffi:rect)))
    (setf (rect :x) (float x 1.0f0)
          (rect :y) (float y 1.0f0)
          (rect :width) (float width 1.0f0)
          (rect :height) (float height 1.0f0))
    (impeller-ffi:display-list-builder-draw-oval builder (rect &) paint))
  nil)

(defun draw-line (builder from-x from-y to-x to-y paint)
  "Draw a line to a display list builder.

Arguments:
  builder - Display list builder from with-display-list-builder
  from-x  - Start X coordinate (float)
  from-y  - Start Y coordinate (float)
  to-x    - End X coordinate (float)
  to-y    - End Y coordinate (float)
  paint   - Paint object from make-paint (use :stroke draw style)

Returns nil."
  (cffi-c-ref:c-with ((from-pt (:struct impeller-ffi:point))
                       (to-pt (:struct impeller-ffi:point)))
    (setf (from-pt :x) (float from-x 1.0f0)
          (from-pt :y) (float from-y 1.0f0)
          (to-pt :x) (float to-x 1.0f0)
          (to-pt :y) (float to-y 1.0f0))
    (impeller-ffi:display-list-builder-draw-line builder (from-pt &) (to-pt &) paint))
  nil)

(defun draw-path (builder path paint)
  "Draw a path to a display list builder.

Arguments:
  builder - Display list builder from with-display-list-builder
  path    - Path object from build-path
  paint   - Paint object from make-paint

Returns nil."
  (impeller-ffi:display-list-builder-draw-path builder path paint)
  nil)

(defun draw-rounded-rect (builder x y width height paint &key (radius 0.0))
  "Draw a rounded rectangle to a display list builder.

Arguments:
  builder - Display list builder from with-display-list-builder
  x       - Left edge coordinate (float)
  y       - Top edge coordinate (float)
  width   - Rectangle width (float)
  height  - Rectangle height (float)
  paint   - Paint object from make-paint
  radius  - Corner radius. Can be:
            - A single number for uniform radius on all corners
            - A plist like (:top-left 8 :bottom-right 4) for per-corner
            - Per-corner values can be (rx . ry) for elliptical corners

Returns nil."
  (cffi:with-foreign-objects ((rect '(:struct impeller-ffi:rect))
                              (radii '(:struct impeller-ffi:rounding-radii)))
    (setf (cffi:foreign-slot-value rect '(:struct impeller-ffi:rect) '%impeller::x)
          (float x 1.0f0))
    (setf (cffi:foreign-slot-value rect '(:struct impeller-ffi:rect) '%impeller::y)
          (float y 1.0f0))
    (setf (cffi:foreign-slot-value rect '(:struct impeller-ffi:rect) '%impeller::width)
          (float width 1.0f0))
    (setf (cffi:foreign-slot-value rect '(:struct impeller-ffi:rect) '%impeller::height)
          (float height 1.0f0))
    (%make-rounding-radii radii radius)
    (impeller-ffi:display-list-builder-draw-rounded-rect builder rect radii paint))
  nil)

(defun draw-shadow (builder path r g b a elevation
                    &key (occluder-transparent nil) (device-pixel-ratio 1.0))
  "Draw a Material Design elevation shadow for a path.

Arguments:
  builder              - Display list builder from with-display-list-builder
  path                 - Path object defining the shadow shape (from build-path)
  r, g, b, a           - Shadow color components (0.0-1.0)
  elevation            - Material Design elevation in dp (e.g., 2, 4, 8, 16)
  occluder-transparent - If T, shadow shows through transparent occluder
  device-pixel-ratio   - HiDPI scale factor (default 1.0)

Returns nil."
  (cffi-c-ref:c-with ((color (:struct impeller-ffi:color)))
    (setf (color :red) (float r 1.0f0)
          (color :green) (float g 1.0f0)
          (color :blue) (float b 1.0f0)
          (color :alpha) (float a 1.0f0))
    (rs-internals:without-float-traps
      (impeller-ffi:display-list-builder-draw-shadow
       builder
       path
       (color &)
       (float elevation 1.0f0)
       occluder-transparent
       (float device-pixel-ratio 1.0f0))))
  nil)

;;; Display list builder transform & state

(defun display-list-builder-set-transform (builder scale-x scale-y translate-x translate-y)
  "Set the transform matrix for a display list builder.

Arguments:
  builder                    - Display list builder
  scale-x, scale-y           - Scaling factors
  translate-x, translate-y   - Translation offsets

Sets a 4x4 column-major matrix on the builder."
  (cffi:with-foreign-object (matrix '(:struct impeller-ffi:matrix))
    (let ((m-ptr (cffi:foreign-slot-pointer matrix '(:struct impeller-ffi:matrix) '%impeller::m)))
      ;; Initialize to zeros
      (dotimes (i 16)
        (setf (cffi:mem-aref m-ptr :float i) 0.0f0))
      ;; Set identity with scale and translation (column-major)
      (setf (cffi:mem-aref m-ptr :float 0) (float scale-x 1.0f0)
            (cffi:mem-aref m-ptr :float 5) (float scale-y 1.0f0)
            (cffi:mem-aref m-ptr :float 10) 1.0f0
            (cffi:mem-aref m-ptr :float 15) 1.0f0
            (cffi:mem-aref m-ptr :float 12) (float translate-x 1.0f0)
            (cffi:mem-aref m-ptr :float 13) (float translate-y 1.0f0))
      (impeller-ffi:display-list-builder-set-transform builder matrix))))

(defun display-list-builder-save (builder)
  "Save the current state (transform, clip) of the display list builder.

Use display-list-builder-restore to restore the saved state."
  (impeller-ffi:display-list-builder-save builder)
  nil)

(defun display-list-builder-restore (builder)
  "Restore the previously saved state of the display list builder.

Must be paired with a prior display-list-builder-save call."
  (impeller-ffi:display-list-builder-restore builder)
  nil)

(defun display-list-builder-get-save-count (builder)
  "Get the current save count of the display list builder.

Returns the number of saved states on the stack (integer)."
  (impeller-ffi:display-list-builder-get-save-count builder))

(defun display-list-builder-translate (builder x y)
  "Apply a translation transform to the display list builder.

Affects all subsequent drawing operations until restored."
  (impeller-ffi:display-list-builder-translate builder
                                              (float x 1.0f0)
                                              (float y 1.0f0))
  nil)

(defun display-list-builder-scale (builder x y)
  "Apply a scale transform to the display list builder.

Affects all subsequent drawing operations until restored."
  (impeller-ffi:display-list-builder-scale builder
                                          (float x 1.0f0)
                                          (float y 1.0f0))
  nil)

(defun display-list-builder-clip-rect (builder x y width height
                                       &key (operation :intersect))
  "Apply a rectangular clip to the display list builder.

Arguments:
  builder   - Display list builder
  x, y      - Top-left corner of clip rectangle (float)
  width     - Width of clip rectangle (float)
  height    - Height of clip rectangle (float)
  operation - Clip operation, :intersect (default) or :difference

Returns nil."
  (cffi-c-ref:c-with ((rect (:struct impeller-ffi:rect)))
    (setf (rect :x) (float x 1.0f0)
          (rect :y) (float y 1.0f0)
          (rect :width) (float width 1.0f0)
          (rect :height) (float height 1.0f0))
    (impeller-ffi:display-list-builder-clip-rect
     builder (rect &) (clip-op-keyword->clip-op-int operation)))
  nil)

;;; Display list composition (retained rendering)

(defun display-list-builder-draw-display-list (builder display-list opacity)
  "Draw a cached display list into the current builder.

Arguments:
  builder      - Display list builder (target)
  display-list - Previously created display list to draw
  opacity      - Opacity multiplier (0.0 to 1.0)

Returns nil. This is the key operation for retained/cached rendering."
  (impeller-ffi:display-list-builder-draw-display-list builder
                                                       display-list
                                                       (float opacity 1.0f0))
  nil)

;;; Display list lifecycle

(defun create-display-list (builder)
  "Create a display list from the current builder state.

Returns a display list pointer. The caller is responsible for releasing
it with release-display-list. The display list is independent of the builder."
  (let ((dl (impeller-ffi:display-list-builder-create-display-list-new builder)))
    (when (cffi:null-pointer-p dl)
      (error 'impeller-creation-error :resource-type "display list"))
    dl))

(defun release-display-list (display-list)
  "Release a display list. Must be called once per display list created."
  (impeller-ffi:display-list-release display-list)
  nil)

(defun retain-display-list (display-list)
  "Increment the reference count of a display list.

Use when sharing a display list across multiple owners."
  (impeller-ffi:display-list-retain display-list)
  nil)

(defun execute-display-list (surface builder)
  "Build and execute a display list on a surface.

Arguments:
  surface - Surface from make-wrapped-fbo-surface
  builder - Display list builder from with-display-list-builder

Returns nil. Executes all recorded drawing operations on the surface."
  (let ((dl (impeller-ffi:display-list-builder-create-display-list-new builder)))
    (when (cffi:null-pointer-p dl)
      (error 'impeller-creation-error :resource-type "display list"))
    (unwind-protect
         (impeller-ffi:surface-draw-display-list surface dl)
      (impeller-ffi:display-list-release dl)))
  nil)

(defun surface-draw-display-list (surface display-list)
  "Draw a pre-built display list directly to a surface.

Arguments:
  surface      - Surface from make-wrapped-fbo-surface
  display-list - A pre-built ImpellerDisplayList (e.g., from
                 scoped-frame-build-display-list or create-display-list)

Unlike execute-display-list (which takes a builder and builds first),
this function draws an already-built display list. Use this for the
Flow rasterization workflow where FlowScopedFrameBuildDisplayListNew
returns a pre-built display list."
  (impeller-ffi:surface-draw-display-list surface display-list))

;;; Surface management

(defun make-wrapped-fbo-surface (context fbo-id width height)
  "Wrap an OpenGL framebuffer object as an Impeller surface.

Arguments:
  context  - Impeller context from make-context
  fbo-id   - OpenGL framebuffer object ID
  width    - Framebuffer width in pixels
  height   - Framebuffer height in pixels

Returns a pointer to an ImpellerSurface. Raises impeller-creation-error
if surface creation fails. Must be released via release-surface."
  (cffi-c-ref:c-with ((size (:struct impeller-ffi:i-size)))
    (setf (size :width) width
          (size :height) height)
    (let ((surface (impeller-ffi:surface-create-wrapped-fbo-new
                    context fbo-id 0 (size &))))
      (when (cffi:null-pointer-p surface)
        (error 'impeller-creation-error :resource-type "wrapped FBO surface"))
      surface)))

(defun release-surface (surface)
  "Release an Impeller surface. Must be called once per surface created."
  (impeller-ffi:surface-release surface))

;;; Color source (gradient) management

(defun make-linear-gradient-color-source (x1 y1 x2 y2 colors stops
                                          &key (tile-mode :clamp))
  "Create a linear gradient color source.

Arguments:
  x1, y1    - Start point of gradient
  x2, y2    - End point of gradient
  colors    - List of (r g b a) color tuples (each 0.0-1.0)
  stops     - List of stop positions (0.0-1.0), same length as colors
  tile-mode - :clamp, :repeat, :mirror, or :decal (default :clamp)

Returns a color source pointer. Must be released with release-color-source.

Example:
  (make-linear-gradient-color-source
   0 0 100 0
   '((1.0 0.0 0.0 1.0) (0.0 0.0 1.0 1.0))  ; red -> blue
   '(0.0 1.0))"
  (let ((stop-count (length colors))
        (tile-enum (tile-mode-keyword->tile-mode-int tile-mode)))
    (cffi:with-foreign-objects ((start-point '(:struct impeller-ffi:point))
                                (end-point '(:struct impeller-ffi:point))
                                (colors-array '(:struct impeller-ffi:color) stop-count)
                                (stops-array :float stop-count))
      ;; Set start point
      (setf (cffi:foreign-slot-value start-point '(:struct impeller-ffi:point) '%impeller::x)
            (float x1 1.0f0))
      (setf (cffi:foreign-slot-value start-point '(:struct impeller-ffi:point) '%impeller::y)
            (float y1 1.0f0))
      ;; Set end point
      (setf (cffi:foreign-slot-value end-point '(:struct impeller-ffi:point) '%impeller::x)
            (float x2 1.0f0))
      (setf (cffi:foreign-slot-value end-point '(:struct impeller-ffi:point) '%impeller::y)
            (float y2 1.0f0))
      ;; Fill colors and stops arrays
      (loop for i from 0
            for (r g b a) in colors
            for stop in stops
            for color-ptr = (cffi:mem-aptr colors-array '(:struct impeller-ffi:color) i)
            do (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::red)
                     (float r 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::green)
                     (float g 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::blue)
                     (float b 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::alpha)
                     (float a 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::color-space)
                     +color-space-srgb+)
               (setf (cffi:mem-aref stops-array :float i) (float stop 1.0f0)))
      ;; Create the color source
      (let ((cs (impeller-ffi:color-source-create-linear-gradient-new
                 start-point end-point
                 stop-count colors-array stops-array
                 tile-enum
                 (cffi:null-pointer))))
        (when (cffi:null-pointer-p cs)
          (error 'impeller-creation-error :resource-type "linear gradient color source"))
        cs))))

(defun make-radial-gradient-color-source (cx cy radius colors stops
                                          &key (tile-mode :clamp))
  "Create a radial gradient color source.

Arguments:
  cx, cy    - Center point of gradient
  radius    - Radius of gradient
  colors    - List of (r g b a) color tuples (each 0.0-1.0)
  stops     - List of stop positions (0.0-1.0), same length as colors
  tile-mode - :clamp, :repeat, :mirror, or :decal (default :clamp)

Returns a color source pointer. Must be released with release-color-source."
  (let ((stop-count (length colors))
        (tile-enum (tile-mode-keyword->tile-mode-int tile-mode)))
    (cffi:with-foreign-objects ((center-point '(:struct impeller-ffi:point))
                                (colors-array '(:struct impeller-ffi:color) stop-count)
                                (stops-array :float stop-count))
      ;; Set center point
      (setf (cffi:foreign-slot-value center-point '(:struct impeller-ffi:point) '%impeller::x)
            (float cx 1.0f0))
      (setf (cffi:foreign-slot-value center-point '(:struct impeller-ffi:point) '%impeller::y)
            (float cy 1.0f0))
      ;; Fill colors and stops arrays
      (loop for i from 0
            for (r g b a) in colors
            for stop in stops
            for color-ptr = (cffi:mem-aptr colors-array '(:struct impeller-ffi:color) i)
            do (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::red)
                     (float r 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::green)
                     (float g 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::blue)
                     (float b 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::alpha)
                     (float a 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::color-space)
                     +color-space-srgb+)
               (setf (cffi:mem-aref stops-array :float i) (float stop 1.0f0)))
      ;; Create the color source
      (let ((cs (impeller-ffi:color-source-create-radial-gradient-new
                 center-point (float radius 1.0f0)
                 stop-count colors-array stops-array
                 tile-enum
                 (cffi:null-pointer))))
         (when (cffi:null-pointer-p cs)
           (error 'impeller-creation-error :resource-type "radial gradient color source"))
         cs))))

(defun make-sweep-gradient-color-source (cx cy start-angle end-angle colors stops
                                         &key (tile-mode :clamp))
  "Create a sweep (angular) gradient color source.

Arguments:
  cx, cy       - Center point of gradient
  start-angle  - Starting angle in degrees (0 = right, 90 = down)
  end-angle    - Ending angle in degrees
  colors       - List of (r g b a) color tuples (each 0.0-1.0)
  stops        - List of stop positions (0.0-1.0), same length as colors
  tile-mode    - :clamp, :repeat, :mirror, or :decal (default :clamp)

The sweep gradient radiates outward from the center point, with colors
rotating around the center like a radar sweep or color wheel.

Returns a color source pointer. Must be released with release-color-source."
  (let ((stop-count (length colors))
        (tile-enum (tile-mode-keyword->tile-mode-int tile-mode)))
    (cffi:with-foreign-objects ((center-point '(:struct impeller-ffi:point))
                                (colors-array '(:struct impeller-ffi:color) stop-count)
                                (stops-array :float stop-count))
      ;; Set center point
      (setf (cffi:foreign-slot-value center-point '(:struct impeller-ffi:point) '%impeller::x)
            (float cx 1.0f0))
      (setf (cffi:foreign-slot-value center-point '(:struct impeller-ffi:point) '%impeller::y)
            (float cy 1.0f0))
      ;; Fill colors and stops arrays
      (loop for i from 0
            for (r g b a) in colors
            for stop in stops
            for color-ptr = (cffi:mem-aptr colors-array '(:struct impeller-ffi:color) i)
            do (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::red)
                     (float r 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::green)
                     (float g 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::blue)
                     (float b 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::alpha)
                     (float a 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::color-space)
                     +color-space-srgb+)
               (setf (cffi:mem-aref stops-array :float i) (float stop 1.0f0)))
      ;; Create the color source
      (let ((cs (impeller-ffi:color-source-create-sweep-gradient-new
                 center-point
                 (float start-angle 1.0f0)
                 (float end-angle 1.0f0)
                 stop-count colors-array stops-array
                 tile-enum
                 (cffi:null-pointer))))
        (when (cffi:null-pointer-p cs)
          (error 'impeller-creation-error :resource-type "sweep gradient color source"))
        cs))))

(defun make-conical-gradient-color-source (start-cx start-cy start-radius
                                           end-cx end-cy end-radius
                                           colors stops
                                           &key (tile-mode :clamp))
  "Create a conical (two-point) gradient color source.

Arguments:
  start-cx, start-cy  - Starting center point
  start-radius        - Starting radius
  end-cx, end-cy      - Ending center point
  end-radius          - Ending radius
  colors              - List of (r g b a) color tuples (each 0.0-1.0)
  stops               - List of stop positions (0.0-1.0), same length as colors
  tile-mode           - :clamp, :repeat, :mirror, or :decal (default :clamp)

The conical gradient interpolates between two circles, creating effects
like spheres, cones, or 3D highlights. Also known as a 2-point radial
gradient.

Returns a color source pointer. Must be released with release-color-source."
  (let ((stop-count (length colors))
        (tile-enum (tile-mode-keyword->tile-mode-int tile-mode)))
    (cffi:with-foreign-objects ((start-point '(:struct impeller-ffi:point))
                                (end-point '(:struct impeller-ffi:point))
                                (colors-array '(:struct impeller-ffi:color) stop-count)
                                (stops-array :float stop-count))
      ;; Set start point
      (setf (cffi:foreign-slot-value start-point '(:struct impeller-ffi:point) '%impeller::x)
            (float start-cx 1.0f0))
      (setf (cffi:foreign-slot-value start-point '(:struct impeller-ffi:point) '%impeller::y)
            (float start-cy 1.0f0))
      ;; Set end point
      (setf (cffi:foreign-slot-value end-point '(:struct impeller-ffi:point) '%impeller::x)
            (float end-cx 1.0f0))
      (setf (cffi:foreign-slot-value end-point '(:struct impeller-ffi:point) '%impeller::y)
            (float end-cy 1.0f0))
      ;; Fill colors and stops arrays
      (loop for i from 0
            for (r g b a) in colors
            for stop in stops
            for color-ptr = (cffi:mem-aptr colors-array '(:struct impeller-ffi:color) i)
            do (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::red)
                     (float r 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::green)
                     (float g 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::blue)
                     (float b 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::alpha)
                     (float a 1.0f0))
               (setf (cffi:foreign-slot-value color-ptr '(:struct impeller-ffi:color) '%impeller::color-space)
                     +color-space-srgb+)
               (setf (cffi:mem-aref stops-array :float i) (float stop 1.0f0)))
      ;; Create the color source
      (let ((cs (impeller-ffi:color-source-create-conical-gradient-new
                 start-point (float start-radius 1.0f0)
                 end-point (float end-radius 1.0f0)
                 stop-count colors-array stops-array
                 tile-enum
                 (cffi:null-pointer))))
        (when (cffi:null-pointer-p cs)
          (error 'impeller-creation-error :resource-type "conical gradient color source"))
        cs))))

(defun release-color-source (color-source)
  "Release an Impeller color source."
  (impeller-ffi:color-source-release color-source)
  nil)

(defun make-image-color-source (texture &key (horizontal-tile-mode :clamp)
                                             (vertical-tile-mode :clamp)
                                             (sampling :linear))
  "Create a color source from a texture/image.

Arguments:
  texture              - Texture object from make-texture-from-bytes
  horizontal-tile-mode - How to tile horizontally: :clamp, :repeat, :mirror, :decal
  vertical-tile-mode   - How to tile vertically: :clamp, :repeat, :mirror, :decal
  sampling             - Texture sampling: :nearest-neighbor or :linear

Returns a color source that can be used with paint-set-color-source to
draw textured shapes.

Example:
  ;; Create a textured rectangle
  (let* ((texture (make-texture-from-bytes ctx 100 100 pixel-data))
         (color-source (make-image-color-source texture
                                                :horizontal-tile-mode :repeat
                                                :vertical-tile-mode :repeat)))
    (unwind-protect
         (progn
           (paint-set-color-source paint color-source)
           (draw-rect builder paint 0 0 200 200))
      (release-color-source color-source)
      (release-texture texture)))"
  (let ((cs (impeller-ffi:color-source-create-image-new
             texture
             (tile-mode-keyword->tile-mode-int horizontal-tile-mode)
             (tile-mode-keyword->tile-mode-int vertical-tile-mode)
             (texture-sampling-keyword->texture-sampling-int sampling))))
    (unless (cffi:null-pointer-p cs)
      cs)))
