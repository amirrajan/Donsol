
;; selection

moveCursorRight:               ; 
  LDA cursor_pos
  CMP #$03
  BEQ selectNextAround
  INC cursor_pos
  JMP selectNextDone
selectNextAround:              ; 
  LDA #$00
  STA cursor_pos
selectNextDone:                ; 
  LDA #$01
  STA reqdraw_cursor
  RTS

;;

moveCursorLeft:                ; 
  LDA cursor_pos
  CMP #$00
  BEQ selectPrevAround
  DEC cursor_pos
  JMP selectPrevDone
selectPrevAround:              ; 
  LDA #$03
  STA cursor_pos
selectPrevDone:                ; 
  LDA #$01
  STA reqdraw_cursor
  RTS

;; Draw card to the table

drawCard:                      ; (x:card_pos, y:card_id)
  TYA
  STA card1, x
  LDA #$01                     ; Request update
  STA reqdraw_card1, x
  RTS

;; flip card from the table, used in controls when press

flipCard:                      ; (x:card_pos)
  ; check if card is flipped
  LDA card1, x                 ; get card id from table
  CMP #$36
  BEQ @done                    ; skip when card is already flipped
  TAY
  JSR pickCard
  ; flip card
  LDA #$36                     ; $36 is flipped
  STA card1, x
  LDA #$01                     ; Request update
  STA reqdraw_card1, x
  ; misc
  INC experience
  JSR requestUpdateStats
@done:                         ; 
  JSR checkRoom
  JSR checkRun
  RTS

;; Pick card from the deck

pickCard:                      ; (y:card_id)
  TYA                          ; transfer from Y to A
  ; check if card is flipped
  CMP #$36                     ; if card is $36(flipped)
  BEQ @done                    ; skip selection
  ; load card data
  LDA card_types, y
  STA card_last_type           ; load type
  LDA card_values, y
  STA card_last_value          ; load value
  ; branch types
  LDA card_types, y
  CMP #$00
  BEQ selectCardHeart
  CMP #$01
  BEQ selectCardDiamond
  CMP #$02
  BEQ selectCardSpade
  CMP #$03
  BEQ selectCardClover
  CMP #$04
  BEQ selectCardJoker
@done:                         ; 
  RTS

;; selection

selectCardHeart:               ; 
  JSR runPotion
  JSR addPotionSickness
  ; JSR flipCard
  RTS
selectCardDiamond:             ; 
  JSR runShield
  JSR removePotionSickness
  ; JSR flipCard
  RTS
selectCardSpade:               ; 
  JSR runAttack
  JSR removePotionSickness
  ; JSR flipCard
  RTS
selectCardClover:              ; 
  JSR runAttack
  JSR removePotionSickness
  ; JSR flipCard
  RTS
selectCardJoker:               ; 
  JSR runAttack
  JSR removePotionSickness
  ; JSR flipCard
  RTS

;; draw some cards

drawCards:                     ; 
  LDA #$03                     ; heart 4
  STA card1
  LDA #$0E                     ; diamond 5
  STA card2
  LDA #$1F                     ; spades 6
  STA card3
  LDA #$2D                     ; clover 7
  STA card4
  RTS

;; turn(potion)

runPotion:                     ; 
  ; check for potion sickness
  LDA potion_sickness
  CMP #$01
  BEQ runPotionSickness
  ; check for potion waste
  LDA health
  CMP #$15
  BEQ runPotionWaste
  ; heal
  LDA health
  CLC
  ADC card_last_value
  STA health
  ; specials
  JSR clampHealth
  ; dialog:potion
  LDA #$06
  STA dialog_id
  JSR requestUpdateDialog
  RTS

;; turn(potion-sickness)

runPotionSickness:             ; 
  ; dialog:sickness
  LDA #$01
  STA dialog_id
  JSR requestUpdateDialog
  RTS

;; turn(potion-waste)

runPotionWaste:                ; 
  ; dialog:potion
  LDA #$07
  STA dialog_id
  JSR requestUpdateDialog
  RTS

;; turn(shield)

runShield:                     ; 
  LDA card_last_value
  STA shield
  LDA #$16                     ; max durability is $15+1
  STA shield_durability
  ; dialog
  LDA #$05
  STA dialog_id
  JSR requestUpdateDialog
  RTS

;; turn(attack)

runAttack:                     ; 
  ; check if can block
  LDA shield
  CMP #$00
  BNE runAttackBlock
  ; load damages(unblocked)
  LDA card_last_value
  STA damages
  JSR runDamages
  ; dialog:unshielded
  LDA #$08
  STA dialog_id
  JSR requestUpdateDialog
  RTS
runAttackBlock:                ; 
  ; check if shield breaking
  LDA card_last_value
  CMP shield_durability
  BCC runAttackShielded
  ; break shield
  LDA #$00
  STA shield
  STA shield_durability
  ; load damages(unblocked)
  LDA card_last_value
  STA damages
  JSR runDamages
  ; dialog:shield break
  LDA #$02
  STA dialog_id
  JSR requestUpdateDialog
  RTS
runAttackShielded:             ; 
  ; check for overflow
  LDA card_last_value
  CMP shield
  BCC runAttackShieldedFull
runAttackShieldedPartial:      ; 
  ; load damages(partial)
  LDA card_last_value
  SEC
  SBC shield                   ; damages is now stored in A
  STA damages
  JSR runDamages
  ; damage shield
  LDA card_last_value
  STA shield_durability
  ; dialog:damages
  LDA #$0B
  STA dialog_id
  JSR requestUpdateDialog
  RTS
runAttackShieldedFull:         ; 
  ; damage shield
  LDA card_last_value
  STA shield_durability
  ; dialog:blocked
  LDA #$0A
  STA dialog_id
  JSR requestUpdateDialog
  RTS
runDamages:                    ; 
  ; check if killing
  LDA damages
  CMP health
  BCC runDamagesSurvive
runDamagesDeath:               ; 
  LDA #$00
  STA health
  STA shield
  STA experience
  ; dialog:death
  LDA #$03
  STA dialog_id
  JSR requestUpdateDialog
  RTS                          ; stop attack phase
runDamagesSurvive:             ; 
  LDA health
  SEC
  SBC damages
  STA health
  ; dialog:attack
  LDA #$09
  STA dialog_id
  JSR requestUpdateDialog
  RTS

;; flags

addPotionSickness:             ; 
  LDA #$01
  STA potion_sickness
  RTS
removePotionSickness:          ; 
  LDA #$00
  STA potion_sickness
  RTS
clampHealth:                   ; 
  LDA health
  CMP #$15
  BCC clampHealthDone
  LDA #$15
  STA health
clampHealthDone:               ; 
  RTS

;; check for completed room

checkRoom:                     ; 
  LDA #$00
  STA room_complete
  LDA card1
  CMP #$36
  BNE @done
  LDA card2
  CMP #$36
  BNE @done
  LDA card3
  CMP #$36
  BNE @done
  LDA card4
  CMP #$36
  BNE @done
  LDA #$01
  STA room_complete            ; set room_complete to $01
@done:                         ; 
  ; auto change room if all cards are flipped
  LDA room_complete
  CMP #$01
  BEQ @complete
  RTS
@complete:                     ; TODO
  LDA #$30                     ; how long until next draw
  STA room_timer
  RTS

;; room timer for auto change

checkRoomTimer:                ; 
  ; check if room complete is true
  LDA room_complete
  CMP #$00
  BEQ @done
  ; check if room timer is done
  LDA room_timer
  CMP #$00
  BEQ enterNextRoom
  ; decrement timer
  DEC room_timer
@done:                         ; 
  RTS                          ; return from NMI interup

;;

enterNextRoom:                 ; 
  LDA #$00
  STA room_complete
  STA room_timer
  JSR drawHand1
  RTS

;;

countCardsLeft:                ; store count in x
  LDX #$00
countCardsLeft1:               ; 
  LDA card1
  CMP #$36
  BEQ countCardsLeft2
  INX
countCardsLeft2:               ; 
  LDA card2
  CMP #$36
  BEQ countCardsLeft3
  INX
countCardsLeft3:               ; 
  LDA card3
  CMP #$36
  BEQ countCardsLeft4
  INX
countCardsLeft4:               ; 
  LDA card4
  CMP #$36
  BEQ @done
  INX
@done:                         ; 
  RTS

;;

checkRun:                      ; 
  ; Easy Mode: All monsters have been dealt with. 
  ; Normal Mode: And, the player has not escaped the previous room. 
  ; Hard Mode: And, there is only one card left in the room. 
  ; Expert Mode: Can never escape. 
checkRunDisable:               ; 
  LDA #$00
  STA can_run
  JSR requestUpdateRun
  LDA difficulty
  CMP #$00
  BEQ @Easy
  CMP #$01
  BEQ @Normal
  CMP #$00
  BEQ @Hard
  CMP #$00
  BEQ @Expert
@Easy:                         ; (x:cards_left)
  JSR countCardsLeft           ; store cards left in room, in regX
  TXA
  STA $30
  RTS
@Normal:                       ; 
  RTS
@Hard:                         ; 
  RTS
@Expert:                       ; 
  RTS

;;

drawHand1:                     ; 
  LDX #$00
  LDY #$13                     ; Diamonds 7
  JSR drawCard
  LDX #$01
  LDY #$24                     ; Spades 11
  JSR drawCard
  LDX #$02
  LDY #$02                     ; Hearts 3
  JSR drawCard
  LDX #$03
  LDY #$2B                     ; Clubs 5
  JSR drawCard
  RTS

;;

drawHand2:                     ; 
  LDX #$00
  LDY #$1D                     ; Spades 8
  JSR drawCard
  LDX #$01
  LDY #$14                     ; Diamonds 8
  JSR drawCard
  LDX #$02
  LDY #$34                     ; Hearts 4
  JSR drawCard
  LDX #$03
  LDY #$06                     ; Clubs 5
  JSR drawCard
  RTS