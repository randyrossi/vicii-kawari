#define UTILITY_VERSION "1.0"

#define CLRSCRN printf ("%c",19) 
#define TOXY(X,Y) r.a=0;r.x=Y;r.y=X;r.flags=0;r.pc=58634L;_sys(&r)

#define WAITKEY do { r.pc=0xF13E; _sys(&r); } while (r.a == 0)
