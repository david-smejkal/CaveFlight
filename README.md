# CaveFlight
Simple flight simulator in a randomly generated environment.
Written in Assembly, utilizes OpenGL.
![CaveFlight screenshot](https://smejkal.software/img/caveflight_scr2.jpg)

## Controls
```
Esc      - Ends the game
P        - Pauses the game
SpaceBar - Accelerates upwards
```

## Project Assignment
Make a simple game in assemly language with help of win32api and opengl. You have nasmGL.exe (modified to allow usage of real constants) to your disposal.

## Design
Game CaveFlight takes place in a randomly generated cave environment. Gravity of `1g` pulls the ship naturally downwards. Spacebar affects the movement in the opposite direction with acceleration of `-2g`. For simplicity we will add these two accelerations together and as such only need to deal with `-1g` when accelerating upwards.

Cave, ship, text outputs (score, velocity, etc.) and everything else is rendered by OpenGL.

Collisions are handled with OpenGL using a stencil buffer technique (more details below).

## Implementation

### Libraries
- kernel32.dll - functions that allow working with kernel such as `ExitProcess()`, `Sleep()`, etc.
- user32.dll - win32api, creation of the window, handling of the window, etc.
- advapi32.dll - extended api functions, also used for generating random numbers
- gdi32.dll - `ChoosePixelFormat()`, `SetPixelFormat()`
- opengl32.dll - `glOrtho()` for mapping of the window boundaries
- glut32.dll - drawing of text, `glutBitmapCharacter()`
- msvcrt.dll - standard C functions, `sprintf()`
- winmm.dll - `timeGetTime()` function to return system time, basis for movement in the game

### Movement
Frames per second (fps) is what's utilized as the basis for movment in the game.
By calling `timeGetTime()` in every frame and by comparing that acquired value with the time acquired in the previous frame we can calculate the time delta that's then used to calculate movement of objects.

```
  ; calculating time between two frames
  invoke timeGetTime ; fills eax with itme in ms
  mov [dwCurMoveTime], eax
  fild dword [dwCurMoveTime]
  fisub dword [dwLastMoveTime]
  fmul dword [dwTimeFactor] ; converts time from ms to s
  fstp dword [dwTimeSpan]
  mov eax, dword [dwCurMoveTime]
  mov [dwLastMoveTime], eax
```

### Collisions
Handling of collisions is done using OpenGL and as such doesn't require complex geometric math that would otherwise require considerably more CPU power.
The actual implementation is achieved by drawing relevant objects into the stencil buffer and by subsequent reading of the stencil buffer to detect collisions.

```
  invoke glClearStencil, 1 ; set stencil buffer to 1
  
  ; draw the inside of a cave (-1)
  invoke glStencilFunc, GL_ALWAYS, 1, 3
  invoke glStencilOp, GL_KEEP, GL_KEEP, GL_DECR
```

```
  ; draw the ship (+1)
  invoke glStencilFunc, GL_ALWAYS, 1, 3
  invoke glStencilOp, GL_KEEP, GL_KEEP, GL_INCR
```

Doing the above results in solid objects represented by `1`, free space by `0` and collisions by `2` in OpenGL's stencil buffer.
By calling `glReadPixels()` around the ship we can eficiently check for any `2` occurrences in the stencil buffer to detect a collision.
When that happens we can then call `InitGame` to reset the game back into its initial state.

## Conclusion
The game can be further enhanced with various graphical textures and by adding more objects to the environment. Adding more objects shouldn't be too difficult because as long as they are also added to the stencil buffer they will automatically become collidable.