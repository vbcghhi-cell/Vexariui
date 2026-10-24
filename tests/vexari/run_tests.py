"""Runs the tests in tests/vexari/*.lua on a real Lua 5.4 VM (system liblua5.4 via ctypes) with a mocked Roblox API.

    python3 tests/vexari/run_tests.py

test_vexari.lua    background image system, font registry, Settings tab wiring
test_dashboard.lua Status (fps / ping), Chip, StatCard, ProfileCard, PageHeader, the Stats / Profile / Header
                   elements and the OpenButton status row (builds every component on a fake Instance tree)

What it covers : logic, state handling and that every constructor runs without errors.
What it does NOT cover: how anything looks in Roblox, real ContentProvider / ImageLabel behaviour, real executors.
Requires       : Linux with liblua5.4 (e.g. `apt install liblua5.4-0`).
"""
import glob, os, sys
here = os.path.dirname(os.path.abspath(__file__))
root = os.path.abspath(os.path.join(here, "..", ".."))
sys.path.insert(0, here)
from lua54 import Lua

failed = False
for path in sorted(glob.glob(os.path.join(here, "test_*.lua"))):
    name = os.path.basename(path)
    code = 'ROOT=%r\n' % root.replace("\\", "/") + open(path, encoding="utf-8").read()
    try:
        result = Lua().run(code, name)
    except Exception as error:  # syntax or harness error
        result = "ERROR: %s" % error
    last = result.splitlines()[-1] if result else ""
    print("== %s" % name)
    print(result)
    if " 0 failed" not in last:
        failed = True

sys.exit(1 if failed else 0)
