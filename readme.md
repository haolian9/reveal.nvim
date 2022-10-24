
## why:
* vifm is my true love on browsing and manipulating files:
* the existed file browsers/managers in nvim world are not my type
    * dirvish, fzf can not manipulate file
    * nerdtree is written by vimscript, i dont kown vimscript
    * for the others, well, i have not gave them a try

## goals
* vifm daemon
* showing vifm via nvim's terminal+floatwin
* opening files in nvim

## non-goals
* fancy TUI on nvim side
* all the features of vifm.vim

## status: experimental, crash-prone
* it uses ffi for FIFO nonblocking reads
* there are some uncovered edge cases on vifm side plugin

## prerequisites:
* linux
* nvim 0.8.0
* vifm 0.12.1

## setup
* add this plugin to your nvim plugin manager
* `$ make link-vifm-plugin`

## usage
* `:lua require'reveal'()`

## todo:
* [x] `filetype *` handler
    * [x] basic open operation
    * [x] no footprints on vifminfo 
    * [ ] `:vs`, `:tabe` ...
    * [ ] handle multiple selections
    * [ ] handle all errors happened on vifm side to prevent vifm fallbacking to the default opener
* [ ] `vicmd` handler
* [ ] ~`fileviewer *` handler~
* [ ] settings
    * [ ] ~cmd to launch vifm~
    * [ ] ~float window size, position, style ...~
