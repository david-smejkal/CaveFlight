;*******************************************************************************
; nasmGL.exe -fobj CaveFlight.asm & ALINK.EXE -oPE -subsys gui -o CaveFlight.exe CaveFlight.obj & CaveFlight.exe
;*******************************************************************************
%include 'win32n.inc'
%include 'general.mac'
%include 'opengl.inc'
;*******************************************************************************
; Functionse from library: kernel32.dll
dllimport GetModuleHandle, kernel32.dll, GetModuleHandleA
dllimport GetCommandLine, kernel32.dll, GetCommandLineA
dllimport GetSystemTime, kernel32.dll
dllimport ExitProcess, kernel32.dll
dllimport GetLastError, kernel32.dll
dllimport Sleep, kernel32.dll
;*******************************************************************************
; Functionse from library: user32.dll
dllimport RegisterClassEx, user32.dll, RegisterClassExA
dllimport CreateWindowEx, user32.dll, CreateWindowExA
dllimport ShowWindow, user32.dll
dllimport UpdateWindow, user32.dll
dllimport TranslateMessage, user32.dll
dllimport DispatchMessage, user32.dll, DispatchMessageA
dllimport GetMessage, user32.dll, GetMessageA
dllimport PeekMessage, user32.dll, PeekMessageA
dllimport PostQuitMessage, user32.dll
dllimport DefWindowProc, user32.dll, DefWindowProcA
dllimport MessageBox, user32.dll, MessageBoxA
dllimport LoadIcon, user32.dll, LoadIconA
dllimport LoadCursor, user32.dll, LoadCursorA
dllimport SetCursor, user32.dll
dllimport GetDC, user32.dll
dllimport ReleaseDC, user32.dll
; dllimport SetTimer, user32.dll
; dllimport KillTimer, user32.dll
dllimport BeginPaint, user32.dll
dllimport EndPaint, user32.dll
; dllimport wsprintf, user32.dll, wsprintfA
;*******************************************************************************
; Functionse from library: advapi32.dll
; dllimport CryptAcquireContext, advapi32.dll, CryptAcquireContextA
; dllimport CryptGenRandom, advapi32.dll
dllimport RtlGenRandom, advapi32.dll, SystemFunction036
;*******************************************************************************
; Functionse from library: gdi32.dll
dllimport SwapBuffers, gdi32.dll
dllimport ChoosePixelFormat, gdi32.dll
dllimport SetPixelFormat, gdi32.dll
dllimport GetStockObject, gdi32.dll
dllimport TextOut, gdi32.dll, TextOutA
dllimport SetBkMode, gdi32.dll
dllimport SetTextColor, gdi32.dll
;*******************************************************************************
; Functionse from library: glu32.dll
; dllimport gluPerspective, glu32.dll
;*******************************************************************************
; Functionse from library: opengl32.dll
dllimport glOrtho, opengl32.dll
;*******************************************************************************
; Functionse from library: glut32.dll
dllimport glutBitmapCharacter, glut32.dll
dllimport glutGet, glut32.dll
;*******************************************************************************
; Functionse from library: MSVCRT.DLL
dllimport sprintf, msvcrt.dll
;*******************************************************************************
; Functionse from library: winmm.dll
dllimport timeGetTime, winmm.dll
; Makra

%macro invoke 1-*
  %if %0 > 1
    %rep %0-1
      %rotate -1
      %pushparam dword %1
    %endrep
    %rotate -1
  %endif
  call [%1]
%endmacro

%macro call 1-*
  %if %0 > 1
    %rep %0-1
      %rotate -1
      %pushparam dword %1
    %endrep
    %rotate -1
  %endif
  call %1
%endmacro

;*******************************************************************************
[section .data use32 class=data align=16]

  string szWndClassName, "Assembler Game Class"
  string szWndCaption, "CaveFlight"

  string sVelocity, "Velocity: %+0.1f"
  string sFloat, "%f"
  string sUnsignedLong, "%lu"
  string sPosX, "PosX: %+0.1f"
  string sPosY, "PosY: %+0.1f"
  string sSpeed, "Speed: %+0.1f"
  string sScore, "Score: %lu"
  string sBestScore, "Best score: %lu"

  hInstance     dd 0
  hWnd          dd 0
  hDC           dd 0
  hRC           dd 0
  
  Message:      resb MSG_size
  
  dwWndWidth      dd 1020
  dwWndHeight     dd 440
  dwWndHalfHeight dd 250

  dwTimeFactor   dd 0.005
  
  dwLastMoveTime dd 0
  dwCurMoveTime  dd 0
  dwTimeSpan     dd 0.0

  dwMsgLoopTimeCount   dd 10 ; 1000/dwMsgLoopTimeCount=fps ; 40 = 25fps
  dwMsgLoopCurTime     dd 0
  dwMsgLoopNextTime    dd 0
  dwMsgLoopMoveFlag    dd 0

  ; <GameSettings>
    dwPause        dd 1     ; Starting state of game (0 - unpaused, 1 - paused)
    dwScore        dd 0
    dwBestScore    dd 0
    dwPosX         dd 100.0 ; Starting X position of CaveShip
    dwPosY         dd 0.0   ; Starting Y position of CaveShip
    dwAreaW        dd 10 ; width of area around caveship 
                         ; that will be tested for collision from stencil buffer
    dwAreaH        dd 10 ; height of area around caveship 
                         ; that will be tested for collision from stencil buffer
  
    dwMainJetAcc   dd 10.0  
    dwAuxJetAcc    dd 40.0
    dwGravityDec   dd -10.0
    dwAuxJetDec    dd -40.0
  
    dwImmAccDecNormal  dd -10.0 ; Starting acceleration/deceleration (main jet)
    dwImmAccDecSpecial dd -40.0 ; Starting acc/dec (auxiliary jets)
  
    dwImmAccDec        dd 0.0 ; immediate acceleration/deceleration
    dwVelocity         dd 0.0  
  
    dwCaveSpeed    dd -20.0 ; cave speed (pixels/sec)
    dwPointSpacing dd 30 ; distance between two points
    
    dwCavePosX       dd -1.0
  ; <\GameSettings>

  dwCavePosXTemp   dd -1.0
  dwCavePosYTop    dd 0
  dwCavePosYBottom dd 0

  dwBuffer:     resb 32 ; used in Rand() function
  sOutput:      resb 32 ; used in PrintStr() function

  wCollisionBuffer:     resb 10000 ; works up to 100x100 pixel rectangle
  string sTesting, "Start:" ; for debuging of dwCaveQueue
  dbStart       db 62 ; '>' ; for debuging of dwCaveQueue 
  dwCaveQueue:  times 64 dd 0 ; 1st dw: cave-bottom <-200;-100>
                                ; 2nd dw: cave-top <100;200>
                                ; 3rd dw: barrier-top <-100;200>
                                ; 4th dw: unasigned yet
                                ; 4096 bytes         
  dbEnd         db 60 ; '<' ; for debuging of dwCaveQueue     

  ; Queue data    
  dwQueueBeg    dd 0
  dwQueueEnd    dd 0
  dwQueueLen    dd 0
  dwQueueWEnd   dd 0
  dwQueueMax    dd 64
  dwQueueLast   dd 256
  dwQueueRead   dd 0
  dwPointsNew   dd 0
  dwPoints      dd 0

  ; Variables for temporary usage
  dwTemp        dd 0
  wTemp         dw 0
  dwLoop        dd 0
  dwLoopLen     dd 0
  dwFlag        dd 0

  ; Other variables
  wKeyTest      dd 0

  WndClass:
    istruc WNDCLASSEX
      at WNDCLASSEX.cbSize,           dd  WNDCLASSEX_size
      at WNDCLASSEX.style,            dd  CS_VREDRAW + CS_HREDRAW + CS_OWNDC
      at WNDCLASSEX.lpfnWndProc,      dd  WndProc
      at WNDCLASSEX.cbClsExtra,       dd  0
      at WNDCLASSEX.cbWndExtra,       dd  0
      at WNDCLASSEX.hInstance,        dd  NULL
      at WNDCLASSEX.hIcon,            dd  NULL
      at WNDCLASSEX.hCursor,          dd  NULL
      at WNDCLASSEX.hbrBackground,    dd  NULL
      at WNDCLASSEX.lpszMenuName,     dd  NULL
      at WNDCLASSEX.lpszClassName,    dd  szWndClassName
      at WNDCLASSEX.hIconSm,          dd  NULL
    iend

  PixelFormatDescriptor:
    istruc PIXELFORMATDESCRIPTOR
      at PIXELFORMATDESCRIPTOR.nSize,             dw  PIXELFORMATDESCRIPTOR_size
      at PIXELFORMATDESCRIPTOR.nVersion,          dw  1
      at PIXELFORMATDESCRIPTOR.dwFlags,           dd  PFD_DOUBLEBUFFER +\
                                                      PFD_DRAW_TO_WINDOW +\
                                                      PFD_SUPPORT_OPENGL
      at PIXELFORMATDESCRIPTOR.iPixelType,        db  PFD_TYPE_RGBA
      at PIXELFORMATDESCRIPTOR.cColorBits,        db  24
      at PIXELFORMATDESCRIPTOR.cRedBits,          db  0
      at PIXELFORMATDESCRIPTOR.cRedShift,         db  0
      at PIXELFORMATDESCRIPTOR.cGreenBits,        db  0
      at PIXELFORMATDESCRIPTOR.cGreenShift,       db  0
      at PIXELFORMATDESCRIPTOR.cBlueBits,         db  0
      at PIXELFORMATDESCRIPTOR.cBlueShift,        db  0
      at PIXELFORMATDESCRIPTOR.cAlphaBits,        db  0
      at PIXELFORMATDESCRIPTOR.cAlphaShift,       db  0
      at PIXELFORMATDESCRIPTOR.cAccumBits,        db  0
      at PIXELFORMATDESCRIPTOR.cAccumRedBits,     db  0
      at PIXELFORMATDESCRIPTOR.cAccumGreenBits,   db  0
      at PIXELFORMATDESCRIPTOR.cAccumBlueBits,    db  0
      at PIXELFORMATDESCRIPTOR.cAccumAlphaBits,   db  0
      at PIXELFORMATDESCRIPTOR.cDepthBits,        db  32
      at PIXELFORMATDESCRIPTOR.cStencilBits,      db  0
      at PIXELFORMATDESCRIPTOR.cAuxBuffers,       db  0
      at PIXELFORMATDESCRIPTOR.iLayerType,        db  PFD_MAIN_PLANE
      at PIXELFORMATDESCRIPTOR.bReserved,         db  0
      at PIXELFORMATDESCRIPTOR.dwLayerMask,       dd  0
      at PIXELFORMATDESCRIPTOR.dwVisibleMask,     dd  0
      at PIXELFORMATDESCRIPTOR.dwDamageMask,      dd  0
    iend

;   Rect:
;     istruc RECT
;       at RECT.left                    dd  0
;       at RECT.top                     dd  0
;       at RECT.right                   dd  0
;       at RECT.bottom                  dd  0
;     iend

  PaintStruct:
    istruc PAINTSTRUCT
      at PAINTSTRUCT.hdc,                          dd  hDC
      at PAINTSTRUCT.fErase,                       db  0
      at PAINTSTRUCT.rcPaint,                      dd  0, dwWndHeight, \
                                                       dwWndWidth, 0
      at PAINTSTRUCT.fRestore,                     db  0
      at PAINTSTRUCT.fIncUpdate,                   db  0
      at PAINTSTRUCT.rgbReserved,                  dw  0
    iend

  SystemTime:
    istruc SYSTEMTIME
      at SYSTEMTIME.wYear,                         dw  0
      at SYSTEMTIME.wMonth,                        dw  0
      at SYSTEMTIME.wDayOfWeek,                    dw  0
      at SYSTEMTIME.wDay,                          dw  0
      at SYSTEMTIME.wHour,                         dw  0
      at SYSTEMTIME.wMinute,                       dw  0
      at SYSTEMTIME.wSecond,                       dw  0
      at SYSTEMTIME.wMilliseconds,                 dw  0
    iend

;*******************************************************************************
[section .code use32 class=code]

..start:

  invoke GetModuleHandle, NULL
  mov [hInstance], eax
  mov [WndClass + WNDCLASSEX.hInstance], eax
  
  invoke LoadIcon, NULL, 32514
  mov [WndClass + WNDCLASSEX.hIcon], eax
  
  invoke RegisterClassEx, WndClass
  test eax, eax
  jz near .Finish
  
  invoke CreateWindowEx,\
    0,\
    szWndClassName, szWndCaption,\
    WS_CAPTION + WS_SYSMENU + WS_VISIBLE + WS_SIZEBOX + WS_MAXIMIZEBOX + WS_MINIMIZEBOX,\
    CW_USEDEFAULT, CW_USEDEFAULT,\
    [dwWndWidth], [dwWndHeight],\
    NULL, NULL, [hInstance], NULL
  test eax, eax
  jz near .Finish

  mov [hWnd], eax
  
  invoke ShowWindow, eax, SW_SHOWDEFAULT
  invoke UpdateWindow, [hWnd]

; Classic Message Loop
; .MessageLoop:
; 
;   invoke GetMessage, Message, NULL, 0, 0
;   test eax, eax
;   jz near .Finish
;   cmp eax, -1
;   jz near .Finish
;   
;   invoke TranslateMessage, Message
;   invoke DispatchMessage, Message
;   
;   call MoveObjects
;   call Render
;   
;   jmp .MessageLoop
; 
; .Finish:
;   invoke ExitProcess, [Message + MSG.wParam]

; Game Message Loop
.MessageLoop:
  invoke timeGetTime
  mov [dwMsgLoopNextTime], eax
  invoke PeekMessage, Message, NULL, 0, 0, PM_NOREMOVE
.msg_loop:
  cmp dword [Message + MSG.message], WM_QUIT
  jz near .Finish
  invoke PeekMessage, Message, NULL, 0, 0, PM_REMOVE
  test eax, eax
  jz near .NoMessage
  invoke TranslateMessage, Message
  invoke DispatchMessage, Message
  jmp .msg_loop

.NoMessage:
  cmp dword [dwMsgLoopNextTime], 1
  jne .NoMovement
    call MoveObjects
    mov dword [dwMsgLoopNextTime], 0
  .NoMovement:
  invoke timeGetTime
  mov [dwMsgLoopCurTime], eax
  cmp eax, dword [dwMsgLoopNextTime]
  jng .NoRendering
    invoke BeginPaint, [hWnd], PaintStruct
    call Render
    invoke EndPaint, [hWnd], PaintStruct
    mov eax, dword [dwMsgLoopTimeCount]
    add [dwMsgLoopNextTime], eax
    mov eax, dword [dwMsgLoopNextTime]
    cmp eax, dword [dwMsgLoopCurTime]
    jnl .NoDrop
      mov eax, dword [dwMsgLoopCurTime]
      add eax, dword [dwMsgLoopTimeCount]
      mov [dwMsgLoopNextTime], eax
      
  .NoDrop:
  mov dword [dwMsgLoopNextTime], 1
  .NoRendering:
  invoke Sleep, 5 ; if we don't sleep, loop would consume 100% CPU
  jmp .msg_loop

.Finish:
  invoke ExitProcess, [Message + MSG.wParam]
  
;*******************************************************************************
; WndProc - Window message service
function WndProc, hWnd, uMsg, wParam, lParam
begin

  mov eax, dword [uMsg]

  cmp eax, WM_DESTROY
  je near .Destroy
  cmp eax, WM_CLOSE
  je near .Destroy
  cmp eax, WM_PAINT
  je near .Paint
  cmp eax, WM_CHAR
  je near .Char
  cmp eax, WM_CREATE
  je near .Create
  cmp eax, WM_SIZE
  je near .Resize
  cmp eax, WM_MOUSEMOVE
  je near .MouseMove
  cmp eax, WM_SETICON
  je near .SetIcon
;   cmp eax, WM_TIMER
;   je near .Timer
;   cmp eax, WM_KEYDOWN
;   je near .KeyDown
  cmp eax, WM_KEYUP
  je near .KeyUp

  invoke DefWindowProc, [hWnd], [uMsg], [wParam], [lParam]
  return eax

.Create:
  invoke GetDC, [hWnd]
  mov [hDC], eax
  invoke ChoosePixelFormat, eax, PixelFormatDescriptor
  invoke SetPixelFormat, [hDC], eax, PixelFormatDescriptor
  invoke wglCreateContext, [hDC]
  mov [hRC], eax
  invoke wglMakeCurrent, [hDC], eax
;   invoke SetTimer, [hWnd], 1, 1000, NULL ; Score Timer
;   call PauseUnpause
  invoke timeGetTime
  mov [dwLastMoveTime], eax
  call InitGL
;   ; setting start position to half of window height
;   fild dword [dwWndHeight]
;   mov dword [dwTemp], 2
;   fidiv dword [dwTemp]
;   fstp dword [dwPosY]
  jmp .Finish

.Paint:
  invoke BeginPaint, [hWnd], PaintStruct
  call Render
  invoke EndPaint, [hWnd], PaintStruct
  jmp .Finish

.Char:
  mov ax, word [wParam]
  mov word [wKeyTest], ax
  cmp dword [wParam], VK_ESCAPE
  jz near .Destroy
  cmp dword [wParam], VK_SPACE
  jz near .SpaceBar
  cmp dword [wParam], 112 ; 'P'
  jz near .Pause
  jmp .Finish

.Resize:
  mov eax, [lParam]
  shr eax, 16
  mov dword [dwWndHeight], eax
  push eax
  mov eax, [lParam]
  and eax, 0x0000FFFF
  mov dword [dwWndWidth], eax
  push eax
  invoke glViewport, 0, 0
  call InitGL
  ; setting dwWndHalfHeight variable
  fild dword [dwWndHeight]
  mov dword [dwTemp], 2
  fidiv dword [dwTemp]
  fistp dword [dwWndHalfHeight]
  ; calculating number of points needed to paint the cave (width/10+3)
  fld dword [dwWndWidth]
  fidiv dword [dwPointSpacing]
  fstp dword [dwPoints]
  add dword [dwPoints], 3 ; 3 points more to ensure whole screen is covered
  ; do we need to add more points to queue?
  mov eax, dword [dwPoints]
  cmp eax, dword [dwQueueLen]
  jle .Resize_Nothing
  sub eax, dword [dwQueueLen]
  mov [dwLoop] , eax
  .Resize_LoopStart:
    mov ecx, dword [dwLoop]
    cmp ecx, 0
    jle .Resize_LoopEnd
    xor ebx, ebx
    call Rand, 10, 150 ; cave top
    mov ebx, eax
    shl ebx, 16
    call Rand, -150, -10 ; cave bottom
    and eax, 0x0000FFFF
    add ebx, eax
    call AddItem_Queue, ebx
    sub dword [dwLoop], 1
    jmp .Resize_LoopStart
  .Resize_LoopEnd:
  .Resize_Nothing:
  jmp .Finish

.MouseMove:
  ; set cursor to IDC_ARROW (32512)
  invoke LoadCursor, NULL, 32512
  invoke SetCursor, eax
  jmp .Finish

.SetIcon:
;   invoke LoadIcon, NULL, 32514
;   invoke SetIcon, eax
  jmp .Finish
; .Timer:
;   cmp dword [wParam], 11 ; Score Timer
;   jz near .Score
;   jmp .Finish

; .Score:  ; Score Timer
;   add dword [dwScore], 1
;   mov eax, dword [dwScore]
;   mov ebx, 5
;   mul ebx
;   div ebx
;   div ebx
;   cmp edx, 0
;   jne near .Score_SameCaveSpeed
;   fld dword [dwCaveSpeed]
;   mov dword [dwTemp], -1
;   fiadd dword [dwTemp]
;   fstp dword [dwCaveSpeed]
;   .Score_SameCaveSpeed:
;   jmp .Finish

.KeyUp:
  cmp dword [wParam], VK_SPACE
  jz near .SpaceBarUp
  jmp .Finish

.SpaceBar:
  mov eax, dword [dwPause]
  cmp eax, 0
  je near .SpaceBar_UnPaused
  call PauseUnpause
;   invoke SetTimer, [hWnd], 1, 1000, NULL ; Score Timer
  .SpaceBar_UnPaused:
  ; when space bar pressed then set acceleration
  mov eax, dword [dwMainJetAcc]
  mov [dwImmAccDecSpecial], eax
  mov eax, dword [dwAuxJetAcc]
  mov [dwImmAccDecNormal], eax
  jmp .Finish

.SpaceBarUp:
  ; when space bar up then set deceleration (gravity)
  mov eax, dword [dwGravityDec]
  mov [dwImmAccDecNormal], eax
  mov eax, dword [dwAuxJetDec]
  mov [dwImmAccDecSpecial], eax
  jmp .Finish

.Pause:
  call PauseUnpause
  jmp .Finish

.Destroy:
  ; end application
;   invoke KillTimer, [hWnd], 1 ; Score Timer
  invoke wglMakeCurrent, NULL, NULL
  invoke wglDeleteContext, [hRC]
  invoke ReleaseDC, [hWnd], [hDC]
  invoke PostQuitMessage, 0

.Finish:
  return 0

end ; WndProc

;*******************************************************************************
; InitGL - Initializing OpenGL window
function InitGL
begin

  invoke glEnable, GL_DEPTH_TEST
;   invoke glEnable, GL_LIGHTING
;   invoke glEnable, GL_LIGHT0
;   invoke glEnable, GL_COLOR_MATERIAL
  invoke glMatrixMode, GL_PROJECTION
  invoke glLoadIdentity

  %pushparam 1.0d
  %pushparam -1.0d
  fild dword [dwWndHeight]
  push dword 0
  push dword 0
  fstp qword [esp]
  ; h
  %pushparam 0.0d
  fild dword [dwWndWidth]
  push dword 0
  push dword 0
  fstp qword [esp]
  ; w
  %pushparam 0.0d
  invoke glOrtho ; maping abstract coordinates to window coordinates
;   invoke glScalef, 1.0f, -1.0f, 1.0f ; inversing y axis
; 
  %pushparam 0.0f
  fild dword [dwWndHeight]
  mov dword [dwTemp], 2
  fidiv dword [dwTemp]
  push dword 0
  fstp dword [esp]
  %pushparam 0.0f
  invoke glTranslatef; moving coordinates (0,h/2) to top left corner of a window

;   dwLastTime = glutGet(GLUT_ELAPSED_TIME = 700)



  return

end ; InitGL

;*******************************************************************************
; Render - Painting window content
function Render
begin

  call MoveObjects

;   call RemItem_Queue
;   call RemItem_Queue
;   call RemItem_Queue
;   call AddItem_Queue, 1
;   call AddItem_Queue, 2
;   call AddItem_Queue, 3

  invoke glMatrixMode, GL_MODELVIEW
  invoke glLoadIdentity
  ;invoke glTranslatef, 0.0f, 0.0f, -2.0f
  ;invoke glRotatef, 30.0f, 1.0f, 0.0f, 0.0f
  ;invoke glRotatef, 30.0f, 0.0f, 1.0f, 0.0f

  invoke glClear, GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT
  
  call CheckCollisions
  call PrintTexts

;   invoke glEnable, GL_STENCIL_TEST
;   invoke glStencilOp, GL_KEEP, GL_KEEP, GL_KEEP
;   invoke glStencilFunc, GL_EQUAL, 2, 2
  
  call DrawScene

;   invoke glDisable, GL_STENCIL_TEST

  invoke SwapBuffers, [hDC]
  invoke glFlush

  return

end ; Render

;*******************************************************************************
; CheckCollisions - Checking for collisions by drawing stencil buffer.
; ret - nothing
function CheckCollisions
begin

  invoke glColorMask, GL_FALSE, GL_FALSE, GL_FALSE, GL_FALSE
  
  invoke glEnable, GL_STENCIL_TEST
  invoke glDepthMask, GL_FALSE
  
  
  invoke glClearStencil, 1 ; set stencil buffer to 1
  
  invoke glStencilFunc, GL_ALWAYS, 1, 3
  invoke glStencilOp, GL_KEEP, GL_KEEP, GL_DECR

  invoke glBegin, GL_QUAD_STRIP ; decrement stencil buffer by 1 on cave painting
  
    mov eax, dword [dwPoints]
    mov [dwLoop] , eax
    mov dword [dwQueueRead], 0
    mov eax, dword [dwCavePosX]
    mov dword [dwCavePosXTemp], eax
    .CheckCollisions_LoopStart:
      mov ecx, dword [dwLoop]
      cmp ecx, 0
      jle near .CheckCollisions_LoopEnd

      call ReadNext_Queue      
      mov dword [dwCavePosYTop], eax
      mov dword [dwCavePosYBottom], eax
      shr dword [dwCavePosYTop], 16
      or dword [dwCavePosYBottom], 0xFFFF0000
   
      fild dword [dwCavePosYBottom]
      push dword 0
      fstp dword [esp]
      fld dword [dwCavePosXTemp]
      push dword 0
      fstp dword [esp]
      invoke glVertex2f
      
      fild dword [dwCavePosYTop]
      push dword 0
      fstp dword [esp]
      fld dword [dwCavePosXTemp]
      push dword 0
      fstp dword [esp]
      invoke glVertex2f
      
      sub dword [dwLoop], 1
      
      fld dword [dwCavePosXTemp]
      fiadd dword [dwPointSpacing]
      fstp dword [dwCavePosXTemp]
      
      jmp .CheckCollisions_LoopStart
    .CheckCollisions_LoopEnd:
    
  invoke glEnd
  
  invoke glStencilFunc, GL_ALWAYS, 1, 3
  invoke glStencilOp, GL_KEEP, GL_KEEP, GL_INCR

;   invoke glPointSize, 5.0f
  invoke glBegin, GL_POINTS ; increment stencil buffer by 1 on caveship painting

    mov dword [dwTemp], 2
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -3
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], 1
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -2
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], 1
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -1
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    invoke glVertex2f, [dwPosX], [dwPosY]

    mov dword [dwTemp], 0
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -1
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], -1
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -1
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], -1
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -2
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], -2
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -3
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

  invoke glEnd

  invoke glDepthMask, GL_TRUE 
  invoke glColorMask, GL_TRUE, GL_TRUE, GL_TRUE, GL_TRUE
  invoke glDisable, GL_STENCIL_TEST

  ; setting first parameter for glReadPixels function
  fld dword [dwPosX]
  fild dword [dwAreaW]
  mov dword [dwTemp], 2
  fidiv dword [dwTemp]
  fsubp st1, st0
  fistp dword [dwTemp]
  mov eax, dword [dwTemp]
  ; setting second parameter for glReadPixels function  
  fld dword [dwPosY]
  fild dword [dwAreaH]
  mov dword [dwTemp], 2
  fidiv dword [dwTemp] 
  fsubp st1, st0
  fiadd dword [dwWndHalfHeight]
  fistp dword [dwTemp]
  mov ebx, dword [dwTemp]

  invoke glReadPixels, eax, ebx, [dwAreaW], [dwAreaH], GL_STENCIL_INDEX, GL_SHORT, wCollisionBuffer
  call TestCollisionBuffer, 2
  cmp eax, 1
  je near .CheckCollisions_Collision
  return
  .CheckCollisions_Collision:
    call InitGame
  return

end ; CheckCollisions

;*******************************************************************************
; TestCollisionBuffer - Test wCollisionBuffer
; ret - nothing
function TestCollisionBuffer, collision
begin
  
  mov eax, dword [dwAreaW]
  mov ebx, dword [dwAreaH]
  mul ebx
  mov ebx, 2 ; checking word (word=2xbyte)
  mul ebx
  mov dword [dwLoopLen], eax
  
  xor ebx, ebx
  xor eax, eax
  
;   mov ebx, dword [wCollisionBuffer]
  mov dword [dwLoop], 0
.TestCollisionBuffer_loopstart:  
  mov eax, dword [dwLoopLen]
  cmp eax, dword [dwLoop]
  je near .TestCollisionBuffer_loopend
  mov edx, dword [dwLoop]
  xor eax, eax
  mov al, byte [wCollisionBuffer+edx]
  cmp eax, [collision]
  je near .TestCollisionBuffer_Collision
  add dword [dwLoop], 1 
  jmp .TestCollisionBuffer_loopstart
.TestCollisionBuffer_loopend: 
  return 0 ; no collision
  .TestCollisionBuffer_Collision:
  return 1 ; collision found

end ; CheckCollisions

;*******************************************************************************
; DrawScene - Draw scene on screen.
; ret - nothing
function DrawScene
begin

  invoke glColor3f, 1.0f, 1.0f, 1.0f ; 34,139,34 - forest green
;   invoke glPointSize, 5.0f
  invoke glBegin, GL_POINTS ; increment stencil buffer by 1 on caveship painting

    mov dword [dwTemp], 2
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -3
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], 1
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -2
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], 1
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -1
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    invoke glVertex2f, [dwPosX], [dwPosY]

    mov dword [dwTemp], 0
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -1
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], -1
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -1
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], -1
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -2
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

    mov dword [dwTemp], -2
    fld dword [dwPosY]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    mov dword [dwTemp], -3
    fld dword [dwPosX]
    fiadd dword [dwTemp]
    push dword 0
    fstp dword [esp]
    invoke glVertex2f

  invoke glEnd

  invoke glColor3f, 0.545f, 0.353f, 0.169f ; 139,90,43 - tan4
  
  invoke glBegin, GL_QUAD_STRIP
  
    mov eax, dword [dwPoints]
    mov [dwLoop] , eax
    mov dword [dwQueueRead], 0
    mov eax, dword [dwCavePosX]
    mov dword [dwCavePosXTemp], eax
;     mov dword [dwFlag], 1
    .DrawScene_LoopStart:
      mov ecx, dword [dwLoop]
      cmp ecx, 0
      jle near .DrawScene_LoopEnd
      
      call ReadNext_Queue      

      mov dword [dwCavePosYTop], eax
      mov dword [dwCavePosYBottom], eax
      shr dword [dwCavePosYTop], 16
      or dword [dwCavePosYBottom], 0xFFFF0000
   
      fild dword [dwCavePosYBottom]
      push dword 0
      fstp dword [esp]
      fld dword [dwCavePosXTemp]
      push dword 0
      fstp dword [esp]
      invoke glVertex2f
      
      fild dword [dwCavePosYTop]
      push dword 0
      fstp dword [esp]
      fld dword [dwCavePosXTemp]
      push dword 0
      fstp dword [esp]
      invoke glVertex2f
      
      sub dword [dwLoop], 1
      
      fld dword [dwCavePosXTemp]
      fiadd dword [dwPointSpacing]
      fstp dword [dwCavePosXTemp]
      
      jmp .DrawScene_LoopStart
    .DrawScene_LoopEnd:
    
  invoke glEnd

  return

end ; DrawScene

;*******************************************************************************
; PrintTexts - Prints all text on screen.
; ret - nothing
function PrintTexts
begin

  fld dword [dwVelocity]
  push dword 0
  push dword 0
  fstp qword [esp]
  push sVelocity
  push sOutput
  invoke sprintf;, sOutput, sFloat, [dwVelocity]  ; returns lenght of sOutput
  add esp, 16  
  mov [dwTemp], eax

;   mov eax, 8 ; char width
;   mul dword [dwTemp]
;   add eax, 4 ; padding
;   mov ecx, dword [dwWndWidth]
;   sub ecx, eax
;   ; ecx = w - (8 * lenof.sOutput + 4)
  mov ecx, 4
  mov ebx, dword [dwWndHalfHeight]
  sub ebx, 16 ; padding
  ; ebx = h/2 - 4
  mov eax, dword [dwTemp]
  call PrintStr, sOutput, eax, 3, ecx, ebx, 1.0f, 1.0f, 1.0f ;1.0f, 0.49f, 0.07f

  fld dword [dwPosY]
  push dword 0
  push dword 0
  fstp qword [esp]
  push sPosY
  push sOutput
  invoke sprintf
  add esp, 16  
  mov [dwTemp], eax

;   mov eax, 8 ; char width
;   mul dword [dwTemp]
;   add eax, 4 ; padding
;   mov ecx, dword [dwWndWidth]
;   sub ecx, eax
;   ; ecx = w - (8 * lenof.sOutput + 4)
  mov ecx, 4
  mov ebx, dword [dwWndHalfHeight]
  sub ebx, 32 ; padding
  ; ebx = h/2 - 4
  call PrintStr, sOutput, eax, 3, ecx, ebx, 1.0f, 1.0f, 1.0f ;1.0f, 0.49f, 0.07f

  fld dword [dwCaveSpeed]
  push dword 0
  push dword 0
  fstp qword [esp]
  push sSpeed
  push sOutput
  invoke sprintf
  add esp, 16 
  mov [dwTemp], eax

;   mov eax, 8 ; char width
;   mul dword [dwTemp]
;   add eax, 4 ; padding
;   mov ecx, dword [dwWndWidth]
;   sub ecx, eax
;   ; ecx = w - (8 * lenof.sOutput + 4)
  mov ecx, 4
  mov ebx, dword [dwWndHalfHeight]
  sub ebx, 48 ; padding
  ; ebx = h/2 - 4
  call PrintStr, sOutput, eax, 3, ecx, ebx, 1.0f, 1.0f, 1.0f ;1.0f, 0.49f, 0.07f


  fld dword [dwBestScore]
  push dword 0
;   push dword 0
  fstp dword [esp]
  push sBestScore
  push sOutput
  invoke sprintf
  add esp, 12 
  mov [dwTemp], eax

  mov eax, 8 ; char width
  mul dword [dwTemp]
  add eax, 4 ; padding
  mov ecx, dword [dwWndWidth]
  sub ecx, eax
  ; ecx = w - (8 * lenof.sOutput + 4)
  mov ebx, dword [dwWndHalfHeight]
  neg ebx
  add ebx, 4 ; padding
  ; ebx = -h/2 - 4
  call PrintStr, sOutput, eax, 3, ecx, ebx, 1.0f, 1.0f, 1.0f ;1.0f, 0.49f, 0.07f

;   xor dx, dx
;   mov ax, word [wKeyTest]
;   cwd
;   mov dword [dwTemp], eax
;   fld dword [dwPosY]
;   fistp dword [dwTemp]
  fld dword [dwScore]
  push dword 0
;   push dword 0
  fstp dword [esp]
  push sScore
  push sOutput
  invoke sprintf
  add esp, 12 
  mov [dwTemp], eax

  mov eax, 8 ; char width
  mul dword [dwTemp]
  add eax, 4 ; padding
  mov ecx, dword [dwWndWidth]
  sub ecx, eax
  ; ecx = w - (8 * lenof.sOutput + 4)
  mov ebx, dword [dwWndHalfHeight]
  neg ebx
  add ebx, 20 ; padding
  ; ebx = -h/2 - 4
  call PrintStr, sOutput, eax, 3, ecx, ebx, 1.0f, 1.0f, 1.0f ;1.0f, 0.49f, 0.07f

  return

end ; PrintTexts

;*******************************************************************************
; MoveObjects - Calculate new positions new variables new operations...
; ret - nothing
function MoveObjects
begin

  ; is the game paused?
  mov eax, dword [dwPause]
  cmp eax, 1
  je near .MoveObjects_PauseTrue ; if yes jump to the end
  
  ; calculating time between two frames
  invoke timeGetTime
  mov [dwCurMoveTime], eax
  fild dword [dwCurMoveTime]
  fisub dword [dwLastMoveTime]
  fmul dword [dwTimeFactor]
  fstp dword [dwTimeSpan]
  mov eax, dword [dwCurMoveTime]
  mov [dwLastMoveTime], eax
  
  ; calculating acceleration
  mov eax, dword [dwImmAccDecNormal]
  mov [dwImmAccDec], eax
  ; checking velocity direction (negative or positive direction)
  ; if gaining altitude (velocity positive) then decelerate more
  ; acts like auxiliary jets (gravity + auxiliary jets deceleration)
  ; if falling (velocity is negative) then accelerate more
  ; acts like auxiliary jets (acceleration + auxiliary jets acceleration)
  mov eax, dword [dwVelocity]
  and eax, 0x80000000 ; masking everything but sign bit
  cmp eax, 0x80000000
  je .movement 
  mov eax, dword [dwImmAccDecSpecial]
  mov [dwImmAccDec], eax
  .movement:
  
  ; calcualating velocity
  fld dword [dwVelocity]
  fld dword [dwImmAccDec]
  fmul dword [dwTimeSpan]
  faddp st1, st0
  fstp dword [dwVelocity]
  
  ; calcualating position
  fld dword [dwPosY]
  fld dword [dwVelocity]
  fmul dword [dwTimeSpan]
  faddp st1, st0
  fstp dword [dwPosY]
  
  ; calculating cave position and wheather to add and remove item from CaveQueue
  fld dword [dwCavePosX]
  fld dword [dwCaveSpeed]
  fmul dword [dwTimeSpan]
  faddp st1, st0
  fild dword [dwPointSpacing]
  fchs ; change sign
  fcomp st1
  fstsw ax ; save flags to ax
  fwait
  sahf ; load flags from ah
  ja near .MoveObjects_MoveQueue
  fstp dword [dwCavePosX]
  return
  .MoveObjects_MoveQueue:
  fiadd dword [dwPointSpacing]
  fild dword [dwPointSpacing]
  fchs ; change sign
  fcomp st1
  fstsw ax ; save flags to ax
  fwait
  sahf ; load flags from ah
  ja near .MoveObjects_MoveQueue
  fstp dword [dwCavePosX]

  ; every dwPointSpacing add 1 to dwScore
  add dword [dwScore], 1
  mov eax, dword [dwScore]
  mov ebx, 5
  mul ebx
  div ebx
  div ebx
  cmp edx, 0
  jne near .MoveObjects_SameCaveSpeed
  fld dword [dwCaveSpeed]
  mov dword [dwTemp], -1
  fiadd dword [dwTemp]
  fstp dword [dwCaveSpeed]
  .MoveObjects_SameCaveSpeed:
  
  call RemItem_Queue
  xor ebx, ebx
  call Rand, 10, 150 ; cave top
  mov ebx, eax
  shl ebx, 16
  call Rand, -150, -10 ; cave bottom
  and eax, 0x0000FFFF
  add ebx, eax
  call AddItem_Queue, ebx
  return

  .MoveObjects_PauseTrue: ; if pause
    invoke timeGetTime
    mov [dwLastMoveTime], eax
  return

end ; MoveObjects

;*******************************************************************************
; Rand - Pseudo-random generator, uses function RtlGenRandom from advapi32.dll
; ret - random number from [min] to [max] (if min > max, ret = 0; max < 65536)
function Rand, min, max
begin

  mov eax, [min]
  cmp eax, [max]
  jg .Zero
  
  invoke RtlGenRandom, dwBuffer, 2
  mov eax, dword [dwBuffer]
  mov dword [dwTemp], eax
  fild dword [dwTemp]
  mov eax, 0xFFFF
  mov [dwTemp], eax
  fidiv dword [dwTemp]
  mov eax, [max]
  sub eax, [min]
  mov [dwTemp], eax
  fimul dword [dwTemp]
  mov eax, [min]
  mov [dwTemp], eax
  fiadd dword [dwTemp]
  frndint ; round to integer
  fistp dword [dwTemp]
  mov eax, dword [dwTemp]

  return eax

.Zero:
  return 0

end ; Rand

;*******************************************************************************
; PrintStr - Printing string with glutBitmapCharacter char by char
; ret - nothing
function PrintStr, string, len, font, x, y, r, g, b
begin
  
  invoke glColor3f, [r], [g], [b]
  invoke glRasterPos2i, [x], [y]

  mov ebx, dword [string]
  mov dword [dwTemp], 0
.loopstart:
  mov eax, dword [len]
  cmp eax, dword [dwTemp]
  je near .loopend
  mov edx, dword [dwTemp]
  xor eax, eax
  mov al, byte [ebx+edx]
  invoke glutBitmapCharacter, [font], eax
  add dword [dwTemp], 1
  jmp .loopstart
.loopend:

  return

end ; PrintStr

;*******************************************************************************
; InitGame - Sets the game into	initial state. 
; ret - nothing
function InitGame
begin
  
  ; setting variables
  mov eax, dword [dwScore]
  cmp eax, dword [dwBestScore]
  jle .InitGame_WorseScore
  mov dword [dwBestScore], eax
  .InitGame_WorseScore:
  mov dword [dwScore], 0
  mov eax, dword [dwGravityDec]
  mov dword [dwImmAccDecNormal], eax
  mov eax, dword [dwAuxJetDec]
  mov dword [dwImmAccDecSpecial], eax    
  mov dword [dwCaveSpeed], 0xC1A00000 ; -20
  mov dword [dwVelocity], 0x00000000
  mov dword [dwPosY], 0x00000000
  mov dword [dwImmAccDec], 0x0000000
  mov dword [dwCavePosX], 0xBF800000 ; -1
  
  ; generating new cave
  mov eax, dword [dwPoints]
  mov [dwLoop] , eax
  .InitGame_LoopStart:
    mov ecx, dword [dwLoop]
    cmp ecx, 0
    jle near .InitGame_LoopEnd

    call RemItem_Queue
    xor ebx, ebx
    call Rand, 10, 150 ; cave top
    mov ebx, eax
    shl ebx, 16
    call Rand, -150, -10 ; cave bottom
    and eax, 0x0000FFFF
    add ebx, eax
    call AddItem_Queue, ebx
      
    sub dword [dwLoop], 1
      
    jmp .InitGame_LoopStart
  .InitGame_LoopEnd:

  ; pause the game
  call PauseUnpause

  return

end ; InitGame

;*******************************************************************************
; PauseUnpause - Pausing game by setting some variables.
; ret - nothing
function PauseUnpause
begin
  
  ; if paused/unpaused then unpause/pause
  mov eax, dword [dwPause]
  cmp eax, 0
  je near .PauseUnpause_SetTrue
  mov dword [dwPause], 0
;   invoke SetTimer, [hWnd], 1, 1000, NULL ; Score Timer
  return
  .PauseUnpause_SetTrue:
  mov dword [dwPause], 1
;   invoke KillTimer, [hWnd], 1 ; Score Timer
  return

end ; PauseUnpause

;*******************************************************************************
;   QUEUE Functions:
;     AddItem_Queue  - dwQueueEnd = item and dwQueueEnd + 4; Returns nothing.
;     RemItem_Queue  - dwQueueBeg + 4; Ret. nothing
;     Stretch_Queue  - dwQueueEnd + 4; Ret. nothing
;     Reduce_Queue   - dwQueueEnd - 4; Ret. nothing
;     ReadNext_Queue - Ret. [dwCaveQueue+dwQueueBeg+dwQueueRead]; dwQueueRead +4
;
;   QUEUE Data:
;     dwCaveQueue:  times 1024 dd 0 
;     dwQueueBeg    dd 0
;     dwQueueEnd    dd 0
;     dwQueueLen    dd 0
;     dwQueueMax    dd 1024
;     dwQueueLast   dd 4095
;     dwQueueRead   dd 0
;     dwPoints      dd 0
;
function AddItem_Queue, item
begin
  mov eax, dword [dwQueueLen]
  cmp eax, dword [dwQueueMax]
  jge .AddItem_Full
  mov eax, dword [dwQueueEnd]
  cmp eax, dword [dwQueueLast]
  jl .AddItem_NoOverflow
  mov dword [dwQueueEnd], 0
  .AddItem_NoOverflow:
  mov eax, dword [item]
  mov ebx, dword [dwQueueEnd]
  mov dword [dwCaveQueue+ebx], eax
  add dword [dwQueueEnd], 4  
  add dword [dwQueueLen], 1
  .AddItem_Full:
  return
end ; AddItem_Queue

function RemItem_Queue
begin
  cmp dword [dwQueueLen], 0
  jle .RemItem_Empty
  mov eax, dword [dwQueueBeg]
  cmp eax, dword [dwQueueLast]
  jl .RemItem_NoOverflow
  mov dword [dwQueueBeg], 0
;   sub dword [dwQueueLen], 1
;   return
  .RemItem_NoOverflow:
  add dword [dwQueueBeg], 4  
  sub dword [dwQueueLen], 1
  .RemItem_Empty:
  return
end ; RemItem_Queue

; function Stretch_Queue
; begin
;   mov eax, dword [dwQueueLen]
;   cmp eax, dword [dwQueueMax]
;   jge .Stretch_Full
;   mov eax, dword [dwQueueEnd]
;   cmp eax, dword [dwQueueLast]
;   jl .Stretch_NoOverflow
;   mov dword [dwQueueEnd], 0
;   .Stretch_NoOverflow:
;   add dword [dwQueueEnd], 4  
;   add dword [dwQueueLen], 1
;   .Stretch_Full:
;   return
; end ; Stretch_Queue

; function Reduce_Queue
; begin
;   cmp dword [dwQueueLen], 0
;   jle .Reduce_Empty
;   mov eax, dword [dwQueueEnd]
;   cmp eax, 0
;   jl .Reduce_NoOverflow
;   mov eax, dword [dwQueueLast]
;   mov dword [dwQueueEnd], eax
;   .Reduce_NoOverflow:
;   sub dword [dwQueueEnd], 4  
;   sub dword [dwQueueLen], 1
;   .Reduce_Empty:
;   return
; end ; Reduce_Queue

function ReadNext_Queue
begin
  
  mov eax, dword [dwQueueRead]
  mov ebx, dword [dwQueueBeg]
  add eax, ebx
  cmp eax, dword [dwQueueLast]
  jl .ReadNext_Queue_NoOverflow
  sub eax, dword [dwQueueLast]
  mov ecx, eax
  mov eax, dword [dwCaveQueue+ecx]
  add dword [dwQueueRead], 4
  return eax
  .ReadNext_Queue_NoOverflow:
  mov ecx, dword [dwQueueRead]
  mov eax, dword [dwCaveQueue+ebx+ecx]
  add dword [dwQueueRead], 4 
  return eax
end ; ReadNext_Queue
;***************************************************************************
; END OF CaveFlight.asm