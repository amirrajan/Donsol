
;; constants

PPUCTRL             .equ $2000
PPUMASK             .equ $2001
PPUSTATUS           .equ $2002
SPRADDR             .equ $2003
PPUSCROLL           .equ $2005
PPUADDR             .equ $2006
PPUDATA             .equ $2007
SPRDMA              .equ $4014
SNDCHN              .equ $4015
JOY1                .equ $4016
JOY2                .equ $4017

;; iNES header

  .db  "NES", $1a              ; identification of the iNES header
  .db  1                       ; number of 16KB PRG-ROM pages
  .db  $01                     ; number of 8KB CHR-ROM pages
  .db  $70|%0001               ; mapper 7
  .dsb $09,$00                 ; clear the remaining bytes
  .fillvalue $FF               ; Sets all unused space in rom to value $FF

;; variables

  .enum $0000                  ; Zero Page variables

;;

; player
health                  .dsb 1
shield                  .dsb 1
shield_durability       .dsb 1
experience              .dsb 1
damages                 .dsb 1
difficulty              .dsb 1
; flags
potion_sickness         .dsb 1
can_run                 .dsb 1
has_run                 .dsb 1
; interface
dialog_id               .dsb 1
cursor                  .dsb 1
ui_health               .dsb 1
ui_shield               .dsb 1
; controls
input_timer             .dsb 1
; table
card1                   .dsb 1
card2                   .dsb 1
card3                   .dsb 1
card4                   .dsb 1
room_timer              .dsb 1
room_complete           .dsb 1
; deck
length@deck             .dsb 1
hand@deck               .dsb 1
; tests
test@count              .dsb 1
; stats
card_last               .dsb 1
card_last_type          .dsb 1
card_last_value         .dsb 1
; redraws flags
reqdraws                .dsb 1
reqdraw_hp              .dsb 1
reqdraw_sp              .dsb 1
reqdraw_xp              .dsb 1
reqdraw_cursor          .dsb 1
reqdraw_card1           .dsb 1
reqdraw_card2           .dsb 1
reqdraw_card3           .dsb 1
reqdraw_card4           .dsb 1
reqdraw_dialog          .dsb 1
reqdraw_run             .dsb 1
reqdraw_name            .dsb 1
; 16-bits
cards_low               .dsb 1
cards_high              .dsb 1
cards_temp              .dsb 1
dialogs_low             .dsb 1
dialogs_high            .dsb 1
dialogs_temp            .dsb 1
names_low               .dsb 1
names_high              .dsb 1
names_temp              .dsb 1

;;

  .ende

;;

  .org $C000

;; RESET

RESET:                         ; 
  SEI                          ; disable IRQs
  CLD                          ; disable decimal mode
  LDX #$40
  STX JOY2                     ; disable APU frame IRQ
  LDX #$FF
  TXS                          ; Set up stack
  INX                          ; now X = 0
  STX PPUCTRL                  ; disable NMI
  STX PPUMASK                  ; disable rendering
  STX $4010                    ; disable DMC IRQs
@vwait1:                       ; First wait for vblank to make sure PPU is ready
  BIT PPUSTATUS
  BPL @vwait1
@clear:                        ; 
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x                 ; move all sprites off screen
  INX
  BNE @clear
@vwait2:                       ; Second wait for vblank, PPU is ready after this
  BIT PPUSTATUS
  BPL @vwait2

;; includes

include "src/setup.asm"
include "src/nmi.asm"
include "src/core.asm"
include "src/deck.asm"
include "src/client.asm"
include "src/tests.asm"
include "src/tables.asm"

;; vectors

  .pad $FFFA
  .dw NMI
  .dw RESET
  .dw 0

;; include sprites

  .incbin "src/sprite.chr"