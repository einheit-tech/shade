# shade

2D Game Engine using sdl2

## Cloning shade

- `git clone git@github.com:avahe-kellenberger/shade.git`
- `git submodule update`


## Install dependencies

`nimble install -dy`

### Setting up sdl_gpu

## Examples

Run the two example games to make sure everything works on your system

## Running examples

`nimble example` or
`nim r examples/basic/basic_game.nim`

## Setting up local shade repo to be used in another project

1. `cd` into the shade repo
2. Run `nimble develop`

"The develop command allows you to link an existing copy of a package into your installation directory. This is so that when developing a package you don't need to keep reinstalling it for every single change."

See [the nimble docs](https://github.com/nim-lang/nimble#nimble-develop) for details.

