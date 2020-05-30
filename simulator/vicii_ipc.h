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
#define VICII_OP_CAPTURE_START 1
// When bit 2 if flipped, fpga sync will stop, bit 1&2 are turned off
#define VICII_OP_CAPTURE_END   2
// Indicates this state change should be happening on phi HIGH only
#define VICII_OP_BUS_ACCESS    4
// Indicates this state change includes sync info
#define VICII_OP_SYNC_STATE    8
// Only start capture when x,y hit 0,0 and do one frame only
#define VICII_OP_CAPTURE_ONE_FRAME 16

// Must not exceed IPC_BUFSIZE
struct vicii_state {
  unsigned int flags;
  unsigned int enabled;

  unsigned char ce;
  unsigned char rw;
  unsigned char phi;
  unsigned char ba;
  unsigned char badline;
  unsigned char aec;

  unsigned short addr_to_sim;
  unsigned short data_to_sim;

  unsigned short addr_from_sim;
  unsigned short data_from_sim;

  unsigned int cycle_num;  // for initial sync
  unsigned int xpos;  // for initial sync
  unsigned int raster_line;  // for initial sync

  // registers for sync
  unsigned char reg[64];
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

  int bufKey;
  int bufShmId;

  struct vicii_state* state;
};

// IPC_RECEIVER must init first
// IPC_SENDER sends a request and waits for a response
// IPC_RECEIVER receives a request and sends a response
struct vicii_ipc* ipc_init(int endPoint);

int ipc_open(struct vicii_ipc* ipc);

void ipc_close(struct vicii_ipc* ipc);

// Return 1 on error, 0 success
int ipc_send(struct vicii_ipc* ipc);

// Return 1 on error, 0 success
int ipc_receive(struct vicii_ipc* ipc);

int ipc_receive_done(struct vicii_ipc* ipc);

#endif
