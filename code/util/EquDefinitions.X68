*-----------------------------------------------------------
* Title      :
* Written by : Justin Moser
* Date       :
* Description: EquDefinitions
*-----------------------------------------------------------

; file to define EQU's so everything is in one place


; =======================================================================================
; === TRAP CODES === ;
;           values of trap-codes and their helper values

GET_TIME                EQU     8
HALT_SIM                EQU     9
GET_USER_INPUT          EQU     19
WAIT                    EQU     23
SET_WINDOW_MODE         EQU     33
PLAY_AUDIO              EQU     73
SET_PEN_COLOR           EQU     80
SET_FILL_COLOR          EQU     81
DRAW_PIXEL              EQU     82
DRAW_LINE               EQU     84
DRAW_FILLED_RECT        EQU     87
SET_DRAW_MODE           EQU     92
REPAINT_SCREEN          EQU     94

SINGLE_BUFFER_MODE      EQU     16
DOUBLE_BUFFER_MODE      EQU     17      ; double buffer code for trap-code 92

FRAME_DURATION          EQU     2       ; used to calculate the wait time for trap-code 23

FULLSCREEN_MODE         EQU     2       ; sets the window to fullscreen mode

KEY_SPACE               EQU     $20     ; key-codes for user input
KEY_ARROW_L             EQU     $25     
KEY_ARROW_R             EQU     $27
KEY_N                   EQU     $4E
KEY_Q                   EQU     $51
KEY_Y                   EQU     $59


; =======================================================================================
; === PARSE BITMAPS === ;
;           byte offsets from bitmap file start to important values in the header

BMP_HEADER_END          EQU     10
BMP_HEADER_SIZE         EQU     14
FROM_HEADER_TO_W        EQU     4
FROM_HEADER_TO_H        EQU     8


; =======================================================================================
; === DRAW BITMAPS === ;
;           offsets into the stack at which arguments for our chunk-drawing subroutines are kept

; constant values used for DrawBackgroundChunk and DrawGameObjChunk
DRAW_CHUNK_STACK_SIZE   EQU     16          ; size of the parameters passed into DrawChunk
OBJECT_BLOCK            EQU     20          ; offset into the stack at which the game object is kept

; offsets into the stack at which values are kept for DrawChunk (4 and up to account for DrawChunk's return address)
DRAW_SCREEN_X           EQU     4           ; screen pixel coordinates
DRAW_SCREEN_Y           EQU     6
DRAW_CHUNK_W            EQU     8           ; chunk dimensions
DRAW_CHUNK_H            EQU     10
DRAW_CHUNK_X            EQU     12          ; chunk pixel coordinates
DRAW_CHUNK_Y            EQU     14
DRAW_HEADER_DATA        EQU     16          ; address of object's image header block


; =======================================================================================
; === OBJECT DEFINITIONS === ;
;           defines blocks of data that we can treat like objects
;               this way, we can pass a block's start address and know how far to look ahead for a value we want
;               instead of moving everything onto the stack

; stores addresses and data parsed from a bitmap header
IMG_START               EQU     0       ;       start address of image
PIXEL_ARRAY             EQU     4       ;       start address of pixel array
COLOR_TABLE             EQU     8       ;       start address of color table
IMG_W                   EQU     12      ;       image pixel dimensions
IMG_H                   EQU     14
PADDING                 EQU     16      ;       number of padding bytes per row

HEADER_SIZE_W           EQU     9

; stores data about a game object (current animation frame, screen position, speed)
IMG_HEADER_DATA         EQU     0       ;       address of the bitmap header block for this object's sprite
CURR_SCREEN_X           EQU     4       ;       current screen position     ; FIXED POINT
CURR_SCREEN_Y           EQU     8                                           ; FIXED POINT
PREV_SCREEN_X           EQU     12      ;       prevous screen position     ; FIXED POINT
PREV_SCREEN_Y           EQU     16                                          ; FIXED POINT
SPEED_X                 EQU     20      ;       speed                       ; FIXED POINT
SPEED_Y                 EQU     24                                          ; FIXED POINT
CHUNK_W                 EQU     28      ;       current chunk dimensions
CHUNK_H                 EQU     30
CHUNK_FRAME             EQU     32      ;       current frame of animation

GAME_OBJ_SIZE_W         EQU     17


; =======================================================================================
; === UTILITY === ;
;           values used for utility

FRACTIONAL_BIT_COUNT    EQU     8       ; the number of fractional bits used in fixed point numbers


; =======================================================================================
; === GAMEPLAY === ;
;           values used to control gameplay

; misc values
BG_DIMENSIONS           EQU     $028001E0                       ; hex for 640 x 480 stored in 2 adjacent words

NUM_GAME_OBJS_IN_ARRAY  EQU     3                               ; size of the array of game objects
FRAMES_UNTIL_OBJ_SPAWN  EQU     270                             ; frames that must pass before we attempt to spawn a game obj

POINTS_UNTIL_ONE_UP     EQU     10                              ; points needed until a life is added

NUM_FRAMES_IN_ANIM      EQU     5                               ; number of frames in an animation (this number + 1)
FRAMES_UNTIL_ANIM       EQU     5                               ; frames that must pass before we change the animation frame of objects

GRAVITY                 EQU     $0<<FRACTIONAL_BIT_COUNT+$50    ; acceleration rate of gravity, fixed point

WALK_AUDIO_FRAME_DELAY  EQU     10                              ; number of frames that must pass before walking audio begins playing again

; gameplay bounds
BOUND_L                 EQU     $28<<FRACTIONAL_BIT_COUNT
BOUND_R                 EQU     $243<<FRACTIONAL_BIT_COUNT
BOUND_B                 EQU     $1BC<<FRACTIONAL_BIT_COUNT

; default player values
PLAYER_CHUNK_W          EQU     40                              ; chunk dimensions
PLAYER_CHUNK_H          EQU     40
PLAYER_START_X          EQU     $140<<FRACTIONAL_BIT_COUNT      ; start position   fixed point
PLAYER_START_Y          EQU     BOUND_B-PLAYER_CHUNK_H<<FRACTIONAL_BIT_COUNT
PLAYER_SPEED            EQU     $7<<FRACTIONAL_BIT_COUNT        ; speed             5, fixed point

STARTING_LIVES          EQU     3

; default game object values
OBJ_START_X             EQU     $20<<FRACTIONAL_BIT_COUNT       ; start position    fixed point
OBJ_START_Y             EQU     $80<<FRACTIONAL_BIT_COUNT
OBJ_START_SPEED_Y       EQU     $00<<FRACTIONAL_BIT_COUNT       ; initial y speed   xx, fixed point
OBJ_CHUNK_W             EQU     40                              ; chunk dimensions
OBJ_CHUNK_H             EQU     40


; =======================================================================================
; === UI === ;
;           values for our UI elements

; values for score chunk region
SCORE_START_X           EQU     $0<<FRACTIONAL_BIT_COUNT
SCORE_START_Y           EQU     $0<<FRACTIONAL_BIT_COUNT
SCORE_CHUNK_W           EQU     70
SCORE_CHUNK_H           EQU     60

; values for lives chunk region
LIVES_START_X           EQU     $23A<<FRACTIONAL_BIT_COUNT
LIVES_START_Y           EQU     $0<<FRACTIONAL_BIT_COUNT
LIVES_CHUNK_W           EQU     70
LIVES_CHUNK_H           EQU     60

; values for ui dialogs
DIALOG_START_X          EQU     $A0<<FRACTIONAL_BIT_COUNT
DIALOG_START_Y          EQU     $78<<FRACTIONAL_BIT_COUNT
DIALOG_CHUNK_W          EQU     320
DIALOG_CHUNK_H          EQU     240


; =======================================================================================
; === LED DRAWING === ;
;           offsets into the stack at which arguments for our LED subroutines are kept

NUM_DIGITS              EQU     2       ; number of digits in our leds

; updateSegmentLED stack offsets
UPDATE_LED_VALUE        EQU     4       ; the value we are updating

; drawDigit stack offsets
DRAW_DIGIT_DIGIT        EQU     6       ; current digit (***ONLY USE BOTTOM WORD***)
DRAW_DIGIT_ORIGIN       EQU     8       ; upper left x,y of the 7segment for this digit (kept as a longword)

; drawSegment stack offsets
DRAW_SEG_COUNTER        EQU     8       ; counter (how far we need to look into the segmentPositions table)
DRAW_SEG_POSITIONS      EQU     12      ; address of the segmentPositions table
DRAW_SEG_OFFSET_DIG_X   EQU     24      ; offsets from the chunk region to the current digit
DRAW_SEG_OFFSET_DIG_Y   EQU     26
DRAW_SEG_OFFSET_CHUNK   EQU     44      ; offsets from the screen to the current chunk

; offsets for the segmentPositions table
SEG_POS_START_X         EQU     0       ; start x,y
SEG_POS_START_Y         EQU     2
SEG_POS_END_X           EQU     4       ; end x,y
SEG_POS_END_Y           EQU     6


; =======================================================================================

































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
