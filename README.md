# ~~Everhorn~~ ~~newlestehorn~~ Everhorn-EXT

**~~Everhorn~~ newlestehorn** is a map editor for the newleste.p8 project. It's a newleste.p8-specific version of Everhorn with UI improvements and all-new Camera Trigger support by @gonengazit!

![Screenshot from 2021-12-07 14-35-25](https://user-images.githubusercontent.com/25254726/145023068-cea6301a-df82-4e93-99b4-252b6af9b657.png)

# How it works

Carts from the newleste.p8 repository have already been setup for you, this is just for your information:

Everhorn is a room-based editor, like Ahorn. While it is able to open and save vanilla Celeste carts, splitting them into 16x16 rooms, its true power is revealed when using [Evercore](https://github.com/CelesteClassic/evercore), which is able to load maps from variables `levels` and `mapdata`, located in the second code tab. To get started with an *evercore*-based cart, you need to open up the code in it, find the place where `levels` and `mapdata` are defined and surround them in `--@begin` and `--@end` comments like this:

```lua
--@begin
levels={
  ...
}

mapdata={
  ...
}

...
--@end
```

*Everhorn* will now be able to locate this section (*'Everhorn section'*) and **automatically** read `levels` and `mapdata` from it and write them back. Note that you can create as many rooms as you want, however, *Evercore* will actually load them into the normal PICO-8 map the moment you enter them. This means that you *must* place rooms within the boundaries of the map (shown as a grid), or you'll get fucky stuff (nothing permanent though, don't worry). However, you can simply stack rooms on top of each other and it will work fine.

Newlestehorn 1.1 introduced an additional @conf block that will be added automatically before @begin; this block contains commented code (not visible to the running cart) that newlestehorn uses to store project settings, such as autotile tilesets and room parameter names.

# Install

Go to the Releases section at the top of the page.

# Usage

* **Ctrl+O** - **Open** a .p8 cart file (loads rooms and the spritesheet).
* **Ctrl+S**, **Ctrl+Shift+S** - **Save/Save As**.
* **Ctrl+R** - **reload** the spritesheet from the currently opened cart.
* **Ctrl+Z**, **Ctrl+Shift+Z** - **Undo/Redo**. Can undo pretty much anything (including something like deleting a room).
* **Middle click** or  **Shift+Left click** pans camera, **Scroll** zooms in/out.
* **Shift + Right Click** selects a tile from the map
* **N** - **create** new room.
* **Alt+Left/Right Mouse Button** - **move** and **resize** rooms.
* **Up/Down, Ctrl+Up/Down** - **switch** between rooms and **reorder** them (can also click to switch).
* **Shift+Delete** - **delete** room.
* **Ctrl+Shift+C** - **copy** the entire room (it's text-based, so you can send it to someone directly).
* **Space** shows/hides the **tool panel** with the tools and the tileset. The tileset also includes 3 **autotiles**, which will automatically pick the right version of the tile based on it's neighbors, both when drawing and erasing. They are defined to match vanilla snow, ice, and dirt (you can put any other sprites instead, of course, and I can define more if needed).
* * **Brush** - **left click** to paint with the tile, **right click** to erase (tile 0)
* * **Rectangle** - same but in rectangles.
* * **Select** - basic selection tool, click and drag to select a rectangle, then you can move it, place it, copy or cut it with **Ctrl+C**, **Ctrl+X** and paste with **Ctrl+V**.
* * **Camera Trigger** - tool for adding, moving and resizing n.p8 camera triggers. Use **Ctrl+Left/Right Mouse Button** to move/resize.
* * **Room** - currently allows setting room exits and whether the room is stored in code inside a string, or in mapdata.
* * **Project** - allows adding/removing level parameters, and configuring whether string levels are saved in base256 or hex format (defaults to whichever the cart uses, or base256 if the cart has no string levels)
* **Tab** toggles **playtesting mode**. When it's enabled, saving a cart will also inject a line of code that spawns you right in the current room and disables music. (conveniently, in PICO-8 you can press **Ctrl+R** to restart the cart and it will reload the map as well!). Press Tab again to enable **2 dashes**.
* **CTRL+H** - shows/hides **garbage tiles** on the tool panel
* **CTRL+T** - shows/hides **camera triggers** when not using the dedicated tool
* **1, 2, 3, 4, 5** - switch to the nth tool
