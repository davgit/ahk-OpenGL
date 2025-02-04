#SingleInstance, Force

; Test script and demonstration of OpenGL library.
; 
; to add text just do lines.insert(text)
; if you want it to scroll in nicely then also do newlinepos--
; to remove a line from the top do lines.remove(1)
; 

    Width := 800
    Height := 600
    Lines := ["1340 <Acuena> dunno how to check that??"
    , "1340 <Worm002> wiggly worm"
    , "1340 <Acuena> msgbox it?"
    , "1341 <Uberi> yep"
    , "1341 <Uberi> MsgBox `% A_EventInfo"
    , "1341 <Uberi> before that line"
    , "just start typing & press enter"]
    lines.current := ""
    
    Gosub, Initialize
    OnExit, ExitSub
    SetTimer, Update, 30
return

Initialize:
    hGDI32 := DllCall("LoadLibrary","Str","gdi32")
    gl := new OpenGL(True)
    
    Gui, +LastFound +Resize +MinSize150x150
    Gui, Add, Edit, vInputLine -WantReturn y-100 gInputLineChange
    Gui, Add, Button, +Default gSubmitLine y-100
    hWindow := WinExist()
    
    hDC := DllCall("GetDC","UInt",hWindow)
    VarSetCapacity(Struct,40,0)
        NumPut(40  ,Struct, 0,"UShort")
        NumPut(1   ,Struct, 2,"UShort")
        NumPut(0x25,Struct, 4,"UInt")  ;PFD_DRAW_TO_WINDOW | PFD_SUPPORT_OPENGL | PFD_DOUBLEBUFFER
        NumPut(0   ,Struct, 8,"UChar") ;PFD_TYPE_RGBA
        NumPut(24  ,Struct, 9,"UChar") ;Color bit depth
        NumPut(16  ,Struct,23,"UChar") ;Depth buffer bit depth
    DllCall("gdi32\SetPixelFormat","UInt",hDC,"Int",DllCall("gdi32\ChoosePixelFormat","UInt",hDC,Ptr,&Struct,"Int"),Ptr,&Struct)
    hRC := gl.wglCreateContext(hDC)
    gl.wglMakeCurrent(hDC,hRC)
    
    gl.glShadeModel(GL_SMOOTH)
    gl.glClearColor(0.0, 0.0, 0.0, 0.0)
    gl.glClearDepth(1.0)
    gl.glEnable(GL_DEPTH_TEST)
    gl.glDepthFunc(GL_LESS)
    gl.glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)
    gl.glEnable(GL_RESCALE_NORMAL)
    gl.glPolygonMode(GL_FRONT_AND_BACK, GL_FILL)
    
    gl.glEnable(GL_LIGHTING)
    gl.glEnable(GL_LIGHT0)
    
    ; attempt at antialiasing, isn't working for me :(
    ; gl.glEnable(GL_LINE_SMOOTH)
    ; gl.glDisable(Gl_DEPTH_TEST)
    ; gl.glEnable(GL_POLYGON_SMOOTH)
    ; gl.glEnable(GL_BLEND)
    ; gl.glDisable(GL_CULL_FACE)
    ; gl.glBlendFunc(GL_SRC_ALPHA_SATURATE, GL_ONE)
    ; gl.glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST)
    
    VarSetCapacity(Struct,16)
        NumPut(1,Struct,0,"Float")
        NumPut(1,Struct,4,"Float")
        NumPut(1,Struct,8,"Float")
        NumPut(1,Struct,12,"Float") ;light with color 1,1,1
    gl.glLightfv(GL_LIGHT0, GL_AMBIENT, &Struct)
    
        NumPut(1,Struct,0,"Float")
        NumPut(1,Struct,4,"Float")
        NumPut(1,Struct,8,"Float")
        NumPut(1,Struct,12,"Float")
    gl.glLightfv(GL_LIGHT0, GL_DIFFUSE, &Struct)
    
        NumPut(0,Struct,0,"Float")
        NumPut(0,Struct,4,"Float")
        NumPut(0,Struct,8,"Float")
        NumPut(0,Struct,12,"Float")
    gl.glLightfv(GL_LIGHT0, GL_SPECULAR, &Struct)
    
        NumPut(0,Struct,0,"Float")
        NumPut(0,Struct,4,"Float")
        NumPut(0,Struct,8,"Float")
        NumPut(1,Struct,12,"Float") ;positional light at 0,0,0
    gl.glLightfv(GL_LIGHT0, GL_POSITION, &Struct) 
    gl.glLightf(GL_LIGHT0, GL_LINEAR_ATTENUATION, 0.01)
    
    FontList := gl.glGenLists(256)
    hFont := DllCall("CreateFont","Int",-16,"Int",0,"Int",0,"Int",0,"Int",100,"UInt",0,"UInt",0,"UInt",0,"UInt",0,"UInt",4,"UInt",0,"UInt",4,"UInt",0,"Str","Arial")
    hTempFont := DllCall("SelectObject","UInt",hDC,"UInt",hFont)
    
    VarSetCapacity(GlyphMetrics,6144,0) ;256 * 24
    gl.wglUseFontOutlines(hDC, 0, 256, FontList, 0, 0.1, WGL_FONT_POLYGONS, &GlyphMetrics)
    
    DllCall("SelectObject","UInt",hDC,"UInt",hTempFont)
    DllCall("DeleteObject","UInt",hFont)
    TextType := A_IsUnicode ? GL_UNSIGNED_SHORT : GL_UNSIGNED_BYTE
    gl.glListBase(FontList)
    
    VerticalPosition := -0.2
    VerticalPosition2 := -7.2
    HorizontalPosition := -6.2
    HorizontalPosition2 := -6.2
    ZPos := -10
    ZPos2 := -7.3
    Angle := -25
    Angle2 := 19
    newlinepos := 0
    scale := 1
    
    Gui, Show, w%Width% h%Height%, 3D Scroller
return

Update:
    GuiControlGet, current_focus, Focus
    if (current_focus != "Edit1" && current_focus != "")
        GuiControl, Focus, InputLine
    
    gl.glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT)
    gl.glLoadIdentity()
    ;gl.glScalef(scale, scale, scale)
    gl.glRotatef(Angle, 1.0, 0.0, 0.0)
    gl.glTranslatef(HorizontalPosition, VerticalPosition + newlinepos + 1, zPos)
    
    if newlinepos
        newlinepos := min(newlinepos + max(ABS(newlinepos)/7, 0.1), 0)
    
    ; output the static lines
    loop % lines._maxindex()
    {
        line := lines[lines._maxindex() - (A_Index - 1)]
        gl.glPushMatrix()
        gl.glCallLists(StrLen(line), TextType, &line)
        gl.glPopMatrix()
        gl.glTranslatef(0, 1, 0)
    }
    
    ; output the current line
    gl.glLoadIdentity()
    gl.glRotatef(Angle2, 1.0, 0.0, 0.0)
    gl.glTranslatef(HorizontalPosition2, VerticalPosition2, zPos2)
    gl.PushMatrix()
    line := lines.current
    gl.glCallLists(StrLen(line), TextType, &line)
    gl.PopMatrix()
    
    DllCall("gdi32\SwapBuffers", "UInt", hDC)
return

ResizeScene(PosX, PosY, Width, Height, FieldOfView = 45.0, ClipNear = 0.5, ClipFar = 100.0)
{
    global
    local MaxX, MaxY
    gl.glViewport(PosX,PosY,Width,Height)
    gl.glMatrixMode(GL_PROJECTION)
    gl.glLoadIdentity()
    MaxY := ClipNear * Tan(FieldOfView * 0.00872664626)
    MaxX := MaxY * (Width / Height)
    gl.glFrustum(0 - MaxX, MaxX, 0 - MaxY, MaxY, ClipNear, ClipFar)
    gl.glMatrixMode(GL_MODELVIEW)
}

InputLineChange:
    GuiControlGet, InputLine
    lines.current := InputLine
return

SubmitLine:
    if (lines.current == "")
        VerticalPosition++
    else
        lines.insert(lines.current)
        , lines.current := ""
    newlinepos -= 1
    GuiControl, , InputLine,
return

GuiSize:
    Width := A_GuiWidth ? A_GuiWidth : 1
    Height := A_GuiHeight ? A_GuiHeight : 1
    ResizeScene(0,0,Width,Height,55.0,0.5,Width / 4)
return

GuiClose:
ExitApp

ExitSub:
    gl.glDeleteLists(FontList,256)
    gl.wglMakeCurrent(0,0)
    gl.wglDeleteContext(hRC)
ExitApp

#IfWinActive 3D Scroller

; Hotkeys: 
;   Up,Down,Right,Left: move text that direction (x,y axis)
;   WheelUp/WheelDown move text forward/back (z axis)
;   Shift+Up,Down changes the angle
;   
; Modifiers:
;   Use CTRL to change the position of the second text (current/edit control text)
;   Use ALT to increment/decrement all of the above in 1/10 the amount

Up::VerticalPosition += 1
Down::VerticalPosition -= 1
!Up::VerticalPosition += 0.1
!Down::VerticalPosition -= 0.1

^Up::VerticalPosition2 += 1
^Down::VerticalPosition2 -= 1
^!Up::VerticalPosition2 += 0.1
^!Down::VerticalPosition2 -= 0.1

WheelUp::ZPos += 1
WheelDown::ZPos -= 1
!WheelUp::ZPos += .1
!WheelDown::ZPos -= .1

^WheelUp::ZPos2 += 1
^WheelDown::ZPos2 -= 1
^!WheelUp::ZPos2 += .1
^!WheelDown::ZPos2 -= .1

+Up::Angle++
+Down::Angle--

^+Up::Angle2++
^+Down::Angle2--

Right::HorizontalPosition++
Left::HorizontalPosition--
!Right::HorizontalPosition += 0.1
!Left::HorizontalPosition -= 0.1

^Right::HorizontalPosition2++
^Left::HorizontalPosition2--
^!Right::HorizontalPosition2 += 0.1
^!Left::HorizontalPosition2 -= 0.1

F12::
    newlinepos := 0
    newline := ""
    InputBox, newline
    lines.insert(newline)
    newlinepos -= 1
return

+F12::lines.remove(1)


max(n, x*) {
    for k,v in x
        if (v > n)
            n := v
    return n
}

min(n, x*) {
    for k,v in x
        if (v < n)
            n := v
    return n
}

#include <OpenGL>
