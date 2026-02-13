;;;; flutter-render-stack/impeller/elevated-panels.lisp
;;;; Material Design inspired elevated panels with shadows

(in-package :flutter-render-stack)

;;; Elevated panel drawing

(defun draw-elevated-panel (builder x y width height elevation
                            &key (corner-radius 4.0)
                                 (panel-color '(1.0 1.0 1.0 1.0))
                                 (shadow-opacity 0.3)
                                 (device-pixel-ratio 1.0))
  "Draw a Material Design style elevated panel with shadow.

Arguments:
  builder            - Display list builder from with-display-list-builder
  x, y               - Top-left corner position (float)
  width, height      - Panel dimensions (float)
  elevation          - Material Design elevation in dp (0-24):
                       0 = flat, 1-2 = cards at rest, 4-8 = raised, 16-24 = dialogs
  corner-radius      - Corner radius for rounded corners (default 4.0)
  panel-color        - Panel color as (r g b a) list (default white)
  shadow-opacity     - Shadow darkness 0.0-1.0 (default 0.3)
  device-pixel-ratio - HiDPI scale factor (default 1.0)

This function draws a complete elevated panel:
1. Draws the shadow using Material Design elevation
2. Draws the rounded panel on top

Example:
  ;; Material Design card at 4dp elevation
  (draw-elevated-panel builder 50 50 200 120 4.0
                       :corner-radius 8.0
                       :panel-color '(0.95 0.95 0.95 1.0))

  ;; Floating action button style (circular, high elevation)
  (draw-elevated-panel builder 300 400 56 56 16.0
                       :corner-radius 28.0  ; Circular
                       :panel-color '(0.2 0.6 1.0 1.0))

Note: Higher elevations (8-24) create larger, softer shadows as per
Material Design spec. Shadows are drawn with an ambient and key light
effect automatically."
  (declare (type float x y width height corner-radius shadow-opacity device-pixel-ratio)
           (type number elevation)
           (type list panel-color))
  ;; Convert elevation to float if needed
  (let ((elevation (float elevation 1.0f0)))
    ;; Create rounded rectangle path using the built-in function
    (with-path-builder (pb)
      (path-add-rounded-rect pb x y width height :radius corner-radius)
      (let ((panel-path (build-path pb)))
        (unwind-protect
             (progn
               ;; Draw shadow first
               (draw-shadow builder panel-path
                            0.0 0.0 0.0 shadow-opacity
                            elevation
                            :device-pixel-ratio device-pixel-ratio)
               ;; Draw panel
               (let ((paint (make-paint)))
                 (unwind-protect
                      (destructuring-bind (r g b a) panel-color
                        (paint-set-color paint r g b a)
                        (paint-set-draw-style paint :fill)
                        (draw-path builder panel-path paint))
                   (release-paint paint))))
          (release-path panel-path))))))

;;; Predefined elevation levels (Material Design 3)

(defun draw-card (builder x y width height
                  &key (elevation 1)
                       (corner-radius 12.0)
                       (panel-color '(1.0 1.0 1.0 1.0)))
  "Draw a Material Design 3 style card.

Arguments:
  builder       - Display list builder
  x, y          - Position
  width, height - Dimensions
  elevation     - 0 (flat), 1 (resting), 2 (hovered), or 4-8 (pressed)
  corner-radius - Default 12dp for MD3
  panel-color   - Card background color

Example:
  ;; Standard card
  (draw-card builder 20 20 300 150)
  
  ;; Elevated card (hovered state)
  (draw-card builder 20 180 300 150 :elevation 2)"
  (draw-elevated-panel builder x y width height elevation
                       :corner-radius corner-radius
                       :panel-color panel-color))

(defun draw-fab (builder cx cy size
                 &key (elevation 6)
                      (fab-color '(0.2 0.6 1.0 1.0)))
  "Draw a Material Design Floating Action Button (FAB).

Arguments:
  builder   - Display list builder
  cx, cy    - Center position
  size      - Button size (56 for regular, 40 for mini)
  elevation - Default 6 for resting, 12 for pressed
  fab-color - Button color (default blue)

Example:
  ;; Regular FAB
  (draw-fab builder 350 550 56)"
  (let ((half-size (/ size 2.0)))
    (draw-elevated-panel builder
                         (- cx half-size) (- cy half-size)
                         size size elevation
                         :corner-radius half-size  ; Circular
                         :panel-color fab-color)))

(defun draw-dialog (builder x y width height
                    &key (elevation 24)
                         (corner-radius 28.0))
  "Draw a Material Design 3 style dialog surface.

Arguments:
  builder       - Display list builder
  x, y          - Position
  width, height - Dimensions  
  elevation     - 24dp (highest, for modal dialogs)
  corner-radius - 28dp for MD3 dialogs

Example:
  ;; Confirmation dialog
  (draw-dialog builder 50 100 300 200)"
  (draw-elevated-panel builder x y width height elevation
                       :corner-radius corner-radius))

;;; Shadow-only helper (for custom content)

(defun draw-elevation-shadow (builder x y width height elevation
                              &key (corner-radius 0.0)
                                   (shadow-opacity 0.3)
                                   (device-pixel-ratio 1.0))
  "Draw only the shadow for an elevated panel (draw content separately).

Use this when you want to draw custom content on top of the shadow.

Example:
  ;; Draw shadow first
  (draw-elevation-shadow builder 50 50 200 100 4.0 :corner-radius 8.0)
  ;; Then draw your custom content
  (draw-custom-content builder 50 50 200 100)"
  (declare (type float x y width height corner-radius shadow-opacity device-pixel-ratio)
           (type number elevation))
  ;; Convert elevation to float if needed
  (let ((elevation (float elevation 1.0f0)))
    (with-path-builder (pb)
      (path-add-rounded-rect pb x y width height :radius corner-radius)
      (let ((panel-path (build-path pb)))
        (unwind-protect
             (draw-shadow builder panel-path
                          0.0 0.0 0.0 shadow-opacity
                          elevation
                          :device-pixel-ratio device-pixel-ratio)
          (release-path panel-path))))))
