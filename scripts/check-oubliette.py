"""Run Oubliette's renderer checks in PICO-8; no third-party dependencies."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
cart = (root / "pico8/oubliette/oubliette.p8").read_text()
checks = r'''
original_init=_init
function _init()
 original_init()
 for seed=1,2 do
  srand(seed)
  new_run()
  local x,y=front(1)
  assert(open_cell(x,y),"spawn faces wall")
  for t=1,4 do
   theme=t
   for facing=t,t do
    dir=facing
    srand(99)
    local expected=rnd()
    srand(99)
    view_dirty=true
    _draw()
    assert(rnd()==expected,"renderer changed gameplay rng")
    assert(pget(0,vy0-1)==5,"viewport frame overwritten")
   end
  end
 end
 fill_map()
 px=5 py=10 dir=1
 for y=4,10 do set_cell(5,y,tiles.floor) end
 items={}
 for kind=1,6 do
  for depth=1,4 do
   mons={{x=5,y=10-depth,t=kind,hp=4,mhp=8,elite=depth==2}}
   srand(99)
   local expected=rnd()
   srand(99)
   flip()
   view_dirty=true
   _draw()
   assert(stat(1)<.5,"warm renderer exceeds half cpu budget")
   assert(rnd()==expected,"monster renderer changed rng")
   assert(pget(0,vy0-1)==5,"monster overlaps viewport frame")
  end
 end
 assert(sget(6,81)!=0,"avatar atlas was overwritten")
 -- UI and world rows must retain separate palettes after every sprite reset.
 for screen in all({"play","title","dead"}) do
  state=screen rest_death=true view_dirty=true
  _draw()
  assert(peek(0x5f5f)==0x10,"scanline palette disabled")
  for y=0,127 do
   local alternate=(peek(0x5f70+flr(y/8))&(1<<(y%8)))!=0
   assert(alternate==(y>=vy0 and y<=vy1),"palette crosses HUD boundary")
  end
  for c=0,15 do
   assert(peek(0x5f60+c)==world_palette[c+1],"world palette overwritten by drawing")
  end
  for c in all({0,1,4,5,6,7,8,9,10}) do
   assert(peek(0x5f10+c)==peek(0x5f60+c),"overlay colour changes across bands")
  end
  assert(peek(0x5f10+12)==12 and peek(0x5f10+13)==13,"HUD colours remapped")
 end
 state="play" rest_death=false
 bar(20,20,20,3,0,12)
 for y=20,23 do
  for x=20,40 do assert(pget(x,y)!=12,"empty bar shows progress") end
 end
 -- Measure the fade on a flat patch: clear nearby, then monotonic darkness.
 local remaining=16
 for step=0,16 do
  rectfill(20,20,23,23,7)
  darken(20,20,23,23,2+step*6/16)
  local lit=0
  for y=20,23 do
   for x=20,23 do if pget(x,y)==7 then lit+=1 end end
  end
  assert(lit==16-step and lit<=remaining,"distance fade coverage")
  remaining=lit
 end
 rectfill(20,20,23,23,7)
 for y=20,23 do
  for x=20,23 do assert(pget(x,y)==7,"fade leaked into later drawing") end
 end
 -- Distinguishable atlas colours expose any abrupt medium/far switch.
 mons={} items={}
 for v=48,79 do
  for u=32,127 do sset(u,v,u<64 and 2 or 1) end
 end
 local original_cast=cast_wall
 local test_depth=1.5
 cast_wall=function(sx) return {d=test_depth,u=.25,side=false,key=1} end
 local previous=256
 for step=0,16 do
  test_depth=1.5+step/8
  flip()
  draw_view()
  local medium=0
  for y=view_cy-6,view_cy+9 do
   for x=view_cx-8,view_cx+7 do if pget(x,y)==2 then medium+=1 end end
  end
  assert(medium<=previous and previous-medium<=32,"wall detail switches abruptly")
  if step==0 then assert(medium==256,"near masonry changed") end
  if step==8 then assert(medium>0 and medium<256,"missing intermediate masonry") end
  if step==16 then assert(medium==0,"far masonry changed") end
  previous=medium
 end
 cast_wall=original_cast
 backdrop_theme=nil
 for message in all({"3 gold","chest: 12 gold","level 2","rat hits -3","hit rat -4","shield +1","blade notches +1","you fall on floor 2"}) do
  say(message)
  _draw()
 end
 printh("OUBLIETTE PASS: rendering, palettes, overlays, bars, detail blend, distance fade")
end
_init()
_init=nil _draw=nil _update60=nil
'''
geometry_checks = r'''
original_init=_init
function _init()
 original_init()
 new_run()
 -- Check first-hit geometry against movement in all orientations.
 for facing=1,4 do
  fill_map()
  px=9 py=9 dir=facing shake=0
  mons={} items={}
  set_cell(px,py,tiles.floor)
  local nx,ny=front(1)
  set_cell(nx,ny,tiles.floor)
  local sx,sy=front(0,-1)
  set_cell(sx,sy,tiles.floor)
  draw_view()
  assert(wall_depth[view_cx]==1.5,"wall drawn one tile out of step")
  local r=rect_for_depth(2)
  local one_step_width=r[3]-r[1]
  local beside=cast_wall(1).d
  set_cell(sx,sy,tiles.wall)
  assert(cast_wall(1).d<beside,"current-tile opening has no depth")
  set_cell(sx,sy,tiles.floor)
  walk(1)
  draw_view()
  assert(px==nx and py==ny and wall_depth[view_cx]==.5,"camera did not advance with player")
  r=rect_for_depth(1)
  assert(r[1]<=view_cx-38 and r[3]>=view_cx+38 and r[4]>=vy1,"adjacent wall looks distant")
  local adjacent_width=r[3]-r[1]
  assert(one_step_width/adjacent_width>=.45 and one_step_width/adjacent_width<=.6,"one step recedes too sharply")
  walk(1)
  assert(px==nx and py==ny,"adjacent wall did not block movement")
 end
 -- A room corner must expose both the end face and the receding side.
 fill_map()
 px=5 py=10 dir=1 shake=0
 for y=5,10 do
  for x=4,8 do set_cell(x,y,tiles.floor) end
 end
 for y=5,8 do
  for x=6,8 do set_cell(x,y,tiles.wall) end
 end
 local end_face=cast_wall(view_cx+26)
 local side_face=cast_wall(view_cx+16)
 assert(end_face.y==8 and not end_face.side,"missing wall end face")
 assert(side_face.x==6 and side_face.side,"missing receding wall side")
 -- Compare every column against a small independent forward ray march.
 for facing=1,4 do
  dir=facing
  local f=dirs[dir]
  local right=dirs[dir%4+1]
  for sx=vx0,vx1 do
   local hit=cast_wall(sx)
   local slope=(sx-view_cx)/38
   local d=.005
   local x,y=px,py
   while cell(x,y)!=tiles.wall do
    x=flr(px+.5+f[1]*d+right[1]*slope*view_z(d))
    y=flr(py+.5+f[2]*d+right[2]*slope*view_z(d))
    d+=.005
   end
   assert(abs(hit.d-d)<.02,"ray skipped first wall")
  end
 end
 -- Geometry must hide entities behind a solid wall without changing pixels.
 dir=1 mons={} items={}
 draw_view()
 memcpy(0xa000,0x6000,0x2000)
 mons={{x=7,y=7,t=4,hp=8,mhp=8,elite=false}}
 set_cell(7,7,tiles.grate)
 draw_view()
 for a=0,0x1fff do
  assert(peek(0x6000+a)==peek(0xa000+a),"entity leaks through wall")
 end
 printh("OUBLIETTE PASS: geometry, occlusion, movement")
end
_init()
_init=nil
_draw=nil
_update60=nil
'''
mechanics_checks = r'''
_init()
new_run()
 fill_map()
 px=9 py=9 dir=1 shake=0
 set_cell(px,py,tiles.floor)
 set_cell(9,8,tiles.floor)
 mons={{x=9,y=8,t=4,hp=100,mhp=100,atk=0,wake=0,elite=false}}
 local target=mons[1]
 walk(1)
 assert(px==9 and py==9 and target.hp<100,"adjacent encounter does not match bump range")
 local before=target.hp
 use_z()
 assert(target.hp<before,"adjacent encounter does not match action range")
 -- Isolate player damage while still checking one monster phase per throw.
 local act=monsters_act
 local phases=0
 monsters_act=function() phases+=1 end
 new_run()
 assert(notches==0,"new run retains ammunition")
 fill_map()
 px=9 py=9 dir=1
 for y=3,9 do set_cell(9,y,tiles.floor) end
 items={} mons={} pots=0
 local blade={x=9,y=9,t=4}
 items={blade}
 take_item(blade)
 assert(notches==1 and atk==4 and #items==0,"blade pickup does not accumulate separately")
 notches=3 atk=50 lvl=10
 local target={x=9,y=5,t=4,hp=20,mhp=20,elite=true}
 mons={target}
 local before_turn=turns
 use_z()
 use_z()
 assert(target.hp==18 and notches==1,"throw includes attack bonus or consumes wrong amount")
 assert(turns==before_turn+2 and phases==2,"throw does not spend exactly one turn")
 set_cell(9,7,tiles.wall)
 use_z()
 assert(target.hp==18 and notches==1,"throw crosses wall")
 set_cell(9,7,tiles.floor)
 target.y=4
 use_z()
 assert(target.hp==18 and notches==1,"throw exceeds visible range")
 target.y=5
 local near={x=9,y=8,t=1,hp=10,mhp=10,elite=false}
 mons={target,near}
 use_z()
 assert(near.hp==9 and target.hp==18 and notches==0,"throw misses first enemy")
 near.hp=100
 use_z()
 assert(near.hp<99 and notches==0,"empty inventory breaks adjacent melee")
 notches=2 near.hp=100
 walk(1)
 assert(near.hp<99 and notches==2,"bump attack spends ammunition")
 near.hp=1
 local old_xp=xp
 use_z()
 assert(near.hp==0 and notches==1 and xp>old_xp,"thrown kill loses reward")
 monsters_act=act
 -- Rest exposes the player on every side without attacking or recovering.
 for facing=1,4 do
  dir=facing
  local x,y=front(1)
  local enemy={x=x,y=y,t=1,hp=10,mhp=10,atk=4,wake=0}
  mons={enemy}
  hp=10 maxhp=26 food=3 def=0 notches=2
  local before_turn=turns
  eat_food()
  assert(hp<10 and food==3,"combat rest recovers or wastes ration")
  assert(enemy.hp==10 and notches==2,"rest attacks enemy")
  assert(px==9 and py==9 and turns==before_turn+1,"rest moves or spends wrong turn count")
 end
 mons[1].hp=0
 hp=10 lvl=1
 eat_food()
 assert(hp==13 and food==2,"dead enemy prevents safe rest")
 mons={} food=0 hp=10
 listen_turn()
 assert(hp==10 and food==0,"empty rest grants recovery")
 mons={{x=9,y=8,t=1,hp=100,mhp=100,atk=4,wake=0}}
 hp=1
 listen_turn()
 assert(state=="dead" and rest_death,"fatal rest misses achievement")
 view_dirty=true
 _draw()
 new_run()
 assert(not rest_death,"achievement persists into new run")
 fill_map() px=9 py=9 dir=1
 set_cell(9,9,tiles.floor) set_cell(9,8,tiles.floor)
 mons={} food=0 hp=10
 listen_turn()
 mons={{x=9,y=8,t=1,hp=100,mhp=100,atk=4,wake=0}}
 hp=1
 walk(1)
 assert(state=="dead" and not rest_death,"later combat death gets rest achievement")
 printh("OUBLIETTE PASS: blade pickup/throws/range/walls/first target/turns/melee/rewards, combat and safe eating/listening")
_init=nil
_draw=nil
_update60=nil
'''
# Separate carts keep the combined game and check code below 8192 tokens.
combat_checks = r'''
_init()
 -- Either rotation gives a pursuer one move, then one attack when adjacent.
 for rotate in all({turn_left,turn_right}) do
  new_run()
  fill_map() px=9 py=9 dir=1
  for y=7,9 do set_cell(9,y,tiles.floor) end
  items={} notches=2
  local enemy={x=9,y=7,t=1,hp=10,mhp=10,atk=4,wake=0}
  mons={enemy}
  rotate()
  assert(dir==(rotate==turn_left and 4 or 2),"rotation changes wrong heading")
  assert(enemy.x==9 and enemy.y==8 and hp==26 and turns==1,"rotation skips or doubles enemy move")
  rotate()
  assert(hp>=20 and hp<=22 and turns==2,"rotation skips or doubles adjacent attack")
  assert(px==9 and py==9 and food==3 and notches==2 and enemy.hp==10,"rotation moves, heals, or attacks")
 end
 -- A second key pressed with a fatal rotation cannot act after death.
 new_run()
 fill_map() px=9 py=9 dir=1 hp=1 notches=2
 set_cell(9,9,tiles.floor) set_cell(8,9,tiles.floor)
 mons={{x=8,y=9,t=1,hp=10,mhp=10,atk=4,wake=0}}
 local original_btnp=btnp
 btnp=function(n) return n==0 or n==1 or n==4 end
 _update60()
 btnp=original_btnp
 assert(state=="dead" and not rest_death and dir==4 and turns==1,"simultaneous keys spend another turn after death")
 assert(notches==2 and mons[1].hp==10,"simultaneous action attacks after fatal rotation")
 -- Compare identical attack rolls from all sides, with and without armour.
 for facing=1,4 do
  new_run()
  px=9 py=9 dir=facing
  local fx,fy=front(1)
  local enemy={x=fx,y=fy,t=1,hp=100,mhp=100,atk=4,wake=0}
  mons={enemy}
  for armour in all({0,100}) do
   def=armour hp=26 enemy.x=fx enemy.y=fy
   srand(21) monsters_act()
   local frontal=26-hp
   if armour==100 then assert(frontal==1,"frontal defence changed") end
   for side=1,4 do
    enemy.x=9+dirs[side][1] enemy.y=9+dirs[side][2]
    hp=26 srand(21) monsters_act()
    assert(26-hp==frontal+(side==facing and 0 or 1),"side/rear bonus is not exactly +1 after defence")
    assert(msg=="rat "..(side==facing and "hits -" or "flanks -")..(26-hp),"damage message hides facing bonus")
   end
  end
  -- Backward collision spends one enemy turn, never a player attack.
  new_run()
  fill_map() px=9 py=9 dir=facing notches=2
  fx,fy=front(1)
  local bx,by=front(-1)
  set_cell(px,py,tiles.floor)
  set_cell(fx,fy,tiles.floor) set_cell(bx,by,tiles.floor)
  enemy={x=bx,y=by,t=1,hp=100,mhp=100,atk=4,wake=0}
  mons={enemy} items={}
  walk(-1)
  assert(px==9 and py==9 and dir==facing and turns==1,"blocked retreat moves or spends wrong turns")
  assert(enemy.hp==100 and notches==2 and food==3 and hp<26,"backing into enemy attacks or skips retaliation")
  enemy.x=fx enemy.y=fy
  walk(1)
  assert(enemy.hp<100 and px==9 and py==9 and turns==2,"forward bump attack changed")
  mons={}
  walk(-1)
  assert(px==bx and py==by and dir==facing and turns==3,"clear backward movement changed")
 end
 printh("OUBLIETTE PASS: rotation enemy moves/attacks/death, simultaneous inputs, facing damage/messages/armour, blocked retreat, forward bump, clear retreat")
_init=nil
_draw=nil
_update60=nil
'''
menu_checks = r'''
_init()
new_run()
fill_map() px=9 py=9 dir=1 hp=10 notches=2
for y=7,9 do set_cell(9,y,tiles.floor) end
local enemy={x=9,y=7,t=1,hp=100,mhp=100,atk=4,wake=0}
mons={enemy} items={}
local old_btnp,old_btn=btnp,btn
local key=-1
btnp=function(n) return n==key end
btn=function(n) return n==key end
function press(n)
 key=n _update60()
 key=-1 _update60()
end
srand(21) local expected=rnd() srand(21)
press(5)
assert(state=="actions" and #action_list==2 and action_list[1].n=="eat" and action_list[2].n=="listen","food menu choices")
press(3) assert(action_index==2,"down does not choose listen")
press(2) assert(action_index==1,"up does not choose eat")
press(2) assert(action_index==2,"menu selection does not wrap")
press(0) press(1)
assert(dir==1 and px==9 and py==9,"menu arrows move player")
view_dirty=true _draw()
assert(peek(0x5f5f)==0x10 and peek(0x5f60+13)==world_palette[14],"menu changes dungeon palette")
assert(rnd()==expected,"menu consumes gameplay rng")
press(5)
assert(state=="play" and turns==0 and enemy.y==7 and hp==10 and food==3,"menu opening/navigation/cancel spends resources or enemy turn")
-- Held menu/confirm keys must not cancel or trigger a gameplay action.
key=5 _update60() _update60()
assert(state=="actions" and turns==0,"held X closes menu")
key=-1 _update60()
press(3)
key=4 _update60() _update60()
assert(state=="play" and turns==1 and enemy.y==8,"listen skips or doubles enemy move")
assert(food==3 and hp==10 and notches==2 and enemy.hp==100,"listen consumes food/heals or held Z attacks")
key=-1 _update60()
press(5) press(4)
assert(food==3 and hp<10 and turns==2 and enemy.hp==100,"combat eating heals, attacks, or wastes food")
hp=1
press(5) press(3) press(4)
assert(state=="dead" and rest_death and food==3 and turns==3,"fatal listen loses rest achievement")
press(4)
assert(state=="play" and not rest_death,"restart retains menu/death state")
mons={} items={} hp=10 maxhp=31 lvl=2 food=1
press(5) press(4)
assert(state=="play" and hp==14 and food==0 and turns==1,"eat does not heal/consume exactly once")
press(5)
assert(#action_list==1 and action_list[1].n=="listen","empty inventory still offers eat")
press(2) press(3)
assert(action_index==1,"single-action menu selection escapes list")
press(4)
assert(food==0 and hp==14 and turns==2,"empty-inventory listen changes supplies or healing")
hp=maxhp food=2
press(5) press(4)
assert(food==2 and hp==maxhp and turns==3,"full-health eating wastes food or skips turn")
hp=maxhp-1
press(5) press(4)
assert(food==1 and hp==maxhp and turns==4,"eating exceeds maxhp")
btnp=old_btnp btn=old_btn
printh("OUBLIETTE PASS: action menu choices/navigation/cancel/palette/RNG, held keys, listen with food, eating/supplies/combat/full health, fatal listen/restart")
_init=nil _draw=nil _update60=nil
'''
chest_checks = r'''
_init()
local old_btnp,old_btn,old_rnd=btnp,btn,rnd
local key=-1
btnp=function(n) return n==key end
btn=function(n) return n==key end
function press(n)
 key=n _update60()
 key=-1 _update60()
end
function chest_scene()
 new_run() fill_map() px=9 py=10 dir=1 keys=2
 for y=7,10 do set_cell(9,y,tiles.floor) end
 local chest={x=9,y=9,t=7}
 local enemy={x=9,y=7,t=1,hp=100,mhp=100,atk=4,wake=0}
 items={chest} mons={enemy}
 return chest,enemy
end
-- Reaching a chest spends only the movement turn and keeps its contents/key.
local c,m=chest_scene()
press(2)
assert(state=="actions" and action_lock==c and px==9 and py==9,"reaching chest does not prompt")
assert(keys==2 and gold==0 and item_at(9,9)==c and turns==1 and m.y==8,"walking auto-opens chest or doubles enemy turn")
assert(#action_list==3 and action_list[1].n=="use a key" and action_list[2].n=="break the lock" and action_list[3].n=="leave","chest choices missing")
press(0) press(1) press(2)
assert(action_index==3 and dir==1 and px==9 and py==9 and turns==1,"chest navigation moves player or fails to wrap")
press(4)
assert(state=="play" and keys==2 and gold==0 and #items==1 and hp==26 and turns==1,"leave spends a turn or opens chest")
-- Z can reopen a chest underfoot. Cancel preserves it.
m.x=8 m.y=9 set_cell(8,9,tiles.floor)
press(4)
assert(state=="actions" and action_lock==c and turns==1,"cannot inspect chest underfoot")
press(5)
assert(state=="play" and #items==1 and turns==1,"cancel spends a turn")
-- Z inspection from in front is free; held Z cannot spend a key or loot twice.
c,m=chest_scene()
srand(21) local expected=rnd() srand(21)
key=4 _update60() _update60() _update60()
assert(state=="actions" and turns==0 and keys==2 and m.y==7,"held Z auto-opens chest")
assert(rnd()==expected,"inspecting chest consumes rng")
key=-1 _update60()
key=4 _update60() _update60() _update60()
assert(state=="play" and keys==1 and #items==0 and gold>=14 and gold<=35,"key does not open chest exactly once")
assert(turns==1 and m.y==8 and pots+notches+def==2,"key skips or doubles enemy turn/reward")
key=-1 _update60()
-- No-key selection is unavailable but leaves breaking/leaving accessible.
c,m=chest_scene() keys=0
press(4) press(4)
assert(state=="actions" and action_list[1].free and msg=="no keys","no-key choice exits prompt")
assert(keys==0 and turns==0 and gold==0 and #items==1 and m.y==7,"no-key choice spends resources or enemy turn")
-- Each failed attempt advances enemies; failure stays selected for retry.
press(3)
rnd=function(n) return (n or 1)*.1 end
for attempt=1,3 do
 press(4)
 assert(state=="actions" and action_index==2 and turns==attempt,"failed attempt closes prompt or skips/doubles turn")
 assert(#items==1 and keys==0 and gold==0,"failed attempt opens chest or consumes key")
end
assert(m.y==9 and hp==23,"failed attempts do not let enemy approach and attack")
hp=1 press(4)
assert(state=="dead" and hp==0 and turns==4 and not rest_death and #items==1,"fatal attempt reopens modal or awards rest achievement")
rnd=old_rnd press(4)
assert(state=="play" and not action_lock and turns==0,"restart retains chest state")
-- Just below the 10% boundary succeeds, keeps keys, and still lets enemies act.
c,m=chest_scene()
press(4) press(3)
rnd=function(n) return (n or 1)*.099 end
press(4)
assert(state=="play" and #items==0 and keys==2 and gold==16 and pots==2,"successful break loses loot or consumes key")
assert(turns==1 and m.y==8,"successful break skips enemy turn")
rnd=old_rnd
-- Opening and arriving can both be fatal; neither may cover the death screen.
c,m=chest_scene() m.x=8 m.y=10 set_cell(8,10,tiles.floor) hp=1
press(4) press(4)
assert(state=="dead" and turns==1 and keys==1 and #items==0 and not rest_death,"fatal key use mishandles death or loot")
c,m=chest_scene() m.y=8 hp=1
press(2)
assert(state=="dead" and turns==1 and keys==2 and #items==1,"fatal arrival opens chest or retains modal")
-- The entire HUD and message area remain visible beneath the three-row modal.
c,m=chest_scene() mons={}
open_actions(c) state="play" _draw()
memcpy(0xa000,0x6000,0x2000)
state="actions" view_dirty=true _draw()
for offset=84*64,0x1fff do
 assert(peek(0x6000+offset)==peek(0xa000+offset),"chest modal obscures HP or messages")
end
key=-1 _update60()
press(5) press(5)
assert(state=="actions" and not action_lock and action_list[1].n=="eat","chest menu leaks into normal actions")
btnp=old_btnp btn=old_btn rnd=old_rnd
printh("OUBLIETTE PASS: chest arrival/inspection/choices/cancel/held keys, keys/rewards, break chance/retries/enemy turns/death, HUD visibility, action menu reset")
_init=nil _draw=nil _update60=nil
'''
grate_checks = r'''
_init()
local old_btnp,old_btn,old_rnd=btnp,btn,rnd
local key=-1
btnp=function(n) return n==key end
btn=function(n) return n==key end
function press(n)
 key=n _update60()
 key=-1 _update60()
end
function roll(v)
 rnd=function() rnd=old_rnd return v end
end
function grate_scene()
 new_run() fill_map() px=9 py=10 dir=1 keys=2
 for y=7,10 do set_cell(9,y,tiles.floor) end
 set_cell(9,9,tiles.grate)
 local m={x=9,y=7,t=1,hp=100,mhp=100,atk=4,wake=0}
 mons={m} items={}
 return m
end
local m=grate_scene()
press(2)
assert(state=="actions" and action_lock.grate and floor_n==1 and keys==2,"arrival bypasses grate lock")
assert(turns==1 and m.y==8 and px==9 and py==9,"grate arrival skips/doubles movement turn")
press(2) press(4)
assert(state=="play" and floor_n==1 and turns==1 and keys==2,"leave descends or spends a turn")
press(4)
m.wake=8
key=4 _update60() _update60() _update60()
assert(state=="play" and floor_n==2 and turns==2 and keys==1,"key/held Z does not descend exactly once")
assert(m.wake==7 and hp>=25 and hp<=26,"descent skips old-floor attack or recovery order")
assert(px==arrival.x and py==arrival.y and not action_lock and gold==0 and pots==1,"descent loses shaft or awards chest loot")
key=-1 _update60()
m=grate_scene() keys=0
press(4) press(4)
assert(state=="actions" and turns==0 and floor_n==1 and m.y==7,"inspection/no-key choice spends a turn")
press(3)
for attempt=1,3 do
 roll(.1) press(4)
 assert(state=="actions" and action_index==2 and turns==attempt and floor_n==1,"failed grate attempt closes or descends")
end
assert(keys==0 and gold==0 and m.y==9 and hp<26,"grate retries skip enemy approach/attack or consume resources")
hp=1 roll(.1) press(4)
assert(state=="dead" and hp==0 and floor_n==1 and not rest_death,"fatal failure escapes floor")
m=grate_scene() keys=0 hp=20
press(4) press(3) roll(.099) press(4)
assert(state=="play" and floor_n==2 and turns==1 and keys==0 and hp==24,"successful break mishandles descent or key")
assert(m.y==8 and gold==0 and pots==1 and arrival.x==px and arrival.y==py,"successful break skips enemy turn or shaft")
for choice=1,2 do
 m=grate_scene() keys=1 hp=1 m.y=9
 set_cell(9,9,tiles.floor) set_cell(9,10,tiles.grate)
 press(4)
 if choice==2 then press(3) roll(.099) end
 press(4)
 assert(state=="dead" and hp==0 and floor_n==1 and turns==1 and not rest_death,"successful unlock bypasses fatal attack")
 assert(keys==choice-1,"fatal unlock spends wrong key count")
end
btnp=old_btnp btn=old_btn rnd=old_rnd
printh("OUBLIETTE PASS: grate inspection/arrival/key/leave/retries/chance, enemy turns before descent, recovery/death order, no chest loot, arrival shaft, held keys")
_init=nil _draw=nil _update60=nil
'''
opening_checks = r'''
_init() new_run()
-- The overhead opening appears in every facing and stays fixed when we turn.
for facing=1,4 do
 px=9 py=9 dir=facing
 cls(7) clip(vx0,vy0,vx1-vx0+1,vy1-vy0+1)
 draw_opening(px,py,true,0,0)
 local changed=0
 for y=vy0,view_cy-1 do
  for x=vx0,vx1 do if pget(x,y)!=7 then changed+=1 end end
 end
 assert(changed>0,"arrival shaft invisible directly overhead")
 local x,y=front(1)
 dir=dir%4+1 dir=dir%4+1
 cls(7) draw_opening(x,y,true,0,0)
 for offset=0,0x1fff do assert(peek(0x6000+offset)==0x77,"shaft follows camera behind player") end
end
-- Openings behind solid masonry cannot leak through it.
fill_map() px=9 py=9 dir=1 mons={} items={} arrival=nil
set_cell(9,9,tiles.floor) set_cell(9,8,tiles.floor)
draw_view() memcpy(0xa000,0x6000,0x2000)
set_cell(9,5,tiles.grate) arrival={x=9,y=5}
draw_view()
for offset=0,0x1fff do
 assert(peek(0x6000+offset)==peek(0xa000+offset),"opening leaks through wall")
end
-- A busy near view still fits the frame budget and preserves RNG and framing.
fill_map() px=9 py=9 dir=1
for y=6,11 do for x=7,11 do set_cell(x,y,tiles.floor) end end
arrival={x=9,y=8} set_cell(9,8,tiles.grate)
mons={{x=10,y=8,t=2,hp=28,mhp=28,mass=4,elite=true}}
srand(41) local expected=rnd() srand(41)
view_dirty=true _draw() flip() view_dirty=true _draw()
assert(stat(1)<1 and rnd()==expected,"openings exceed frame budget or change gameplay RNG")
assert(pget(0,vy0-1)==5 and pget(0,vy1+1)==5,"openings escape viewport")
printh("OUBLIETTE PASS: shaft all facings/overhead/world anchoring, wall occlusion, simultaneous openings and elite slime CPU/RNG/viewport")
_init=nil _draw=nil _update60=nil
'''
slime_checks = r'''
_init()
function slime(x,y,h,maxh,a)
 return {x=x,y=y,t=2,hp=h,mhp=maxh,atk=a,wake=0}
end
-- Both participants spend their action, regardless of list order.
for reverse=0,1 do
 new_run() fill_map() px=9 py=9 dir=1
 set_cell(9,9,tiles.floor) set_cell(9,8,tiles.floor) set_cell(10,8,tiles.floor)
 local a=slime(9,8,3,7,2)
 local b=slime(10,8,5,12,3)
 b.elite=true b.wake=8
 mons=reverse==0 and {a,b} or {b,a}
 items={}
 local survivor,absorbed=mons[1],mons[2]
 local x,y=survivor.x,survivor.y
 listen_turn()
 assert(survivor.hp==8 and survivor.mhp==19 and survivor.atk==5 and survivor.mass==2,"merge loses wounds or strength")
 assert(survivor.elite and survivor.wake==7,"merge loses elite/awake state")
 assert(survivor.x==x and survivor.y==y and hp==26 and turns==1,"merge also moves or attacks")
 assert(absorbed.hp==0 and not monster_at(absorbed.x,absorbed.y),"absorbed slime still occupies a tile")
 assert(xp==0 and gold==0 and #items==0,"absorption awards a kill")
 assert(msg=="slimes combine x2","nearby merge is silent")
 survivor.x=9 survivor.y=8
 listen_turn()
 assert(hp>=20 and hp<=22 and turns==2,"merged slime does not resume with combined attack")
end
-- A cluster takes multiple turns to combine; damage already dealt stays dealt.
new_run() fill_map() px=9 py=9 dir=1
set_cell(9,9,tiles.floor)
for x=8,10 do set_cell(x,8,tiles.floor) end
local a,b,c=slime(9,8,7,7,2),slime(10,8,7,7,2),slime(8,8,7,7,2)
mons={a,b,c} items={}
listen_turn()
assert(a.mass==2 and c.hp==7 and hp==26,"slime chain merges in one turn")
listen_turn()
assert(a.mass==3 and a.hp==21 and a.atk==6 and c.hp==0 and hp==26,"next-turn merge fails or attacks")
lvl=10 xp=0 gold=0
srand(21) local expected_gold=(flr(rnd(4))+2)*3 srand(21)
hit_monster(a,a.hp)
assert(xp==12 and gold==expected_gold and #items<=1,"merged kill loses rewards or multiplies drops")
assert(not monster_at(9,8) and not monster_at(10,8) and not monster_at(8,8),"merged kill leaves an enemy")
-- Already-combined slimes add their masses rather than just one more unit.
a=slime(9,8,9,14,4) a.mass=2
b=slime(10,8,15,21,6) b.mass=3
mons={a,b}
monsters_act()
assert(a.mass==5 and a.hp==24 and a.mhp==35 and a.atk==10,"combined partners lose mass or stats")
-- Diagonal, separated, dead, and other-species neighbours cannot combine.
for kind=1,4 do
 fill_map() px=1 py=1
 a=slime(9,9,7,7,2)
 b=slime(kind==3 and 11 or 10,kind==2 and 10 or 9,7,7,2)
 if kind==1 then b.t=1 end
 if kind==4 then b.hp=0 end
 set_cell(a.x,a.y,tiles.floor) set_cell(b.x,b.y,tiles.floor)
 mons={a,b}
 monsters_act()
 assert(not a.mass and not b.mass and a.hp==7,"invalid slime partner combines")
end
-- Moving next to a partner cannot buy a second action in the same phase.
fill_map() px=9 py=9 dir=1 hp=26
for y=7,9 do set_cell(9,y,tiles.floor) end
set_cell(8,8,tiles.floor)
a=slime(9,7,7,7,2) b=slime(8,8,7,7,2)
mons={a,b}
monsters_act()
assert(a.y==8 and not a.mass and not b.mass and hp==26,"slime moves and combines in one turn")
monsters_act()
assert(a.mass==2 and b.hp==0 and hp==26,"adjacent pair cannot merge on following turn")
-- Rendered slime area grows; a large slime remains clipped to the viewport.
local area=0
for mass=1,4 do
 cls(0)
 a=slime(5,9,7*mass,7*mass,2*mass) a.mass=mass
 draw_world_mon(a,rect_for_depth(1.5),1)
 local green=0
 for y=vy0,vy1 do
  for x=vx0,vx1 do if pget(x,y)==11 then green+=1 end end
 end
 assert(green>area,"merged slime does not visibly grow")
 area=green
end
new_run() fill_map() px=5 py=10 dir=1
for y=4,10 do set_cell(5,y,tiles.floor) end
a=slime(5,9,112,112,32) a.mass=16 a.elite=true
mons={a} items={}
_draw() flip() view_dirty=true _draw()
assert(stat(1)<1,"giant slime exceeds frame budget")
cls(7)
draw_visible_object({kind="monster",d=1,r=rect_for_depth(1.5),obj=a})
for y=0,127 do
 for x=0,127 do
  if x<vx0 or x>vx1 or y<vy0 or y>vy1 then
   assert(pget(x,y)==7,"giant slime escapes viewport")
  end
 end
end
printh("OUBLIETTE PASS: slime merge actions/order/wounds/stats/elites/occupancy/rewards, multi-turn growth, partner rules, movement, visible size and clipping")
_init=nil _draw=nil _update60=nil
'''
with tempfile.TemporaryDirectory(prefix="oubliette-check-") as tmp:
    for name, fixture in (("core", checks), ("geometry", geometry_checks), ("mechanics", mechanics_checks), ("combat", combat_checks), ("menu", menu_checks), ("chest", chest_checks), ("grate", grate_checks), ("openings", opening_checks), ("slime", slime_checks)):
        target = Path(tmp) / f"{name}.p8"
        target.write_text(cart.replace("__gfx__", fixture + "\n__gfx__", 1))
        try:
            result = subprocess.run(
                ["/Applications/PICO-8.app/Contents/MacOS/pico8", "-x", str(target)],
                capture_output=True, text=True, timeout=30,
            )
        except subprocess.TimeoutExpired as error:
            print((error.stdout or b"").decode(), end="")
            print((error.stderr or b"").decode(), end="")
            raise
        print(result.stdout, end="")
        print(result.stderr, end="")
        assert result.returncode == 0 and "OUBLIETTE PASS" in result.stdout, f"PICO-8 {name} checks failed"
