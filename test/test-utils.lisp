;;;; flutter-render-stack/test/test-utils.lisp
;;;; Native library availability probes and test skip macros

(in-package :flutter-render-stack-tests)

;;; Native library availability probes
;;; These are checked once at first use; integration tests skip honestly
;;; (showing as SKIPPED, not falsely PASSED) when native libs are absent.

(defvar *impeller-native-available* :untested)
(defvar *flow-native-available* :untested)

(defun impeller-native-available-p ()
  "Probe whether the Impeller native library is loadable.
Caches the result after the first call."
  (when (eq *impeller-native-available* :untested)
    (setf *impeller-native-available*
          (handler-case
              (let ((ctx (frs:make-typography-context)))
                (frs:release-typography-context ctx)
                t)
            (error () nil))))
  *impeller-native-available*)

(defun flow-native-available-p ()
  "Probe whether the Flow native library is loadable.
Caches the result after the first call."
  (when (eq *flow-native-available* :untested)
    (setf *flow-native-available*
          (handler-case
              (frs:with-compositor-context (ctx)
                ctx
                t)
            (error () nil))))
  *flow-native-available*)

(defmacro skip-unless-impeller (&body body)
  "Execute BODY if Impeller native library is available, otherwise skip.
Skipped tests show as SKIPPED in Parachute output rather than falsely passing."
  `(if (impeller-native-available-p)
       (progn ,@body)
       (skip "Impeller native library not available"
         (true t))))

(defmacro skip-unless-flow (&body body)
  "Execute BODY if Flow native library is available, otherwise skip.
Skipped tests show as SKIPPED in Parachute output rather than falsely passing."
  `(if (flow-native-available-p)
       (progn ,@body)
       (skip "Flow native library not available"
         (true t))))
