
## goals:
* open file in nvim
* browser/manipulate files in vifm

## status: experimental, crash-prone
* uses ffi for FIFO nonblocking read/write
* too much edge cases in vifm have not been covered properly

## prerequisites:
* nvim 0.8.0
* vifm 0.12.1

## todo:
* [x] openers
    * [x] basic open operation
    * [ ] able control how the file will be opened in nvim
    * [ ] handle any error to prevent vifm fallback to default opener
    * [ ] handle multiple selection
* [ ] viewer # not planned
* [ ] vicmd # not planned
