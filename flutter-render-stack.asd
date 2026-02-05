(asdf:defsystem :flutter-render-stack
  :description "Lispy wrappers for Flutter's rendering stack (Impeller + Flow)"
  :version "0.1.0"
  :author "Joel Boehland"
  :license "MIT"
  :depends-on (:flutter-render-stack-ffi
               :alexandria
               :bordeaux-threads
               :log4cl)
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
                                           (:file "typography" :depends-on ("context"))))
                             ;; Flow (compositor)
                             (:module "flow"
                              :depends-on ("conditions")
                              :components ((:file "layer-tree")
                                           (:file "rasterizer" :depends-on ("layer-tree"))
                                           (:file "damage" :depends-on ("layer-tree")))))))
  :in-order-to ((test-op (test-op "flutter-render-stack/tests"))))

(asdf:defsystem :flutter-render-stack/tests
  :depends-on (:flutter-render-stack
               :fiveam)
  :components ((:module "test"
                :components ((:file "package")
                             (:file "impeller-tests" :depends-on ("package"))
                             (:file "flow-tests" :depends-on ("package")))))
  :perform (test-op (op c) (symbol-call :fiveam :run! :flutter-render-stack)))
