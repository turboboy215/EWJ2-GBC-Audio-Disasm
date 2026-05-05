;Earthworm Jim: Menace 2 the Galaxy audio (bank 1) disassembly
;Original audio & code by Mark Cooksey
;Disassembly by Will Trowbridge

include "HARDWARE.INC"

def AudioROM equ $4000
def AudioRAM equ $DF00
def WaveRAM equ $FF30

SECTION "Audio1", ROMX[$4000], BANK[$1]

	jp Init


	jp GetSFXMacro


	jp LoadSong


	jp PlaySongSFX


	jp PlaySong


	jp PlaySFXC1


	jp ClearChVol


	jp MusicOn


	jp CheckVolR1


	jp CheckVolNew


	jp ClearAudio


	jp SetTempo


	jp LoadSFX


SetTempo:
	ld [Tempo], a
	ret


PlaySongSFX:
	call PlaySong
	call PlaySFXC1
	ret

;Check the volume of the right speaker - if it is too low, then mute
CheckVolR1:
	ldh a, [rNR50]
	;If volume is 0, then load 0 into B
	and %00000111
	jr z, .CheckVolR10

;Otherwise, decrease and load value into B
	dec a
	or %00001000
	ld b, a
	jp CheckVolL1

;Right volume is 0
.CheckVolR10
	ld b, 0

;Now, check the volume of the left speaker
CheckVolL1:
	ldh a, [rNR50]
	;If volume is 0, then load 0 into A
	and %01110000
	jr z, .CheckVolL10

;Otherwise, decrease and load value into A
	sub $10
	jp CtrlCheck


;Left volume is 0
.CheckVolL10
	ld a, 0

;Check if the resulting values are 0 or not
CtrlCheck:
	or b
	cp 0
	;If not 0, then load new value into NR50
	jr nz, SetMasterVol

	;Otherwise, set values to 0
	call ClearChVol

;Load the value into master volume control
SetMasterVol:
	ldh [rNR50], a
	ret


;Clear all audio
ClearAudio:
	xor a
	ldh [rNR51], a
	ld [MasterPan], a
	ldh [rNR50], a
	ld [PlayFlag], a
	ret


;Clear each channel's volume
ClearChVol:
	ld a, 0
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	ld [PlayFlag], a
	ret


;Turn music on
MusicOn:
	ld a, $FF
	ld [PlayFlag], a
	ret


;Check the status of the audio
CheckVolNew:
	;Set the music play flag
	call MusicOn
	;Check the master volume control
	ldh a, [rNR50]
	cp 0
	;If not 0, then check L and R volumes again
	jr nz, CheckVolR2

	;Otherwise, set volumes off
	ld a, %10001000
	ldh [rNR50], a
	ret


;Check the volume of the right speaker again - if it is not full, then set to max
CheckVolR2:
	and %00000111
	cp %00000111
	jr z, CheckVolL2

	;Increase volume
	add 1
	ld b, a


;Check the volume of the left speaker again
CheckVolL2:
	ldh a, [rNR50]
	;If at full volume
	and %01110000
	srl a
	srl a
	srl a
	srl a
	cp %00000111
	ret z

	;...Then increase volume by 1
	add 1
	sla a
	sla a
	sla a
	sla a
	
	;Set all volume bits
	or b
	or %10001000
	ldh [rNR50], a
	ret


;Get SFX from number
LoadSFX:
	add a
	add a
	ld hl, SFXTab
	add l
	ld l, a
	jr nc, GetSFX

	inc h


;Get first channel macro value
GetSFX:
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP2

	call PlaySFXFromMacro


;Get second channel macro value
.GetSFXP2
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP3

	call PlaySFXFromMacro


;Get third channel macro value
.GetSFXP3
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .GetSFXP4

	call PlaySFXFromMacro


;Get fourth channel macro value
.GetSFXP4
	inc hl
	ld a, [hl]
	;$FF = Skip
	cp $FF
	jr z, .ExitSFX

	call PlaySFXFromMacro


;If no channels used, then return
.ExitSFX
	ret


PlaySFXFromMacro:
	push hl
	call GetSFXMacro
	pop hl
	ret


;Clear RAM and copy waveform
Init:

	;Disable audio
	ld a, 0
	ldh [rNR52], a
	nop
	ldh [rNR52], a
	
	;Clear RAM values
	ld [C1SFXPos], a
	ld [C1SFXPos+1], a
	ld [C2SFXPos], a
	ld [C2SFXPos+1], a
	ld [C3SFXPos], a
	ld [C3SFXPos+1], a
	ld [C4SFXPos], a
	ld [C4SFXPos+1], a
	ld [C1PlayFlag], a
	ld [C2PlayFlag], a
	ld [C3PlayFlag], a
	ld [C4PlayFlag], a
	
	;Set default tempo
	ld a, 255
	ld [Tempo], a

	;Set timer/beat counter
	ld a, 1
	ld [BeatCounter], a
	
	;Copy the waveform into wave RAM
	ld de, WaveRAM
	ld hl, Waveform
	ld b, $10

.CopyWave
	ld a, [hl]
	ld [de], a
	inc hl
	inc de
	dec b
	jr nz, .CopyWave

	call ChannelInit
	ret


;Load song
LoadSong:
;Get song number from A
	ld l, a
	ld h, $00
	
	;Get song address
	;x10 bytes = Song entry length
	add hl, hl
	ld d, h
	ld e, l
	add hl, hl
	add hl, hl
	add hl, de
	;Add to the song table
	ld de, SongTab
	add hl, de
	
	;Load starting positions and note length pointers into RAM
	ld a, [hl+]
	ld [C1Pos], a
	ld a, [hl+]
	ld [C1Pos+1], a
	ld a, [hl+]
	ld [C2Pos], a
	ld a, [hl+]
	ld [C2Pos+1], a
	ld a, [hl+]
	ld [C3Pos], a
	ld a, [hl+]
	ld [C3Pos+1], a
	ld a, [hl+]
	ld [C4Pos], a
	ld a, [hl+]
	ld [C4Pos+1], a
	ld a, [hl+]
	ld [NoteLens], a
	ld a, [hl+]
	ld [NoteLens+1], a
	;Set default note lengths
	ld a, 1
	ld [C1Len], a
	ld [C2Len], a
	ld a, 2
	ld [C3Len], a
	ld [C4Len], a
	;Enable play flags
	ld a, 3
	ld [C1PlayFlag], a
	ld [C2PlayFlag], a
	ld [C3PlayFlag], a
	ld [C4PlayFlag], a
	ld [PlayFlag], a
	ld a, 255
	ld [Tempo], a
	ld a, 1
	ld [BeatCounter], a

ChannelInit:
	;Turn on channels
	ld a, %10001111
	ldh [rNR52], a
	nop
	nop
	ldh [rNR52], a
	;Initialize CH1 sweep
	ld a, %00001000
	ldh [rNR10], a
	
	;Set panning and master volume
	ld a, %11111111
	ldh [rNR51], a
	ld [MasterPan], a
	ld a, %01110111
	ldh [rNR50], a
	
	;Turn on CH3 DAC
	ld a, %10000000
	ldh [rNR30], a
	
	;Clear all channels' volume
	xor a
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR32], a
	ldh [rNR42], a
	
	;Disable macro transpose
	ld [C1MacroTrans], a
	ld [C2MacroTrans], a
	ld [C3MacroTrans], a
	ld [C4MacroTrans], a
	
	;Clear macro flag
	ld [C1InMacro], a
	ld [C2InMacro], a
	ld [C3InMacro], a
	ld [C4InMacro], a
	
	;Also disable Ch4 vibrato sequence
	ld [C4VibSeqDelay], a
	ret


PlaySong:
	;Check to see if the song is currently playing
	ld a, [PlayFlag]
	and a
	ret z

	;Get the current song tempo and number of beats
	ld a, [Tempo]
	ld b, a
	ld a, [BeatCounter]
	add b
	ld [BeatCounter], a
	;Don't update if no overflow
	ret nc

StartC1:
	;Set current channel number (0)
	xor a
	ld [CurChan], a
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC1
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C1MacroTrans]
	ld [CurTrans], a
	ld hl, C1PlayFlag
	ld de, rNR11
	call GetNextByte
	;Check if the current channel is active
	ld a, [C1PlayFlag]
	and %00000001
	;If not, then skip to channel 2
	jp z, StartC2

	;Check if the current channel is active for SFX
	ld a, [C1SFXPos+1]
	and a
	;If so, then skip to channel 2
	jp nz, StartC2

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C1EnvSeqDelay
	ld de, C1EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR12
	call CheckEnvSeqDelay
	ld de, C1EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	ld hl, C1PlayFlag
	ld de, rNR13
	call SetPerLo
	;Process the channel vibrato from sequence
	ld hl, C1VibSeqDelay
	ld de, C1VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C1Freq+1
	call CheckVibSeqDelay
	ld de, C1VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Check delay for pitch modulation sequence
	ld a, [C1ModSeqDelay]
	and a
	;If value is 0, then skip
	jr z, StartC2

.C1ProcessModSeq
	;Otherwise, decrement
	dec a
	ld [C1ModSeqDelay], a
	and a
	;If delay has not yet finished, then return
	jr nz, StartC2

	;Load sequence pointer from RAM
	ld a, [C1ModSeq]
	ld c, a
	ld a, [C1ModSeq+1]
	ld b, a
	ld a, [bc]
	;If reached loop point (FF)...
	cp $FF
	jr z, .C1ProcessModLoop

	;Otherwise, store the next value as new delay in RAM
	ld [C1ModSeqDelay], a
	inc bc
	;Next byte = note frequency change
	ld a, [bc]
	;Add to current note
	ld e, a
	ld a, [CurNoteC1]
	add e
	push af
	;Get the high frequency byte and add it
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .C1ProcessModSeq2

	inc d

.C1ProcessModSeq2
	ld a, [de]
	ld [C1Freq], a
	pop af
	;Now get the low frequency byte and add it
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .C1ProcessModSeq3

	inc d

.C1ProcessModSeq3
	ld a, [de]
	ld [C1Freq+1], a
	;Advance to the next part of the sequence
	inc bc
	;Store the updated pointer in RAM
	ld a, c
	ld [C1ModSeq], a
	ld a, b
	ld [C1ModSeq+1], a
	jp StartC2


;Go to pitch modulation sequence loop
.C1ProcessModLoop
	;Reset the delay to 1
	ld a, 1
	ld [C1ModSeqDelay], a
	;Go to the position in the following pointer (2 bytes)
	inc bc
	ld a, [bc]
	ld [C1ModSeq], a
	inc bc
	ld a, [bc]
	ld [C1ModSeq+1], a

StartC2:
	;Set current channel number (1)
	ld a, 1
	ld [CurChan], a
	;Save current code position for restart	
	ld hl, CurRestartPos
	ld de, StartC2
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C2MacroTrans]
	ld [CurTrans], a
	ld hl, C2PlayFlag
	ld de, rNR21
	call GetNextByte
	;Check if the current channel is active
	ld a, [C2PlayFlag]
	and %00000001
	;If not, then skip to channel 3
	jp z, StartC3

	;Check if the current channel is active for SFX
	ld a, [C2SFXPos+1]
	and a
	;If so, then skip to channel 3
	jp nz, StartC3

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C2EnvSeqDelay
	ld de, C2EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR22
	call CheckEnvSeqDelay
	ld de, C2EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	ld hl, C2PlayFlag
	ld de, rNR23
	call SetPerLo
	;Process the channel vibrato from sequence
	ld hl, C2VibSeqDelay
	ld de, C2VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C2Freq+1
	call CheckVibSeqDelay
	ld de, C2VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Check delay for pitch modulation sequence
	ld a, [C2ModSeqDelay]
	and a
	;If value is 0, then skip
	jr z, StartC3

.C2ProcessModSeq
	;Otherwise, decrement
	dec a
	ld [C2ModSeqDelay], a
	and a
	;If delay has not yet finished, then return
	jr nz, StartC3

	;Load sequence pointer from RAM
	ld a, [C2ModSeq]
	ld c, a
	ld a, [C2ModSeq+1]
	ld b, a
	ld a, [bc]
	cp $FF
	jr z, .C2ProcessModLoop

	;Otherwise, store the next value as new delay in RAM
	ld [C2ModSeqDelay], a
	inc bc
	;Next byte = note frequency change
	ld a, [bc]
	;Add to current note
	ld e, a
	ld a, [CurNoteC2]
	add e
	push af
	;Get the high frequency byte and add it
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .C2ProcessModSeq2

	inc d

.C2ProcessModSeq2
	ld a, [de]
	ld [C2Freq], a
	pop af
	;Now get the low frequency byte and add it
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .C2ProcessModSeq3

	inc d

.C2ProcessModSeq3
	ld a, [de]
	ld [C2Freq+1], a
	;Advance to the next part of the sequence
	inc bc
	;Store the updated pointer in RAM
	ld a, c
	ld [C2ModSeq], a
	ld a, b
	ld [C2ModSeq+1], a
	jp StartC3


;Go to pitch modulation sequence loop
.C2ProcessModLoop
	;Reset the delay to 1
	ld a, 1
	ld [C2ModSeqDelay], a
	;Go to the position in the following pointer (2 bytes)
	inc bc
	ld a, [bc]
	ld [C2ModSeq], a
	inc bc
	ld a, [bc]
	ld [C2ModSeq+1], a

StartC3:
	;Set current channel number (2)
	ld a, 2
	ld [CurChan], a
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC3
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C3MacroTrans]
	ld [CurTrans], a
	ld hl, C3PlayFlag
	ld de, rNR31
	call GetNextByte
	;Check if the current channel is active
	ld a, [C3PlayFlag]
	and %00000001
	;If not, then skip to channel 4
	jp z, StartC4

	;Check if the current channel is active for SFX
	ld a, [C3SFXPos+1]
	and a
	;If so, then skip to channel 3
	jp nz, StartC4

	;Get instrument parameter bytes
	;Set period
	ld hl, C3PlayFlag
	ld de, rNR33
	call SetPerLo
	;Process the channel envelope from sequence
	ld hl, C3EnvSeqDelay
	ld de, C3EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR32
	call CheckEnvSeqDelay
	ld de, C3EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Process the channel vibrato from sequence
	ld hl, C3VibSeqDelay
	ld de, C3VibSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	;Get the low of the frequency
	ld de, C3Freq+1
	call CheckVibSeqDelay
	ld de, C3VibSeq
	;Store updated vibrato sequence pos. in RAM
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Check delay for pitch modulation sequence
	ld a, [C3ModSeqDelay]
	and a
	;If value is 0, then skip
	jr z, StartC4

.C3ProcessModSeq
	;Otherwise, decrement
	dec a
	ld [C3ModSeqDelay], a
	and a
	;If delay has not yet finished, then return
	jr nz, StartC4

	;Load sequence pointer from RAM
	ld a, [C3ModSeq]
	ld c, a
	ld a, [C3ModSeq+1]
	ld b, a
	ld a, [bc]
	;If reached loop point (FF)...
	cp $FF
	jr z, .C3ProcessModLoop

	;Otherwise, store the next value as new delay in RAM
	ld [C3ModSeqDelay], a
	inc bc
	;Next byte = note frequency change
	ld a, [bc]
	;Add to current note
	ld e, a
	ld a, [CurNoteC3]
	add e
	push af
	;Get the high frequency byte and add it
	ld de, FreqsHi
	add e
	ld e, a
	jr nc, .C3ProcessModSeq2

	inc d

.C3ProcessModSeq2
	ld a, [de]
	ld [C3Freq], a
	pop af
	;Now get the low frequency byte and add it
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .C2ProcessModSeq3

	inc d

.C2ProcessModSeq3
	ld a, [de]
	ld [C3Freq+1], a
	;Advance to the next part of the sequence
	inc bc
	;Store the updated pointer in RAM
	ld a, c
	ld [C3ModSeq], a
	ld a, b
	ld [C3ModSeq+1], a
	jp StartC4


;Go to pitch modulation sequence loop
.C3ProcessModLoop
	;Reset the delay to 1
	ld a, 1
	ld [C3ModSeqDelay], a
	;Go to the position in the following pointer (2 bytes)
	inc bc
	ld a, [bc]
	ld [C3ModSeq], a
	inc bc
	ld a, [bc]
	ld [C3ModSeq+1], a

StartC4:
	;Set current channel number (3)
	ld a, 3
	ld [CurChan], a
	;Save current code position for restart
	ld hl, CurRestartPos
	ld de, StartC4
	ld [hl], e
	inc hl
	ld [hl], d
	;Load current channel macro transpose
	ld a, [C4MacroTrans]
	ld [CurTrans], a
	ld hl, C4PlayFlag
	ld de, rNR41
	call GetNextByte
	;Check if the current channel is active
	ld a, [C4PlayFlag]
	and %00000001
	;If not, then set period and return
	jr z, .C4SetPeriod

	;Check if the current channel is active for SFX
	ld a, [C4SFXPos+1]
	and a
	;If value is 0, then skip
	jp nz, .C4SetPeriod

	;Get instrument parameter bytes
	;Process the channel envelope from sequence
	ld hl, C4EnvSeqDelay
	ld de, C4EnvSeq
	ld a, [de]
	ld c, a
	inc de
	ld a, [de]
	ld b, a
	ld de, rNR42
	call CheckEnvSeqDelay
	ld de, C4EnvSeq
	ld a, c
	ld [de], a
	ld a, b
	inc de
	ld [de], a
	;Now process the vibrato envelope
	call C4CheckVibSeqDelay

.C4SetPeriod
	ld hl, C4PlayFlag
	ld de, rNR43
	call SetPerLo
	ret


CheckEnvSeqDelay:
;Check if envelope sequence is enabled
	ld a, [hl]
	and a
	ret z

	;Otherwise, decrement
	dec [hl]
	;If delay has not yet finished, then return
	ret nz

	;Otherwise, check if reached end of pattern (value FF)
	ld a, [bc]
	cp $FF
	;If not, then keep going
	jr nz, ProcessEnvSeq

	;Otherwise, then disable envelope sequence
	ld a, 0
	ld [hl], a
	ret


ProcessEnvSeq:
	;Write the volume to the register
	ld [de], a
	;Get next byte
	inc bc
	ld a, [bc]
	;Set delay for next envelope value
	ld [hl], a
	;Now go to frequency...
	ld a, l
	sub 6
	ld l, a
	jr nc, .ProcessEnvSeq2

	dec h

.ProcessEnvSeq2
	;and reset the trigger
	ld a, [hl]
	or $80
	ld [hl], a
	;Then store the current duty into RAM
	ld a, l
	add 4
	ld l, a
	jr nc, .ProcessEnvSeq3

	inc h

.ProcessEnvSeq3
	ld a, [de]
	ld [hl], a
	;Go to next byte in sequence
	inc bc
	ret


CheckVibSeqDelay:
	;If value is 0, then return
	ld a, [hl]
	and a
	ret z

	;If delay is more than 1, then return (wait)
	dec [hl]
	ret nz

	;Load delay into RAM
	inc bc
	ld a, [bc]
	push hl
	ld [hl], a
	dec bc
	;Load current frequency from RAM
	ld a, [de]
	ld l, a
	dec de
	ld a, [de]
	ld h, a
	;Now get vibrato value
	ld a, [bc]
	;Is it a stop command?
	cp $7E
	jr nz, ProcessVibSeq

	pop hl
	ret


ProcessVibSeq:
	;Is it a loop command?
	cp $7D
	;If so, then keep checking
	jr z, ProcessVibLoop

	;Is it negative?
	cp $7F
	;If so, then subtract from frequency
	jr nc, .SubVibFreq

;Otherwise, add to frequency
.AddVibFreq
	add l
	ld l, a
	jr nc, .ProcessVibSeq2

	inc h

.ProcessVibSeq2
	jr .ProcessVibSeq3

.SubVibFreq
	add l
	ld l, a
	jr c, .ProcessVibSeq3

	dec h

.ProcessVibSeq3
	;Load the new frequency into RAM
	ld a, h
	ld [de], a
	inc de
	ld a, l
	ld [de], a
	
	;Go to the next entry and return
	inc bc
	inc bc
	pop hl
	ret


ProcessVibLoop:
	;Get the next 2 bytes (pointer) and jump to position
	inc bc
	ld a, [bc]
	push af
	inc bc
	ld a, [bc]
	ld b, a
	pop af
	ld c, a
	pop hl
	;Reset the delay to 1
	ld a, 1
	ld [hl], a
	ret


GetNextByte:
	;Check to see if the current channel is 1-3
	ld a, [hl]
	and %00000010
	;Return if it is 4
	ret z

	;Otherwise, then go to channel note length
	inc hl
	dec [hl]
	;Return if still playing note
	ret nz

	;Otherwise, then get next command
	inc hl
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, [bc]
	
	;Load the current command value into RAM
	ld [CurCmd], a
	;Mask out the highest bit
	and %01111111
	
	;Is it a note?
	cp $5F
	;If not, then it must be a command
	jp nc, GetVCMD

	;Save current audio register value
	push de
	
	;Get the current transpose
	ld de, CurTrans
	ld a, [de]
	ld d, a
	;And get the current byte
	ld a, [bc]
	;Mask out the highest bit
	and %01111111
	;Add the transpose
	add d
	ld d, a
	
	;Save the current note value
	push af
	ld a, [CurChan]
CheckC1:
	;Is the channel 1?
	cp 0
	;If not, then skip to channel 2
	jr nz, CheckC2

	;Otherwise, then save current Ch1 note
	ld a, d
	ld [CurNoteC1], a

CheckC2:
	;Is the channel 2?
	cp 1
	;If not, then skip to channel 3
	jr nz, CheckC3

	ld a, d
	ld [CurNoteC2], a

CheckC3:
	;Is the channel 3?
	cp 2
	;If not, then skip to the next part
	jr nz, GetFreq

	ld a, d
	ld [CurNoteC3], a

;Get the current frequency
GetFreq:
	pop af
	ld de, FreqsHi
	add e
	ld e, a
	jp nc, .GetFreq2

	inc d

.GetFreq2
	ld a, [de]
	;Load that value into RAM
	inc hl
	ld [hl], a
	;Get current transpose value
	ld de, CurTrans
	ld a, [de]
	ld d, a
	;And get current note again
	ld a, [bc]
	;Mask off the highest bit
	and %01111111
	;Add the transpose
	add d
	;Now get the low byte from table
	ld de, FreqsLo
	add e
	ld e, a
	jr nc, .GetFreq3

	inc d

.GetFreq3
	ld a, [de]
	inc hl
	ld [hl], a
	
;Now get the note length from the next byte
GetLen:	
	inc bc
	ld a, [bc]
	;Mask off the upper 4 bits to get the note length index
	and %00001111
	push hl
	;Get the address of the current note length
	ld hl, NoteLens+1
	ld d, [hl]
	dec hl
	ld e, [hl]
	pop hl
	add e
	ld e, a
	jr nc, .GetLen2

	inc d

.GetLen2
	ld a, [de]
	;Store the current note length value in RAM
	ld de, -4
	add hl, de
	ld [hl], a
	
;Now get the instrument from the first bit of byte 1 and lower 4 bits of byte 2
GetInst:
	;Get the first note byte again
	ld a, [CurCmd]
	;If bit is set, then add 32 to total (instrument is +16)
	and %10000000
	srl a
	srl a
	ld d, a
	;Now get the second byte again
	ld a, [bc]
	;Mask out the lower 4 bits to get the instrument number
	and %11110000
	;Shift right to calculate the instrument offset (2 x instrument number)
	srl a
	srl a
	srl a
	;Add the extra 32 bytes if present
	add d
	
	;Get the current instrument offset in table
	push hl
	ld hl, InsTab
	add l
	ld l, a
	jr nc, .GetInst2

	inc h

.GetInst2
	;Load the current instrument address into RAM
	ld e, [hl]
	inc hl
	ld d, [hl]
	pop hl
	
	;Update the position and load it into RAM
	inc bc
	inc hl
	ld [hl], c
	inc hl
	ld [hl], b
	ld b, d
	ld c, e
	pop de
	inc hl
	;Instrument byte 1 - Period control
	ld a, [bc]
	or [hl]
	ld [hl], a
	inc hl
	inc hl
	inc hl
	;Instrument byte 2 - Duty
	inc bc
	ld a, [bc]
	ld [hl], a
	;Instrument byte 3 - Initial volume/envelope
	inc bc
	inc de
	inc hl
	ld a, [bc]
	ld [hl], a
	inc hl
	inc hl
	inc bc
	;Instrument byte 4 - Volume/envelope sequence delay
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 5-6 = Volume/envelope sequence pointer
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 7 = Vibrato sequence delay
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	;Instrument byte 8-9 = Vibrato sequence pointer
	ld a, [bc]
	ld [hl], a
	inc hl
	inc bc
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	;Instrument byte 10 = Pitch modulation sequence delay
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	;Instrument byte 11-12 = Pitch modulation sequence pointer
	ld a, [bc]
	ld [hl], a
	inc bc
	inc hl
	ld a, [bc]
	ld [hl], a
	ret


;Set frequency/period (low)
SetPerLo:
;Check if channel is active
	ld a, [hl]
	and %00000001
	;Return if not active
	ret z

	;Get second byte of frequency (period low)
	ld bc, 5
	add hl, bc
	ld a, e
	;Go to another method if channel 4
	cp LOW(rNR43)
	jp z, SetC4Freq

	;Otherwise, load the period low into register NRx3
	ld a, [hl]
	ld [de], a

CheckPerTrigger:
	;Now check the period high
	dec hl
	inc de
	;Save the period address and RAM location
	push de
	push hl
	;If trigger is set, then don't set the duty and envelope
	ld a, [hl]
	and %10000000
	jr z, SetPerHi

	;Set duty from RAM value
	ld bc, 3
	add hl, bc
	dec de
	dec de
	dec de
	ld a, [hl]
	ld [de], a
	;Set envelope from RAM value
	inc hl
	inc de
	ld a, [hl]
	ld [de], a

SetPerHi:
;Set period (high)
	;Load the period low (with trigger) value from RAM
	pop hl
	pop de
	ld a, [hl]
	ld [de], a
	
	;Clear the trigger in RAM
	and %01111111
	ld [hl], a
	ret


SetC4Freq:
	;Load the current noise frequency from RAM variable into Ch4 RAM and NR43
	ld a, [CurNoise]
	ld [C4Freq+1], a
	ld [de], a
	;Then do the rest
	jr CheckPerTrigger

C4CheckVibSeqDelay:
	;If value is 0, then return
	ld a, [C4VibSeqDelay]
	and a
	ret z

	;Otherwise, decrement
	dec a
	ld [C4VibSeqDelay], a
	and a
	ret nz

	;Load noise vibrato pointer from RAM
	ld a, [C4VibSeq]
	ld l, a
	ld a, [C4VibSeq+1]
	ld h, a
	ld a, [hl]
	;Is it a stop command?
	cp $7E
	;Then return
	ret z

	;Is it a loop command?
	cp $7D
	;If so, then keep checking
	jr z, C4ProcessVibLoop

	;Otherwise, set the current noise frequency from sequence
	ld [CurNoise], a
	inc hl
	ld a, [hl]
	ld [C4VibSeqDelay], a
	inc hl
	;Store the new delay and updated pointer in RAM
	ld a, l
	ld [C4VibSeq], a
	ld a, h
	ld [C4VibSeq+1], a
	ret


C4ProcessVibLoop:
	;Reset the delay to 1
	ld a, 1
	ld [C4VibSeqDelay], a
	;Get the next 2 bytes (pointer) and jump to position
	inc hl
	ld a, [hl]
	ld [C4VibSeq], a
	inc hl
	ld a, [hl]
	ld [C4VibSeq+1], a
	ret


VCMDTable:
	dw EventTie			;$60
	dw EventStop		;$61
	dw EventJump		;$62
	dw EventNoise		;$63
	dw EventMacro		;$64
	dw EventMacroRet	;$65
	dw EventCondFlag	;$66
	dw EventGlobalPan	;$67
	dw EventNoteLens	;$68
	dw EventTempo		;$69
	dw EventC1Pan		;$6A
	dw EventC2Pan		;$6B
	dw EventC3Pan		;$6C
	dw EventC4Pan		;$6D

GetVCMD:
;Get the current voice command (VCMD)
	sub $60
	add a
	push hl
	;Increment the channel note length/delay
	dec hl
	dec hl
	inc [hl]
	;Get the pointer to the VCMD
	ld hl, VCMDTable+1
	add l
	ld l, a
	jr nc, .GetVCMD2

	inc h

.GetVCMD2
	ld a, [hl]
	dec hl
	ld l, [hl]
	ld h, a
	jp hl

EventTie:
;Delay the next note by length, increasing note length
	;Get the note lengths pointer
	;Parameters: -x (- = unused, x = length)
	ld hl, NoteLens+1
	ld a, [hl]
	dec hl
	ld l, [hl]
	ld h, a
	inc bc
	ld a, [bc]
	;Mask out the upper 4 bits to get the length index
	and %00001111
	add l
	ld l, a
	jr .EventTie2

	inc h

.EventTie2
	;Get the note length from the pointer
	ld a, [hl]
	pop hl
	;Add the length to the current note length
	ld de, -2
	add hl, de
	ld [hl], a
	;Update the pointer
	inc bc
	inc hl
	jp UpdatePtr

EventStop:
	;Stop the channel
	pop hl
	;Set the channel play flag to 0
	ld bc, -3
	add hl, bc
	ld a, 0
	ld [hl], a
	ret

EventJump:
;Jump to the following pointer (used for looping)
;Parameters: xx xx (x = Pointer)
	;Set the channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Get the pointer from the next 2 values and load into RAM
	inc bc
	ld a, [bc]
	ld [hl+], a
	inc bc
	ld a, [bc]
	ld [hl], a
	jp GotoRestart

EventNoise:
;Change the noise frequency value (NR43)
;Parameters: xx (X = Value)
	pop hl
	;Get next noise parameter and load it into RAM
	inc bc
	ld a, [bc]
	ld [CurNoise], a
	;Set channel note length to 1
	ld de, -2
	add hl, de
	ld a, 1
	;Update pointer
	ld [hl+], a
	inc bc
	call UpdatePtr
	jp GotoRestart

EventMacro:
;Go to a macro (subroutine) with transpose for specified number of times
;Parameters: xxxx yy zz (X = Pointer, Y = Transpose, Z = Number of times)
;(Note: 1 level only)
	;Set channel length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Then get macro number from parameter byte
	inc bc
	ld a, [bc]
	sla a
	jr nc, .EventMacro2
	;Add to macro table
	ld de, SongMacroTab
	inc d
	jr .EventMacro3

.EventMacro2
	;Add to macro table
	ld de, SongMacroTab

.EventMacro3
	add e
	ld e, a
	jr nc, .EventMacro4

	inc d

.EventMacro4
	ld a, [de]
	;Load the macro position in RAM
	ld [hl+], a
	inc de
	ld a, [de]
	ld [hl+], a
	;Now get the macro transpose value and load it into RAM
	ld d, h
	ld e, l
	ld a, $10
	add e
	ld e, a
	jr nc, .EventMacro5

	inc d

.EventMacro5
	inc bc
	ld a, [bc]
	ld [de], a
	inc de
	;Now check the macro flag in RAM
	ld a, [de]
	and a
	;If 0, then get the times in macro
	jr z, .EventMacro6

	inc bc
	jr .EventMacro7

.EventMacro6
	ld a, 1
	ld [de], a
	;Now get the number of times in macro and load into RAM (times left)
	dec de
	dec de
	inc bc
	ld a, [bc]
	;Subtract 1 to get actual number
	sub 1
	ld [de], a
	inc de
	inc de

.EventMacro7
	;Now store the address to return from the macro into RAM
	inc bc
	inc de
	ld a, c
	ld [de], a
	inc de
	ld a, b
	ld [de], a
	jp GotoRestart

EventMacroRet:
	;Reset macro transpose to 0
	inc bc
	;Set channel length flag to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Now check for macro times left
	ld d, h
	ld e, l
	ld a, $11
	add e
	ld e, a
	jr nc, .EventMacroRet2

	inc d

.EventMacroRet2
	ld a, [de]
	and a
	jr z, EventMacroRetEnd

	;Otherwise, subtract 1 and jump to macro start
	sub 1
	ld [de], a
	inc de
	inc de
	inc de
	;Update the position in RAM (use macro return and subtract 4 to get start position)
	ld a, [de]
	sub 4
	ld [hl+], a
	inc de
	ld a, [de]
	jr nc, .EventMacroRet3

	sub 1

.EventMacroRet3
	;Jump to the macro start position
	ld [hl], a
	jp GotoRestart


EventMacroRetEnd:
	;Reset macro transpose to 0
	inc de
	ld a, 0
	;And macro flag to 0
	ld [de], a
	inc de
	ld [de], a
	;Set position to return from macro (from RAM)
	inc de
	ld a, [de]
	ld [hl+], a
	inc de
	ld a, [de]
	ld [hl], a
	;Go to start code
	jp GotoRestart

EventCondFlag:
	;Set a conditional flag (not used by the driver)
	;Parameters: xx (X = Value)
	inc bc
	ld a, [bc]
	ld [LoopFlag], a
	;Set channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	inc bc
	call UpdatePtr
	jp GotoRestart

EventGlobalPan:
	;Set global panning
	;Parameters: xx (X = Value, see NR51 usage)
	inc bc
	ld a, [bc]
	ldh [rNR51], a
	ld [MasterPan], a

;Reset the note by setting the channel length to 1
ResetNote:
	;Set channel note length to 1
	inc bc
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	call UpdatePtr
	jr GotoRestart

EventC1Pan:
;Set channel 1 panning
;Parameters: xx (X = Value, only channel 1 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 1 bits
	ld a, [MasterPan]
	and %11101110
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote

EventC2Pan:
;Set channel 2 panning
;Parameters: xx (X = Value, only channel 2 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 2 bits
	ld a, [MasterPan]
	and %11011101
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote

EventC3Pan:
;Set channel 3 panning
;Parameters: xx (X = Value, only channel 3 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 3 bits
	ld a, [MasterPan]
	and %10111011
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote

EventC4Pan:
;Set channel 4 panning
;Parameters: xx (X = Value, only channel 4 bits are used)
	inc bc
	;Get current panning (NR51) value and mask out channel 4 bits
	ld a, [MasterPan]
	and %01110111
	ld h, a
	;Mask in parameter values
	ld a, [bc]
	or h
	;Store new value into RAM and register
	ld [MasterPan], a
	ldh [rNR51], a
	jr ResetNote

EventNoteLens:
;Set note lengths from the following pointer (for all channels)
;Parameters: xx xx (X = Pointer)
	inc bc
	ld a, [bc]
	ld [NoteLens], a
	inc bc
	ld a, [bc]
	ld [NoteLens+1], a
	;Set channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	inc bc
	call UpdatePtr
	jr GotoRestart

EventTempo:
;Set the tempo
;Parameters: x (X = Value)
	inc bc
	ld a, [bc]
	ld [Tempo], a
	;Set channel note length to 1
	pop hl
	ld de, -2
	add hl, de
	ld a, 1
	ld [hl+], a
	;Update the channel pointer
	inc bc
	call UpdatePtr
	jr GotoRestart

UpdatePtr:
	ld [hl], c
	inc hl
	ld [hl], b
	ret


GotoRestart:
	pop hl
	ld de, CurRestartPos
	ld a, [de]
	ld l, a
	inc de
	ld a, [de]
	ld h, a
	jp hl


FreqsLo:
	db LOW($009D), LOW($0107), LOW($016B), LOW($01CA), LOW($0223), LOW($0278), LOW($02C7), LOW($0312), LOW($0359), LOW($039C), LOW($03DB), LOW($0417)
	db LOW($044F), LOW($0484), LOW($04B6), LOW($04E5), LOW($0512), LOW($053C), LOW($0564), LOW($0589), LOW($05AD), LOW($05CE), LOW($05EE), LOW($060C)
	db LOW($0628), LOW($0642), LOW($065B), LOW($0673), LOW($0689), LOW($069E), LOW($06B2), LOW($06C5), LOW($06D7), LOW($06E7), LOW($06F7), LOW($0706)
	db LOW($0714), LOW($0721), LOW($072E), LOW($073A), LOW($0745), LOW($074F), LOW($0759), LOW($0763), LOW($076C), LOW($0774), LOW($077C), LOW($0783)
	db LOW($078A), LOW($0791), LOW($0797), LOW($079D), LOW($07A3), LOW($07A8), LOW($07AD), LOW($07B1), LOW($07B6), LOW($07BA), LOW($07BE), LOW($07C2)
	db LOW($07C5), LOW($07C9), LOW($07CC), LOW($07CF), LOW($07D2), LOW($07D4), LOW($07D7), LOW($07D9), LOW($07DB), LOW($07DD), LOW($07DF), LOW($07E1)
	db LOW($07E3), LOW($07E5), LOW($07E6), LOW($07E8), LOW($07E9), LOW($07EA), LOW($07EC), LOW($07ED), LOW($07EE), LOW($07EF), LOW($07F0), LOW($07F1)
	db LOW($07F2), LOW($07F3), LOW($07F3), LOW($07F4), LOW($07F5), LOW($07F5), LOW($07F7), LOW($07F7), LOW($07F8), LOW($07F8), LOW($07FA), LOW($07FA)

FreqsHi:
	db HIGH($009D), HIGH($0107), HIGH($016B), HIGH($01CA), HIGH($0223), HIGH($0278), HIGH($02C7), HIGH($0312), HIGH($0359), HIGH($039C), HIGH($03DB), HIGH($0417)
	db HIGH($044F), HIGH($0484), HIGH($04B6), HIGH($04E5), HIGH($0512), HIGH($053C), HIGH($0564), HIGH($0589), HIGH($05AD), HIGH($05CE), HIGH($05EE), HIGH($060C)
	db HIGH($0628), HIGH($0642), HIGH($065B), HIGH($0673), HIGH($0689), HIGH($069E), HIGH($06B2), HIGH($06C5), HIGH($06D7), HIGH($06E7), HIGH($06F7), HIGH($0706)
	db HIGH($0714), HIGH($0721), HIGH($072E), HIGH($073A), HIGH($0745), HIGH($074F), HIGH($0759), HIGH($0763), HIGH($076C), HIGH($0774), HIGH($077C), HIGH($0783)
	db HIGH($078A), HIGH($0791), HIGH($0797), HIGH($079D), HIGH($07A3), HIGH($07A8), HIGH($07AD), HIGH($07B1), HIGH($07B6), HIGH($07BA), HIGH($07BE), HIGH($07C2)
	db HIGH($07C5), HIGH($07C9), HIGH($07CC), HIGH($07CF), HIGH($07D2), HIGH($07D4), HIGH($07D7), HIGH($07D9), HIGH($07DB), HIGH($07DD), HIGH($07DF), HIGH($07E1)
	db HIGH($07E3), HIGH($07E5), HIGH($07E6), HIGH($07E8), HIGH($07E9), HIGH($07EA), HIGH($07EC), HIGH($07ED), HIGH($07EE), HIGH($07EF), HIGH($07F0), HIGH($07F1)
	db HIGH($07F2), HIGH($07F3), HIGH($07F3), HIGH($07F4), HIGH($07F5), HIGH($07F5), HIGH($07F7), HIGH($07F7), HIGH($07F8), HIGH($07F8), HIGH($07FA), HIGH($07FA)

GetSFXMacro:
	;Get SFX macro pointer from table
	ld hl, SFXMacroTab
	sla a
	add l
	ld l, a
	jr nc, InitSFX

	inc h

InitSFX:
	;Go to SFX pointer
	ld a, [hl]
	ld c, a
	inc hl
	ld a, [hl]
	ld b, a
	;Enable all channels
	ld a, %10001111
	ldh [rNR52], a
	;Check the channel number
	ld a, [bc]
	inc bc
	
	;Is it channel 2?
	cp 1
	jr z, InitSFXC2

	;Is it channel 3?
	cp 2
	jr z, InitSFXC3

	;Is it channel 4?
	cp 3
	jr z, InitSFXC4

	;Otherwise, it is channel 1
InitSFXC1:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %00010001
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C1PlayFlag]
	and %11111110
	ld [C1PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C1SFXPos], a
	ld a, b
	ld [C1SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C1SFXDelay], a
	jr PlaySFXC1

InitSFXC2:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %00100010
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C2PlayFlag]
	and %11111110
	ld [C2PlayFlag], a
	;Enable SFX playback with flag
	ld a, c
	ld [C2SFXPos], a
	ld a, b
	ld [C2SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C2SFXDelay], a
	jr PlaySFXC1

InitSFXC3:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %01000100
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C3PlayFlag]
	and %11111110
	ld [C3PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C3SFXPos], a
	ld a, b
	ld [C3SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C3SFXDelay], a
	jr PlaySFXC1

InitSFXC4:
	;Set panning
	ld a, [MasterPan]
	ld d, a
	ld a, %10001000
	or d
	ld [MasterSFXPan], a
	;Enable SFX playback with flag
	ld a, [C4PlayFlag]
	and %11111110
	ld [C4PlayFlag], a
	;Go to SFX position from RAM
	ld a, c
	ld [C4SFXPos], a
	ld a, b
	ld [C4SFXPos+1], a
	;Set SFX channel delay
	ld a, 2
	ld [C4SFXDelay], a

;Play the current sound effect, starting with channel 1 if present
PlaySFXC1:
	ld hl, C1PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C1SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC2

	;Otherwise, then play SFX
	ld de, rNR11
	call CheckSFX

PlaySFXC2:
	ld hl, C2PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C2SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC3

	ld de, rNR21
	call CheckSFX

PlaySFXC3:
	ld hl, C3PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C3SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then go to next channel
	jr z, PlaySFXC4

	ld de, rNR31
	call CheckSFX

PlaySFXC4:
	ld hl, C4PlayFlag
	ld a, l
	ld [CurSFX], a
	ld a, h
	ld [CurSFX+1], a
	ld hl, C4SFXPos
	ld c, [hl]
	inc hl
	ld b, [hl]
	ld a, b
	or c
	;If not present (0 value), then return
	jr z, PlaySFXRet

	ld de, rNR41
	call CheckSFX

;Return from SFX routine
PlaySFXRet:
	ret


CheckSFX:
	;Set the panning for SFX
	ld a, [MasterSFXPan]
	ldh [rNR51], a
	;Check if channel is ready
	inc hl
	dec [hl]
	;If so, then continue
	jr z, GetNextSFXCMD

	;Otherwise, return
	ret


GetNextSFXCMD:
	;Get the next SFX command
	ld a, [bc]
	;Is it a stop command (FF)?
	cp $FF
	jr z, SFXEventStop

	;Is it a jump command (FE)?
	cp $FE
	jr z, SFXEventJump

	;Otherwise...
	;Byte 1 = Delay
	ld [hl], a
	;Byte 2 = NRx1 (Channel length/duty)
	inc bc
	ld a, [bc]
	ld [de], a
	;Byte 3 = NRx2 (Volume/envelope)
	inc bc
	inc de
	ld a, [bc]
	ld [de], a
	;Byte 4 = NRx4 (Period high/control)
	inc bc
	inc de
	inc de
	ld a, [bc]
	ld [de], a
	;Byte 5 = NRx3 (Period low)
	inc bc
	dec de
	ld a, [bc]
	ld [de], a
	inc bc

SFXUpdatePtr:
;Update the pointer
	dec hl
	ld [hl], b
	dec hl
	ld [hl], c
	ret


SFXEventStop:
;Stop the macro
	;Reset the pointer
	ld a, 0
	dec hl
	ld [hl], a
	dec hl
	ld [hl], a
	;Get the current channel's play flag
	ld hl, CurSFX
	ld c, [hl]
	inc hl
	ld b, [hl]

	;Check if panning is zero
	ld a, [bc]
	and %00000010
	jp z, SFXRestorePan

	;Reset it to 3 (music)
	ld a, [bc]
	or %00000001
	ld [bc], a

SFXRestorePan:
	;Restore the original panning
	ld a, [MasterPan]
	ldh [rNR51], a
	ret


SFXEventJump:
	;Load the loop position from the following 2 bytes as the position
	inc bc
	ld a, [bc]
	ld e, a
	inc bc
	ld a, [bc]
	ld b, a
	ld c, e
	;Reset SFX channel play flag to 1
	ld a, 1
	ld [hl], a
	jr SFXUpdatePtr

Waveform:
	db $AA, $AA, $AA, $AA, $AA, $AA, $AA, $AA, $00, $00, $00, $00, $00, $00, $00, $00

SFXMacroTab:
	dw SFXMacro00
	dw SFXMacro01
	dw SFXMacro02
	dw SFXMacro03
	dw SFXMacro04
	dw SFXMacro05
	dw SFXMacro06
	dw SFXMacro07
	dw SFXMacro08
	dw SFXMacro09
	dw SFXMacro0A
	dw SFXMacro0B
	dw SFXMacro0C
	dw SFXMacro0D
	dw SFXMacro0E
	dw SFXMacro0F
	dw SFXMacro10
	dw SFXMacro11
	dw SFXMacro12
	dw SFXMacro13
	dw SFXMacro14
	dw SFXMacro15
	dw SFXMacro16
	dw SFXMacro17
	dw SFXMacro18
	dw SFXMacro19
	dw SFXMacro1A
	dw SFXMacro1B
	dw SFXMacro1C
	dw SFXMacro1D
	dw SFXMacro1E
	dw SFXMacro1F
	dw SFXMacro20
	dw SFXMacro21
	dw SFXMacro22
	dw SFXMacro23
	dw SFXMacro24
	dw SFXMacro25
	dw SFXMacro26
	dw SFXMacro27
	dw SFXMacro28
	dw SFXMacro29
	dw SFXMacro2A
	dw SFXMacro2B
	dw SFXMacro2C
	dw SFXMacro2D
	dw SFXMacro2E
	dw SFXMacro2F
	dw SFXMacro30
	dw SFXMacro31
	dw SFXMacro32
	dw SFXMacro33
	dw SFXMacro34
	dw SFXMacro35
	dw SFXMacro36
	dw SFXMacro37
	dw SFXMacro38
	dw SFXMacro39
	dw SFXMacro3A
	dw SFXMacro3B
	dw SFXMacro3C
	dw SFXMacro3D
	dw SFXMacro3E
	dw SFXMacro3F
	dw SFXMacro40
	dw SFXMacro41
	dw SFXMacro42
	dw SFXMacro43
	dw SFXMacro44
	dw SFXMacro45
	dw SFXMacro46
	dw SFXMacro47
	dw SFXMacro48
	dw SFXMacro49
	dw SFXMacro4A
	dw SFXMacro4B
	dw SFXMacro4C
	dw SFXMacro4D
	dw SFXMacro4E
	dw SFXMacro4F
	dw SFXMacro50
	dw SFXMacro51
	dw SFXMacro52
	dw SFXMacro53
	dw SFXMacro54
	dw SFXMacro55
	dw SFXMacro56
	dw SFXMacro57
	dw SFXMacro58
	dw SFXMacro59
	dw SFXMacro5A
	dw SFXMacro5B
	dw SFXMacro5C
	dw SFXMacro5D
	dw SFXMacro5E
	dw SFXMacro5F
SFXTab:
.SFXMenuSelect
	db $00, $FF, $FF, $FF
.SFXConfirm
	db $01, $FF, $FF, $FF
.PasswordAccepted
	db $02, $FF, $FF, $FF
.PasswordRejected
	db $03, $04, $FF, $FF
.ExtraHealth
	db $05, $FF, $FF, $FF
.RocketPickup
	db $06, $07, $FF, $FF
.RocketExplode
	db $08, $FF, $FF, $FF
.RocketShoot
	db $09, $FF, $FF, $FF
.RocketLowFuel
	db $0A, $FF, $FF, $FF
.Jump
	db $0B, $FF, $FF, $FF
.Land
	db $0C, $FF, $FF, $FF
.Snott
	db $0D, $FF, $FF, $FF
.Switch1
	db $0E, $FF, $FF, $FF
.Switch2
	db $0F, $FF, $FF, $FF
.DoubleJump
	db $10, $FF, $FF, $FF
.Coin1
	db $11, $FF, $FF, $FF
.Coin2
	db $12, $FF, $FF, $FF
.SelectWeapon
	db $13, $FF, $FF, $FF
.ExtraLife
	db $14, $FF, $FF, $FF
.ToiletPortal
	db $15, $16, $FF, $FF
.SnottBounce
	db $17, $18, $FF, $FF
.DoorShut
	db $19, $FF, $FF, $FF
.EnemyHit
	db $1A, $FF, $FF, $FF
.PortalLocked1
	db $1B, $1C, $FF, $FF
.PortalLocked2
	db $1D, $1E, $FF, $FF
.Alarm
	db $1F, $FF, $FF, $FF
.DoNotUse
	db $20, $FF, $FF, $FF
.BossDefeated
	db $21, $22, $23, $FF
.Cannon1
	db $24, $25, $FF, $FF
.Cannon2
	db $26, $25, $FF, $FF
.Asteroid
	db $27, $25, $FF, $FF
.DoorOpen
	db $28, $29, $FF, $FF
.Cannon3
	db $2A, $FF, $FF, $FF
.Slide
	db $2B, $2C, $FF, $FF
.Pickup1
	db $2D, $FF, $FF, $FF
.Pickup2
	db $2E, $FF, $FF, $FF
.Pickup3
	db $2F, $30, $FF, $FF
.Pickup4
	db $31, $FF, $FF, $FF
.Teleport
	db $32, $33, $FF, $FF
.EnemyDie
	db $34, $35, $36, $FF
.FallHole
	db $37, $FF, $FF, $FF
.AllCoinsCollected
	db $38, $39, $3A, $FF
.GunFire1
	db $3B, $3C, $FF, $FF
.GunFire2
	db $3D, $3E, $FF, $FF
.GunFire3
	db $3F, $40, $41, $FF
.GunFire4
	db $42, $43, $FF, $FF
.JimDown
	db $44, $45, $46, $FF
.JimHit1
	db $47, $48, $FF, $FF
.JimHit2
	db $49, $4A, $FF, $FF
.JimHit3
	db $4B, $FF, $FF, $FF
.BossHit1
	db $4C, $4D, $FF, $FF
.Rumble
	db $4E, $FF, $FF, $FF
.BossHit2
	db $4F, $50, $FF, $FF
.EvilJimRocket
	db $51, $52, $FF, $FF
.BossExplode1
	db $53, $FF, $FF, $FF
.BossExplode2
	db $54, $55, $FF, $FF
.Snap1
	db $56, $57, $FF, $FF
.Snap2
	db $58, $59, $FF, $FF
.BabyFire
	db $5A, $5B, $FF, $FF
.Empty
	db $5C, $5D, $5E, $5F
	
SFXMacro00:
	db 1
	db 1, $80, $F0, $87, $BE
	db 1, $80, $70, $87, $B6
	db 1, $80, $F0, $87, $BE
	db 1, $80, $70, $87, $B6
	db 1, $80, $F0, $87, $BE
	db 1, $80, $70, $87, $B6
	db 1, $80, $F0, $87, $BE
	db $FE
	dw SFXMacro5CLoop
SFXMacro01:
	db 1
	db 1, $80, $F0, $87, $3A
	db 1, $80, $E0, $87, $9D
	db 1, $80, $D0, $87, $3A
	db 1, $80, $C0, $87, $9D
	db 1, $80, $B0, $87, $3A
	db 1, $80, $A0, $87, $9D
	db 1, $80, $90, $87, $3A
	db 2, $80, $80, $87, $9D
	db 2, $80, $70, $87, $3A
	db 2, $80, $60, $87, $9D
	db 3, $80, $50, $87, $3A
	db 3, $80, $40, $87, $9D
	db 3, $80, $30, $87, $3A
	db 3, $80, $20, $87, $9D
	db $FE
	dw SFXMacro5CLoop
SFXMacro02:
	db 1
	db 1, $80, $20, $86, $28
	db 1, $80, $40, $86, $5B
	db 1, $80, $60, $86, $89
	db 1, $80, $80, $86, $9E
	db 1, $80, $90, $86, $C5
	db 1, $80, $A0, $86, $E7
	db 1, $80, $B0, $86, $F7
	db 1, $80, $C0, $87, $06
	db 1, $80, $D0, $87, $14
	db 2, $80, $F0, $87, $8A
	db 150, $80, $67, $87, $8A
	db $FE
	dw SFXMacro5CLoop
SFXMacro03:
	db 0
	db 2, $80, $F0, $81, $CA
	db 30, $40, $80, $81, $CA
	db $FE
	dw SFXMacro5CLoop
SFXMacro04:
	db 1
	db 2, $80, $F0, $82, $23
	db 30, $40, $80, $82, $23
	db $FE
	dw SFXMacro5CLoop
SFXMacro05:
	db 1
	db 2, $80, $40, $86, $28
	db 2, $80, $80, $87, $14
	db 2, $80, $40, $86, $5B
	db 2, $80, $80, $87, $2E
	db 2, $80, $40, $86, $89
	db 2, $80, $80, $87, $45
	db 2, $80, $40, $86, $9E
	db 2, $80, $80, $87, $4F
	db 2, $80, $40, $86, $C5
	db 2, $80, $80, $87, $63
	db 2, $80, $40, $86, $E7
	db 2, $80, $80, $87, $74
	db 2, $80, $40, $87, $06
	db 2, $80, $80, $87, $83
	db 2, $80, $40, $87, $14
	db 2, $80, $80, $87, $8A
	db 2, $80, $40, $87, $2E
	db 2, $80, $80, $87, $97
	db 2, $80, $40, $87, $45
	db 2, $80, $80, $87, $A3
	db 2, $80, $40, $87, $4F
	db 2, $80, $80, $87, $A8
	db 50, $80, $87, $87, $63
	db $FE
	dw SFXMacro5CLoop
SFXMacro06:
	db 1
SFXMacro06Loop:
	db 6, $80, $A4, $87, $97
	db 6, $80, $A4, $87, $AD
	db 6, $80, $A4, $87, $BA
	db 6, $80, $A4, $87, $74
	db 6, $80, $A4, $87, $59
	db 6, $80, $A4, $87, $2E
	db 6, $80, $A4, $86, $5B
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro07:
	db 0
	db 6, $00, $00, $00, $00
	db $FE
	dw SFXMacro06Loop
SFXMacro08:
	db 3
	db 4, $00, $B0, $80, $42
	db 1, $00, $00, $00, $00
	db 4, $00, $C0, $80, $43
	db 2, $00, $00, $00, $00
	db 3, $00, $D0, $80, $33
	db 3, $00, $00, $00, $00
	db 5, $00, $80, $80, $34
	db 1, $00, $00, $00, $00
	db 2, $00, $90, $80, $34
	db 2, $00, $00, $00, $00
	db 3, $00, $C0, $80, $34
	db 1, $00, $00, $00, $00
	db 4, $00, $90, $80, $42
	db $FE
	dw SFXMacro5CLoop
SFXMacro09:
	db 3
	db 4, $00, $F0, $80, $46
	db 20, $00, $94, $80, $46
	db 5, $00, $10, $80, $46
	db 4, $00, $20, $80, $45
	db 3, $00, $30, $80, $44
	db 5, $00, $40, $80, $43
	db 4, $00, $50, $80, $42
	db 3, $00, $60, $80, $35
	db 5, $00, $70, $80, $34
	db 4, $00, $80, $80, $33
	db 80, $00, $97, $80, $32
	db $FE
	dw SFXMacro5CLoop
SFXMacro0A:
	db 1
	db 5, $80, $E0, $85, $12
	db 4, $00, $00, $00, $00
	db 5, $80, $E0, $85, $12
	db 2, $00, $00, $00, $00
	db 5, $80, $E0, $85, $12
	db 1, $00, $00, $00, $00
	db 5, $80, $E0, $85, $12
	db $FE
	dw SFXMacro5CLoop
SFXMacro0B:
	db 1
SFXMacro0BLoop:
	db 4, $80, $F0, $83, $00
	db 1, $80, $C0, $83, $05
	db 1, $80, $B0, $83, $0A
	db 1, $80, $A0, $83, $0F
	db 1, $80, $90, $83, $14
	db 1, $80, $80, $83, $1A
	db 1, $80, $70, $83, $20
	db 1, $80, $60, $83, $28
	db 1, $80, $50, $83, $30
	db 1, $80, $50, $83, $38
	db 1, $80, $50, $83, $42
	db 1, $80, $40, $83, $4C
	db 1, $80, $40, $83, $56
	db 1, $80, $40, $83, $60
	db 1, $80, $30, $83, $6A
	db 1, $80, $30, $83, $78
	db 1, $80, $30, $83, $87
	db 1, $80, $30, $83, $A0
	db 1, $80, $30, $83, $AF
	db 1, $80, $20, $83, $BE
	db 1, $80, $20, $83, $CD
	db 1, $80, $20, $83, $DC
	db 1, $80, $20, $83, $E6
	db 1, $80, $10, $83, $F0
	db 1, $80, $10, $83, $FA
	db 1, $80, $10, $83, $FE
	db $FE
	dw SFXMacro5CLoop
SFXMacro0C:
	db 3
	db 3, $00, $F0, $80, $63
	db 30, $00, $C1, $80, $63
	db $FE
	dw SFXMacro5CLoop
SFXMacro0D:
	db 3
	db 1, $00, $20, $80, $44
	db 1, $00, $40, $80, $43
	db 1, $00, $60, $80, $42
	db 1, $00, $80, $80, $35
	db 1, $00, $A0, $80, $34
	db 2, $00, $A0, $80, $33
	db 7, $00, $00, $00, $00
	db 3, $00, $F0, $80, $63
	db $FE
	dw SFXMacro5CLoop
SFXMacro0E:
	db 1
	db 4, $80, $A0, $87, $3A
	db 70, $80, $F3, $87, $9D
	db $FE
	dw SFXMacro5CLoop
SFXMacro0F:
	db 1
	db 4, $80, $F0, $86, $9E
	db 60, $80, $B4, $87, $4F
	db $FE
	dw SFXMacro5CLoop
SFXMacro10:
	db 1
.SFXMacro10Loop
	db 4, $80, $F0, $83, $32
	db 1, $80, $C0, $83, $3C
	db 1, $80, $80, $83, $46
	db 1, $80, $60, $83, $50
	db 1, $80, $40, $83, $5A
	db $FE
	dw SFXMacro0BLoop
SFXMacro11:
	db 1
	db 2, $80, $F0, $87, $BE
	db 40, $80, $84, $87, $BE
	db $FE
	dw SFXMacro5CLoop
SFXMacro12:
	db 1
	db 2, $80, $F0, $87, $C9
	db 40, $80, $84, $87, $C9
	db $FE
	dw SFXMacro5CLoop
SFXMacro13:
	db 1
	db 2, $80, $F0, $87, $D7
	db 2, $80, $F0, $87, $DB
	db 2, $80, $F0, $87, $D7
	db 2, $80, $F0, $87, $DB
	db 2, $80, $F0, $87, $D7
	db 2, $80, $F0, $87, $EC
	db 20, $80, $A4, $87, $AD
	db $FE
	dw SFXMacro5CLoop
SFXMacro14:
	db 1
	db 4, $80, $F1, $87, $3A
	db 4, $80, $F1, $87, $7C
	db 4, $80, $F1, $87, $63
	db 4, $80, $F1, $87, $9D
	db 4, $80, $F1, $87, $7C
	db 4, $80, $F1, $87, $B1
	db 40, $80, $F3, $87, $9D
	db $FE
	dw SFXMacro5CLoop
SFXMacro15:
	db 0
	db 80, $80, $1C, $81, $6B
	db 100, $80, $F7, $81, $75
	db $FE
	dw SFXMacro5CLoop
SFXMacro16:
	db 1
	db 80, $80, $1C, $81, $6D
	db 100, $80, $F7, $81, $77
	db $FE
	dw SFXMacro5CLoop
SFXMacro17:
	db 3
	db 10, $00, $F0, $80, $66
	db $FE
	dw SFXMacro5CLoop
SFXMacro18:
	db 1
	db 10, $00, $F0, $80, $32
	db $FE
	dw SFXMacro5CLoop
SFXMacro19:
	db 3
	db 5, $00, $F4, $80, $46
	db 5, $00, $F4, $00, $44
	db 5, $00, $F4, $00, $42
	db 20, $00, $A1, $80, $44
	db $FE
	dw SFXMacro5CLoop
SFXMacro1A:
	db 3
	db 4, $00, $F0, $80, $71
	db 4, $00, $F0, $80, $62
	db 4, $00, $F0, $80, $63
	db 4, $00, $F0, $80, $64
	db 4, $00, $F0, $80, $65
	db $FE
	dw SFXMacro5CLoop
SFXMacro1B:
	db 1
	db 10, $00, $19, $81, $6B
	db 30, $00, $F2, $84, $B6
	db 30, $00, $F2, $87, $CC
	db $FE
	dw SFXMacro5CLoop
SFXMacro1C:
	db 0
	db 10, $00, $19, $81, $6C
	db 30, $00, $F2, $84, $BB
	db 30, $00, $F2, $87, $CC
	db $FE
	dw SFXMacro5CLoop
SFXMacro1D:
	db 1
	db 10, $00, $19, $87, $CC
	db 30, $00, $F2, $84, $B6
	db 30, $00, $F2, $81, $6B
	db $FE
	dw SFXMacro5CLoop
SFXMacro1E:
	db 0
	db 10, $00, $19, $87, $CC
	db 30, $00, $F2, $84, $BB
	db 30, $00, $F2, $81, $6C
	db $FE
	dw SFXMacro5CLoop
SFXMacro1F:
	db 1
.SFXMacro1FLoop
	db 1, $00, $A0, $87, $E3
	db 2, $00, $A0, $87, $E4
	db 1, $00, $A0, $87, $E5
	db 1, $00, $A0, $87, $E6
	db 2, $00, $A0, $87, $E5
	db 1, $00, $A0, $87, $E7
	db 3, $00, $00, $87, $E8
	db $FE
	dw .SFXMacro1FLoop
SFXMacro20:
	db 1
	db $FE
	dw SFXMacro5CLoop
SFXMacro21:
	db 0
	db 10, $40, $A2, $87, $14
	db 10, $40, $A2, $87, $14
	db 10, $40, $A2, $87, $14
	db 10, $40, $A2, $87, $2E
	db 10, $40, $A2, $87, $14
	db 10, $40, $A2, $87, $2E
	db 64, $40, $A7, $87, $45
	db $FE
	dw SFXMacro5CLoop
SFXMacro22:
	db 1
	db 30, $00, $A5, $86, $89
	db 30, $00, $A5, $87, $06
	db 64, $00, $A7, $86, $D7
	db $FE
	dw SFXMacro5CLoop
SFXMacro23:
	db 2
	db 30, $00, $20, $84, $4F
	db 30, $00, $20, $85, $89
	db 64, $00, $40, $85, $12
	db $FE
	dw SFXMacro5CLoop
SFXMacro24:
	db 3
	db 6, $00, $F0, $80, $62
	db 40, $00, $77, $80, $62
	db 70, $00, $10, $80, $62
	db $FE
	dw SFXMacro5CLoop
SFXMacro25:
	db 1
	db 6, $80, $F1, $84, $4F
	db $FE
	dw SFXMacro5CLoop
SFXMacro26:
	db 3
	db 6, $00, $F0, $80, $47
	db 30, $00, $84, $80, $47
	db 20, $00, $10, $80, $47
	db $FE
	dw SFXMacro5CLoop
SFXMacro27:
	db 3
	db 2, $00, $F0, $80, $61
	db 2, $00, $F0, $80, $44
	db 2, $00, $F0, $80, $47
	db 2, $00, $F0, $80, $43
	db 40, $00, $A5, $80, $45
	db 20, $00, $10, $80, $45
	db $FE
	dw SFXMacro5CLoop
SFXMacro28:
	db 3
	db 8, $00, $0B, $80, $61
	db 1, $00, $F0, $80, $44
	db 10, $00, $91, $80, $61
	db 3, $00, $00, $00, $00
	db 1, $00, $F0, $80, $44
	db 1, $00, $40, $80, $44
	db 1, $00, $20, $80, $44
	db 1, $00, $20, $80, $44
	db 1, $00, $10, $80, $44
	db $FE
	dw SFXMacro5CLoop
SFXMacro29:
	db 1
	db 9, $00, $00, $00, $00
	db 10, $00, $0A, $87, $E3
	db $FE
	dw SFXMacro5CLoop
SFXMacro2A:
	db 3
	db 4, $00, $F0, $80, $62
	db 10, $00, $A1, $80, $62
	db 10, $00, $20, $80, $62
	db 20, $00, $10, $80, $62
	db $FE
	dw SFXMacro5CLoop
SFXMacro2B:
	db 1
	db 1, $80, $40, $87, $78
	db 1, $80, $60, $87, $7C
	db 1, $80, $80, $87, $80
	db 1, $80, $A0, $87, $84
	db 2, $80, $C0, $87, $88
	db 1, $80, $F0, $87, $8C
	db 1, $80, $E0, $87, $90
	db 1, $80, $D0, $87, $94
	db 1, $80, $A0, $87, $98
	db 2, $80, $80, $87, $9C
	db 1, $80, $60, $87, $A0
	db 1, $80, $40, $87, $A4
	db 1, $80, $30, $87, $A8
	db 1, $80, $20, $87, $AC
	db $FE
	dw SFXMacro5CLoop
SFXMacro2C:
	db 3
	db 16, $00, $60, $80, $44
	db $FE
	dw SFXMacro5CLoop
SFXMacro2D:
	db 1
	db 6, $80, $A1, $87, $14
	db 6, $80, $A1, $87, $2E
	db 6, $80, $A1, $87, $45
	db 60, $80, $A4, $87, $63
	db $FE
	dw SFXMacro5CLoop
SFXMacro2E:
	db 1
	db 4, $80, $A1, $87, $2E
	db 4, $80, $A1, $87, $45
	db 5, $80, $A1, $87, $59
	db 30, $80, $A2, $87, $74
	db $FE
	dw SFXMacro5CLoop
SFXMacro2F:
	db 1
	db 10, $40, $A9, $81, $6B
	db 10, $40, $A9, $81, $CA
	db 10, $40, $A9, $81, $6B
	db 40, $40, $1A, $81, $CA
	db $FE
	dw SFXMacro5CLoop
SFXMacro30:
	db 0
	db 10, $40, $A9, $81, $6D
	db 10, $40, $A9, $81, $CC
	db 10, $40, $A9, $81, $6D
	db 40, $40, $1A, $81, $CC
	db $FE
	dw SFXMacro5CLoop
SFXMacro31:
	db 2
	db 1, $00, $20, $87, $97
	db 2, $00, $20, $87, $BA
	db 1, $00, $20, $87, $9D
	db 2, $00, $20, $87, $BE
	db 1, $00, $20, $87, $A3
	db 2, $00, $20, $87, $C2
	db 1, $00, $20, $87, $A8
	db 2, $00, $20, $87, $C5
	db 1, $00, $20, $87, $AD
	db 2, $00, $20, $87, $C9
	db 1, $00, $20, $87, $B1
	db $FE
	dw SFXMacro5CLoop
SFXMacro31B:
	db 3
	db 4, $00, $A0, $80, $69
	db 4, $00, $A0, $80, $6A
	db 4, $00, $A0, $80, $6C
	db 4, $00, $A0, $80, $6F
	db 4, $00, $A0, $80, $6C
	db 4, $00, $A0, $80, $6A
	db 4, $00, $A9, $80, $67
	db $FE
	dw SFXMacro5CLoop
SFXMacro32:
	db 0
	db 2, $80, $50, $84, $4F
	db 2, $80, $60, $84, $B6
	db 2, $80, $70, $85, $12
	db 2, $80, $90, $85, $3C
	db 2, $80, $B0, $85, $89
	db 2, $80, $D0, $85, $CE
	db 4, $80, $C0, $87, $8A
	db 4, $80, $A0, $87, $A3
	db 4, $80, $80, $87, $C5
	db 3, $80, $50, $87, $B1
	db 3, $80, $A0, $87, $D2
	db 2, $80, $70, $87, $B1
	db 2, $80, $A0, $87, $A3
	db 2, $80, $70, $87, $8A
	db 40, $80, $C4, $87, $14
	db $FE
	dw SFXMacro5CLoop
SFXMacro33:
	db 1
	db 2, $80, $50, $85, $12
	db 2, $80, $60, $85, $64
	db 2, $80, $70, $85, $89
	db 2, $80, $90, $85, $CE
	db 2, $80, $B0, $86, $0C
	db 2, $80, $D0, $86, $28
	db 6, $80, $C0, $87, $A3
	db 4, $80, $A0, $87, $C5
	db 4, $80, $80, $87, $B1
	db 3, $80, $50, $87, $D2
	db 3, $80, $A0, $87, $B1
	db 2, $80, $70, $87, $A3
	db 2, $80, $A0, $87, $8A
	db 2, $80, $70, $87, $C5
	db 40, $80, $A4, $87, $A3
	db $FE
	dw SFXMacro5CLoop
SFXMacro34:
	db 0
	db 2, $80, $40, $80, $FA
	db 2, $80, $60, $80, $E6
	db 2, $80, $80, $80, $D2
	db 2, $80, $A0, $80, $BE
	db 2, $80, $C0, $80, $AA
	db 2, $80, $F0, $80, $96
	db 3, $80, $E0, $80, $82
	db 4, $80, $D0, $80, $6E
	db 5, $80, $C0, $80, $5A
	db 6, $80, $B0, $80, $46
	db $FE
	dw SFXMacro5CLoop
SFXMacro35:
	db 1
	db 2, $80, $40, $80, $F5
	db 2, $80, $60, $80, $E1
	db 2, $80, $80, $80, $CD
	db 2, $80, $A0, $80, $B9
	db 2, $80, $C0, $80, $A5
	db 2, $80, $F0, $80, $91
	db 3, $80, $E0, $80, $7D
	db 4, $80, $D0, $80, $69
	db 5, $80, $C0, $80, $55
	db 6, $80, $B0, $80, $41
	db $FE
	dw SFXMacro5CLoop
SFXMacro36:
	db 3
	db 35, $00, $00, $00, $00
	db 30, $00, $F1, $80, $62
	db $FE
	dw SFXMacro5CLoop
SFXMacro37:
	db 1
	db 2, $80, $20, $87, $64
	db 2, $80, $40, $87, $5F
	db 2, $80, $60, $87, $5A
	db 2, $80, $80, $87, $55
	db 2, $80, $A0, $87, $50
	db 2, $80, $C0, $87, $4B
	db 2, $80, $D0, $87, $46
	db 2, $80, $F0, $87, $41
	db 2, $80, $F0, $87, $3C
	db 2, $80, $D0, $87, $37
	db 2, $80, $C0, $87, $32
	db 2, $80, $A0, $87, $2D
	db 2, $80, $70, $87, $28
	db 2, $80, $50, $87, $23
	db 2, $80, $30, $87, $1E
	db 2, $80, $20, $87, $19
	db 2, $80, $10, $87, $14
	db $FE
	dw SFXMacro5CLoop
SFXMacro38:
	db 0
	db 8, $80, $F1, $86, $C5
	db 8, $80, $F1, $86, $C5
	db 8, $80, $F1, $86, $C5
	db 8, $80, $F1, $86, $E7
	db 8, $80, $F1, $86, $E7
	db 8, $80, $F1, $86, $E7
	db 8, $80, $F1, $87, $06
	db 8, $80, $F1, $87, $06
	db 8, $80, $F1, $87, $06
	db 80, $80, $F7, $86, $D7
	db $FE
	dw SFXMacro5CLoop
SFXMacro39:
	db 1
	db 8, $80, $F1, $87, $06
	db 8, $80, $F1, $87, $06
	db 8, $80, $F1, $87, $06
	db 8, $80, $F1, $87, $21
	db 8, $80, $F1, $87, $21
	db 8, $80, $F1, $87, $21
	db 8, $80, $F1, $87, $3A
	db 8, $80, $F1, $87, $3A
	db 8, $80, $F1, $87, $3A
	db 8, $80, $F1, $87, $6C
	db 8, $80, $F1, $87, $45
	db 8, $80, $F1, $86, $D7
	db 62, $80, $F5, $87, $45
	db $FE
	dw SFXMacro5CLoop
SFXMacro3A:
	db 2
	db 24, $00, $20, $85, $89
	db 24, $00, $20, $85, $CE
	db 24, $00, $20, $86, $0C
	db 60, $00, $20, $85, $12
	db 10, $00, $40, $85, $12
	db 10, $00, $60, $85, $12
	db $FE
	dw SFXMacro5CLoop
SFXMacro3B:
	db 3
	db 2, $00, $F0, $80, $21
	db 2, $00, $F0, $80, $22
	db 2, $00, $F0, $80, $23
	db 2, $00, $A0, $80, $24
	db 2, $00, $90, $80, $32
	db 2, $00, $80, $80, $33
	db 2, $00, $70, $80, $34
	db 2, $00, $60, $80, $35
	db 2, $00, $50, $80, $42
	db 2, $00, $40, $80, $43
	db 2, $00, $30, $80, $44
	db 2, $00, $20, $80, $45
	db 4, $00, $10, $80, $60
	db $FE
	dw SFXMacro5CLoop
SFXMacro3C:
	db 1
	db 4, $80, $F0, $84, $4F
	db $FE
	dw SFXMacro5CLoop
SFXMacro3D:
	db 3
	db 1, $00, $F0, $80, $32
	db 1, $00, $F0, $80, $33
	db 1, $00, $F0, $80, $34
	db 1, $00, $F0, $80, $35
	db 1, $00, $A0, $80, $42
	db 1, $00, $90, $80, $43
	db 1, $00, $80, $80, $44
	db 1, $00, $70, $80, $45
	db 1, $00, $60, $80, $21
	db 1, $00, $50, $80, $45
	db 1, $00, $40, $80, $21
	db 1, $00, $30, $80, $45
	db 2, $00, $20, $80, $21
	db 2, $00, $10, $80, $45
	db $FE
	dw SFXMacro5CLoop
SFXMacro3E:
	db 1
	db 1, $80, $F0, $84, $4F
	db 1, $80, $30, $83, $C8
	db 1, $80, $60, $83, $BE
	db 1, $80, $F0, $83, $B4
	db 1, $80, $F0, $83, $AA
	db 2, $80, $F0, $83, $A0
	db 1, $80, $F0, $83, $96
	db 1, $80, $C0, $83, $8C
	db 1, $80, $B0, $83, $82
	db 1, $80, $A0, $83, $78
	db $FE
	dw SFXMacro5CLoop
SFXMacro3F:
	db 0
	db 38, $C0, $1C, $81, $07
	db 18, $40, $F1, $81, $07
	db $FE
	dw SFXMacro5CLoop
SFXMacro40:
	db 1
	db 38, $C0, $1C, $81, $0C
	db 18, $40, $F1, $81, $0C
	db $FE
	dw SFXMacro5CLoop
SFXMacro41:
	db 3
	db 10, $00, $F1, $80, $62
	db $FE
	dw SFXMacro5CLoop
SFXMacro42:
	db 3
	db 8, $00, $F0, $80, $63
	db 50, $00, $A5, $80, $63
	db 7, $00, $10, $80, $62
	db 6, $00, $20, $80, $61
	db 5, $00, $30, $80, $60
	db 5, $00, $40, $80, $47
	db 5, $00, $50, $80, $46
	db 4, $00, $60, $80, $45
	db 5, $00, $70, $80, $44
	db 6, $00, $80, $80, $43
	db 80, $00, $97, $80, $42
	db $FE
	dw SFXMacro5CLoop
SFXMacro43:
	db 1
	db 40, $80, $F5, $80, $9D
	db $FE
	dw SFXMacro5CLoop
SFXMacro44:
	db 1
	db 5, $80, $A1, $86, $E7
	db 5, $80, $A1, $86, $D7
	db 5, $80, $A1, $86, $C5
	db 5, $80, $A1, $86, $B2
	db 5, $80, $A1, $86, $9E
	db 5, $80, $A1, $86, $89
	db 5, $80, $A1, $86, $73
	db 5, $80, $A1, $86, $5B
	db 5, $80, $A1, $86, $42
	db 5, $80, $A1, $86, $28
	db 5, $80, $A1, $86, $0C
	db 10, $80, $A7, $85, $CE
	db 55, $80, $F7, $85, $CE
	db $FE
	dw SFXMacro5CLoop
SFXMacro45:
	db 0
	db 5, $80, $A1, $86, $F7
	db 5, $80, $A1, $86, $E7
	db 5, $80, $A1, $86, $D7
	db 5, $80, $A1, $86, $C5
	db 5, $80, $A1, $86, $B2
	db 5, $80, $A1, $86, $9E
	db 5, $80, $A1, $86, $89
	db 5, $80, $A1, $86, $73
	db 5, $80, $A1, $86, $5B
	db 5, $80, $A1, $86, $42
	db 5, $80, $A1, $86, $28
	db 10, $80, $A7, $85, $EE
	db 55, $80, $A7, $86, $89
	db $FE
	dw SFXMacro5CLoop
SFXMacro46:
	db 2
	db 30, $00, $20, $85, $CE
	db 35, $00, $20, $85, $12
	db 15, $00, $20, $83, $9C
	db 15, $00, $40, $83, $9C
	db 15, $00, $60, $83, $9C
	db $FE
	dw SFXMacro5CLoop
SFXMacro47:
	db 1
	db 2, $00, $F0, $84, $64
	db 1, $00, $10, $84, $5A
	db 2, $00, $E0, $84, $50
	db 1, $00, $10, $84, $46
	db 2, $00, $D0, $84, $3C
	db 1, $00, $10, $84, $32
	db 2, $00, $C0, $84, $28
	db 1, $00, $10, $84, $1E
	db 2, $00, $B0, $84, $14
	db $FE
	dw SFXMacro5CLoop
SFXMacro48:
	db 0
	db 2, $00, $F0, $84, $64
	db 1, $00, $10, $84, $5A
	db 2, $00, $E0, $84, $50
	db 1, $00, $10, $84, $46
	db 2, $00, $D0, $84, $3C
	db 1, $00, $10, $84, $32
	db 2, $00, $C0, $84, $28
	db 1, $00, $10, $84, $1E
	db 2, $00, $B0, $84, $14
	db $FE
	dw SFXMacro5CLoop
SFXMacro49:
	db 1
	db 1, $00, $F0, $85, $64
	db 1, $00, $10, $85, $5A
	db 1, $00, $E0, $85, $50
	db 1, $00, $10, $85, $46
	db 1, $00, $D0, $85, $3C
	db 1, $00, $10, $85, $32
	db 1, $00, $C0, $85, $28
	db 1, $00, $10, $85, $1E
	db 2, $00, $B0, $85, $14
	db $FE
	dw SFXMacro5CLoop
SFXMacro4A:
	db 0
	db 1, $00, $F0, $85, $64
	db 1, $00, $10, $85, $5A
	db 1, $00, $E0, $85, $50
	db 1, $00, $10, $85, $46
	db 1, $00, $D0, $85, $3C
	db 1, $00, $10, $85, $32
	db 1, $00, $C0, $85, $28
	db 1, $00, $10, $85, $1E
	db 2, $00, $B0, $85, $14
	db $FE
	dw SFXMacro5CLoop
SFXMacro4B:
	db 3
	db 2, $00, $F0, $80, $62
	db 1, $00, $50, $80, $45
	db 2, $00, $F0, $80, $46
	db 1, $00, $50, $80, $47
	db 2, $00, $F0, $80, $60
	db 1, $00, $50, $80, $61
	db 2, $00, $F0, $80, $62
	db 1, $00, $50, $80, $63
	db 2, $00, $F0, $80, $64
	db $FE
	dw SFXMacro5CLoop
SFXMacro4C:
	db 1
	db 4, $00, $50, $85, $64
	db 4, $40, $70, $85, $5A
	db 4, $80, $90, $85, $50
	db 2, $C0, $C0, $85, $46
	db 2, $80, $F0, $85, $3C
	db 4, $40, $C0, $85, $32
	db 6, $00, $90, $85, $28
	db 8, $40, $70, $85, $1E
	db 10, $80, $30, $85, $14
	db 12, $C0, $10, $85, $0A
	db $FE
	dw SFXMacro5CLoop
SFXMacro4D:
	db 0
	db 4, $00, $50, $85, $70
	db 4, $40, $70, $85, $66
	db 4, $80, $90, $85, $5C
	db 2, $C0, $C0, $85, $52
	db 2, $80, $F0, $85, $48
	db 4, $40, $C0, $85, $3E
	db 6, $00, $90, $85, $34
	db 8, $40, $70, $85, $2A
	db 10, $80, $30, $85, $20
	db 12, $C0, $10, $85, $16
	db $FE
	dw SFXMacro5CLoop
SFXMacro4E:
	db 3
	db 65, $00, $1D, $80, $64
	db 45, $00, $F7, $80, $64
	db 10, $00, $20, $80, $64
	db 10, $00, $10, $80, $64
	db $FE
	dw SFXMacro5CLoop
SFXMacro4F:
	db 0
	db 2, $00, $20, $87, $75
	db 2, $00, $40, $87, $75
	db 2, $00, $80, $87, $75
	db 2, $00, $F0, $87, $75
	db 2, $00, $E0, $87, $8C
	db 2, $00, $D0, $87, $8A
	db 2, $00, $C0, $87, $88
	db 2, $00, $B0, $87, $86
	db 2, $00, $A0, $87, $84
	db 2, $00, $90, $87, $82
	db 2, $00, $80, $87, $80
	db 2, $00, $70, $87, $7E
	db 2, $00, $60, $87, $7C
	db 4, $00, $50, $87, $7A
	db 4, $00, $40, $87, $80
	db 4, $00, $30, $87, $7E
	db 4, $00, $20, $87, $7C
	db 4, $00, $10, $87, $7A
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro50:
	db 1
	db 2, $00, $20, $87, $7A
	db 2, $00, $40, $87, $7A
	db 2, $00, $80, $87, $7A
	db 2, $00, $F0, $87, $7A
	db 2, $00, $00, $00, $00
	db 2, $00, $E0, $87, $8C
	db 2, $00, $D0, $87, $8A
	db 2, $00, $C0, $87, $88
	db 2, $00, $B0, $87, $86
	db 2, $00, $A0, $87, $84
	db 2, $00, $90, $87, $82
	db 2, $00, $80, $87, $80
	db 2, $00, $70, $87, $7E
	db 2, $00, $60, $87, $7C
	db 4, $00, $50, $87, $7A
	db 4, $00, $40, $87, $80
	db 4, $00, $30, $87, $7E
	db 4, $00, $20, $87, $7C
	db 4, $00, $10, $87, $7A
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro51:
	db 1
	db 2, $00, $20, $83, $0A
	db 2, $40, $40, $86, $0B
	db 2, $80, $60, $83, $0C
	db 2, $C0, $80, $86, $0D
	db 2, $80, $A0, $83, $0E
	db 2, $40, $C0, $86, $0F
	db 2, $00, $E0, $83, $10
	db 2, $40, $F0, $86, $11
	db 2, $80, $E0, $83, $12
	db 2, $C0, $C0, $86, $13
	db 2, $80, $A0, $83, $14
	db 2, $40, $80, $83, $15
	db 2, $00, $70, $86, $16
	db 2, $40, $60, $83, $17
	db 2, $80, $50, $86, $18
	db 2, $C0, $40, $83, $19
	db 2, $80, $30, $86, $1A
	db 2, $40, $20, $83, $1B
	db 2, $00, $10, $86, $1C
	db $FE
	dw SFXMacro5CLoop
SFXMacro52:
	db 0
	db 2, $00, $20, $83, $0F
	db 2, $40, $40, $86, $10
	db 2, $80, $60, $83, $11
	db 2, $C0, $80, $86, $12
	db 2, $80, $A0, $83, $13
	db 2, $40, $C0, $86, $14
	db 2, $00, $E0, $83, $15
	db 2, $40, $F0, $86, $16
	db 2, $80, $E0, $83, $17
	db 2, $C0, $C0, $86, $18
	db 2, $80, $A0, $83, $19
	db 2, $40, $80, $83, $1A
	db 2, $00, $70, $86, $1B
	db 2, $40, $60, $83, $1C
	db 2, $80, $50, $86, $1D
	db 2, $C0, $40, $83, $1E
	db 2, $80, $30, $86, $1F
	db 2, $40, $20, $83, $20
	db 2, $00, $10, $86, $21
	db $FE
	dw SFXMacro5CLoop
SFXMacro53:
	db 3
	db 10, $00, $F3, $80, $62
	db 5, $00, $F3, $80, $60
	db 20, $00, $F3, $80, $63
	db 2, $00, $F3, $80, $46
	db 15, $00, $F3, $80, $61
	db 10, $00, $F3, $80, $45
	db 5, $00, $F3, $80, $47
	db 9, $00, $F3, $80, $62
	db 18, $00, $F3, $80, $46
	db 150, $00, $F7, $80, $62
	db $FE
	dw SFXMacro5CLoop
SFXMacro54:
	db 3
	db 4, $00, $F2, $80, $47
	db 7, $00, $F2, $80, $61
	db 4, $00, $F2, $80, $64
	db 8, $00, $F2, $80, $60
	db 12, $00, $F2, $80, $65
	db 3, $00, $F2, $80, $61
	db 18, $00, $F2, $80, $64
	db 6, $00, $F2, $80, $47
	db 7, $00, $F2, $80, $61
	db 9, $00, $F2, $80, $64
	db 6, $00, $F2, $80, $47
	db 6, $00, $F2, $80, $62
	db 7, $00, $F2, $80, $61
	db 2, $00, $F2, $80, $45
	db 9, $00, $F2, $80, $60
	db 12, $00, $F2, $80, $62
	db 150, $00, $F7, $80, $63
	db $FE
	dw SFXMacro5CLoop
SFXMacro55:
	db 1
	db 4, $80, $F1, $82, $23
	db 10, $80, $F1, $82, $23
	db 4, $80, $F1, $82, $23
	db 8, $80, $F1, $82, $23
	db 12, $80, $F1, $82, $23
	db 3, $80, $F1, $82, $23
	db 18, $80, $F1, $82, $23
	db 6, $80, $F1, $82, $23
	db 12, $80, $F1, $82, $23
	db 7, $80, $F1, $82, $23
	db 6, $80, $F1, $82, $23
	db 13, $80, $F1, $82, $23
	db 7, $80, $F1, $82, $23
	db 2, $80, $F1, $82, $23
	db 9, $80, $F1, $82, $23
	db 12, $80, $F1, $82, $23
	db 5, $80, $F1, $82, $23
	db $FE
	dw SFXMacro5CLoop
SFXMacro56:
	db 3
	db 1, $00, $F0, $80, $47
	db 1, $00, $80, $80, $47
	db 1, $00, $10, $80, $47
	db 4, $00, $F0, $80, $35
	db 1, $00, $80, $80, $35
	db 1, $00, $70, $80, $35
	db 1, $00, $60, $80, $35
	db 1, $00, $50, $80, $35
	db 1, $00, $40, $80, $35
	db 1, $00, $30, $80, $35
	db 1, $00, $20, $80, $35
	db 1, $00, $10, $80, $35
	db $FE
	dw SFXMacro5CLoop
SFXMacro57:
	db 1
	db 3, $00, $00, $00, $00
	db 4, $80, $F0, $80, $9D
	db $FE
	dw SFXMacro5CLoop
SFXMacro58:
	db 3
	db 5, $00, $F0, $80, $46
	db 2, $00, $80, $80, $42
	db 2, $00, $60, $80, $46
	db 2, $00, $50, $80, $42
	db 2, $00, $40, $80, $46
	db 2, $00, $30, $80, $42
	db 2, $00, $20, $80, $46
	db 2, $00, $10, $80, $42
	db $FE
	dw SFXMacro5CLoop
SFXMacro59:
	db 1
	db 5, $80, $F0, $80, $9D
	db $FE
	dw SFXMacro5CLoop
SFXMacro5A:
	db 0
	db 1, $80, $10, $82, $78
	db 1, $80, $20, $82, $C7
	db 1, $80, $30, $83, $12
	db 1, $80, $40, $83, $59
	db 1, $80, $50, $83, $9C
	db 1, $80, $60, $83, $DB
	db 2, $80, $70, $84, $17
	db 2, $80, $80, $84, $4F
	db 2, $80, $C0, $84, $84
	db 5, $80, $F0, $84, $B6
	db 2, $80, $C0, $84, $E5
	db 2, $80, $B0, $85, $12
	db 2, $80, $A0, $85, $3C
	db 2, $80, $90, $85, $64
	db 2, $80, $80, $86, $B2
	db 2, $80, $70, $85, $89
	db 2, $80, $60, $86, $C5
	db 2, $80, $50, $85, $AD
	db 2, $80, $40, $86, $D7
	db 2, $80, $30, $85, $CE
	db 2, $80, $20, $86, $E7
	db 2, $80, $10, $85, $CE
	db $FE
	dw SFXMacro5CLoop
SFXMacro5B:
	db 1
	db 1, $80, $10, $82, $78
	db 1, $80, $20, $82, $C7
	db 1, $80, $30, $83, $12
	db 1, $80, $40, $83, $59
	db 1, $80, $50, $83, $9C
	db 1, $80, $60, $83, $DB
	db 2, $80, $70, $84, $17
	db 2, $80, $80, $84, $4F
	db 2, $80, $C0, $84, $84
	db 5, $80, $F0, $84, $B6
	db 2, $80, $C0, $84, $E5
	db 2, $80, $B0, $85, $12
	db 2, $80, $A0, $85, $3C
	db 2, $80, $90, $85, $64
	db 2, $80, $80, $86, $B2
	db 2, $80, $70, $85, $89
	db 2, $80, $60, $86, $C5
	db 2, $80, $50, $85, $AD
	db 2, $80, $40, $86, $D7
	db 2, $80, $30, $85, $CE
	db 2, $80, $20, $86, $E7
	db 2, $80, $10, $85, $CE
	db $FE
	dw SFXMacro5CLoop
SFXMacro5C:
	db 0
SFXMacro5CLoop:
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro5D:
	db 1
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro5E:
	db 2
	db 1, $00, $00, $00, $00
	db $FF
SFXMacro5F:
	db 3
	db 1, $00, $00, $00, $00
	db $FF
	
EmptyA:
	db $67, %11111111
	db $69, 255
	db $24, $00
	db $66, 1
	db $61
EmptyB:
	db $24, $00
	db $61
EmptyC:
	db $24, $00
	db $61
EmptyD:
	db $24, $00
	db $61
	
TitleA:
	db $67, %11111111
	db $69, 225
	db $24, $0C
	db $24, $0C
	db $24, $0C
	db $64, $03, -29, 1
	db $64, $05, -41, 1
	db $64, $07, -41, 1
	db $64, $09, -29, 1
	db $64, $0D, -29, 4
	db $64, $11, -17, 1
	db $64, $07, -41, 1
	db $64, $09, -29, 1
	db $64, $0D, -29, 4
	db $64, $11, -17, 1
	db $66, 1
	db $62
	dw TitleA
TitleB:
	db $24, $0C
	db $24, $0C
	db $24, $0C
	db $64, $04, -29, 1
	db $64, $06, -41, 1
	db $64, $08, -41, 1
	db $64, $0A, -29, 1
	db $64, $10, -5, 2
	db $64, $12, -17, 1
	db $64, $08, -41, 1
	db $64, $0A, -29, 1
	db $64, $10, -5, 2
	db $64, $12, -17, 1
	db $62
	dw TitleB
TitleC:
	db $64, $00, -17, 2
	db $64, $00, -12, 2
	db $64, $00, -17, 2
	db $64, $00, -17, 8
	db $64, $00, -12, 8
	db $64, $00, -17, 8
	db $64, $0B, -17, 1
	db $64, $0E, -17, 4
	db $64, $13, -5, 1
	db $64, $00, -17, 8
	db $64, $0B, -17, 1
	db $64, $0E, -17, 4
	db $64, $13, -5, 1
	db $62
	dw TitleC
TitleD:
	db $64, $01, 0, 2
	db $64, $02, 0, 1
	db $64, $01, 0, 3
	db $64, $02, 0, 1
	db $64, $01, 0, 3
	db $64, $02, 0, 1
	db $64, $01, 0, 3
	db $64, $02, 0, 1
	db $64, $0C, 0, 1
	db $64, $0F, 0, 2
	db $64, $14, 0, 1
	db $64, $01, 0, 3
	db $64, $02, 0, 1
	db $64, $0C, 0, 1
	db $64, $0F, 0, 2
	db $64, $14, 0, 1
	db $62
	dw TitleD
SongMacro00:
	db $A1, $14
	db $A1, $14
	db $A8, $14
	db $A8, $14
	db $A7, $14
	db $A7, $14
	db $A4, $14
	db $A3, $14
	db $65
SongMacro01:
	db $18, $12
	db $1E, $32
	db $1E, $32
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $1E, $32
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $18, $12
	db $18, $12
	db $18, $12
	db $1E, $32
	db $1E, $32
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $1E, $32
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $65
SongMacro02:
	db $18, $12
	db $1E, $32
	db $1E, $32
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $1E, $32
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1E, $32
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $1E, $32
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1A, $22
	db $1A, $22
	db $1A, $22
	db $1E, $32
	db $65
SongMacro03:
	db $45, $C6
	db $45, $CA
	db $24, $06
	db $43, $C4
	db $40, $C4
	db $3E, $C4
	db $3C, $C4
	db $3F, $C6
	db $40, $CB
	db $24, $06
	db $3F, $C6
	db $40, $CA
	db $24, $04
	db $3C, $C6
	db $39, $C4
	db $37, $C4
	db $35, $C4
	db $39, $C6
	db $39, $CB
	db $24, $06
	db $65
SongMacro04:
	db $3F, $F6
	db $40, $FA
	db $24, $06
	db $40, $F4
	db $3C, $F4
	db $3B, $F4
	db $39, $F4
	db $39, $F6
	db $39, $FB
	db $24, $06
	db $39, $F6
	db $39, $FA
	db $24, $04
	db $39, $F6
	db $34, $F4
	db $32, $F4
	db $32, $F4
	db $33, $F6
	db $34, $FB
	db $24, $06
	db $65
SongMacro05:
	db $4A, $C6
	db $4A, $C9
	db $24, $04
	db $48, $C2
	db $45, $C2
	db $43, $C4
	db $41, $C4
	db $3E, $C2
	db $41, $C2
	db $43, $C2
	db $44, $C2
	db $45, $C4
	db $49, $C4
	db $4A, $C6
	db $4A, $C9
	db $24, $04
	db $4A, $C2
	db $4C, $C2
	db $4D, $C4
	db $4C, $C4
	db $4A, $C4
	db $49, $C4
	db $4A, $C4
	db $45, $C4
	db $4A, $C6
	db $4A, $C9
	db $24, $02
	db $48, $C2
	db $45, $C2
	db $43, $C2
	db $41, $C2
	db $3E, $C2
	db $39, $C2
	db $3C, $C2
	db $3E, $C2
	db $41, $C2
	db $43, $C2
	db $45, $C2
	db $43, $C4
	db $41, $C4
	db $3E, $C6
	db $3E, $CA
	db $24, $07
	db $3C, $C4
	db $39, $C4
	db $3C, $C4
	db $65
SongMacro06:
	db $44, $F6
	db $45, $F9
	db $24, $0A
	db $44, $F6
	db $45, $F9
	db $24, $0A
	db $44, $F6
	db $45, $F9
	db $24, $0A
	db $38, $F6
	db $39, $FA
	db $24, $09
	db $65
SongMacro07:
	db $D1, $A5
	db $D1, $A5
	db $D1, $A2
	db $D1, $A4
	db $CF, $A2
	db $CC, $A2
	db $CA, $A2
	db $C8, $A2
	db $C5, $A2
	db $C8, $A4
	db $D1, $A2
	db $D1, $A4
	db $D1, $A2
	db $D1, $A4
	db $D1, $A2
	db $D1, $A4
	db $CF, $A2
	db $CC, $A2
	db $CA, $A2
	db $C8, $A2
	db $C5, $A2
	db $C8, $A2
	db $CA, $A2
	db $CB, $A2
	db $CA, $A2
	db $C8, $A2
	db $C5, $A2
	db $C3, $A2
	db $C0, $A2
	db $C3, $A2
	db $C4, $A2
	db $C5, $A2
	db $C8, $A2
	db $CA, $A2
	db $CB, $A2
	db $CC, $A4
	db $CF, $A2
	db $D1, $A4
	db $CF, $A2
	db $D1, $A2
	db $D4, $A2
	db $D1, $A4
	db $CF, $A2
	db $D1, $A4
	db $CF, $A2
	db $CC, $A2
	db $CA, $A2
	db $CB, $A4
	db $CC, $A4
	db $D1, $A2
	db $D1, $A4
	db $D1, $A2
	db $D1, $A4
	db $D1, $A2
	db $D1, $A4
	db $CF, $A2
	db $CC, $A2
	db $CA, $A2
	db $C8, $A4
	db $C5, $A4
	db $D1, $A2
	db $D1, $A4
	db $D1, $A2
	db $D1, $A2
	db $CF, $A2
	db $CC, $A2
	db $CA, $A2
	db $C8, $A2
	db $C5, $A2
	db $C8, $A2
	db $CA, $A2
	db $CB, $A2
	db $CA, $A2
	db $C8, $A2
	db $C5, $A2
	db $C3, $A2
	db $C0, $A2
	db $C3, $A2
	db $C4, $A2
	db $C5, $A2
	db $C8, $A2
	db $CA, $A2
	db $CB, $A2
	db $CC, $A2
	db $CF, $A4
	db $D0, $A5
	db $D1, $A4
	db $D1, $A2
	db $D1, $A4
	db $D1, $A2
	db $D1, $A4
	db $D1, $A2
	db $D1, $A8
	db $24, $02
	db $65
SongMacro08:
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F2
	db $39, $F6
	db $3C, $F6
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F2
	db $39, $F6
	db $3C, $F6
	db $34, $F6
	db $39, $F6
	db $3C, $F6
	db $34, $F6
	db $39, $F6
	db $3C, $F6
	db $34, $F6
	db $39, $F6
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F2
	db $39, $F6
	db $3C, $F6
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F6
	db $39, $F6
	db $3C, $F6
	db $34, $F6
	db $39, $F6
	db $3C, $F6
	db $34, $F6
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F4
	db $4B, $F2
	db $4C, $F8
	db $24, $02
	db $65
SongMacro09:
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $3E, $F4
	db $3F, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $3E, $F4
	db $3F, $F4
	db $40, $F5
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $3E, $F4
	db $3F, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F2
	db $40, $F4
	db $40, $F4
	db $CC, $CA
	db $65
SongMacro0A:
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $39, $C4
	db $3A, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $39, $C4
	db $3A, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $39, $C4
	db $3A, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C2
	db $3B, $C4
	db $3B, $C4
	db $C7, $CA
	db $65
SongMacro0B:
 	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A6, $14
	db $A7, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A6, $14
	db $A7, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A6, $14
	db $A7, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $12
	db $A8, $14
	db $A8, $14
	db $A8, $1A
	db $65
SongMacro0C:
	db $18, $16
	db $18, $16
	db $18, $16
	db $18, $14
	db $18, $24
	db $18, $16
	db $18, $16
	db $18, $16
	db $18, $14
	db $18, $24
	db $18, $16
	db $18, $16
	db $18, $16
	db $18, $14
	db $18, $24
	db $18, $16
	db $18, $16
	db $18, $16
	db $18, $14
	db $18, $24
	db $18, $16
	db $18, $15
	db $18, $24
	db $18, $22
	db $18, $24
	db $18, $24
	db $18, $24
	db $65
SongMacro0D:
	db $2D, $C6
	db $30, $C6
	db $32, $C4
	db $34, $C6
	db $2D, $C6
	db $30, $C6
	db $32, $C4
	db $33, $C6
	db $34, $C6
	db $65
SongMacro0E:
	db $A1, $26
	db $A4, $26
	db $A6, $24
	db $A8, $26
	db $A1, $26
	db $A4, $26
	db $A6, $24
	db $A7, $26
	db $A8, $26
	db $65
SongMacro0F:
	db $18, $14
	db $1E, $34
	db $1A, $22
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1A, $24
	db $1E, $34
	db $18, $12
	db $1E, $32
	db $18, $14
	db $1E, $34
	db $1A, $22
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1A, $24
	db $1E, $34
	db $18, $12
	db $1E, $32
	db $18, $14
	db $1E, $34
	db $1A, $22
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1A, $24
	db $1E, $34
	db $18, $12
	db $1E, $32
	db $18, $14
	db $1E, $34
	db $1A, $22
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $18, $12
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $1A, $22
	db $1E, $32
	db $1A, $22
	db $1A, $22
	db $65
SongMacro10:
	db $26, $76
	db $24, $76
	db $23, $74
	db $1F, $76
	db $26, $76
	db $24, $74
	db $23, $74
	db $21, $76
	db $1F, $72
	db $1F, $72
	db $1F, $74
	db $1F, $74
	db $26, $76
	db $24, $76
	db $23, $74
	db $1F, $76
	db $26, $76
	db $24, $74
	db $23, $74
	db $21, $76
	db $1F, $72
	db $1F, $72
	db $1F, $74
	db $1F, $74
	db $65
SongMacro11:
	db $C0, $CC
	db $65
SongMacro12:
	db $BB, $CC
	db $65
SongMacro13:
	db $B9, $DC
	db $65
SongMacro14:
	db $19, $6A
	db $1A, $26
	db $1A, $27
	db $1A, $22
	db $1A, $22
	db $1A, $24
	db $1A, $24
	db $65
	
GraveyardA:
	db $67, %11111111
	db $69, 200
	db $24, $03
	db $64, $18, -29, 1
	db $64, $18, -25, 1
	db $64, $18, -29, 1
	db $64, $18, -25, 1
	db $64, $18, -22, 1
	db $64, $18, -26, 1
	db $64, $18, -22, 1
	db $64, $18, -26, 1
	db $64, $19, -29, 1
	db $64, $1B, -29, 1
	db $64, $1C, -29, 1
	db $64, $1D, -29, 1
	db $64, $1D, -31, 1
	db $64, $1D, -33, 1
	db $64, $21, -29, 1
	db $69, 210
	db $64, $24, -29, 1
	db $69, 220
	db $64, $28, -29, 1
	db $64, $28, -28, 1
	db $64, $28, -27, 1
	db $64, $28, -26, 1
	db $69, 206
	db $64, $2B, -27, 1
	db $66, 1
	db $62
	dw GraveyardA
GraveyardB:
	db $64, $18, -29, 1
	db $64, $18, -25, 1
	db $64, $18, -29, 1
	db $64, $18, -25, 1
	db $64, $18, -22, 1
	db $64, $18, -26, 1
	db $64, $18, -22, 1
	db $64, $18, -26, 1
	db $64, $19, -29, 1
	db $24, $03
	db $64, $18, -29, 1
	db $64, $18, -25, 1
	db $64, $18, -29, 1
	db $64, $18, -25, 1
	db $64, $18, -22, 1
	db $64, $18, -26, 1
	db $64, $18, -22, 1
	db $64, $18, -26, 1
	db $64, $1E, -29, 1
	db $64, $1E, -31, 1
	db $64, $1E, -33, 1
	db $64, $22, -29, 1
	db $64, $25, -29, 2
	db $64, $29, -29, 1
	db $64, $29, -28, 1
	db $64, $29, -27, 1
	db $64, $29, -26, 1
	db $64, $2C, -27, 1
	db $62
	dw GraveyardB
GraveyardC:
	db $64, $17, -17, 1
	db $64, $17, -13, 1
	db $64, $17, -17, 1
	db $64, $17, -13, 1
	db $64, $17, -10, 1
	db $64, $17, -14, 1
	db $64, $17, -10, 1
	db $64, $17, -14, 1
	db $64, $1A, -17, 1
	db $64, $17, -17, 1
	db $64, $17, -13, 1
	db $64, $17, -17, 1
	db $64, $17, -13, 1
	db $64, $17, -10, 1
	db $64, $17, -14, 1
	db $64, $17, -10, 1
	db $64, $17, -14, 1
	db $64, $1F, -17, 1
	db $64, $23, -17, 1
	db $64, $26, -17, 2
	db $64, $2A, -17, 1
	db $64, $2D, -15, 1
	db $62
	dw GraveyardC
GraveyardD:
	db $64, $15, 0, 3
	db $64, $16, 0, 1
	db $64, $15, 0, 4
	db $64, $16, 0, 1
	db $64, $15, 0, 3
	db $64, $16, 0, 1
	db $64, $15, 0, 3
	db $64, $16, 0, 1
	db $64, $20, 0, 12
	db $64, $16, 0, 1
	db $64, $27, 0, 4
	db $64, $15, 0, 4
	db $64, $16, 0, 1
	db $62
	dw GraveyardD
SongMacro18:
	db $35, $D6
	db $38, $D6
	db $3C, $D6
	db $3D, $D6
	db $3C, $D6
	db $38, $D6
	db $35, $D6
	db $38, $D6
	db $3C, $D6
	db $3D, $D6
	db $3C, $D6
	db $38, $D6
	db $65
SongMacro17:
	db $9D, $09
	db $A9, $09
	db $9D, $09
	db $A9, $09
	db $65
SongMacro15:
	db $98, $E4
	db $98, $E4
	db $27, $56
	db $98, $E4
	db $98, $E4
	db $9A, $F4
	db $9A, $F4
	db $27, $56
	db $9A, $F4
	db $9A, $F4
	db $98, $E4
	db $98, $E4
	db $27, $56
	db $98, $E4
	db $98, $E4
	db $9A, $F4
	db $9A, $F4
	db $27, $54
	db $9A, $F4
	db $98, $E4
	db $98, $E4
	db $65
SongMacro16:
	db $98, $E4
	db $98, $E4
	db $27, $56
	db $98, $E4
	db $98, $E4
	db $9A, $F4
	db $9A, $F4
	db $27, $56
	db $9A, $F4
	db $9A, $F4
	db $98, $E4
	db $98, $E4
	db $27, $56
	db $98, $E4
	db $98, $E4
	db $9A, $F4
	db $9A, $F4
	db $27, $54
	db $9A, $F2
	db $9A, $F2
	db $9A, $F4
	db $9A, $F2
	db $9A, $F2
	db $65
SongMacro19:
	db $3C, $D6
	db $40, $D6
	db $43, $D6
	db $46, $D6
	db $44, $D6
	db $43, $D6
	db $3C, $D6
	db $40, $D6
	db $43, $D6
	db $46, $D6
	db $44, $D6
	db $43, $D4
	db $24, $00
	db $65
SongMacro1A:
	db $A4, $08
	db $A4, $04
	db $A4, $04
	db $B0, $06
	db $AB, $06
	db $A8, $06
	db $A4, $08
	db $A4, $04
	db $A4, $04
	db $B0, $06
	db $AB, $06
	db $A8, $06
	db $65
SongMacro1B:
	db $41, $E8
	db $43, $E6
	db $44, $E8
	db $48, $E6
	db $4C, $E9
	db $4D, $E8
	db $4F, $E6
	db $51, $E8
	db $4C, $E6
	db $48, $E8
	db $40, $E6
	db $44, $E9
	db $45, $E9
	db $41, $E4
	db $43, $E4
	db $44, $E6
	db $48, $E6
	db $4C, $E8
	db $4D, $E6
	db $50, $E6
	db $4F, $E6
	db $4D, $E6
	db $48, $E8
	db $44, $E6
	db $4B, $E8
	db $4C, $E6
	db $48, $E8
	db $40, $E6
	db $44, $E9
	db $45, $E9
	db $65
SongMacro1C:
	db $4F, $E4
	db $4D, $E4
	db $4B, $E6
	db $4A, $E6
	db $48, $E8
	db $43, $E6
	db $47, $E9
	db $48, $E9
	db $44, $E6
	db $47, $E6
	db $4B, $E6
	db $4C, $E8
	db $50, $E6
	db $52, $E9
	db $53, $E9
	db $54, $E4
	db $4F, $E4
	db $4B, $E6
	db $48, $E6
	db $43, $E8
	db $3F, $E6
	db $47, $E9
	db $48, $E9
	db $4B, $E8
	db $47, $E6
	db $44, $E8
	db $3F, $E6
	db $46, $E8
	db $47, $E6
	db $44, $E9
	db $65
SongMacro1D:
	db $42, $D6
	db $42, $D4
	db $3E, $D4
	db $42, $D4
	db $3E, $D4
	db $41, $D6
	db $41, $D4
	db $3D, $D4
	db $41, $D4
	db $3D, $D4
	db $42, $D6
	db $42, $D4
	db $3E, $D4
	db $42, $D4
	db $3E, $D4
	db $41, $D6
	db $41, $D4
	db $3D, $D4
	db $41, $D4
	db $3D, $D4
	db $65
SongMacro1E:
	db $3E, $D6
	db $3E, $D4
	db $3B, $D4
	db $3E, $D4
	db $3B, $D4
	db $3D, $D6
	db $3D, $D4
	db $35, $D4
	db $3D, $D4
	db $35, $D4
	db $3E, $D6
	db $3E, $D4
	db $3B, $D4
	db $3E, $D4
	db $3B, $D4
	db $3D, $D6
	db $3D, $D4
	db $35, $D4
	db $3D, $D4
	db $35, $D4
	db $65
SongMacro1F:
	db $A3, $07
	db $A5, $04
	db $A6, $04
	db $AA, $04
	db $A9, $09
	db $A3, $07
	db $A5, $04
	db $A6, $04
	db $AA, $04
	db $A9, $06
	db $A5, $06
	db $9E, $06
	db $A1, $07
	db $A3, $04
	db $A4, $04
	db $A8, $04
	db $A7, $09
	db $A1, $07
	db $A3, $04
	db $A4, $04
	db $A8, $04
	db $A7, $08
	db $9B, $06
	db $9F, $07
	db $A1, $04
	db $A2, $04
	db $A6, $04
	db $A7, $09
	db $9F, $07
	db $A1, $04
	db $A2, $04
	db $A6, $04
	db $A5, $09
	db $65
SongMacro20:
	db $1E, $42
	db $1E, $42
	db $2E, $42
	db $1E, $42
	db $1E, $42
	db $1E, $42
	db $2E, $42
	db $1E, $42
	db $1E, $42
	db $1E, $42
	db $2E, $42
	db $1E, $42
	db $65
SongMacro21:
	db $32, $D6
	db $36, $D6
	db $39, $D6
	db $3A, $D6
	db $39, $D6
	db $36, $D6
	db $32, $D6
	db $36, $D6
	db $39, $D6
	db $37, $D9
	db $65
SongMacro22:
	db $51, $D2
	db $50, $D2
	db $4F, $D2
	db $4E, $D2
	db $4D, $D2
	db $4C, $D2
	db $4B, $D2
	db $4A, $D2
	db $49, $D2
	db $48, $D2
	db $47, $D2
	db $46, $D2
	db $45, $D2
	db $44, $D2
	db $43, $D2
	db $42, $D2
	db $41, $D2
	db $40, $D2
	db $3F, $D2
	db $3E, $D2
	db $3D, $D2
	db $3C, $D2
	db $3B, $D2
	db $3A, $D2
	db $39, $D2
	db $38, $D2
	db $37, $D2
	db $36, $D2
	db $35, $D2
	db $34, $D2
	db $33, $D2
	db $32, $D6
	db $00, $02
	db $37, $D9
	db $65
SongMacro23:
	db $A6, $06
	db $A4, $06
	db $A2, $06
	db $A1, $06
	db $A4, $06
	db $A2, $06
	db $A1, $06
	db $9E, $08
	db $9F, $09
	db $65
SongMacro24:
	db $43, $E4
	db $45, $E4
	db $46, $E6
	db $49, $E6
	db $4A, $E9
	db $46, $E4
	db $45, $E4
	db $43, $E6
	db $3D, $E6
	db $3E, $E9
	db $42, $E4
	db $41, $E4
	db $3F, $E4
	db $42, $E4
	db $41, $E4
	db $3F, $E4
	db $42, $E4
	db $41, $E4
	db $3F, $E6
	db $45, $E6
	db $46, $E8
	db $3E, $E6
	db $43, $E9
	db $43, $E4
	db $45, $E4
	db $46, $E6
	db $49, $E6
	db $4A, $E9
	db $46, $E4
	db $45, $E4
	db $43, $E6
	db $3D, $E6
	db $3E, $E9
	db $3F, $E4
	db $41, $E4
	db $42, $E6
	db $46, $E6
	db $4B, $E9
	db $4A, $E8
	db $3E, $E6
	db $43, $E9
	db $65
SongMacro25:
	db $37, $D4
	db $32, $D4
	db $2E, $D6
	db $2E, $D6
	db $37, $D4
	db $32, $D4
	db $2E, $D6
	db $2E, $D6
	db $37, $D4
	db $32, $D4
	db $2E, $D6
	db $2E, $D6
	db $37, $D4
	db $32, $D4
	db $2E, $D6
	db $2E, $D6
	db $36, $D4
	db $33, $D4
	db $2E, $D6
	db $2E, $D6
	db $36, $D4
	db $33, $D4
	db $2E, $D6
	db $2E, $D6
	db $37, $D4
	db $32, $D4
	db $2E, $D6
	db $2E, $D6
	db $37, $D4
	db $32, $D4
	db $2E, $D6
	db $2E, $D6
	db $65
SongMacro26:
	db $9F, $06
	db $AB, $06
	db $AB, $06
	db $9A, $06
	db $AB, $06
	db $AB, $06
	db $9F, $06
	db $AB, $06
	db $AB, $06
	db $9A, $06
	db $AB, $06
	db $AB, $06
	db $9B, $06
	db $AA, $06
	db $AA, $06
	db $A2, $06
	db $AA, $06
	db $AA, $06
	db $9F, $06
	db $AB, $06
	db $AB, $06
	db $9A, $06
	db $AB, $06
	db $AB, $06
	db $65
SongMacro27:
	db $98, $E6
	db $1E, $44
	db $1E, $44
	db $1E, $46
	db $9A, $F6
	db $1E, $44
	db $1E, $44
	db $1E, $46
	db $98, $E6
	db $1E, $44
	db $1E, $44
	db $1E, $46
	db $9A, $F6
	db $1E, $44
	db $1E, $44
	db $1E, $46
	db $65
SongMacro28:
	db $43, $E8
	db $3D, $E6
	db $43, $E4
	db $43, $E4
	db $43, $E6
	db $3D, $E6
	db $43, $E4
	db $43, $E4
	db $43, $E4
	db $43, $E4
	db $43, $E4
	db $3D, $E4
	db $43, $E9
	db $65
SongMacro29:
	db $3D, $E8
	db $37, $E6
	db $3D, $E4
	db $3D, $E4
	db $3D, $E6
	db $37, $E6
	db $3D, $E4
	db $3D, $E4
	db $3D, $E4
	db $3D, $E4
	db $3D, $E4
	db $37, $E4
	db $3D, $E9
	db $65
SongMacro2A:
	db $9F, $08
	db $AB, $06
	db $A5, $08
	db $A6, $06
	db $9F, $06
	db $A1, $06
	db $A2, $06
	db $A5, $09
	db $A0, $08
	db $A2, $06
	db $A3, $08
	db $A5, $06
	db $A6, $08
	db $AA, $06
	db $AC, $09
	db $A1, $08
	db $A3, $06
	db $A4, $08
	db $A6, $06
	db $A8, $09
	db $A7, $09
	db $A2, $08
	db $A4, $06
	db $A5, $08
	db $A9, $06
	db $AA, $09
	db $A9, $09
	db $65
SongMacro2B:
	db $46, $D8
	db $44, $D6
	db $42, $D8
	db $41, $D6
	db $3F, $D8
	db $3E, $D4
	db $3C, $D4
	db $3A, $D9
	db $65
SongMacro2C:
	db $2E, $D6
	db $32, $D6
	db $35, $D6
	db $36, $D6
	db $35, $D6
	db $32, $D6
	db $2E, $D6
	db $32, $D6
	db $35, $D6
	db $36, $D6
	db $35, $D6
	db $32, $D6
	db $65
SongMacro2D:
	db $A2, $08
	db $A2, $04
	db $A2, $04
	db $AE, $08
	db $A9, $06
	db $A2, $08
	db $A2, $04
	db $A2, $04
	db $AE, $06
	db $A9, $06
	db $A6, $06
	db $65

SweetshopA:
	db $67, %11111111
	db $69, 216
	db $24, $0B
	db $24, $0B
	db $64, $2E, -31, 1
	db $64, $2F, -31, 1
	db $64, $32, -31, 1
	db $64, $37, -31, 1
	db $64, $37, -28, 1
	db $64, $37, -26, 1
	db $64, $37, -23, 1
	db $64, $3A, -31, 1
	db $64, $3A, -29, 1
	db $64, $3A, -27, 1
	db $64, $3A, -25, 1
	db $69, $AB
	db $64, $40, -31, 1
	db $64, $41, -31, 1
	db $64, $40, -31, 1
	db $64, $41, -31, 1
	db $64, $40, -32, 1
	db $64, $41, -32, 1
	db $64, $40, -25, 1
	db $64, $41, -34, 1
	db $64, $42, -31, 1
	db $69, $D8
	db $64, $49, -31, 2
	db $64, $4C, -31, 1
	db $64, $4D, -31, 1
	db $66, 1
	db $62
	dw SweetshopA
SweetshopB:
	db $64, $30, -31, 5
	db $64, $30, -29, 4
	db $64, $33, -31, 3
	db $64, $34, -31, 1
	db $64, $38, -31, 1
	db $64, $38, -28, 1
	db $64, $38, -26, 1
	db $64, $38, -23, 1
	db $64, $3B, -31, 1
	db $64, $3C, -41, 1
	db $64, $3C, -39, 1
	db $64, $3D, -37, 1
	db $64, $43, -31, 1
	db $64, $43, -35, 1
	db $64, $43, -31, 1
	db $64, $43, -35, 1
	db $64, $43, -32, 1
	db $64, $43, -29, 1
	db $64, $43, -37, 1
	db $64, $43, -34, 1
	db $64, $44, -31, 1
	db $64, $4A, -31, 4
	db $64, $4E, -31, 2
	db $64, $4F, -31, 1
	db $62
	dw SweetshopB
SweetshopC:
	db $64, $31, -19, 5
	db $64, $31, -17, 4
	db $64, $35, -19, 3
	db $64, $36, -19, 1
	db $64, $39, -19, 1
	db $64, $39, -16, 1
	db $64, $39, -14, 1
	db $64, $39, -11, 1
	db $64, $3E, -19, 1
	db $64, $3F, -29, 1
	db $64, $3F, -27, 1
	db $64, $3F, -25, 1
	db $64, $45, -19, 2
	db $64, $46, -19, 1
	db $64, $47, -19, 1
	db $64, $48, -19, 1
	db $64, $4B, -19, 4
	db $64, $50, -19, 2
	db $64, $51, -19, 1
	db $62
	dw SweetshopC
SweetshopD:
	db $61
	db $62
	dw SweetshopD
SongMacro2E:
	db $4C, $B7
	db $4A, $B4
	db $4C, $B6
	db $4D, $B7
	db $4F, $B4
	db $4D, $B6
	db $4C, $B7
	db $4A, $B4
	db $48, $B6
	db $4A, $B6
	db $47, $B6
	db $43, $B6
	db $48, $B4
	db $4A, $B4
	db $4C, $B6
	db $4F, $B6
	db $51, $B7
	db $4F, $B4
	db $4D, $B6
	db $4C, $B9
	db $4A, $B9
	db $4F, $B4
	db $4D, $B4
	db $4C, $B6
	db $4F, $B6
	db $4D, $B7
	db $4A, $B4
	db $47, $B6
	db $48, $B7
	db $4A, $B4
	db $4C, $B6
	db $43, $B8
	db $43, $B6
	db $48, $B4
	db $4A, $B4
	db $4C, $B6
	db $4F, $B6
	db $51, $B7
	db $4F, $B4
	db $4D, $B6
	db $4C, $B6
	db $4F, $B6
	db $48, $B6
	db $4A, $B9
	db $65
SongMacro2F:
	db $4E, $B4
	db $4C, $B4
	db $4A, $B6
	db $51, $B6
	db $4F, $B4
	db $4E, $B4
	db $4C, $B6
	db $4F, $B6
	db $4E, $B4
	db $4C, $B4
	db $4A, $B6
	db $47, $B6
	db $45, $B9
	db $3E, $B4
	db $40, $B4
	db $42, $B6
	db $45, $B6
	db $47, $B7
	db $45, $B4
	db $43, $B6
	db $42, $B6
	db $45, $B6
	db $4A, $B6
	db $4C, $B9
	db $4E, $B4
	db $4F, $B4
	db $51, $B4
	db $4E, $B4
	db $4F, $B4
	db $51, $B4
	db $4F, $B4
	db $4E, $B4
	db $4C, $B6
	db $4F, $B6
	db $4E, $B4
	db $4C, $B4
	db $4A, $B6
	db $47, $B6
	db $45, $B4
	db $43, $B4
	db $42, $B6
	db $40, $B6
	db $42, $B4
	db $40, $B4
	db $3E, $B6
	db $45, $B6
	db $47, $B4
	db $45, $B4
	db $43, $B6
	db $4A, $B6
	db $4E, $B7
	db $4C, $B4
	db $4A, $B6
	db $51, $B9
	db $65
SongMacro30:
	db $34, $A4
	db $3C, $A4
	db $34, $A4
	db $3C, $A4
	db $34, $A4
	db $3C, $A4
	db $39, $A4
	db $41, $A4
	db $39, $A4
	db $41, $A4
	db $39, $A4
	db $41, $A4
	db $34, $A4
	db $3C, $A4
	db $34, $A4
	db $3C, $A4
	db $34, $A4
	db $3C, $A4
	db $3B, $A4
	db $43, $A4
	db $3B, $A4
	db $43, $A4
	db $3B, $A4
	db $43, $A4
	db $65
SongMacro31:
	db $A4, $96
	db $B0, $96
	db $B0, $96
	db $A9, $96
	db $B5, $96
	db $B5, $96
	db $A4, $96
	db $B0, $96
	db $B0, $96
	db $AB, $96
	db $B7, $96
	db $B7, $96
	db $65
SongMacro32:
	db $4C, $B4
	db $4B, $B4
	db $4A, $B4
	db $49, $B4
	db $48, $B4
	db $47, $B4
	db $46, $B4
	db $45, $B4
	db $44, $B4
	db $43, $B4
	db $42, $B4
	db $41, $B4
	db $40, $B6
	db $45, $B6
	db $48, $B6
	db $4C, $B4
	db $4D, $B4
	db $4C, $B4
	db $4A, $B4
	db $4C, $B6
	db $4C, $B4
	db $4B, $B4
	db $4A, $B4
	db $49, $B4
	db $48, $B4
	db $47, $B4
	db $46, $B4
	db $45, $B4
	db $44, $B4
	db $43, $B4
	db $42, $B4
	db $41, $B4
	db $40, $B6
	db $45, $B6
	db $48, $B6
	db $4C, $B6
	db $51, $B4
	db $53, $B4
	db $54, $B6
	db $4C, $B7
	db $4D, $B4
	db $4C, $B4
	db $4A, $B4
	db $48, $B4
	db $4A, $B4
	db $4C, $B6
	db $48, $B6
	db $4A, $B4
	db $4C, $B4
	db $4A, $B4
	db $48, $B4
	db $47, $B4
	db $4A, $B4
	db $48, $B6
	db $45, $B8
	db $44, $B4
	db $45, $B4
	db $47, $B6
	db $4A, $B6
	db $4D, $B6
	db $4C, $B6
	db $4A, $B6
	db $48, $B4
	db $47, $B4
	db $45, $B8
	db $43, $B9
	db $65
SongMacro33:
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $3C, $A4
	db $45, $A4
	db $3C, $A4
	db $45, $A4
	db $3C, $A4
	db $45, $A4
	db $3C, $A4
	db $45, $A4
	db $3C, $A4
	db $45, $A4
	db $3C, $A4
	db $45, $A4
	db $65
SongMacro34:
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $3C, $A4
	db $45, $A4
	db $3C, $A4
	db $45, $A4
	db $3C, $A4
	db $45, $A4
	db $3B, $A4
	db $43, $A4
	db $3B, $A4
	db $43, $A4
	db $3B, $A4
	db $43, $A4
	db $65
SongMacro35:
	db $A8, $96
	db $B4, $96
	db $B4, $96
	db $A8, $96
	db $B4, $96
	db $B4, $96
	db $AD, $96
	db $B9, $96
	db $B9, $96
	db $AD, $96
	db $B9, $96
	db $B9, $96
	db $65
SongMacro36:
	db $A8, $96
	db $B4, $96
	db $B4, $96
	db $A8, $96
	db $B4, $96
	db $B4, $96
	db $AD, $96
	db $B9, $96
	db $B9, $96
	db $AB, $96
	db $B7, $96
	db $B7, $96
	db $65
SongMacro37:
	db $3C, $B4
	db $3F, $B4
	db $43, $B6
	db $44, $B6
	db $43, $B6
	db $3F, $B6
	db $3B, $B6
	db $3C, $B4
	db $3F, $B4
	db $43, $B6
	db $44, $B6
	db $43, $B9
	db $65
SongMacro38:
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $33, $A4
	db $3C, $A4
	db $65
SongMacro39:
	db $A4, $96
	db $B0, $96
	db $B0, $96
	db $A4, $96
	db $B0, $96
	db $B0, $96
	db $A4, $96
	db $B0, $96
	db $B0, $96
	db $A4, $96
	db $B0, $96
	db $B0, $96
	db $65
SongMacro3A:
	db $4B, $BA
	db $47, $B6
	db $4B, $B6
	db $4C, $BB
	db $65
SongMacro3B:
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $38, $A4
	db $40, $A4
	db $65
SongMacro3C:
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $43, $A4
	db $4C, $A4
	db $43, $A4
	db $4C, $A4
	db $43, $A4
	db $4C, $A4
	db $43, $A4
	db $4C, $A4
	db $43, $A4
	db $4C, $A4
	db $43, $A4
	db $4C, $A4
	db $65
SongMacro3D:
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $3F, $A4
	db $47, $A4
	db $44, $A4
	db $4C, $A4
	db $44, $A4
	db $4C, $A4
	db $44, $A4
	db $4C, $A4
	db $44, $A4
	db $4C, $A4
	db $44, $A4
	db $4C, $A4
	db $44, $A4
	db $4C, $A4
	db $65
SongMacro3E:
	db $AF, $96
	db $BB, $96
	db $BB, $96
	db $AF, $96
	db $BB, $96
	db $BB, $96
	db $A8, $96
	db $B4, $96
	db $B4, $96
	db $A8, $96
	db $B4, $96
	db $B4, $96
	db $65
SongMacro3F:
	db $AF, $96
	db $BB, $96
	db $BB, $96
	db $AF, $96
	db $BB, $96
	db $BB, $96
	db $B4, $96
	db $C0, $96
	db $C0, $96
	db $B4, $96
	db $C0, $96
	db $C0, $96
	db $65
SongMacro40:
	db $4B, $AD
	db $4A, $AD
	db $49, $AD
	db $48, $AD
	db $47, $AD
	db $46, $AD
	db $45, $AD
	db $44, $AD
	db $43, $AD
	db $42, $AD
	db $41, $AD
	db $40, $AD
	db $3F, $AD
	db $3E, $AD
	db $3D, $AD
	db $3C, $AD
	db $3B, $AD
	db $3A, $AD
	db $39, $AD
	db $38, $AD
	db $37, $AD
	db $36, $AD
	db $35, $AD
	db $33, $AD
	db $65
SongMacro41:
	db $36, $AD
	db $37, $AD
	db $38, $AD
	db $39, $AD
	db $3A, $AD
	db $3B, $AD
	db $3C, $AD
	db $3D, $AD
	db $3E, $AD
	db $3F, $AD
	db $40, $AD
	db $41, $AD
	db $42, $AD
	db $43, $AD
	db $44, $AD
	db $45, $AD
	db $46, $AD
	db $47, $AD
	db $48, $AD
	db $49, $AD
	db $4A, $AD
	db $4B, $AD
	db $4C, $AD
	db $4D, $AD
	db $65
SongMacro42:
	db $39, $AD
	db $3A, $AD
	db $3B, $AD
	db $3C, $AD
	db $3D, $AD
	db $3E, $AD
	db $3F, $AD
	db $40, $AD
	db $41, $AD
	db $42, $AD
	db $43, $AD
	db $44, $AD
	db $45, $A9
	db $65
SongMacro43:
	db $BF, $BD
	db $C2, $BD
	db $C6, $BD
	db $C7, $BD
	db $C6, $BD
	db $C2, $BD
	db $BF, $BD
	db $C2, $BD
	db $C6, $BD
	db $C7, $BD
	db $C6, $BD
	db $C2, $BD
	db $BF, $BD
	db $C2, $BD
	db $C6, $BD
	db $C7, $BD
	db $C6, $BD
	db $C2, $BD
	db $BF, $BD
	db $C2, $BD
	db $C6, $BD
	db $C7, $BD
	db $C6, $BD
	db $C2, $BD
	db $65
SongMacro44:
	db $C0, $B4
	db $B9, $B4
	db $BC, $B4
	db $C0, $B4
	db $C5, $B4
	db $C0, $B4
	db $BC, $B4
	db $C0, $B4
	db $B9, $B9
	db $65
SongMacro45:
	db $A7, $09
	db $A7, $04
	db $A9, $04
	db $AA, $06
	db $AC, $06
	db $AD, $06
	db $AE, $06
	db $AF, $08
	db $AA, $08
	db $A3, $08
	db $AA, $08
	db $65
SongMacro46:
	db $A6, $07
	db $A8, $02
	db $A9, $02
	db $AD, $07
	db $AE, $04
	db $AD, $07
	db $AB, $04
	db $A9, $06
	db $A6, $06
	db $A9, $06
	db $AC, $06
	db $B0, $06
	db $A4, $06
	db $A9, $07
	db $AB, $04
	db $AC, $06
	db $A4, $06
	db $65
SongMacro47:
	db $A1, $07
	db $A3, $04
	db $A4, $06
	db $A7, $06
	db $A8, $08
	db $AD, $06
	db $A8, $06
	db $AB, $04
	db $A9, $04
	db $A7, $06
	db $A4, $06
	db $9F, $06
	db $A4, $07
	db $A6, $04
	db $A7, $06
	db $A4, $06
	db $65
SongMacro48:
	db $A1, $98
	db $A8, $98
	db $A1, $96
	db $A8, $96
	db $A8, $96
	db $65
SongMacro49:
	db $45, $B8
	db $48, $B6
	db $4C, $B8
	db $4D, $B6
	db $4A, $B8
	db $47, $B6
	db $4C, $B9
	db $45, $B8
	db $48, $B6
	db $4C, $B8
	db $4D, $B6
	db $4A, $B8
	db $4F, $B6
	db $4C, $B9
	db $65
SongMacro4A:	
	db $40, $A4
	db $39, $A4
	db $3C, $A4
	db $40, $A4
	db $3F, $A4
	db $39, $A4
	db $40, $A4
	db $39, $A4
	db $3C, $A4
	db $39, $A4
	db $41, $A4
	db $39, $A4
	db $3E, $A4
	db $37, $A4
	db $3B, $A4
	db $3E, $A4
	db $40, $A4
	db $38, $A4
	db $3C, $A4
	db $34, $A4
	db $39, $A4
	db $3C, $A4
	db $34, $A4
	db $39, $A4
	db $65
SongMacro4B:
	db $A1, $96
	db $AD, $96
	db $AD, $96
	db $A1, $96
	db $AD, $96
	db $9D, $96
	db $9F, $96
	db $AB, $96
	db $9C, $96
	db $A1, $96
	db $AD, $96
	db $AD, $96
	db $65
SongMacro4C:
	db $39, $B8
	db $45, $B6
	db $41, $B9
	db $45, $B8
	db $4C, $B6
	db $4D, $B9
	db $65
SongMacro4D:
	db $45, $B7
	db $47, $B4
	db $48, $B6
	db $4A, $B6
	db $47, $B6
	db $43, $B6
	db $4F, $B6
	db $4D, $B6
	db $4A, $B6
	db $47, $B6
	db $45, $B6
	db $43, $B6
	db $65
SongMacro4E:
 	db $40, $A4
	db $39, $A4
	db $3C, $A4
	db $40, $A4
	db $39, $A4
	db $3C, $A4
	db $3F, $A4
	db $39, $A4
	db $3C, $A4
	db $3F, $A4
	db $39, $A4
	db $3C, $A4
	db $65
SongMacro4F:
	db $40, $A4
	db $39, $A4
	db $3C, $A4
	db $40, $A4
	db $39, $A4
	db $3C, $A4
	db $3E, $A4
	db $37, $A4
	db $3B, $A4
	db $3E, $A4
	db $37, $A4
	db $3E, $A4
	db $37, $A4
	db $39, $A4
	db $3B, $A4
	db $3C, $A4
	db $3E, $A4
	db $40, $A4
	db $41, $A6
	db $3E, $A6
	db $3B, $A6
	db $65
SongMacro50:
	db $A1, $96
	db $AD, $96
	db $AD, $96
	db $9D, $96
	db $A9, $96
	db $A9, $96
	db $65
SongMacro51:
	db $A1, $96
	db $AD, $96
	db $AD, $96
	db $9F, $96
	db $AB, $96
	db $AB, $96
	db $9F, $96
	db $AB, $96
	db $AB, $96
	db $9F, $96
	db $AB, $96
	db $AB, $96
	db $65
	
SubwayA:
	db $67, %11111111
	db $69, 180
	db $64, $52, -31, 1
	db $64, $56, -31, 2
	db $64, $58, -31, 2
	db $64, $5C, -31, 1
	db $64, $5E, -19, 1
	db $64, $61, -31, 1
	db $64, $61, -26, 1
	db $64, $62, -26, 1
	db $64, $64, -31, 1
	db $64, $67, -31, 1
	db $64, $69, -31, 1
	db $64, $67, -31, 1
	db $64, $6B, -31, 1
	db $64, $61, -31, 1
	db $64, $61, -26, 1
	db $64, $62, -26, 1
	db $64, $64, -31, 1
	db $64, $6D, -31, 2
	db $66, 1
	db $62
	dw SubwayA
SubwayB:
	db $64, $53, -31, 1
	db $64, $57, -31, 2
	db $64, $59, -31, 2
	db $64, $5D, -31, 1
	db $64, $5F, -19, 1
	db $64, $63, -31, 1
	db $64, $63, -26, 1
	db $64, $63, -33, 1
	db $64, $65, -31, 1
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $24, $0A
	db $64, $6A, -31, 1
	db $64, $67, -43, 1
	db $64, $6C, -31, 1
	db $64, $63, -31, 1
	db $64, $63, -26, 1
	db $64, $63, -33, 1
	db $64, $65, -31, 1
	db $64, $6E, -31, 2
	db $62
	dw SubwayB
SubwayC:
	db $64, $54, -19, 3
	db $64, $5A, -19, 6
	db $64, $60, -19, 1
	db $64, $60, -17, 1
	db $64, $60, -24, 1
	db $64, $60, -19, 1
	db $64, $60, -26, 1
	db $64, $66, -19, 1
	db $64, $68, -19, 2
	db $64, $68, -26, 2
	db $64, $68, -19, 2
	db $64, $68, -24, 1
	db $64, $68, -26, 1
	db $64, $68, -19, 1
	db $64, $60, -24, 1
	db $64, $60, -19, 1
	db $64, $60, -26, 1
	db $64, $66, -19, 1
	db $64, $6F, -19, 2
	db $62
	dw SubwayC
SubwayD:
	db $64, $55, 0, 6
	db $64, $5B, 0, 31
	db $64, $55, 0, 1
	db $62
	dw SubwayD
SongMacro52:
	db $43, $D5
	db $43, $D5
	db $43, $D6
	db $43, $D4
	db $43, $D4
	db $43, $D4
	db $42, $D5
	db $42, $D5
	db $42, $D6
	db $42, $D4
	db $42, $D4
	db $42, $D4
	db $41, $D5
	db $41, $D5
	db $41, $D6
	db $41, $D4
	db $41, $D4
	db $41, $D4
	db $40, $D5
	db $40, $D5
	db $40, $D6
	db $40, $D4
	db $40, $D6
	db $65
SongMacro53:
	db $3D, $D5
	db $3D, $D5
	db $3D, $D6
	db $3D, $D4
	db $3D, $D4
	db $3D, $D4
	db $3C, $D5
	db $3C, $D5
	db $3C, $D6
	db $3C, $D4
	db $3C, $D4
	db $3C, $D4
	db $3B, $D5
	db $3B, $D5
	db $3B, $D6
	db $3B, $D4
	db $3B, $D4
	db $3B, $D4
	db $3C, $D5
	db $3B, $D5
	db $3C, $D6
	db $3C, $D4
	db $3C, $D6
	db $65
SongMacro54:
	db $A1, $95
	db $A1, $95
	db $A1, $96
	db $A1, $94
	db $A1, $94
	db $A1, $94
	db $A6, $95
	db $A6, $95
	db $A6, $96
	db $A6, $94
	db $A6, $94
	db $A6, $94
	db $9F, $95
	db $9F, $95
	db $9F, $96
	db $9F, $94
	db $A1, $94
	db $A3, $94
	db $A4, $95
	db $A4, $95
	db $A4, $96
	db $A4, $94
	db $A4, $94
	db $A3, $94
	db $65
SongMacro55:
	db $1E, $46
	db $1E, $46
	db $1E, $46
	db $1E, $46
	db $1E, $46
	db $1E, $46
	db $1E, $46
	db $1E, $44
	db $2E, $54
	db $65
SongMacro56:
	db $43, $D5
	db $43, $D5
	db $43, $D6
	db $43, $D4
	db $45, $D4
	db $43, $D4
	db $42, $D5
	db $42, $D5
	db $42, $D6
	db $42, $D4
	db $43, $D4
	db $42, $D1
	db $43, $D1
	db $42, $D1
	db $41, $D5
	db $41, $D5
	db $41, $D6
	db $41, $D4
	db $43, $D4
	db $41, $D1
	db $43, $D1
	db $41, $D1
	db $40, $D5
	db $40, $D5
	db $40, $D5
	db $40, $D5
	db $40, $D4
	db $40, $D4
	db $65
SongMacro57:
	db $3D, $D5
	db $3D, $D5
	db $3D, $D6
	db $3D, $D4
	db $3D, $D4
	db $3D, $D4
	db $3C, $D5
	db $3C, $D5
	db $3C, $D6
	db $3C, $D4
	db $3C, $D4
	db $3C, $D4
	db $3B, $D5
	db $3B, $D5
	db $3B, $D6
	db $3B, $D4
	db $3B, $D6
	db $3C, $D5
	db $3C, $D5
	db $3C, $D5
	db $3C, $D5
	db $3C, $D4
	db $3C, $D4
	db $65
SongMacro58:
	db $43, $D4
	db $43, $D4
	db $43, $D4
	db $45, $D2
	db $43, $D4
	db $41, $D4
	db $40, $D4
	db $41, $D2
	db $43, $D2
	db $40, $D2
	db $41, $D4
	db $41, $D4
	db $41, $D2
	db $43, $D2
	db $41, $D2
	db $40, $D2
	db $3A, $D2
	db $3A, $D4
	db $3A, $D4
	db $3A, $D5
	db $35, $D4
	db $35, $D4
	db $39, $D2
	db $39, $D4
	db $3C, $D4
	db $3C, $D4
	db $3C, $D2
	db $3F, $D2
	db $3F, $D2
	db $3F, $D2
	db $3F, $D2
	db $40, $D4
	db $40, $D2
	db $41, $D2
	db $43, $D2
	db $45, $D4
	db $46, $D4
	db $45, $D4
	db $43, $D5
	db $41, $D4
	db $43, $D4
	db $43, $D4
	db $43, $D2
	db $45, $D2
	db $43, $D2
	db $41, $D2
	db $40, $D2
	db $41, $D4
	db $43, $D4
	db $40, $D2
	db $41, $D2
	db $43, $D2
	db $41, $D4
	db $41, $D4
	db $3E, $D2
	db $3E, $D4
	db $3A, $D4
	db $3A, $D4
	db $3A, $D4
	db $3A, $D2
	db $3A, $D2
	db $3A, $D2
	db $35, $D2
	db $35, $D2
	db $35, $D2
	db $35, $D2
	db $39, $D2
	db $39, $D2
	db $39, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $3E, $D2
	db $3F, $D2
	db $3C, $D2
	db $3E, $D2
	db $3F, $D4
	db $40, $D2
	db $41, $D2
	db $43, $D2
	db $45, $D2
	db $46, $D2
	db $45, $D2
	db $43, $D2
	db $42, $D2
	db $43, $D2
	db $40, $D4
	db $40, $D6
	db $24, $02
	db $65
SongMacro59:
	db $40, $D4
	db $40, $D4
	db $40, $D4
	db $41, $D2
	db $40, $D4
	db $3E, $D4
	db $3C, $D4
	db $3E, $D2
	db $40, $D2
	db $3C, $D2
	db $3E, $D4
	db $3E, $D4
	db $3E, $D2
	db $40, $D2
	db $3E, $D2
	db $3C, $D2
	db $38, $D2
	db $38, $D4
	db $38, $D4
	db $38, $D5
	db $33, $D4
	db $33, $D4
	db $35, $D2
	db $35, $D4
	db $39, $D4
	db $39, $D4
	db $39, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D4
	db $3C, $D2
	db $3E, $D2
	db $40, $D2
	db $41, $D4
	db $43, $D4
	db $41, $D4
	db $40, $D5
	db $3E, $D4
	db $40, $D4
	db $40, $D4
	db $40, $D2
	db $41, $D2
	db $40, $D2
	db $3E, $D2
	db $3C, $D2
	db $3E, $D4
	db $40, $D4
	db $3C, $D2
	db $3E, $D2
	db $40, $D2
	db $3E, $D4
	db $3E, $D4
	db $3A, $D2
	db $3A, $D4
	db $38, $D4
	db $38, $D4
	db $38, $D4
	db $38, $D2
	db $38, $D2
	db $38, $D2
	db $33, $D2
	db $33, $D2
	db $33, $D2
	db $33, $D2
	db $35, $D2
	db $35, $D2
	db $35, $D2
	db $39, $D2
	db $39, $D2
	db $39, $D2
	db $39, $D2
	db $39, $D2
	db $39, $D2
	db $39, $D2
	db $39, $D4
	db $3C, $D4
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D4
	db $3C, $D6
	db $24, $02
	db $65
SongMacro5A:
	db $A4, $94
	db $A4, $94
	db $A8, $92
	db $AB, $92
	db $AD, $92
	db $AE, $94
	db $AD, $94
	db $AB, $94
	db $A8, $92
	db $A6, $92
	db $A4, $92
	db $A2, $94
	db $A2, $94
	db $A2, $92
	db $A6, $92
	db $A9, $92
	db $AC, $94
	db $AB, $94
	db $A9, $94
	db $A6, $92
	db $A2, $92
	db $A1, $92
	db $9D, $94
	db $9D, $94
	db $A1, $92
	db $A4, $92
	db $A6, $92
	db $A7, $94
	db $A6, $92
	db $A4, $92
	db $A7, $94
	db $A6, $92
	db $A4, $92
	db $A1, $92
	db $A4, $94
	db $A4, $94
	db $A8, $92
	db $AB, $92
	db $AD, $92
	db $AE, $94
	db $AD, $92
	db $AB, $92
	db $A8, $94
	db $A4, $92
	db $A2, $92
	db $A3, $92
	db $65
SongMacro5B:
	db $98, $E2
	db $1E, $42
	db $98, $E2
	db $1E, $42
	db $98, $F4
	db $22, $42
	db $98, $E2
	db $1E, $42
	db $98, $E2
	db $1E, $42
	db $98, $E2
	db $98, $F4
	db $22, $44
	db $98, $E2
	db $1E, $42
	db $98, $E2
	db $1E, $42
	db $98, $F4
	db $22, $42
	db $98, $E2
	db $1E, $42
	db $98, $E2
	db $1E, $42
	db $98, $E2
	db $98, $F2
	db $98, $E2
	db $98, $E2
	db $1E, $42
	db $65
SongMacro5C:
	db $46, $D2
	db $46, $D2
	db $46, $D2
	db $4A, $D2
	db $48, $D2
	db $48, $D2
	db $48, $D2
	db $46, $D4
	db $46, $D4
	db $46, $D2
	db $48, $D2
	db $46, $D5
	db $41, $D2
	db $41, $D2
	db $41, $D2
	db $44, $D4
	db $41, $D4
	db $3E, $D4
	db $3A, $D4
	db $38, $D4
	db $3A, $D6
	db $39, $D2
	db $3A, $D2
	db $3C, $D2
	db $3E, $D4
	db $3F, $D2
	db $41, $D4
	db $45, $D4
	db $45, $D4
	db $46, $D2
	db $48, $D6
	db $43, $D2
	db $41, $D2
	db $40, $D2
	db $41, $D2
	db $43, $D2
	db $45, $D2
	db $46, $D2
	db $45, $D2
	db $43, $D2
	db $41, $D2
	db $43, $D2
	db $45, $D2
	db $43, $D2
	db $41, $D2
	db $40, $D2
	db $40, $D2
	db $40, $D2
	db $43, $D4
	db $46, $D4
	db $45, $D4
	db $43, $D2
	db $46, $D2
	db $45, $D2
	db $43, $D2
	db $46, $D2
	db $45, $D4
	db $41, $D5
	db $41, $D4
	db $3E, $D4
	db $3A, $D4
	db $38, $D4
	db $3A, $D6
	db $24, $02
	db $3C, $D2
	db $3E, $D2
	db $3F, $D4
	db $41, $D2
	db $45, $D4
	db $48, $D4
	db $46, $D2
	db $45, $D2
	db $41, $D4
	db $3F, $D2
	db $3C, $D4
	db $40, $D2
	db $41, $D2
	db $43, $D2
	db $45, $D2
	db $46, $D2
	db $45, $D2
	db $43, $D2
	db $41, $D2
	db $43, $D4
	db $43, $D2
	db $43, $D4
	db $43, $D5
	db $65
SongMacro5D:
	db $40, $D2
	db $40, $D2
	db $40, $D2
	db $40, $D2
	db $43, $D2
	db $43, $D2
	db $43, $D2
	db $40, $D4
	db $40, $D4
	db $40, $D2
	db $43, $D2
	db $40, $D5
	db $3E, $D2
	db $3E, $D2
	db $3E, $D2
	db $41, $D4
	db $3E, $D4
	db $3A, $D4
	db $38, $D4
	db $35, $D4
	db $38, $D6
	db $35, $D2
	db $37, $D2
	db $39, $D2
	db $3A, $D4
	db $3C, $D2
	db $3C, $D4
	db $3F, $D4
	db $41, $D4
	db $43, $D2
	db $45, $D6
	db $40, $D2
	db $3E, $D2
	db $3C, $D2
	db $3E, $D2
	db $40, $D2
	db $41, $D2
	db $43, $D2
	db $41, $D2
	db $40, $D2
	db $3E, $D2
	db $40, $D2
	db $41, $D2
	db $40, $D2
	db $3E, $D2
	db $3C, $D2
	db $3C, $D2
	db $3C, $D2
	db $40, $D4
	db $40, $D4
	db $40, $D4
	db $40, $D2
	db $40, $D2
	db $40, $D2
	db $40, $D2
	db $40, $D2
	db $40, $D4
	db $3C, $D5
	db $3E, $D4
	db $3A, $D4
	db $38, $D4
	db $35, $D4
	db $38, $D6
	db $24, $02
	db $39, $D2
	db $39, $D2
	db $3C, $D4
	db $3C, $D2
	db $41, $D4
	db $45, $D4
	db $43, $D2
	db $41, $D2
	db $3F, $D4
	db $3C, $D2
	db $39, $D4
	db $3C, $D2
	db $3E, $D2
	db $40, $D2
	db $41, $D2
	db $43, $D2
	db $41, $D2
	db $40, $D2
	db $3E, $D2
	db $40, $D4
	db $40, $D2
	db $40, $D4
	db $40, $D5
	db $65
SongMacro5E:
	db $30, $D6
	db $34, $D6
	db $37, $D6
	db $3A, $D6
	db $30, $D6
	db $34, $D6
	db $37, $D4
	db $35, $D4
	db $34, $D6
	db $32, $D6
	db $36, $D6
	db $39, $D6
	db $3B, $D6
	db $3C, $D4
	db $3B, $D4
	db $39, $D4
	db $37, $D4
	db $39, $D8
	db $65
SongMacro60:
	db $A4, $94
	db $A4, $94
	db $A8, $92
	db $AB, $92
	db $AD, $92
	db $AE, $94
	db $AD, $94
	db $AB, $94
	db $A1, $92
	db $A2, $92
	db $A3, $92
	db $A4, $94
	db $A4, $94
	db $A4, $92
	db $A1, $92
	db $9F, $92
	db $A4, $94
	db $B0, $94
	db $AB, $94
	db $A8, $92
	db $A6, $94
	db $65
SongMacro5F:
	db $32, $84
	db $32, $84
	db $2F, $85
	db $2D, $84
	db $2D, $84
	db $2D, $82
	db $2B, $84
	db $2B, $84
	db $32, $84
	db $32, $84
	db $30, $85
	db $2F, $84
	db $2F, $84
	db $2F, $82
	db $2D, $84
	db $2D, $84
	db $32, $84
	db $32, $84
	db $2F, $85
	db $2D, $84
	db $2D, $84
	db $2D, $82
	db $2B, $84
	db $2B, $84
	db $32, $84
	db $32, $84
	db $2F, $85
	db $32, $84
	db $32, $84
	db $32, $82
	db $2F, $84
	db $2B, $84
	db $65
SongMacro61:
	db $43, $D6
	db $41, $D5
	db $3E, $D4
	db $3E, $D4
	db $3E, $D2
	db $3E, $D4
	db $41, $D4
	db $43, $D4
	db $43, $D4
	db $43, $D2
	db $41, $D4
	db $43, $D6
	db $24, $02
	db $24, $06
	db $65
SongMacro62:
	db $34, $D2
	db $37, $D2
	db $38, $D2
	db $39, $D2
	db $3C, $D2
	db $3E, $D2
	db $3F, $D2
	db $40, $D2
	db $43, $D2
	db $44, $D2
	db $45, $D2
	db $48, $D4
	db $45, $D2
	db $43, $D2
	db $40, $D2
	db $48, $D2
	db $45, $D2
	db $43, $D2
	db $40, $D2
	db $43, $D2
	db $45, $D2
	db $43, $D2
	db $40, $D2
	db $43, $D8
	db $65
SongMacro63:
	db $3B, $D6
	db $39, $D5
	db $35, $D4
	db $35, $D4
	db $35, $D2
	db $35, $D4
	db $39, $D4
	db $3B, $D4
	db $3B, $D4
	db $3B, $D2
	db $39, $D4
	db $3B, $D6
	db $24, $02
	db $24, $06
	db $65
SongMacro64:
	db $3A, $D4
	db $3A, $D4
	db $3A, $D4
	db $3A, $D2
	db $3A, $D4
	db $3A, $D4
	db $3A, $D2
	db $3A, $D4
	db $3A, $D4
	db $3B, $D4
	db $3B, $D4
	db $3B, $D4
	db $3B, $D2
	db $3B, $D4
	db $3B, $D4
	db $3B, $D2
	db $3B, $D4
	db $3B, $D4
	db $65
SongMacro65:
	db $38, $D4
	db $38, $D4
	db $38, $D4
	db $38, $D2
	db $38, $D4
	db $38, $D4
	db $38, $D2
	db $38, $D4
	db $38, $D4
	db $35, $D4
	db $35, $D4
	db $35, $D4
	db $35, $D2
	db $35, $D4
	db $35, $D4
	db $35, $D2
	db $35, $D4
	db $35, $D4
	db $65
SongMacro66:
 	db $A2, $94
	db $A2, $94
	db $A2, $94
	db $A2, $92
	db $A2, $94
	db $A2, $94
	db $A2, $92
	db $A2, $94
	db $A2, $94
	db $9F, $94
	db $9F, $94
	db $9F, $94
	db $9F, $92
	db $9F, $94
	db $9F, $94
	db $9F, $92
	db $9F, $94
	db $9F, $94
	db $65
SongMacro67:
	db $37, $D2
	db $3A, $D2
	db $3B, $D2
	db $3C, $D2
	db $3F, $D2
	db $41, $D2
	db $42, $D2
	db $43, $D4
	db $46, $D2
	db $47, $D2
	db $48, $D2
	db $4B, $D2
	db $4D, $D2
	db $4E, $D4
	db $4F, $D2
	db $4D, $D2
	db $4B, $D2
	db $48, $D2
	db $4F, $D2
	db $4D, $D2
	db $4B, $D2
	db $48, $D2
	db $4E, $D2
	db $4D, $D2
	db $4B, $D2
	db $48, $D5
	db $46, $D6
	db $48, $D2
	db $4B, $D2
	db $4D, $D2
	db $4E, $D2
	db $4F, $D2
	db $4D, $D2
	db $4B, $D2
	db $48, $D2
	db $46, $D2
	db $48, $D2
	db $4B, $D1
	db $48, $D1
	db $46, $D1
	db $43, $D2
	db $46, $D2
	db $48, $D2
	db $4B, $D2
	db $48, $D2
	db $46, $D2
	db $43, $D2
	db $41, $D2
	db $42, $D2
	db $43, $D4
	db $46, $D2
	db $47, $D2
	db $48, $D2
	db $4B, $D4
	db $4D, $D4
	db $65
SongMacro68:
	db $A4, $96
	db $B0, $95
	db $AE, $94
	db $AB, $94
	db $A9, $94
	db $A7, $92
	db $A9, $92
	db $AB, $92
	db $A4, $94
	db $A4, $94
	db $B0, $94
	db $AE, $92
	db $AB, $94
	db $A9, $92
	db $A7, $92
	db $A9, $92
	db $AB, $92
	db $A9, $92
	db $A7, $94
	db $65
SongMacro69:
	db $4D, $D2
	db $4D, $D4
	db $4D, $D2
	db $4D, $D4
	db $4D, $D2
	db $4D, $D4
	db $4B, $D2
	db $48, $D2
	db $46, $D2
	db $44, $D2
	db $41, $D2
	db $44, $D2
	db $46, $D2
	db $4D, $D2
	db $4D, $D4
	db $4D, $D2
	db $4D, $D4
	db $4F, $D2
	db $50, $D5
	db $4F, $D4
	db $4D, $D4
	db $4B, $D4
	db $4D, $D2
	db $4D, $D2
	db $4D, $D2
	db $4D, $D2
	db $4D, $D2
	db $4D, $D2
	db $4D, $D2
	db $4D, $D4
	db $4B, $D2
	db $48, $D2
	db $46, $D2
	db $44, $D2
	db $41, $D2
	db $44, $D2
	db $46, $D2
	db $47, $D2
	db $48, $D2
	db $4B, $D2
	db $4C, $D2
	db $4D, $D2
	db $50, $D2
	db $52, $D2
	db $53, $D2
	db $54, $D8
	db $65
SongMacro6A:
	db $47, $D2
	db $48, $D4
	db $47, $D2
	db $48, $D4
	db $47, $D2
	db $48, $D4
	db $3F, $D2
	db $3C, $D2
	db $3A, $D2
	db $38, $D2
	db $35, $D2
	db $38, $D2
	db $3A, $D2
	db $47, $D2
	db $48, $D4
	db $47, $D2
	db $48, $D4
	db $48, $D2
	db $48, $D5
	db $48, $D4
	db $48, $D4
	db $48, $D4
	db $47, $D2
	db $48, $D2
	db $47, $D2
	db $48, $D2
	db $47, $D2
	db $48, $D2
	db $47, $D2
	db $48, $D4
	db $3F, $D2
	db $3C, $D2
	db $3A, $D2
	db $38, $D2
	db $35, $D2
	db $38, $D2
	db $3A, $D2
	db $3B, $D2
	db $3C, $D2
	db $3F, $D2
	db $40, $D2
	db $41, $D2
	db $44, $D2
	db $46, $D2
	db $47, $D2
	db $48, $D8
	db $65
SongMacro6B:
	db $4F, $D2
	db $4F, $D4
	db $4F, $D2
	db $4F, $D4
	db $4F, $D2
	db $4F, $D4
	db $4F, $D2
	db $4F, $D2
	db $4F, $D2
	db $4F, $D4
	db $4F, $D4
	db $4F, $D2
	db $4D, $D2
	db $4A, $D2
	db $48, $D2
	db $46, $D2
	db $43, $D2
	db $46, $D2
	db $48, $D5
	db $46, $D4
	db $43, $D6
	db $4D, $D2
	db $4D, $D4
	db $4D, $D2
	db $4D, $D4
	db $4D, $D2
	db $4D, $D4
	db $4B, $D2
	db $48, $D2
	db $46, $D2
	db $44, $D2
	db $41, $D2
	db $44, $D2
	db $46, $D2
	db $47, $D2
	db $48, $D2
	db $4B, $D2
	db $4D, $D2
	db $50, $D4
	db $4D, $D2
	db $4B, $D4
	db $48, $D2
	db $4B, $D2
	db $4D, $D2
	db $50, $D4
	db $4D, $D6
	db $54, $D2
	db $52, $D2
	db $4F, $D2
	db $4D, $D2
	db $4B, $D2
	db $48, $D2
	db $4B, $D2
	db $4D, $D2
	db $4E, $D2
	db $4D, $D2
	db $4B, $D2
	db $48, $D2
	db $46, $D2
	db $48, $D2
	db $4B, $D4
	db $48, $D4
	db $46, $D2
	db $43, $D4
	db $48, $D8
	db $24, $02
	db $65
SongMacro6C:
	db $49, $D2
	db $4A, $D4
	db $49, $D2
	db $4A, $D4
	db $49, $D2
	db $4A, $D4
	db $49, $D2
	db $4A, $D2
	db $49, $D2
	db $4A, $D4
	db $49, $D4
	db $32, $D6
	db $37, $D6
	db $3A, $D6
	db $37, $D6
	db $47, $D2
	db $48, $D4
	db $47, $D2
	db $48, $D4
	db $47, $D2
	db $48, $D2
	db $30, $D6
	db $2C, $D6
	db $35, $D6
	db $30, $D6
	db $38, $D6
	db $35, $D6
	db $3C, $D4
	db $4F, $D4
	db $37, $D6
	db $33, $D6
	db $30, $D6
	db $37, $D6
	db $3C, $D5
	db $43, $D8
	db $24, $02
	db $65
SongMacro6D:
	db $40, $D4
	db $40, $D4
	db $40, $D4
	db $40, $D2
	db $40, $D4
	db $40, $D4
	db $40, $D2
	db $40, $D4
	db $40, $D4
	db $65
SongMacro6E:
	db $3C, $D4
	db $3B, $D4
	db $3C, $D4
	db $3B, $D2
	db $3C, $D4
	db $3C, $D4
	db $3B, $D2
	db $3C, $D4
	db $3B, $D4
	db $65
SongMacro6F:
	db $A4, $94
	db $A4, $94
	db $A4, $94
	db $A4, $92
	db $A4, $94
	db $A4, $94
	db $A4, $92
	db $A4, $94
	db $A4, $94
	db $65

SongTab:
.Empty
	dw EmptyA, EmptyB, EmptyC, EmptyD, NoteLens1
.Title
	dw TitleA, TitleB, TitleC, TitleD, NoteLens1
.Graveyard
	dw GraveyardA, GraveyardB, GraveyardC, GraveyardD, NoteLens1
.Sweetshop
	dw SweetshopA, SweetshopB, SweetshopC, SweetshopD, NoteLens1
.Subway
	dw SubwayA, SubwayB, SubwayC, SubwayD, NoteLens1
	
NoteLens1:
	db 3, 4, 6, 9, 12, 18, 24, 36, 48, 72, 96, 144, 192, 8, 16, 32
	
InsTab:
	dw InsRest
	dw InsBassDrum
	dw InsSnare
	dw InsHiHatC
	dw InsHiHatP
	dw InsHiHatO
	dw InsCymbal
	dw InsTomTom1
	dw InsTomTom2
	dw InsPlain1
	dw InsArp1
	dw InsArp2
	dw InsPlain2
	dw InsBell1
	dw InsPiano1
	dw InsPlain3
	dw InsSweep1
	dw InsSweep2
	dw InsSweep3
	dw InsArp7
	dw InsArp12
	dw InsSweep4
	dw InsDoNotUse1
	dw InsDoNotUse2
	dw InsDoNotUse3
	dw InsSweep5
	dw InsArpTrem
	dw InsBell2
	dw InsSlideDown1
	dw InsSlideDown2
	dw InsBassDrum2
	dw InsSnare2
	
InsRest:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $02
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsBassDrum:
	;Period ctrl
	db $C0
	;Duty
	db $BD
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq00
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq00
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsSnare:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq01
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq01
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsHiHatC:
	;Period ctrl
	db $C0
	;Duty
	db $BB
	;Initial vol/env
	db $61
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq02
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsHiHatP:
	;Period ctrl
	db $C0
	;Duty
	db $BB
	;Initial vol/env
	db $41
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq02
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsHiHatO:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq02
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq03
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsCymbal:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $F7
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq03
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsTomTom1:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq03
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq00
InsTomTom2:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq04
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq00
InsPlain1:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $87
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsArp1:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq07
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq02
InsArp2:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq08
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq03
InsPlain2:
	;Period ctrl
	db $80
	;Duty
	db $40
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq09
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq04
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsBell1:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0A
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq04
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsPiano1:
	;Period ctrl
	db $80
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0B
	;Vib seq delay
	db 10
	;Vib seq ptr
	dw VibSeq05
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsPlain3:
	;Period ctrl
	db $80
	;Duty
	db $40
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0C
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq04
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsSweep1:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0D
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq06
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsSweep2:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0E
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsSweep3:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq0F
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsArp7:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $84
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq04
InsArp12:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $84
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq05
InsSweep4:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $84
	;Env seq delay
	db 0
	;Env seq ptr
	dw 0
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq06
InsDoNotUse1:
InsDoNotUse2:
InsDoNotUse3:
InsSweep5:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq10
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsArpTrem:
	;Period ctrl
	db $80
	;Duty
	db $40
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq12
	;Vib seq delay
	db 0
	;Vib seq ptr
	dw 0
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq07
InsBell2:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq13
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq07
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsSlideDown1:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq14
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq08
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq08
InsSlideDown2:
	;Period ctrl
	db $C0
	;Duty
	db $00
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq11
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq04
	;Pitch mod delay
	db 1
	;Pitch mod ptr
	dw ModSeq08
InsBassDrum2:
	;Period ctrl
	db $C0
	;Duty
	db $BD
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq15
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq00
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0
InsSnare2:
	;Period ctrl
	db $80
	;Duty
	db $80
	;Initial vol/env
	db $00
	;Env seq delay
	db 1
	;Env seq ptr
	dw EnvSeq16
	;Vib seq delay
	db 1
	;Vib seq ptr
	dw VibSeq01
	;Pitch mod delay
	db 0
	;Pitch mod ptr
	dw 0

EnvSeq00:
	db $F0, 1
	db $00, 1
	db $40, 1
	db $00, 1
	db $FF
EnvSeq01:
	db $F0, 1
	db $80, 1
	db $40, 2
	db $20, 2
	db $10, 5
	db $00, 1
	db $FF
EnvSeq02:
	db $50, 2
	db $30, 4
	db $20, 8
	db $10, 8
	db $10, 8
	db $00, 1
	db $FF
EnvSeq03:
	db $F0, 2
	db $80, 2
	db $60, 2
	db $30, 1
	db $20, 2
	db $10, 2
	db $00, 1
	db $FF
EnvSeq04:
	db $C0, 2
	db $70, 4
	db $40, 4
	db $20, 4
	db $00, 1
	db $FF
EnvSeq05:
	db $80, 1
	db $40, 1
	db $00, 2
	db $10, 1
	db $00, 1
	db $FF
EnvSeq06:
	db $A0, 1
	db $50, 1
	db $40, 1
	db $30, 1
	db $20, 1
	db $00, 1
	db $FF
EnvSeq07:
	db $80, 1
	db $70, 3
	db $60, 4
	db $50, 6
	db $40, 4
	db $30, 2
	db $20, 60
	db $10, 60
	db $00, 1
	db $FF
EnvSeq08:
	db $80, 1
	db $70, 1
	db $60, 4
	db $50, 6
	db $40, 6
	db $30, 20
	db $20, 60
	db $10, 60
	db $00, $01
	db $FF
EnvSeq09:
	db $A0, 2
	db $90, 4
	db $70, 40
	db $60, 60
	db $50, 40
	db $40, 30
	db $30, 40
	db $10, 40
	db $00, 1
	db $FF
EnvSeq0A:
	db $90, 2
	db $80, 3
	db $70, 2
	db $60, 4
	db $50, 7
	db $40, 8
	db $30, 4
	db $20, 20
	db $10, 60
	db $10, 60
	db $00, 1
	db $FF
EnvSeq0B:
	db $80, 5
	db $60, 200
	db $40, 200
	db $20, 200
	db $10, 60
	db $00, 1
	db $FF
EnvSeq0C:
	db $90, 2
	db $80, 4
	db $60, 40
	db $50, 60
	db $30, 40
	db $10, 80
	db $00, 1
	db $FF
EnvSeq0D:
	db $20, 1
	db $40, 30
	db $60, 240
	db $00, 1
	db $FF
EnvSeq0E:
	db $20, 3
	db $40, 12
	db $60, 50
	db $00, $01
	db $FF
EnvSeq0F:
	db $20, 3
	db $40, 40
	db $60, 240
	db $60, 240
	db $00, 1
	db $FF
EnvSeq10:
	db $20, 8
	db $40, 20
	db $60, 100
	db $00, $01
	db $FF
EnvSeq11:
	db $20, 4
	db $40, 200
	db $40, 100
	db $60, 40
	db $FF
EnvSeq12:
	db $90, 3
	db $80, 5
	db $70, 4
	db $50, 40
	db $40, 60
	db $30, 40
	db $20, 30
	db $10, 40
	db $10, 40
	db $00, 1
	db $FF
EnvSeq13:
	db $60, 1
	db $40, 58
	db $20, 50
	db $00, 1
	db $FF
EnvSeq14:
	db $20, 5
	db $30, 5
	db $40, 5
	db $70, 200
	db $50, 200
	db $30, 200
	db $00, 1
	db $FF
EnvSeq15:
	db $C0, 1
	db $00, 1
	db $30, 1
	db $00, 1
	db $FF
EnvSeq16:
	db $C0, 1
	db $90, 1
	db $60, 1
	db $40, 2
	db $20, 2
	db $10, 5
	db $00, 1
	db $FF
VibSeq00:
	db 96, 200
	db $7E
VibSeq01:
	db 55, 2
	db 100, 2
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 1
	db 55, 1
	db 34, 16
	db $7E
VibSeq02:
	db 18, 200
	db $7E
VibSeq03:
	db 34, 1
	db 16, 200
	db $7E
VibSeq04:
	db 3, 3
	db -3, 3
	db -3, 3
	db 3, 3
	db $7D
	dw VibSeq04
VibSeq05:
	db 1, 2
	db -1, 2
	db 1, 2
	db -1, 2
	db $7D
	dw VibSeq04
VibSeq06:
	db 6, 2
	db -6, 2
	db -6, 2
	db 6, 2
	db $7D
	dw VibSeq06
VibSeq07:
	db -3, 2
	db 3, 2
	db 3, 2
	db -3, 2
	db $7D
	dw VibSeq07
VibSeq08:
	db 13, 3
	db -13, 3
	db -13, 3
	db 13, 3
	db $7D
	dw VibSeq04
ModSeq00:
	db 1, -1
	db 1, -2
	db 1, -3
	db 1, -4
	db 1, -5
	db 1, -6
	db 1, -7
	db 1, -8
	db 1, -9
	db 1, -10
	db 1, -11
	db 1, -12
	db 1, -13
	db 200, -13
	db $FF
	dw ModSeq00
ModSeq01:
	db 2, 0
	db 1, 1
	db 1, 2
	db 1, 3
	db 200, 3
	db $FF
	dw ModSeq01
ModSeq02:
	db 3, 0
	db 3, 12
	db 3, 0
	db 3, 12
	db 3, 0
	db 3, 12
	db $FF
	dw ModSeq02
ModSeq03:
	db 4, 12
	db 4, 0
	db 4, 12
	db 4, 0
	db 4, 12
	db 4, 0
	db $FF
	dw ModSeq03
ModSeq04:
	db 1, 0
	db 1, 4
	db 1, 7
	db 1, 0
	db 1, 4
	db 1, 7
	db $FF
	dw ModSeq04
ModSeq05:
	db 1, 4
	db 1, 7
	db 1, 12
	db 1, 4
	db 1, 7
	db 1, 12
	db $FF
	dw ModSeq05
ModSeq06:
	db 1, 7
	db 1, 12
	db 1, 16
	db 1, 7
	db 1, 12
	db 1, 16
	db $FF
	dw ModSeq06
ModSeq07:
	db 2, 12
	db 2, 0
	db 2, 12
	db 2, 0
	db 2, 12
	db 2, 0
	db $FF
	dw ModSeq07
ModSeq08:
	db 12, 0
	db 3, -1
	db 3, -2
	db 3, -3
	db 3, -4
	db 3, -5
	db 3, -6
	db 3, -7
	db 3, -8
	db 3, -9
	db 3, -10
	db 3, -11
	db 3, -12
	db 3, -13
	db 3, -14
	db 3, -15
	db 3, -16
	db 3, -17
	db 3, -18
	db 3, -19
	db 3, -20
	db 3, -21
	db 3, -22
	db 3, -23
	db 200, -24
	db $FF
	dw ModSeq08
SongMacroTab:
	dw SongMacro00
	dw SongMacro01
	dw SongMacro02
	dw SongMacro03
	dw SongMacro04
	dw SongMacro05
	dw SongMacro06
	dw SongMacro07
	dw SongMacro08
	dw SongMacro09
	dw SongMacro0A
	dw SongMacro0B
	dw SongMacro0C
	dw SongMacro0D
	dw SongMacro0E
	dw SongMacro0F
	dw SongMacro10
	dw SongMacro11
	dw SongMacro12
	dw SongMacro13
	dw SongMacro14
	dw SongMacro15
	dw SongMacro16
	dw SongMacro17
	dw SongMacro18
	dw SongMacro19
	dw SongMacro1A
	dw SongMacro1B
	dw SongMacro1C
	dw SongMacro1D
	dw SongMacro1E
	dw SongMacro1F
	dw SongMacro20
	dw SongMacro21
	dw SongMacro22
	dw SongMacro23
	dw SongMacro24
	dw SongMacro25
	dw SongMacro26
	dw SongMacro27
	dw SongMacro28
	dw SongMacro29
	dw SongMacro2A
	dw SongMacro2B
	dw SongMacro2C
	dw SongMacro2D
	dw SongMacro2E
	dw SongMacro2F
	dw SongMacro30
	dw SongMacro31
	dw SongMacro32
	dw SongMacro33
	dw SongMacro34
	dw SongMacro35
	dw SongMacro36
	dw SongMacro37
	dw SongMacro38
	dw SongMacro39
	dw SongMacro3A
	dw SongMacro3B
	dw SongMacro3C
	dw SongMacro3D
	dw SongMacro3E
	dw SongMacro3F
	dw SongMacro40
	dw SongMacro41
	dw SongMacro42
	dw SongMacro43
	dw SongMacro44
	dw SongMacro45
	dw SongMacro46
	dw SongMacro47
	dw SongMacro48
	dw SongMacro49
	dw SongMacro4A
	dw SongMacro4B
	dw SongMacro4C
	dw SongMacro4D
	dw SongMacro4E
	dw SongMacro4F
	dw SongMacro50
	dw SongMacro51
	dw SongMacro52
	dw SongMacro53
	dw SongMacro54
	dw SongMacro55
	dw SongMacro56
	dw SongMacro57
	dw SongMacro58
	dw SongMacro59
	dw SongMacro5A
	dw SongMacro5B
	dw SongMacro5C
	dw SongMacro5D
	dw SongMacro5E
	dw SongMacro5F
	dw SongMacro60
	dw SongMacro61
	dw SongMacro62
	dw SongMacro63
	dw SongMacro64
	dw SongMacro65
	dw SongMacro66
	dw SongMacro67
	dw SongMacro68
	dw SongMacro69
	dw SongMacro6A
	dw SongMacro6B
	dw SongMacro6C
	dw SongMacro6D
	dw SongMacro6E
	dw SongMacro6F
	
SECTION "Audio RAM", WRAMX[AudioRAM]

C1PlayFlag: ds 1
C1Len: ds 1
C1Pos: ds 2
C1Freq: ds 2
Unk06: ds 1
C1Duty: ds 1
C1Env: ds 1
Unk09: ds 1
C1EnvSeqDelay: ds 1
C1EnvSeq: ds 2
C1VibSeqDelay: ds 1
C1VibSeq: ds 2
C1ModSeqDelay: ds 1
C1ModSeq: ds 2
C1MacroTimesLeft: ds 1
C1MacroTrans: ds 1
C1InMacro: ds 1
C1MacroRet: ds 2
C2PlayFlag: ds 1
C2Len: ds 1
C2Pos: ds 2
C2Freq: ds 2
Unk1E: ds 1
C2Duty: ds 1
C2Env: ds 1
Unk21: ds 1
C2EnvSeqDelay: ds 1
C2EnvSeq: ds 2
C2VibSeqDelay: ds 1
C2VibSeq: ds 2
C2ModSeqDelay: ds 1
C2ModSeq: ds 2
C2MacroTimesLeft: ds 1
C2MacroTrans: ds 1
C2InMacro: ds 1
C2MacroRet: ds 2
C3PlayFlag: ds 1
C3Len: ds 1
C3Pos: ds 2
C3Freq: ds 2
Unk36: ds 1
C3Duty: ds 1
C3Env: ds 1
Unk39: ds 1
C3EnvSeqDelay: ds 1
C3EnvSeq: ds 2
C3VibSeqDelay: ds 1
C3VibSeq: ds 2
C3ModSeqDelay: ds 1
C3ModSeq: ds 2
C3MacroTimesLeft: ds 1
C3MacroTrans: ds 1
C3InMacro: ds 1
C3MacroRet: ds 2
C4PlayFlag: ds 1
C4Len: ds 1
C4Pos: ds 2
C4Freq: ds 2
Unk4E: ds 1
C4Duty: ds 1
C4Env: ds 1
Unk51: ds 1
C4EnvSeqDelay: ds 1
C4EnvSeq: ds 2
C4VibSeqDelay: ds 1
C4VibSeq: ds 2
C4ModSeqDelay: ds 1
C4ModSeq: ds 2
C4MacroTimesLeft: ds 1
C4MacroTrans: ds 1
C4InMacro: ds 1
C4MacroRet: ds 2
NoteLens: ds 2
CurRestartPos: ds 2
CurNoise: ds 1
CurTrans: ds 1
CurCmd: ds 1
LoopFlag: ds 1
C1SFXPos: ds 2
C1SFXDelay: ds 1
C2SFXPos: ds 2
C2SFXDelay: ds 1
C3SFXPos: ds 2
C3SFXDelay: ds 1
C4SFXPos: ds 2
C4SFXDelay: ds 1
CurSFX: ds 2
PlayFlag: ds 1
BeatCounter: ds 1
Tempo: ds 1
MasterPan: ds 1
MasterSFXPan: ds 1
CurChan: ds 1
CurNoteC1: ds 1
CurNoteC2: ds 1
CurNoteC3: ds 1
CurNoteC4: ds 1