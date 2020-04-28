#include "vicii_ipc.h"

int main(int argc, char* argv[]) {
   struct vicii_ipc* ipc = ipc_init(IPC_SENDER);
   unsigned char ipc_buf[IPC_BUFSIZE];

   ipc_open(ipc);

   printf ("Send\n");
   ipc_send(ipc, ipc_buf);

   printf ("Wait for response\n");
   ipc_receive(ipc, ipc_buf);

   printf ("Done\n");
   ipc_close(ipc);
}
