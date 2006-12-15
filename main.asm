#include <p18f2455.inc>

;Process table definition
		cblock	0x00
			pc_0u
			pc_0h
			pc_0l
			status_0
			w_0
			pc_1u
			pc_1h
			pc_1l
			status_1
			w_1
			pc_2u
			pc_2h
			pc_2l
			status_2
			w_2
		endc

;Variables
        cblock 0x20           
                portb_buf		; Buffer to hold the state of Port B
                count0          ; Counter to slow the interrupts
                flag500ms       ; Contains a 0 unless 500 1-ms Timer 2
                                ; interrupts have been processed.
        endc

; Processor reset vector
        ORG     0x000             
        goto    main             

; Interrupt service vector
		ORG     0x008           

		movff	TOSU,INDF0		; save the upper program address
		incf	FSR0L			; FIXME: this will only work if the addr never overflows!!!
		movff	TOSH, INDF0		; save the high program address
		incf	FSR0L			; FIXME: this will only work if the addr never overflows!!!			
		movff	TOSL, INDF0		; save the low program address
		
        movwf   INDF2			; save off current W register contents
        swapf   STATUS,W        ; move status register into W register
        movwf   INDF1			; save off contents of STATUS register
		 
        btfsc   PIR1,TMR2IF     ; If Timer 2 (the scheduler) caused the interrupt, handle it.
        call    Scheduler

		movf	INDF0,W			; restore the upper program address
		movwf	TOSU
		incf	FSR0L			; FIXME: this will only work if the addr never overflows!!!
		movf	INDF0,W 		; restore the high program address
		movwf	TOSH
		incf	FSR0L			; FIXME: this will only work if the addr never overflows!!!
		movf	INDF0,W 		; restore the low program address
		movwf	TOSL
		
		;Return the INDF0 to the correct position for the next interrupt handle
		decf	FSR0L
		decf	FSR0L

        swapf   INDF1,w			; retrieve copy of STATUS register
        movwf   STATUS			; restore pre-isr STATUS register contents
        swapf   INDF2,f
        swapf   INDF2,w			; restore pre-isr W register contents

		bsf INTCON,	GIE			; Clear flag and continue. 
        return					; return from interrupt


;****************************************************************************

; Place microprograms here
;****************************************************************************
; Round Robin Schduler
; Increment the address by 3 (FSR0,1,2)
; Check to make sure that this does not overflow (FSR0,1,2)
	; if it does than it needs to reset to 0x00 (FSR0,1,2)
; 

Scheduler
		;Move the INDF pointers down the process table
        movlw	0x03			
        addwf	FSR0L,F			;FIXME: Overflow
        movlw	0x05
        addwf	FSR1L,F			;FIXME: Overflow
        movlw	0x05
        addwf	FSR2L,F			;FIXME: Overflow
        
        movlw	pc_2u			
        cpfsgt	FSR0L			;Compare to see if within bounds
        goto	WithinBound
        
        ;Out of bounds, go back to process 0
        movlw	pc_0u
      	movwf	FSR0L
      	movlw	status_0
      	movwf	FSR1L
      	movlw	w_0
      	movwf	FSR2L
      		
WithinBound        
        ;incf    count0,F                     
        ;btfss   STATUS,Z		; if overflow then set flag500ms
        ;goto    EndScheduler

        ;movlw   H'FF'
        ;movwf   flag500ms
        ;clrf   count0

;EndScheduler
		bcf PIR1,TMR2IF ; Clear flag and continue.       
        return

main
		clrf	PORTB			; Initialize PORTB
		clrf	TRISB
		
		clrf	portb_buf		; Initialize the port b buffer
        clrf    count0
        clrf    flag500ms       ; Turn off the flag which, when set, says 500 ms has elapsed.

		movlw	pc_1l			; Initialize the process table
		movwf	FSR0L
		movlw	task1
		movwf	INDF0
		movlw	pc_2l
		movwf	FSR0L
		movlw	task2
		movwf	INDF0
		
		movlw	pc_0u			; Setup up the pointers
		movwf	FSR0L
		movlw	status_0
		movwf	FSR1L
		movlw	w_0
		movwf	FSR2L


		

;Initialize Timer 2
        clrf    TMR2            ; Clear Timer2 register
        bsf     INTCON,PEIE     ; Enable peripheral interrupts
        clrf    PIE1            ; Mask all peripheral interrupts except
        bsf     PIE1,TMR2IE     ; the timer 2 interrupts.
        clrf    PIR1            ; Clear peripheral interrupts Flags
        movlw   B'01001001'     ; Set Postscale = 10, Prescale = 4, Timer 2 = off.
        movwf   T2CON
        movlw   D'25'-1         ; Set the PR2 register for Timer 2 to divide by 25.
        movwf   PR2
        bsf     INTCON,GIE      ; Global interrupt enable.
        bsf     T2CON,TMR2ON    ; Timer2 starts to increment

task0

	goto task0
	
task1
	
	goto task1

task2
	
	goto task2

        END
