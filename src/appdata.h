/*
 * Copyright (c) 2005-2007 Jose F. Nieves <nieves@ltp.upr.clu.edu>
 *
 * See LICENSE
 *
 * $Id$
 */
#ifndef APPDATA_H
#define APPDATA_H

#include "libconnth/conn.h"
#include "const.h"

int ident_client_protocol(struct conn_table_st *ct, int i,
			  char *msg, size_t msg_size);

int get_client_protocol(struct conn_table_st *ct, int i);
int get_client_protocol_byce(struct conn_element_st *ce);

#endif
