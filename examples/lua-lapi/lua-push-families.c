#include <stdarg.h>
#include <stddef.h>
#include <string.h>

#include "lprefix.h"
#include "lua.h"
#include "lapi.h"
#include "ldebug.h"
#include "ldo.h"
#include "lgc.h"
#include "lobject.h"
#include "lstate.h"
#include "lstring.h"
#include "ltable.h"
#include "ltm.h"
#include "lvm.h"

void lua_pushnumber (lua_State *(l), lua_Number n) {
  lua_lock(l);
  setfltvalue(s2v(l->top.p), n);
  api_incr_top(l);
  lua_unlock(l);
}

void lua_pushinteger (lua_State *(l), lua_Integer n) {
  lua_lock(l);
  setivalue(s2v(l->top.p), n);
  api_incr_top(l);
  lua_unlock(l);
}

void lua_pushlightuserdata (lua_State *(l), void *(p)) {
  lua_lock(l);
  setpvalue(s2v(l->top.p), p);
  api_incr_top(l);
  lua_unlock(l);
}

lua_Number lua_tonumberx (lua_State *(l), int idx, int *(pisnum)) {
  lua_Number n = 0;
  TValue *(o) = index2value(l, idx);
  int isnum = tonumber(o, &n);
  if (((pisnum) != (0))) {
    *pisnum = isnum;
  }
  if (isnum) {
    return (n);
  }
  return (0);
}

lua_Integer lua_tointegerx (lua_State *(l), int idx, int *(pisnum)) {
  lua_Integer n = 0;
  TValue *(o) = index2value(l, idx);
  int isnum = tointeger(o, &n);
  if (((pisnum) != (0))) {
    *pisnum = isnum;
  }
  if (isnum) {
    return (n);
  }
  return (0);
}

#undef lua_isfunction

#undef lua_istable

#undef lua_islightuserdata

#undef lua_isnil

#undef lua_isboolean

#undef lua_isthread

int lua_isfunction (lua_State *(l), int idx) {
  return (((lua_type(l, idx)) == (LUA_TFUNCTION)));
}

int lua_istable (lua_State *(l), int idx) {
  return (((lua_type(l, idx)) == (LUA_TTABLE)));
}

int lua_islightuserdata (lua_State *(l), int idx) {
  return (((lua_type(l, idx)) == (LUA_TLIGHTUSERDATA)));
}

int lua_isnil (lua_State *(l), int idx) {
  return (((lua_type(l, idx)) == (LUA_TNIL)));
}

int lua_isboolean (lua_State *(l), int idx) {
  return (((lua_type(l, idx)) == (LUA_TBOOLEAN)));
}

int lua_isthread (lua_State *(l), int idx) {
  return (((lua_type(l, idx)) == (LUA_TTHREAD)));
}


