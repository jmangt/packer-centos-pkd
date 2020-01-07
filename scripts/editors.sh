#!/bin/bash
set -e

sudo yum install tmux emacs tree -y

# Configure Emacs
mkdir -p /home/vagrant/.emacs.d/
cat <<EOF > /home/vagrant/.emacs.d/init.el
(set-keyboard-coding-system nil)

;; initialize environment variables including PATH
(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))

;; enable ido mode
(require 'ido)
(ido-mode t)

;; enable melpa package repository
(require 'package)
(add-to-list 'package-archives '("melpa" . "http://melpa.org/packages/"))
EOF