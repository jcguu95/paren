#include <stdio.h>

enum { moving_up, moving_down, door_open, door_closing, door_opening, emergency, idle };

enum { evt_btn_up, evt_btn_down, evt_btn_open, evt_arrived, evt_fully_open, evt_timeout, evt_btn_close, evt_emergency, evt_fully_closed, evt_obstacle, evt_reset, evt_maintenance };

int elevator_next (int state, int event) {
  switch (state) {
    case moving_up:
      if (((event) == (evt_arrived))) {
        return (door_opening);
      }
      if (((event) == (evt_emergency))) {
        return (emergency);
      }
      break;
    case moving_down:
      if (((event) == (evt_arrived))) {
        return (door_opening);
      }
      if (((event) == (evt_emergency))) {
        return (emergency);
      }
      break;
    case door_open:
      if (((event) == (evt_timeout))) {
        return (door_closing);
      }
      if (((event) == (evt_btn_close))) {
        return (door_closing);
      }
      if (((event) == (evt_emergency))) {
        return (emergency);
      }
      break;
    case door_closing:
      if (((event) == (evt_fully_closed))) {
        return (idle);
      }
      if (((event) == (evt_obstacle))) {
        return (door_opening);
      }
      break;
    case door_opening:
      if (((event) == (evt_fully_open))) {
        return (door_open);
      }
      break;
    case emergency:
      if (((event) == (evt_reset))) {
        return (idle);
      }
      if (((event) == (evt_maintenance))) {
        return (idle);
      }
      break;
    case idle:
      if (((event) == (evt_btn_up))) {
        return (moving_up);
      }
      if (((event) == (evt_btn_down))) {
        return (moving_down);
      }
      if (((event) == (evt_btn_open))) {
        return (door_opening);
      }
      break;
    default:
      return (state);
      break;
  }
}

int main () {
  int state = idle;
  state = elevator_next(state, evt_btn_up);
  printf("state=%d\n", state);
  return (0);
}


