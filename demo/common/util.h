#define UTILITY_VERSION "1.0"

#define CLRSCRN printf ("%c",147) 
#define HOME printf ("%c",19) 
#define TOXY(X,Y) r.a=0;r.x=Y;r.y=X;r.flags=0;r.pc=58634L;_sys(&r)

#define WAITKEY do { r.pc=0xF13E; _sys(&r); } while (r.a == 0)

#define CRSR_UP 145
#define CRSR_DOWN 17
#define CRSR_LEFT 157
#define CRSR_RIGHT 29
