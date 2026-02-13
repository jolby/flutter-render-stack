(asdf:defsystem :flutter-render-stack
  :description "Lispy wrappers for Flutter's rendering stack (Impeller + Flow)"
  :version "0.1.0"
  :author "Joel Boehland"
  :license "MIT"
  :depends-on (:flutter-render-stack-ffi
               :render-stack-internals  ; FFI utils, logging, cancellation
               :cffi                    ; foreign function interface
               :cffi-c-ref              ; stack-allocated struct construction
               :float-features          ; float trap masking
               :alexandria
               :verbose)               ; operational logging (Shinmera)
  :components ((:module "src"
                :components ((:file "package")
                             (:file "conditions" :depends-on ("package"))
                              ;; Impeller (2D graphics)
                              (:module "impeller"
                               :depends-on ("conditions")
                               :components ((:file "context")
                                            (:file "paint" :depends-on ("context"))
                                            (:file "path" :depends-on ("context"))
                                            (:file "display-list" :depends-on ("paint" "path"))
                                            (:file "typography" :depends-on ("context"))
                                            (:file "mask-filters" :depends-on ("paint"))
                                            (:file "image-filters" :depends-on ("paint"))
                                            (:file "color-filters" :depends-on ("paint"))
                                            (:file "texture" :depends-on ("context"))
                                            (:file "elevated-panels" :depends-on ("display-list" "path"))))
                              ;; Typography (extended text metrics)
                              (:module "typography"
                               :depends-on ("impeller")
                               :components ((:file "line-metrics")
                                            (:file "glyph-info")
                                            (:file "word-boundaries")))
                             ;; Flow (compositor)
                             (:module "flow"
                              :depends-on ("conditions")
                              :components ((:file "layer-tree")
                                           (:file "rasterizer" :depends-on ("layer-tree"))
                                           (:file "damage" :depends-on ("layer-tree")))))))
  :in-order-to ((test-op (test-op "flutter-render-stack/tests"))))

(asdf:defsystem :flutter-render-stack/tests
  :depends-on (:flutter-render-stack
               :parachute)
  :components ((:module "test"
                :components ((:file "package")
                             (:file "test-utils" :depends-on ("package"))
                             (:file "impeller-tests" :depends-on ("test-utils"))
                             (:file "flow-tests" :depends-on ("test-utils")))))
  :perform (test-op (op c) (uiop:symbol-call :parachute :test :flutter-render-stack-tests)))
