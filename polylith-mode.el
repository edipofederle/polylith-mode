;;; polylith-mode.el --- Navigate project components efficiently and run project commands

;; Author: Edipo Luis Federle
;; Keywords: navigation, project, clojure
;; Package-Requires: ((emacs "25.1") (helm "3.0") (projectile "2.0"))

;;; Commentary:
;; This package provides tools for navigating and interacting with Polylith architecture projects.
;; Polylith is a component-based architecture for Clojure projects that separates
;; functionality into reusable components and bases.
;;
;; Key features:
;;   - Navigate to components and bases within a Polylith workspace
;;   - Quick switching between source and test files
;;   - Run build commands on selected projects
;;   - Customizable directory structure to fit your Polylith workspace setup
;;
;; To set up the workspace directory, customize the polylith-mode-workspace-directory variable:
;;   (setq polylith-mode-workspace-directory "/path/to/your/workspace/")
;;
;; If needed, you can also customize the directory names:
;;   (setq polylith-mode-components-directory-name "components")
;;   (setq polylith-mode-bases-directory-name "bases")
;;   (setq polylith-mode-projects-directory-name "projects")
;;
;; To activate the mode:
;;   (polylith-mode 1)
;;
;; Key bindings:
;;   C-c p c - Find and open a component
;;   C-c p b - Find and open a base
;;   C-c p C - Jump to components directory
;;   C-c p u - Run clojure uberjar command
;;   C-c t   - Toggle between source and test files

;;; Code:
(require 'helm)
(require 'projectile)

(defgroup polylith-mode nil
  "Navigate to project components."
  :group 'tools
  :prefix "polylith-mode-")

(defcustom polylith-mode-workspace-directory (expand-file-name "~/workspace/")
  "Root directory for the Polylith workspace.
This will be used as the base directory for components, bases, and projects."
  :type 'string
  :group 'polylith-mode)

(defcustom polylith-mode-components-directory-name "components"
  "Name of the components directory within the workspace."
  :type 'string
  :group 'polylith-mode)

(defcustom polylith-mode-bases-directory-name "bases"
  "Name of the bases directory within the workspace."
  :type 'string
  :group 'polylith-mode)

(defcustom polylith-mode-projects-directory-name "projects"
  "Name of the projects directory within the workspace."
  :type 'string
  :group 'polylith-mode)

;; Directory path helper functions
(defun polylith-mode--get-components-dir ()
  "Get the full path to the components directory."
  (expand-file-name
   (concat polylith-mode-components-directory-name "/")
   polylith-mode-workspace-directory))

(defun polylith-mode--get-bases-dir ()
  "Get the full path to the bases directory."
  (expand-file-name
   (concat polylith-mode-bases-directory-name "/")
   polylith-mode-workspace-directory))

(defun polylith-mode--get-projects-dir ()
  "Get the full path to the projects directory."
  (expand-file-name
   (concat polylith-mode-projects-directory-name "/")
   polylith-mode-workspace-directory))

;; Generic directory listing function
(defun polylith-mode--list-dirs (dir)
  "List all directories in DIR."
  (when (file-directory-p dir)
    (let ((dirs '()))
      (dolist (directory (directory-files dir t directory-files-no-dot-files-regexp))
        (when (file-directory-p directory)
          (push (cons (file-name-nondirectory directory) directory) dirs)))
      dirs)))

;; Specialized listing functions that use the generic helper
(defun polylith-mode--list-components (components-dir)
  "List all components in COMPONENTS-DIR."
  (polylith-mode--list-dirs components-dir))

(defun polylith-mode--list-bases (bases-dir)
  "List all bases in BASES-DIR."
  (polylith-mode--list-dirs bases-dir))

;; Single function for opening directories
(defun polylith-mode--open-dir (dir-path)
  "Open DIR-PATH in a dired buffer."
  (dired dir-path))

;; Generic function to find and open directories
(defun polylith-mode--find-dir (get-dir-fn list-fn source-name buffer-name)
  "Find and open a directory using GET-DIR-FN and LIST-FN.
Display results in a helm buffer with SOURCE-NAME and BUFFER-NAME."
  (let ((dir (funcall get-dir-fn)))
    (if (not dir)
        (message "Not in a project or directory not found")
      (helm :sources
            (helm-build-sync-source source-name
              :candidates (funcall list-fn dir)
              :action '(("Open" . polylith-mode--open-dir)))
            :buffer buffer-name))))

;; Specialized find functions using the generic helper
(defun polylith-mode-find-component ()
  "Interactively find and open a component."
  (interactive)
  (polylith-mode--find-dir
   'polylith-mode--get-components-dir
   'polylith-mode--list-components
   "Project Components"
   "*helm component nav*"))

(defun polylith-mode-find-base ()
  "Interactively find and open a base."
  (interactive)
  (polylith-mode--find-dir
   'polylith-mode--get-bases-dir
   'polylith-mode--list-bases
   "Project Bases"
   "*helm base nav*"))

(defun polylith-mode-jump-to-components-dir ()
  "Jump to the components directory in dired."
  (interactive)
  (let ((components-dir (polylith-mode--get-components-dir)))
    (if (not components-dir)
        (message "Not in a project or components directory not found")
      (dired components-dir))))

(defun polylith-mode--list-projects ()
  "List all projects in the projects directory."
  (let ((projects-dir (polylith-mode--get-projects-dir)))
    (when (file-directory-p projects-dir)
      (let ((projects '()))
        (dolist (dir (directory-files projects-dir t directory-files-no-dot-files-regexp))
          (when (file-directory-p dir)
            (push (cons (file-name-nondirectory dir) (file-name-nondirectory dir)) projects)))
        projects))))

(defun polylith-mode-run-clojure-uberjar ()
  "Run clojure uberjar command with project name completion."
  (interactive)
  (let* ((project (helm :sources
                        (helm-build-sync-source "Select Project"
                          :candidates (polylith-mode--list-projects)
                          :action 'identity)
                        :buffer "*helm select project*"))
         (command (format "clojure -T:build uberjar :project %s" project))
         (default-directory polylith-mode-workspace-directory))
    (when project
      (message "Running: %s in %s" command default-directory)
      (async-shell-command command "*Clojure Uberjar*"))))

(defun toggle-between-src-and-test ()
  (interactive)
  (when (buffer-file-name)
    (let* ((current-file (buffer-file-name))
           (is-test (string-match-p "/test/" current-file))
           (is-src (string-match-p "/src/" current-file))
           (target-file
            (cond
             (is-test
              (replace-regexp-in-string
               "/test/" "/src/"
               (replace-regexp-in-string "_test\\.clj$" ".clj" current-file)))

             (is-src
              (replace-regexp-in-string
               "/src/" "/test/"
               (replace-regexp-in-string "\\.clj$" "_test.clj" current-file)))

             (t nil))))
      (if target-file
          (if (file-exists-p target-file)
              (find-file target-file)
            (when (y-or-n-p (format "File %s does not exist. Create it?" target-file))
              (find-file target-file)))
        (message "Could not determine the corresponding test/source file.")))))

;; Keyboard shortcuts
(defvar polylith-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c p c") 'polylith-mode-find-component)
    (define-key map (kbd "C-c p b") 'polylith-mode-find-base)
    (define-key map (kbd "C-c p C") 'polylith-mode-jump-to-components-dir)
    (define-key map (kbd "C-c p u") 'polylith-mode-run-clojure-uberjar)
    (define-key map (kbd "C-c t") 'toggle-between-src-and-test)
    map)
  "Keymap for Polylith mode.")

;;;###autoload
(define-minor-mode polylith-mode
  "Minor mode for navigating project components."
  :lighter " Polylith"
  :keymap polylith-mode-map
  :group 'polylith-mode
  :global t)

(provide 'polylith-mode)
;;; polylith-mode.el ends here
