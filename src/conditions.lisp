(in-package :flutter-render-stack)

;;; Conditions for Flutter rendering stack operations

(define-condition flutter-render-error (error)
  ((message :initarg :message :reader flutter-render-error-message))
  (:report (lambda (condition stream)
             (format stream "Flutter render error: ~A" 
                     (flutter-render-error-message condition)))))

(define-condition impeller-error (flutter-render-error)
  ()
  (:report (lambda (condition stream)
             (format stream "Impeller error: ~A" 
                     (flutter-render-error-message condition)))))

(define-condition flow-error (flutter-render-error)
  ()
  (:report (lambda (condition stream)
             (format stream "Flow error: ~A" 
                     (flutter-render-error-message condition)))))
