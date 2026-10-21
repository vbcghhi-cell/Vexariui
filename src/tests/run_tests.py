"""Runs tests/vexari/test_vexari.lua on a real Lua 5.4 VM (system liblua5.4 via ctypes) with a mocked Roblox API.

    python3 tests/vexari/run_tests.py

What it covers : Background.Parse, the background manager (apply / reset / cancel / failure / decal fallback /
                 timeouts / URL download), the font registry and the Settings tab wiring.
What it does NOT cover: real Roblox rendering, real ContentProvider / ImageLabel behaviour, real executors.
Requires       : Linux with liblua5.4 (e.g. `apt install liblua5.4-0`).
"""
import os, sys
here = os.path.dirname(os.path.abspath(__file__))
root = os.path.abspath(os.path.join(here, "..", ".."))
sys.path.insert(0, here)
from lua54 import Lua

code = 'ROOT=%r\n' % root.replace("\\", "/") + open(os.path.join(here, "test_vexari.lua"), encoding="utf-8").read()
result = Lua().run(code, "test_vexari")
print(result)
sys.exit(0 if " 0 failed" in result.splitlines()[-1] else 1)
