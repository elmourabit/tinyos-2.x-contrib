/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

#include <IPDispatch.h>
#include <lib6lowpan.h>
#include <ip.h>

#include "UDPReport.h"
#include "PrintfUART.h"

//// added header file for UserButtonC
//#include <UserButton.h>

#define REPORT_PERIOD 15L

module UDPEchoP {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;

    interface UDP as Echo;
    interface UDP as Status;

    interface Leds;
    
    interface Timer<TMilli> as StatusTimer;
   
    interface Statistics<ip_statistics_t> as IPStats;
    interface Statistics<route_statistics_t> as RouteStats;
    interface Statistics<icmp_statistics_t> as ICMPStats;

    interface Random;

    interface Timer<TMilli> as DebugTimer;

    //// added the interface for UserButtonC
    //interface Get<button_state_t>;
    //interface Notify<button_state_t>;
  }

} implementation {

  bool timerStarted;
  udp_statistics_t stats;
  struct sockaddr_in6 route_dest;

  event void Boot.booted() {
    call RadioControl.start();
    call StatusTimer.startOneShot(call Random.rand16() % (1024 * REPORT_PERIOD));
    timerStarted = FALSE;

    call IPStats.clear();
    call RouteStats.clear();
    call ICMPStats.clear();
    printfUART_init();

    stats.total = 0;
    stats.failed = 0;

    route_dest.sin_port = hton16(7000);
    inet6_aton("2001:470:1f04:56d::64", route_dest.sin_addr);

    // Timer period can be changed.
    // This value is 5000 for xml.01
    // and 1000 for all others
    call DebugTimer.startPeriodic(1000);  

    //// Enable UserButtonC
    //call Notify.enable();
  }

  //// event handler for Notify.notify()
  //event void Notify.notify(button_state_t state) {
  //  if (state == BUTTON_PRESSED) {
  //    call Leds.led2On();
  //  } 
  //  else if (state == BUTTON_RELEASED) {
  //    call Leds.led2Off();
  //  }
  //}

  event void RadioControl.startDone(error_t e) {

  }

  event void RadioControl.stopDone(error_t e) {

  }

  event void Status.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip_metadata *meta) {

  }

  event void Echo.recvfrom(struct sockaddr_in6 *from, void *data, 
                           uint16_t len, struct ip_metadata *meta) {
    call Echo.sendto(from, data, len);
  }

  enum {
    STATUS_SIZE = sizeof(ip_statistics_t) + sizeof(route_statistics_t) 
    + sizeof(icmp_statistics_t) + sizeof(udp_statistics_t),
  };

  event void DebugTimer.fired() {
    call Leds.led1Toggle();
    // This can be commented out
    // Comment this line for xml.02
    call Leds.led2Toggle();
  }

  event void StatusTimer.fired() {
    uint8_t status[STATUS_SIZE];
    struct udp_report *payload;
    
    call Leds.led0Toggle();

    stats.total++;
    
    if (!timerStarted) {
      call StatusTimer.startPeriodic(1024 * REPORT_PERIOD);
      timerStarted = TRUE;
    }

    payload = (struct udp_report *)status;
    
    stats.seqno++;
    stats.sender = TOS_NODE_ID;

    memcpy(&payload->ip,    call IPStats.get(),    sizeof(ip_statistics_t));
    memcpy(&payload->route, call RouteStats.get(), sizeof(route_statistics_t));
    memcpy(&payload->icmp,  call ICMPStats.get(),  sizeof(icmp_statistics_t));
    memcpy(&payload->udp,   &stats,                sizeof(udp_statistics_t));

    call Status.sendto(&route_dest, status, STATUS_SIZE);
  }
}