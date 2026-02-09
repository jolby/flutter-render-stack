;;;; flutter-render-stack/conditions.lisp
;;;; Condition hierarchy for Flutter rendering stack operations

(in-package :flutter-render-stack)

;;; Base condition

(define-condition flutter-render-error (error)
  ((message :initarg :message :reader flutter-render-error-message))
  (:report (lambda (condition stream)
             (format stream "Flutter render error: ~A"
                     (flutter-render-error-message condition)))))

;;; Impeller conditions

(define-condition impeller-error (flutter-render-error)
  ()
  (:report (lambda (condition stream)
             (format stream "Impeller error: ~A"
                     (flutter-render-error-message condition)))))

(define-condition impeller-creation-error (impeller-error)
  ((resource-type :initarg :resource-type
                  :reader impeller-creation-error-resource-type))
  (:report (lambda (condition stream)
             (format stream "Failed to create Impeller ~A"
                     (impeller-creation-error-resource-type condition)))))

;;; Flow conditions

(define-condition flow-error (flutter-render-error)
  ()
  (:report (lambda (condition stream)
             (format stream "Flow error: ~A"
                     (flutter-render-error-message condition)))))

(define-condition flow-creation-error (flow-error)
  ((resource-type :initarg :resource-type
                  :reader flow-creation-error-resource-type))
  (:report (lambda (condition stream)
             (format stream "Failed to create Flow ~A"
                     (flow-creation-error-resource-type condition)))))
