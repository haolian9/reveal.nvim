
## goals
* vifm daemon
* showing vifm via nvim's terminal+floatwin
* opening files in nvim
* opinionated settings

## non-goals
* fancy TUI on nvim side
* all the features of vifm.vim
* nerdtree like

## status: just-work
* it uses lua ffi which may crash nvim (though i havent met yet)
* no new features are planned
* custom settings for keymaps, window style, vifm cmd would complicate the
  code, please consider forking it

## prerequisites:
* linux
* nvim 0.8.0
* vifm master

## setup
* add it to your nvim plugin manager
* `$ make link-vifm-plugin`

## usage
* `:lua require'reveal'()`

## default settings
keymaps for vifm
* `n <cr>`  -> `:e`
* `n <c-o>` -> `:sp`
* `n <c-/>` -> `:vs`
* `n <c-t>` -> `:tabe`

keymaps for nvim terminal-buffer
* `n q`, `n <esc>`, `n <c-[>`, `n <c-]>` -> hide the terminal-buffer
