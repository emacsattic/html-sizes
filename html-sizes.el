;;; html-sizes.el --- maintain file sizes shown for html links

;; Copyright 2007 Kevin Ryde
;;
;; Author: Kevin Ryde <user42@zip.com.au>
;; Version: 1
;; Keywords: convenience, hypermedia
;; URL: http://www.geocities.com/user42_kevin/html-sizes/index.html
;; EmacsWiki: HtmlMode
;;
;; html-sizes.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; html-sizes.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
;; Public License for more details.
;;
;; You can get a copy of the GNU General Public License online at
;; <http://www.gnu.org/licenses/>.


;;; Commentary:

;; This is a spot of code offering an `M-x html-sizes-update' to update file
;; sizes shown in a HTML web page (based on local file sizes).  See the
;; docstring below for more.

;;; Install:

;; Put html-sizes.el somewhere in your `load-path', and in your .emacs put
;;
;;     (autoload 'html-sizes-update "html-sizes" nil t)
;;
;; There's an autoload cookie for this below, if you use
;; `update-file-autoloads' and friends.

;;; Emacsen:

;; Designed for Emacs 21 and 22.  Doesn't work in XEmacs 21 due to
;; process-replace taking fewer arguments.

;;; History:

;; Version 1 - the first version.


;;; Code:

(defcustom html-sizes-update-query t
  "Whether `html-sizes-update' should ask before changing the buffer."
  :type  'boolean
  ;; chucked in the sgml group, along with `html-mode-hook', for want of
  ;; somewhere better
  :group 'sgml
  :link  '(url-link
           :tag "html-sizes home page"
           "http://www.geocities.com/user42_kevin/html-sizes/index.html"))

;;;###autoload
(defun html-sizes-update ()
  "Update file sizes shown for downloadable links in HTML source.
In a web page you might have a download like

    <a href=\"foo.tar.gz\">foo.tar.gz</a> (64k, gzipped tar)
or
    <a href=\"bar.txt\">bar.txt</a> (text, 8k)

showing how big the link target is.  `html-sizes-update' updates
that \"64k\" or \"8k\" size, based on your local files.  This is
good when updating the page to offer versions.

Changes are queried, to make it clear what's being done.
Customize `html-sizes-update-query' to run without querying.
\(`diff-backup' or `vc-diff' can be used in the check what's
changed of course.)

If there's no local file it's counted as a \"missing\" in the
message at the end, so pay attention to that if something doesn't
seem to update.

Only a link style like the href above followed by \"(...123k...\"
in parens is recognised, and only with \"k\" for kilobytes.
\(Perhaps in the future that can be controlled within the
document.)"

  (interactive)
  (let ((total   0)
        (differ  0)
        (missing 0)
        (quit    nil))
    (save-excursion
      (goto-char (point-min))
      (while (and (not quit)
                  (re-search-forward "<a\\s-+href=\"\\([^\"\n]+\\)\">\\(.\\|\n\\)*?</a>" nil t))
        (let ((filename (match-string 1)))
          (and (not (string-match "\\`[a-z]:" filename)) ;; no http: etc links
               (looking-at "[ \t\r\n]*([^<)]*?\\([0-9]+\\)+k") ;; "(..123k...)"
               (let* ((got   (string-to-number (match-string 1)))
                      (attrs (file-attributes (file-truename filename)))
                      (want  (if attrs
                                 ;; size in kilobytes rounded up
                                 (/ (+ (nth 7 attrs) 999) 1000)
                               ;; file not found
                               (setq missing (1+ missing))
                               got)))

                 (setq total (1+ total))
                 (unless (= got want)
                   (setq differ (1+ differ))

                   ;; `perform-replace' returns nil if the user says "q" to
                   ;; quit
                   (or (perform-replace (match-string 1)         ;; old text
                                        (number-to-string want)  ;; new text
                                        html-sizes-update-query
                                        nil  ;; not a regexp
                                        nil  ;; don't demand word boundary
                                        nil  ;; no repeat-count business
                                        nil  ;; standard keymap
                                        (match-beginning 1) ;; only this
                                        (match-end 1))      ;; single change
                       (goto-char (point-max)))))))))

    (message "Total %d file sizes, %d differed, %d missing"
             total differ missing)))

(provide 'html-sizes-update)

;;; html-sizes.el ends here
