(defun pairon-sync ()
  (shell-command "pairon sync -f"))

(defun pairon-enable ()
  (interactive)
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 0.5)
  )

(defun pairon-disable ()
  (interactive)
  (global-auto-revert-mode -1)
  (setq auto-revert-interval 5) ;; default value
  )
