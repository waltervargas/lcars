;;; doom-lcars-theme.el --- Star Trek LCARS colours -*- lexical-binding: t; no-byte-compile: t; -*-
;;
;; Author: Walter Vargas
;; Source: https://github.com/waltervargas/lcars
;;
;;; Commentary:
;;
;; Colours come from palette/lcars.json in the LCARS repo: a black background,
;; peach text, orange for the active mode-line and highlights, violet for
;; inactive bars. Matches the sway, kitty, foot, glow and VS Code targets.
;;
;;; Code:

(require 'doom-themes)


;;
;;; Variables

(defgroup doom-lcars-theme nil
  "Options for the `doom-lcars' theme."
  :group 'doom-themes)

(defcustom doom-lcars-padded-modeline doom-themes-padded-modeline
  "If non-nil, adds a 4px padding to the mode-line.
Can be an integer to determine the exact padding."
  :group 'doom-lcars-theme
  :type '(choice integer boolean))


(defface doom-lcars-hugo-shortcode
  '((t :inherit font-lock-preprocessor-face))
  "Face for Hugo shortcodes in Org posts, used by writing/.dir-locals.el."
  :group 'doom-lcars-theme)


;;
;;; Theme definition

(def-doom-theme doom-lcars
  "A dark theme in the style of the Star Trek LCARS interface."

  ;; name        default   256           16
  ((bg         '("#000000" "black"       "black"        ))
   (fg         '("#FFCC99" "#ffd7af"     "brightwhite"  ))

   ;; bg-alt is used by solaire-mode for non-file buffers. Black cannot get
   ;; darker, so it is a hint lighter instead.
   (bg-alt     '("#0D0814" "#080808"     "black"        ))
   (fg-alt     '("#D9C8B4" "#d7d7af"     "white"        ))

   ;; A spectrum from black through the LCARS purples to bright white.
   (base0      '("#000000" "black"       "black"        ))
   (base1      '("#0D0814" "#080808"     "brightblack"  ))
   (base2      '("#1A1122" "#1c1c1c"     "brightblack"  ))
   (base3      '("#332244" "#303030"     "brightblack"  ))
   (base4      '("#553F6E" "#5f5f87"     "brightblack"  ))
   (base5      '("#8877AA" "#8787af"     "brightblack"  ))
   (base6      '("#9977AA" "#af87af"     "brightblack"  ))
   (base7      '("#B3A3C2" "#afafd7"     "brightblack"  ))
   (base8      '("#FFF0E0" "#ffffdf"     "white"        ))

   (grey       base4)
   (red        '("#DD5555" "#d75f5f"     "red"          ))
   (orange     '("#FF9900" "#ff8700"     "brightred"    ))
   (green      '("#99CC66" "#87af5f"     "green"        ))
   (teal       '("#66CCCC" "#5fafaf"     "brightgreen"  ))
   (yellow     '("#FFCC66" "#ffd75f"     "yellow"       ))
   (blue       '("#9999FF" "#8787ff"     "brightblue"   ))
   (dark-blue  '("#5555AA" "#5f5faf"     "blue"         ))
   (magenta    '("#CC99CC" "#d7afd7"     "brightmagenta"))
   (violet     '("#9977AA" "#af87af"     "magenta"      ))
   (cyan       '("#66CCCC" "#5fd7d7"     "brightcyan"   ))
   (dark-cyan  '("#3F8F8F" "#5f8787"     "cyan"         ))

   ;; Extra LCARS colours, used only in this theme.
   (rust       '("#CC6633" "#d75f00"     "red"          ))
   (bright-red '("#FF7777" "#ff8787"     "brightred"    ))

   ;; Universal syntax classes required by doom-themes-base.
   (highlight      orange)
   (vertical-bar   base3)
   (selection      (doom-blend orange bg 0.4))
   (builtin        magenta)
   (comments       base5)
   (doc-comments   (doom-lighten base5 0.2))
   (constants      cyan)
   (functions      yellow)
   (keywords       orange)
   (methods        yellow)
   (operators      fg-alt)
   (type           blue)
   (strings        green)
   (variables      fg)
   (numbers        cyan)
   (region         selection)
   (error          bright-red)
   (warning        yellow)
   (success        green)
   (vc-modified    blue)
   (vc-added       green)
   (vc-deleted     red)

   ;; Mode-line: an orange LCARS bar with black text when active, violet when
   ;; inactive. The ml-* colours are dark tints that stay readable on orange.
   (modeline-bg          orange)
   (modeline-fg          bg)
   (modeline-bg-inactive violet)
   (modeline-fg-inactive bg)
   (ml-muted             base3)
   (ml-green             (doom-darken green 0.65))
   (ml-red               (doom-darken red 0.5))
   (ml-blue              (doom-darken dark-blue 0.4))
   (ml-violet            (doom-darken violet 0.5))
   (ml-cyan              (doom-darken dark-cyan 0.5))
   (ml-rust              (doom-darken rust 0.5))

   (-modeline-pad
    (when doom-lcars-padded-modeline
      (if (integerp doom-lcars-padded-modeline) doom-lcars-padded-modeline 4))))


  ;;;; Base theme face overrides
  ((cursor :background orange)
   (hl-line :background base2 :extend t)
   ((line-number &override) :foreground base5)
   ((line-number-current-line &override) :foreground orange)
   ((font-lock-comment-face &override) :slant 'italic)
   (link :foreground blue :underline t :weight 'bold)
   (lazy-highlight :background (doom-blend yellow bg 0.35) :foreground fg :weight 'bold)
   (isearch :background yellow :foreground bg :weight 'bold)
   (minibuffer-prompt :foreground orange :weight 'bold)

   ;;;; mode-line
   (mode-line
    :background modeline-bg :foreground modeline-fg
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (mode-line-inactive
    :background modeline-bg-inactive :foreground modeline-fg-inactive
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))
   (mode-line-emphasis :foreground bg :weight 'bold)
   (mode-line-highlight :background fg :foreground bg)
   (mode-line-buffer-id :foreground bg :weight 'bold)
   (header-line :background bg :foreground orange)

   ;;;; doom-modeline
   (doom-modeline-bar :background magenta)
   (doom-modeline-bar-inactive :background base3)
   (doom-modeline-buffer-path :foreground bg :weight 'bold)
   (doom-modeline-buffer-file :foreground bg :weight 'bold)
   (doom-modeline-buffer-modified :foreground ml-red :weight 'bold)
   (doom-modeline-buffer-major-mode :foreground bg :weight 'bold)
   (doom-modeline-buffer-minor-mode :foreground ml-muted)
   (doom-modeline-project-dir :foreground bg :weight 'bold)
   (doom-modeline-project-parent-dir :foreground ml-muted :weight 'bold)
   (doom-modeline-project-root-dir :foreground bg :weight 'bold)
   (doom-modeline-info :foreground ml-green :weight 'bold)
   (doom-modeline-warning :foreground ml-rust :weight 'bold)
   (doom-modeline-urgent :foreground ml-red :weight 'bold)
   (doom-modeline-notification :foreground ml-red :weight 'bold)
   (doom-modeline-debug :foreground ml-muted :weight 'bold)
   (doom-modeline-host :foreground ml-muted :slant 'italic)
   (doom-modeline-input-method :foreground bg :weight 'bold)
   (doom-modeline-persp-name :foreground ml-muted :slant 'italic)
   (doom-modeline-time :foreground bg :weight 'bold)
   (doom-modeline-lsp-success :foreground ml-green)
   (doom-modeline-lsp-warning :foreground ml-rust)
   (doom-modeline-lsp-error :foreground ml-red)
   (doom-modeline-lsp-running :foreground ml-muted)
   (doom-modeline-repl-success :foreground ml-green)
   (doom-modeline-repl-warning :foreground ml-rust)
   (doom-modeline-battery-charging :foreground ml-green)
   (doom-modeline-battery-full :foreground ml-green)
   (doom-modeline-battery-normal :foreground bg)
   (doom-modeline-battery-warning :foreground ml-rust)
   (doom-modeline-battery-critical :foreground ml-red)
   (doom-modeline-battery-error :foreground ml-red)
   (doom-modeline-evil-normal-state :foreground bg :weight 'bold)
   (doom-modeline-evil-insert-state :foreground ml-blue :weight 'bold)
   (doom-modeline-evil-visual-state :foreground ml-violet :weight 'bold)
   (doom-modeline-evil-replace-state :foreground ml-red :weight 'bold)
   (doom-modeline-evil-motion-state :foreground ml-cyan :weight 'bold)
   (doom-modeline-evil-operator-state :foreground bg :weight 'bold)
   (doom-modeline-evil-emacs-state :foreground ml-muted :weight 'bold)

   ;;;; tabs
   (tab-line :background bg :foreground bg)
   (tab-line-tab :background orange :foreground bg)
   (tab-line-tab-current :background orange :foreground bg)
   (tab-line-tab-inactive :background violet :foreground bg)
   (tab-line-highlight :background magenta :foreground bg)
   (tab-bar :background bg :foreground bg)
   (tab-bar-tab :background orange :foreground bg)
   (tab-bar-tab-inactive :background violet :foreground bg)
   (centaur-tabs-default :background bg :foreground bg)
   (centaur-tabs-selected :background orange :foreground bg)
   (centaur-tabs-unselected :background violet :foreground bg)
   (centaur-tabs-selected-modified :background orange :foreground ml-red)
   (centaur-tabs-unselected-modified :background violet :foreground ml-red)
   (centaur-tabs-active-bar-face :background magenta)

   ;;;; writing/.dir-locals.el
   (doom-lcars-hugo-shortcode :foreground violet :slant 'italic)

   ;;;; doom-dashboard
   (doom-dashboard-banner :foreground orange)
   (doom-dashboard-menu-title :foreground magenta)
   (doom-dashboard-menu-desc :foreground fg-alt)
   (doom-dashboard-footer-icon :foreground orange)
   (doom-dashboard-loaded :foreground base5)

   ;;;; magit
   (magit-section-heading :foreground orange :weight 'bold :extend t)
   (magit-header-line :background violet :foreground bg :weight 'bold
                      :box `(:line-width 3 :color ,violet))

   ;;;; markdown-mode
   (markdown-markup-face :foreground base5)
   (markdown-header-face :inherit 'bold :foreground orange)
   ((markdown-code-face &override) :background base2)

   ;;;; neotree
   (neo-root-dir-face :foreground orange :background bg :box `(:line-width 4 :color ,bg))

   ;;;; org-mode / outline
   (outline-1 :foreground orange  :weight 'bold :extend t)
   (outline-2 :foreground magenta :weight 'bold :extend t)
   (outline-3 :foreground blue    :weight 'bold :extend t)
   (outline-4 :foreground teal    :weight 'bold :extend t)
   (outline-5 :foreground yellow  :weight 'bold :extend t)
   (outline-6 :foreground violet  :weight 'bold :extend t)
   (outline-7 :foreground green   :weight 'bold :extend t)
   (outline-8 :foreground fg-alt  :weight 'bold :extend t)
   (org-document-title :foreground orange :weight 'bold)

   ;;;; rainbow-delimiters
   (rainbow-delimiters-depth-1-face :foreground orange)
   (rainbow-delimiters-depth-2-face :foreground magenta)
   (rainbow-delimiters-depth-3-face :foreground blue)
   (rainbow-delimiters-depth-4-face :foreground teal)
   (rainbow-delimiters-depth-5-face :foreground yellow)
   (rainbow-delimiters-depth-6-face :foreground green)
   (rainbow-delimiters-depth-7-face :foreground orange)
   (rainbow-delimiters-depth-8-face :foreground magenta)
   (rainbow-delimiters-depth-9-face :foreground blue)

   ;;;; solaire-mode
   (solaire-mode-line-face
    :inherit 'mode-line
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg)))
   (solaire-mode-line-inactive-face
    :inherit 'mode-line-inactive
    :box (if -modeline-pad `(:line-width ,-modeline-pad :color ,modeline-bg-inactive)))

   ;;;; terminal colours, matching the kitty and foot targets
   (ansi-color-black          :foreground base3   :background base3)
   (ansi-color-red            :foreground red     :background red)
   (ansi-color-green          :foreground green   :background green)
   (ansi-color-yellow         :foreground orange  :background orange)
   (ansi-color-blue           :foreground blue    :background blue)
   (ansi-color-magenta        :foreground magenta :background magenta)
   (ansi-color-cyan           :foreground cyan    :background cyan)
   (ansi-color-white          :foreground fg-alt  :background fg-alt)
   (ansi-color-bright-black   :foreground base5   :background base5)
   (ansi-color-bright-red     :foreground "#FF7777" :background "#FF7777")
   (ansi-color-bright-green   :foreground "#BBDD88" :background "#BBDD88")
   (ansi-color-bright-yellow  :foreground yellow  :background yellow)
   (ansi-color-bright-blue    :foreground "#BBBBFF" :background "#BBBBFF")
   (ansi-color-bright-magenta :foreground "#EEBBEE" :background "#EEBBEE")
   (ansi-color-bright-cyan    :foreground "#99DDDD" :background "#99DDDD")
   (ansi-color-bright-white   :foreground base8   :background base8)
   (term-color-black   :foreground base3   :background base5)
   (term-color-red     :foreground red     :background "#FF7777")
   (term-color-green   :foreground green   :background "#BBDD88")
   (term-color-yellow  :foreground orange  :background yellow)
   (term-color-blue    :foreground blue    :background "#BBBBFF")
   (term-color-magenta :foreground magenta :background "#EEBBEE")
   (term-color-cyan    :foreground cyan    :background "#99DDDD")
   (term-color-white   :foreground fg-alt  :background base8)
   (vterm-color-black   :foreground base3   :background base5)
   (vterm-color-red     :foreground red     :background "#FF7777")
   (vterm-color-green   :foreground green   :background "#BBDD88")
   (vterm-color-yellow  :foreground orange  :background yellow)
   (vterm-color-blue    :foreground blue    :background "#BBBBFF")
   (vterm-color-magenta :foreground magenta :background "#EEBBEE")
   (vterm-color-cyan    :foreground cyan    :background "#99DDDD")
   (vterm-color-white   :foreground fg-alt  :background base8))

  ;;;; Base theme variable overrides
  ())

;;; doom-lcars-theme.el ends here
