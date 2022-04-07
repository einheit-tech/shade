# shade

2D Game Engine using sdl2

## Clone and setup

1. Have Nim installed (preferably via [choosenim](https://github.com/dom96/choosenim#choosenim))

```shell
git clone https://github.com/avahe-kellenberger/shade.git
cd shade
nimble install -dy
nimble fetch_deps
```

## Examples

Run the two example games to make sure everything works on your system

## Running examples

Platformer:

`nimble platformer`

Physics:

`nimble physics`

Click on the screen when the game launches to spawn shapes

## Using shade for a game project

1. `nimble install 'https://github.com/avahe-kellenberger/shade'`
2. Wherever you'd like your project: `shade --init projectname`
3. `cd projectname && nimble runr` to run the example

