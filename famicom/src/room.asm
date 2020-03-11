
;; room

update@room:                   ; update from the nmi
  ; look for unflipped cards
  LDA card1@room
  CMP #$36
  BNE @incomplete
  LDA card2@room
  CMP #$36
  BNE @incomplete
  LDA card3@room
  CMP #$36
  BNE @incomplete
  LDA card4@room
  CMP #$36
  BNE @incomplete
  ; when the room is complete
  LDA timer@room
  CMP #$00
  BEQ @proceed
  DEC timer@room
  RTS
@proceed:                      ; 
  ; reset ran flag
  LDA #$00
  STA has_run@player
  ; reset timer
  LDA #$30
  STA timer@room
  ; go on..
  JSR enter@room
@incomplete:                   ; 
  RTS

;;

enter@room:                    ; 
  JSR pull@deck                ; pull card1
  LDY hand@deck
  TYA
  STA card1@room
  JSR pull@deck                ; pull card2
  LDY hand@deck
  TYA
  STA card2@room
  JSR pull@deck                ; pull card3
  LDY hand@deck
  TYA
  STA card3@room
  JSR pull@deck                ; pull card4
  LDY hand@deck
  TYA
  STA card4@room
  ; etcs
  JSR checkRun
  JSR requestUpdateRun
  JSR requestUpdateCards
  RTS

;; flip card from the table, used in controls when press

flip@room:                     ; (x:card_pos)
  LDA hp@player
  CMP #$00
  BEQ @done
  ; when player is alive
  LDA card1@room, x
  CMP #$36
  BEQ @done
  ; when card is not flipped
  TAY                          ; pick card
  JSR pickCard
  LDA #$36                     ; flip card
  STA card1@room, x
  LDA #$01                     ; request draw
  STA reqdraw_card1, x
@done:                         ; 
  RTS

;;

count@room:                    ; () -> store count in x
  LDX #$00
@card1:                        ; 
  LDA card1@room
  CMP #$36
  BEQ @card2
  INX
@card2:                        ; 
  LDA card2@room
  CMP #$36
  BEQ @card3
  INX
@card3:                        ; 
  LDA card3@room
  CMP #$36
  BEQ @card4
  INX
@card4:                        ; 
  LDA card4@room
  CMP #$36
  BEQ @done
  INX
@done:                         ; 
  RTS

;; running

checkRun:                      ; 
  ; Easy Mode: Can run when has not run before.
  ; Normal Mode: Can run when has not run before, AND there is only 1 monster left.
  ; Hard Mode: Can never run.
  LDA difficulty@player
  CMP #$00
  BEQ @Easy
  CMP #$01
  BEQ @Normal
  CMP #$02
  BEQ @Hard
@Easy:                         ; (x:cards_left)
  ; can at any time, only once
  LDA has_run@player
  CMP #$00
  BEQ @enableRun
  JSR @disableRun
  RTS
@Normal:                       ; 
  ; can run, when has not ran before
  LDA has_run@player
  CMP #$01
  BEQ @disableRun
  ; can run when 3 cards left on table
  JSR count@room               ; store cards left in room, in regX
  TXA
  CMP #$01
  BEQ @enableRun
  RTS
@Hard:                         ; 
  ; can never run
  JSR @disableRun
  RTS
@enableRun:                    ; 
  LDA #$01
  STA can_run@player
  RTS
@disableRun
  LDA #$00
  STA can_run@player
  RTS

;;

tryRun:                        ; 
  ; check if player is alive
  LDA hp@player
  CMP #$00
  BNE @begin
  JSR restart@game
  RTS
@begin:                        ; 
  JSR checkRun
  LDA can_run@player
  CMP #$01
  BNE @unable
  ; record running
  LDA #$01
  STA has_run@player
  ; draw cards for next room
  JSR enter@room
  ; update interface
  JSR requestUpdateRun
  ; dialog:run
  LDA #$0C
  JSR show@dialog
  RTS
@unable:                       ; 
  ; dialog:cannot_run
  LDA #$0D
  JSR show@dialog
  RTS