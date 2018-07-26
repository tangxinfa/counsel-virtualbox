;;; counsel-virtualbox.el --- Control VirtualBox with Ivy  -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2018  Free Software Foundation, Inc.

;; Author: tangxinfa <tangxinfa@gmail.com>
;; Keywords: matching

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

(require 'ivy)

;;** `counsel-virtualbox'
(ivy-set-actions
 'counsel-virtualbox
 `(("r" counsel-virtualbox-action-run "run")
   ("s" counsel-virtualbox-action-save "save")
   ("p" counsel-virtualbox-action-power-off "power off")
   ("n" ,(lambda (x) (kill-new (second x))) "copy name")
   ("g" ,(lambda (x) (kill-new (third x))) "copy guest os")))

(defface counsel-virtualbox-name
  '((t :inherit font-lock-variable-name-face))
  "Face used by `counsel-virtualbox' for names."
  :group 'ivy-faces)

(defface counsel-virtualbox-guest-os
  '((t :inherit font-lock-comment-face))
  "Face used by `counsel-virtualbox' for guest os."
  :group 'ivy-faces)

(defface counsel-virtualbox-state-running
  '((t :inherit success))
  "Face used by `counsel-virtualbox' for running state."
  :group 'ivy-faces)

(defface counsel-virtualbox-state-saved
  '((t :inherit font-lock-constant-face))
  "Face used by `counsel-virtualbox' for saved state."
  :group 'ivy-faces)

(defface counsel-virtualbox-state-aborted
  '((t :inherit error))
  "Face used by `counsel-virtualbox' for aborted state."
  :group 'ivy-faces)

(defface counsel-virtualbox-state-powered-off
  '((t :inherit font-lock-comment-face))
  "Face used by `counsel-virtualbox' for powered off state."
  :group 'ivy-faces)

(defface counsel-virtualbox-state-other
  '((t :inherit warning))
  "Face used by `counsel-virtualbox' for other states."
  :group 'ivy-faces)

(defun counsel--virtualbox-run (name)
  "Run virtualbox by NAME."
  (message "Run virtualbox %s" (propertize name 'face 'counsel-virtualbox-name))
  (message "%s" (shell-command-to-string (format "vboxmanage startvm '%s'" name))))

(defun counsel--virtualbox-save (name)
  "Save virtualbox by NAME."
  (message "Save virtualbox %s" (propertize name 'face 'counsel-virtualbox-name))
  (message "%s" (shell-command-to-string (format "vboxmanage controlvm '%s' savestate" name))))

(defun counsel--virtualbox-power-off (name)
  "Power off virtualbox by NAME."
  (message "Power off virtualbox %s" (propertize name 'face 'counsel-virtualbox-name))
  (message "%s" (shell-command-to-string (format "vboxmanage controlvm '%s' poweroff" name))))

(defun counsel--virtualbox-state-face (state)
  "Get face by STATE."
  (pcase state
    ("running" 'counsel-virtualbox-state-running)
    ("saved" 'counsel-virtualbox-state-saved)
    ("powered off" 'counsel-virtualbox-state-powered-off)
    ("aborted" 'counsel-virtualbox-state-aborted)
    (_ 'counsel-virtualbox-state-other)))

(defun counsel-virtualbox-action (x)
  "Action on candidate X."
  (let ((name (second x))
        (state (fourth x)))
    (pcase state
      ("running" (counsel--virtualbox-save name))
      ("saved" (counsel--virtualbox-run name))
      ("powered off" (counsel--virtualbox-run name))
      ("aborted" (counsel--virtualbox-run name))
      (_ (message "No action taken on %s virtualbox %s"
                  (propertize state 'face (counsel--virtualbox-state-face state))
                  (propertize name 'face 'counsel-virtualbox-name))))))

(defun counsel-virtualbox-action-run (x)
  "Run on candidate X."
  (counsel--virtualbox-run (second x)))

(defun counsel-virtualbox-action-save (x)
  "Save on candidate X."
  (counsel--virtualbox-save (second x)))

(defun counsel-virtualbox-action-power-off (x)
  "Power off on candidate X."
  (counsel--virtualbox-power-off (second x)))

(defun counsel--virtualbox-candidates ()
  "Return list of `counsel-virtualbox' candidates."
  (with-temp-buffer
    (insert (shell-command-to-string "VBoxManage list -l vms"))
    (let ((case-fold-search t)
          candidates
          state
          guest-os
          name)
      (while (re-search-backward "^State:\s*\\(.*\\)\s*(.*" nil t)
        (setq state (trim-string (match-string 1)))
        (if (re-search-backward "^Guest OS:\s*\\(.*\\)" nil t)
            (setq guest-os (trim-string (match-string 1)))
          (signal 'error (list "Parsing virtualbox from output"
                               "No Guest OS found"
                               (buffer-string))))
        (if (re-search-backward "^Name:\s*\\(.*\\)" nil t)
            (setq name (trim-string (match-string 1)))
          (signal 'error (list "Parsing virtualbox from output"
                               "No Name found"
                               (buffer-string))))
        (push (list
               (format "%-30s %-40s %s"
                       (propertize name 'face 'counsel-virtualbox-name)
                       (propertize guest-os 'face 'counsel-virtualbox-guest-os)
                       (propertize state 'face (counsel--virtualbox-state-face state)))
               name
               guest-os
               state)
              candidates))
      candidates)))
(counsel--virtualbox-candidates)

;;;###autoload
(defun counsel-virtualbox ()
  "Complete VirtualBox with Ivy."
  (interactive)
  (ivy-read "virtualbox: " (counsel--virtualbox-candidates)
            :history 'counsel-virtualbox-history
            :action #'counsel-virtualbox-action
            :caller 'counsel-virtualbox
            :require-match t))

(provide 'counsel-virtualbox)
;;; counsel-virtualbox.el ends here
