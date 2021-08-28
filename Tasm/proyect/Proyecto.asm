title "Proyecto: Pong" ; titulo del programa
	.model small	;directiva de modelo de memoria, small => 64KB para memoria de programa y 64KB para memoria de datos
	.386			;directiva para indicar version del procesador
	.stack 64 		;Define el tamano del segmento de stack, se mide en bytes
	.data			;Definicion del segmento de datos
;---------------------------Definición de constantes---------------------------;
;Valor ASCII de caracteres para el marco del programa
marcoEsqInfIzq 		equ 	200d 	;'╚'
marcoEsqInfDer 		equ 	188d	;'╝'
marcoEsqSupDer 		equ 	187d	;'╗'
marcoEsqSupIzq 		equ 	201d 	;'╔'
marcoCruceVerSup	equ		203d	;'╦'
marcoCruceHorDer	equ 	185d 	;'╣'
marcoCruceVerInf	equ		202d	;'╩'
marcoCruceHorIzq	equ 	204d 	;'╠'
marcoCruce 			  equ		206d	;'╬'
marcoHor 			    equ 	205d 	;'═'
marcoVer 			    equ 	186d 	;'║'
;Atributos de color de BIOS
;Valores de color para carácter
cNegro 			  equ		00h
cAzul 			  equ		01h
cVerde 			  equ 	02h
cCyan 			  equ 	03h
cRojo 			  equ 	04h
cMagenta 		  equ		05h
cCafe 			  equ 	06h
cGrisClaro		equ		07h
cGrisOscuro		equ		08h
cAzulClaro		equ		09h
cVerdeClaro		equ		0Ah
cCyanClaro		equ		0Bh
cRojoClaro		equ		0Ch
cMagentaClaro	equ		0Dh
cAmarillo 		equ		0Eh
cBlanco 		  equ		0Fh
;Valores de color para fondo de carácter
bgNegro 		    equ		00h
bgAzul 			    equ		10h
bgVerde 		    equ 	20h
bgCyan 			    equ 	30h
bgRojo 			    equ 	40h
bgMagenta 		  equ		50h
bgCafe 			    equ 	60h
bgGrisClaro		  equ		70h
bgGrisOscuro	  equ		80h
bgAzulClaro		  equ		90h
bgVerdeClaro	  equ		0A0h
bgCyanClaro	  	equ		0B0h
bgRojoClaro		  equ		0C0h
bgMagentaClaro	equ		0D0h
bgAmarillo 	  	equ		0E0h
bgBlanco 	  	  equ		0F0h

;---------------------------Definicion de variables---------------------------;
; textos in game
titulo 		   	db 		"PONG"
player1 		  db 		"Player 1"
player2 		  db 		"Player 2"
tiempo_cadena	db 		"0:00"
tiempo_s 		  dw 		0	;  2184 es el valor de dos minutos para los 18.2 ticks del procesador
fps 					db 		0 ;  variable que define la cantidad de cuadros por segundo
											;  el juego se ejecuta a 100FPS
; puntajes
p1_score 	   	db 		0
p2_score	   	db 		0

; Ganando player1
wp1 db "Gana player1"
; Ganando player2
wp2 db "Gana player2"

; Variables para el tiempo
pazos64 		db		0   ; cantidad de pasos del juego para dividir los ticks
; es la suma de los puntos decimales de los 18.2 ticks
; cada 5 se vuelve un entero y se suma al t_inicial (tick_inicial)
t_inicial		db 		12h	; guarda números de ticks inicial (12h = 18d)
; para 1 segundo ingame son 18.2 ticks
; por eso se utiliza la var de arriba y volverlo 13 para compensar lo perdido

in_game db 0 ; Bandera de comprobacion de que el juego esta en ejecución
ia db 0 ; Bandera de modo de juego
; 0 = dos jugadores
; 1 = un jugador

					; Variable para controlar ciclos de valores mayores a 10
pila db 0 ; cuenta los datos ingresados en la pila

; borrar linea de jugador anterior
movimiento_j db 0   ;opcion de impresion de caracter vacio
; 1 sube por lo tanto borra abajo
; 2 baja por lo tanto borra arriba

;--------------------------- posiciones ---------------------------;
; posiciones de la bola
dragon_ball_col db 40
dragon_ball_ren db 14
;variables para guardar la posición del player 1
p1_col			db 		6	 ; x
p1_ren			db 		14 ; y
;variables para guardar la posición del player 2
p2_col 			db 		73 ; x
p2_ren 			db 		14 ; y

; booleanos de la bola "boola"
bola_sube 		db 1 ; 1 sube, 0 baja
bola_derecha 	db 1 ; 1 derecha, 0 izquierda

;variables para guardar una posición auxiliar
;sirven como variables globales para algunos procedimientos
col_aux 		db 		0
ren_aux 		db 		0
;variable que se utiliza como valor 10 auxiliar en divisiones
diez 			  dw 		10
diez_b			db    10 ; utilizado para ciertas comprobaciones con medios registros

;Una variable contador para algunos loops
conta 			db 		0
;Variables que sirven de parametros para el procedimiento IMPRIME_BOTON
boton_caracter 	db 		0
boton_renglon 	db 		0
boton_columna 	db 		0
boton_color		  db 		0
boton_bg_color	db 		0
;Auxiliar para calculo de coordenadas del mouse
ocho		    db 		8
;Cuando el driver del mouse no esta disponible
no_mouse		db 	'No se encuentra driver de mouse. Presione [enter] para salir$'

;--------------------------- Macros ---------------------------;
;clear - Limpia pantalla
clear macro
	mov ax,0003h 	;ah = 00h, selecciona modo video
					;al = 03h. Modo texto, 16 colores
	int 10h		;llama interrupcion 10h con opcion 00h.
				;Establece modo de video limpiando pantalla
endm

;posiciona_cursor - Cambia la posición del cursor a la especificada con 'renglon' y 'columna'
posiciona_cursor macro renglon,columna
	mov dh,renglon	;dh = renglon
	mov dl,columna	;dl = columna
	mov bx,0
	mov ax,0200h 	;preparar ax para interrupcion, opcion 02h
	int 10h 		;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm

;inicializa_ds_es - Inicializa el valor del registro DS y ES
inicializa_ds_es 	macro
	mov ax,@data
	mov ds,ax
	mov es,ax 		;Este registro se va a usar, junto con BP, para imprimir cadenas utilizando interrupción 10h
endm

;muestra_cursor_mouse - Establece la visibilidad del cursor del mouse
muestra_cursor_mouse	macro
	mov ax,1		;opcion 0001h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm

;oculta_cursor_teclado - Oculta la visibilidad del cursor del teclado
oculta_cursor_teclado	macro
	mov ah,01h 		;Opcion 01h
	mov cx,2607h 	;Parametro necesario para ocultar cursor
	int 10h 		;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;apaga_cursor_parpadeo - Deshabilita el parpadeo del cursor cuando se imprimen caracteres con fondo de color
;Habilita 16 colores de fondo
apaga_cursor_parpadeo	macro
	mov ax,1003h 		;Opcion 1003h
	xor bl,bl 			;BL = 0, parámetro para int 10h opción 1003h
  	int 10h 			;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'.
;Los colores disponibles están en la lista a continuacion;
; Colores:
; 0h: Negro
; 1h: Azul
; 2h: Verde
; 3h: Cyan
; 4h: Rojo
; 5h: Magenta
; 6h: Cafe
; 7h: Gris Claro
; 8h: Gris Oscuro
; 9h: Azul Claro
; Ah: Verde Claro
; Bh: Cyan Claro
; Ch: Rojo Claro
; Dh: Magenta Claro
; Eh: Amarillo
; Fh: Blanco
; utiliza int 10h opcion 09h
; 'caracter' - caracter que se va a imprimir
; 'color' - color que tomará el caracter
; 'bg_color' - color de fondo para el carácter en la celda
; Cuando se define el color del carácter, éste se hace en el registro BL:
; La parte baja de BL (los 4 bits menos significativos) define el color del carácter
; La parte alta de BL (los 4 bits más significativos) define el color de fondo "background" del carácter
imprime_caracter_color macro caracter,color,bg_color
	mov ah,09h				;preparar AH para interrupcion, opcion 09h
	mov al,caracter 		;AL = caracter a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos
							;'bg_color' define los 4 bits más significativos
	mov cx,1				;CX = numero de veces que se imprime el caracter
							;CX es un argumento necesario para opcion 09h de int 10h
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;imprime_caracter_color - Imprime un caracter de cierto color en pantalla, especificado por 'caracter', 'color' y 'bg_color'.
; utiliza int 10h opcion 09h
; 'cadena' - nombre de la cadena en memoria que se va a imprimir
; 'long_cadena' - longitud (en caracteres) de la cadena a imprimir
; 'color' - color que tomarán los caracteres de la cadena
; 'bg_color' - color de fondo para los caracteres en la cadena
imprime_cadena_color macro cadena,long_cadena,color,bg_color
	mov ah,13h				;preparar AH para interrupcion, opcion 13h
	lea bp,cadena 			;BP como apuntador a la cadena a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos
							;'bg_color' define los 4 bits más significativos
	mov cx,long_cadena		;CX = longitud de la cadena, se tomarán este número de localidades a partir del apuntador a la cadena
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

;lee_mouse - Revisa el estado del mouse
;Devuelve:
;;BX - estado de los botones
;;;Si BX = 0000h, ningun boton presionado
;;;Si BX = 0001h, boton izquierdo presionado
;;;Si BX = 0002h, boton derecho presionado
;;;Si BX = 0003h, boton izquierdo y derecho presionados
; (400,120) => 80x25 =>Columna: 400 x 80 / 640 = 50; Renglon: (120 x 25 / 200) = 15 => 50,15
;;CX - columna en la que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
;;DX - renglon en el que se encuentra el mouse en resolucion 640x200 (columnas x renglones)
lee_mouse	macro
	mov ax,0003h
	int 33h
endm

;comprueba_mouse - Revisa si el driver del mouse existe
comprueba_mouse 	macro
	mov ax,0		;opcion 0
	int 33h			;llama interrupcion 33h para manejo del mouse, devuelve un valor en AX
					;Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
endm


	.code
inicio:					;etiqueta inicio
	inicializa_ds_es
	comprueba_mouse		;macro para revisar driver de mouse
	xor ax,0FFFFh		;compara el valor de AX con FFFFh, si el resultado es zero, entonces existe el driver de mouse
	jz imprime_ui		;Si existe el driver del mouse, entonces salta a 'imprime_ui'
	                ;Si no existe el driver del mouse entonces se muestra un mensaje

	;
	lea dx,[no_mouse]
	mov ax,0900h	;opcion 9 para interrupcion 21h
	int 21h			;interrupcion 21h. Imprime cadena.
	jmp teclado		;salta a 'teclado'
imprime_ui:
	clear 					;limpia pantalla
	oculta_cursor_teclado	;oculta cursor del mouse
	apaga_cursor_parpadeo 	;Deshabilita parpadeo del cursor
	call DIBUJA_UI 	;procedimiento que dibuja marco de la interfaz
	muestra_cursor_mouse 	;hace visible el cursor del mouse
	;Revisar que el boton izquierdo del mouse no esté presionado
	;Si el botón no está suelto, no continúa
mouse_no_clic:
	lee_mouse
	test bx,0001h
	jnz mouse_no_clic
	;Lee el mouse y avanza hasta que se haga clic en el boton izquierdo
mouse:
	lee_mouse
	test bx,0001h ;Para revisar si el boton izquierdo del mouse fue presionado
	jz mouse ;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse

	;Leer la posicion del mouse y hacer la conversion a resolucion
	;80x25 (columnas x renglones) en modo texto
	mov ax,dx 			;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
	div [ocho] 			;Division de 8 bits
		;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
		;para obtener el valor correspondiente en resolucion 80x25
	xor ah,ah 			;Descartar el residuo de la division anterior
	mov dx,ax 			;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

	mov ax,cx 			;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
	div [ocho] 			;Division de 8 bits
		;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
		;para obtener el valor correspondiente en resolucion 80x25
	xor ah,ah 			;Descartar el residuo de la division anterior
	mov cx,ax 			;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

	; presionado
	cmp dx, 0		;Si el mouse fue presionado en el renglon 0
	je boton_x	;se va a revisar si fue dentro del boton [X]

	; boton de play esta dentro del renglón 1, 2 y 3
	; asi que se comprueban todos de una vez
	cmp dx, 1
	je boton_play
	cmp dx, 2
	je boton_play
	cmp dx, 3
	je boton_play
	; no comprobamos stop ya que se da por hecho que esta detenido el juego

	; si no fue ninguno omitimos los demas valores
	jmp mouse_no_clic ; "de vuelta al basurero" -bob esponja

boton_play: ; solo funciona si esta en stop el juego
	mov in_game, 1	; in_game = true
	mov ia, 1				; ia_mode = true
	cmp cx, 43 			; todo el boton de play cubre las columnas 43, 44 y 45
	je game_loop		;	vamos al juego
	cmp cx, 44
	je game_loop		; vamos al juego
	cmp cx, 45
	je game_loop		; vamos al juego
	; si fue cerca pero no en el boton ignoramos los demas resultados
	mov in_game, 0 	; regresamos la bandera de juego a falso
	jmp mouse_no_clic; regresamos a leer el mouse

boton_stop:	; boton de stop solo funciona si esta en funcionamiento el programa
							; boton stop solo funciona dentro del juego y cubre las columnas
							; 34, 35 y 36
	cmp cx, 34
	je detener	; detenemos el juego
	cmp cx, 35
	je detener	; detenemos el juego
	cmp cx, 36
	je detener	; detenemos el juego
	cmp in_game, 1 	; fue cerca del boton pero el juego sigue en ejecucion
	je game_loop		; regresamos al flujo de juego
	jz mouse_no_clic; si no, nos vamos a la lectura fuera de juego

game_loop:	; void FixedUpdate de C#
		;--------------------------- Tiempo ---------------------------;
		mov ah, 2Ch ; opcion 2Ch que retorna horas minutos y segundos del sistema
		int 21h			; interrupcion 21h

		cmp dl, fps ; comparamos dl que contiene centesimas de segundo con los fotogramas
		; a imprimir
		je game_loop ; mientras no cambie volvemos a comprobar

		mov fps, dl ; una vez que cambia ejecutamos los demas
		call crono	; manejamos el tiempo en pantalla

;--------------------------- bola y colisiones ---------------------------;
	colisiones:
		call BORRA_BOLA 					; limpiamos la posicion anterior

		; colisiones horizontales
		cmp dragon_ball_col, 5 		; choque con la porteria del jugador 1
		jbe choque_bola_gol_p1		; anotamos gol
		cmp dragon_ball_col, 74 	; choque con la porteria del jugador 2
		jae choque_bola_gol_p2		; anotamos gol

		; colisiones verticales
		cmp dragon_ball_ren, 5 		; choque con la pared de arriba
		je choque_bola_arriba			; vamos a que la bola baje
		cmp dragon_ball_ren, 23 	; choque con la pared de abajo
		je choque_bola_bajo				; vamos a que la bola suba

		; si no ha chocado con nada de eso
		mov al, p1_col						; pasamos el lugar del jugador 1
		cmp [dragon_ball_col], al ; choque con el jugador 1
		je choque_bola_p1					; cambiamos con respecto a la posicion del j1
		inc al										; para revisar no solo la posicion y dar mas
		;	credibilidad al juego
		cmp [dragon_ball_col], al ; si no también con el jugador mismo
		je choque_bola_p1					; cambiamos con respecto a la posicion del j1

		mov al, p2_col
		cmp [dragon_ball_col], al ; choque con el jugador 2
		je choque_bola_p2					; cambiamos con respecto a la posicion del j1
		dec al
		cmp [dragon_ball_col], al ; choque con el jugador 2
		je choque_bola_p2					; cambiamos con respecto a la posicion del j1

		; si no mas no choca con nada
		jmp movimientos_bola 			; vamos a sus movimientos

	choque_bola_arriba:; choca arriba asi que debe bajar
		mov [bola_sube], 0 				;  subir = false
		jmp movimientos_bola			; vamos a sus movimientos

	choque_bola_bajo:						; choca abajo asi que debe subir
		mov [bola_sube], 1 				;  subir = true
		jmp movimientos_bola			; vamos a sus movimientos

	choque_bola_gol_p1: 				; anotamos gol en la porteria del primer jugador
		mov [dragon_ball_col], 8	; movemos la pelota a la posicion central (col)
		mov [dragon_ball_ren], 14 ; movemos la pelota a la posicion central (ren)
		inc p2_score							; incrementamos el score de p2
		mov [bola_derecha], 1			; cambia de direccion la bola
		jmp movimientos_bola			; la bola sigue en movimiento
	choque_bola_gol_p2:					; anotamos gol en la porteria del segundo jugador
		mov [dragon_ball_col], 70	; movemos la pelota a la posicion central (col)
		mov [dragon_ball_ren], 14 ; movemos la pelota a la posicion central (ren)
		inc p1_score							; incrementamos el score de p1
		mov [bola_derecha], 0			; cambia de direccion la bola
		jmp movimientos_bola			; la bola sigue en movimiento

	choque_bola_p1:							; la bola choco con el player1
		mov al, p1_ren
		cmp al, [dragon_ball_ren]
		je cbp1_t
		dec al
		cmp al, [dragon_ball_ren]
		je cbp1_t
		dec al
		cmp al, [dragon_ball_ren]
		je cbp1_t
		add al, 3
		cmp al, [dragon_ball_ren]
		je cbp1_t
		dec al
		cmp al, [dragon_ball_ren]
		je cbp1_t
		jmp movimientos_bola
	cbp1_t:
		mov [bola_derecha], 1
		jmp movimientos_bola

	choque_bola_p2:							; la bola choco con el player2
		mov al, p2_ren
		cmp al, dragon_ball_ren
		je cbp2_t
		dec al
		cmp al, dragon_ball_ren
		je cbp2_t
		dec al
		cmp al, dragon_ball_ren
		je cbp2_t
		add al, 3
		cmp al, dragon_ball_ren
		je cbp2_t
		dec al
		cmp al, dragon_ball_ren
		je cbp2_t

		jmp movimientos_bola
	cbp2_t:
		mov [bola_derecha], 0
		jmp movimientos_bola


	movimientos_bola:						; movimientos de acuerdo a las posiciones nuevas
															;	o previas
		cmp bola_sube, 1; checamos que esta haciendo la bola
		je bola_s_i; si esta subiendo comprobamos que se mueva a la izquierda
	bola_b_i:; si no la bola esta bajando
		cmp bola_derecha, 1; comparamos que se mueva a la derecha
		je bola_b_d; nos vamos a moverla a la derecha
		inc dragon_ball_ren ; si no vamos a mover su posicion abajo
		dec dragon_ball_col ; a la izquierda
		jmp sigue_loop ;  seguimos en el loop de juego
	bola_b_d: ; la bola baja a la derecha
		inc dragon_ball_ren ; movemos a la derecha
		inc dragon_ball_col ; bajamos
		jmp sigue_loop ; regresamos al loop del juego
	bola_s_i: ;  la bola esta subiendo
		cmp bola_derecha, 1 ; va a la derecha?
		je bola_s_d ; nos vamos a su segmento
		dec dragon_ball_ren ; si no la subimos
		dec dragon_ball_col ; y vamos a la izquierda
		jmp sigue_loop ; regresamos al loop del juego
	bola_s_d: ; la bola sube y va a la derecha
		dec dragon_ball_ren ; subimos
		inc dragon_ball_col ; vamos a la derecha
		jmp sigue_loop ; regresamos al juego
	;--------------------------- fin bola y colisiones ---------------------------;

	sigue_loop:
		; --------------------------- scary monsters and nice sprites ---------------------------;
	 	call RENDERIZA_JUEGO ; redibujamos con los nuevos cambios
		; --------------------------- mouse ---------------------------;
		lee_mouse;Leer la posicion del mouse y hacer la conversion a resolucion
		;80x25 (columnas x renglones) en modo texto
		test bx,0001h 		;Para revisar si el boton izquierdo del mouse fue presionado
		jz leer_teclado_p1 			;Si el boton izquierdo no fue presionado, lee el teclado

	mouse_in_game:

		mov ax,dx 			;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
		div [ocho] 			;Division de 8 bits
							;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
							;para obtener el valor correspondiente en resolucion 80x25
		xor ah,ah 			;Descartar el residuo de la division anterior
		mov dx,ax 			;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

		mov ax,cx 			;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
		div [ocho] 			;Division de 8 bits
							;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
							;para obtener el valor correspondiente en resolucion 80x25
		xor ah,ah 			;Descartar el residuo de la division anterior
		mov cx,ax 			;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

		;Si el mouse fue presionado en el renglon 0
		;se va a revisar si fue dentro del boton [X]
		cmp dx, 0
		je boton_x

		cmp dx, 1			; boton de stop esta dentro del renglón 1
		je boton_stop	; y no tiene sentido verificar el boton de play
		cmp dx, 2			; boton de stop esta dentro del renglón 2
		je boton_stop	; y no tiene sentido verificar el boton de play
		cmp dx, 3			; boton de stop esta dentro del renglón 3
		je boton_stop	; y no tiene sentido verificar el boton de play

		jmp game_loop	; regresamos al juego
	;--------------------------- teclado y movimientos ---------------------------;
	leer_teclado_p1: ; leemos la entrada del primer jugador
		xor ax,ax ; limpiamos cualquier otra interrupcion o valor recibido

		mov ah, 01h 	; opcion de lectura del teclado
		int 16h 			; interrupcion 16h para lectura del buffer
		jz ia_mode 		; si la bandera de cero = 1 no hay tecla presionada
		mov ah,00h 		; limpiamos el buffer
		int 16h
		; player 1
		cmp al, 77h		;compara la entrada de teclado si fue [w]
		je dec_p1 		; subimos la barra
		cmp al, 73h		; compara la entrada de teclado si fue [s]
		je inc_p1 		; bajamos la barra

		cmp ia, 1 		; comprobamos el modo de juego (1 o 2 jugadores)
		jae ia_mode 	; saltamos al modo de IA

	leer_teclado_p2: 	; si no leemos el teclado del segundo jugador
		mov ia, 0			 	; desactivamos la ia para evitar problemas
		; player 2
		cmp al,6Fh			;compara la entrada de teclado si fue [o]
		je dec_p2 			; subimos la barra
		cmp al,6Ch			;compara la entrada de teclado si fue [l]
		je inc_p2 			; bajamos la barra

		jmp game_loop ; regresamos al juego

	ia_mode:
		cmp ia, 1						; volvemos a comprobar el valor de ia
		jb leer_teclado_p2 	; en todo caso nos vamos a leer al segundo jugador

		cmp al,6Fh					; compara la entrada de teclado si fue [o]
		je leer_teclado_p2 	; regresamos al modo de dos jugadores
		cmp al,6Ch					; compara la entrada de teclado si fue [l]
		je leer_teclado_p2 	; regresamos al modo de dos jugadores

		mov al, [p2_ren]		; no hubo interacciones del segundo jugador
		cmp [dragon_ball_ren], al ; movemos el renglon del j2 al mismo
		ja inc_p2						; que el de la pelota
		jbe dec_p2					; dependiendo de si sube o baja

		jmp game_loop 			; regresamos al juego

	dec_p2:; decrementar el renglon del player 2
		xor ax,ax						; limpiamos ax
		mov ah, p2_ren			; movemos las barras y comprobamos colisiones
		sub ah, 2						; le restamos 2 para que quede la parte superior de la barra
		cmp ah,	5						; comparamos con la posicion del limite superior
		je game_loop				; en caso de choque regresamos al juego
		dec p2_ren					; si no choca subimos la barra una unidad

		mov ah, [p2_ren]		; movemos los componentes del p2 a los auxiliares para
		mov [ren_aux],ah		; borrar su estela de la posicion anterior
		mov [movimiento_j], 1d
		mov al,[p2_col]			; de a cuerdo a su tipo de movimiento
		mov [col_aux],al
		call IMPRIME_PLAYER	; imprimimos la nueva posición
		mov [movimiento_j], 0d ; quitamos el tipo de movimiento para volver a usarlo

		jmp game_loop				; regresamos al juego

	inc_p2: ; incrementa el renglon del player 2
		xor ax,ax						;limpiamos ax
		mov ah, p2_ren 			; pasamos el valor actual del renglon de p2
		add ah, 2						; le sumamos dos
		cmp ah,	23					; comprobamos que no choque
		je game_loop				; si choca regresamos al juego
		inc p2_ren					; si no choca le aumentamos en 1 el renglón

		mov ah, [p2_ren]		; movemos los componentes del p2 a los auxiliares para
		mov [ren_aux],ah		; borrar su estela de la posicion anterior
		mov [movimiento_j], 2d
		mov al,[p2_col]			; de a cuerdo a su tipo de movimiento
		mov [col_aux],al
		call IMPRIME_PLAYER	; imprimimos la nueva posición
		mov [movimiento_j], 0d; quitamos el tipo de movimiento para volver a usarlo

		jmp game_loop				; regresamos al juego

	dec_p1: ; decrementar el renglon del player 1, subir barra
		xor ax,ax 					; limpiamos ax
		mov ah, p1_ren			; pasamos el valor actual del renglon de p1
		sub ah, 2						; le restamos dos
		cmp ah,	5						; comprobamos si choca arriba
		je game_loop				; si choca regresamos al juego
		dec p1_ren					; si no choca seguimos y subimos la barra una unidad

		mov ah, [p1_ren]		; la imprimimos nuevamente de tal manera que
		mov [ren_aux],ah		; no deje una estela
		mov [movimiento_j], 1d; cambiamos el tipo de movimiento
		mov al,[p1_col]
		mov [col_aux],al
		call IMPRIME_PLAYER	; imprimimos
		mov [movimiento_j], 0d; quitamos el tipo de movimiento para volver a usarlo

		jmp game_loop				; regresamos al juego

	inc_p1:; incrementa el renglon del player 1, bajar barra
		xor ax,ax 					; limpiamos ax
		mov ah, p1_ren 			; pasamos el valor actual del renglon de p1
		add ah, 2						; le sumamos dos para comprobar
		cmp ah,	23					; si choca por abajo
		je game_loop				; si choca vamos al juego
		inc p1_ren 					; si no choca bajamos la barra en 1

		mov ah, [p1_ren]		; la imprimimos nuevamente de tal manera que
		mov [ren_aux],ah		; no deje una estela
		mov [movimiento_j], 2d; cambiamos el tipo de movimiento
		mov al,[p1_col]
		mov [col_aux],al
		call IMPRIME_PLAYER	; imprimimos
		mov [movimiento_j], 0d; quitamos el tipo de movimiento para volver a usarlo
		jmp game_loop				; regresamos al juego
;--------------------------- fin de procedimientos internos de juego ---------------------------;

;--------------------------- Botones de arriba ---------------------------;
detener:	; boton de stop
	; reset de posiciones
	mov [p1_ren], 14	; regresamos al jugador al centro
	mov [p2_ren], 14	; en el renglon 14
	mov [dragon_ball_col], 40	; regresamos la bola a la posicion central
	mov [dragon_ball_ren], 14	; de la pantalla
	jmp imprime_ui ; reinicia de cero sin comprobar el driver del mouse

boton_x:	; boton de salir
	jmp boton_x1	; fue presionado cerca, vamos a comprobar

pausa:		; boton de pausa
	cmp cx, 4				; el boton de pausa ocupa desde
	jbe full_p			; el renglon 1 hasta el 4 y ya comprobamos el 1, por ende esta en el rango
	cmp in_game, 1	; comprobamos si el juego esta en ejecución
	jae game_loop		; de ser asi regresamos al mismo
full_p:		; si no se pausa y vamos a esperar movimiento del mouse
	mov in_game, 0 	; cambiamos in_game a falso
	jmp mouse_no_clic	; pausa del juego

;Lógica para revisar si el mouse fue presionado en [X]
;[X] se encuentra en renglon 0 y entre columnas 76 y 78
boton_x1: ; parte 1 del boton cerrar
	cmp cx,76			; fue presionado en uno de los renglones del boton
	jge boton_x2  ; nos vamos a comprobar si fue en este o en los siguientes
	cmp cx, 1			; no fue cerca tal vez fue en la pausa
	ja pausa			; saltamos a la pausa
	cmp in_game, 1; si no comprobamos si el juego esta en ejecución
	jae game_loop	; regresamos al juego
	jmp mouse_no_clic	; no estuvo en ninguno y el juego esta detenido
boton_x2:	; parte 2 del boton cerrar
	cmp cx,78			; fue presionado al final
	jbe boton_x3	; fue aqui o antes
	cmp in_game, 1; el juego esta en ejecución
	jae game_loop	; regresamos al juego
	jmp mouse_no_clic; regresamos a la espera del mouse
boton_x3:	; parte 3 del boton cerrar
	;Se cumplieron todas las condiciones
	jmp salir ; salimos del juego

;--------------------------- errores ---------------------------;
;Si no se encontró el driver del mouse, muestra un mensaje y el usuario debe salir tecleando [enter]
teclado:
	mov ah,08h
	int 21h
	cmp al,0Dh		;compara la entrada de teclado si fue [enter]
	jnz teclado 	;Sale del ciclo hasta que presiona la tecla [enter]

;--------------------------- salida ---------------------------;
salir:
	clear 				;limpia pantalla
	mov ax,4C00h	;AH = 4Ch, opción para terminar programa, AL = 0 Exit Code, código devuelto al finalizar el programa
	int 21h				;señal 21h de interrupción, pasa el control al sistema operativo

;--------------------------- PROCEDIMIENTOS ---------------------------;

	crono proc ;  proceso que controla todas las interacciones del tiempo real y el de la maquina
			xor ax, ax			; limpiamos ax
			inc pazos64     ; una pasada de 18.2
			dec tiempo_s 		; bajamos los segundos
			cmp tiempo_s, 0	; "y tu tiempo se acabo" -ENDGAME
			jbe detener 		; en caso de finalizar el tiempo se detiene el juego
			cmp [tiempo_s], 1092d ; comparamos con 1092 que es un minuto
			; traducido en ticks (cada tick es de 18.2)
			jb cero_minutos ; si es menor a 1092d a transcurrido un minuto

		un_minuto:				; sabemos que falta un minuto
			mov [tiempo_cadena],"1" ; por lo que esta parte nunca cambia
			mov [tiempo_cadena+1],":"; y esta tampoco
			cmp [pazos64], 5; comparamos la cantidad de pasos desde la ultima vez
			je aumento			; si es 5 se aumenta en 1 el valor de ticks (18->19)
			mov ax, tiempo_s; si no le restamos al tiempo un minuto
			sub ax, 1092d 	; para que sean 60 segundos
			xor dh, dh			; limpiamos el residuo de la division
			div t_inicial 	; tiempo en segundos
			cmp al, 60
			jb fin_crono
			ret

		aumento:
			inc t_inicial
			mov [pazos64], 0
			mov ax, tiempo_s
			sub ax, 1092d
			div t_inicial ;  tiempo en segundos


			dec t_inicial
			jmp fin_crono

		cero_minutos:
			mov [tiempo_cadena],"0"
			mov [tiempo_cadena+1],":"
			cmp [pazos64], 5
			je aumento_dos
			mov ax, tiempo_s
			div t_inicial ;  tiempo en segundos
			cmp al, 60
			jb fin_crono
			ret

			aumento_dos:
				inc t_inicial
				mov [pazos64], 0
				mov ax, tiempo_s
				div t_inicial

				dec t_inicial
		fin_crono:
			cmp al, 0000h
			ja dividir_time
			mov [tiempo_cadena+2],"0"
			mov [tiempo_cadena+3],"0"
			ret

			dividir_time:; parte del codigo para dividir mayores a 10d
				xor dx, dx
				xor ah, ah ; limpiamos ah evitando asi medios numeros
				cmp al, [diez_b]; comparamos un numero menor a 10
				jb	sacar_der
				div [diez_b]   ; debemos dividir el valor
				mov dl, ah
				push dx       ; el residuo es mandado a la pila
				inc pila      ; aumentamos en 1 el valor a la pila
				cmp al, [diez_b]   ; comparamos el resultado de la division
				jae dividir_time   ; dividimos mientras el valor sea mayor o igual a 10
				jb sacar      ; sacamos los valores de la pila si son menores a 10

			sacar_n:
			  dec pila      ; creamos nuestro propio loop sin interrumpir fibonacci
							                ; (el valor mas a la izquierda del numero)
			  pop dx        ; sacamos cada valor de la pila
				add dl, 30h
				mov [tiempo_cadena+3], dl
				cmp pila, 0h; comparamos para saber la cantidad de valores
				ja sacar_n    ; si es mayor o igual se repite
				ret

			sacar:          ; para sacar cada valor de la pila menor a 10 e imprimir
							                ; (el valor mas a la izquierda del numero)
			  cmp al, 00h ; comparamos el resultado de la division
			  jbe sacar_n   ;si es 0 no hay mas numeros y solo imprimimos de la pila

			  mov ah, al    ; en todo caso el primer valor a imprimir
				add ah, 30h
				mov [tiempo_cadena+2], ah
			  cmp pila, 00h; comparamos para saber la cantidad de valores
			  ja sacar_n    ; si es mayor o igual se repite en sacar_n
				ret
			sacar_der:
				mov [tiempo_cadena+2], "0"
				mov ah, al    ; en todo caso el primer valor a imprimir
				add ah, 30h
				mov [tiempo_cadena+3], ah
				cmp pila, 00h; comparamos para saber la cantidad de valores
		ret
	endp

	RENDERIZA_JUEGO proc

		;imprime cadena de Timer
		posiciona_cursor 2,38
		imprime_cadena_color tiempo_cadena,4,cBlanco,bgNegro

		;Imprime el score del player 1, en la posición del col_aux
		;la posición de ren_aux está fija en IMPRIME_SCORE_BL
		mov [col_aux],4
		mov bl,[p1_score]
		call IMPRIME_SCORE_BL

		;Imprime el score del player 2, en la posición del col_aux
		;la posición de ren_aux está fija en IMPRIME_SCORE_BL
		mov [col_aux],76
		mov bl,[p2_score]
		call IMPRIME_SCORE_BL

	imprime_players:
		;player 1
		;columna: p1_col, renglón: p1_ren
		mov al,[p1_col]
		mov ah,[p1_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call IMPRIME_PLAYER

		;player 2
		;columna: p2_col, renglón: p2_ren
		mov al,[p2_col]
		mov ah,[p2_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call IMPRIME_PLAYER

		;imprime bola
		;columna: 40, renglón: 14
		mov al,[dragon_ball_col]
		mov ah,[dragon_ball_ren]
		mov [col_aux], al
		mov [ren_aux], ah
		call IMPRIME_BOLA

		ret
	endp


	DIBUJA_UI proc
		;imprimir esquina superior izquierda del marco
		posiciona_cursor 0,0
		imprime_caracter_color marcoEsqSupIzq,cAmarillo,bgNegro

		;imprimir esquina superior derecha del marco
		posiciona_cursor 0,79
		imprime_caracter_color marcoEsqSupDer,cAmarillo,bgNegro

		;imprimir esquina inferior izquierda del marco
		posiciona_cursor 24,0
		imprime_caracter_color marcoEsqInfIzq,cAmarillo,bgNegro

		;imprimir esquina inferior derecha del marco
		posiciona_cursor 24,79
		imprime_caracter_color marcoEsqInfDer,cAmarillo,bgNegro

		;imprimir marcos horizontales, superior e inferior
		mov cx,78 		;CX = 004Eh => CH = 00h, CL = 4Eh
	marcos_horizontales:
		mov [col_aux],cl
		;Superior
		posiciona_cursor 0,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		;Inferior
		posiciona_cursor 24,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		;Limite mouse
		posiciona_cursor 4,[col_aux]
		imprime_caracter_color marcoHor,cAmarillo,bgNegro
		mov cl,[col_aux]
		loop marcos_horizontales

		;imprimir marcos verticales, derecho e izquierdo
		mov cx,23 		;CX = 0017h => CH = 00h, CL = 17h
	marcos_verticales:
		mov [ren_aux],cl
		;Izquierdo
		posiciona_cursor [ren_aux],0
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		;Inferior
		posiciona_cursor [ren_aux],79
		imprime_caracter_color marcoVer,cAmarillo,bgNegro
		mov cl,[ren_aux]
		loop marcos_verticales

		;imprimir marcos verticales internos
		mov cx,3 		;CX = 0003h => CH = 00h, CL = 03h
	marcos_verticales_internos:
		mov [ren_aux],cl
		;Interno izquierdo (marcador player 1)
		posiciona_cursor [ren_aux],7
		imprime_caracter_color marcoVer,cAmarillo,bgNegro

		;Interno derecho (marcador player 2)
		posiciona_cursor [ren_aux],72
		imprime_caracter_color marcoVer,cAmarillo,bgNegro

		jmp marcos_verticales_internos_aux1
	marcos_verticales_internos_aux2:
		jmp marcos_verticales_internos
	marcos_verticales_internos_aux1:
		;Interno central izquierdo (Timer)
		posiciona_cursor [ren_aux],32
		imprime_caracter_color marcoVer,cAmarillo,bgNegro

		;Interno central derecho (Timer)
		posiciona_cursor [ren_aux],47
		imprime_caracter_color marcoVer,cAmarillo,bgNegro

		mov cl,[ren_aux]
		loop marcos_verticales_internos_aux2

		;imprime intersecciones internas
		posiciona_cursor 0,7
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 4,7
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 0,32
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 4,32
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 0,47
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 4,47
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 0,72
		imprime_caracter_color marcoCruceVerSup,cAmarillo,bgNegro
		posiciona_cursor 4,72
		imprime_caracter_color marcoCruceVerInf,cAmarillo,bgNegro

		posiciona_cursor 4,0
		imprime_caracter_color marcoCruceHorIzq,cAmarillo,bgNegro
		posiciona_cursor 4,79
		imprime_caracter_color marcoCruceHorDer,cAmarillo,bgNegro

		;imprimir [X] para cerrar programa
		posiciona_cursor 0,76
		imprime_caracter_color '[',cAmarillo,bgNegro
		posiciona_cursor 0,77
		imprime_caracter_color 'X',cRojoClaro,bgNegro
		posiciona_cursor 0,78
		imprime_caracter_color ']',cAmarillo,bgNegro
		;imprimir [||] para pausar programa
		posiciona_cursor 0,1
		imprime_caracter_color '[',cAmarillo,bgNegro
		posiciona_cursor 0,2
		imprime_caracter_color '|',cRojoClaro,bgNegro
		posiciona_cursor 0,3
		imprime_caracter_color '|',cRojoClaro,bgNegro
		posiciona_cursor 0,4
		imprime_caracter_color ']',cAmarillo,bgNegro

		;imprimir título
		mov al, p2_score
		cmp p1_score, al
		je	titulo1
		ja 	titulo2
		jb 	titulo3
	titulo1:
		posiciona_cursor 0,38
		imprime_cadena_color [titulo],4,cBlanco,bgNegro
		jmp termina_titulos
	titulo2:
		posiciona_cursor 0,34
		imprime_cadena_color [wp1],12,cCyanClaro,bgNegro
		jmp termina_titulos
	titulo3:
		posiciona_cursor 0,34
		imprime_cadena_color [wp2],12,cAmarillo,bgNegro
	termina_titulos:
		call IMPRIME_DATOS_INICIALES
		ret
	endp


	IMPRIME_DATOS_INICIALES proc
		;inicializa la cadena del timer
		mov [tiempo_cadena],"2"
		mov [tiempo_cadena+1],":"
		mov [tiempo_cadena+2],"0"
		mov [tiempo_cadena+3],"0"

		mov [tiempo_s],2184 	;inicializa el número de segundos del timer
		mov [p1_score],0 			;inicializa el score del player 1
		mov [p2_score],0 			;inicializa el score del player 2

		;Imprime el score del player 1, en la posición del col_aux
		;la posición de ren_aux está fija en IMPRIME_SCORE_BL
		mov [col_aux],4
		mov bl,[p1_score]
		call IMPRIME_SCORE_BL

		;Imprime el score del player 1, en la posición del col_aux
		;la posición de ren_aux está fija en IMPRIME_SCORE_BL
		mov [col_aux],76
		mov bl,[p2_score]
		call IMPRIME_SCORE_BL

		;imprime cadena 'Player 1'
		posiciona_cursor 2,9
		imprime_cadena_color player1,8,cBlanco,bgNegro

		;imprime cadena 'Player 2'
		posiciona_cursor 2,63
		imprime_cadena_color player2,8,cBlanco,bgNegro

		;imprime cadena de Timer
		posiciona_cursor 2,38
		imprime_cadena_color tiempo_cadena,4,cBlanco,bgNegro

		;imprime players
		;player 1
		;columna: p1_col, renglón: p1_ren
		mov al,[p1_col]
		mov ah,[p1_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call IMPRIME_PLAYER

		;player 2
		;columna: p2_col, renglón: p2_ren
		mov al,[p2_col]
		mov ah,[p2_ren]
		mov [col_aux],al
		mov [ren_aux],ah
		call IMPRIME_PLAYER

		;imprime bola
		;columna: 40, renglón: 14
		mov [col_aux],40
		mov [ren_aux],14
		call IMPRIME_BOLA

		;Botón Stop
		mov [boton_caracter],254d
		mov [boton_color],bgAmarillo
		mov [boton_renglon],1
		mov [boton_columna],34
		call IMPRIME_BOTON

		;Botón Start
		mov [boton_caracter],16d
		mov [boton_color],bgAmarillo
		mov [boton_renglon],1
		mov [boton_columna],43d
		call IMPRIME_BOTON

		ret
	endp

	;procedimiento IMPRIME_SCORE_BL
	;Imprime el marcador de un jugador, poniendo la posición
	;en renglón: 2, columna: col_aux
	;El valor que imprime es el que se encuentre en el registro BL
	;Obtiene cada caracter haciendo divisiones entre 10 y metiéndolos en
	;la pila
	IMPRIME_SCORE_BL proc
		xor ah,ah
		mov al,bl
		mov [conta],0
	div10:
		xor dx,dx
		div [diez]
		push dx
		inc [conta]
		cmp ax,0
		ja div10
	imprime_digito:
		posiciona_cursor 2,[col_aux]
		pop dx
		or dl,30h
		imprime_caracter_color dl,cBlanco,bgNegro
		inc [col_aux]
		dec [conta]
		cmp [conta],0
		ja imprime_digito
		ret
	endp

	;procedimiento IMPRIME_PLAYER
	;Imprime la barra que corresponde a un jugador tomando como referencia la posición indicada por las variables
	;ren_aux y col_aux, donde esa posición es el centro del jugador
	;Se imprime el carácter █ en color blanco en cinco renglones
	IMPRIME_PLAYER proc
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		add [ren_aux],3
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro
		inc [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 219d,cBlanco,bgNegro

		; despues de imprimir todo el player
		cmp movimiento_j, 1d
		je imp_abj

		cmp movimiento_j, 2d
		je imp_arr
		jmp sEm 	;salida de emergencia

		imp_abj:
			inc [ren_aux]
			posiciona_cursor [ren_aux],[col_aux]
			imprime_caracter_color 32d,cBlanco,bgNegro
			jmp sEm

		imp_arr:
			sub [ren_aux], 5d
			posiciona_cursor [ren_aux],[col_aux]
			imprime_caracter_color 32d,cBlanco,bgNegro
		sEm:

		ret
	endp

	BORRA_BOLA proc
		mov al, [dragon_ball_ren]
		mov [ren_aux], al
		mov al, [dragon_ball_col]
		mov [col_aux], al
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 32d,cBlanco,bgNegro
		ret
	endp

	;procedimiento IMPRIME_BOLA
	;Imprime el carácter ☻ (02h en ASCII) en la posición indicada por
	;las variables globales
	;ren_aux y col_aux
	IMPRIME_BOLA proc
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color 2d,cCyanClaro,bgNegro
		ret
	endp

	;procedimiento IMPRIME_BOTON
	;Dibuja un boton que abarca 3 renglones y 3 columnas
	;con un caracter centrado dentro del boton
	;en la posición que se especifique (esquina superior izquierda)
	;y de un color especificado
	;Utiliza paso de parametros por variables globales
	;Las variables utilizadas son:
	;boton_caracter: debe contener el caracter que va a mostrar el boton
	;boton_renglon: contiene la posicion del renglon en donde inicia el boton
	;boton_columna: contiene la posicion de la columna en donde inicia el boton
	;boton_color: contiene el color del boton
	IMPRIME_BOTON proc
	 	;La esquina superior izquierda se define en registro CX y define el inicio del botón
		;La esquina inferior derecha se define en registro DX y define el final del botón
		;utilizando opción 06h de int 10h
		;el color del botón se define en BH
		mov ax,0600h 			;AH=06h (scroll up window) AL=00h (borrar)
		mov bh,cRojo	 		;Caracteres en color rojo dentro del botón, los 4 bits menos significativos de BH
		xor bh,[boton_color] 	;Color de fondo en los 4 bits más significativos de BH
		mov ch,[boton_renglon] 	;Renglón de la esquina superior izquierda donde inicia el boton
		mov cl,[boton_columna] 	;Columna de la esquina superior izquierda donde inicia el boton
		mov dh,ch 				;Copia el renglón de la esquina superior izquierda donde inicia el botón
		add dh,2 				;Incrementa el valor copiado por 2, para poner el renglón final
		mov dl,cl 				;Copia la columna de la esquina superior izquierda donde inicia el botón
		add dl,2 				;Incrementa el valor copiado por 2, para poner la columna final
		int 10h
		;se recupera los valores del renglón y columna del botón
		;para posicionar el cursor en el centro e imprimir el
		;carácter en el centro del botón
		mov [col_aux],dl
		mov [ren_aux],dh
		dec [col_aux]
		dec [ren_aux]
		posiciona_cursor [ren_aux],[col_aux]
		imprime_caracter_color [boton_caracter],cRojo,[boton_color]
	 	ret 			;Regreso de llamada a procedimiento
	endp	 			;Indica fin de procedimiento UI para el ensamblador
end inicio			;fin de etiqueta inicio, fin de programa
