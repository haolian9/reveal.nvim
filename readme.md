
## goals
* running vifm in nvim's float window
* daemonized vifm
* opinionated settings
* minimal codebase
* optional handling partial vifm fsop events

## status: just-work
* it uses luajit's ffi lib which may crash nvim
* no custom settings for keymap, window style, vifm cmd ...

## prerequisites:
* linux
* nvim 0.8.*
* vifm master

## usage
* `:lua require'reveal'()`

## opinionated settings
keymaps for vifm
* `n <cr>`  -> `:e`
* `n <c-o>` -> `:sp`
* `n <c-/>` -> `:vs`
* `n <c-t>` -> `:tabe`

keymaps for nvim terminal-buffer
* `n q`, `n <esc>`, `n <c-[>`, `n <c-]>` -> hide the terminal-buffer

handling filesystem changes happened on vifm side
* `mv a b`   -> rename the corresponding nvim buffer
* `mv a/ b/` -> rename the corresponding nvim buffers under directory a
* `rm a`     -> no-op
* `trash a`  -> no-op

## non-goals
* fancy TUI on nvim side
* all the features of vifm.vim
* nerdtree like

