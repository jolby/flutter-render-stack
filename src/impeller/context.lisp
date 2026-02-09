;;;; flutter-render-stack/impeller/context.lisp
;;;; Impeller GPU rendering context management

(in-package :flutter-render-stack)

;;; Context management

(defun make-context (&key gl-proc-address-callback)
  "Create an OpenGL ES Impeller context.

Arguments:
  gl-proc-address-callback - Callback function for GL proc address resolution.
                             Default: null (caller must provide if using GL).

Returns a pointer to an ImpellerContext object. Raises
impeller-creation-error if context creation fails.

The returned context must be released via release-context.

The GL callback signature is:
  (callback (proc-name :string) (user-data :pointer)) -> :pointer

Example (with SDL3):
  (cffi:defcallback gl-proc-getter :pointer
      ((proc-name :string) (user-data :pointer))
    (%sdl3:gl-get-proc-address proc-name))
  (make-context :gl-proc-address-callback (cffi:callback gl-proc-getter))"
  (let ((ctx (impeller-ffi:context-create-open-gles-new
              impeller-ffi:+version+
              (or gl-proc-address-callback (cffi:null-pointer))
              (cffi:null-pointer))))
    (when (cffi:null-pointer-p ctx)
      (error 'impeller-creation-error :resource-type "context"))
    ctx))

(defun release-context (context)
  "Release an OpenGL ES Impeller context.

Frees all resources associated with the context. Must be called
exactly once per context created via make-context."
  (impeller-ffi:context-release context))
