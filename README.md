# flutter-render-stack

Lispy wrappers for Flutter's rendering stack (Impeller + Flow).

## Purpose

Idiomatic Common Lisp API built on [flutter-render-stack-ffi](https://github.com/jolby/flutter-render-stack-ffi):

### Impeller (2D Graphics)
- Context management
- Paint and path abstractions
- Display list building
- Typography and text rendering

### Flow (Compositor)
- Layer tree construction
- Rasterizer integration
- Damage tracking

## Dependencies

- flutter-render-stack-ffi
- alexandria
- bordeaux-threads
- log4cl

## Usage

```lisp
(ql:quickload :flutter-render-stack)

;; Impeller graphics
(frs:with-context (ctx)
  (frs:with-display-list-builder (builder ctx)
    (frs:draw-rect builder 0 0 100 100 paint)))

;; Flow layer tree
(frs:with-layer-tree (tree)
  (frs:add-picture-layer tree display-list))
```

## Related Projects

- [flutter-render-stack-ffi](https://github.com/jolby/flutter-render-stack-ffi) - Underlying FFI bindings
- [render-stack](https://github.com/jolby/render-stack) - Core rendering engine

## License

MIT
