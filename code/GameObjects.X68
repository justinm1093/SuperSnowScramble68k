*-----------------------------------------------------------
* Title      :
* Written by : Justin Moser
* Date       :
* Description: GameObjects
*-----------------------------------------------------------

; update calls and other functions for game objects

; =======================================================================================

; handles input and movement logic for the player object
UpdatePlayerObj:
        
        lea     player, a0
        
        ; set trap task to listen for left and right arrow keys
        move.l  #KEY_ARROW_L<<8+KEY_ARROW_R, d1
        move.l  #GET_USER_INPUT, d0
        TRAP    #15
        
        ; save off previous screen position
        ;       we do this for every frame whether or not we move
        ;       because there are cases that otherwise led to a mismatch between current and previous
        move.l  CURR_SCREEN_X(a0), PREV_SCREEN_X(a0)        
        
        ; check which inputs are detected
        cmpi.w  #$FF00, d1          ; only left detected
        beq     LeftDetected
        cmpi.w  #$00FF, d1          ; only right detected
        beq     RightDetected
        
        ; else neither or both are detected, set idle animation and return
        lea     playerHeaderIdle, a1
        move.l  a1, IMG_HEADER_DATA(a0)
        bra     EndUpdatePlayer
        
        LeftDetected:
        
        ; set left animation
        lea     playerHeaderLeft, a1
        move.l  a1, IMG_HEADER_DATA(a0)
        
        ; check screen left bounds
        move.l  CURR_SCREEN_X(a0), d0
        cmpi.l  #BOUND_L, d0
        ble     PlayWalkingAudio
        
        ; move player left if not outside bounds
        lea     player, a0
        move.l  SPEED_X(a0), d0
        sub.l   d0, CURR_SCREEN_X(a0)
        bra     PlayWalkingAudio
        
        RightDetected:
        
        ; set right animation
        lea     playerHeaderRight, a1
        move.l  a1, IMG_HEADER_DATA(a0)
        
        ; check screen right bounds
        move.l  CURR_SCREEN_X(a0), d0
        addi.l  #PLAYER_CHUNK_W<<FRACTIONAL_BIT_COUNT, d0       ; have to account for fractional bits, so we shift chunk width
        cmpi.l  #BOUND_R, d0
        bge     PlayWalkingAudio
        
        ; move player right if not outside bounds
        lea     player, a0
        move.l  SPEED_X(a0), d0
        add.l   d0, CURR_SCREEN_X(a0)
        
        PlayWalkingAudio:
        jsr     HandlePlayerWalkingAudio

        EndUpdatePlayer:

        rts

; =======================================================================================
   
; handles movment and logic for the current game object
;       we only update 1 object per frame to save time
;       it is here that we update the pointer to the currentGameObj
UpdateCurrentGameObj:
        
        ; load the current game object
        lea     currentGameObj, a0          ; currentGameObj is a pointer to the current element in the array
        move.l  (a0), a2                    ; so we get the contents of a0 to load the current object's actual address
        
        move.l  (a2), d0                    ; check object for null
        beq     SetNextCurrentGameObj       ; skip this update if the object is null
        
        move.l  CURR_SCREEN_X(a2), d0
        move.l  CURR_SCREEN_Y(a2), d1
        move.l  d0, PREV_SCREEN_X(a2)       ; save last screen position
        move.l  d1, PREV_SCREEN_Y(a2)
        
        ; check collision with bottom bounds of screen
        addi.l  #OBJ_CHUNK_H<<FRACTIONAL_BIT_COUNT, d1
        cmpi.l  #BOUND_B, d1
        blt     GameObjCheckRightBound
        
        jsr     DecrementLives
        jsr     DestroyGameObj                          ;       decrement lives, destroy game object,
        bra     EndUpdateCurrentGameObj                 ;       and return
        
        ; check collision with right bounds of screen
        GameObjCheckRightBound:
        addi.l  #OBJ_CHUNK_W<<FRACTIONAL_BIT_COUNT, d0
        cmpi.l  #BOUND_R, d0
        blt     GameObjCheckPlayerCollision
        
        jsr     IncrementScore
        jsr     DestroyGameObj                          ;       increment the score, destroy game object,
        jsr     InitGameObj                             ;       create new one in its place, and set the next game object
        jsr     SetNextCurrentGameObj
        bra     EndUpdateCurrentGameObj
        
        ; check collision with the player object
        GameObjCheckPlayerCollision:
        lea     player, a3
        
        cmp.l   CURR_SCREEN_Y(a3), d1                       ; check y bounds of player and obj
        blt     NoCollisionDetected                         ;       no collision if obj is still above player
        
        move.l  CURR_SCREEN_X(a3), d2
        cmp.l   d2, d0                                      ; check obj right bound vs player left bound
        blt     NoCollisionDetected                         ;       no collision if obj right is still left of player left
        
        add.l   #PLAYER_CHUNK_W<<FRACTIONAL_BIT_COUNT, d2   ; check obj left bound vs player right bound
        cmp.l   CURR_SCREEN_X(a2), d2                       ;       no collision if obj left is still right of player right
        blt     NoCollisionDetected 
        
        eori.l  #$FFFFFFFF, SPEED_Y(a2)                     ; if a collision is detected...
        addi.l  #1, SPEED_Y(a2)                             ;       set the object's speed to its negative equivalent (reverse bits, add 1)
        
        move.l  CURR_SCREEN_Y(a3), d3       
        subi.l  #PLAYER_CHUNK_H<<FRACTIONAL_BIT_COUNT, d3   ; we also have to set the object's y to the player's y
        move.l  d3, CURR_SCREEN_Y(a2)                       ;       otherwise, the object could get stuck on the player object
        
        lea     bounceAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15
        
        bra     UpdateObjScreenPosition
        
        ; no collisions detected, apply gravity to object
        NoCollisionDetected:
        subi.l  #GRAVITY, SPEED_Y(a2)
        
        UpdateObjScreenPosition:
        move.l  SPEED_Y(a2), d1             ; update screen y
        sub.l   d1, CURR_SCREEN_Y(a2)
        move.l  SPEED_X(a2), d1             ; update screen x
        add.l   d1, CURR_SCREEN_X(a2)
        
        ; set the next game object pointer
        jsr     SetNextCurrentGameObj
        
        EndUpdateCurrentGameObj:
        
        rts
        
; =======================================================================================
        
; sets the next current game object pointer
SetNextCurrentGameObj:

        lea     currentGameObj, a0          ; currentGameObj is a pointer to the current element in the array
        move.l  (a0), a1                    ; so we get the contents of a0 to load the current object's actual address

        adda.l   #GAME_OBJ_SIZE_W*2, a1
        
        cmp.l   a1, a0                      ; if the current obj address is the currentGameObj pointer,
        bne     EndSetNextCurrentGameObj    ; we need to set the current obj address back to the array start
        lea     gameObjArray, a1
        
        EndSetNextCurrentGameObj:
        move.l  a1, (a0)                    ; reassign the currentGameObj to the next element
        
        rts
        
; =======================================================================================

; counts the frames until we may spawn an object
;       when the required number of frames has passed, we may attempt to spawn a new object
AttemptSpawnGameObj:

        ; decrement the number of remaining frames
        subi.w  #1, (framesUntilObjSpawn)
        bne     SkipAttemptSpawn            ; if the number of frames hasn't been reached, skip attempting to spawn
        
        jsr     InitGameObj                 ; else, we can try to spawn an object at the first null array element
        move.w  #FRAMES_UNTIL_OBJ_SPAWN, (framesUntilObjSpawn)
        
        SkipAttemptSpawn:

        rts

; =======================================================================================

; creates a game object at the first non-null element in our game objects array
InitGameObj:

        ; step through array of game objs
        lea     gameObjArray, a0
        move.l  #NUM_GAME_OBJS_IN_ARRAY-1, d7
 
        FindFirstNonNullArrayElement:
        move.l  (a0), d0
        beq     CreateObj                           ; create object at current location if element is null (0 for an image header ptr)
        adda.l  #GAME_OBJ_SIZE_W*2, a0              ; else, continue to next element
        dbra    d7, FindFirstNonNullArrayElement
        
        bra     EndInitGameObj                      ; there were no null array elements, don't create a new object

        CreateObj:

        ; play audio
        lea     dispenseObjAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15

        lea     objImgHeader, a1                    ; image header
        move.l  a1, IMG_HEADER_DATA(a0)
        
        move.l  #OBJ_START_X, CURR_SCREEN_X(a0)     ; starting position
        move.l  #OBJ_START_Y, CURR_SCREEN_Y(a0)
        move.l  #OBJ_START_X, PREV_SCREEN_X(a0)
        move.l  #OBJ_START_Y, PREV_SCREEN_Y(a0)
        
        jsr     getRandomSpeed                      ; object speed (x value is randomized)
        move.l  d7, SPEED_X(a0)
        move.l  #OBJ_START_SPEED_Y, SPEED_Y(a0)
        
        move.w  #OBJ_CHUNK_W, CHUNK_W(a0)           ; chunk dimensions
        move.w  #OBJ_CHUNK_H, CHUNK_H(a0)
        
        move.w  (currentAnimFrame), CHUNK_FRAME(a0) ; chunk animation frame

        EndInitGameObj:

        rts
        
; =======================================================================================

; nulls the memory of the current game object
DestroyGameObj:

        lea     currentGameObj, a2
        move.l  (a2), a1
        
        ; repaint background at position so it doesn't stick there
        move.l  a1, -(sp)
        jsr     DrawBackgroundChunk
        move.l  (sp)+, a1

        ; then destroy the currentGameObj
        move.l  #0, (a1)                        ; 0 out image header at the address
        
        rts  
       
; =======================================================================================

; handles slight delay for playing player walking audio
HandlePlayerWalkingAudio:
        
        subi.w  #1, (framesUntilWalkingAudio)
        bne     SkipWalkingAudio
        
        move.w  #WALK_AUDIO_FRAME_DELAY, (framesUntilWalkingAudio)
        
        lea     playerWalkingAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15
        
        SkipWalkingAudio:

        rts

; =======================================================================================
    
    
    
    
    
    























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
