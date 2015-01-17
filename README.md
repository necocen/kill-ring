# kill-ring
An emacs-like kill-ring package.

## features
* mark and region
* kill and yank

## keybindings
|key          |command                          |
|:------------|:--------------------------------|
|ctrl-space   |kill-ring:set-mark               |
|ctrl-w       |kill-ring:kill-region            |
|alt-w        |kill-ring:copy-region-as-kill    |
|ctrl-k       |kill-ring:kill-line              |
|ctrl-y       |kill-ring:yank                   |
|alt-y        |kill-ring:yank-pop               |
|ctrl-x ctrl-x|kill-ring:exchange-point-and-mark|

## (far) future plan
* add test
* work well with clipboard
* kill-ring saving (serialize)

## License
MIT
