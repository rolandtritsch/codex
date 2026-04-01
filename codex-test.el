;;; codex-test.el --- Tests for codex.el -*- lexical-binding: t; -*-

;;; Commentary:
;; Tests for the pure-logic functions in codex.el.

;;; Code:
(require 'ert)
(require 'codex)

;;;; Buffer name parsing tests

(ert-deftest codex-test-extract-directory-from-buffer-name ()
  "Test extracting directory from buffer names."
  (should (equal (codex--extract-directory-from-buffer-name "*codex:/path/to/project/*")
                 "/path/to/project/"))
  (should (equal (codex--extract-directory-from-buffer-name "*codex:/path/to/project/:tests*")
                 "/path/to/project/"))
  (should (equal (codex--extract-directory-from-buffer-name "*codex:~/repos/myapp/*")
                 "~/repos/myapp/"))
  (should (null (codex--extract-directory-from-buffer-name "*not-codex:something*")))
  (should (null (codex--extract-directory-from-buffer-name "regular-buffer"))))

(ert-deftest codex-test-extract-instance-name-from-buffer-name ()
  "Test extracting instance name from buffer names."
  (should (equal (codex--extract-instance-name-from-buffer-name "*codex:/path/to/project/:tests*")
                 "tests"))
  (should (equal (codex--extract-instance-name-from-buffer-name "*codex:/path/:my-instance*")
                 "my-instance"))
  (should (null (codex--extract-instance-name-from-buffer-name "*codex:/path/to/project/*")))
  (should (null (codex--extract-instance-name-from-buffer-name "not-a-codex-buffer"))))

(ert-deftest codex-test-buffer-p ()
  "Test Codex buffer predicate."
  (should (codex--buffer-p "*codex:/some/path/*"))
  (should (codex--buffer-p "*codex:/some/path/:instance*"))
  (should-not (codex--buffer-p "*claude:/some/path/*"))
  (should-not (codex--buffer-p "*scratch*"))
  (should-not (codex--buffer-p nil)))

;;;; CLI argument building tests

(ert-deftest codex-test-build-cli-args-defaults ()
  "Test CLI arg building with default settings."
  (let ((codex-use-alt-screen t)
        (codex-full-auto nil)
        (codex-sandbox-mode nil)
        (codex-approval-policy nil)
        (codex-model nil)
        (codex-profile nil)
        (codex-reasoning-effort nil)
        (codex-default-images nil))
    (should (equal (codex--build-cli-args) nil))))

(ert-deftest codex-test-build-cli-args-no-alt-screen ()
  "Test CLI arg building with alt-screen disabled."
  (let ((codex-use-alt-screen nil)
        (codex-full-auto nil)
        (codex-sandbox-mode nil)
        (codex-approval-policy nil)
        (codex-model nil)
        (codex-profile nil)
        (codex-reasoning-effort nil)
        (codex-default-images nil))
    (should (equal (codex--build-cli-args) '("--no-alt-screen")))))

(ert-deftest codex-test-build-cli-args-full-auto ()
  "Test CLI arg building with full-auto mode."
  (let ((codex-use-alt-screen t)
        (codex-full-auto t)
        (codex-sandbox-mode 'read-only)
        (codex-approval-policy 'never)
        (codex-model nil)
        (codex-profile nil)
        (codex-reasoning-effort nil)
        (codex-default-images nil))
    ;; full-auto should override sandbox and approval
    (should (equal (codex--build-cli-args) '("--full-auto")))))

(ert-deftest codex-test-build-cli-args-sandbox-and-approval ()
  "Test CLI arg building with sandbox and approval settings."
  (let ((codex-use-alt-screen t)
        (codex-full-auto nil)
        (codex-sandbox-mode 'workspace-write)
        (codex-approval-policy 'on-request)
        (codex-model nil)
        (codex-profile nil)
        (codex-reasoning-effort nil)
        (codex-default-images nil))
    (should (equal (codex--build-cli-args)
                   '("--sandbox=workspace-write" "--ask-for-approval=on-request")))))

(ert-deftest codex-test-build-cli-args-model-and-profile ()
  "Test CLI arg building with model and profile."
  (let ((codex-use-alt-screen t)
        (codex-full-auto nil)
        (codex-sandbox-mode nil)
        (codex-approval-policy nil)
        (codex-model "gpt-5.4")
        (codex-profile "work")
        (codex-reasoning-effort "high")
        (codex-default-images nil))
    (should (equal (codex--build-cli-args)
                   '("--model" "gpt-5.4" "--profile" "work" "--reasoning-effort" "high")))))

(ert-deftest codex-test-build-cli-args-images ()
  "Test CLI arg building with default images."
  (let ((codex-use-alt-screen t)
        (codex-full-auto nil)
        (codex-sandbox-mode nil)
        (codex-approval-policy nil)
        (codex-model nil)
        (codex-profile nil)
        (codex-reasoning-effort nil)
        (codex-default-images '("/path/to/img1.png" "/path/to/img2.jpg")))
    (should (equal (codex--build-cli-args)
                   '("--image" "/path/to/img1.png" "--image" "/path/to/img2.jpg")))))

(ert-deftest codex-test-build-cli-args-all-options ()
  "Test CLI arg building with everything set."
  (let ((codex-use-alt-screen nil)
        (codex-full-auto nil)
        (codex-sandbox-mode 'danger-full-access)
        (codex-approval-policy 'untrusted)
        (codex-model "o3")
        (codex-profile "testing")
        (codex-reasoning-effort "low")
        (codex-default-images '("/img.png")))
    (should (equal (codex--build-cli-args)
                   '("--no-alt-screen"
                     "--sandbox=danger-full-access"
                     "--ask-for-approval=untrusted"
                     "--model" "o3"
                     "--profile" "testing"
                     "--reasoning-effort" "low"
                     "--image" "/img.png")))))

;;;; TOML config manipulation tests

(ert-deftest codex-test-config-toml-hooks-empty-file ()
  "Test ensuring hooks in an empty config.toml."
  (let* ((temp-file (make-temp-file "codex-test-config" nil ".toml"))
         (codex-hooks-config-path temp-file))
    (unwind-protect
        (progn
          (codex--ensure-config-toml-hooks)
          (let ((content (with-temp-buffer
                           (insert-file-contents temp-file)
                           (buffer-string))))
            (should (string-match-p "\\[features\\]" content))
            (should (string-match-p "codex_hooks = true" content))))
      (delete-file temp-file))))

(ert-deftest codex-test-config-toml-hooks-existing-features ()
  "Test ensuring hooks when [features] section already exists."
  (let* ((temp-file (make-temp-file "codex-test-config" nil ".toml"))
         (codex-hooks-config-path temp-file))
    (unwind-protect
        (progn
          (with-temp-file temp-file
            (insert "[features]\nsome_feature = true\n"))
          (codex--ensure-config-toml-hooks)
          (let ((content (with-temp-buffer
                           (insert-file-contents temp-file)
                           (buffer-string))))
            (should (string-match-p "codex_hooks = true" content))
            ;; Should not duplicate [features] section
            (should (= 1 (cl-count-if (lambda (_) t)
                                       (split-string content "\\[features\\]" t))))))
      (delete-file temp-file))))

(ert-deftest codex-test-config-toml-hooks-already-present ()
  "Test that existing codex_hooks = true is not duplicated."
  (let* ((temp-file (make-temp-file "codex-test-config" nil ".toml"))
         (codex-hooks-config-path temp-file))
    (unwind-protect
        (progn
          (with-temp-file temp-file
            (insert "[features]\ncodex_hooks = true\n"))
          (codex--ensure-config-toml-hooks)
          (let ((content (with-temp-buffer
                           (insert-file-contents temp-file)
                           (buffer-string))))
            ;; Should appear exactly once
            (let ((count 0)
                  (start 0))
              (while (string-match "codex_hooks = true" content start)
                (setq count (1+ count)
                      start (match-end 0)))
              (should (= 1 count)))))
      (delete-file temp-file))))

;;;; hooks.json merging tests

(ert-deftest codex-test-hooks-json-creates-new-file ()
  "Test that hooks.json is created from scratch."
  (let* ((temp-dir (make-temp-file "codex-test-hooks" t))
         (temp-file (expand-file-name "hooks.json" temp-dir))
         (codex-hooks-json-path temp-file)
         (codex-enable-hooks t))
    (unwind-protect
        (progn
          ;; Mock the hook wrapper path
          (cl-letf (((symbol-function 'codex--hook-wrapper-path)
                     (lambda () "/mock/path/codex-hook-wrapper")))
            (codex--ensure-hooks-json)
            (should (file-exists-p temp-file))
            (let ((content (with-temp-buffer
                             (insert-file-contents temp-file)
                             (json-parse-buffer :object-type 'alist))))
              (should (alist-get 'hooks content))
              ;; Check all 5 hook types are present
              (let ((hooks (alist-get 'hooks content)))
                (should (alist-get 'Stop hooks))
                (should (alist-get 'SessionStart hooks))
                (should (alist-get 'PreToolUse hooks))
                (should (alist-get 'PostToolUse hooks))
                (should (alist-get 'UserPromptSubmit hooks))))))
      (delete-directory temp-dir t))))

(ert-deftest codex-test-hooks-json-preserves-existing ()
  "Test that existing hooks.json entries are preserved."
  (let* ((temp-dir (make-temp-file "codex-test-hooks" t))
         (temp-file (expand-file-name "hooks.json" temp-dir))
         (codex-hooks-json-path temp-file)
         (codex-enable-hooks t))
    (unwind-protect
        (progn
          ;; Write an existing hooks.json with a user hook
          (with-temp-file temp-file
            (insert (json-encode
                     '((hooks . ((Stop . [((matcher . "*")
                                           (hooks . [((type . "command")
                                                      (command . "/usr/bin/my-custom-hook Stop")
                                                      (timeout . 10))]))])))))))
          (cl-letf (((symbol-function 'codex--hook-wrapper-path)
                     (lambda () "/mock/path/codex-hook-wrapper")))
            (codex--ensure-hooks-json)
            (let* ((content (with-temp-buffer
                              (insert-file-contents temp-file)
                              (json-parse-buffer :object-type 'alist)))
                   (hooks (alist-get 'hooks content))
                   (stop-hooks (alist-get 'Stop hooks)))
              ;; Should have 2 entries: existing + ours
              (should (= 2 (length stop-hooks)))
              ;; Verify the user's hook is preserved
              (let* ((first-entry (aref stop-hooks 0))
                     (first-hooks (alist-get 'hooks first-entry))
                     (first-cmd (alist-get 'command (aref first-hooks 0))))
                (should (string= first-cmd "/usr/bin/my-custom-hook Stop"))))))
      (delete-directory temp-dir t))))

(provide 'codex-test)

;;; codex-test.el ends here
