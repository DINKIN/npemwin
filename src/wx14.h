/*
 * $Id$
 */
#ifndef WX14_H
#define WX14_H

#include <time.h>

/* non-os errors */
#define WX14_ERROR_INVALID_HEADER 1    /* error in bytes 0,1 */
#define WX14_ERROR_INVALID_MSGTYPE 2   /* unrecognized command type */
#define WX14_ERROR_UNEXPECTED_MSGTYPE 3

#define WX14_ERROR_READ_TIMEOUT 4 /* time out (poll) before reading anything */
#define WX14_ERROR_READ_EOF 5     /* eof (server disconnected) */
#define WX14_ERROR_READ_SHORT 6   /* short read (timedout or disconnect)
				   * while reading */

#define WX14_ERROR_EMWIN_BUF 7    /* emwin packet buffer size too small */
#define WX14_ERROR_EMWIN_FILL_PACKET 8  /* error from fill_packet_struct_wx14
					 * function */
#define WX14_ERROR_EMWIN_INCOMPLETEBLOCK 9   /* the start of a block was
					      * received before the current
					      * one ended. */


#define WX14_HEADER_SIZE 5
/*
 * We assume that a wx14 data message is not longer than an emwin
 * data block and the wx14 header
 */
#ifndef EMWIN_BLOCK_SIZE
#define EMWIN_BLOCK_SIZE 1116
#endif
#define WX14_MESSAGE_MAXSIZE (WX14_HEADER_SIZE + EMWIN_BLOCK_SIZE)

struct wx14_signalstatus_st {
  int f_freq;
  int f_viterbi;
  int f_frame;
  int f_mode;
  int level;
  int data_quality;
  int gain;
  int signal_quality;
  int loss_frame;
  int freq_error;
  /* internal variables */
  time_t unixseconds;
  time_t unixseconds_lastlog;
};

struct wx14_msg_st {
  unsigned char message[WX14_MESSAGE_MAXSIZE];
  int msg_type;
  size_t dataN;	/* size of data that starts at message[5] */
  void *data;	/* data = &message[5] */
  int emwin_block_index;  /* used by find_emwin_block() */
  unsigned char emwin_block[EMWIN_BLOCK_SIZE];
  size_t emwin_block_size;
  unsigned char emwin_block_part[EMWIN_BLOCK_SIZE + 6];
  size_t emwin_block_part_size;
  struct wx14_signalstatus_st wx14ss;
};

/* wx14.c  (lower level functions) */
int wx14_read_data_msg(int fd, unsigned int secs, int retry,
		       void *buf, size_t *size, int *type);
int wx14_read_data_msg_emwin(int fd, unsigned int secs, int retry,
			     void *buf, size_t *size);

int wx14_is_emwin_msg(struct wx14_msg_st *wx14msg);
int wx14_is_signalstatus_msg(struct wx14_msg_st *wx14msg);

/* wx14_init.c */
void wx14_init(struct wx14_msg_st *wx14msg);

/* wx14_emwin.c */
int wx14_init_emwin_block(int fd, unsigned int secs, int retry,
			  struct wx14_msg_st *wx14msg);
int wx14_read_emwin_block(int fd, unsigned int secs, int retry,
			  struct wx14_msg_st *wx14msg);
void *wx14_get_emwin_block(struct wx14_msg_st *wx14msg);
int wx14_memcpy_emwin_block(void *buf, size_t *size,
			    struct wx14_msg_st *wx14msg);

/* wx14_ss.c */
int wx14_signalstatus_write(char *file, struct wx14_msg_st *wx14msg);
int wx14_signalstatus_log(char *file, struct wx14_msg_st *wx14msg);
int wx14_signalstatus_fprintf(char *file,
			      struct wx14_msg_st *wx14msg,
			      const char *mode);
#endif
