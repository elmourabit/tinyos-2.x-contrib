/* Copyright (c) 2007 ETH Zurich.
*  All rights reserved.
*
*  Redistribution and use in source and binary forms, with or without
*  modification, are permitted provided that the following conditions
*  are met:
*
*  1. Redistributions of source code must retain the above copyright
*     notice, this list of conditions and the following disclaimer.
*  2. Redistributions in binary form must reproduce the above copyright
*     notice, this list of conditions and the following disclaimer in the
*     documentation and/or other materials provided with the distribution.
*  3. Neither the name of the copyright holders nor the names of
*     contributors may be used to endorse or promote products derived
*     from this software without specific prior written permission.
*
*  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS `AS IS'
*  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
*  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
*  ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR CONTRIBUTORS
*  BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
*  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE, DATA,
*  OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
*  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
*  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
*  THE POSSIBILITY OF SUCH DAMAGE.
*
*  For additional information see http://www.btnode.ethz.ch/
* 
*  @author: Roman Lim <lim@tik.ee.ethz.ch>
*
*/

#ifndef NEIGHBOURSYNC_H
#define NEIGHBOURSYNC_H

#include <AM.h>
#include "CC2420.h"

enum {
  NEIGHBOURSYNCTABLESIZE = 10, // size of sync neighbour table
  MEASURE_HISTORY_SIZE = 4,
  NO_VALID_OFFSET = 0xffff,
  NO_VALID_DRIFT = 32767,
  NO_ENTRY = 0xff,
  NO_SYNC = 0xffffffff,
  T32KHZ_TO_TMILLI_SHIFT = 5, // factor for conversion TMilli > T32khz

  RADIO_STARTUP_OFFSET = 400, // jiffys until the radio is started and FIFO is loaded, should be calculated from packet length
  REVERSE_SEND_OFFSET = 65, //use 80 if no initial backoff  // less means: transmission begins earlier 
  NO_COMPENSATION_OFFSET = 50,  // less means: transmission begins later. This offset is used to begin transmission earlier when no compensation is done

  ALARM_OFFSET = RADIO_STARTUP_OFFSET,
  AGING_PERIOD = 10,
  TOTAL_AGING_PERIOD = NEIGHBOURSYNCTABLESIZE * AGING_PERIOD, // after AGING_PERIOD packets, each usageCounter is decremented by AGING_PERIOD / 16
  

  SYNC_FAIL_THRESHOLD = 10, // after SYNC_FAIL_THRESHOLD non-acked packets, sync information is not valid anymore
  REQ_SYNC_FLAG = 0x8000,
  SYNC_TIMER_PERIOD = 30000UL, // period to gather sync-requests in milliseconds
  DRIFT_CHANGE_LIMIT = 50, 	// value >> 21 that a new measured drift is allowed to differ from the last average
  							// 50 is about 23ppm
  MAX_DRIFT_ERRORS = 5,	// number of false drifts until history is cleared, e.g. when neihgbour node has resetted
  MIN_MEASUREMENT_PERIOD = 32768U, // minimal drift measurement period in ticks
  
  RESYNC_AM_TYPE = 26, 
};

typedef struct {	// 16 + MEASURE_HISTORY_SIZE * 4 bytes
  am_addr_t address; // 0
  uint32_t wakeupTimestamp[MEASURE_HISTORY_SIZE]; // 2
  uint32_t wakeupAverage; // 18
  bool odd; // 22
  uint8_t measurementCount; // 23
  uint16_t usageCount; // 24
  uint8_t failCount; // 26
  uint8_t driftLimitCount; // 27
  uint16_t lplPeriod; // in ms 28
  int16_t drift; // 30
  bool dirty; // 32
  // align to word address -> struct size = 34, when MEASURE_HISTORY_SIZE==4
} neighbour_sync_item_t;

typedef nx_struct {
  nx_uint16_t wakeupOffset;
  nx_uint16_t lplPeriod;	// this field contains REQ_SYNC_FLAG (highest bit) and lpl information
} neighbour_sync_header_t;

#endif