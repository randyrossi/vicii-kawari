#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <malloc.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/shm.h>
#include <math.h>

#include "vicii_ipc.h"

#define MODULE_NAME "ipc"

static int v(struct vicii_ipc* ipc, int semaphore) {
  ipc->operation[semaphore][0].sem_num = semaphore;
  ipc->operation[semaphore][0].sem_op = 1;
  ipc->operation[semaphore][0].sem_flg = 0;
  if (semop(ipc->semsId, ipc->operation[semaphore], 1) != 0) {
    fprintf(stderr, "%s: can't do v op\n", MODULE_NAME);
    perror("REASON");
    return 1;
  }
  return 0;
}

static int p(struct vicii_ipc* ipc, int semaphore) {
  ipc->operation[semaphore][0].sem_num = semaphore;
  ipc->operation[semaphore][0].sem_op = -1;
  ipc->operation[semaphore][0].sem_flg = 0;
  if (semop(ipc->semsId, ipc->operation[semaphore], 1) != 0) {
    fprintf(stderr, "%s: can't do p op\n", MODULE_NAME);
    perror("REASON");
    return 1;
  }
  return 0;
}

struct vicii_ipc* ipc_init(int endPoint) {
   struct vicii_ipc* ipc = (struct vicii_ipc*)
       malloc(sizeof(struct vicii_ipc));
   ipc->endPoint = endPoint;
   ipc->semsKey = 1240;
   if ( ipc->endPoint == IPC_RECEIVER) {
     ipc->dspOutBufKey = 1241;
     ipc->dspInBufKey = 1242;
   } else {
     ipc->dspOutBufKey = 1242;
     ipc->dspInBufKey = 1241;
   }
   return ipc;
}

int ipc_open(struct vicii_ipc* ipc) {
  int mode;

  if (ipc->endPoint == IPC_RECEIVER) {
    mode = IPC_CREAT;
  } else {
    mode = 0;
  }

  ipc->semsId = semget(ipc->semsKey, 4, mode | 0666);
  if (ipc->semsId < 0) {
    fprintf(stderr, "%s: can't create semaphore\n", MODULE_NAME);
    return -1;
  }

  // If this is the originating end, set all semaphores to 0
  if (ipc->endPoint == IPC_RECEIVER) {
    union semun argument;
    for (int i = 0; i < 4; i++) {
      argument.val = 0;
      if (semctl(ipc->semsId, i, SETVAL, argument) < 0) {
        fprintf(stderr, "%s: can't set semaphore\n", MODULE_NAME);
        return -1;
      }
    }
  }

  ipc->dspOutBufShmId = shmget(ipc->dspOutBufKey, IPC_BUFSIZE, mode | 0644);
  if (ipc->dspOutBufShmId < 0) {
    fprintf(stderr, "%s: can't allocate shared memory segment for outbuf %d\n",
            MODULE_NAME, IPC_BUFSIZE);
    perror("REASON");
    return -1;
  }

  ipc->dspOutBuf = (unsigned char*)shmat(ipc->dspOutBufShmId, NULL, 0);

  ipc->dspInBufShmId = shmget(ipc->dspInBufKey, IPC_BUFSIZE, mode | 0644);

  if (ipc->dspInBufShmId < 0) {
    fprintf(stderr, "%s: can't allocate shared memory segment for inbuf %d\n",
            MODULE_NAME, IPC_BUFSIZE);
    perror("REASON");
    return -1;
  }

  ipc->dspInBuf = (unsigned char*)shmat(ipc->dspInBufShmId, NULL, 0);

  if (ipc->dspOutBuf == NULL || ipc->dspInBuf == NULL) {
    fprintf(stderr, "%s: can't allocate dsp buffer\n", MODULE_NAME);
    return -1;
  }

  return 0;
}

void ipc_close(struct vicii_ipc* ipc) {
  // Now free up all the memory and close handles
  shmdt(ipc->dspOutBuf);
  shmdt(ipc->dspInBuf);
  ipc->dspOutBuf = NULL;
  ipc->dspInBuf = NULL;
}

int ipc_send(struct vicii_ipc* ipc, unsigned char *b) {
  memcpy (ipc->dspOutBuf, b, IPC_BUFSIZE);

  if (ipc->endPoint == IPC_RECEIVER) {
    if (v(ipc, END1_PRODUCER_SIG_END2_CONSUME_OK))
       return 1;
    if (p(ipc, END2_CONSUMER_SIG_END1_PRODUCE_OK))
       return 1;
  } else {
    if (v(ipc, END2_PRODUCER_SIG_END1_CONSUME_OK))
       return 1;
    if (p(ipc, END1_CONSUMER_SIG_END2_PRODUCE_OK))
       return 1;
  }
  return 0;
}

int ipc_receive(struct vicii_ipc* ipc, unsigned char *b) {
    if (ipc->endPoint == IPC_SENDER) {
      if (p(ipc, END1_PRODUCER_SIG_END2_CONSUME_OK))
         return 1;
    } else {
      if (p(ipc, END2_PRODUCER_SIG_END1_CONSUME_OK))
         return 1;
    }
    memcpy(b, ipc->dspInBuf, IPC_BUFSIZE);
    if (ipc->endPoint == IPC_SENDER) {
      if (v(ipc, END2_CONSUMER_SIG_END1_PRODUCE_OK))
         return 1;
    } else {
      if (v(ipc, END1_CONSUMER_SIG_END2_PRODUCE_OK))
         return 1;
    }
    return 0;
}
