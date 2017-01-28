*-----------------------------------------------------------
* Title      :
* Written by : Justin Moser
* Date       :
* Description: GameFlow
*-----------------------------------------------------------

; a collection of subroutines for initialization and game flow
    
; =======================================================================================

; calls our other init functions
InitGame:

        ; set draw mode to single buffer for background load
        move.l  #SINGLE_BUFFER_MODE, d1
        move.l  #SET_DRAW_MODE, d0
        TRAP    #15

        jsr     InitGameplayVariables
        jsr     InitGameObjsArray
        jsr     InitBackground
        jsr     InitRetryDialog
        jsr     InitLEDChunks
        jsr     InitPlayer
        jsr     InitTime
        
        ; set draw mode to double buffer for gameplay
        move.l  #DOUBLE_BUFFER_MODE, d1
        move.l  #SET_DRAW_MODE, d0
        TRAP    #15

        rts 

; ======================================================================================= 

; resets our flags and gameplay variables
InitGameplayVariables:

        ; clear gameplay variables and flags, seed the rng
        move.l  #-1, (score)                        ; init score to -1, so when we draw the first score, it is 0
        move.l  #STARTING_LIVES+1, (lives)
        
        jsr     seedRNG
        
        move.w  #FRAMES_UNTIL_OBJ_SPAWN, (framesUntilObjSpawn)
        
        move.w  #WALK_AUDIO_FRAME_DELAY, (framesUntilWalkingAudio)
        
        move.w  #FRAMES_UNTIL_ANIM, (framesUntilAnimChange)
        move.w  #NUM_FRAMES_IN_ANIM, (currentAnimFrame)
        
        move.w  #POINTS_UNTIL_ONE_UP+1, (pointsUntilOneUp)
        
        move.b  #0, (didLoseFlag)
        move.b  #0, (willRetryFlag)

        rts
        
; ======================================================================================= 

; resets all entries in the game objects array to null
InitGameObjsArray:

        ; init game objects in array to null
        lea     gameObjArray, a0
        lea     currentGameObj, a1
        move.l  a0, (a1)                            ; init the currentGameObj to the start of the array
        
        move.l  #NUM_GAME_OBJS_IN_ARRAY-1, d7
        StepThroughGameObjArray_Init:
        move.l  #0, (a0)                            ; 0 in the object image header is our flag for a null game object
        adda.l  #GAME_OBJ_SIZE_W*2, a0
        dbra    d7, StepThroughGameObjArray_Init

        rts
        
; ======================================================================================= 

; draws the background
InitBackground:

        lea     loadAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15

        ; draw entire background image
        ;       this is a special case where we don't draw the background relative to
        ;       a game object's position, so we don't use DrawBackgroundChunk and instead
        ;       just prepare the stack and call DrawChunk directly   
        suba.l  #DRAW_CHUNK_STACK_SIZE, sp          ; prep stack
        
        lea     backgroundImgHeader, a0
        move.l  a0, DRAW_HEADER_DATA-4(sp)          ; img header data
        move.l  #0, DRAW_CHUNK_X-4(sp)              ; chunk coords          (start at image origin (0,0))
        move.l  #0, DRAW_SCREEN_X-4(sp)             ; screen coords         (start at screen origin (0,0))
        move.l  #BG_DIMENSIONS, DRAW_CHUNK_W-4(sp)  ; chunk dimensions
        
        jsr     DrawChunk
        adda.l  #DRAW_CHUNK_STACK_SIZE, sp          ; restore stack

        rts

; =======================================================================================  

; initializes retry dialog
InitRetryDialog

        lea     retryDialog, a0
        
        lea     retryImgHeader, a1
        move.l  a1, IMG_HEADER_DATA(a0)
        
        move.l  #DIALOG_START_X, CURR_SCREEN_X(a0)
        move.l  #DIALOG_START_Y, CURR_SCREEN_Y(a0)
        
        move.w  #DIALOG_CHUNK_W, CHUNK_W(a0)
        move.w  #DIALOG_CHUNK_H, CHUNK_H(a0)
        
        move.w  #0, CHUNK_FRAME(a0)
        
        rts
        
; =======================================================================================   

; initializes the regions used to paint our 7segment LED's for score and lives
InitLEDChunks:

        ; define the region used to paint over the score when updating
        lea     scoreChunkRegion, a0
        move.l  #SCORE_START_X, PREV_SCREEN_X(a0)
        move.l  #SCORE_START_Y, PREV_SCREEN_Y(a0)
        move.w  #SCORE_CHUNK_W, CHUNK_W(a0)
        move.w  #SCORE_CHUNK_H, CHUNK_H(a0)
        jsr     IncrementScore                  ; draw the initialized score as 00
        
        ; define the region used to paint over the lives count when updating
        lea     livesChunkRegion, a0
        move.l  #LIVES_START_X, PREV_SCREEN_X(a0)
        move.l  #LIVES_START_Y, PREV_SCREEN_Y(a0)
        move.w  #LIVES_CHUNK_W, CHUNK_W(a0)
        move.w  #LIVES_CHUNK_H, CHUNK_H(a0)
        jsr     DecrementLives

        rts

; =======================================================================================      
        
; initializes the player game object and its default values
InitPlayer:

        ; init player variables
        lea     player, a0
        
        lea     playerHeaderIdle, a1                ; image header (init to idle animation)
        move.l  a1, IMG_HEADER_DATA(a0)
        
        move.l  #PLAYER_START_X, CURR_SCREEN_X(a0)  ; starting position
        move.l  #PLAYER_START_Y, CURR_SCREEN_Y(a0)
        move.l  #PLAYER_START_X, PREV_SCREEN_X(a0)
        move.l  #PLAYER_START_Y, PREV_SCREEN_Y(a0)
        
        move.l  #PLAYER_SPEED, SPEED_X(a0)          ; speed
        move.l  #0, SPEED_Y(a0)
        
        move.w  #PLAYER_CHUNK_W, CHUNK_W(a0)        ; chunk dimensions
        move.w  #PLAYER_CHUNK_H, CHUNK_H(a0)
        
        move.w  (currentAnimFrame), CHUNK_FRAME(a0) ; chunk animation frame

        rts
        
; =======================================================================================

; initializes timer for delta time
InitTime:

        ; initialize time tracking
        move.l  #GET_TIME, d0
        TRAP    #15
        move.l  d1, prevFrameStartTime

        rts

; =======================================================================================

; handles input for the post-game retry confirmation dialog
;       'Y' key sets the retry flag and restarts the game
;       'N' key quits the game
HandleRetryConfirmation:

        HandleRetryLoop:
        
        ; set trap task to listen for Y or N
        move.l  #KEY_Y<<8+KEY_N, d1
        move.l  #GET_USER_INPUT, d0
        TRAP    #15
        
        ; check which inputs are detected
        cmpi.w  #$FF00, d1          ; only Y detected
        beq     ConfirmRetry
        cmpi.w  #$00FF, d1          ; only N detected
        beq     DenyRetry
        
        bra     HandleRetryLoop     ; otherwise, nothing or both detected, continue loop
        
        ; confirm retry -- set retry flag and play confirm audio
        ConfirmRetry:
        
        move.b  #$FF, willRetryFlag
        
        lea     menuConfirmAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15
        
        bra     EndHandleRetryConfirmation
        
        ; deny retry -- play cancel audio
        DenyRetry:
        
        lea     menuCancelAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15
        
        EndHandleRetryConfirmation:
        
        rts

; =======================================================================================  

; initializes start dialog
InitStartDialog
        
        ; init the start dialog
        lea     startDialog, a0
        
        lea     startImgHeader, a1
        move.l  a1, IMG_HEADER_DATA(a0)
        
        move.l  #DIALOG_START_X, CURR_SCREEN_X(a0)
        move.l  #DIALOG_START_Y, CURR_SCREEN_Y(a0)
        
        move.w  #DIALOG_CHUNK_W, CHUNK_W(a0)
        move.w  #DIALOG_CHUNK_H, CHUNK_H(a0)
        
        move.w  #0, CHUNK_FRAME(a0)

        rts
        
; =======================================================================================  

; pauses the flow of the program until the spacebar is pressed to begin the game
HandleBeginConfirmation:

        ; set full screen mode
        jsr     SetFullScreen

        ; clear the screen and display a start dialog
        jsr     ClearScreen
        jsr     InitStartDialog
        
        lea     startAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15
        
        lea     startDialog, a0
        move.l  a0, -(sp)
        jsr     DrawGameObjChunk
        move.l  (sp)+, a0

        move.l  #REPAINT_SCREEN, d0
        TRAP    #15

        HandleBeginLoop:
        
        ; set trap task to listen for spacebar or q
        move.l  #KEY_SPACE<<8+KEY_Q, d1
        move.l  #GET_USER_INPUT, d0
        TRAP    #15
        
        cmpi.w  #$FF00, d1          ; only spacebar detected
        beq     StartGame
        cmpi.w  #$00FF, d1          ; only 'q' detected
        beq     SetQuitFlag
        
        bra     HandleBeginLoop
        
        SetQuitFlag:
        
        ; quitting, set quit flag and play cancel audio
        move.b  #$FF, didQuitFlag
        
        lea     menuCancelAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15
        
        bra     EndHandleBeginConfirmation      ; skip playing confirmation audio
        
        StartGame:
        
        ; starting game, play confirmation audio
        lea     menuConfirmAudio, a1
        move.l  #PLAY_AUDIO, d0
        TRAP    #15
        
        EndHandleBeginConfirmation:
        rts

; =======================================================================================
        
        
        
        
        
        





































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
