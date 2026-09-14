"""Render repeatable Oubliette art proofs using PICO-8's own framebuffer."""
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--cart", type=Path, default=root / "pico8/oubliette/oubliette.p8")
parser.add_argument("--output", type=Path, default=root / "game-specs/oubliette/visual-proof/pass-2")
parser.add_argument("--layouts", action="store_true", help="Render generated top-down layouts instead of fixed encounter scenes")
parser.add_argument("--scenes", nargs="+", help="Render only these named scenes")
args = parser.parse_args()
args.output.mkdir(parents=True, exist_ok=True)
source = args.cart.read_text()
setup = '''
_init()
srand(7)
new_run()
fill_map()
px=5 py=10 dir=1
for y=4,10 do set_cell(5,y,tiles.floor) end
mons={} items={}
msg="you step into the damp hall."
msg_t=999
'''
scenes = {name: f"theme={i}" for i, name in enumerate(("crypt", "moss", "brick", "pit"), 1)}
for i, name in enumerate(("rat", "slime", "bat", "skeleton", "goblin", "wraith"), 1):
    scenes[name] = f'mons={{{{x=5,y=9,t={i},hp=8,mhp=8,elite=false}}}}\nmsg="{name} blocks the way."'
scenes["junction"] = "set_cell(4,9,tiles.floor) set_cell(6,8,tiles.floor)"
scenes["adjacent-wall"] = "set_cell(5,9,tiles.wall)"
scenes["wall-one-step-away"] = "set_cell(5,8,tiles.wall)"
scenes["passage-beside-player"] = "set_cell(4,10,tiles.floor)"
scenes["passage-one-step-ahead"] = "set_cell(4,9,tiles.floor)"
for depth, name in ((1,"near"),(2,"middle"),(3,"far")):
    scenes[f"grate-{name}"] = f'set_cell(5,{10-depth},tiles.grate) msg="locked grate"'
scenes["grate-menu"] = 'keys=2 set_cell(5,9,tiles.grate) use_z()'
scenes["grate-menu-break"] = 'set_cell(5,9,tiles.grate) use_z() action_index=2'
scenes["arrival-first"] = 'srand(7) new_run()'
scenes["arrival-second"] = 'floor_n=2 srand(9) new_floor()'
for distance in (0,1,2):
    scenes[f"shaft-{distance}"] = f'for x=3,7 do for y=7,11 do set_cell(x,y,tiles.floor) end end arrival={{x=5,y=9}} py={9+distance} msg="open shaft overhead"'
for depth, name in ((1, "near"), (2, "middle"), (3, "far")):
    scenes[f"chest-{name}"] = f'items={{{{x=5,y={10-depth},t=7}}}} msg="locked chest"'
for name, keys, choice in (("key", 2, 1), ("no-key", 0, 1), ("break", 0, 2), ("leave", 2, 3)):
    scenes[f"chest-menu-{name}"] = f'keys={keys} items={{{{x=5,y=9,t=7}}}} open_actions(items[1]) action_index={choice}'
scenes["chest-menu-attacked"] = '''
items={{x=5,y=10,t=7}}
mons={{x=5,y=9,t=1,hp=8,mhp=8,atk=4,wake=0}}
open_actions(items[1]) action_index=2
local original_rnd=rnd
rnd=function(n) return (n or 1)*.5 end
state="play" break_lock()
rnd=original_rnd
'''
scenes["elite"] = 'mons={{x=5,y=8,t=4,hp=4,mhp=8,elite=true}}'
for mass in (2, 3, 4):
    scenes[f"slime-x{mass}"] = f'mons={{{{x=5,y=9,t=2,hp={7*mass},mhp={7*mass},atk={2*mass},mass={mass},wake=0}}}} msg="slimes combine x{mass}"'
scenes["slime-merge"] = '''
set_cell(6,9,tiles.floor)
mons={{x=5,y=9,t=2,hp=4,mhp=7,atk=2,wake=0},
 {x=6,y=9,t=2,hp=7,mhp=7,atk=2,wake=0}}
listen_turn()
'''
scenes["rest-in-pieces"] = 'hp=1 mons={{x=5,y=9,t=1,hp=8,mhp=8,atk=4,wake=0}} listen_turn()'
scenes["actions-food"] = 'hp=10 open_actions()'
scenes["actions-listen"] = 'hp=10 open_actions() action_index=2'
scenes["actions-no-food"] = 'food=0 open_actions()'
scenes["actions-full-health"] = 'open_actions()'
scenes["title"] = 'state="title"'
scenes["hud-counts"] = 'hp=126 maxhp=131 xp=999 lvl=100 floor_n=100 notches=12 def=9 food=10 pots=8 keys=99 gold=123 msg="chest opens. blade notches +1 and 12 gold."'
scenes["wide-room"] = 'for y=7,10 do for x=3,7 do set_cell(x,y,tiles.floor) end end'
scenes["long-hall"] = 'for y=1,10 do set_cell(5,y,tiles.floor) end'
for depth, name in ((4, "far"), (3, "transition"), (2, "medium")):
    scenes[f"detail-{name}"] = f'''
for y=6,10 do for x=3,7 do set_cell(x,y,tiles.floor) end end
py={5+depth} dir=1
msg="stone ahead."
'''
scenes["room-corner"] = '''
for y=5,10 do
 for x=4,8 do set_cell(x,y,tiles.floor) end
end
for y=5,8 do
 for x=6,8 do set_cell(x,y,tiles.wall) end
end
msg="stone has depth."
'''
scenes["bestiary"] = '''
_draw=function()
 cls(0)
 print("oubliette / bestiary",25,4,13)
 for i=1,6 do
  local x=2+(i-1)%3*42
  local y=16+flr((i-1)/3)*53
  panel(x,y,x+39,y+49,0,5)
  draw_sprite(mon_spr[i],x+4,y+3,32,32,false)
  print(mon_db[i].n,x+7,y+39,6)
 end
 pal(1,129,1) pal(2,133,1) pal(3,131,1)
end
'''
if args.layouts:
    scenes = {}
    for seed in (1, 7, 19, 42):
        scenes[f"layout-{seed}"] = f'srand({seed}) new_run()\n' + '''
_draw=function()
 cls(0)
 print("oubliette / architecture",17,4,13)
 for y=0,mh-1 do
  for x=0,mw-1 do
   local c=cell(x,y)==tiles.wall and 5 or 1
   if cell(x,y)==tiles.grate then c=10 end
   if x==1 and y==1 then c=11 end
   rectfill(16+x*5,15+y*5,20+x*5,19+y*5,c)
  end
 end
 print("green: shaft  gold: grate",13,116,6)
end
'''
    scenes["entrance-7"] = "srand(7) new_run()"
if args.scenes:
    unknown = set(args.scenes) - scenes.keys()
    if unknown:
        parser.error("Unknown scenes: " + ", ".join(sorted(unknown)))
    scenes = {name: scenes[name] for name in args.scenes}
with tempfile.TemporaryDirectory(prefix="oubliette-art-") as tmp:
    for name, scene in scenes.items():
        fixture = setup + scene + '''
view_dirty=true
_draw()
flip()
view_dirty=true
_draw()
printh("warm draw cpu "..stat(1))
flip()
extcmd("screen",4)
_init=nil _draw=nil _update60=nil
'''
        cart = Path(tmp) / f"{name}.p8"
        cart.write_text(source.replace("__gfx__", fixture + "\n__gfx__", 1))
        result = subprocess.run(
            ["/Applications/PICO-8.app/Contents/MacOS/pico8", "-desktop", tmp, "-x", str(cart)],
            capture_output=True, text=True, timeout=15,
        )
        image = Path(tmp) / f"{name}_0.png"
        if result.returncode or not image.exists():
            raise RuntimeError(result.stdout + result.stderr)
        shutil.copyfile(image, args.output / f"{name}.png")
        print(name + ": " + result.stdout.strip().splitlines()[-1])
