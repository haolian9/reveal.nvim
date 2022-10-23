
## goals:
* opening files in nvim
* browsering and manipulating files in vifm

## status: experimental, crash-prone
* it uses ffi for FIFO nonblocking read/write
* there are some edge cases on vifm side that have not been covered properly

## prerequisites:
* linux # due to the use of named pipe and `/`
* nvim 0.8.0
* vifm 0.12.1

## setup
* add this plugin via your nvim plugin manager
* `$ make link-vifm-plugin`

## usage
* `:lua require'reveal'()`

## todo:
* [x] `filetype *` handler
    * [x] basic open operation
    * [x] custom cmd to launch vifm
    * [ ] handle multiple selections
    * [ ] define how the selected file will be opend in nvim (`:vs`, `:tabe` ...)
    * [ ] handle all errors happened to prevent vifm fallbacking to the default opener
* ~[ ] `fileviewer *` handler~
* ~[ ] `vicmd` handler~
