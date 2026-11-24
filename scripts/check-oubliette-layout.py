"""Check generated architecture, reachability, grates, and arrival shafts in PICO-8."""
from pathlib import Path
import subprocess
import tempfile
from pico8_check_cart import check_cart

root = Path(__file__).resolve().parents[1]
source = (root / "pico8/oubliette/oubliette.p8").read_text()
checks = r'''
_init()
local loop_floors=0
local tree_floors=0
for seed=1,64 do
 srand(seed)
 floor_n=1+(seed%4)*3
 new_floor()
 assert(arrival.x==px and arrival.y==py and open_cell(arrival.x,arrival.y),"arrival shaft is not at spawn")
 assert(#rooms>=6 and #rooms<=8,"room count")
 assert(#passages>=#rooms-1 and #passages<=#rooms,"connection count")
 if #passages==#rooms then loop_floors+=1 else tree_floors+=1 end
 local queue={{1,1}}
 local distance={[id(1,1)]=0}
 local head=1
 local farthest=0
 while head<=#queue do
  local p=queue[head]
  head+=1
  local next_d=distance[id(p[1],p[2])]+1
  for v in all(dirs) do
   local x,y=p[1]+v[1],p[2]+v[2]
   if open_cell(x,y) and distance[id(x,y)]==nil then
    distance[id(x,y)]=next_d
    farthest=max(farthest,next_d)
    add(queue,{x,y})
   end
  end
 end
 local grates=0
 local floors=0
 for y=0,mh-1 do
  for x=0,mw-1 do
   if x==0 or y==0 or x==mw-1 or y==mh-1 then
    assert(cell(x,y)==tiles.wall,"outer stone breached")
   end
   if open_cell(x,y) then
    floors+=1
    assert(distance[id(x,y)]!=nil,"unreachable floor")
    if cell(x,y)==tiles.grate then
     grates+=1
     assert(distance[id(x,y)]==farthest,"grate not farthest by walking distance")
    end
   else
    assert(not(open_cell(x-1,y) and open_cell(x+1,y)),"one-tile vertical partition")
    assert(not(open_cell(x,y-1) and open_cell(x,y+1)),"one-tile horizontal partition")
   end
  end
 end
 assert(grates==1 and floors==#queue and farthest>=12,"floor traversal")
 for a in all(rooms) do
  for b in all(rooms) do
   if a!=b then
    assert(a.x+a.w+1<b.x or b.x+b.w+1<a.x or a.y+a.h+1<b.y or b.y+b.h+1<a.y,"rooms lack reserved stone")
   end
  end
 end
 local occupied={}
 for group in all({items,mons}) do
  for entity in all(group) do
   local k=id(entity.x,entity.y)
   assert(not occupied[k] and cell(entity.x,entity.y)==tiles.floor,"overlapping/invalid spawn")
   assert(distance[k]!=nil and abs(entity.x-1)+abs(entity.y-1)>4,"unsafe/unreachable spawn")
   occupied[k]=true
  end
 end
end
assert(loop_floors>0 and tree_floors>0,"missing layout variety")
-- Exhaustion must stop placement rather than overlap existing occupants.
srand(9)
new_floor()
place_loot(400)
local count_before=#mons
place_mons(400)
assert(#mons==count_before,"monsters spawned into exhausted floor")
assert(free_floor()==nil,"exhausted floor returned an occupied cell")
new_run()
for y=1,mh-2 do
 for x=1,mw-2 do
  if cell(x,y)==tiles.grate then px=x py=y end
 end
end
use_z()
assert(floor_n==1 and state=="actions" and action_lock.grate,"grate bypasses its lock")
keys=1 mons={} state="play" use_lock_key()
assert(floor_n==2 and px==1 and py==1 and open_cell(px,py),"descent did not create a usable next floor")
assert(arrival.x==px and arrival.y==py and not action_lock,"new floor lost arrival shaft or retained old lock")
printh("LAYOUT PASS: 64 seeds, floors 1/4/7/10; connected rooms, thick partitions, farthest grates, arrival shafts, valid spawns, exhaustion, locked descent; loops="..loop_floors.." trees="..tree_floors)
_init=nil _draw=nil _update60=nil
'''
with tempfile.TemporaryDirectory(prefix="oubliette-layout-") as tmp:
    cart = Path(tmp) / "check.p8"
    cart.write_text(check_cart(source, checks))
    result = subprocess.run(
        ["/Applications/PICO-8.app/Contents/MacOS/pico8", "-x", str(cart)],
        capture_output=True, text=True, timeout=60,
    )
    print(result.stdout, end="")
    print(result.stderr, end="")
    assert result.returncode == 0 and "LAYOUT PASS" in result.stdout, "Layout checks failed"
