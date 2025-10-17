;-----------------------------------------------------------------------------
; PONG Game in NASM Assembly
;-----------------------------------------------------------------------------

segment data
    ;-------------------------------------------------------------------------
    ; Game State Variables
    ;-------------------------------------------------------------------------
    time_aux                db  0       ; Auxiliary variable to control frame time based on system time
    computer_points         db  0       ; Stores the computer's score
    player_one_points      db  0       ; Stores player one's score
    current_speed_stage_index db 0      ; Index representing the current ball speed level (0, 1, or 2)

    ;-------------------------------------------------------------------------
    ; Powerup Variables
    ;-------------------------------------------------------------------------
    speed_boost_active      db  0       ; 0 = inactive, 1 = active
    speed_boost_timer       db  0       ; Timer for speed boost duration
    original_velocity_x     dw  0       ; Store original X velocity
    original_velocity_y     dw  0       ; Store original Y velocity
    boost_multiplier        dw  2       ; Speed multiplier during boost (2x speed)

    ;-------------------------------------------------------------------------
    ; User Interface (UI) Text Elements
    ;-------------------------------------------------------------------------
    header_line1           db  'Final Project for Computer Architecture', '$' ; Text for header line 1
    header_line2_prefix    db  'Group Shit:  ', '$'                                  ; Prefix for header line 2
    header_line2_score_separator db ' x ', '$'                                                 ; Separator between player and computer score in header line 2
    header_line2_computer_text db '  Computer -- Current speed: ', '$'                    ; Text indicating computer score and current speed
    header_line2_velocity_range db '(from 1 to 3)', '$'                                          ; Text indicating the speed range
    text_player_one_points db  '00', '$'                                                      ; Buffer to store player one's score as text
    text_computer_points   db  '00', '$'                                                      ; Buffer to store the computer's score as text
    ball_speed_text        db  '1', '$'     
    boost_active_msg      db  'SPEED BOOST ACTIVE!', '$'                                                  ; Buffer to store the current ball speed level as text

    ;-------------------------------------------------------------------------
    ; Ball Properties
    ;-------------------------------------------------------------------------
    ball_original_x        dw  127h    ; Initial X position of the ball (hexadecimal value)
    ball_original_y        dw  0D7h    ; Initial Y position of the ball (hexadecimal value)
    ball_x                dw  127h    ; Current X position of the ball (hexadecimal value)
    ball_y                dw  0D7h    ; Current Y position of the ball (hexadecimal value)
    ball_radius           dw  07h     ; Ball radius (hexadecimal value)
    ball_velocity_x       dw  00H     ; Current horizontal velocity of the ball (hexadecimal value, positive for right, negative for left)
    ball_velocity_y       dw  00h     ; Current vertical velocity of the ball (hexadecimal value, positive for down, negative for up)
    ball_speeds           dw  05h, 0Ah, 0Fh  ; Array of word values defining ball speeds for each speed level (hexadecimal values)
    num_speed_stages      equ 3       ; Number of available speed levels

    ;-------------------------------------------------------------------------
    ; Screen Dimensions and Margins
    ;-------------------------------------------------------------------------
    window_width dw 280h                       ; Screen width in pixels (640 pixels = 280h)
    window_height dw 1E0h                      ; Screen height in pixels (480 pixels = 1E0h)
    window_bounds dw 05h                       ; Boundary margin for collision detection (pixels)
    top_margin dw 032h                         ; Top margin for the game area (pixels)
    right_margin dw 05Ah                       ; Right margin for paddle positioning (pixels)

    ;-------------------------------------------------------------------------
    ; Paddle Properties
    ;-------------------------------------------------------------------------
    paddle_width dw 0AH                        ; Paddle width (pixels)
    paddle_height dw 032h                       ; Paddle height (pixels)

    ; Right Paddle Properties (Player Controlled)
    paddle_right_x dw 253h                     ; Initial X position of the right paddle (hexadecimal value)
    paddle_right_y dw 0D7h                      ; Initial Y position of the right paddle (hexadecimal value)

    ; Left Paddle Properties (Player 2 Controlled)
    paddle_left_x dw 28h                       ; Initial X position of the left paddle (hexadecimal value, near left margin)
    paddle_left_y dw 0D7h                      ; Initial Y position of the left paddle (hexadecimal value)

    ;-------------------------------------------------------------------------
    ; Paddle Movement Properties
    ;-------------------------------------------------------------------------
    paddle_velocity dw 0Ah                     ; Paddle movement speed (pixels per key press)

    ;-------------------------------------------------------------------------
    ; Color Definitions
    ;-------------------------------------------------------------------------
    cor		db		branco_intenso         ; Current drawing color, initialized to bright white

    ;	I R G B COLOR - Color bit representation
    ;	0 0 0 0 black          - Black
    ;	0 0 0 1 blue           - Blue
    ;	0 0 1 0 green          - Green
    ;	0 0 1 1 cyan           - Cyan
    ;	0 1 0 0 red            - Red
    ;	0 1 0 1 magenta        - Magenta
    ;	0 1 1 0 brown          - Brown
    ;	0 1 1 1 white          - White
    ;	1 0 0 0 gray           - Gray
    ;	1 0 0 1 light blue     - Light Blue
    ;	1 0 1 0 light green    - Light Green
    ;	1 0 1 1 light cyan     - Light Cyan
    ;	1 1 0 0 pink           - Pink
    ;	1 1 0 1 light magenta  - Light Magenta
    ;	1 1 1 0 yellow         - Yellow
    ;	1 1 1 1 bright white   - Bright White

    preto		equ		0
    azul		equ		1
    verde		equ		2
    cyan		equ		3
    vermelho	equ		4
    magenta		equ		5
    marrom		equ		6
    branco		equ		7
    cinza		equ		8
    azul_claro	equ		9
    verde_claro	equ		10
    cyan_claro	equ		11
    rosa		equ		12
    magenta_claro	equ		13
    amarelo		equ		14
    branco_intenso	equ		15

    ;-------------------------------------------------------------------------
    ; Variables for drawing and other purposes
    ;-------------------------------------------------------------------------
    linha   	dw  		0         ; General purpose variable for row coordinate
    coluna  	dw  		0         ; General purpose variable for column coordinate
    deltax		dw		0         ; General purpose variable to store delta X for line drawing
    deltay		dw		0         ; General purpose variable to store delta Y for line drawing

    ;-------------------------------------------------------------------------
    ; Debug Labels (Potentially for future debugging purposes)
    ;-------------------------------------------------------------------------
	ball_pos_label    db 'Ball: X,Y=', '$'   ; Label for debug output of ball position
    paddle_pos_label  db '  Paddle: Y=', '$' ; Label for debug output of paddle Y position

segment code
    ;-------------------------------------------------------------------------
    ; Procedure: initialize_ball_velocity
    ; Initializes the ball velocity based on the first speed level.
    ;-------------------------------------------------------------------------
initialize_ball_velocity:
		mov     si, 0000h             ; Initializes SI to 0, index for the first speed level
		lea     bx, [ball_speeds + si]  ; Loads the effective address of the first speed from 'ball_speeds' array into BX
		mov     ax, word [bx]         ; Moves the word value pointed to by BX (first speed value) into AX
		mov     word [ball_velocity_x], ax    ; Initializes the horizontal ball velocity with the loaded speed value
		neg     ax                    ; Negates the speed value for the opposite direction
        mov     word [ball_velocity_y], ax    ; Initializes the vertical ball velocity with the loaded speed value
		ret                             ; Returns from the procedure

;-----------------------------------------------------------------------------
; Debug Functions (commented out for release, can be uncommented for debug)
;-----------------------------------------------------------------------------
; print_positions:
;     pusha                       ; Saves all general-purpose registers onto the stack
;
;     ; Sets the cursor position for debug output (adjust row/column as needed)
;     mov     ah, 02H             ; BIOS function to SET CURSOR POSITION
;     mov     bh, 00H             ; Page number 0
;     mov     dh, 08H             ; Row number (8th row) for cursor position
;     mov     dl, 01H             ; Column number (1st column) for cursor position
;     int     10H                 ; Calls the BIOS video service
;
;     ; Prints the label "Ball: X,Y="
;     mov     ah, 09h             ; DOS function to WRITE STRING TO STANDARD OUTPUT
;     lea     dx, [ball_pos_label] ; Loads the effective address of 'ball_pos_label' into DX
;     int     21h                 ; Calls the DOS service to print the string
;
;     ; Prints the value of ball_x
;     mov     ax, word [ball_x]    ; Moves the word value of 'ball_x' into AX
;     call    print_number        ; Calls the 'print_number' procedure to print the number in AX
;     mov     al, ','             ; Moves the ASCII value of comma into AL
;     call    caracter            ; Calls the 'caracter' procedure to print the character in AL
;
;     ; Prints the value of ball_y
;     mov     ax, word [ball_y]    ; Moves the word value of 'ball_y' into AX
;     call    print_number        ; Calls the 'print_number' procedure to print the number in AX
;
;     ; Prints the label "  Paddle: Y="
;     mov     ah, 09h             ; DOS function to WRITE STRING TO STANDARD OUTPUT
;     lea     dx, [paddle_pos_label] ; Loads the effective address of 'paddle_pos_label' into DX
;     int     21h                 ; Calls the DOS service to print the string
;
;     ; Prints the value of paddle_right_y
;     mov     ax, word [paddle_right_y] ; Moves the word value of 'paddle_right_y' into AX
;     call    print_number        ; Calls the 'print_number' procedure to print the number in AX
;
;     popa                        ; Restores all general-purpose registers from the stack
;     ret                         ; Returns from the procedure
;
; ;-----------------------------------------------------------------------------
; ; Procedure: print_number
; ; Prints a number (AX) to the console.
; ;-----------------------------------------------------------------------------
; print_number:
;     push dx                     ; Saves the DX register onto the stack
;     push cx                     ; Saves the CX register onto the stack
;     push bx                     ; Saves the BX register onto the stack
;
;     mov cx, 0                   ; Initializes counter CX to 0 (digit count)
;     mov bx, 10                  ; Sets BX to 10, the base for decimal conversion
;
; convert_loop:                   ; Loop to convert number to digits
;     mov dx, 0                   ; Clears the DX register (for remainder)
;     div bx                      ; Divides AX by BX (10), quotient in AX, remainder in DX
;     push dx                     ; Pushes the remainder (digit) onto the stack
;     inc cx                      ; Increments the digit counter
;     test ax, ax                 ; Tests if the quotient AX is zero
;     jnz convert_loop            ; Jumps to 'convert_loop' if the quotient is not zero
;
; print_loop:                     ; Loop to print digits from the stack
;     pop dx                      ; Pops a digit (ASCII value) from the stack into DX
;     add dl, '0'                 ; Converts the digit value to ASCII character ('0'-'9')
;     mov ah, 02h                 ; DOS function to WRITE CHARACTER TO STANDARD OUTPUT
;     int 21h                     ; Calls the DOS service to print the character
;     loop print_loop             ; Loops 'cx' times to print all digits
;
;     pop bx                      ; Restores the BX register from the stack
;     pop cx                      ; Restores the CX register from the stack
;     pop dx                      ; Restores the DX register from the stack
;     ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Start of main program execution
;-----------------------------------------------------------------------------
..start:
    mov     ax, data            ; Moves the segment address of the 'data' segment into AX
    mov     ds, ax            ; Sets the Data Segment (DS) register to AX, making the data segment accessible
    mov     ax, stack           ; Moves the segment address of the 'stack' segment into AX
    mov     ss, ax            ; Sets the Stack Segment (SS) register to AX, making the stack segment accessible
    mov     sp, stacktop        ; Sets the Stack Pointer (SP) register to 'stacktop', initializing the stack

    call    clear_screen          ; Calls the 'clear_screen' procedure to clear the screen and set video mode
	call    initialize_ball_velocity ; Calls 'initialize_ball_velocity' to set the initial ball velocity

    ;-------------------------------------------------------------------------
    ; Main game loop - Synchronized with system time for frame rate control
    ;-------------------------------------------------------------------------
check_time:
    mov     ah, 2Ch             ; DOS interrupt function to GET SYSTEM TIME
    int     21h                 ; Calls the DOS interrupt
    cmp     dl, byte [time_aux] ; Compares the current hundredths (DL) with stored value
    je      check_boost_timer   ; If equal, check boost timer but don't update frame
    mov     byte [time_aux], dl ; Updates 'time_aux' with the new value
    
    ; Update game frame
    call    clear_screen        ; Clears the screen for the next frame
    call    move_ball           ; Updates the ball's position
    call    draw_ball           ; Draws the ball at its new position
    call    move_paddles        ; Processes paddle movement based on user input
    call    draw_paddles        ; Draws the paddles
    call    draw_ui             ; Draws the user interface elements (score, headers)
    call    update_boost_timer  ; Update boost timer

check_boost_timer:
    jmp     check_time          ; Jump back to check_time to repeat the game loop

;-----------------------------------------------------------------------------
; Procedure: update_boost_timer
; Updates the speed boost timer and deactivates boost when time expires.
;-----------------------------------------------------------------------------
update_boost_timer:
    ; Check if speed boost is active
    cmp     byte [speed_boost_active], 1
    jne     .exit_update_boost
    
    ; Decrement boost timer
    dec     byte [speed_boost_timer]
    jnz     .exit_update_boost
    
    ; Timer expired - restore original speed
    mov     ax, word [original_velocity_x]
    mov     word [ball_velocity_x], ax
    mov     ax, word [original_velocity_y]
    mov     word [ball_velocity_y], ax
    mov     byte [speed_boost_active], 0

.exit_update_boost:
    ret

;-----------------------------------------------------------------------------
; Procedure: draw_paddles
; Draws the right paddle on the screen.
;-----------------------------------------------------------------------------
draw_paddles:
    ; Draws the Left Paddle
    mov     cx, word [paddle_left_x]
    mov     dx, word [paddle_left_y]
draw_paddle_left_horizontal:
    mov     ah, 0Ch
    mov     al, 0Fh
    mov     bh, 00h
    int     10h
    inc     cx
    mov     ax, cx
    sub     ax, word [paddle_left_x]
    cmp     ax, word [paddle_width]
    jng     draw_paddle_left_horizontal
    mov     cx, word [paddle_left_x]
    inc     dx
    mov     ax, dx
    sub     ax, word [paddle_left_y]
    cmp     ax, word [paddle_height]
    jng     draw_paddle_left_horizontal

    ; Draws the Right Paddle
    mov     cx, word [paddle_right_x]
    mov     dx, word [paddle_right_y]
draw_paddle_right_horizontal:
    mov     ah, 0Ch
    mov     al, 0Fh
    mov     bh, 00h
    int     10h
    inc     cx
    mov     ax, cx
    sub     ax, word [paddle_right_x]
    cmp     ax, word [paddle_width]
    jng     draw_paddle_right_horizontal
    mov     cx, word [paddle_right_x]
    inc     dx
    mov     ax, dx
    sub     ax, word [paddle_right_y]
    cmp     ax, word [paddle_height]
    jng     draw_paddle_right_horizontal

    ret

;-----------------------------------------------------------------------------
; Procedure: draw_ball
; Draws the ball on the screen using the 'full_circle' procedure.
;-----------------------------------------------------------------------------
draw_ball:
    ; mov cx, word [ball_x]     ; (Not used - CX and DX are set by full_circle parameters)
    ; mov dx, word [ball_y]     ; (Not used - CX and DX are set by full_circle parameters)
    mov     byte [cor], vermelho ; Sets the drawing color to red (vermelho)
    mov     ax, word [ball_x]    ; Moves the ball's X coordinate into AX for 'full_circle' parameter
    push    ax              ; Pushes the X coordinate onto the stack
    mov     ax, word [ball_y]    ; Moves the ball's Y coordinate into AX for 'full_circle' parameter
    push    ax              ; Pushes the Y coordinate onto the stack
    mov     ax, word [ball_radius] ; Moves the ball's radius into AX for 'full_circle' parameter
    push    ax              ; Pushes the radius onto the stack
    call    full_circle         ; Calls the 'full_circle' procedure to draw a filled circle
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: move_ball
; Updates the ball's position, handles boundary collisions and paddle collisions.
;-----------------------------------------------------------------------------
move_ball:
    ; Horizontal movement
    mov     ax, word [ball_velocity_x] ; Gets the horizontal velocity of the ball
    add     word [ball_x], ax        ; Adds the velocity to the ball's X position

    ; Checks for collision with the paddle before boundary checks
    call    check_paddle_collision    ; Calls 'check_paddle_collision' to check if the ball hit the paddle

    ; Horizontal boundary checks
    mov     ax, word [ball_x]        ; Gets the current X position of the ball
    sub     ax, word [ball_radius]   ; Subtracts the ball's radius to get the left edge of the ball
    mov     bx, word [window_bounds] ; Gets the window boundary margin
    add     bx, word [window_bounds] ; Adds the window boundary margin to itself (effectively 2 * window_bounds)
    cmp     ax, bx              ; Compares the left edge with the boundary margin
    jl      near neg_velocity_x   ; If left edge is Less than the boundary, ball hit the left wall -> reverse X velocity

    mov     ax, word [ball_x]        ; Gets the current X position of the ball
    add     ax, word [ball_radius]   ; Adds the ball's radius to get the right edge of the ball
    mov     bx, word [window_width]  ; Gets the screen width
    sub     bx, word [window_bounds] ; Subtracts the boundary margin from the screen width
    cmp     ax, bx              ; Compares the right edge with the right boundary
    jg      near give_point_to_computer ; If right edge is Greater than the boundary, ball passed the right side -> computer gets a point.

    ; Vertical movement
    mov     ax, word [ball_velocity_y] ; Gets the vertical velocity of the ball
    add     word [ball_y], ax        ; Adds the velocity to the ball's Y position

    ; Vertical boundary checks
    mov     ax, word [ball_y]        ; Gets the current Y position of the ball
    sub     ax, word [ball_radius]   ; Subtracts the ball's radius to get the top edge of the ball

    mov     bx, word [top_margin]     ; Loads top_margin for the top boundary
    add     bx, word [window_bounds]    ; Adds window_bounds to top_margin (BX = top_margin + window_bounds)

    cmp     ax, bx              ; Compares the top edge with the top boundary
    jl      near neg_velocity_y   ; If top edge is Less than the top boundary, ball hit the top wall -> reverse Y velocity

    mov     ax, word [ball_y]        ; Gets the current Y position of the ball
    add     ax, word [ball_radius]   ; Adds the ball's radius to get the bottom edge of the ball
    mov     bx, word [window_height] ; Gets the screen height
    sub     bx, word [window_bounds]   ; Subtracts the boundary margin from the screen height
    sub     bx, word [window_bounds]   ; Subtracts the boundary margin again (effectively 2 * window_bounds from the bottom)

    cmp     ax, bx              ; Compares the bottom edge with the bottom boundary
    jg      near neg_velocity_y   ; If bottom edge is Greater than the bottom boundary, ball hit the bottom wall -> reverse Y velocity
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: check_paddle_collision
; Checks if the ball collided with the right paddle and determines the collision region.
;-----------------------------------------------------------------------------
check_paddle_collision:
    ; --- Left Paddle Collision Check (added for two-player) ---
    mov     ax, word [ball_x]        ; Left edge of the ball (ball_x - radius)
    sub     ax, word [ball_radius]
    mov     bx, word [paddle_left_x]
    add     bx, word [paddle_width]
    cmp     ax, bx
    jg      skip_left_paddle_collision
    mov     ax, word [ball_x]
    add     ax, word [ball_radius]
    cmp     ax, word [paddle_left_x]
    jl      skip_left_paddle_collision
    mov     ax, word [ball_y]
    add     ax, word [ball_radius]
    cmp     ax, word [paddle_left_y]
    jl      skip_left_paddle_collision
    mov     ax, word [ball_y]
    sub     ax, word [ball_radius]
    mov     bx, word [paddle_left_y]
    add     bx, word [paddle_height]
    cmp     ax, bx
    jg      skip_left_paddle_collision
    ; Collision with left paddle
    mov     ax, word [ball_y]
    mov     bx, word [paddle_left_y]
    add     bx, word [ball_radius]
    cmp     ax, bx
    jl      left_paddle_player_one_scores
    mov     bx, word [paddle_left_y]
    add     bx, word [paddle_height]
    sub     bx, word [ball_radius]
    cmp     ax, bx
    jg      left_paddle_player_one_scores
    ; Collision at the front of the left paddle (player two scores a point)
    call    give_point_to_player_two
    jmp     no_paddle_collision
left_paddle_player_one_scores:
    call    give_point_to_player_one
    jmp     no_paddle_collision
skip_left_paddle_collision:
    ; Checks horizontal collision with the paddle
    mov     ax, word [ball_x]        ; Right edge of the ball (ball_x + radius)
    add     ax, word [ball_radius]
    cmp     ax, word [paddle_right_x]
    jl      no_paddle_collision       ; No collision if the ball is to the left of the paddle

    mov     ax, word [ball_x]        ; Left edge of the ball (ball_x - radius)
    sub     ax, word [ball_radius]
    mov     bx, word [paddle_right_x]
    add     bx, word [paddle_width]
    cmp     ax, bx
    jg      no_paddle_collision       ; No collision if the ball is to the right of the paddle

    ; Checks vertical collision with the paddle
    mov     ax, word [ball_y]        ; Bottom edge of the ball (ball_y + radius)
    add     ax, word [ball_radius]
    cmp     ax, word [paddle_right_y]
    jl      no_paddle_collision       ; No collision if the ball is above the paddle

    mov     ax, word [ball_y]        ; Top edge of the ball (ball_y - radius)
    sub     ax, word [ball_radius]
    mov     bx, word [paddle_right_y]
    add     bx, word [paddle_height]
    cmp     ax, bx
    jg      no_paddle_collision       ; No collision if the ball is below the paddle

    ; Checks if the collision is at the top or bottom of the paddle
    mov     ax, word [ball_y]        ; Y position of the ball's center
    mov     bx, word [paddle_right_y]
    add     bx, word [ball_radius]   ; BX = top of the paddle + ball radius
    cmp     ax, bx
    jl      computer_scores          ; Collision at the top

    mov     bx, word [paddle_right_y]
    add     bx, word [paddle_height]
    sub     bx, word [ball_radius]   ; BX = bottom of the paddle - ball radius
    cmp     ax, bx
    jg      computer_scores          ; Collision at the bottom

    ; Collision at the front of the paddle (player scores a point)
    call    give_point_to_player_one
    jmp     no_paddle_collision

; Player two (left paddle) scores routine
give_point_to_player_two:
    neg     word [ball_velocity_x]
    ; You may want to add a player two score variable and update display here
    ret

computer_scores:
    ; Collision at the top or bottom (computer scores a point)
    call    give_point_to_computer

no_paddle_collision:
    ret                        ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: give_point_to_player_one
; In this version, it is used to reverse the ball's direction after paddle collision.
;-----------------------------------------------------------------------------
give_point_to_player_one:
    neg     word [ball_velocity_x] ; Reverses the horizontal velocity of the ball
    inc     byte [player_one_points] ; Increments player one's score
    call    update_player_one_points  ; Calls 'update_player_one_points' to update the score display
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: give_point_to_computer
; In this version, resets the ball's position and reverses the ball's direction.
;-----------------------------------------------------------------------------
give_point_to_computer:
    inc     byte [computer_points] ; Increments the computer's score
    neg     word [ball_velocity_x] ; Reverses the horizontal velocity of the ball

    call    reset_ball_position   ; Calls 'reset_ball_position' to reset the ball to the initial position
    call    update_computer_points    ; Calls 'update_computer_points' to update the score display
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: game_over
; Resets the game scores (not actually used in game over logic in this version).
;-----------------------------------------------------------------------------
game_over:
    mov     byte [player_one_points], 00H ; Resets player one's score to 0
    mov     byte [computer_points], 00H ; Resets the computer's score to 0
    call    update_player_one_points  ; Updates player one's score display
    call    update_computer_points    ; Updates the computer's score display
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: neg_velocity_y
; Reverses the vertical velocity of the ball.
;-----------------------------------------------------------------------------
neg_velocity_y:
    neg     word [ball_velocity_y] ; Negates (reverses) the vertical velocity
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: neg_velocity_x
; Reverses the horizontal velocity of the ball.
;-----------------------------------------------------------------------------
neg_velocity_x:
    neg     word [ball_velocity_x] ; Negates (reverses) the horizontal velocity
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: exit_collision_paddle (empty procedure - placeholder)
;-----------------------------------------------------------------------------
exit_collision_paddle:
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: move_paddles
; Handles paddle movement based on keyboard input.
;-----------------------------------------------------------------------------
move_paddles:
    ; Checks for keyboard input
    mov     ah, 01h                 ; BIOS function to CHECK KEYBOARD STATUS
    int     16h                 ; Calls the BIOS keyboard service
    jz      near exit_paddle_mov      ; Jumps to 'exit_paddle_mov' if Zero Flag is set (no key pressed)
    mov     ah, 00h                 ; BIOS function to GET KEY PRESSED
    int     16h                 ; Calls the BIOS keyboard service to read the pressed key (AL=ASCII, AH=Scan Code)
    jmp     check_key           ; Jumps to 'check_key' to process the pressed key

;-----------------------------------------------------------------------------
; Label: check_key
; Checks the pressed key and performs corresponding paddle actions.
;-----------------------------------------------------------------------------
check_key:

    ; Checks if 'x' or 'X' key was pressed to exit the game
    cmp     al, 78h ; 'x'
    je      near exit_game
    cmp     al, 58h ; 'X'
    je      near exit_game

    ; Left Paddle Controls (W/S for up/down)
    cmp     al, 77h ; 'w'
    je      move_left_paddle_up
    cmp     al, 57h ; 'W'
    je      move_left_paddle_up
    cmp     al, 73h ; 's'
    je      move_left_paddle_down
    cmp     al, 83h ; 'S'
    je      move_left_paddle_down

    ; Right Paddle Controls (Up/Down/Left/Right arrows)
    cmp     ah, 48h         ; Up arrow scan code
    je      move_right_paddle_up
    cmp     ah, 50h         ; Down arrow scan code
    je      move_right_paddle_down  
    cmp     ah, 4Bh         ; Left arrow scan code
    je      move_right_paddle_left
    cmp     ah, 4Dh         ; Right arrow scan code
    je      near activate_speed_boost  ; Right arrow now activates speed boost

    jmp     exit_paddle_mov

; Left paddle movement routines
move_left_paddle_up:
    mov     ax, word [paddle_velocity]
    sub     word [paddle_left_y], ax
    mov     bx, word [top_margin]
    cmp     word [paddle_left_y], bx
    jl      fix_paddle_left_top_position
    jmp     exit_paddle_mov
fix_paddle_left_top_position:
    mov     word [paddle_left_y], bx
    jmp     exit_paddle_mov

move_left_paddle_down:
    mov     ax, word [paddle_velocity]
    add     word [paddle_left_y], ax
    mov     ax, word [window_height]
    sub     ax, word [window_bounds]
    sub     ax, word [paddle_height]
    cmp     word [paddle_left_y], ax
    jg      fix_paddle_left_bottom_position
    jmp     exit_paddle_mov
fix_paddle_left_bottom_position:
    mov     word [paddle_left_y], ax
    jmp     exit_paddle_mov

;-----------------------------------------------------------------------------
; Procedure: move_right_paddle_up
; Moves the right paddle up, with boundary checking.
;-----------------------------------------------------------------------------
move_right_paddle_up:
    mov     ax, word [paddle_velocity] ; Gets the paddle velocity
    sub     word [paddle_right_y], ax ; Subtracts the velocity from the paddle's Y position (moves up)

	mov		bx, word [top_margin]   ; Loads the top margin
    cmp     word [paddle_right_y], bx ; Compares the paddle's Y position with the top margin

    jl      fix_paddle_right_top_position ; Jumps if paddle's Y position is Less than the top margin (out of bounds)
    jmp     exit_paddle_mov       ; Otherwise, exits paddle movement handling

fix_paddle_right_top_position:
    mov     word [paddle_right_y], bx ; Corrects the paddle's Y position to the top margin (prevents going out of bounds)
    jmp     exit_paddle_mov       ; Exits paddle movement handling

;-----------------------------------------------------------------------------
; Procedure: move_right_paddle_down
; Moves the right paddle down, with boundary checking.
;-----------------------------------------------------------------------------
move_right_paddle_down:
    mov     ax, word [paddle_velocity] ; Gets the paddle velocity
    add     word [paddle_right_y], ax ; Adds the velocity to the paddle's Y position (moves down)

    mov     ax, word [window_height] ; Gets the screen height
    sub     ax, word [window_bounds] ; Subtracts the window boundary
    sub     ax, word [paddle_height] ; Subtracts the paddle height to get the bottom boundary for the paddle

    cmp     word [paddle_right_y], ax ; Compares the paddle's Y position with the bottom boundary
    jg      fix_paddle_right_bottom_position ; Jumps if paddle's Y position is Greater than the bottom boundary (out of bounds)

    jmp     exit_paddle_mov       ; Otherwise, exits paddle movement handling

fix_paddle_right_bottom_position:
    mov     word [paddle_right_y], ax ; Corrects the paddle's Y position to the bottom boundary (prevents going out of bounds)
    jmp     exit_paddle_mov       ; Exits paddle movement handling

;-----------------------------------------------------------------------------
; Procedure: move_right_paddle_left
;-----------------------------------------------------------------------------
move_right_paddle_left:
    mov     ax, word [paddle_velocity]
    sub     word [paddle_right_x], ax

    mov     ax, word [window_width]
    sub     ax, word [right_margin]

    cmp     word [paddle_right_x], ax
    jl      fix_paddle_right_left_position
    jmp     exit_paddle_mov

fix_paddle_right_left_position:
    mov     word [paddle_right_x], ax
    jmp     exit_paddle_mov

;-----------------------------------------------------------------------------
; Procedure: move_right_paddle_right
;-----------------------------------------------------------------------------
move_right_paddle_right:
    mov     ax, word [paddle_velocity]
    add     word [paddle_right_x], ax

    mov     ax, word [window_width]
    sub     ax, word [window_bounds]
    sub     ax, word [paddle_width]

    cmp     word [paddle_right_x], ax
    jg      fix_paddle_right_right_position
    jmp     exit_paddle_mov

fix_paddle_right_right_position:
    mov     word [paddle_right_x], ax
    jmp     exit_paddle_mov

;-----------------------------------------------------------------------------
; Label: exit_paddle_mov
; Label to exit paddle movement handling.
;-----------------------------------------------------------------------------
exit_paddle_mov:
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: activate_speed_boost
; Activates a temporary speed boost for 2 seconds when right arrow key is pressed.
;-----------------------------------------------------------------------------
activate_speed_boost:
    cmp     byte [speed_boost_active], 1
    je      exit_speed_boost           ; If boost already active, do nothing
    
    ; Store original velocities
    mov     ax, word [ball_velocity_x]
    mov     word [original_velocity_x], ax
    mov     ax, word [ball_velocity_y]
    mov     word [original_velocity_y], ax
    
    ; Apply speed boost (double the speed)
    mov     ax, word [ball_velocity_x]
    sal     ax, 1                      ; Multiply by 2 (shift left)
    mov     word [ball_velocity_x], ax
    
    mov     ax, word [ball_velocity_y]
    sal     ax, 1                      ; Multiply by 2 (shift left)
    mov     word [ball_velocity_y], ax
    
    ; Activate boost and set timer
    mov     byte [speed_boost_active], 1
    mov     byte [speed_boost_timer], 36  ; ~2 seconds at 18.2 ticks/sec
    
    jmp     exit_speed_boost

exit_speed_boost:
    ret


;-----------------------------------------------------------------------------
; Procedure: set_ball_speed_from_stage
; Sets the ball speed based on the current speed level index.
;-----------------------------------------------------------------------------
set_ball_speed_from_stage:
    mov     bl, byte [current_speed_stage_index] ; Gets the current speed level index
    mov     bh, 00h                             ; Clears BH for word offset calculation
    mov     si, bx                              ; Moves the index to SI
    sal     si, 1                               ; Multiplies the index by 2 to get the word offset in 'ball_speeds' array
    lea     bx, [ball_speeds + si]              ; Loads the effective address of the selected speed value into BX

    mov     ax, word [bx]                       ; Loads the new speed value from memory into AX

    ; Preserves X direction
    mov     bx, word [ball_velocity_x]          ; Gets the current horizontal velocity
    or      bx, bx                              ; Tests if the current X velocity is negative (OR with itself, SF will be set if negative)
    jns     .check_y                            ; Jumps if Not Signed (positive or zero), no need to negate
    neg     ax                                  ; Negates the new speed value if the current X velocity is negative
.check_y:
    mov     word [ball_velocity_x], ax          ; Sets the new horizontal velocity

    ; Gets the new base speed again for Y velocity (reloads from array)
    mov     bl, byte [current_speed_stage_index] ; Gets the current level index again
    mov     bh, 00h
    mov     si, bx
    sal     si, 1
    lea     bx, [ball_speeds + si]
    mov     ax, word [bx]

    ; Preserves Y direction
    mov     bx, word [ball_velocity_y]          ; Gets the current vertical velocity
    or      bx, bx                              ; Tests if the current Y velocity is negative
    jns     .finish                             ; Jumps if Not Signed (positive or zero), no need to negate
    neg     ax                                  ; Negates the new speed value if the current Y velocity is negative
.finish:
    mov     word [ball_velocity_y], ax          ; Sets the new vertical velocity

    ; Updates the speed display in the UI
    mov     al, byte [current_speed_stage_index] ; Gets the current speed level index
    inc     al                                  ; Converts to base 1 for display (levels are 1, 2, 3 not 0, 1, 2)
    add     al, 30h                            ; Converts to ASCII character ('1', '2' or '3')
    mov     byte [ball_speed_text], al          ; Updates the speed text in the data segment

    jmp     exit_speed            ; Exits speed adjustment

;-----------------------------------------------------------------------------
; Label: exit_speed
; Label to exit speed adjustment procedures.
;-----------------------------------------------------------------------------
exit_speed:
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: reset_ball_position
; Resets the ball to its original starting position.
;-----------------------------------------------------------------------------
reset_ball_position:
    mov     ax, word [ball_original_x] ; Gets the original X position
    mov     word [ball_x], ax        ; Sets the current ball X position to the original X position
    mov     ax, word [ball_original_y] ; Gets the original Y position
    mov     word [ball_y], ax        ; Sets the current ball Y position to the original Y position
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: draw_ui
; Draws the user interface elements (headers, scores, speed display).
;-----------------------------------------------------------------------------
draw_ui:
    ; --- Clears the UI Area (Optional, but recommended - adjust coordinates as needed) ---
    ; You might want to clear the area where the UI is drawn to prevent text overlapping
    ; This would involve drawing a filled rectangle in the background color (black)
    ; For simplicity, we'll skip explicit clearing for now, but consider adding it if needed.

    ; --- Header Line 1 ---
    mov     ah, 02H             ; BIOS function to SET CURSOR POSITION
    mov     bh, 00H             ; Page number 0
    mov     dh, 01H             ; Row number 1 (first line)
    mov     dl, 06H             ; Column number 6 (horizontal position)
    int     10H             ; Calls the BIOS video service

    mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    lea     dx, [header_line1]  ; Loads the effective address of 'header_line1' into DX
    int     21H             ; Calls the DOS service to print the string

    ; --- Header Line 2 - Part 1 (Name Prefix) ---
    mov     ah, 02H             ; BIOS function to SET CURSOR POSITION
    mov     bh, 00H             ; Page number 0
    mov     dh, 02H             ; Row number 2 (second line)
    mov     dl, 06H             ; Column number 6
    int     10H             ; Calls the BIOS video service

    mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    lea     dx, [header_line2_prefix] ; Loads the effective address of 'header_line2_prefix' into DX
    int     21H             ; Calls the DOS service to print the string

    ; --- Header Line 2 - Player 1 Score ---
    mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    lea     dx, [text_player_one_points] ; Loads the effective address of 'text_player_one_points' into DX
    int     21H             ; Calls the DOS service to print the string

    ; --- Header Line 2 - Score Separator " x " ---
    mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    lea     dx, [header_line2_score_separator] ; Loads the effective address of 'header_line2_score_separator' into DX
    int     21H             ; Calls the DOS service to print the string

    ; --- Header Line 2 - Computer Score ---
    mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    lea     dx, [text_computer_points] ; Loads the effective address of 'text_computer_points' into DX
    int     21H             ; Calls the DOS service to print the string

    ; --- Header Line 2 - Computer Text " Computer Current speed: " ---
    mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    lea     dx, [header_line2_computer_text] ; Loads the effective address of 'header_line2_computer_text' into DX
    int     21H             ; Calls the DOS service to print the string

    ; --- Header Line 2 - Ball Speed Level (Number) ---
    mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    lea     dx, [ball_speed_text]  ; Loads the effective address of 'ball_speed_text' into DX
    int     21H             ; Calls the DOS service to print the string

    ; --- Header Line 2 - Speed Range "(from 1 to 3)" - Optional ---
    ; mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    ; lea     dx, [header_line2_velocity_range] ; Loads the effective address of 'header_line2_velocity_range' into DX
    ; int     21H                 ; Calls the DOS service to print the string - Uncomment if you want to show the range

        ; --- Speed Boost Indicator ---
    cmp     byte [speed_boost_active], 1
    jne     no_boost_indicator
    
    mov     ah, 02H             ; BIOS function to SET CURSOR POSITION
    mov     bh, 00H             ; Page number 0
    mov     dh, 03H             ; Row number 3
    mov     dl, 06H             ; Column number 6
    int     10H                 ; Calls the BIOS video service
    
    mov     ah, 09H             ; DOS function to WRITE STRING TO STANDARD OUTPUT
    lea     dx, [boost_active_msg] ; Load message address
    int     21H                 ; Calls the DOS service to print the string

no_boost_indicator:

	mov		byte[cor],branco_intenso	; Sets the color to bright white for antennas
	mov		ax,0
	push		ax
	mov		ax,49
	push		ax
	mov		ax,639
	push		ax
	mov		ax,49
	push		ax
	call		line                ; Calls the 'line' procedure to draw a horizontal line (antennas - visual element)
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: update_player_one_points
; Updates the displayed score of player one.
;-----------------------------------------------------------------------------
update_player_one_points:
    mov al, byte [player_one_points]  ; Gets the player's score from memory
    lea si, [text_player_one_points]  ; Loads the effective address of player 1's score text buffer into SI
    call convert_score_to_ascii_2_digits ; Calls 'convert_score_to_ascii_2_digits' to convert the score to 2-digit ASCII
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: update_computer_points
; Updates the displayed score of the computer.
;-----------------------------------------------------------------------------
update_computer_points:
    mov al, byte [computer_points]  ; Gets the computer's score from memory
    lea si,  [text_computer_points]    ; Loads the effective address of the computer's score text buffer into SI
    call convert_score_to_ascii_2_digits ; Calls 'convert_score_to_ascii_2_digits' to convert the score to 2-digit ASCII
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: convert_score_to_ascii_2_digits
; Converts a score (0-99) in AL to a 2-digit ASCII string.
; Stores the result in the buffer pointed to by SI.
;-----------------------------------------------------------------------------
convert_score_to_ascii_2_digits:
    ; Input: AL = score (0-99)
    ;       SI = pointer to the score text buffer (text_player_one_points or text_computer_points)
    ; Output: ASCII digits written to the buffer pointed to by SI

    push bx                     ; Saves the BX register
    push cx                     ; Saves the CX register
    push dx                     ; Saves the DX register

    mov ah, 0                   ; Prepares AX for division (AH = 0 for word division with byte divisor)
    mov bl, 10                  ; Divisor = 10 (for decimal conversion)

    div bl                      ; Divides AX by BL: AL = quotient (tens digit), AH = remainder (units digit)

    ; Converts the units digit to ASCII and stores it
    add ah, 30h               ; Converts the remainder (units digit 0-9) to ASCII character ('0'-'9')
    mov byte [si+1], ah         ; Stores the units digit (second character) in the buffer

    ; Converts the tens digit to ASCII and stores it
    add al, 30h               ; Converts the quotient (tens digit 0-9) to ASCII character ('0'-'9')
    mov byte [si], al          ; Stores the tens digit (first character) in the buffer

    pop dx                      ; Restores the DX register
    pop cx                      ; Restores the CX register
    pop bx                      ; Restores the BX register
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: clear_screen
; Clears the screen and sets the video mode to 640x480 16 colors.
;-----------------------------------------------------------------------------
clear_screen:
    mov     ah, 0               ; BIOS function to SET VIDEO MODE
    mov     al, 12h             ; Video mode 12h: 640x480 16 colors
    int     10h                 ; Calls the BIOS video service to set the video mode

    mov     ah, 0Bh             ; BIOS function to SET BACKGROUND COLOR
    mov     bh, 00h             ; Page number 0
    mov     bl, 00h             ; Background color: Black (00h)
    int     10h                 ; Calls the BIOS video service to set the background color
    ret                         ; Returns from the procedure

;-----------------------------------------------------------------------------
; Procedure: caracter
; Writes a character (AL) at the current cursor position with the current color.
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
   		mov     	bl,[cor]      ; Attribute (color) for the character, gets from 'cor' variable
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

;-----------------------------------------------------------------------------
; Procedure: plot_xy
; Draws a pixel at coordinates (X, Y) with the current color.
; Parameters are passed on the stack: Y then X.
;-----------------------------------------------------------------------------
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
	    mov     	al,[cor]      ; Pixel color, gets from 'cor' variable
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

;-----------------------------------------------------------------------------
; Procedure: circle
; Draws the outline of a circle using Bresenham's circle algorithm.
; Parameters are passed on the stack: radius, center Y, center X.
;-----------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------
; Procedure: full_circle
; Draws a filled circle using Bresenham's circle algorithm and horizontal lines.
; Parameters are passed on the stack: radius, center Y, center X.
;-----------------------------------------------------------------------------
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

;-----------------------------------------------------------------------------
; Procedure: line
; Draws a line between two points (x1, y1) and (x2, y2) using Bresenham's line algorithm.
; Parameters are passed on the stack: y2, x2, y1, x1.
;-----------------------------------------------------------------------------
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
line2:		                                 ; deltax=0 - Vertical line case
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

;deltax <>0 - Non-vertical line case
line1:
; Compares absolute values of deltax and deltay knowing that cx > ax (x2 > x1)
	; cx > ax (x2 > x1)
		push		cx          ; Saves x2
		sub		cx,ax           ; cx = x2 - x1 (deltax)
		mov		[deltax],cx     ; Stores deltax in memory
		pop		cx          ; Restores x2
		push		dx          ; Saves y2
		sub		dx,bx           ; dx = y2 - y1 (deltay)
		ja		line32          ; Jumps if y2 is Above y1 (y2 > y1)
		neg		dx          ; Negates deltay if y2 <= y1 (makes it positive for algorithm)
line32:
		mov		[deltay],dx     ; Stores deltay in memory
		pop		dx          ; Restores y2

		push		ax          ; Saves x1
		mov		ax,[deltax]     ; Gets deltax
		cmp		ax,[deltay]     ; Compares deltax and deltay
		pop		ax          ; Restores x1
		jb		line5           ; Jumps if deltax is Below deltay (more vertical line)

	; cx > ax and deltax>deltay - Mostly horizontal line
		push		cx          ; Saves x2
		sub		cx,ax           ; cx = x2 - x1 (deltax)
		mov		[deltax],cx     ; Stores deltax in memory
		pop		cx          ; Restores x2
		push		dx          ; Saves y2
		sub		dx,bx           ; dx = y2 - y1 (deltay)
		mov		[deltay],dx     ; Stores deltay in memory
		pop		dx          ; Restores y2

		mov		si,ax           ; SI = x1 (current x)
line4:
		push		ax          ; Saves x1
		push		dx          ; Saves y2
		push		si          ; Saves current x
		sub		si,ax	         ; si = current x - x1
		mov		ax,[deltay]     ; Gets deltay
		imul		si          ; AX:DX = deltay * (current x - x1) - numerator
		mov		si,[deltax]		     ; Gets deltax
		shr		si,1            ; si = deltax / 2 - rounding term
; if numerator (DX)>0 add if <0 subtract - rounding logic
		cmp		dx,0            ; Checks the sign of DX (high word of numerator)
		jl		ar1             ; Jumps if DX is Less than 0 (negative numerator)
		add		ax,si           ; AX = AX + deltax/2 - adds rounding term
		adc		dx,0            ; DX:AX += deltax/2 (handles carry)
		jmp		arc1            ; Jumps to arc1
ar1:		sub		ax,si           ; AX = AX - deltax/2 - subtracts rounding term
		sbb		dx,0            ; DX:AX -= deltax/2 (handles borrow)
arc1:
		idiv		word [deltax]   ; AX = (DX:AX) / deltax - calculates y increment
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
		sub		cx,ax           ; cx = x2 - x1 (deltax)
		mov		[deltax],cx     ; Stores deltax in memory
		pop		cx          ; Restores x2
		push		dx          ; Saves y2
		sub		dx,bx           ; dx = y2 - y1 (deltay)
		mov		[deltay],dx     ; Stores deltay in memory
		pop		dx          ; Restores y2

		mov		si,bx           ; SI = y1 (current y)
line6:
		push		dx          ; Saves y2
		push		si          ; Saves current y
		push		ax          ; Saves x1
		sub		si,bx	         ; si = current y - y1
		mov		ax,[deltax]     ; Gets deltax
		imul		si          ; AX:DX = deltax * (current y - y1) - numerator
		mov		si,[deltay]		     ; Gets deltay
		shr		si,1            ; si = deltay / 2 - rounding term
; if numerator (DX)>0 add if <0 subtract - rounding logic
		cmp		dx,0            ; Checks the sign of DX (high word of numerator)
		jl		ar2             ; Jumps if DX is Less than 0 (negative numerator)
		add		ax,si           ; AX = AX + deltay/2 - adds rounding term
		adc		dx,0            ; DX:AX += deltay/2 (handles carry)
		jmp		arc2            ; Jumps to arc2
ar2:		sub		ax,si           ; AX = AX - deltay/2 - subtracts rounding term
		sbb		dx,0            ; DX:AX -= deltay/2 (handles borrow)
arc2:
		idiv		word [deltay]   ; AX = (DX:AX) / deltay - calculates x increment
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
; Procedure: exit_game
; Restores text mode and exits the program.
;-----------------------------------------------------------------------------
exit_game:
    call clear_screen         ; Calls 'clear_screen' to clear the screen from graphics mode
    mov     al, 03h            ; Video mode 03h: 80x25 text mode, 16 colors
    int     10h                ; BIOS function to SET VIDEO MODE, restores text mode

    mov     ah, 4Ch            ; DOS function to TERMINATE PROGRAM
    mov     al, 00h            ; Exit code 0 (successful termination)
    int     21h                ; Calls the DOS service to terminate the program

segment stack stack
    resb 512                          ; Reserves 512 bytes for stack space
    stacktop:                          ; Label marking the top of the stack