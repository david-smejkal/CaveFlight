# CaveFlight
Simple flight simulator in a randomly generated environment. Written in assembly language using OpenGL.
![CaveFlight screenshot](https://smejkal.software/img/caveflight_scr2.jpg)

## Project Assignment
Make a simple game in assemly language with help of win32api and opengl. You have nasmGL.exe (modified for real constant usage) to your disposal.

## Design
Game CaveFlight will utilize a randomly generated cave environment. Gravitation of one g will affect the movement of the ship. Spacebar will affect the movement in opposite direction with momentum of two g. For simplicity we will add these two accelerations and as such only refer to the acceleration as -g (minues one g).

Cave, ship, outputs and everything else will be drawn by OpenGL.

Collisions are handled in OpenGL using a stencil buffer technique (more details below).

## Implementation

### Liraries
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
By calling `timeGetTime()` in every frame and by comparing its value returned in the previous frame we get back the time delta required to calculate movement of objects.

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
Handling of collisions is done using OpenGL which saves the app from doing complex geometrical mathematical functions using CPU.
The actual implementation is achieved by drawing relevant objects into stencil buffer and by subsequent scanning of the stencil buffer for collisions.

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

Doing the above we end up with a stencil buffer where solid objects are represented by `1`, free space by `0` and collisions by `2`.
By calling `glReadPixels()` around the ship we can eficiently check for any `2` occurrences in the stencil buffer to detect a collision.
When that happens we can then call `InitGame` to set the game back into the initial state.

## Controlls
Esc      - Ends the game
P        - Pauses the game
SpaceBar - Accelerates upwards

## Conclusion
We can further enhance the game using various textures and images and by adding more objects. We don't have to change the inner workings of the game because in order for these objects to be collidable all we would have to do is to draw them in the stencil buffer.