*-----------------------------------------------------------
* Title      :
* Written by : Justin Moser
* Date       :
* Description: UtilSubroutines
*-----------------------------------------------------------

; general utility functions -- time keeping, rng, score, misc

; =======================================================================================

; updates delta time on the stack and makes the game loop wait if needed
UpdateDeltaTime:

        ; get current frame start time
        move.l  #GET_TIME, d0
        TRAP    #15
         
        ; get delta time between this and previous, overwrite previous frame start time with current
        move.l  d1, d2
        sub.l   prevFrameStartTime, d2
        move.l  d2, deltaTime
        move.l  d1, prevFrameStartTime
        
        ; check to see if we have to delay the game loop to keep our framerate
        move.l  #FRAME_DURATION, d1
        sub.l   d2, d1
        ble     SkipWait                        ; compare delta time with frame duration, skip wait if delta was greater
        move.l  #WAIT, d0                       
        TRAP    #15                             ; else delay for d1 1/100s seconds
        
        move.l  #GET_TIME, d0                   ; if we waited, we need to update the previous frame start
        TRAP    #15
        move.l  d1, prevFrameStartTime
        
        SkipWait:

        rts
        
; =======================================================================================

; seeds the rng on initialization
seedRNG:
                      
        move.b  #GET_TIME, d0               ; seed the rng with the current time
        TRAP    #15
        move.l  d1, randomNumber

        rts
        
; =======================================================================================
    
; creates a random number based on a seed value (random number becomes seed for the next call)
getRandomNumber:

        move.l  randomNumber, d0            ; get the random seed
        
       	moveq	#$AF-$100, d1               ; some values for the random generation
       	moveq	#12, d2
       	
        getRandomNumber_1:
	    add.l	d0, d0
	    bcc     getRandomNumber_2
	    eor.l	d1, d0
	    swap    d0
	    
        getRandomNumber_2:
	    dbf	d2, getRandomNumber_1
	
	    move.l	d0, randomNumber            ; save the random long we made for the next seed

        rts

; =======================================================================================

; creates a random speed value (fixed point) for our game objecs
;       returns the value to d7
getRandomSpeed:

        ; create a random number with which we can work
        jsr     getRandomNumber
        
        ; work the random number into something usable as a game object speed
        clr.l   d7
        move.l  (randomNumber), d7          ; getRandomNumber may create a random longword
        andi.l  #$00000007, d7              ;       but all we care about for the speed is the lower 3 bits
        
        addi.l  #$1, d7                     ; add 1 to the speed so it can never be 0
        lsl.l   #FRACTIONAL_BIT_COUNT, d7   ; convert this to fixed point

        rts

; =======================================================================================

; swaps the bytes in d0
ByteSwap:

        rol.w   #8, d0
        swap    d0
        rol.w   #8, d0

        rts
        
; =======================================================================================

; updates the number of the current animation frame
UpdateAnimationFrameNumber:

        ; count down frames remaining until we change the animation frame
        subi.w  #1, (framesUntilAnimChange)
        bne     SkipAnimFrameChange
        
        move.w  #FRAMES_UNTIL_ANIM, (framesUntilAnimChange)     ; reset the countdown
        
        ; if countdown is done, update the current animation frame number
        move.w  (currentAnimFrame), d0
        subi.w  #1, d0                          ; if the current animation frame is 0 or greater...
        bge     SkipResetAnimFrameNumber        ;       reset it to the default value
        
        move.w  #NUM_FRAMES_IN_ANIM, d0
        
        SkipResetAnimFrameNumber:
        
        ; give current animation frame to player
        lea     player, a0
        move.w  d0, CHUNK_FRAME(a0)
        
        ; give current animation frame to each game object
        lea     gameObjArray, a0
        move.l  #NUM_GAME_OBJS_IN_ARRAY-1, d7
 
        GiveAnimFrameToObjsLoop:
        move.l  (a0), d1
        beq     SkipGiveAnimFrameToThisObj          ; skip if object is null
        move.w  d0, CHUNK_FRAME(a0)                 ; else, give current animation frame to object
        
        SkipGiveAnimFrameToThisObj:
        adda.l  #GAME_OBJ_SIZE_W*2, a0              ; move on to the next element
        dbra    d7, GiveAnimFrameToObjsLoop

        ; save the new current animation frame
        move.w  d0, (currentAnimFrame)
        
        SkipAnimFrameChange:

        rts

; =======================================================================================

; sets lose game flag for main function and handles lose game events
HandleLose:
        
         ; play lose game audio
        lea     loseGameAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15

        ; set lose flag and draw dialog
        move.b  #$FF, didLoseFlag
        
        lea     retryDialog, a0
        move.l  a0, -(sp)
        jsr     DrawGameObjChunk
        move.l  (sp)+, a0

        rts
        
; =======================================================================================

; decrements lives count and updates the LED
DecrementLives:

        ; play audio
        lea     loseLifeAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15

        ; redraw the background chunk over the lives area
        lea     livesChunkRegion, a0
        move.l  a0, -(sp)
        jsr     DrawBackgroundChunk
        
        ; handle lives change
        subi.l  #1, (lives)
        bne     SkipSetLose
        
        jsr     HandleLose
        
        SkipSetLose:
        
        move.l  (lives), -(sp)
        jsr     updateSegmentLED
        
        move.l  (sp)+, d0
        move.l  (sp)+, a0           ; restore stack for return

        rts
        
; =======================================================================================

; increments the lives count and updates the LED
IncrementLives:

        ; play audio
        lea     oneUpAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15

        ; redraw the background chunk over the lives area
        lea     livesChunkRegion, a0
        move.l  a0, -(sp)
        jsr     DrawBackgroundChunk
        
        ; handle lives change
        addi.l  #1, (lives)
        
        move.l  (lives), -(sp)
        jsr     updateSegmentLED
        
        move.l  (sp)+, d0
        move.l  (sp)+, a0
        
        rts

; =======================================================================================

; updates and draws the new score to the screen as a 7-segment display
IncrementScore:
 
        ; play audio
        lea     pointAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15
 
        ; redraw background chunk over the score area
        lea     scoreChunkRegion, a0
        move.l  a0, -(sp)
        jsr     DrawBackgroundChunk  
        
        ; handle score change
        addi.l  #1, (score)
        
        move.l  (score), -(sp)
        jsr     updateSegmentLED
        
        move.l  (sp)+, d0 
        move.l  (sp)+, a0           ; restore stack
        
        ; decrease the points counter that tracks when we get a 1up
        subi.w  #1, (pointsUntilOneUp)
        bne     SkipOneUp
        
        move.w  #POINTS_UNTIL_ONE_UP, (pointsUntilOneUp)
        jsr     IncrementLives
        
        SkipOneUp:
        
        rts
        
; =======================================================================================
   
; updates and draws the 7segment LED passed in on the stack     
updateSegmentLED:
        
        move.l  UPDATE_LED_VALUE(sp), d0    ; retrieve the value we are drawing from the stack
        
        ; iterate through each digit we must draw
        lea     digitStartPositions, a0
        move.l  #NUM_DIGITS, d7 
        
        updateSegmentLEDLoop:
        move.l  a0, -(sp)                   ; save the values we need to keep (table address and counter)
        move.l  d7, -(sp)
        
        divu    #10, d0                     ; divide value by 10 to separate the least significant digit (remainder) from the quotient
        swap    d0                          ;       swap words, d0's bottom word now contains least significant digit of remaining value
        
        ; prepare and restore stack for drawDigit call
        move.l  (a0), -(sp)                 ; move the current digit origin point onto the stack
        move.l  d0, -(sp)                   ; move current digit (in bottom word) onto the stack
        jsr     drawDigit
        move.l  (sp)+, d0
        move.l  (sp)+, d7
        
        lsr.l   #8, d0                      ; shift out bottom word from d0
        lsr.l   #8, d0                      ;       d0 now contains the quotient from the last divu call
        
        move.l  (sp)+, d7                   ; get our saved values off of the stack
        move.l  (sp)+, a0
        
        adda.l  #4, a0                      ; go to the next digit origin definition
        subi.l  #1, d7                      ; decrement the number of remaining digits
        bne     updateSegmentLEDLoop
        
        rts
        
; =======================================================================================

drawDigit:

        move.w  DRAW_DIGIT_DIGIT(sp), d0    ; d0 = current digit
        
        ; load the segment mask for the current digit from its lookup table
        lea     digitSegmentMasks, a0
        lea     segmentPositions, a1
        move.l  a1, -(sp)
        
        clr.l   d1
        move.b  (a0, d0), d1                ; d1 = segment mask
        
        ; initialize our current segment counter
        move.l  #6, d7                      ; d7 = counter
        handleSegmentsLoop:
        
        ; get the last bit out of the mask
        move.b  d1, d2                      ; d2 used as temp place to do the mask logic
        andi.b  #1, d2
        beq     SkipDrawSegment             ; draw current segment if it is 1, else skip it
        
        ; draw the current segment
        move.l  d7, -(sp)
        move.l  d1, -(sp)                   ; we need to save the mask for when we return
        jsr     drawSegment
        move.l  (sp)+, d1
        move.l  (sp)+, d7
        
        SkipDrawSegment:
        lsr.b   #1, d1                      ; shift out the mask bit we just handled
        dbra    d7, handleSegmentsLoop      ; decrement our counter
        
        move.l  (sp)+, a1                   ; restore the stack before we return

        rts

; =======================================================================================

drawSegment:

        ; set color for line draw
        move.l  #SET_PEN_COLOR, d0
        move.l  #$0000FF00, d1
        TRAP    #15

        ; get the address of the current segment's table entry
        move.l  DRAW_SEG_POSITIONS(sp), a0
        move.l  DRAW_SEG_COUNTER(sp), d7    ; multiply the counter by 8 to get the offset from the table start
        mulu    #8, d7
        adda.l  d7, a0

        ; get the offsets from the digit start from the table
        move.w  SEG_POS_START_X(a0), d1
        move.w  SEG_POS_START_Y(a0), d2
        move.w  SEG_POS_END_X(a0), d3
        move.w  SEG_POS_END_Y(a0), d4
        
        ; get the absolute positions of the line start and end (absolute position = region origin + digit offset + segment offset)
        move.l  DRAW_SEG_OFFSET_CHUNK(sp), a1
        move.l  PREV_SCREEN_X(a1), d5
        move.l  PREV_SCREEN_Y(a1), d6
        lsr.l   #FRACTIONAL_BIT_COUNT, d5
        lsr.l   #FRACTIONAL_BIT_COUNT, d6
        
        add.w   d5, d1
        add.w   d6, d2
        add.w   d5, d3
        add.w   d6, d4
        
        add.w   DRAW_SEG_OFFSET_DIG_X(sp), d1
        add.w   DRAW_SEG_OFFSET_DIG_Y(sp), d2
        add.w   DRAW_SEG_OFFSET_DIG_X(sp), d3
        add.w   DRAW_SEG_OFFSET_DIG_Y(sp), d4
        
        ; draw the line
        move.l  #DRAW_LINE, d0
        TRAP    #15
        
        rts

; =======================================================================================






















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
