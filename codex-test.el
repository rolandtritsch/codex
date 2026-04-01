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

;;;; Buffer display name tests

(ert-deftest codex-test-buffer-display-name-with-instance ()
  "Test display name when buffer has an instance name."
  (let ((buf (generate-new-buffer "*codex:/path/to/myproject/:tests*")))
    (unwind-protect
        (should (equal (codex--buffer-display-name buf)
                       "myproject:tests (/path/to/myproject/)"))
      (kill-buffer buf))))

(ert-deftest codex-test-buffer-display-name-without-instance ()
  "Test display name when buffer has no instance name."
  (let ((buf (generate-new-buffer "*codex:/path/to/myproject/*")))
    (unwind-protect
        (should (equal (codex--buffer-display-name buf)
                       "myproject (/path/to/myproject/)"))
      (kill-buffer buf))))

(ert-deftest codex-test-buffer-display-name-tilde-path ()
  "Test display name with abbreviated home directory path."
  (let ((buf (generate-new-buffer "*codex:~/repos/app/*")))
    (unwind-protect
        (should (equal (codex--buffer-display-name buf)
                       "app (~/repos/app/)"))
      (kill-buffer buf))))

;;;; Buffers to choices tests

(ert-deftest codex-test-buffers-to-choices-full-format ()
  "Test converting buffers to choices with full display names."
  (let ((buf1 (generate-new-buffer "*codex:/path/to/proj/*"))
        (buf2 (generate-new-buffer "*codex:/path/to/proj/:tests*")))
    (unwind-protect
        (let ((choices (codex--buffers-to-choices (list buf1 buf2))))
          (should (= 2 (length choices)))
          (should (equal (cdr (nth 0 choices)) buf1))
          (should (equal (cdr (nth 1 choices)) buf2))
          ;; Full format includes directory
          (should (string-match-p "proj" (car (nth 0 choices))))
          (should (string-match-p "tests" (car (nth 1 choices)))))
      (kill-buffer buf1)
      (kill-buffer buf2))))

(ert-deftest codex-test-buffers-to-choices-simple-format ()
  "Test converting buffers to choices with simple format."
  (let ((buf1 (generate-new-buffer "*codex:/path/to/proj/*"))
        (buf2 (generate-new-buffer "*codex:/path/to/proj/:tests*")))
    (unwind-protect
        (let ((choices (codex--buffers-to-choices (list buf1 buf2) t)))
          ;; Simple format uses instance name or "default"
          (should (equal (car (nth 0 choices)) "default"))
          (should (equal (car (nth 1 choices)) "tests")))
      (kill-buffer buf1)
      (kill-buffer buf2))))

(ert-deftest codex-test-buffers-to-choices-empty-list ()
  "Test converting empty buffer list."
  (should (null (codex--buffers-to-choices nil))))

;;;; Format file reference tests

(ert-deftest codex-test-format-file-reference-single-line ()
  "Test formatting a reference with explicit file and line."
  (should (equal (codex--format-file-reference "/foo/bar.el" 42 nil)
                 "@/foo/bar.el:42")))

(ert-deftest codex-test-format-file-reference-line-range ()
  "Test formatting a reference with a line range."
  (should (equal (codex--format-file-reference "/foo/bar.el" 10 20)
                 "@/foo/bar.el:10-20")))

(ert-deftest codex-test-format-file-reference-nil-file ()
  "Test formatting a reference when no file name is available."
  (with-temp-buffer
    ;; No file associated with this buffer
    (should (null (codex--format-file-reference nil 1 nil)))))

;;;; Buffer name generation tests

(ert-deftest codex-test-buffer-name-without-instance ()
  "Test buffer name generation without instance name."
  ;; We need to mock codex--directory
  (cl-letf (((symbol-function 'codex--directory)
             (lambda () "/tmp/test-project/")))
    (let ((name (codex--buffer-name)))
      (should (string-match-p "^\\*codex:" name))
      (should (string-match-p "\\*$" name))
      (should-not (string-match-p "::" name)))))

(ert-deftest codex-test-buffer-name-with-instance ()
  "Test buffer name generation with instance name."
  (cl-letf (((symbol-function 'codex--directory)
             (lambda () "/tmp/test-project/")))
    (let ((name (codex--buffer-name "my-instance")))
      (should (string-match-p "^\\*codex:" name))
      (should (string-match-p ":my-instance\\*$" name)))))

;;;; Hook wrapper path tests

(ert-deftest codex-test-hook-wrapper-path ()
  "Test that hook wrapper path resolves to bin/codex-hook-wrapper."
  (let ((load-file-name (expand-file-name "codex.el" "/fake/path/")))
    (should (equal (codex--hook-wrapper-path)
                   "/fake/path/bin/codex-hook-wrapper"))))

;;;; Hooks config dispatch tests

(ert-deftest codex-test-ensure-hooks-config-disabled ()
  "Test that hooks config does nothing when codex-enable-hooks is nil."
  (let* ((codex-enable-hooks nil)
         (toml-called nil)
         (json-called nil))
    (cl-letf (((symbol-function 'codex--ensure-config-toml-hooks)
               (lambda () (setq toml-called t)))
              ((symbol-function 'codex--ensure-hooks-json)
               (lambda () (setq json-called t))))
      (codex--ensure-hooks-config)
      (should-not toml-called)
      (should-not json-called))))

(ert-deftest codex-test-ensure-hooks-config-enabled ()
  "Test that hooks config calls both helpers when enabled."
  (let* ((codex-enable-hooks t)
         (toml-called nil)
         (json-called nil))
    (cl-letf (((symbol-function 'codex--ensure-config-toml-hooks)
               (lambda () (setq toml-called t)))
              ((symbol-function 'codex--ensure-hooks-json)
               (lambda () (setq json-called t))))
      (codex--ensure-hooks-config)
      (should toml-called)
      (should json-called))))

;;;; hooks.json idempotency test

(ert-deftest codex-test-hooks-json-idempotent ()
  "Test that running ensure-hooks-json twice doesn't duplicate entries."
  (let* ((temp-dir (make-temp-file "codex-test-hooks" t))
         (temp-file (expand-file-name "hooks.json" temp-dir))
         (codex-hooks-json-path temp-file)
         (codex-enable-hooks t))
    (unwind-protect
        (cl-letf (((symbol-function 'codex--hook-wrapper-path)
                   (lambda () "/mock/path/codex-hook-wrapper")))
          (codex--ensure-hooks-json)
          (codex--ensure-hooks-json)
          (let* ((content (with-temp-buffer
                            (insert-file-contents temp-file)
                            (json-parse-buffer :object-type 'alist)))
                 (hooks (alist-get 'hooks content))
                 (stop-hooks (alist-get 'Stop hooks)))
            ;; Each hook type should have exactly 1 entry, not 2
            (should (= 1 (length stop-hooks)))
            (should (= 1 (length (alist-get 'SessionStart hooks))))
            (should (= 1 (length (alist-get 'PreToolUse hooks))))
            (should (= 1 (length (alist-get 'PostToolUse hooks))))
            (should (= 1 (length (alist-get 'UserPromptSubmit hooks))))))
      (delete-directory temp-dir t))))

;;;; config.toml edge case tests

(ert-deftest codex-test-config-toml-hooks-creates-directory ()
  "Test that ensure-config-toml-hooks creates the parent directory."
  (let* ((temp-dir (make-temp-file "codex-test-dir" t))
         (nested-dir (expand-file-name "subdir" temp-dir))
         (config-path (expand-file-name "config.toml" nested-dir))
         (codex-hooks-config-path config-path))
    (unwind-protect
        (progn
          (should-not (file-directory-p nested-dir))
          (codex--ensure-config-toml-hooks)
          (should (file-exists-p config-path))
          (let ((content (with-temp-buffer
                           (insert-file-contents config-path)
                           (buffer-string))))
            (should (string-match-p "\\[features\\]" content))
            (should (string-match-p "codex_hooks = true" content))))
      (delete-directory temp-dir t))))

(ert-deftest codex-test-config-toml-hooks-preserves-other-content ()
  "Test that existing config.toml content is preserved."
  (let* ((temp-file (make-temp-file "codex-test-config" nil ".toml"))
         (codex-hooks-config-path temp-file))
    (unwind-protect
        (progn
          (with-temp-file temp-file
            (insert "[model]\ndefault = \"gpt-4\"\n\n[features]\nother_feature = true\n"))
          (codex--ensure-config-toml-hooks)
          (let ((content (with-temp-buffer
                           (insert-file-contents temp-file)
                           (buffer-string))))
            (should (string-match-p "default = \"gpt-4\"" content))
            (should (string-match-p "other_feature = true" content))
            (should (string-match-p "codex_hooks = true" content))))
      (delete-file temp-file))))

;;;; CLI args edge cases

(ert-deftest codex-test-build-cli-args-full-auto-overrides-sandbox ()
  "Test that full-auto truly suppresses sandbox and approval flags."
  (let ((codex-use-alt-screen t)
        (codex-full-auto t)
        (codex-sandbox-mode 'danger-full-access)
        (codex-approval-policy 'never)
        (codex-model nil)
        (codex-profile nil)
        (codex-reasoning-effort nil)
        (codex-default-images nil))
    (let ((args (codex--build-cli-args)))
      (should (member "--full-auto" args))
      (should-not (cl-find-if (lambda (a) (string-prefix-p "--sandbox" a)) args))
      (should-not (cl-find-if (lambda (a) (string-prefix-p "--ask-for-approval" a)) args)))))

(ert-deftest codex-test-build-cli-args-multiple-images ()
  "Test that multiple images produce alternating --image flags."
  (let ((codex-use-alt-screen t)
        (codex-full-auto nil)
        (codex-sandbox-mode nil)
        (codex-approval-policy nil)
        (codex-model nil)
        (codex-profile nil)
        (codex-reasoning-effort nil)
        (codex-default-images '("/a.png" "/b.png" "/c.png")))
    (let ((args (codex--build-cli-args)))
      (should (equal args '("--image" "/a.png" "--image" "/b.png" "--image" "/c.png"))))))

;;;; Buffer predicate edge cases

(ert-deftest codex-test-buffer-p-with-live-buffer ()
  "Test buffer predicate with an actual buffer object."
  (let ((buf (generate-new-buffer "*codex:/some/path/*")))
    (unwind-protect
        (should (codex--buffer-p buf))
      (kill-buffer buf))))

(ert-deftest codex-test-buffer-p-rejects-similar-names ()
  "Test that buffer predicate rejects similar but non-codex names."
  (should-not (codex--buffer-p "*codex-output*"))
  (should-not (codex--buffer-p "codex:/path/*"))
  (should-not (codex--buffer-p "*codex*")))

;;;; Directory buffer map cleanup tests

(ert-deftest codex-test-cleanup-directory-mapping ()
  "Test that cleanup removes the dying buffer from the directory map."
  (let ((codex--directory-buffer-map (make-hash-table :test 'equal))
        (buf (generate-new-buffer "*codex:/test/path/*")))
    (unwind-protect
        (progn
          (puthash "/test/path/" buf codex--directory-buffer-map)
          (puthash "/other/path/" (generate-new-buffer " *other*") codex--directory-buffer-map)
          (should (= 2 (hash-table-count codex--directory-buffer-map)))
          ;; Simulate the buffer being killed
          (with-current-buffer buf
            (codex--cleanup-directory-mapping))
          (should (= 1 (hash-table-count codex--directory-buffer-map)))
          (should-not (gethash "/test/path/" codex--directory-buffer-map))
          (should (gethash "/other/path/" codex--directory-buffer-map)))
      (kill-buffer buf)
      (when-let ((other (gethash "/other/path/" codex--directory-buffer-map)))
        (kill-buffer other)))))

;;;; Error formatting tests

(ert-deftest codex-test-format-errors-no-errors ()
  "Test error formatting when no error system is active."
  (with-temp-buffer
    ;; No flycheck, no help-at-pt
    (should (equal (codex--format-errors-at-point) "No errors at point"))))

;;;; hooks.json matcher values

(ert-deftest codex-test-hooks-json-user-prompt-submit-matcher ()
  "Test that UserPromptSubmit hook uses empty string matcher."
  (let* ((temp-dir (make-temp-file "codex-test-hooks" t))
         (temp-file (expand-file-name "hooks.json" temp-dir))
         (codex-hooks-json-path temp-file)
         (codex-enable-hooks t))
    (unwind-protect
        (cl-letf (((symbol-function 'codex--hook-wrapper-path)
                   (lambda () "/mock/path/codex-hook-wrapper")))
          (codex--ensure-hooks-json)
          (let* ((content (with-temp-buffer
                            (insert-file-contents temp-file)
                            (json-parse-buffer :object-type 'alist)))
                 (hooks (alist-get 'hooks content))
                 (ups-entry (aref (alist-get 'UserPromptSubmit hooks) 0))
                 (stop-entry (aref (alist-get 'Stop hooks) 0)))
            ;; UserPromptSubmit uses "" matcher
            (should (equal (alist-get 'matcher ups-entry) ""))
            ;; Other hooks use "*" matcher
            (should (equal (alist-get 'matcher stop-entry) "*"))))
      (delete-directory temp-dir t))))

;;;; Find codex buffers tests

(ert-deftest codex-test-find-all-codex-buffers ()
  "Test finding all codex buffers from buffer-list."
  (let ((buf1 (generate-new-buffer "*codex:/path/a/*"))
        (buf2 (generate-new-buffer "*codex:/path/b/:test*"))
        (buf3 (generate-new-buffer "*not-codex*")))
    (unwind-protect
        (let ((found (codex--find-all-codex-buffers)))
          (should (memq buf1 found))
          (should (memq buf2 found))
          (should-not (memq buf3 found)))
      (kill-buffer buf1)
      (kill-buffer buf2)
      (kill-buffer buf3))))

(provide 'codex-test)

;;; codex-test.el ends here
