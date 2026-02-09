;;;; flutter-render-stack/test/package.lisp
;;;; Test package definition

(defpackage :flutter-render-stack-tests
  (:use :cl :parachute)
  (:local-nicknames (:frs :flutter-render-stack))
  (:documentation
   "Test suite for flutter-render-stack wrapper module.
    Tests wrapper API correctness, resource management, and FFI bindings."))
