*-----------------------------------------------------------
* Title      :
* Written by : Justin Moser
* Date       :
* Description: ParseBitmap
*-----------------------------------------------------------
    
; takes all images and unpacks their headers into memory so our draw
; calls won't get bogged down with repeated calls to ParseImage
LoadImages:

        ; parse the background image
        lea     backgroundImgHeader, a0
        lea     backgroundImg, a1
        jsr     ParseImage
        
        ; parse the game object images, save the address of the header object
        lea     playerHeaderIdle, a0        ; player idle animation
        lea     playerImgIdle, a1
        jsr     ParseImage
        
        lea     playerHeaderLeft, a0        ; player left animation
        lea     playerImgLeft, a1
        jsr     ParseImage
        
        lea     playerHeaderRight, a0       ; player right animation
        lea     playerImgRight, a1
        jsr     ParseImage
        
        lea     objImgHeader, a0            ; game object animation
        lea     objImg, a1
        jsr     ParseImage
        
        ; parse dialog images
        lea     retryImgHeader,a0           ; retry dialog
        lea     retryImg, a1
        jsr     ParseImage
        
        lea     startImgHeader, a0          ; start dialog
        lea     startImg, a1
        jsr     ParseImage

        rts
        
; =======================================================================================
        
; populates a block of memory whose start is kept in a0 with data from the header of a bmp file
;       a0 = memory location of image header data block
;       a1 = memory location of image we are parsing
ParseImage:

        ; move the image start into the header block
        move.l  a1, IMG_START(a0)
        
        ; move address of image pixel array into the header block
        move.l  BMP_HEADER_END(a1), d0      ;   the last word of the Bitmap FileHeader is the offset from the
        jsr     ByteSwap                    ;   file start to the pixel array
        move.l  a1, a2
        adda.l  d0, a2                      ;   address of pixel array = image address + offset
        move.l  a2, PIXEL_ARRAY(a0)
        
        ; move address of image color table into the header block
        move.l  BMP_HEADER_SIZE(a1), d0     ;   first word of the DIB Header is the size of the DIB Header
        jsr     ByteSwap
        move.l  a1, a2                      ;   address of color table =
        adda.l  #BMP_HEADER_SIZE, a2        ;       image address + BMP header size + DIB header size
        adda.l  d0, a2
        move.l  a2, COLOR_TABLE(a0)
        
        ; move image width to the header block
        move.l  BMP_HEADER_SIZE+FROM_HEADER_TO_W(a1), d0
        jsr     ByteSwap
        move.w  d0, IMG_W(a0)
        
        ; get number of padding bytes, add it to the header block
        andi.l  #$00000003, d0              ; using a bitmask to get the bottom 2 bits of image width
        move.l  #4, d1
        sub.l   d0, d1                      ; the bottom 2 bits of the difference between 4 and the width's bottom 2 bits
        andi.l  #$00000003, d1              ; gives us the number of padding bits added to each row
        move.w  d1, PADDING(a0)
        
        ; move image height to the header block
        move.l  BMP_HEADER_SIZE+FROM_HEADER_TO_H(a1), d0
        jsr     ByteSwap
        move.w  d0, IMG_H(a0)

        rts
        
; =======================================================================================
















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
