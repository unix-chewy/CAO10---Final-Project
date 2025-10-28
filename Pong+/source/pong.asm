;-----------------------------------------------------------------------------
; PONG+ Enhanced Game - Assembly Implementation
; Enhanced Features: Two-player mode, power-up system, adaptive ball physics
; Development Team: Kyle Naguit, Fritzch Santos, Joney Sunga
;-----------------------------------------------------------------------------

segment data
    ;-------------------------------------------------------------------------
    ; Primary Game State Variables
    ;-------------------------------------------------------------------------
    frame_counter              db  0       ; Controls frame timing using system clock
    player_two_score           db  0       ; Player two's current score
    player_one_score           db  0       ; Player one's current score
    ball_velocity_index        db  0       ; Current ball speed tier (0-2)

    ;-------------------------------------------------------------------------
    ; Power-up System Variables
    ;-------------------------------------------------------------------------
    velocity_boost_active      db  0       ; Velocity boost status
    velocity_boost_duration    db  0       ; Remaining boost time
    base_velocity_x            dw  0       ; Original X velocity storage
    base_velocity_y            dw  0       ; Original Y velocity storage
    velocity_multiplier        dw  2       ; Boost speed factor

    ; Player-specific original velocity storage
    base_vel_x_player_left     dw  0  
    base_vel_y_player_left     dw  0
    base_vel_x_player_right    dw  0  
    base_vel_y_player_right    dw  0

    ; Right Player Enhancement Variables
    paddle_enhance_right       db  0
    paddle_timer_right         db  0  
    standard_height_right      dw  32h
    enhanced_height_right      dw  64h

    ; Left Player Enhancement Variables
    paddle_enhance_left        db  0
    paddle_timer_left          db  0
    standard_height_left       dw  32h
    enhanced_height_left       dw  64h

    ; Ball Deceleration System
    slow_ball_left_active      db  0  
    slow_ball_left_timer       db  0    
    slow_ball_right_active     db  0  
    slow_ball_right_timer      db  0
    
    ;-------------------------------------------------------------------------
    ; User Interface Elements
    ;-------------------------------------------------------------------------
    game_header              db  'Final Project for Computer Architecture', '$'
    score_prefix             db  'Team Members: Naguit Kyle, Santos Fritzch, Sunga Joney', '$'
    score_separator          db ' x ', '$'
    speed_display_text       db '  Computer -- Current speed: ', '$'
    speed_range_info         db '(from 1 to 3)', '$'
    player_one_display       db  '00', '$'
    player_two_display       db  '00', '$'
    current_speed_display    db  '1', '$'
    boost_status_message     db  'VELOCITY BOOST ACTIVE!', '$'

    ;-------------------------------------------------------------------------
    ; Game Object Properties
    ;-------------------------------------------------------------------------
    ball_initial_x           dw  127h    ; Starting X coordinate
    ball_initial_y           dw  0D7h    ; Starting Y coordinate
    ball_position_x          dw  127h    ; Current X position
    ball_position_y          dw  0D7h    ; Current Y position
    ball_diameter            dw  07h     ; Ball size
    ball_velocity_x          dw  00H     ; Horizontal movement speed
    ball_velocity_y          dw  00h     ; Vertical movement speed
    velocity_tiers           dw  05h, 0Ah, 0Fh  ; Speed levels

    ; Display configuration
    display_width            dw 280h     ; Screen width (640px)
    display_height           dw 1E0h     ; Screen height (480px)
    border_offset            dw 05h      ; Collision boundary
    play_area_top            dw 032h     ; Top play boundary
    side_boundary            dw 05Ah     ; Side margin

    ;-------------------------------------------------------------------------
    ; Paddle Configuration  
    ;-------------------------------------------------------------------------
    paddle_thickness         dw 0AH      ; Paddle width
    standard_paddle_height   dw 032h     ; Normal paddle height

    ; Individual paddle properties
    left_paddle_height       dw 032h     ; Left paddle height
    right_paddle_height      dw 032h     ; Right paddle height

    ; Right Paddle (Player 1)
    right_paddle_x           dw 253h
    right_paddle_y           dw 0D7h

    ; Left Paddle (Player 2)
    left_paddle_x            dw 28h
    left_paddle_y            dw 0D7h
    
    paddle_move_speed        dw 0Ah      ; Paddle movement rate

    ;-------------------------------------------------------------------------
    ; Graphics Configuration
    ;-------------------------------------------------------------------------
    active_color		        db		bright_white

    ; Color definitions
    black           equ  0
    blue            equ  1
    green           equ  2
    cyan            equ  3
    red             equ  4
    magenta         equ  5
    brown           equ  6
    white           equ  7
    gray            equ  8
    light_blue      equ  9
    light_green     equ  10
    light_cyan      equ  11
    pink            equ  12
    light_magenta   equ  13
    yellow          equ  14
    bright_white    equ  15
    
    ; Drawing coordinates
    coord_x   	    dw  0         
    coord_y  	    dw  0         
    diff_x		    dw 0         
    diff_y		    dw 0         

segment code
    ;-------------------------------------------------------------------------
    ; Initializes ball movement using base speed
    ;-------------------------------------------------------------------------
initialize_ball_motion:
		mov     si, 0000h
		lea     bx, [velocity_tiers + si]
		mov     ax, word [bx]
		mov     word [ball_velocity_x], ax
		neg     ax
        mov     word [ball_velocity_y], ax
		ret

;-----------------------------------------------------------------------------
; PROGRAM INITIALIZATION
;-----------------------------------------------------------------------------

..start:
    ; Initialize system segments
    mov     ax, data
    mov     ds, ax
    mov     ax, stack
    mov     ss, ax
    mov     sp, stacktop

    ; Prepare game environment
    call    clear_display
	call    initialize_ball_motion

    ;-------------------------------------------------------------------------
    ; Primary Game Loop - Frame Rate Controlled
    ;-------------------------------------------------------------------------
game_loop:
    mov     ah, 2Ch             ; Get system time
    int     21h
    cmp     dl, byte [frame_counter]
    je      check_powerups
    mov     byte [frame_counter], dl
    
    ; Frame rendering sequence
    call    clear_display
    call    update_ball_position
    call    draw_ball_sprite
    call    process_paddle_movement
    call    render_paddles
    call    display_interface
    call    update_powerup_timers

check_powerups:
    jmp     game_loop

;-----------------------------------------------------------------------------
; Updates all power-up timers and deactivates expired power-ups
;-----------------------------------------------------------------------------
update_powerup_timers:
    ; Check velocity boost
    cmp     byte [velocity_boost_active], 1
    jne     .check_right_paddle_boost
    
    dec     byte [velocity_boost_duration]
    jnz     .check_right_paddle_boost
    
    ; Restore original velocity
    mov     ax, word [base_velocity_x]
    mov     word [ball_velocity_x], ax
    mov     ax, word [base_velocity_y]
    mov     word [ball_velocity_y], ax
    mov     byte [velocity_boost_active], 0

.check_right_paddle_boost:
    cmp byte [paddle_enhance_right], 1
    jne .check_left_paddle_boost
    
    dec byte [paddle_timer_right]
    jnz .check_left_paddle_boost
    
    ; Restore right paddle height
    mov ax, word [standard_height_right]
    mov word [right_paddle_height], ax
    mov byte [paddle_enhance_right], 0

.check_left_paddle_boost:
    cmp byte [paddle_enhance_left], 1
    jne .check_slow_ball_left
    
    dec byte [paddle_timer_left]
    jnz .check_slow_ball_left
    
    ; Restore left paddle height
    mov ax, word [standard_height_left]
    mov word [left_paddle_height], ax
    mov byte [paddle_enhance_left], 0

.check_slow_ball_left:
    cmp byte [slow_ball_left_active], 1
    jne .check_slow_ball_right
    
    dec byte [slow_ball_left_timer]
    jnz .check_slow_ball_right
    
    ; Restore original speed
    mov ax, word [base_vel_x_player_left]
    mov word [ball_velocity_x], ax
    mov ax, word [base_vel_y_player_left]
    mov word [ball_velocity_y], ax
    
    mov byte [slow_ball_left_active], 0
    jmp .exit_powerup_update

.check_slow_ball_right:
    cmp byte [slow_ball_right_active], 1
    jne .exit_powerup_update
    
    dec byte [slow_ball_right_timer]
    jnz .exit_powerup_update
    
    ; Restore original speed  
    mov ax, word [base_vel_x_player_right]
    mov word [ball_velocity_x], ax
    mov ax, word [base_vel_y_player_right]
    mov word [ball_velocity_y], ax
    
    mov byte [slow_ball_right_active], 0

.exit_powerup_update:
    ret

;-----------------------------------------------------------------------------
; GRAPHICS RENDERING ENGINE
;-----------------------------------------------------------------------------
; Renders both player paddles
render_paddles:
    ; Draw left paddle
    mov     cx, word [left_paddle_x]
    mov     dx, word [left_paddle_y]

draw_left_paddle_vertical:
    mov     ah, 0Ch
    mov     al, 0Fh
    mov     bh, 00h
    int     10h
    inc     cx
    mov     ax, cx
    sub     ax, word [left_paddle_x]
    cmp     ax, word [paddle_thickness]
    jng     draw_left_paddle_vertical
    mov     cx, word [left_paddle_x]
    inc     dx
    mov     ax, dx
    sub     ax, word [left_paddle_y]
    cmp     ax, word [left_paddle_height]
    jng     draw_left_paddle_vertical

    ; Draw right paddle
    mov     cx, word [right_paddle_x]
    mov     dx, word [right_paddle_y]

draw_right_paddle_vertical:
    mov     ah, 0Ch
    mov     al, 0Fh
    mov     bh, 00h
    int     10h
    inc     cx
    mov     ax, cx
    sub     ax, word [right_paddle_x]
    cmp     ax, word [paddle_thickness]
    jng     draw_right_paddle_vertical
    mov     cx, word [right_paddle_x]
    inc     dx
    mov     ax, dx
    sub     ax, word [right_paddle_y]
    cmp     ax, word [right_paddle_height]
    jng     draw_right_paddle_vertical

    ret

; Renders the game ball
draw_ball_sprite:
    mov     byte [active_color], red
    mov     ax, word [ball_position_x]
    push    ax
    mov     ax, word [ball_position_y]
    push    ax
    mov     ax, word [ball_diameter]
    push    ax
    call    full_circle
    ret

;-----------------------------------------------------------------------------
; Updates ball position and handles collisions
;-----------------------------------------------------------------------------
update_ball_position:
    ; Horizontal movement
    mov     ax, word [ball_velocity_x]
    add     word [ball_position_x], ax

    ; Check paddle collisions before boundaries
    call    detect_paddle_contact

    ; Horizontal boundary checks
    mov     ax, word [ball_position_x]
    sub     ax, word [ball_diameter]
    mov     bx, word [border_offset]
    add     bx, word [border_offset]
    cmp     ax, bx
    jl      near invert_x_velocity

    mov     ax, word [ball_position_x]
    add     ax, word [ball_diameter]
    mov     bx, word [display_width]
    sub     bx, word [border_offset]
    cmp     ax, bx
    jg      near award_point_player_two

    ; Vertical movement
    mov     ax, word [ball_velocity_y]
    add     word [ball_position_y], ax

    ; Vertical boundary checks
    mov     ax, word [ball_position_y]
    sub     ax, word [ball_diameter]
    mov     bx, word [play_area_top]
    add     bx, word [border_offset]
    cmp     ax, bx
    jl      near invert_y_velocity

    mov     ax, word [ball_position_y]
    add     ax, word [ball_diameter]
    mov     bx, word [display_height]
    sub     bx, word [border_offset]
    sub     bx, word [border_offset]
    cmp     ax, bx
    jg      near invert_y_velocity
    ret

;-----------------------------------------------------------------------------
; Detects paddle collisions and determines collision region
;-----------------------------------------------------------------------------
detect_paddle_contact:
    ; Left paddle collision detection
    mov     ax, word [ball_position_x]
    sub     ax, word [ball_diameter]
    mov     bx, word [left_paddle_x]
    add     bx, word [paddle_thickness]
    cmp     ax, bx
    jg      skip_left_paddle_check
    mov     ax, word [ball_position_x]
    add     ax, word [ball_diameter]
    cmp     ax, word [left_paddle_x]
    jl      skip_left_paddle_check
    mov     ax, word [ball_position_y]
    add     ax, word [ball_diameter]
    cmp     ax, word [left_paddle_y]
    jl      skip_left_paddle_check
    mov     ax, word [ball_position_y]
    sub     ax, word [ball_diameter]
    mov     bx, word [left_paddle_y]
    add     bx, word [left_paddle_height]    ; ← CHANGED to left_paddle_height
    cmp     ax, bx
    jg      skip_left_paddle_check
    
    ; Left paddle collision handling
    mov     ax, word [ball_position_y]
    mov     bx, word [left_paddle_y]
    add     bx, word [ball_diameter]
    cmp     ax, bx
    jl      left_paddle_player_one_scores
    mov     bx, word [left_paddle_y]
    add     bx, word [left_paddle_height]    ; ← CHANGED to left_paddle_height
    sub     bx, word [ball_diameter]
    cmp     ax, bx
    jg      left_paddle_player_one_scores
    
    call    award_point_player_two
    jmp     no_paddle_contact
    
left_paddle_player_one_scores:
    call    award_point_player_one
    jmp     no_paddle_contact

skip_left_paddle_check:
    ; Right paddle horizontal collision
    mov     ax, word [ball_position_x]
    add     ax, word [ball_diameter]
    cmp     ax, word [right_paddle_x]
    jl      no_paddle_contact

    mov     ax, word [ball_position_x]
    sub     ax, word [ball_diameter]
    mov     bx, word [right_paddle_x]
    add     bx, word [paddle_thickness]
    cmp     ax, bx
    jg      no_paddle_contact

    ; Right paddle vertical collision
    mov     ax, word [ball_position_y]
    add     ax, word [ball_diameter]
    cmp     ax, word [right_paddle_y]
    jl      no_paddle_contact

    mov     ax, word [ball_position_y]
    sub     ax, word [ball_diameter]
    mov     bx, word [right_paddle_y]
    add     bx, word [right_paddle_height]    ; ← CHANGED to right_paddle_height
    cmp     ax, bx
    jg      no_paddle_contact

    ; Determine collision region
    mov     ax, word [ball_position_y]
    mov     bx, word [right_paddle_y]
    add     bx, word [ball_diameter]
    cmp     ax, bx
    jl      player_two_scores

    mov     bx, word [right_paddle_y]
    add     bx, word [right_paddle_height]    ; ← CHANGED to right_paddle_height
    sub     bx, word [ball_diameter]
    cmp     ax, bx
    jg      player_two_scores

    call    award_point_player_one
    jmp     no_paddle_contact

player_two_scores:
    call    award_point_player_two

no_paddle_contact:
    ret

;-----------------------------------------------------------------------------
; Scoring procedures
;-----------------------------------------------------------------------------
award_point_player_one:
    neg     word [ball_velocity_x]
    inc     byte [player_one_score]
    call    update_player_one_display
    ret

award_point_player_two:
    neg     word [ball_velocity_x]
    inc     byte [player_two_score]
    call    update_player_two_display
    ret

;-----------------------------------------------------------------------------
; Game reset procedure
;-----------------------------------------------------------------------------
reset_game_state:
    mov     byte [player_one_score], 00H
    mov     byte [player_two_score], 00H
    call    update_player_one_display
    call    update_player_two_display
    ret

;-----------------------------------------------------------------------------
; Velocity inversion procedures
;-----------------------------------------------------------------------------
invert_y_velocity:
    neg     word [ball_velocity_y]
    ret

invert_x_velocity:
    neg     word [ball_velocity_x]
    ret

;-----------------------------------------------------------------------------
; Paddle movement processing
;-----------------------------------------------------------------------------
process_paddle_movement:
    mov     ah, 01h                 ; Check keyboard status
    int     16h
    jz      exit_paddle_processing
    mov     ah, 00h                 ; Get key press
    int     16h
    jmp     process_key_input

process_key_input:
    ; Exit game keys
    cmp al, 78h ; 'x'
    je near terminate_game
    cmp al, 58h ; 'X'
    je near terminate_game

    ; Player 1 controls (Left paddle)
    cmp al, 77h ; 'w'
    je move_left_paddle_upward
    cmp al, 57h ; 'W'
    je move_left_paddle_upward
    cmp al, 73h ; 's'
    je move_left_paddle_downward
    cmp al, 83h ; 'S'
    je move_left_paddle_downward
    cmp al, 61h ; 'a' - Paddle enhance
    je near activate_left_paddle_enhance
    cmp al, 41h ; 'A'
    je near activate_left_paddle_enhance
    cmp al, 64h ; 'd' - Velocity boost
    je near activate_velocity_boost
    cmp al, 44h ; 'D'
    je near activate_velocity_boost
    cmp al, 71h ; 'q' - Slow ball
    je near activate_left_slow_ball
    cmp al, 51h ; 'Q'
    je near activate_left_slow_ball

    ; Player 2 controls (Right paddle)
    cmp ah, 48h ; Up arrow
    je move_right_paddle_upward
    cmp ah, 50h ; Down arrow
    je move_right_paddle_downward
    cmp ah, 4Bh ; Left arrow - Paddle enhance
    je near activate_right_paddle_enhance
    cmp ah, 4Dh ; Right arrow - Velocity boost
    je near activate_velocity_boost
    
    ; Player 2 slow ball
    cmp al, 2Fh ; '/' key
    je near activate_right_slow_ball
    cmp al, 3Fh ; '?' key
    je near activate_right_slow_ball

    jmp exit_paddle_processing

; Left paddle movement
move_left_paddle_upward:
    mov     ax, word [paddle_move_speed]
    sub     word [left_paddle_y], ax
    mov     bx, word [play_area_top]
    cmp     word [left_paddle_y], bx
    jl      adjust_left_paddle_top
    jmp     exit_paddle_processing

adjust_left_paddle_top:
    mov     word [left_paddle_y], bx
    jmp     exit_paddle_processing

move_left_paddle_downward:
    mov     ax, word [paddle_move_speed]
    add     word [left_paddle_y], ax
    mov     ax, word [display_height]
    sub     ax, word [border_offset]
    sub     ax, word [standard_paddle_height]
    cmp     word [left_paddle_y], ax
    jg      adjust_left_paddle_bottom
    jmp     exit_paddle_processing

adjust_left_paddle_bottom:
    mov     word [left_paddle_y], ax
    jmp     exit_paddle_processing

; Right paddle movement
move_right_paddle_upward:
    mov     ax, word [paddle_move_speed]
    sub     word [right_paddle_y], ax
	mov	bx, word [play_area_top]
    cmp     word [right_paddle_y], bx
    jl      adjust_right_paddle_top
    jmp     exit_paddle_processing

adjust_right_paddle_top:
    mov     word [right_paddle_y], bx
    jmp     exit_paddle_processing

move_right_paddle_downward:
    mov     ax, word [paddle_move_speed]
    add     word [right_paddle_y], ax
    mov     ax, word [display_height]
    sub     ax, word [border_offset]
    sub     ax, word [standard_paddle_height]
    cmp     word [right_paddle_y], ax
    jg      adjust_right_paddle_bottom
    jmp     exit_paddle_processing

adjust_right_paddle_bottom:
    mov     word [right_paddle_y], ax
    jmp     exit_paddle_processing

exit_paddle_processing:
    ret

;-----------------------------------------------------------------------------
; Power-up activation procedures
;-----------------------------------------------------------------------------
activate_velocity_boost:
    ; Prevent boost if slow ball active
    cmp byte [slow_ball_left_active], 1
    je exit_velocity_boost
    cmp byte [slow_ball_right_active], 1  
    je exit_velocity_boost
    
    cmp byte [velocity_boost_active], 1
    je exit_velocity_boost
    
    ; Store original velocities
    mov     ax, word [ball_velocity_x]
    mov     word [base_velocity_x], ax
    mov     ax, word [ball_velocity_y]
    mov     word [base_velocity_y], ax
    
    ; Apply velocity boost
    mov     ax, word [ball_velocity_x]
    sal     ax, 1
    mov     word [ball_velocity_x], ax
    
    mov     ax, word [ball_velocity_y]
    sal     ax, 1
    mov     word [ball_velocity_y], ax
    
    ; Activate boost
    mov     byte [velocity_boost_active], 1
    mov     byte [velocity_boost_duration], 36
    
    jmp     exit_velocity_boost

exit_velocity_boost:
    ret

activate_right_paddle_enhance:
    cmp byte [paddle_enhance_right], 1
    je exit_right_enhance
    
    ; Apply right paddle enhancement
    mov ax, word [right_paddle_height]
    mov word [standard_height_right], ax
    mov ax, word [enhanced_height_right]
    mov word [right_paddle_height], ax
    
    mov byte [paddle_enhance_right], 1
    mov byte [paddle_timer_right], 72
    
exit_right_enhance:
    ret

activate_left_paddle_enhance:
    cmp byte [paddle_enhance_left], 1
    je exit_left_enhance
    
    ; Apply left paddle enhancement
    mov ax, word [left_paddle_height]
    mov word [standard_height_left], ax
    mov ax, word [enhanced_height_left]
    mov word [left_paddle_height], ax
    
    mov byte [paddle_enhance_left], 1
    mov byte [paddle_timer_left], 72
    
exit_left_enhance:
    ret

activate_left_slow_ball:
    cmp byte [slow_ball_left_active], 1
    je exit_slow_ball_left
    
    ; Prevent multiple slow balls
    cmp byte [slow_ball_right_active], 1
    je exit_slow_ball_left
    
    ; Store original velocity
    mov ax, word [ball_velocity_x]
    mov word [base_vel_x_player_left], ax
    mov ax, word [ball_velocity_y] 
    mov word [base_vel_y_player_left], ax
    
    ; Apply slow effect
    sar word [ball_velocity_x], 1
    sar word [ball_velocity_y], 1
    
    mov byte [slow_ball_left_active], 1
    mov byte [slow_ball_left_timer], 64
    
exit_slow_ball_left:
    jmp exit_paddle_processing

activate_right_slow_ball:
    cmp byte [slow_ball_right_active], 1
    je exit_slow_ball_right
    
    ; Prevent multiple slow balls
    cmp byte [slow_ball_left_active], 1
    je exit_slow_ball_right
    
    ; Store original velocity
    mov ax, word [ball_velocity_x]
    mov word [base_vel_x_player_right], ax
    mov ax, word [ball_velocity_y] 
    mov word [base_vel_y_player_right], ax
    
    ; Apply slow effect
    sar word [ball_velocity_x], 1
    sar word [ball_velocity_y], 1
    
    mov byte [slow_ball_right_active], 1
    mov byte [slow_ball_right_timer], 64
    
exit_slow_ball_right:
    jmp exit_paddle_processing

;-----------------------------------------------------------------------------
; Ball position reset
;-----------------------------------------------------------------------------
reset_ball_location:
    mov     ax, word [ball_initial_x]
    mov     word [ball_position_x], ax
    mov     ax, word [ball_initial_y]
    mov     word [ball_position_y], ax
    ret

;-----------------------------------------------------------------------------
; User interface rendering
;-----------------------------------------------------------------------------
display_interface:
    ; Header line 1
    mov     ah, 02H
    mov     bh, 00H
    mov     dh, 01H
    mov     dl, 06H
    int     10H

    mov     ah, 09H
    lea     dx, [game_header]
    int     21H

    ; Header line 2 - Prefix
    mov     ah, 02H
    mov     bh, 00H
    mov     dh, 02H
    mov     dl, 06H
    int     10H

    mov     ah, 09H
    lea     dx, [score_prefix]
    int     21H

    ; Player 1 score
    mov     ah, 09H
    lea     dx, [player_one_display]
    int     21H

    ; Score separator
    mov     ah, 09H
    lea     dx, [score_separator]
    int     21H

    ; Player 2 score
    mov     ah, 09H
    lea     dx, [player_two_display]
    int     21H

    ; Speed display text
    mov     ah, 09H
    lea     dx, [speed_display_text]
    int     21H

    ; Current speed
    mov     ah, 09H
    lea     dx, [current_speed_display]
    int     21H

    ; Boost status indicator
    cmp     byte [velocity_boost_active], 1
    jne     skip_boost_indicator
    
    mov     ah, 02H
    mov     bh, 00H
    mov     dh, 03H
    mov     dl, 06H
    int     10H
    
    mov     ah, 09H
    lea     dx, [boost_status_message]
    int     21H

skip_boost_indicator:
    ; Draw divider line
	mov		byte[active_color],bright_white
	mov		ax,0
	push	ax
	mov		ax,49
	push	ax
	mov		ax,639
	push	ax
	mov		ax,49
	push	ax
	call	line
    ret

;-----------------------------------------------------------------------------
; Score display updates
;-----------------------------------------------------------------------------
update_player_one_display:
    mov al, byte [player_one_score]
    lea si, [player_one_display]
    call convert_score_to_text
    ret

update_player_two_display:
    mov al, byte [player_two_score]
    lea si,  [player_two_display]
    call convert_score_to_text
    ret

;-----------------------------------------------------------------------------
; Score conversion to display text
;-----------------------------------------------------------------------------
convert_score_to_text:
    push bx
    push cx
    push dx

    mov ah, 0
    mov bl, 10
    div bl

    add ah, 30h
    mov byte [si+1], ah

    add al, 30h
    mov byte [si], al

    pop dx
    pop cx
    pop bx
    ret

;-----------------------------------------------------------------------------
; Display management
;-----------------------------------------------------------------------------
clear_display:
    mov     ah, 0
    mov     al, 12h
    int     10h

    mov     ah, 0Bh
    mov     bh, 00h
    mov     bl, 00h
    int     10h
    ret

;-----------------------------------------------------------------------------
; Graphics primitives
;-----------------------------------------------------------------------------

caracter:
		pushf                   ; Pushes the flags register onto the stack
		push 		ax          ; Saves the AX register
		push 		bx          ; Saves the BX register
		push		cx          ; Saves the CX register
		push		dx          ; Saves the DX register
		push		si          ; Saves the SI register
		push		di          ; Saves the DI register
		push		bp          ; Saves the BP register
    		mov     	ah,9          ; BIOS function to WRITE CHARACTER AND ATTRIBUTE
    		mov     	bh,0          ; Page number 0
    		mov     	cx,1          ; Number of times to write the character (1 time)
   		mov     	bl,[active_color]      ; Attribute (color) for the character, gets from 'active_color' variable
    		int     	10h         ; Calls the BIOS video service to write the character
		pop		bp          ; Restores the BP register
		pop		di          ; Restores the DI register
		pop		si          ; Restores the SI register
		pop		dx          ; Restores the DX register
		pop		cx          ; Restores the CX register
		pop		bx          ; Restores the BX register
		pop		ax          ; Restores the AX register
		popf                    ; Pops the flags register from the stack
		ret                     ; Returns from the procedure

; Draws a pixel at coordinates (X, Y) with the current color. Parameters are passed on the stack: Y then X.
plot_xy:
		push		bp          ; Saves the BP register
		mov		bp,sp          ; Sets BP to the stack pointer to access parameters
		pushf                   ; Pushes the flags register onto the stack
		push 		ax          ; Saves the AX register
		push 		bx          ; Saves the BX register
		push		cx          ; Saves the CX register
		push		dx          ; Saves the DX register
		push		si          ; Saves the SI register
		push		di          ; Saves the DI register
	    mov     	ah,0ch        ; BIOS function to WRITE PIXEL
	    mov     	al,[active_color]      ; Pixel color, gets from 'active_color' variable
	    mov     	bh,0          ; Page number 0
	    mov     	dx,[bp+4]     ; Gets the Y coordinate from the stack [bp+4]
	    mov     	cx,[bp+6]     ; Gets the X coordinate from the stack [bp+6]
	    int     	10h         ; Calls the BIOS video service to plot pixel
		pop		di          ; Restores the DI register
		pop		si          ; Restores the SI register
		pop		dx          ; Restores the DX register
		pop		cx          ; Restores the CX register
		pop		bx          ; Restores the BX register
		pop		ax          ; Restores the AX register
		popf                    ; Pops the flags register from the stack
		pop		bp          ; Restores the BP register
		ret		4             ; Returns from the procedure, clears 4 bytes from the stack (2 parameters: X and Y - 2 bytes each)

; Draws the outline of a circle using Bresenham's circle algorithm. Parameters are passed on the stack: radius, center Y, center X.
circle:
	push 	bp              ; Saves the BP register
	mov	 	bp,sp              ; Sets BP to the stack pointer to access parameters
	pushf                       ; Pushes the flags register onto the stack
	push 	ax              ; Saves the AX register
	push 	bx              ; Saves the BX register
	push	cx              ; Saves the CX register
	push	dx              ; Saves the DX register
	push	si              ; Saves the SI register
	push	di              ; Saves the DI register

	mov		ax,[bp+8]         ; Gets the center X (xc) from the stack [bp+8]
	mov		bx,[bp+6]         ; Gets the center Y (yc) from the stack [bp+6]
	mov		cx,[bp+4]         ; Gets the radius (r) from the stack [bp+4]

	mov 	dx,bx           ; Initializes DX with center Y (yc)
	add		dx,cx           ; DX = yc + r (topmost point)
	push    ax              ; Pushes center X (xc) onto the stack
	push	dx              ; Pushes yc + r onto the stack
	call plot_xy          ; Plots pixel at (xc, yc+r) - top point

	mov		dx,bx           ; Initializes DX with center Y (yc)
	sub		dx,cx           ; DX = yc - r (bottommost point)
	push    ax              ; Pushes center X (xc) onto the stack
	push	dx              ; Pushes yc - r onto the stack
	call plot_xy          ; Plots pixel at (xc, yc-r) - bottom point

	mov 	dx,ax           ; Initializes DX with center X (xc)
	add		dx,cx           ; DX = xc + r (rightmost point)
	push    dx              ; Pushes xc + r onto the stack
	push	bx              ; Pushes center Y (yc) onto the stack
	call plot_xy          ; Plots pixel at (xc+r, yc) - right point

	mov		dx,ax           ; Initializes DX with center X (xc)
	sub		dx,cx           ; DX = xc - r (leftmost point)
	push    dx              ; Pushes xc - r onto the stack
	push	bx              ; Pushes center Y (yc) onto the stack
	call plot_xy          ; Plots pixel at (xc-r, yc) - left point

	mov		di,cx           ; DI = radius (r)
	sub		di,1	         ; DI = r - 1
	mov		dx,0  	         ; DX = 0 (x variable for Bresenham's algorithm)

; Bresenham's circle algorithm loop
stay:				             ; Loop start
	mov		si,di           ; SI = d (decision variable)
	cmp		si,0            ; Compares d with 0
	jg		inf             ; Jumps if d is Greater than 0 (selects lower pixel)
	mov		si,dx		     ; SI = x
	sal		si,1		     ; SI = 2x
	add		si,3            ; SI = 2x + 3
	add		di,si           ; d = d + 2x + 3
	inc		dx		         ; x = x + 1
	jmp		plotar          ; Jumps to plot pixels
inf:
	mov		si,dx           ; SI = x
	sub		si,cx  		     ; SI = x - y
	sal		si,1            ; SI = 2(x - y)
	add		si,5            ; SI = 2(x - y) + 5
	add		di,si           ; d = d + 2(x - y) + 5
	inc		dx		         ; x = x + 1
	dec		cx		         ; y = y - 1 (decrements radius, effectively y coordinate in the algorithm)

plotar:
	mov		si,dx           ; SI = x
	add		si,ax           ; SI = x + xc
	push    si		         ; Pushes x + xc onto the stack (x coordinate)
	mov		si,cx           ; SI = y (radius as y in the algorithm)
	add		si,bx           ; SI = y + yc
	push    si		         ; Pushes y + yc onto the stack (y coordinate)
	call plot_xy		     ; Plots pixel at (xc+x, yc+y) - octant 2
	mov		si,ax           ; SI = xc
	add		si,dx           ; SI = xc + x
	push    si		         ; Pushes xc + x onto the stack
	mov		si,bx           ; SI = yc
	sub		si,cx           ; SI = yc - y
	push    si		         ; Pushes yc - y onto the stack
	call plot_xy		     ; Plots pixel at (xc+x, yc-y) - octant 7
	mov		si,ax           ; SI = xc
	add		si,cx           ; SI = xc + y
	push    si		         ; Pushes xc + y onto the stack
	mov		si,bx           ; SI = yc
	add		si,dx           ; SI = yc + x
	push    si		         ; Pushes yc + x onto the stack
	call plot_xy		     ; Plots pixel at (xc+y, yc+x) - octant 2 (error in original comment?) - should be octant 1
	mov		si,ax           ; SI = xc
	add		si,cx           ; SI = xc + y
	push    si		         ; Pushes xc + y onto the stack
	mov		si,bx           ; SI = yc
	sub		si,dx           ; SI = yc - x
	push    si		         ; Pushes yc - x onto the stack
	call plot_xy		     ; Plots pixel at (xc+y, yc-x) - octant 8
	mov		si,ax           ; SI = xc
	sub		si,dx           ; SI = xc - x
	push    si		         ; Pushes xc - x onto the stack
	mov		si,bx           ; SI = yc
	add		si,cx           ; SI = yc + y
	push    si		         ; Pushes yc + y onto the stack
	call plot_xy		     ; Plots pixel at (xc-x, yc+y) - octant 3
	mov		si,ax           ; SI = xc
	sub		si,dx           ; SI = xc - x
	push    si		         ; Pushes xc - x onto the stack
	mov		si,bx           ; SI = yc
	sub		si,cx           ; SI = yc - y
	push    si		         ; Pushes yc - y onto the stack
	call plot_xy		     ; Plots pixel at (xc-x, yc-y) - octant 6
	mov		si,ax           ; SI = xc
	sub		si,cx           ; SI = xc - y
	push    si		         ; Pushes xc - y onto the stack
	mov		si,bx           ; SI = yc
	sub		si,dx           ; SI = yc - x
	push    si		         ; Pushes yc - x onto the stack
	call plot_xy		     ; Plots pixel at (xc-y, yc-x) - octant 5
	mov		si,ax           ; SI = xc
	sub		si,cx           ; SI = xc - y
	push    si		         ; Pushes xc - y onto the stack
	mov		si,bx           ; SI = yc
	add		si,dx           ; SI = yc + x
	push    si		         ; Pushes yc + x onto the stack
	call plot_xy		     ; Plots pixel at (xc-y, yc+x) - octant 4

	cmp		cx,dx           ; Compares y (radius) with x
	jb		fim_circle      ; Jumps if y is Below x (algorithm complete)
	jmp		stay		         ; Otherwise, continues the loop

fim_circle:
	pop		di              ; Restores the DI register
	pop		si              ; Restores the SI register
	pop		dx              ; Restores the DX register
	pop		cx              ; Restores the CX register
	pop		bx              ; Restores the BX register
	pop		ax              ; Restores the AX register
	popf                    ; Pops the flags register from the stack
	pop		bp              ; Restores the BP register
	ret		6             ; Returns from the procedure, clears 6 bytes from the stack (3 parameters: radius, yc, xc - 2 bytes each)


; Draws a filled circle using Bresenham's circle algorithm and horizontal lines. Parameters are passed on the stack: radius, center Y, center X.
full_circle:
	push 	bp              ; Saves the BP register
	mov	 	bp,sp              ; Sets BP to the stack pointer to access parameters
	pushf                       ; Pushes the flags register onto the stack
	push 	ax              ; Saves the AX register
	push 	bx              ; Saves the BX register
	push	cx              ; Saves the CX register
	push	dx              ; Saves the DX register
	push	si              ; Saves the SI register
	push	di              ; Saves the DI register

	mov		ax,[bp+8]         ; Gets center X (xc) from the stack [bp+8]
	mov		bx,[bp+6]         ; Gets center Y (yc) from the stack [bp+6]
	mov		cx,[bp+4]         ; Gets radius (r) from the stack [bp+4]

	mov		si,bx           ; SI = yc
	sub		si,cx           ; SI = yc - r
	push    ax		         ; Pushes center X (xc) onto the stack
	push	si		         ; Pushes yc - r onto the stack (line start Y)
	mov		si,bx           ; SI = yc
	add		si,cx           ; SI = yc + r
	push	ax		         ; Pushes center X (xc) onto the stack
	push	si		         ; Pushes yc + r onto the stack (line end Y)
	call line             ; Draws horizontal line from (xc, yc-r) to (xc, yc+r) - diameter line

	mov		di,cx           ; DI = radius (r)
	sub		di,1	         ; DI = r - 1
	mov		dx,0  	         ; DX = 0 (x variable for Bresenham's algorithm)

; Bresenham's circle algorithm loop for filled circle
stay_full:				         ; Loop start
	mov		si,di           ; SI = d (decision variable)
	cmp		si,0            ; Compares d with 0
	jg		inf_full        ; Jumps if d is Greater than 0 (selects lower pixel)
	mov		si,dx		     ; SI = x
	sal		si,1		     ; SI = 2x
	add		si,3            ; SI = 2x + 3
	add		di,si           ; d = d + 2x + 3
	inc		dx		         ; x = x + 1
	jmp		plotar_full     ; Jumps to draw horizontal lines
inf_full:
	mov		si,dx           ; SI = x
	sub		si,cx  		     ; SI = x - y
	sal		si,1            ; SI = 2(x - y)
	add		si,5            ; SI = 2(x - y) + 5
	add		di,si           ; d = d + 2(x - y) + 5
	inc		dx		         ; x = x + 1
	dec		cx		         ; y = y - 1 (decrements radius, effectively y coordinate in the algorithm)

plotar_full:
	mov		si,ax           ; SI = xc
	add		si,cx           ; SI = xc + y
	push	si		         ; Pushes xc + y onto the stack (Line start X coordinate)
	mov		si,bx           ; SI = yc
	sub		si,dx           ; SI = yc - x
	push    si		         ; Pushes yc - x onto the stack (Line start Y coordinate)
	mov		si,ax           ; SI = xc
	add		si,cx           ; SI = xc + y
	push	si		         ; Pushes xc + y onto the stack (Line end X coordinate)
	mov		si,bx           ; SI = yc
	add		si,dx           ; SI = yc + x
	push    si		         ; Pushes yc + x onto the stack (Line end Y coordinate)
	call 	line             ; Draws horizontal line between calculated points
	mov		si,ax           ; SI = xc
	add		si,dx           ; SI = xc + x
	push	si		         ; Pushes xc + x onto the stack
	mov		si,bx           ; SI = yc
	sub		si,cx           ; SI = yc - y
	push    si		         ; Pushes yc - y onto the stack
	mov		si,ax           ; SI = xc
	add		si,dx           ; SI = xc + x
	push	si		         ; Pushes xc + x onto the stack
	mov		si,bx           ; SI = yc
	add		si,dx           ; SI = yc + y
	push    si		         ; Pushes yc + y onto the stack
	call	line             ; Draws horizontal line between calculated points
	mov		si,ax           ; SI = xc
	sub		si,dx           ; SI = xc - x
	push	si		         ; Pushes xc - x onto the stack
	mov		si,bx           ; SI = yc
	sub		si,cx           ; SI = yc - y
	push    si		         ; Pushes yc - y onto the stack
	mov		si,ax           ; SI = xc
	sub		si,dx           ; SI = xc - x
	push	si		         ; Pushes xc - x onto the stack
	mov		si,bx           ; SI = yc
	add		si,cx           ; SI = yc + y
	push    si		         ; Pushes yc + y onto the stack
	call	line             ; Draws horizontal line between calculated points
	mov		si,ax           ; SI = xc
	sub		si,cx           ; SI = xc - y
	push	si		         ; Pushes xc - y onto the stack
	mov		si,bx           ; SI = yc
	sub		si,dx           ; SI = yc - x
	push    si		         ; Pushes yc - x onto the stack
	mov		si,ax           ; SI = xc
	sub		si,cx           ; SI = xc - y
	push	si		         ; Pushes xc - y onto the stack
	mov		si,bx           ; SI = yc
	add		si,dx           ; SI = yc + x
	push    si		         ; Pushes yc + x onto the stack
	call	line             ; Draws horizontal line between calculated points

	cmp		cx,dx           ; Compares y (radius) with x
	jb		fim_full_circle ; Jumps if y is Below x (algorithm complete)
	jmp		stay_full		     ; Otherwise, continues the loop

fim_full_circle:
	pop		di              ; Restores the DI register
	pop		si              ; Restores the SI register
	pop		dx              ; Restores the DX register
	pop		cx              ; Restores the CX register
	pop		bx              ; Restores the BX register
	pop		ax              ; Restores the AX register
	popf                    ; Pops the flags register from the stack
	pop		bp              ; Restores the BP register
	ret		6             ; Returns from the procedure, clears 6 bytes from the stack (3 parameters: radius, yc, xc - 2 bytes each)

; Draws a line between two points (x1, y1) and (x2, y2) using Bresenham's line algorithm.
line:
		push		bp          ; Saves the BP register
		mov		bp,sp          ; Sets BP to the stack pointer to access parameters
		pushf                   ; Pushes the flags register onto the stack
		push 		ax          ; Saves the AX register
		push 		bx          ; Saves the BX register
		push		cx          ; Saves the CX register
		push		dx          ; Saves the DX register
		push		si          ; Saves the SI register
		push		di          ; Saves the DI register
		mov		ax,[bp+10]        ; Gets x1 from the stack [bp+10]
		mov		bx,[bp+8]         ; Gets y1 from the stack [bp+8]
		mov		cx,[bp+6]         ; Gets x2 from the stack [bp+6]
		mov		dx,[bp+4]         ; Gets y2 from the stack [bp+4]
		cmp		ax,cx           ; Compares x1 and x2
		je		line2           ; Jumps if x1 is Equal to x2 (vertical line)
		jb		line1           ; Jumps if x1 is Below x2 (x1 < x2)
		xchg		ax,cx           ; Swaps x1 and x2
		xchg		bx,dx           ; Swaps y1 and y2
		jmp		line1           ; Jumps to line1 (now x1 < x2 is guaranteed)
line2:		                                 ; diff_x=0 - Vertical line case
		cmp		bx,dx           ; Compares y1 and y2
		jb		line3           ; Jumps if y1 is Below y2 (y1 < y2)
		xchg		bx,dx           ; Swaps y1 and y2 (now y1 < y2 is guaranteed)
line3:	                                 ; dx > bx - y2 > y1
		push		ax          ; Pushes x1 (which is equal to x2 in vertical line case)
		push		bx          ; Pushes y1
		call 		plot_xy       ; Plots pixel at (x1, y1)
		cmp		bx,dx           ; Compares y1 and y2
		jne		line31          ; Jumps if y1 is Not Equal to y2 (more pixels to draw)
		jmp		fim_line        ; Jumps to end of line drawing if y1 == y2
line31:		inc		bx          ; Increments y1
		jmp		line3           ; Jumps back to line3 to plot the next pixel

;diff_x <>0 - Non-vertical line case
line1:
; Compares absolute values of diff_x and diff_y knowing that cx > ax (x2 > x1)
	; cx > ax (x2 > x1)
		push		cx          ; Saves x2
		sub		cx,ax           ; cx = x2 - x1 (diff_x)
		mov		[diff_x],cx     ; Stores diff_x in memory
		pop		cx          ; Restores x2
		push		dx          ; Saves y2
		sub		dx,bx           ; dx = y2 - y1 (diff_y)
		ja		line32          ; Jumps if y2 is Above y1 (y2 > y1)
		neg		dx          ; Negates diff_y if y2 <= y1 (makes it positive for algorithm)
line32:
		mov		[diff_y],dx     ; Stores diff_y in memory
		pop		dx          ; Restores y2

		push		ax          ; Saves x1
		mov		ax,[diff_x]     ; Gets diff_x
		cmp		ax,[diff_y]     ; Compares diff_x and diff_y
		pop		ax          ; Restores x1
		jb		line5           ; Jumps if diff_x is Below diff_y (more vertical line)

	; cx > ax and diff_x>diff_y - Mostly horizontal line
		push		cx          ; Saves x2
		sub		cx,ax           ; cx = x2 - x1 (diff_x)
		mov		[diff_x],cx     ; Stores diff_x in memory
		pop		cx          ; Restores x2
		push		dx          ; Saves y2
		sub		dx,bx           ; dx = y2 - y1 (diff_y)
		mov		[diff_y],dx     ; Stores diff_y in memory
		pop		dx          ; Restores y2

		mov		si,ax           ; SI = x1 (current x)
line4:
		push		ax          ; Saves x1
		push		dx          ; Saves y2
		push		si          ; Saves current x
		sub		si,ax	         ; si = current x - x1
		mov		ax,[diff_y]     ; Gets diff_y
		imul		si          ; AX:DX = diff_y * (current x - x1) - numerator
		mov		si,[diff_x]		     ; Gets diff_x
		shr		si,1            ; si = diff_x / 2 - rounding term
; if numerator (DX)>0 add if <0 subtract - rounding logic
		cmp		dx,0            ; Checks the sign of DX (high word of numerator)
		jl		ar1             ; Jumps if DX is Less than 0 (negative numerator)
		add		ax,si           ; AX = AX + diff_x/2 - adds rounding term
		adc		dx,0            ; DX:AX += diff_x/2 (handles carry)
		jmp		arc1            ; Jumps to arc1
ar1:		sub		ax,si           ; AX = AX - diff_x/2 - subtracts rounding term
		sbb		dx,0            ; DX:AX -= diff_x/2 (handles borrow)
arc1:
		idiv		word [diff_x]   ; AX = (DX:AX) / diff_x - calculates y increment
		add		ax,bx           ; AX = AX + y1 - calculates current y
		pop		si          ; Restores current x
		push		si          ; Pushes current x
		push		ax          ; Pushes current y
		call		plot_xy       ; Plots pixel at (current x, current y)
		pop		dx          ; Restores y2
		pop		ax          ; Restores x1
		cmp		si,cx           ; Compares current x with x2
		je		fim_line        ; Jumps if current x is Equal to x2 (line end reached)
		inc		si          ; Increments current x
		jmp		line4           ; Jumps back to line4 for the next pixel

line5:		cmp		bx,dx           ; Compares y1 and y2
		jb 		line7           ; Jumps if y1 is Below y2 (y1 < y2)
		xchg		ax,cx           ; Swaps x1 and x2
		xchg		bx,dx           ; Swaps y1 and y2
line7:
		push		cx          ; Saves x2
		sub		cx,ax           ; cx = x2 - x1 (diff_x)
		mov		[diff_x],cx     ; Stores diff_x in memory
		pop		cx          ; Restores x2
		push		dx          ; Saves y2
		sub		dx,bx           ; dx = y2 - y1 (diff_y)
		mov		[diff_y],dx     ; Stores diff_y in memory
		pop		dx          ; Restores y2

		mov		si,bx           ; SI = y1 (current y)
line6:
		push		dx          ; Saves y2
		push		si          ; Saves current y
		push		ax          ; Saves x1
		sub		si,bx	         ; si = current y - y1
		mov		ax,[diff_x]     ; Gets diff_x
		imul		si          ; AX:DX = diff_x * (current y - y1) - numerator
		mov		si,[diff_y]		     ; Gets diff_y
		shr		si,1            ; si = diff_y / 2 - rounding term
; if numerator (DX)>0 add if <0 subtract - rounding logic
		cmp		dx,0            ; Checks the sign of DX (high word of numerator)
		jl		ar2             ; Jumps if DX is Less than 0 (negative numerator)
		add		ax,si           ; AX = AX + diff_y/2 - adds rounding term
		adc		dx,0            ; DX:AX += diff_y/2 (handles carry)
		jmp		arc2            ; Jumps to arc2
ar2:		sub		ax,si           ; AX = AX - diff_y/2 - subtracts rounding term
		sbb		dx,0            ; DX:AX -= diff_y/2 (handles borrow)
arc2:
		idiv		word [diff_y]   ; AX = (DX:AX) / diff_y - calculates x increment
		mov		di,ax           ; DI = AX (current x increment)
		pop		ax          ; Restores x1
		add		di,ax           ; DI = DI + x1 - calculates current x
		pop		si          ; Restores current y
		push		di          ; Pushes current x
		push		si          ; Pushes current y
		call		plot_xy       ; Plots pixel at (current x, current y)
		pop		dx          ; Restores y2
		cmp		si,dx           ; Compares current y with y2
		je		fim_line        ; Jumps if current y is Equal to y2 (line end reached)
		inc		si          ; Increments current y
		jmp		line6           ; Jumps back to line6 for the next pixel

fim_line:
		pop		di          ; Restores the DI register
		pop		si          ; Restores the SI register
		pop		dx          ; Restores the DX register
		pop		cx          ; Restores the CX register
		pop		bx          ; Restores the BX register
		pop		ax          ; Restores the AX register
		popf                    ; Pops the flags register from the stack
		pop		bp          ; Restores the BP register
		ret		8             ; Returns from the procedure, clears 8 bytes from the stack (4 parameters: y2, x2, y1, x1 - 2 bytes each)

;-----------------------------------------------------------------------------
; Program termination
;-----------------------------------------------------------------------------
terminate_game:
    call clear_display
    mov     al, 03h
    int     10h

    mov     ah, 4Ch
    mov     al, 00h
    int     21h

segment stack stack
    resb 512
    stacktop: