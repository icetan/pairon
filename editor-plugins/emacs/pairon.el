(defun pairon-sync ()
  (shell-command "pairon sync"))

(defun pairon-enable ()
  (interactive)
  (global-auto-revert-mode 1)
  (setq auto-revert-interval 0.5)
  (add-hook 'after-save-hook 'pairon-sync))

(defun pairon-disable ()
  (interactive)
  (global-auto-revert-mode -1)
  (setq auto-revert-interval 5) ;; default value
  (remove-hook 'after-save-hook 'pairon-sync))
