;;; .dir-locals.el --- Org writing setup for the doom-lcars theme  -*- no-byte-compile: t -*-
;;
;; Put this file in the root of a writing project, such as a Hugo site with
;; posts in Org format. In Org buffers it gives a book-like page: serif body
;; text in variable pitch, bold narrow sans headings in the LCARS style, hidden
;; emphasis markers, soft-wrapped lines, and Hugo shortcodes highlighted. Code,
;; tables and keywords stay in the fixed-pitch font.
;;
;; Emacs asks before applying the `eval' form. Answer `!' to trust this file.
;; Optional packages, used when installed: mixed-pitch, visual-fill-column.

((nil
  . ((fill-column . 80)
     (sentence-end-double-space . nil)
     (indent-tabs-mode . nil)
     (require-final-newline . t)
     (ispell-local-dictionary . "en_US")))

 (org-mode
  . ((org-hide-emphasis-markers . t)
     (org-pretty-entities . t)
     (org-adapt-indentation . nil)
     (eval
      . (progn
          (setq-local line-spacing 0.25)
          (visual-line-mode 1)
          (when (fboundp 'flyspell-mode)
            (flyspell-mode 1))

          ;; Body text: the first serif font that is installed. ET Book is the
          ;; blog's typeface; Liberation Serif is the usual fallback.
          (let ((pick (lambda (families)
                        (seq-find (lambda (f) (find-font (font-spec :family f)))
                                  families)))
                (fixed '(org-block org-block-begin-line org-block-end-line
                         org-code org-verbatim org-table org-formula
                         org-meta-line org-document-info-keyword
                         org-special-keyword org-property-value org-drawer
                         org-checkbox org-date org-tag
                         line-number line-number-current-line)))
            (let ((serif (funcall pick '("ET Book" "Liberation Serif"
                                         "Noto Serif" "DejaVu Serif")))
                  (sans (funcall pick '("Liberation Sans Narrow"
                                        "Liberation Sans" "DejaVu Sans"))))
              (if (fboundp 'mixed-pitch-mode)
                  (mixed-pitch-mode 1)
                (variable-pitch-mode 1)
                (dolist (face fixed)
                  (face-remap-add-relative face 'fixed-pitch)))
              (when serif
                (face-remap-add-relative 'variable-pitch
                                         :family serif :height 1.15))
              ;; Headings: LCARS style, bold narrow sans, stepped sizes.
              (dolist (spec '((org-document-title . 1.6)
                              (org-level-1 . 1.35)
                              (org-level-2 . 1.2)
                              (org-level-3 . 1.1)
                              (org-level-4 . 1.0)))
                (apply #'face-remap-add-relative (car spec)
                       :weight 'bold :height (cdr spec)
                       (and sans (list :family sans))))))

          ;; Hugo shortcodes: {{< sidenote >}} ... {{< /sidenote >}}
          (font-lock-add-keywords
           nil
           `(("{{[<%][^}]*[>%]}}" 0
              ',(if (facep 'doom-lcars-hugo-shortcode)
                    'doom-lcars-hugo-shortcode
                  'font-lock-preprocessor-face)
              t)))

          ;; Center the text column when visual-fill-column is installed.
          (when (fboundp 'visual-fill-column-mode)
            (setq-local visual-fill-column-width 88
                        visual-fill-column-center-text t)
            (visual-fill-column-mode 1))

          (font-lock-flush))))))
