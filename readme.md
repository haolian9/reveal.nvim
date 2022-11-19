
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
* vifm 0.12.1

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

## todo:
* [x] `filetype *` handler
    * [x] basic open operation
    * [x] `:vs`, `:tabe` ...
    * [x] no footprints on vifminfo 
    * [ ] ~handle multiple selections~
    * [x] handle possible errors on vifm side
* [ ] ~`vicmd` handler~
* [ ] ~`fileviewer *` handler~
* [ ] custom settings
    * [ ] ~cmd to launch vifm~
    * [ ] ~float window size, position, style ...~
