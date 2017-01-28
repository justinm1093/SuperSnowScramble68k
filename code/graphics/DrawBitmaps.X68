*-----------------------------------------------------------
* Title      :
* Written by : Justin Moser
* Date       :
* Description: DrawBitmap
*-----------------------------------------------------------
    
; takes all game objects and draws them
;       first draws chunks of the background image at the previous screen locations of each game object
;       then draws each game object at their current screen location
RefreshScreen:

        ; refresh background at previous object positions
        lea     player, a0
        move.l  a0, -(sp)
        jsr     DrawBackgroundChunk
        jsr     DrawGameObjChunk
        move.l  (sp)+, a0
        
        ; draw the currentGameObj
        ;       since we've only updated one game object this frame, this saves us tons of time per draw
        lea     currentGameObj, a0
        move.l  (a0), a1
        move.l  (a1), d0
        beq     AfterDrawCurrentGameObj         ; check if the current game object is null (skip draw if null)
        
        move.l  a1, -(sp)
        jsr     DrawBackgroundChunk
        jsr     DrawGameObjChunk
        move.l  (sp)+, a0
        
        AfterDrawCurrentGameObj:
 
        ; copy the buffer to the screen, then return
        move.l  #REPAINT_SCREEN, d0
        TRAP    #15

        rts
 
; =======================================================================================

; draws a chunk of the background at the previous screen location of the given game object
;
;       have to subtract offsets by 4 here to account for return address added with 
;       'jsr    DrawChunk'
DrawBackgroundChunk:

        ; prepare the stack with values for DrawChunk
        suba.l  #DRAW_CHUNK_STACK_SIZE, sp
        
        lea     backgroundImgHeader, a0                 ; move background img header data onto stack
        move.l  a0, DRAW_HEADER_DATA-4(sp)
        
        move.l  OBJECT_BLOCK(sp), a1                    ; get the object's pointer 
        
        move.l  CHUNK_W(a1), DRAW_CHUNK_W-4(sp)         ; the chunk's dimensions is the object's dimensions
        
        move.l  PREV_SCREEN_X(a1), d0                   ; remove fractional bits from object position
        move.l  PREV_SCREEN_Y(a1), d1
        lsr.l   #FRACTIONAL_BIT_COUNT, d0
        lsr.l   #FRACTIONAL_BIT_COUNT, d1
        
        move.w  d0, DRAW_CHUNK_X-4(sp)                  ; the chunk's coords and screen position are the
        move.w  d1, DRAW_CHUNK_Y-4(sp)                  ; object's position from the previous frame
        move.w  d0, DRAW_SCREEN_X-4(sp)
        move.w  d1, DRAW_SCREEN_Y-4(sp)
        
        jsr     DrawChunk
        
        ; restore the stack
        adda.l  #DRAW_CHUNK_STACK_SIZE, sp

        rts

; =======================================================================================

; draws a chunk of the given game object
;
;       have to subtract offsets by 4 here to account for return address added with
;       'jsr    DrawChunk'
DrawGameObjChunk:

        ; prepare the stack with values for DrawChunk
        suba.l  #DRAW_CHUNK_STACK_SIZE, sp
        
        move.l  OBJECT_BLOCK(sp), a0                                ; get the object's image data pointer
        move.l  IMG_HEADER_DATA(a0), DRAW_HEADER_DATA-4(sp)
        
        move.l  CHUNK_W(a0), DRAW_CHUNK_W-4(sp)                     ; chunk dimensions
        
        move.w  CHUNK_W(a0), d0
        move.w  CHUNK_FRAME(a0), d1
        mulu    d0, d1
        move.w  d1, DRAW_CHUNK_X-4(sp)                              ; chunks of objects start at x-coord = chunk-width * current animation frame
        move.w  #0, DRAW_CHUNK_Y-4(sp)                              ; chunks of objects start at y-coord = 0

        move.l  CURR_SCREEN_X(a0), d0                               ; remove fractional bits from object position
        move.l  CURR_SCREEN_Y(a0), d1
        lsr.l   #FRACTIONAL_BIT_COUNT, d0
        lsr.l   #FRACTIONAL_BIT_COUNT, d1
        
        move.w  d0, DRAW_SCREEN_X-4(sp)
        move.w  d1, DRAW_SCREEN_Y-4(sp)
        
        jsr     DrawChunk
        
        ; restore the stack
        adda.l  #DRAW_CHUNK_STACK_SIZE, sp

        rts

; =======================================================================================

; draws a chunk of the provided image
;       data on the image to use, the chunk position and size, and the screen position
;       are all stored on the stack before this function is called
DrawChunk:

        ; get the address of the pixel array and color table out of the image header data block
        move.l  DRAW_HEADER_DATA(sp), a3
        move.l  PIXEL_ARRAY(a3), a0         ; a0 = pixel array address
        move.l  COLOR_TABLE(a3), a1         ; a1 = color table address
        
        ; init some important values for the draw loops
        clr.l   d7
        move.w  IMG_W(a3), d7               ; d7 = image width
        move.w  PADDING(a3), d6             ; d6 = image padding
        move.w  DRAW_CHUNK_W(sp), d5        ; d5 = chunk width counter
        move.w  DRAW_SCREEN_X(sp), d4       ; d4 = current screen x
        
        ; get the address of the chunk start
        move.w  IMG_H(a3), d0               ; because bitmaps store their pixel array rows in reverse order
        sub.w   DRAW_CHUNK_Y(sp), d0        ; the top row of the chunk is technically an offset from the image height
        sub.w   #1, d0                      ;       true chunk y (in terms of bmp pixel array) = image height - chunk y - 1
        move.w  d0, d1
                             
        mulu.w  d7, d0                      ; byte offset from start of image to start of chunk = 
        mulu.w  d6, d1                      ;       (image width * true chunk y) + (padding * true chunk y) + chunk x       
        add.l   d1, d0        
        clr.l   d2
        move.w  DRAW_CHUNK_X(sp), d2                    
        add.l   d2, d0
        
        move.l  a0, a2                      ; address of chunk start = pixel array address + byte offset to chunk start
        adda.l  d0, a2                      ;       a2 = address of current pixel
        
        DrawLoop:
        
        ; get the current pixel out of the pixel array
        clr.l   d0
        move.b  (a2), d0                    ; getting the index in the color table
        lsl.l   #2, d0                      ; each entry in color table is 4 bytes, so we have to multiply the index by 4
        
        move.l  (a1, d0), d1                ; getting color out of color table
        lsr.l   #8, d1                      ; else, shift out the leading 0's so the color is formatted as $00BBGGRR
        beq     SkipDrawCurrentPixel        ; if the color is black, skip drawing it (black as transparent)
        
        ; set the pen using the current color in d1
        move.l  #SET_PEN_COLOR, d0
        TRAP    #15
        
        ; draw the pixel at the current screen position
        move.l  #DRAW_PIXEL, d0
        move.w  d4, d1                      ; current screen x to d1
        move.w  DRAW_SCREEN_Y(sp), d2       ; current screen y to d2
        TRAP    #15
        
        SkipDrawCurrentPixel:
        
        ; handle x value changes
        addi.w  #1, d4                      ; increment screen x
        adda.l  #1, a2                      ; increment address of current pixel
        subi.w  #1, d5                      ; decrement chunk w counter
        bne     DrawLoop                    ;       loop back if pixels in row remain
        
        ; restore the chunk width counter and screen x for the next row
        move.w  DRAW_CHUNK_W(sp), d5        ; d6 = chunk width counter
        move.w  DRAW_SCREEN_X(sp), d4       ; d5 = current screen x
        
        ; get address of next chunk row
        suba.l  d7, a2                      ; start address of next chunk row =
        suba.l  d6, a2                      ;       end address of last chunk row - image width - padding - chunk width
        suba.l  d5, a2
        
        ; handle y value changes
        addi.w  #1, DRAW_SCREEN_Y(sp)       ; increment screen y
        subi.w  #1, DRAW_CHUNK_H(sp)        ; decrement num remaining rows
        bne     DrawLoop                    ;       loop back if rows remain
        
        AfterDrawLoop:
        
        rts

; =======================================================================================

; draws a black rectangle over the entirety of the screen to clear it
ClearScreen:

        ; set draw mode to double buffer for gameplay
        move.l  #DOUBLE_BUFFER_MODE, d1
        move.l  #SET_DRAW_MODE, d0
        TRAP    #15
        
        ; set pen and fill color for rectangle
        move.l  #$00000000, d1
        
        move.l  #SET_PEN_COLOR, d0
        TRAP    #15
        
        move.l  #SET_FILL_COLOR, d0
        TRAP    #15
        
        ; set bounds and draw rectangle
        move.l  #DRAW_FILLED_RECT, d0
        move.l  #BG_DIMENSIONS, d7
        
        move.w  #0, d1          ; upper left
        move.w  #0, d2
        move.w  d7, d4          ; lower right
        swap    d7
        move.w  d7, d3
        
        TRAP    #15
        
        ; repaint the screen
        move.l  #REPAINT_SCREEN, d0
        TRAP    #15

        rts

; =======================================================================================

; sets the game window to full screen mode
SetFullScreen:

        move.l  #FULLSCREEN_MODE, d1
        move.l  #SET_WINDOW_MODE, d0
        TRAP    #15

        rts

; =======================================================================================







































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
