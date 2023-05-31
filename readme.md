just an simple **example** shows how to use a vifm daemon in nvim

https://user-images.githubusercontent.com/6236829/238663010-45748118-6650-4500-bff0-1abfa341c94f.mp4

## goals/limits
* running vifm in a nvim float window
* daemonized vifm
* opinionated settings
* minimal codebase
* handling partial vifm fsop events

## non-goals
* fancy TUI on nvim side
* all the features of vifm.vim
* nerdtree like
* no custom settings for keymap, window style, vifm cmd ...

## status
* it just works on my machine (tm)
* it uses luajit's ffi lib which may crash nvim
* it is kind of feature freezed
* the handling of vifm fsop events is experimental, which has not been tested against complex usecases.

## how does it work?
* this plugin has two parts: one for nvim, the other for vifm
* the two parts use a named pipe to communicate with each other use a simple 'protocol' implemented in `reveal.opstr_iter`.
* the vifm part is a lua plugin of vifm which will:
    * register necessary handlers, commands, keymaps
    * subscribe filesystem events
    * send commands to the pipe
* the nvim part is also a lua plugin but for nvim, which will:
    * spawn a vifm daemon
    * show the daemon in a float window
    * poll and enqueue commands from the pipe, process them when user leaved the vifm 

## prerequisites:
* linux
* nvim 0.9.*
* vifm 0.13
* haolian9/infra.nvim

## usage
* `:lua require'reveal'()`

## opinionated settings
keymaps (lhs=vifm, rhs=nvim)
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
