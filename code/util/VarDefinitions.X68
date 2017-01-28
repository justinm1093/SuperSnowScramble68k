*-----------------------------------------------------------
* Title      :
* Written by : Justin Moser
* Date       :
* Description: VarDefinitions
*-----------------------------------------------------------

; defines gameplay variables and lookup tables

; =======================================================================================
; === TABLES === ;
;           lookup tables and other such stuff

                        ;       x   y
digitStartPositions     dc.w    40, 10      ; ones digit
                        dc.w    10, 10      ; tens digit
                        
                        ;       0    1    2    3    4    5    6    7    8    9
digitSegmentMasks       dc.b    $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $6F

                        ;       start (x,y), end (x,y)
segmentPositions        dc.w    0, 20, 20, 20       ; G
                        dc.w    0, 0, 0, 20         ; F
                        dc.w    0, 20, 0, 40        ; E
                        dc.w    0, 40, 20, 40       ; D
                        dc.w    20, 20, 20, 40      ; C
                        dc.w    20, 0, 20, 20       ; B
                        dc.w    0, 0, 20, 0         ; A


; =======================================================================================
; === GRAPHICS VARIABLES === ;
;           variables for graphics (image pointers and blocks for header data

; image files
backgroundImg           INCBIN  "assets/imgs/background.bmp"

playerImgIdle           INCBIN  "assets/imgs/player_idle.bmp"
playerImgLeft           INCBIN  "assets/imgs/player_left.bmp"
playerImgRight          INCBIN  "assets/imgs/player_right.bmp"

objImg                  INCBIN  "assets/imgs/obj.bmp"

retryImg                INCBIN  "assets/imgs/retry_dialog.bmp"
startImg                INCBIN  "assets/imgs/start_dialog.bmp"

; blocks for data parsed from image headers
backgroundImgHeader     ds.w    HEADER_SIZE_W

playerHeaderIdle        ds.w    HEADER_SIZE_W
playerHeaderLeft        ds.w    HEADER_SIZE_W
playerHeaderRight       ds.w    HEADER_SIZE_W

objImgHeader            ds.w    HEADER_SIZE_W

retryImgHeader          ds.w    HEADER_SIZE_W
startImgHeader          ds.w    HEADER_SIZE_W


; =======================================================================================
; === GAME VARIABLES === ;
;           important game variables
;               have to keep these here in main, because keeping them in EquDefinitions
;               does weird things to jsr calls (maybe because of the large addresses?)

; time keeping variables
deltaTime               ds.l    1       ; in 1/100's of seconds
prevFrameStartTime      ds.l    1

; game objects
scoreChunkRegion        ds.w    GAME_OBJ_SIZE_W
livesChunkRegion        ds.w    GAME_OBJ_SIZE_W

retryDialog             ds.w    GAME_OBJ_SIZE_W
startDialog             ds.w    GAME_OBJ_SIZE_W

player                  ds.w    GAME_OBJ_SIZE_W
gameObjArray            ds.w    GAME_OBJ_SIZE_W*NUM_GAME_OBJS_IN_ARRAY
currentGameObj          ds.l    1

; score keeping
score                   ds.l    1
lives                   ds.l    1

; gameplay variables
randomNumber            ds.l    1

framesUntilObjSpawn     ds.w    1       ; frames count until spawn object attempt

framesUntilWalkingAudio ds.w    1       ; frames until the player walking audio may play again

framesUntilAnimChange   ds.w    1       ; frames count until animation frame change
currentAnimFrame        ds.w    1       ; current animation frame number (0-5 inclusive)

pointsUntilOneUp        ds.w    1       ; points needed until a life is added

didLoseFlag             ds.b    1
willRetryFlag           ds.b    1
didQuitFlag             dc.b    $00


; =======================================================================================
; === AUDIO VARIABLES === ;
;           file paths for audio assets

startAudio              dc.b    'assets/audio/start.wav',0
loadAudio               dc.b    'assets/audio/load.wav',0
menuConfirmAudio        dc.b    'assets/audio/menu_confirm.wav',0
menuCancelAudio         dc.b    'assets/audio/menu_cancel.wav',0

dispenseObjAudio        dc.b    'assets/audio/spawn_obj.wav',0
bounceAudio             dc.b    'assets/audio/bounce.wav',0

playerWalkingAudio      dc.b    'assets/audio/walking.wav',0

pointAudio              dc.b    'assets/audio/point.wav',0
oneUpAudio              dc.b    'assets/audio/gain_life.wav',0
loseLifeAudio           dc.b    'assets/audio/drop_obj.wav',0

loseGameAudio           dc.b    'assets/audio/lose_game.wav',0


; =======================================================================================
























*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
