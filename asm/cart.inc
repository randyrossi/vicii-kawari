; put this after your program code
; to fill up the image to make an 8k cart
* = $9fff                     ; fill up to -$9fff
        !byte 0
