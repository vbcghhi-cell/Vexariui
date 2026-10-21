"""Minimal Lua 5.4 runner over the system liblua5.4 via ctypes (no headers / no interpreter binary needed)."""
import ctypes
L5=ctypes.CDLL('liblua5.4.so.0')
L5.luaL_newstate.restype=ctypes.c_void_p
L5.luaL_openlibs.argtypes=[ctypes.c_void_p]
L5.luaL_loadstring.argtypes=[ctypes.c_void_p,ctypes.c_char_p]
L5.luaL_loadstring.restype=ctypes.c_int
L5.luaL_loadbufferx.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_size_t,ctypes.c_char_p,ctypes.c_char_p]
L5.lua_pcallk.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.c_int,ctypes.c_int,ctypes.c_void_p,ctypes.c_void_p]
L5.lua_pcallk.restype=ctypes.c_int
L5.lua_tolstring.argtypes=[ctypes.c_void_p,ctypes.c_int,ctypes.POINTER(ctypes.c_size_t)]
L5.lua_tolstring.restype=ctypes.c_char_p
L5.lua_settop.argtypes=[ctypes.c_void_p,ctypes.c_int]
L5.lua_gettop.argtypes=[ctypes.c_void_p]

class Lua:
    def __init__(self):
        self.L=L5.luaL_newstate(); L5.luaL_openlibs(self.L)
    def run(self,code,name='chunk'):
        code=code.encode() if isinstance(code,str) else code
        L5.lua_settop(self.L,0)
        if L5.luaL_loadbufferx(self.L,code,len(code),name.encode(),None)!=0:
            msg=L5.lua_tolstring(self.L,-1,None).decode(errors='replace'); L5.lua_settop(self.L,0)
            raise SyntaxError(msg)
        if L5.lua_pcallk(self.L,0,1,0,None,None)!=0:
            msg=L5.lua_tolstring(self.L,-1,None).decode(errors='replace'); L5.lua_settop(self.L,0)
            raise RuntimeError(msg)
        r=L5.lua_tolstring(self.L,-1,None)
        L5.lua_settop(self.L,0)
        return r.decode(errors='replace') if r is not None else None

def syntax_check(path):
    """Compile only (Lua 5.4 grammar). Valid for files that use no Luau-only syntax."""
    code=open(path,'rb').read()
    L=Lua()
    if L5.luaL_loadbufferx(L.L,code,len(code),path.encode(),None)!=0:
        return L5.lua_tolstring(L.L,-1,None).decode(errors='replace')
    return None
