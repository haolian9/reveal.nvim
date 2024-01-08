an example to integrate vifm into nvim which utilizes lua API of both

## features/limits
* run vifm in a terminal buffer + floating window
* communicate between vifm and nvim via pipe
* able to handle vifm fsop events
* opinionated settings

## status: just-work
* it uses ffi which may crash nvim
* no settings are changeable

## prerequisites:
* linux
* nvim 0.9.*
* vifm 0.12 and above

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
* `mv a b`   -> rename nvim buffer if any
* `mv a/ b/` -> rename nvim buffers under dir a if any
* `rm a`     -> no-op
* `trash a`  -> no-op

## non-goals
* all the features of vifm.vim
* nerdtree like

