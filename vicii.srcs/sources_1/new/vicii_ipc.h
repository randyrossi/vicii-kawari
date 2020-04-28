#ifndef VICII_IPC_H
#define VICII_IPC_H

// A super simple IPC mechanism

// This util lets two processes exchange a fixed buffer
// size of IPC_BUFSIZE bytes.  One end initializes as
// the IPC_RECEIVER endpoint (first).  The other end
// initialized as the IPC_SENDER.  Then either side
// can coordinate request/responses using ipc_receive()
// or ipc_send() functions.

#include <stdlib.h>
#include <stdio.h>
#include <sys/sem.h>

union semun {
  int val;
  struct semid_ds* buf;
  ushort* array;
};

// When bit 1 is flipped, fpga sync will start
#define VICII_OP_CAPTURE      1
// When bit 2 if flipped, fpga sync will stop, bit 1&2 are turned off
#define VICII_OP_CAPTURE_END  2

// Must not exceed IPC_BUFSIZE
struct vicii_state {
  unsigned int flags;

  unsigned char ce;
  unsigned char rw;
  unsigned short addr;
  unsigned char data;
};

#define END1_PRODUCER_SIG_END2_CONSUME_OK 0
#define END2_CONSUMER_SIG_END1_PRODUCE_OK 1
#define END2_PRODUCER_SIG_END1_CONSUME_OK 2
#define END1_CONSUMER_SIG_END2_PRODUCE_OK 3

#define IPC_RECEIVER 1
#define IPC_SENDER   2

#define IPC_BUFSIZE  1024

struct vicii_ipc {
  int endPoint;
  int semsKey;
  int semsId;
  struct sembuf operation[4][1];

  int dspOutBufKey;
  int dspOutBufShmId;
  int dspInBufKey;
  int dspInBufShmId;

  unsigned char* dspOutBuf;
  unsigned char* dspInBuf;
};

// IPC_RECEIVER must init first
// IPC_SENDER sends a request and waits for a response
// IPC_RECEIVER receives a request and sends a response
struct vicii_ipc* ipc_init(int endPoint);

int ipc_open(struct vicii_ipc* ipc);

void ipc_close(struct vicii_ipc* ipc);

// Return 1 on error, 0 success
int ipc_send(struct vicii_ipc* ipc, unsigned char *b);

// Return 1 on error, 0 success
int ipc_receive(struct vicii_ipc* ipc, unsigned char *b);

#endif
