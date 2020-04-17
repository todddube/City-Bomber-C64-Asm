
#region Version Header
;*********************************************************************************************
; Current Version : 3.1
;*********************************************************************************************
;Date           Version         Changes
; 31/03/2020    1.0             - Setup special characters and enable them.
;                               - Print the header. 
;                               - Place plane on screen.
;                               - Make plane move and set initial speed.
;
; 03/04/2020    2.0             - Place bomb on screen
;                               - Make bomb drop.
;
; 04/04/2020    2.1             - added custom chars at the letter and number 
;                                 position in the charset.
;                               - Moved the text to append the code.
;                               - Moved variables and labels to append code.
;
; 07/04/2020    3.0             - Build level 1.
;
;
; 08/04/2020    3.1             - Adding more levels. Totally added 10 levels.
;                               - Game can check if there are any map cells left on the map
;
;
; 15/04/2020    4.0             - Change between levels when a level is completed.
;                               - Update scoring.
;
;
;
; 15/04/2020    5.0             - Run gameloop at rasters
;                               
;
;
;
#endregion

; 10 SYS (4096)

*=$0801

                BYTE    $0E, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $00, $00, $00



          

*=$1000

#region Init game
InitGame

;        lda $01
;        and #%11111110
;        sta $01

        ldx #$00                   ; Set x register to zero for loop   
        lda #$00    
        sta FillScreenChar
        jsr FillScreen             ; Call sub routine that fill screen with spaces
          
        ldx #$00                   ; Set x register to zero for loop
        lda #$00                   ; Set accumulator to one - the color
        sta CharFillColor
        jsr FillCharColor          ; Call sub routine that fill screen positions with one color
        
        lda #$0e                   ; Set the color code    
        sta ScreenColor
        lda #$00
        sta BorderColor
        jsr SetScreenColor         ; Call sub routine that changes the background and border color 

        lda #28    
        sta $d018                  ; set where characters are in memory

        ; Start Screen
        jsr StartScreen

        ; Init the cell score.
        sed
        lda #$03
        sta CellScore
        cld
          
        PrintScreen HeaderTxt,$0400   ; Put header text on the screen
        jsr BuildLevel
        ;jsr SplashScreen

        jsr GameLoop
          
        rts

#endregion


#region Game Loop
GameLoop
        
        lda #$ff
        cmp $d012
        bne GameLoop

        lda #$01
        sta $d020

        lda GameMode
        cmp #$02
        bne @nxt1
        jsr GMPlane      
        jsr GMBomb
        jsr GMlevel_progress
@nxt1
        lda GameMode
        cmp #$03
        bne @nxt2
        jsr GMlevel_end

@nxt2        
        lda GameMode
        cmp #$05
        bne @nxt3
        jsr GMstart_new_level
@nxt3


        jsr Keypressed
        jsr PrintScore
        lda #$00
        sta $d020

        jmp GameLoop
          
        rts

#endregion


#region Splash Loop
SplashLoop

          jsr    Keypressed
          jmp    SplashLoop

          rts

#endregion


;*****************************************************************************
; Game routines
;*****************************************************************************

#region Plane handling
GMPlane

        ;Prepare the plane height and position
        ldx PlaneHeight
        lda BScreenOff_H,x
        sta $fe
        lda BScreenOff_L,x
        sta $fd

        lda CScreenOff_H,x
        sta $fc
        lda CScreenOff_L,x
        sta $fb

        ldy PlanePosition
        clc
        cpy #$28    ; Check if front of the plane is out of the screen
        beq @tail   ; then jump past the plane front print

        cpy #$29    ; Check if the tail of the plane is out of the screen
        beq @clear  ; then jump past the plane tail print

        cpy #$2a    ; print the front of the plane
        bcs @out1
        lda #69
        sta ($fd),y
        lda #$01
        sta ($fb),y
        cpy #$00
        beq @out1
@tail   dey
        lda #70     ; print the tail of the plane
        sta ($fd),y
        cpy #$00
        beq @out1
        jmp @clear1
@clear  dey
@clear1 dey
        lda #$00 ;#32     ; Clear the tail from previous plane position
        sta ($fd),y


@out1
        ; Check plane speed 2 if value is not reached then exit 

        ldx PlaneSpeedMem2
        inx
        stx PlaneSpeedMem2
        cpx PlaneSpeed2
        bne @out3
        ; Time to move plane forward
        clc      
        ldx #$00
        stx PlaneSpeedMem2
        ldx PlanePosition
        inx
        cpx #$2a
        bne @out2
        ldx #$00
        stx PlanePosition
        ldx PlaneHeight
        inx
        stx PlaneHeight

        jmp @out3
@out2
        ldx PlanePosition
        inx
        stx PlanePosition
        ; check if plane crash at next move
        ldx PlaneHeight
        lda BScreenOff_H,x
        sta $fe     
        ldx PlaneHeight
        lda BScreenOff_L,x
        sta $fd     
        ldy PlanePosition
        iny
        iny
        lda ($fd),y
        cmp #$00
        beq @out3
        lda #$01
        sta PlaneCrash

@out3

        rts

#endregion

#region Bomb handling
GMBomb

        ldx BombHeight
        lda BScreenOff_H,x
        sta $fe     
        ldx BombHeight
        lda BScreenOff_L,x
        sta $fd     
        lda CScreenOff_H,x
        sta $fc
        lda CScreenOff_L,x
        sta $fb
        ldy BombPosition

        ldx PlaneHeight
     
        cpx BombHeight
        bcs @nxt1
        lda #$00
        sta ($fd),y  


 
@nxt1   ldx BombHeight
        inx
        lda BScreenOff_H,x
        sta $fe     
        ldx BombHeight
        inx
        lda BScreenOff_L,x
        sta $fd 
        lda CScreenOff_H,x
        sta $fc
        lda CScreenOff_L,x
        sta $fb


        ; Check if next cell has a building part
        ; if so then subtract one cell from the map
        lda ($fd),y
        cmp #$41
        beq @nxt3
        cmp #$42
        beq @nxt3
        jmp @nxt4
@nxt3
        lda MapCells
        sec
        sbc #$01
        sta MapCells
        jsr AddScore
        
@nxt4
        ; Chec if bomb has to be displayed or a blank
        lda BombOut
        cmp #$01
        bne @nxt2

        ;Set bomb on new position on map
        lda #$47
        sta ($fd),y
        lda #$00
        sta ($fb),y
        jmp @out1
        
        ; set a blank dummy when no bomb has to be displayed
@nxt2   lda #$00
        sta $0427
@out1
        ; Check if bomb delay timer is done
        ldx BombSpeedMem2
        inx
        stx BombSpeedMem2
        cpx BombSpeed2
        bne @out3
        ; Time to move bomb down
        ldx #$00
        stx BombSpeedMem2
        stx BombSpeedMem2
        ldx BombHeight
        inx
        cpx #$18
        bne @out2
        ; No bomb out and clear bomb at bottom line

        lda BScreenOff_H,x
        sta $fe     
        lda BScreenOff_L,x
        sta $fd           
        lda #$00
        sta ($fd),y 

        lda #$00
        sta BombOut
        ldx PlaneHeight
        stx BombHeight
        


@out2
         stx BombHeight
@out3
          rts
#endregion

#region Key press handling
Keypressed

        ; Check if spacebar has been pressed. If not then out
        lda    $c5     
        cmp    #$3c
        bne    @out2

        lda KeyPressdbounce
        cmp #$00
        bne @out2

        lda #$0a
        sta KeyPressdbounce

        ; check if game is running (gamemode 2)
        lda GameMode
        cmp #$02
        bne @out1



        lda BombOut   ; Check if bomb is already out
        cmp #$01      ; then jump out of routine
        beq @out2
        ldx #$01
        stx BombOut
        ldx PlaneHeight
        inx
        stx BombHeight
        clc
        ldx PlanePosition ;Check if plane still inside the screen.
        cpx #$28          ;If not then reset BombOut    
        bcs @out1
        stx BombPosition
        jmp @out2      

@out1
        lda #$00
        sta BombOut

        ; check if level is finished (gamemode 4)
        lda GameMode
        cmp #$04
        bne @out2
        lda #$05
        sta GameMode


@out2
        lda KeyPressdbounce    
        cmp #$00
        beq @out3
        sec
        sbc #$01
        sta KeyPressdbounce

@out3
        

        rts

#endregion

#region Check level progress
GMlevel_progress
        lda MapCells   
        cmp #$00
        bne @out1
        ;brk ; this break has to go when all levels are tested
        lda #$03
        sta GameMode

@out1
        rts

#endregion

#region End level
GMlevel_end
        
        PrintScreen LevelCleared1,$04d7   ; Put text on the screen
        PrintScreen LevelCleared2,$0500   ; Put text on the screen
        PrintScreen PressSpace,$0524      ; Put text on the screen


        lda #$04                          ; set game mode to 4 and wait for press on space to continue.        
        sta GameMode

        rts

#endregion

#region Start new level
GMstart_new_level


        ;add one to level
        ldx Level
        inx
        stx level
        ; Update score per Cell
        sed
        clc
        lda #$01
        adc CellScore
        sta CellScore
        cld
        
        ;update LevelOffset to load map
        ldx LevelOffset
        inx
        cpx #$0a
        bne @nxt1
        ldx LevelRollOver
        inx
        stx LevelRollOver
        ldx #$00
@nxt1
        stx LevelOffset

        ; intit different variables
        lda #$00
        sta PlanePosition
        sta BombOut
        sta BombPosition
        lda #$01
        sta PlaneHeight


        ldx #$00                   ; Set x register to zero for loop   
        lda #$00    
        sta FillScreenChar
        jsr FillScreen             ; Call sub routine that fill screen with spaces
        PrintScreen HeaderTxt,$0400   ; Put header text on the screen
        jsr BuildLevel
        lda #$02
        sta GameMode

        rts

#endregion

#region Add_Score
AddScore
        sed
        clc
        lda CellScore;ScoreAdd
        adc Score1
        sta Score1
        lda Score2
        adc #00
        sta Score2
        lda Score3
        adc #00
        sta Score3
        cld
        rts

#endregion

;*****************************************************************************
; Sub routines
;*****************************************************************************

#region Subroutine

#region Set border and screen color
SetScreenColor     
          lda    BorderColor
          sta    $d020   
          lda    ScreenColor
          sta    $d021    
          rts
#endregion

#region Fill Screen with char          
FillScreen
          lda    FillScreenChar    
          sta    $0400,x   
          sta    $0500,x
          sta    $0600,x  
          sta    $06e8,x 
          inx
          bne    FillScreen
          rts
#endregion

#region Fill Char color
FillCharColor
          lda    CharFillColor    
          sta    $d800,x 
          sta    $d900,x 
          sta    $da00,x 
          sta    $dae8,x 
          inx
          bne    FillCharColor
          rts
#endregion
          
#region Splash Screen         
SplashScreen


        rts
#endregion

#region Start Screen
StartScreen

        PrintScreen StartPage1,$0433
        PrintScreen StartPage2,$0460
        PrintScreen StartPage3,$0486

        PrintScreen StartPage4,$04ce
        PrintScreen StartPage5,$04fd
        PrintScreen StartPage6,$0525
        PrintScreen StartPage7,$0550

        PrintScreen StartPage8,$05bb
        PrintScreen StartPage9,$05e2
        PrintScreen StartPage10,$0608
        PrintScreen StartPage11,$063b

        PrintScreen StartPage12,$0683
        PrintScreen StartPage13,$06ab
        PrintScreen StartPage14,$06d2

        PrintScreen PressSpace,$0752

@loop1
        lda $c5     
        cmp #$3c
        bne @nxt1
        jmp @out1

@nxt1
;************START Color ramp loop

        lda #$ff
        cmp $d012
        bne @loop1

        clc
        lda ColorRampSpeed
        adc #$01
        sta ColorRampSpeed
        cmp #$03
        bne @loop1

        lda #$00
        sta ColorRampSpeed

        ldx ColorRampIndex
        inx
        cpx #$0c
        bne @nxt2
        ldx #$00
@nxt2
        stx ColorRampIndex

        ; Direction 1
        ldy #$0d
@l1
        lda ColorRamp,x
        sta $d8fd,y
        sta $d925,y
        sta $d950,y
        inx
        cpx #$0c
        bne @n1
        ldx #$00
@n1
        dey
        bpl @l1




;*************END color ramp loop

        jmp @loop1
@out1

        ldx #$00                   ; Set x register to zero for loop   
        lda #$00    
        sta FillScreenChar
        jsr FillScreen             ; Call sub routine that fill screen with spaces
          
        ldx #$00                   ; Set x register to zero for loop
        lda #$00                   ; Set accumulator to one - the color
        sta CharFillColor
        jsr FillCharColor          ; Call sub routine that fill screen positions with one color

        rts

#endregion

#region Build Level
BuildLevel


        ; load level memory offset for the map
        ldx Level
        inx
        stx Level

        ldx LevelOffset
        cpx #$0a
        bcc @nxt1

        ; When all 10 levels has been played start over but faster and lower
        lda #$01
        sta $0400
        lda #$00
        sta LevelOffset
        clc
        lda PlaneSpeed2
        sbc #$01
        sta PlaneSpeed2
        clc
        lda BombSpeed2
        sbc #$01
        sta BombSpeed2
        clc
        lda PlaneHeight
        adc #$01
        sta PlaneHeight
        clc


        
@nxt1
        ; Set the tiles of the map
        lda 1LevelOFF_H,x
        sta $fc     
        lda 1LevelOFF_L,x
        sta $fb 

        lda 2LevelOFF_H,x
        sta $fe     
        lda 2LevelOFF_L,x
        sta $fd 

        ldy #$00
@Loop1        
        lda ($fb),y
        cpy #$00
        bne @nxt2

        sta MapCells
        lda MapCells    
        jmp @nxt3
@nxt2   
        sta $0658,y
@nxt3
        lda ($fd),y
        sta $0721,y
        iny
        cpy #$c8
        bne @Loop1

;        ; Set the color of the map
;        lda 1LevelOFF_C_H,x
;        sta $fc     
;        lda 1LevelOFF_C_L,x
;        sta $fb 

;        lda 2LevelOFF_C_H,x
;        sta $fe     
;        lda 2LevelOFF_C_L,x
;        sta $fd 

        ldy #$00
@Loop2        
        lda $6000,y ;lda($fb),y
        sta $da57,y
        lda $60c9,y ;lda($fd),y
        sta $db20,y

        iny
        cpy #$c8
        bne @Loop2

        

        ldx LevelOffset
        inx
        stx LevelOffset

        rts


#endregion

          
#endregion

#region PrintScore
PrintScore
        lda Score3      ; Hundred thousands
        and #$f0
        lsr
        lsr
        lsr
        lsr
        ora #$30
        ;sta $0400
        lda Score3      ; Ten thousands
        and #$0f
        ora #$30
        sta $0406

        lda Score2      ; Thousands
        and #$f0
        lsr
        lsr
        lsr
        lsr
        ora #$30
        sta $0407
        lda Score2      ; Hundreds
        and #$0f
        ora #$30
        sta $0408
       
        lda Score1      ; Tens
        and #$f0
        lsr
        lsr
        lsr
        lsr
        ora #$30
        sta $0409
        lda Score1      ; Ones
        and #$0f
        ora #$30
        sta $040a

        rts

#endregion

          
;****************************************************************************
; Macros
;****************************************************************************          

#region Macros
defm PrintScreen ; /1= text as byte /2 screen addr
          ldy    #0      
@Loop
          lda    /1,y    
          beq    @Out    
          sta    /2,y    
          iny
          beq    @Out
          jmp    @Loop   
@Out            
          endm
          
#endregion


;****************************************************************************
; Variables and labels
;**************************************************************************** 

#region Varables and labels

;                         00  01  02  03  04  05  06  07  08  09  0a  0b  0c  0d  0e  0f  10  11  12  13  14  15  16  17  18
BScreenOff_H    byte    $04,$04,$04,$04,$04,$04,$04,$05,$05,$05,$05,$05,$05,$06,$06,$06,$06,$06,$06,$06,$07,$07,$07,$07,$07
BScreenOff_L    byte    $00,$28,$50,$78,$a0,$c8,$f0,$18,$40,$68,$90,$b8,$e0,$08,$30,$58,$80,$a8,$d0,$f8,$20,$48,$70,$98,$c0

CScreenOff_H    byte    $d8,$d8,$d8,$d8,$d8,$d8,$d8,$d9,$d9,$d9,$d9,$d9,$d9,$da,$da,$da,$da,$da,$da,$da,$db,$db,$db,$db,$db
CScreenOff_L    byte    $00,$28,$50,$78,$a0,$c8,$f0,$18,$40,$68,$90,$b8,$e0,$08,$30,$58,$80,$a8,$d0,$f8,$20,$48,$70,$98,$c0


1LevelOFF_H     byte    $c0,$c1,$c3,$c4,$c6,$c7,$c9,$ca,$cc,$ce
1LevelOFF_L     byte    $00,$90,$20,$b0,$40,$d0,$60,$f0,$80,$10

2LevelOFF_H     byte    $c0,$c2,$c3,$c5,$c7,$c8,$ca,$cb,$cd,$ce
2LevelOFF_L     byte    $c9,$59,$e9,$79,$09,$99,$29,$b9,$49,$d9

1LevelOFF_C_H   byte    $60,$61,$63,$64,$66,$67,$69,$6a,$6c,$6e
1LevelOFF_C_L   byte    $00,$90,$20,$b0,$40,$d0,$60,$f0,$80,$10

2LevelOFF_C_H   byte    $60,$62,$63,$65,$67,$68,$6a,$6b,$6d,$6e
2LevelOFF_C_L   byte    $c9,$59,$e9,$79,$09,$99,$29,$b9,$49,$d9

ColorRamp       byte $01,$0d,$03,$0c,$04,$02,$09,$02,$04,$0c,$03,$0d ; 12
ColorRampIndex  byte $00
ColorRampSpeed  byte $00

                

ScreenColor     BYTE    $01
BorderColor     BYTE    $01
CharFillColor   BYTE    $01
FillScreenChar  BYTE    $20


; Game variables
Score1          byte $00
Score2          byte $00
Score3          byte $00

HiScore1        byte $00
HiScore2        byte $05
HiScore3        byte $00

ScoreAdd        byte $00
CellScore       byte $20

KeyPressdbounce byte $00

Level           byte $01
LevelOffset     byte $00
LevelRollOver   byte $00

GameMode        byte $02 ;1 = splash screen, 2 = Game playing, 3 map cleared, 4 wait for press space after level cleared, 5 start new level          
GameMainVersion = #4
GameSubVersion =#0          

DecreseScore byte $02          

; Plane variables
PlaneHeight     byte    $01
PlanePosition   byte    $00
PlaneSpeed1     byte    $ff ;ff
PlaneSpeed2     byte    $0f ;0a
PlaneSpeedMem1  byte    $00
PlaneSpeedMem2  byte    $00 
PlaneCrash      byte    $00
             


; Bomb variables
BombOut         byte    $00
BombHeight      byte    $00
BombPosition    byte    $00
BombSpeed1      byte    $ff
BombSpeed2      byte    $0a
BombSpeedMem1   byte    $00
BombSpeedMem2   byte    $00

; Map variables
MapBuildheight        byte $0f
MapBuildPos           byte $00
MapCells              byte $ff


#endregion


;****************************************************************************
; Screen text
;****************************************************************************          

#region Screen Text
HeaderTxt       text 'SCORE 00000   HI-SCORE 00000   LEVEL 01@'       
LevelCleared1   text 'LEVEL CLEARED@'
LevelCleared2   text 'BONUS 00000@'
PressSpace      text 'PRESS SPACE TO START@'

StartPage1      text '6502 NOOB  HACKZAW@'                      ; Line 2
StartPage2      text 'PRESENTS@'                                ; Line 3
StartPage3      text 'CITY  BOMBER@'                            ; Line 4
;StartPage4      text 'I WILL DEDICATE THIS GAME TO@'            ; Line 6
StartPage4      text 'I WANT TO THANK THE FOLLOWING@'            ; Line 6
StartPage5      text 'GRAY DEFENDER@'                           ; Line 7
StartPage6      text 'OLDSKOOLCODER@'                           ; Line 8
StartPage7      text 'SHALLAN@'                                 ; Line 9
StartPage8      text 'GRAY AND OLDSKOOLCODER GAVE ME THE@'      ; Line 11
StartPage9      text 'INPIRATION TO START COODING ASSEMBLY@'    ; Line 12
StartPage10     text 'WITH THEIR EASY TO UNDERSTAND TUTORIALS@'      ; Line 13
StartPage11     text 'IT HELPED ME A LOT@'                          ; Line 14
StartPage12     text 'SHALLAN IS IN A LEAGUE OF HIS OWN@'       ; Line 16
StartPage13     text 'HE MAKES IT LOOK SO EASY AND HAVE@'       ; Line 17
StartPage14     text 'GIVEN ME INSIGTH IN MANY TECHNIQUES@'     ; Line 18


#endregion


;****************************************************************************
; Levels
;****************************************************************************          
#region Levels

#endregion


;****************************************************************************
; Includes
;**************************************************************************** 
         
#region Includes

; Load charset into memory location $3000
*=$3000
incbin "char2.bin"


*=$6000
incbin "Level_all_c.bin"

*=$c000
incbin "Level1.bin"
incbin "Level2.bin"
incbin "Level3.bin"
incbin "Level4.bin"
incbin "Level5.bin"
incbin "Level6.bin"
incbin "Level7.bin"
incbin "Level8.bin"
incbin "Level9.bin"
incbin "Levela.bin"
#endregion


