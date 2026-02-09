# flutter-render-stack

Idiomatic Common Lisp wrappers for Flutter's rendering stack, built on [flutter-render-stack-ffi](https://github.com/jolby/flutter-render-stack-ffi).

## Modules

### Impeller (2D GPU Graphics) — Complete

GPU-accelerated 2D rendering via Flutter's Impeller engine:

- **Context & Surface** — OpenGL ES context creation, FBO surface wrapping
- **Paint** — Color, stroke style, width, cap, join, miter, color sources
- **Path** — Path building: move/line-to, rects, ovals, rounded rects, close
- **Display List** — Drawing primitives (rect, oval, path, rounded rect, shadow), transform/clip state, retained rendering via cached display lists
- **Gradients** — Linear and radial gradient color sources with tile modes
- **Typography** — Font loading (memory/file), paragraph style/builder/metrics, text rendering

### Flow (Compositor) — Planned

Retained-mode compositor with layer tree construction, rasterizer integration, and damage tracking. Skeleton files are in place; implementation is tracked as a future task.

## Dependencies

```
flutter-render-stack-ffi   ; C API bindings (CLAW-generated)
render-stack-internals     ; FFI utilities, logging, cancellation
cffi                       ; Foreign function interface
cffi-c-ref                 ; Stack-allocated struct construction
float-features             ; Float trap masking
alexandria                 ; Utilities
verbose                    ; Operational logging (Shinmera)
```

Testing uses [Parachute](https://github.com/Shinmera/parachute).

## Usage

```lisp
(ql:quickload :flutter-render-stack)
```

### Drawing a rectangle

```lisp
(let ((paint (frs:make-paint)))
  (frs:paint-set-color paint 1.0 0.0 0.0 1.0)     ; red
  (frs:paint-set-draw-style paint :fill)
  (frs:with-display-list-builder (builder)
    (frs:draw-rect builder 10 10 200 100 paint)
    (frs:execute-display-list surface builder))
  (frs:release-paint paint))
```

### Building a path

```lisp
(frs:with-path-builder (pb)
  (frs:path-move-to pb 0 0)
  (frs:path-line-to pb 100 0)
  (frs:path-line-to pb 50 80)
  (frs:path-close pb)
  (let ((path (frs:build-path pb)))
    (frs:with-display-list-builder (builder)
      (frs:draw-path builder path paint)
      (frs:execute-display-list surface builder))
    (frs:release-path path)))
```

### Linear gradient

```lisp
(let ((cs (frs:make-linear-gradient-color-source
           0 0 100 0
           '((1.0 0.0 0.0 1.0) (0.0 0.0 1.0 1.0))  ; red -> blue
           '(0.0 1.0))))
  (frs:paint-set-color-source paint cs)
  ;; ... draw with paint ...
  (frs:release-color-source cs))
```

### Typography

```lisp
(let ((typo-ctx (frs:make-typography-context)))
  (frs:register-font-from-file typo-ctx "/path/to/font.ttf")
  (let ((style (frs:make-paragraph-style)))
    (frs:paragraph-style-set-font-family style "MyFont")
    (frs:paragraph-style-set-font-size style 24.0)
    (frs:with-paragraph-builder (pb typo-ctx)
      (frs:paragraph-builder-push-style pb style)
      (frs:paragraph-builder-add-text pb "Hello, Impeller!")
      (let ((paragraph (frs:paragraph-builder-build pb 400.0)))
        (frs:with-display-list-builder (builder)
          (frs:draw-paragraph builder paragraph 10.0 10.0)
          (frs:execute-display-list surface builder))
        (frs:release-paragraph paragraph)))
    (frs:release-paragraph-style style))
  (frs:release-typography-context typo-ctx))
```

## Examples

See [examples/basic-drawing.lisp](examples/basic-drawing.lisp) for complete, runnable examples covering:

1. **Colored rectangles** — filled and stroked rects with paint configuration
2. **Custom path** — building and drawing a triangle
3. **Card with shadow** — rounded rect + Material Design elevation shadow
4. **Linear gradient** — gradient color source on a rectangle
5. **Transform state** — save/restore with translate to draw a grid of circles
6. **Retained display list** — build once, draw multiple times at different opacities

Each example is a standalone function that takes a `surface` argument (from `frs:make-wrapped-fbo-surface`).

## Testing

```lisp
(asdf:test-system :flutter-render-stack)
```

Tests include export verification, condition hierarchy checks, and enum converter round-trips. Integration tests degrade gracefully when native Impeller libraries are unavailable.

## Package

The system exports a single package: `flutter-render-stack` (nickname `:frs`).

## Related Projects

- [flutter-render-stack-ffi](https://github.com/jolby/flutter-render-stack-ffi) — CLAW-generated C API bindings
- [render-stack-internals](https://github.com/jolby/render-stack-internals) — Shared FFI utilities and logging
- [render-stack-sdl3](https://github.com/jolby/render-stack-sdl3) — SDL3 windowing and input
- [render-stack](https://github.com/jolby/render-stack) — Top-level system integrating all modules

## License

MIT
