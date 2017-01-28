*-----------------------------------------------------------
* Title      :
* Written by : Justin Moser
* Date       :
* Description: Assembly Game
*-----------------------------------------------------------
    
; handles the core game loop
    
Start   ORG    $1000

        jsr     LoadImages                  ; load all of our images ahead of time
        
        jsr     HandleBeginConfirmation
        lea     didQuitFlag, a0
        clr.l   d0
        move.b  (a0), d0
        bne     QuitGame                    ; if the quit flag is non-zero, quit the game

        BeforeInitGame:
        jsr     InitGame                    ; else, initialize all game-related things and start

        GameLoop:
        
        jsr     UpdateDeltaTime             ; update time-keeping
        jsr     RefreshScreen               ; refresh screen from last loop's changes

        ; check lose flag
        lea     didLoseFlag, a0
        clr.l   d0
        move.b  (a0), d0
        bne     AfterGameLoop               ; if the lose flag is non-zero, break out of game loop
        
        ; update our game objects
        jsr     AttemptSpawnGameObj
        jsr     UpdatePlayerObj
        jsr     UpdateCurrentGameObj
        jsr     UpdateAnimationFrameNumber
        
        bra     GameLoop
        
        AfterGameLoop:
        
        ; handle retry confirmation
        jsr     HandleRetryConfirmation
        lea     willRetryFlag, a0
        clr.l   d0
        move.b  (a0), d0
        bne     BeforeInitGame              ; if the retry flag is non-zero, restart game
        
        QuitGame:
        
        jsr     ClearScreen

        move.l  #HALT_SIM, d0
        TRAP    #15     

; =======================================================================================
        
        ; .x68 secondary file includes
        INCLUDE code/util/EquDefinitions.x68    ; utility -- equ defines, time keeping, rng
        INCLUDE code/util/UtilSubroutines.x68
        
        INCLUDE code/GameObjects.x68            ; game obj subroutines
        
        INCLUDE code/GameFlow.x68               ; game flow -- init, loss checks
        
        INCLUDE code/graphics/ParseBitmaps.x68  ; bitmap handling
        INCLUDE code/graphics/DrawBitmaps.x68
        
        STOP    #$2000
        
; =======================================================================================

        INCLUDE code/util/VarDefinitions.x68    ; variable and table definitions

        END    START
















































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
