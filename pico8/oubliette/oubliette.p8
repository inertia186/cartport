pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- oubliette
-- glow-up rebuild
-- turn-by-turn first-person dungeon crawl

mw=19
mh=19
vx0=1
vy0=11
vx1=126
vy1=82
view_cx=64
view_cy=43

-- The middle band has its own stone, fire, and shadow colours.
world_palette={0,129,133,131,4,5,6,7,8,9,10,11,140,134,128,143}

-- Irregular 4x4 coverage, transparent to black; stable between redraws.
dark_patterns={0xffff,0xfeff,0xfedf,0x7edf,0x7ede,0x7ade,0x7ad6,0x7a96,0x5a96,0x5a94,0x5294,0x5284,0x1284,0x1280,0x0280,0x0200,0x0000}

dirs={{0,-1},{1,0},{0,1},{-1,0}}
dnames={"n","e","s","w"}

tiles={
 wall=1,
 floor=0,
 grate=2
}

themes={
 {n="crypt",ceil=1,ground=1,wall=5,stone=1,hi=5,edge=5,lit=10,shade=0,accent=2,moss=3},
 {n="moss",ceil=1,ground=1,wall=5,stone=1,hi=5,edge=5,lit=10,shade=0,accent=3,moss=11},
 {n="brick",ceil=1,ground=1,wall=5,stone=4,hi=5,edge=5,lit=9,shade=0,accent=4,moss=3},
 {n="pit",ceil=0,ground=1,wall=2,stone=1,hi=5,edge=5,lit=10,shade=0,accent=2,moss=3}
}

sp_rat=0
sp_slime=2
sp_bat=4
sp_skel=6
sp_gob=8
sp_wraith=10
sp_potion=32
sp_key=33
sp_coin=34
sp_sword=35
sp_shield=36
sp_ration=37
sp_chest=46
sp_grate=12
sp_shaft=14
sp_torch=41
sp_torch2=42
sp_avatar=160
sp_glow=44

-- authored environment atlas
sp_niche=88
sp_frame=192
sp_bar=194
big_spr={[0]=true,[2]=true,[4]=true,[6]=true,[8]=true,[10]=true,[46]=true,[160]=true}

mon_spr={sp_rat,sp_slime,sp_bat,sp_skel,sp_gob,sp_wraith}
item_spr={sp_potion,sp_key,sp_coin,sp_sword,sp_shield,sp_ration,sp_chest}

mon_db={
 {n="rat",c=4,h=4,a=1,xp=2},
 {n="slime",c=11,h=6,a=2,xp=3},
 {n="bat",c=5,h=5,a=2,xp=4},
 {n="skel",c=6,h=8,a=3,xp=5},
 {n="gob",c=8,h=10,a=4,xp=7},
 {n="wraith",c=2,h=14,a=5,xp=10}
}

g={}
mons={}
items={}

px=1
py=1
dir=1
floor_n=1
theme=1
turns=0
depth_seed=0

hp=26
maxhp=26
lvl=1
xp=0
gold=0
pots=1
keys=0
food=3
atk=4
notches=0
def=0

msg=""
msg_t=0
state="title"
shake=0
view_dirty=true
torch_frame=0

function _init()
 poke(0x5f2d,1)
 memset(0x5f70,0,16)
 for y=vy0,vy1 do
  local a=0x5f70+flr(y/8)
  poke(a,peek(a)|(1<<(y%8)))
 end
 state="title"
 msg="z enters the oubliette"
 msg_t=999
 view_dirty=true
end

function _update60()
 local nf=flr(time()*7.5)%2
 if nf!=torch_frame then
  torch_frame=nf
  view_dirty=true
 end
 if msg_t>0 then
  msg_t-=1
  if msg_t==0 then view_dirty=true end
 end
 if shake>0 then
  shake-=1
  view_dirty=true
 end

 local b0=btnp(0)
 local b1=btnp(1)
 local b2=btnp(2)
 local b3=btnp(3)
 local b4=btnp(4)
 local b5=btnp(5)
 -- Release the menu key before confirming, cancelling, or acting again.
 if action_keys_held then
  b4=false b5=false
  if not btn(4) and not btn(5) then action_keys_held=false end
 end
 if b0 or b1 or b2 or b3 or b4 or b5 then view_dirty=true end

 if state=="title" then
  if b4 or b5 then new_run() end
  return
 end

 if state=="dead" then
  if b4 or b5 then new_run() end
  return
 end

 if state=="actions" then
  if b5 then state="play" action_keys_held=true
  elseif b2 then action_index=(action_index-2)%#action_list+1
  elseif b3 then action_index=action_index%#action_list+1
  elseif b4 then
   state="play"
   action_keys_held=true
   action_list[action_index].run()
  end
  return
 end

 if b0 then turn_left()
 elseif b1 then turn_right()
 elseif b2 then walk(1)
 elseif b3 then walk(-1)
 elseif b4 then use_z()
 elseif b5 then open_actions() end
end

function _draw()
 if not view_dirty then return end
 view_dirty=false
 poke(0x5f5f,0)
 cls(0)
 if state=="title" then
  draw_view()
  draw_title()
 else
  draw_view()
  draw_hud()
  draw_msg()
  if state=="dead" then draw_dead() end
  if state=="actions" then draw_actions() end
 end
 -- Sprite blits reset palettes, so apply the display palette last.
 pal(1,129,1)
 pal(2,133,1)
 pal(3,131,1)
 for c=0,15 do pal(c,world_palette[c+1],2) end
 poke(0x5f5f,0x10)
end

function new_run()
 rest_death=false
 action_keys_held=false
 action_lock=nil
 hp=26
 maxhp=26
 lvl=1
 xp=0
 gold=0
 pots=1
 keys=0
 food=3
 atk=4
 notches=0
 def=0
 turns=0
 floor_n=1
 state="play"
 new_floor()
 say("you land below an open shaft.")
end

function new_floor()
 theme=(floor_n-1)%#themes+1
 depth_seed=flr(rnd(9000))+1000
 g={}
 mons={}
 items={}
 fill_map()
 carve_dungeon()
 place_grate()
 place_loot(6+flr(floor_n*.8))
 place_mons(5+floor_n*2)
 px=1
 py=1
 arrival={x=px,y=py}
 action_lock=nil
 dir=1
 -- Start looking into the maze rather than directly at its boundary wall.
 for i=1,4 do
  if open_cell(px+dirs[i][1],py+dirs[i][2]) then dir=i break end
 end
 say("floor "..floor_n..": "..themes[theme].n)
end

function id(x,y)
 return y*mw+x+1
end

function inb(x,y)
 return x>=0 and y>=0 and x<mw and y<mh
end

function cell(x,y)
 if not inb(x,y) then return tiles.wall end
 return g[id(x,y)] or tiles.wall
end

function set_cell(x,y,v)
 if inb(x,y) then g[id(x,y)]=v end
end

function open_cell(x,y)
 return cell(x,y)!=tiles.wall
end

function fill_map()
 for y=0,mh-1 do
  for x=0,mw-1 do
   set_cell(x,y,tiles.wall)
  end
 end
end

function carve_dungeon()
 -- Room sites reserve two or more solid tiles between their footprints.
 -- ponytail: a 3x3 room lattice keeps routing safe on the 19x19 map;
 -- use a larger placement search only if larger floors need freer shapes.
 rooms={}
 passages={}
 local sites={}
 for row=0,2 do
  for col=0,2 do
   local x=1+col*6
   local y=1+row*6
   add(sites,{slot=row*3+col+1,x=x,y=y,
    w=3+flr(rnd(2)),h=3+flr(rnd(2)),cx=x+1,cy=y+1})
  end
 end
 sites[1].active=true
 add(rooms,sites[1])
 local count=6+flr(rnd(3))
 while #rooms<count do
  local frontier={}
  for a in all(rooms) do
   local col=(a.slot-1)%3
   local row=flr((a.slot-1)/3)
   for v in all(dirs) do
    local nx=col+v[1]
    local ny=row+v[2]
    if nx>=0 and nx<3 and ny>=0 and ny<3 then
     local b=sites[ny*3+nx+1]
     if not b.active then add(frontier,{a,b}) end
    end
   end
  end
  local edge=rnd(frontier)
  edge[2].active=true
  add(rooms,edge[2])
  add(passages,edge)
 end

 -- One optional extra connection makes a loop without punching room walls.
 local loops={}
 for a in all(rooms) do
  for b in all(rooms) do
   if a.slot<b.slot and abs(a.cx-b.cx)+abs(a.cy-b.cy)==6 then
    local linked=false
    for edge in all(passages) do
     if (edge[1]==a and edge[2]==b) or (edge[1]==b and edge[2]==a) then linked=true end
    end
    if not linked then add(loops,{a,b}) end
   end
  end
 end
 if #loops>0 and rnd()<.75 then add(passages,rnd(loops)) end
 for room in all(rooms) do
  for y=room.y,room.y+room.h-1 do
   for x=room.x,room.x+room.w-1 do
    set_cell(x,y,tiles.floor)
   end
  end
 end
 for edge in all(passages) do
  local a,b=edge[1],edge[2]
  local x,y=a.cx,a.cy
  local dx,dy=sgn(b.cx-x),sgn(b.cy-y)
  while x!=b.cx or y!=b.cy do
   set_cell(x,y,tiles.floor)
   x+=dx y+=dy
  end
 end
end

function free_floor()
 local choices={}
 for y=1,mh-2 do
  for x=1,mw-2 do
   if cell(x,y)==tiles.floor and abs(x-1)+abs(y-1)>4 and not monster_at(x,y) and not item_at(x,y) then
    add(choices,{x,y})
   end
  end
 end
 if #choices==0 then return end
 local p=rnd(choices)
 return p[1],p[2]
end

function place_grate()
 -- Breadth-first order measures actual walking distance through the rooms.
 local queue={{1,1}}
 local visited={[id(1,1)]=true}
 local head=1
 while head<=#queue do
  local p=queue[head]
  head+=1
  for v in all(dirs) do
   local x,y=p[1]+v[1],p[2]+v[2]
   if open_cell(x,y) and not visited[id(x,y)] then
    visited[id(x,y)]=true
    add(queue,{x,y})
   end
  end
 end
 local last=queue[#queue]
 set_cell(last[1],last[2],tiles.grate)
end

function place_loot(n)
 for i=1,n do
  local x,y=free_floor()
  if not x then return end
  local r=rnd()
  local t=3
  if r<.19 then t=1
  elseif r<.33 then t=2
  elseif r<.48 then t=6
  elseif r<.58 then t=4
  elseif r<.67 then t=5
  elseif r<.82 then t=7 end
  add(items,{x=x,y=y,t=t})
 end
end

function place_mons(n)
 for i=1,n do
  local x,y=free_floor()
  if not x then return end
  local t=mid(1,flr(rnd(2+floor_n/2))+1,#mon_db)
  local elite=rnd()<min(.24,floor_n*.025)
  local hpv=mon_db[t].h+floor_n+(elite and 5 or 0)
  add(mons,{
   x=x,y=y,t=t,hp=hpv,mhp=hpv,
   atk=mon_db[t].a+flr(floor_n/3),
   elite=elite,wake=0
  })
 end
end

function turn_left()
 dir=(dir+2)%4+1
 tick("turn left")
end

function turn_right()
 dir=dir%4+1
 tick("turn right")
end

function walk(step)
 local v=dirs[dir]
 local nx=px+v[1]*step
 local ny=py+v[2]*step
 local m=monster_at(nx,ny)

 if m then
  if step>0 then hit_monster(m)
  else tick("enemy blocks retreat") end
  return
 end

 if not open_cell(nx,ny) then
  shake=6
  say("stone refuses you")
  sfx(1)
  return
 end

 px=nx
 py=ny
 pickup_here()
 if cell(px,py)==tiles.grate then open_actions({grate=true}) end
 tick()
end

function use_z()
 if cell(px,py)==tiles.grate then
  open_actions({grate=true})
  return
 end

 if notches>0 then
  for d=1,4 do
   local tx,ty=front(d)
   if not open_cell(tx,ty) then break end
   local target=monster_at(tx,ty)
   if target then
    notches-=1
    hit_monster(target,1)
    return
   end
  end
 end

 local x,y=front(1,0)
 local m=monster_at(x,y)
 if m then
  hit_monster(m)
  return
 end

 if cell(x,y)==tiles.grate then open_actions({grate=true}) return end

 local it=item_at(px,py)
 if it and it.t==7 then open_actions(it) return end
 it=item_at(x,y)
 if it and open_cell(x,y) then
  if it.t==7 then
   open_actions(it)
  else
   px=x
   py=y
   take_item(it)
   tick()
  end
  return
 end

 if pots>0 and hp<maxhp then
  pots-=1
  hp=min(maxhp,hp+11)
  tick("potion warms the blood")
 else
  say("nothing answers")
 end
end

function open_actions(lock)
 action_lock=lock
 action_list={}
 if lock then
  add(action_list,{n="use a key",hint=keys>0 and (lock.grate and "1 key / descend" or "1 key / open the chest") or "no keys",free=keys<=0,run=use_lock_key})
  add(action_list,{n="break the lock",hint="10% chance each attempt",run=break_lock})
  add(action_list,{n="leave",hint="leave it locked",free=true,run=function() end})
 else
  if food>0 then
   add(action_list,{n="eat",hint=hp==maxhp and "hp full / keep food" or "1 food: +"..(2+lvl).." hp if safe",run=eat_food})
  end
  add(action_list,{n="listen",hint="wait / keep food",run=listen_turn})
 end
 action_index=1
 action_keys_held=true
 state="actions"
 view_dirty=true
end

function eat_food()
 if food<=0 then say("no food") return end
 for m in all(mons) do
  if m.hp>0 and abs(m.x-px)+abs(m.y-py)==1 then
   tick("can't eat in combat",true)
   return
  end
 end
 if hp<maxhp then
  food-=1
  hp=min(maxhp,hp+2+lvl)
  tick("ration and a breath",true)
 else
  tick("already full",true)
 end
end

function listen_turn()
 tick("listen...",true)
end

function tick(t,resting)
 turns+=1
 if t then say(t) end
 monsters_act()
 if hp<=0 then
  hp=0
  state="dead"
  rest_death=resting==true
  say("you fall on floor "..floor_n)
 end
end

function front(n,side)
 side=side or 0
 local f=dirs[dir]
 local r=dirs[dir%4+1]
 return px+f[1]*n+r[1]*side,py+f[2]*n+r[2]*side
end

function monster_at(x,y)
 for m in all(mons) do
  if m.hp>0 and m.x==x and m.y==y then return m end
 end
 return nil
end

function item_at(x,y)
 for it in all(items) do
  if it.x==x and it.y==y then return it end
 end
 return nil
end

function pickup_here()
 local it=item_at(px,py)
 if it then take_item(it) end
end

function take_item(it)
 if it.t==1 then pots+=1 say("potion")
 elseif it.t==2 then keys+=1 say("iron key")
 elseif it.t==3 then
  local g=5+flr(rnd(12))
  gold+=g
  say(g.." gold")
 elseif it.t==4 then notches+=1 say("blade notches +1")
 elseif it.t==5 then def+=1 say("shield +1")
 elseif it.t==6 then food+=1 say("ration")
 elseif it.t==7 then open_actions(it) return
 end
 del(items,it)
end

function use_lock_key()
 if keys<=0 then
  state="actions"
  say("no keys")
  return
 end
 keys-=1
 open_lock()
end

function break_lock()
 if rnd()<.1 then
  open_lock()
 else
  tick("lock holds")
  if state!="dead" then state="actions" end
 end
end

function open_lock()
 if action_lock.grate then
  tick("grate swings open")
  if state!="dead" then
   floor_n+=1
   hp=min(maxhp,hp+4)
   state="play"
   new_floor()
  end
 else
  open_chest(action_lock)
 end
end

function open_chest(it)
 local g=14+flr(rnd(22))
 gold+=g
 if rnd()<.45 then pots+=1
 elseif rnd()<.7 then notches+=1
 else def+=1 end
 say("chest: "..g.." gold")
 del(items,it)
 tick()
end

function hit_monster(m,thrown_damage)
 local dmg=thrown_damage or max(1,atk+notches+flr(rnd(4))-1-(m.elite and 1 or 0))
 m.hp-=dmg
 shake=3
 sfx(0)
 if m.hp<=0 then
  xp+=(mon_db[m.t].xp+floor_n)*(m.mass or 1)
  gold+=(flr(rnd(4))+m.t)*(m.mass or 1)
  say(mon_db[m.t].n.." undone")
  if rnd()<.14 then add(items,{x=m.x,y=m.y,t=1}) end
  level_check()
 else
  m.wake=60
  say((thrown_damage and "throw " or "hit ")..mon_db[m.t].n.." -"..dmg)
 end
 tick()
end

function level_check()
 local need=lvl*10
 while xp>=need do
  xp-=need
  lvl+=1
  maxhp+=5
  hp=maxhp
  atk+=1
  if lvl%2==0 then def+=1 end
  say("level "..lvl)
  sfx(2)
  need=lvl*10
 end
end

function monsters_act()
 local acted={}
 for m in all(mons) do
  if m.hp>0 and not acted[m] then
   acted[m]=true
   if not (m.t==2 and combine_slime(m,acted)) then
    local d=abs(m.x-px)+abs(m.y-py)
    if d==1 then
     local fx,fy=front(1)
     local exposed=m.x!=fx or m.y!=fy
     local dmg=max(1,m.atk-def+flr(rnd(3))-1)
     if exposed then dmg+=1 end
     hp-=dmg
     shake=5
     say(mon_db[m.t].n..(exposed and " flanks -" or " hits -")..dmg)
     sfx(1)
    elseif d<7 and has_line(m.x,m.y,px,py) then
     m.wake=70
     hunt(m)
    elseif m.wake>0 or rnd()<.08 then
     wander(m)
    end
   end
   if m.wake>0 then m.wake-=1 end
  end
 end
end

function combine_slime(m,acted)
 for other in all(mons) do
  if other.t==2 and other.hp>0 and not acted[other] and abs(m.x-other.x)+abs(m.y-other.y)==1 then
   m.hp+=other.hp
   m.mhp+=other.mhp
   m.atk+=other.atk
   m.mass=(m.mass or 1)+(other.mass or 1)
   m.elite=m.elite or other.elite
   m.wake=max(m.wake,other.wake)
   other.hp=0
   acted[other]=true
   if abs(m.x-px)+abs(m.y-py)<=4 and has_line(m.x,m.y,px,py) then
    say("slimes combine x"..m.mass)
   end
   return true
  end
 end
end

function has_line(x1,y1,x2,y2)
 if x1==x2 then
  local a=min(y1,y2)+1
  local b=max(y1,y2)-1
  for y=a,b do if not open_cell(x1,y) then return false end end
  return true
 end
 if y1==y2 then
  local a=min(x1,x2)+1
  local b=max(x1,x2)-1
  for x=a,b do if not open_cell(x,y1) then return false end end
  return true
 end
 return abs(x1-x2)+abs(y1-y2)<4
end

function hunt(m)
 local dx=sgn(px-m.x)
 local dy=sgn(py-m.y)
 if abs(px-m.x)>abs(py-m.y) then dy=0
 elseif abs(py-m.y)>abs(px-m.x) then dx=0
 elseif rnd()<.5 then dx=0 else dy=0 end
 move_mon(m,m.x+dx,m.y+dy)
end

function wander(m)
 local v=dirs[flr(rnd(4))+1]
 move_mon(m,m.x+v[1],m.y+v[2])
end

function move_mon(m,x,y)
 if open_cell(x,y) and not monster_at(x,y) and (x!=px or y!=py) then
  m.x=x
  m.y=y
 end
end

function say(t)
 msg=t
 msg_t=90
 view_dirty=true
end

function draw_view()
 local ox=0
 local oy=0
 if shake>0 then
  ox=(turns+shake)%3-1
  oy=(turns*2+shake)%3-1
 end

 if backdrop_theme!=theme then
  cls(0)
  draw_ground(true)
  draw_ground(false)
  memcpy(0x8000,0x6000,0x2000)
  -- Reserved atlas rows 48..79: four depth strips, cold and torch-lit.
  for d=1,4 do
   for v=0,31 do
    for u=0,31 do
     sset((d-1)*32+u,48+v,stone(u%16,v,d,u>=16 and abs(v-12)<9))
    end
   end
  end
  backdrop_theme=theme
 end
 memcpy(0x6000,0x8000,0x2000)

 -- Floor and ceiling openings share the ground projection. Walls cover them.
 local actors={}
 clip(vx0,vy0,vx1-vx0+1,vy1-vy0+1)
 for d=4,1,-1 do
  for side=-4,4 do
   local x,y=front(d,side)
   if open_cell(x,y) then
    if cell(x,y)==tiles.grate then draw_opening(x,y,false,ox,oy) end
    local r=rect_for_depth(d+.5)
    local shift=38*side/view_z(d)+ox
    r={r[1]+shift,r[2]+oy,r[3]+shift,r[4]+oy}
    local it=item_at(x,y)
    if it then add(actors,{kind="item",d=d,r=r,obj=it}) end
    local m=monster_at(x,y)
    if m then add(actors,{kind="monster",d=d,r=r,obj=m}) end
   end
  end
 end
 if arrival then draw_opening(arrival.x,arrival.y,true,ox,oy) end
 clip()

 wall_depth={}
 wall_keys={}
 local objects={}
 local torches={}
 clip(vx0,vy0,vx1-vx0+1,vy1-vy0+1)
 palt(0,false)
 -- A sprite's second fill colour is transparent during the detail blend.
 for c=0,15 do pal(c,c,2) end
 for sx=vx0,vx1 do
  local hit=cast_wall(sx-ox)
  local z=view_z(hit.d)
  local top=view_cy-16.5/z+oy
  local bottom=view_cy+21/z+oy
  local bank=mid(1,flr(hit.d+.5),4)-1
  local warm=hit.side and hit.d<3.5
  local u=flr(hit.u*32)%16
  if hit.d>1.5 and hit.d<3.5 then
   -- Reveal medium masonry gradually over two moves, using the same geometry.
   sspr(64+u,48,1,32,sx,top,1,bottom-top+1)
   local detail=flr((3.5-hit.d)*8)
   fillp(dark_patterns[detail+1]+.75)
   sspr(32+u+(warm and 16 or 0),48,1,32,sx,top,1,bottom-top+1)
   fillp()
  else
   sspr(bank*32+u+(warm and 16 or 0),48,1,32,sx,top,1,bottom-top+1)
  end
  darken(sx,top,sx,bottom,hit.d)
  wall_depth[sx]=hit.d
  wall_keys[sx]=hit.key
  if warm and not torches[hit.key] then
   torches[hit.key]=true
   local f=dirs[dir]
   local right=dirs[dir%4+1]
   local dx,dy=hit.tx-px-.5,hit.ty-py-.5
   local d=dx*f[1]+dy*f[2]
   if d>.4 and d<3 then
    local tz=view_z(d)
    add(objects,{kind="torch",d=d,key=hit.key,
     x=view_cx+38*(dx*right[1]+dy*right[2])/tz+ox,
     y=view_cy-8/tz+oy,s=12/tz})
   end
  end
 end
 palt()
 pal(2)
 clip()

 for o in all(actors) do add(objects,o) end
 -- Small scene list: far-to-near insertion sort, then wall-depth clipping.
 for i=2,#objects do
  local o=objects[i]
  local j=i
  while j>1 and objects[j-1].d<o.d do
   objects[j]=objects[j-1]
   j-=1
  end
  objects[j]=o
 end
 for o in all(objects) do draw_visible_object(o) end
 draw_view_frame()
end

function cast_wall(sx)
 local f=dirs[dir]
 local right=dirs[dir%4+1]
 local slope=(sx-view_cx)/38
 -- Invert view_z(): lateral offset = slope*(.25+.5*forward distance).
 -- The ray starts inside the current tile and preserves the tuned projection.
 local ox=px+.5+right[1]*slope*.25
 local oy=py+.5+right[2]*slope*.25
 local dx=f[1]+right[1]*slope*.5
 local dy=f[2]+right[2]*slope*.5
 local mx,my=flr(ox),flr(oy)
 local stepx,stepy=sgn(dx),sgn(dy)
 local delta_x=dx==0 and 1024 or abs(1/dx)
 local delta_y=dy==0 and 1024 or abs(1/dy)
 local next_x=(dx<0 and ox-mx or mx+1-ox)*delta_x
 local next_y=(dy<0 and oy-my or my+1-oy)*delta_y
 local distance=0
 local axis=0
 -- A ray crosses at most mw+mh boundaries before leaving this bounded map.
 for step=1,mw+mh do
  if next_x<next_y then
   distance=next_x next_x+=delta_x mx+=stepx axis=0
  else
   distance=next_y next_y+=delta_y my+=stepy axis=1
  end
  if cell(mx,my)==tiles.wall then
   local u=axis==0 and oy+distance*dy or ox+distance*dx
   local tx=axis==0 and mx+(dx<0 and 1 or 0) or mx+.5
   local ty=axis==1 and my+(dy<0 and 1 or 0) or my+.5
   return {d=max(.01,distance),x=mx,y=my,u=u%1,
    side=f[axis+1]==0,key=id(mx,my)*2+axis,tx=tx,ty=ty}
  end
 end
end

function draw_visible_object(o)
 local start=nil
 for x=vx0,vx1+1 do
  local visible=x<=vx1 and (o.key and wall_keys[x]==o.key or not o.key and wall_depth[x]>=o.d-.01)
  if visible and not start then start=x end
  if not visible and start then
   clip(start,vy0,x-start,vy1-vy0+1)
   if o.kind=="torch" then draw_torch(o.x,o.y,o.s)
   elseif o.kind=="monster" then draw_world_mon(o.obj,o.r,o.d)
   elseif o.kind=="item" then draw_world_item(o.obj,o.r,o.d) end
   start=nil
  end
 end
 clip()
end

function view_z(distance)
 -- Compress visible tile spacing; keep the adjacent boundary at z=.5.
 return .25+distance*.5
end

function rect_for_depth(d)
 if d==0 then return {vx0,vy0,vx1,vy1} end
 local z=view_z(d-.5)
 return {flr(view_cx-19/z),flr(view_cy-16.5/z),ceil(view_cx+19/z),ceil(view_cy+21/z)}
end

-- Stone coordinates are in world space: blocks shrink toward the horizon.
-- Deterministic grain never advances the dungeon's random sequence.
function stone(u,v,d,warm)
 local row=flr(v/(theme==3 and 6 or 8))
 local a=flr(u+row*5)%16
 local b=flr(v)%(theme==3 and 6 or 8)
 -- Keep joints, but interrupt the black horizontal bands in distant stone.
 if a==0 or b==0 then return d>=3 and (a<5 or a>12) and 0 or 1 end
 -- Chipped corners, recessed lower edges, and short branching fractures.
 if (a==1 or a==15) and b==1 then return 0 end
 local grain=(flr(a/2)*7+flr(b/2)*11+row*3)%19
 local c=2
 if grain==3 or grain==4 then c=14 end
 if b==1 and a>2 and a<14 then c=d>=2 and 2 or 5 end
 if b==7 or a==15 or grain<3 then c=1 end
 local crack=row%3!=0 and b>=2 and b<=5 and a==7+flr(b/2)+row%3
 if crack then c=0 end
 if a==6+flr(b/2)+row%3 and b>=3 and b<=4 then c=1 end
 if warm and b==1 and a>3 and a<12 then c=13 end
 if theme==2 and ((a+row*3)%16<4 and b<5) then
  c=grain<7 and 3 or 1
 end
 if theme==4 and crack and d<3 then c=2 end
 if d>=3 then c=(c==0 or grain<3) and 0 or 1 end
 return c
end

function draw_ground(ceiling)
 local ya=ceiling and vy0 or view_cy+2
 local yb=ceiling and view_cy-1 or vy1
 for y=ya,yb do
  local dist=abs(y-view_cy)
  local z=(ceiling and 16.5 or 21)/max(1,dist)
  local world_z=(z-.25)*2
  for x=vx0,vx1 do
   local u=(x-view_cx)*z/38*32
   local v=world_z*32
   local d=ceiling and max(2,world_z+.5) or world_z+.5
   pset(x,y,stone(u,v,d,not ceiling and z<1 and abs(x-view_cx)<20))
  end
  darken(vx0,y,vx1,y,world_z)
 end
end

function darken(x1,y1,x2,y2,d)
 -- Keep the first two tiles clear; disappear into darkness at eight.
 local level=mid(0,flr((d-2)*16/6),16)
 if level==0 then return end
 fillp(dark_patterns[level+1]+.5)
 rectfill(x1,y1,x2,y2,0)
 fillp()
end

function draw_view_frame()
 rect(vx0-1,vy0-1,vx1+1,vy1+1,5)
 panel(0,0,127,9,0,13)
 print("o u b l i e t t e",30,3,13)
 draw_sprite(sp_torch,21,1,8,8,false)
 draw_sprite(sp_torch2,99,1,8,8,false)
 if state!="title" then
  print("lv",3,3,10)
  print(short_n(lvl),13,3,7)
  print("f"..short_n(floor_n),109,3,3)
  print(dnames[dir],122,3,13)
 end
end

function draw_torch(x,y,s)
 draw_sprite(sp_glow,x-s,y-s,s*2,s*2,false)
 draw_sprite(sp_niche,x-s/2,y-s/2,s,s,false)
 local id=torch_frame==0 and sp_torch or sp_torch2
 draw_sprite(id,x-s/2,y-s/2,s,s,false)
end

function draw_opening(x,y,ceiling,ox,oy)
 local f,right=dirs[dir],dirs[dir%4+1]
 local dx,dy=x-px,y-py
 local d=dx*f[1]+dy*f[2]
 local side=dx*right[1]+dy*right[2]
 -- The wider arrival shaft leaves its far rim visible directly overhead.
 local radius=ceiling and 1 or .45
 if d+radius<=0 or d-radius>=8 then return end
 local ya=ceiling and vy0 or view_cy+1+oy
 local yb=ceiling and view_cy-1+oy or vy1
 local id=ceiling and sp_shaft or sp_grate
 palt(0,false)
 for sy=ya,yb do
  local z=(ceiling and 16.5 or 21)/abs(sy-view_cy-oy)
  local forward=(z-.25)*2
  local v=(forward-d)/radius
  if abs(v)<1 then
   local half=sqrt(1-v*v)*radius
   local x0=max(vx0,ceil(view_cx+38*(side-half)/z+ox))
   local x1=min(vx1,flr(view_cx+38*(side+half)/z+ox))
   if x0<=x1 then
    local tv=mid(0,flr((v+1)*8),15)
    clip(x0,sy,x1-x0+1,1)
    sspr((id%16)*8,flr(id/16)*8+tv,16,1,
     view_cx+38*(side-radius)/z+ox,sy,76*radius/z,1)
    darken(x0,sy,x1,sy,forward)
   end
  end
 end
 palt()
 clip(vx0,vy0,vx1-vx0+1,vy1-vy0+1)
end

function draw_world_item(it,r,d)
 local cx=(r[1]+r[3])/2
 local s=max(4,(it.t==7 and 18 or 11)/view_z(d))
 ovalfill(cx-s/2,r[4]-5,cx+s/2,r[4]-2,1)
 draw_sprite(item_spr[it.t],cx-s/2,r[4]-s-4,s,s,false)
end

function draw_world_mon(m,r,d)
 local cx=(r[1]+r[3])/2
 local sizes={20,24,26,32,30,32}
 local scale=m.t==2 and min(2,sqrt(m.mass or 1)) or 1
 local s=max(6,flr(sizes[m.t]*scale/view_z(d)))
 local cy=r[4]-s/2-3
 if m.t==3 or m.t==6 then cy-=max(2,7-d) end
 ovalfill(cx-s/2,cy+s/2-2,cx+s/2,cy+s/2+1,1)
 draw_sprite(mon_spr[m.t],cx-s/2,cy-s/2,s,s,m.elite)
 if m.elite then
  pset(cx-3,cy-s/2-2,10)
  pset(cx,cy-s/2-4,10)
  pset(cx+3,cy-s/2-2,10)
 end
 if m.mass and m.mass>1 then
  local label="x"..short_n(m.mass)
  rectfill(cx-#label*2-1,r[4]-12,cx+#label*2,r[4]-6,0)
  print(label,cx-#label*2,r[4]-11,11)
 end
 if m.hp<m.mhp or d==1 then
  rect(cx-s/2,cy+s/2+2,cx+s/2,cy+s/2+4,1)
  rectfill(cx-s/2+1,cy+s/2+3,cx-s/2+flr((s-1)*m.hp/m.mhp),cy+s/2+3,8)
 end
end

function draw_sprite(id,x,y,w,h,elite)
 palt(0,true)
 local sw=big_spr[id] and 16 or 8
 if elite then
  for c=1,15 do pal(c,8) end
  sspr((id%16)*8,flr(id/16)*8,sw,sw,x-1,y,w,h)
  sspr((id%16)*8,flr(id/16)*8,sw,sw,x+1,y,w,h)
  sspr((id%16)*8,flr(id/16)*8,sw,sw,x,y-1,w,h)
  sspr((id%16)*8,flr(id/16)*8,sw,sw,x,y+1,w,h)
  pal()
 end
 sspr((id%16)*8,flr(id/16)*8,sw,sw,x,y,w,h)
 pal()
 palt()
end

function draw_hud()
 panel(0,84,23,108,1,13)
 draw_sprite(sp_avatar,4,86,16,16,false)
 print("you",6,103,10)
 panel(25,84,77,108,0,13)
 print("hp",28,87,8)
 print(hp.."/"..maxhp,40,87,7)
 bar(28,93,46,3,hp/maxhp,8)
 print("xp",28,98,12)
 print(xp.."/"..lvl*10,40,98,7)
 bar(28,104,46,3,xp/(lvl*10),12)
 panel(79,84,127,108,0,13)
 local ids={sp_sword,sp_shield,sp_ration,sp_potion,sp_key,sp_coin}
 local ns={notches,def,food,pots,keys,gold}
 for i=1,6 do
  local x=81+(i-1)%3*15
  local y=85+flr((i-1)/3)*11
  rect(x,y,x+13,y+11,5)
  draw_sprite(ids[i],x+1,y+1,8,8,false)
  print(short_n(ns[i]),x+6,y+6,7)
 end
 print("arrows move z use x actions",12,123,5)
end

function bar(x,y,w,h,v,c)
 v=mid(0,v,1)
 rectfill(x,y,x+w,y+h,0)
 draw_atlas_frame(sp_bar,x,y,x+w,y+h,5)
 if v>0 then rectfill(x+1,y+1,x+max(1,flr((w-1)*v)),y+h-1,c) end
 if v>.08 then line(x+2,y+1,x+flr((w-1)*v)-1,y+1,7) end
end

function panel(x1,y1,x2,y2,fillc,edgec)
 rectfill(x1,y1,x2,y2,fillc)
 draw_atlas_frame(sp_frame,x1,y1,x2,y2,edgec)
end

function draw_atlas_frame(id,x1,y1,x2,y2,c)
 local sx=(id%16)*8
 local sy=flr(id/16)*8
 local mw=max(1,x2-x1-5)
 local mh=max(1,y2-y1-5)
 palt(0,true)
 pal(13,c)
 sspr(sx,sy,3,3,x1,y1,3,3)
 sspr(sx+5,sy,3,3,x2-2,y1,3,3)
 sspr(sx,sy+5,3,3,x1,y2-2,3,3)
 sspr(sx+5,sy+5,3,3,x2-2,y2-2,3,3)
 sspr(sx+3,sy,2,3,x1+3,y1,mw,3)
 sspr(sx+3,sy+5,2,3,x1+3,y2-2,mw,3)
 sspr(sx,sy+3,3,2,x1,y1+3,3,mh)
 sspr(sx+5,sy+3,3,2,x2-2,y1+3,3,mh)
 pal()
 palt()
end

function short_n(n)
 if n>99 then return "++" end
 return n
end

function draw_msg()
 if msg_t>0 then
  local text=">"
  local y=111
  for word in all(split(msg," ",false)) do
   if #text+#word>30 then
    print(text,2,y,10)
    text=""
    y+=6
    if y>117 then return end
   end
   text=text..word.." "
  end
  print(text,2,y,10)
 end
end

function draw_actions()
 local footer=30+#action_list*10
 -- Shared overlay colours keep the palette boundary invisible.
 panel(11,12,117,footer+21,0,5)
 print(action_lock and (action_lock.grate and "grate" or "chest") or "actions",18,16,7)
 print(action_lock and "keys "..short_n(keys) or "food "..short_n(food),83,16,6)
 line(18,24,110,24,5)
 for i=1,#action_list do
  local a=action_list[i]
  local y=29+(i-1)*10
  if i==action_index then
   rectfill(18,y-2,110,y+7,1)
   print(">",22,y,10)
  end
  print(a.n,30,y,i==action_index and 10 or 6)
 end
 local a=action_list[action_index]
 print(a.hint,18,footer,6)
 print(a.free and "no turn spent" or "enemies get a turn",18,footer+7,5)
 print("up/down  z act  x back",18,footer+14,10)
end

function draw_title()
 -- Overlays cross palette bands: use colours shared by both palettes.
 panel(11,25,117,90,0,5)
 draw_torch(23,43,9)
 draw_torch(105,43,9)
 print("oubliette",46,35,7)
 line(35,45,93,45,5)
 print("first-person",39,53,6)
 print("dungeon crawl",38,61,6)
 panel(34,72,94,84,1,5)
 print("z/x descend",41,76,10)
end

function draw_dead()
 local extra=rest_death and 18 or 0
 panel(11,33,117,86+extra,0,8)
 draw_sprite(sp_wraith,18,42,18,18,false)
 print("lost below",43,42,8)
 print("floor "..floor_n.." gold "..gold,39,56,10)
 if rest_death then
  print("achievement unlocked",24,68,10)
  print("rest in pieces",36,77,7)
 end
 panel(30,68+extra,102,80+extra,1,5)
 print("z/x wake",48,72+extra,7)
end

function sgn(v)
 if v<0 then return -1 end
 if v>0 then return 1 end
 return 0
end

__gfx__
000000000000000000000000000000000000000000000000000000555000000000000000000000000000000200000000000000dddd000000000000dddd000000
0000000000000000000000000000000000000000000000000000056765000000000000333000000000000025200000000000ddd50ddd00000000dddeeddd0000
0000000000000000000000000000000020000000000000020000566666500000000003bb33000000000002555200000000de00050005dd0000deee1111eedd00
000044000004400000000000000000002200000000000022000066060660000000003b0b0b300000000025555520000000d5000500050d0000de11000011ed00
0004ff40004ff40000000333330000002520002002000252000006606600000000003bbbbb30000000002500052000000d565556555655d00de1000000001ed0
000455544455540000003bbbbb30000025520052250025520000006760000000000003f0f30000000002550a052200000d040005000500d00de1000000001ed0
00455555555554000003b7bbbbb300002555225555225552000665666566000000004433344000000002550005520000dd050005000500dddd100000000001dd
0455655555555400003bbbbb3bbb30000255552885555520006506060606500000044333334400000002255555220000d005000aa005000dde100000000001ed
0456555555855f40003bbb03b03b300000255555555552000060056665006550003404333404300000255222225520005556555a155655555e100000000001e5
445555555555fff4003bbb03b03b300000025555555520000650060606055455003404333404360000252555552520005505000aa00400555510000000000155
0044455444444440003bbbbbbbbb3000000022f55f220000060005666505464500340444440066600025225552252000050500050005005005e1000000001e50
00045f400045f400003bbb333bbb30000000002552000000650000656005545500030344430006000002225552220000050500050005005005e1000000001e50
00044400000444000033bbb3bbb3300000000002200000006000006060005550000003303300040000025225225200000056555655565500005e11000011e500
000000000000000003333bbbbb3333000000000000000000000000606000000000000340430000000022522522522000005e000500055500005eee1111ee5500
0000000000000000003333333333300000000000000000000000065056000000000044404440000000220220220220000000555505e500000000555ee5e50000
000000000000000000000000000000000000000000000000000066505660000000000000000000000000000000000000000000e555000000000000e555000000
0006600000000000000aa000000000600055550000033000000000001222222100000000000a000000090000000ff00000000000000000000000000000000000
00077000000aa00000a99a000000067005666550003bb300000000001252525100000000009a900000aaa00000f99f0000040000000000000000000000000000
0016610000a00a000a9aa9a0000067605667766503b7bb3000000000125252510000000000aaa000009a900000f99f0000404000000000000001111111111100
016cc610000aa0000a9a99a000067600566776653bbbbbb300000000125252510000000000090000000a0000000ff00004090400000000000019999999999510
16cccc61000a00000a99a9a0006760000566665033bbbb330000000012525251000000000004000000040000003b330000404000000000000199699999644551
16c7cc61000a0a000a9aa9a0094600000056650003333330000000001252525100000000004440000044400003bbb33000040000000000001966999996644551
01666610000aaa0000a99a00049000000005500000300300000000001252a2510000000000040000000400000034430000000000000000001945444444544551
0000000000000000000aa00040090000000000000000000000000000122222210000000000040000000400000040040000000000000000001155111111551511
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000145444aaa4454511
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000145444a1a4454511
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000145444aaa4454511
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001454444444454511
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001464444444465511
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001444444444441511
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001111111111111111
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111511151111111111131111111311131111111111141111111411141111111100010000000100010000000000000000000000000000000000000000
15555551155155511515151513333331133133311313131314444441144144411414141401111110011011100101010100000000000000000000000000000000
15dddd51111511111111111113555531111311111115111114999941111411111112111101222210000100000000000000000000000000000000000000000000
15111151551551555151515113111131331331333131313114111141441441444141414101000010110110111010101000000000000000000000000000000000
11555111111511511115111511333111113113311113111311444111114114411114111400111000001001100001000100000000000000000000000000000000
1dddddd1155155511551555115533551133133311331333119944991144144411441444102511250011011100110111000000000000000000000000000000000
11151111111511111111111111131111111311111111111111141111111411111111111100010000000100000000000000000000000000000000000000000000
15555551551551555151515113333331331331333131313114444441441441444141414101111110110110111010101000000000000000000000000000000000
11151111111311111114111100010000111111111111111111111111000000000011110000010000000000000000000000000000000000000000000000000000
15555551133333311444444101111110115555111133331111444411001111000155551000110000000000000000000000000000000000000000000000000000
15111511131113111411141101000100151111511311113114111141010000101522225100011000000000000000000000000000000000000000000000000000
51115115311131134111411410001001111551111113311111144111000110001520025100001100000000000000000000000000000000000000000000000000
11551111113311111144111100110000115115111131131111411411001001001520025100011000000000000000000000000000000000000000000000000000
15515551133133311441444101101110151111511311113114111141010000101522225100100100000000000000000000000000000000000000000000000000
11151111111311111114111100010000111511111113111111141111000100000155551001000100000000000000000000000000000000000000000000000000
51111515311113134111141410000101115555111133331111444411001111000010010000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000044400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000444440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000044ffff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004f0ff04000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000004ffff0000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000344430000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00003333333006600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555333333306600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05665533335f06600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05665533335066600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555344443009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000343330009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000330330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000440440000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00004400444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550022222200555555005555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd52dddddd25dddddd55d5555d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d0000d52d5555d25d1111d55d2222d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d0000d52d5005d25d1111d55d2002d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d0000d52d5005d25d1111d55d2002d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5d0000d52d5555d25d1111d55d2222d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddd52dddddd25dddddd55d5555d5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
05555550022222200555555005555550000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100
00111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100
00110000000010000011100000000000000101111000010000100111100000000000100000011111000000110000000000110000000110000000000001001100
00110000000000000000110000000000000011111000000100011011111001000000000000000000000011111110001000000000011000001100000000001100
00110000000000100000010000000000000010111001010000111010011001000000000000000000000011111110001000000000011000001100000000001100
00110000000000000100010000000000000000011101000100000000111000000000001000011100001111111000000000000000001000000011100000001100
00110000000000000100010000000000000000111110111000011151100001100000010000000010101100000000000000000000101000000010000000001100
00110000000000000100010000000000000000111110111000011151111001100000000000000110101100000000000001000000101000000110000000001100
00110000000011011111010000000000000000000000000000000000000000000000000000000000000000000000000000000110510000111000000000001100
00110000000010000011000001110000010000111111151111000151011000111100011000000100055511100000000000111000150000111111111000001100
00110001000010000015000001110000010000111111151111000151111000110100011000000500055511110001000000111000500000111111111101001100
00110001100000011100110001511100000110001555111111100111110000110100000001011100010010000000000001111111000110111551111100001100
00110000500010011511510000001101000000000110111111110011100000011000000111000000110000000000000011111110111110001551111000001100
00110000500010011511510000001101000010000110111111110011000000111000000111011000110100000000000011111150111110001551110000001100
00110110055011000155510011100011110001000001000111000000011000000100000100000000100000000000000111000000001000111111550000001100
00110000000511010005550051100001110000010000000000000000000000000000000000000000000000000000000011110001005010551150001000001100
00110111000555010011550051100001110000110000000000000000000000000000000000000000000000000000000011110001005110551150000000001100
00110111000000001101550011151100010010001000111111111000011110011000000001100011100000000000110115000155111110555000111001001100
00110111000000000111150051111100010010000000000100011100000001000100000000000000000000000000110150110155111510550001511111001100
00110101100011100045150054415501000010000000000000000000000000000000000000000000000000000001110001110115115550000001550110001100
00110111100011100055150044415501000011000000000000000000000000000000000000000000000000000001110001110115114110000001150110001100
00110111500015111000410045511101110010110000000000000000000000000000000000000000000000000001110011550441554000011001115000001100
00110111500011151051000004455501111001000000000000000000000000000000000000000000000000000001000111550551440001111001111000001100
00110101500011151055000004455501111001000000000000000000000000000000000000000000000000000001000111550551440005111005550000001100
00110110100011151011410005514405511000000000000000000000000000000000000000000000000000000001001114110004000510551005551000001100
00110101100011411045151180004404111110000000000000000000000000000000000000000000000000000000001115550000ee0115551005115110001100
00110101100111511045151180004404111110000000000000000000000000000000000000000000000000000000001115550000440115551005115100001100
00110001500011500055455514800005111110000010000000000000000000000000000000000000000000000001001110440004551551111004515110001100
00110001100055155055411516611100051110110000000000000000000000000000000000000000000000000011001554000154445551440005111110001100
00110001100155155055411556d11100051110110000000000000000000000000000000000000000000000000011001554000554445551440005111510001100
00110001500155555055151144414411005110000000000000000000000000000000000000000000000000001111001540115111444555550004551111001100
00110000400011545045551189951141010050110000000000000000000000000000000000000000000000001115005001554154ff2555115004111550001100
0011000040001154505551118a911141110050110000000000000000000000000000000000000000000000001115005001554114ff2555115004011550001100
0011000000015455501544449ff95511150000000110000000000000000000000000000000000000000001001111000005441449ee2885551004015550001100
001100015000004450555444f7744414510011000110000000000000000000000000000000000000000000101050551004554229774445111001004110001100
001101015000004450555444f7744414510011000110100000000000000000000000000000000000000000001050551004554229774445111001114111001100
0011010514410001104551297aa7445111001110000011000000000000000111110000000000000000000000150111400511499faa9115551004111551001100
00110110111545000044599a7779441511005011000000000000000000000000000000010000000000000000000111100455444777a445555004111500001100
0011001111154500004459997779441551005155000000000000000000000000000000000000000000000000000111100451444777a445455004111500001100
00110110511144011000494070091154510150001001000000000000000000000000000011000000000010000101114001551990770551441000110000001100
00110105111555055411194050091155110010110000110000000000000000000000000000100000000000015501555005551990aa0441441000000550001100
001101151115550554111940d0091055110010110000110000000010000000000100000000100000000000015501554004511990aa0441441000000550001100
0011011115554501154400115dd4551455015100100111000000000000000000000000000001100000000000010155100155544d111100440000005111001100
00110111511555055444000000000014500141111001110000000100000000000000011000011000000000015501114004150000000000004115001551001100
00110111511155055544000000000045100540111001100000000000000000000000011000000000001100011101551001440000000000445115001111001100
00110111555111011555455000001140040000000001000000000000000000000100000000000100001100011001550001940000000440441551004111001100
00110111111155045500455005404450051110001000000000000000000000000100000010000100000000050001001540554001000440515111005111001100
00110111155155055100455001505550055110000000000000000000000000000100000000000100001000050000001550444001000440001111005111001100
00110115155111055000551000005550055110000000000000000000000000000000000010000100000000000010111550444000000110001111005111001100
00110101155145011000100050045510051111001110000000000000000110111011011000000000000000001150115440554440550000001115001550001100
00110111155155051000000050041150051111001110000000000010000110000100100000000000000000001150115550555440550000001551001111001100
00110010055111055000000150051140051101000000000000000011000000000100100000100000000000001110115110445550550001001551001101001100
00110000055145010000100005544410041110001000000000000010000001000000000000000010000000000000111110455110000000001115000100001100
00110000500151011000100104414410051100001000000000000011011001000000000000100100000010001100551550115545005000001441005000001100
00110000100111011000100105414410051100001000000000000010011001000000000000100100000010001100551550115555001000001451005000001100
00110000000000000000000501151150041101001110000000000010011001000000100000100000000010000010101550551001005000000000000000001100
00110111555000500000001500000000050111000111000000000011000001000000100000000000000000001110110150000000005000000111441100001100
00110111555000100000001500000000040111000111001000000011000001000000100000000000000000001110111150000000005000000111551000001100
00110111555044500000010014440045100000000000000000000011000001000000100000100100000000000000000000441440440150001115110001001100
00110111144011111000050015550051150001111000100000000011000000000000000000100111000000000011440001555540440550000441111111001100
00110111144011111000050015550051150001111000000000000010000000000000000000100111000000010011440011555550440150000441111111001100
00110001111011411000000015550051111005000000000000000011011000000000000000000000000000000110550115111550110000000551111111001100
00110001111011111000005551110051101005000000000000000010000001001000000000000000000000110111110111101150555000111551111100001100
00110001111011111100005551110041111005001000000000000001000001001000000000000000000001110151110111011550555000011551111001001100
00110100111011155100005555550011110001010000000000000011000000115100000000100000000000000111010111555110441000000110111100001100
00110101111000111110011510150051111001110000000000011001000000001000000000000111000000000010110111551110111001110111111110001100
00110011111000111100011510150050110001111000000000011000000000001000000000000110000000000010110001551110151001110111111110001100
00110111155011111551001150110011110000000000000000000000000000110100000000000000000000000000110010111150441111110455110110001100
00110011011001111151011111150001100000001110000000000001000001001000000000000000000001101110000000111110110001000551111110001100
00110001111010111151011111110000000010001000000000000010000001000000000000000000000000001010000000001110110001110551111000001100
00110000111000111051011151500000000011001000000000000010000000000100000000000000000010000011000000000110110115550550101000001100
00110010000001011100000000001114110101000110000000000000000000000000000000000000000010000010001551000000000115550110110000001100
00110000055000111000000000005515110000000000000000000000000000000000000000000000000000000001001151000000000000110111111000001100
00110000155000111000000000015511110000001000000000000000000000000001000000000000000000000001000111000555000000110111111000001100
00110110011000000000055510010111110110000000000000000000000000000000000000000000010000000010001001001111155000000000000011001100
00110000000000000045411110001110110110000000000000000011101000100111100100000000500010000010000001001551115550000000000110001100
00110000000000000045411110001101100110000000000000000010000000000101100000000000100000000000000001001551114550000000000550001100
00110000000155500011511100011115110000000000000100000000000000000000000000000000001000000000000001005115551000005551000000001100
00110000145155100111111110010011010010000115100000000000000000000000011001010000010000014510000010001101551110551115551000001100
00110000144111100111110010010011010010000115100000000011000001000100011001101100010000014510001000001001555110551115441000001100
00110115144111100011101110000000001100000000111000000000111100111011000100000011001101150011000000001110001000110000111550001100
00110110010111100011110110001100000000115001000000000000000000000000000000010000000001100000110000001111011110550111111111001100
00110110000110100111100010001100000000115000000000001010000000000000000000111100000001100000110000000111011110550111111111001100
00110110000111100011101110000011000000001550100100000111111100111111101100000011100005110000100110001111111110551110111001001100
00110000011011000011110100001100000000000000011000100111011001110011111111011111100000000000000001000111000000010000111001001100
00110000011011000011111000001100000000000000011000100111011001110011111111011111100100000000000001000110000000010000111001001100
00110000511011000110010001500011000001555001110000000000000000000000000000000000000000051100000000110000001000551111110000001100
00110000511115000010000010000000000001551000100011100011111001011111011100000111100010010015550000111000000000000001001001001100
00110000511055000010000050000000000001451000000011100011111000001111011100000111100011100015551000111000110000000001001000001100
00110111001110100100011100000000000000000100000111111111111001111111111111100011110001105510000000000110000000000111000110001100
00110000110000100000010000001150000000000115001011111111100011551111111111111011111101101100000000100000550000551001100110001100
00110000100000100000010000001151000005551115000111111111100001551111111111111051111111101100000000000000550000551001001111001100
00110000001001000010000000001115400005511110011011100555000000111115511555111000110000000000000000000000115100001000000000001100
00110000111000055510010000000001150011000000000000111000000000000000000000000000000000051010000000000010010555000000100000001100
00110000111000055500010000000001110001000000000000111000000000000000000000000000000000051100000000000000101151000000110000001100
00110000100000510110000005500000100000110001110011100111500011555555111155555100110110011000011005550000001111510000000000001100
00110000000015111110000011150000000011110111115111111111000115115555555155511111011101111101000555551000000111511000000000001100
00110000000111111110000000015500011111000111111111111555011555555111155511111100055511111111000115110100001001010110000001001100
00110000000111011110000000015500111111000011115511111555011555555111555511111100015511111111110111110110001001101110000001001100
00110000100001100000000000000000005110001111111111555511011111115555555100555511105555510011110000000000000111001100000000001100
00110001500001100000015500001111000000111111555111111011011001155555151555111151000151111110111000000000000000001110555000001100
00110001500001100000011100001111001110111111555111111011011001115555155555511115001051111110111110000000000000000110155000001100
00110110100001000000105510001100011000111111551555000110011001555555555555511111500011101111000005111005550001001000001110001100
00110101000000010000000000100000000000000000000000000000000000000000000000000000000000000000000000000115551000001110000001001100
00110100000000000000000000000000000000000000000100000000000000000000000000100100000000000000000000000115551000010110000001001100
00110000000000000000000011101111100555551001111155544500015555001555555511555155510001151111001000001555111000000000000001001100
00110000000000000000011111111110001111111111111111555500155111111555555555555111110005551110110100000000000000000000001000001100
00110000000000000000011111111110005111111110111111155500155111111511555555555111110005551111110110000000000000000000001000001100
00110000000000555500000011111110001151101551111155111100111555115100155555511511501100015551110111100000000001100000111000001100
00110000000000111150000011110100015101115000101155111011555111011111101555011511111100051111001111110110000000000000110000001100
00110000000000111550000011111000015111115000001155111011555111011111111555011511111110051111001110110110000000000000110000001100
00110000000000155101100111100001111111101111515111155011111011111111111011500100000000000011110111000000000000005000000000001100
00110100000000011110000100100000011100000000550101111011011111111500111111011000000000001100000001000000000005515000000000001100
00110110000000011150000111100000011100000001550501111011011111511500111111111000000000001110000000000000000005115000000000001100
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000151551510000000001100
00110000000000000010000000011110011100000110000151500000111100011111001500001555510011100010000150000110000005110000000000001100
00110000000000000010110100011110011100000110000055500000111100000111001500000555150010000010000110000110000005110000000000001100
00110000000000000001110000000001100001000000000000000010001111000000000000000000100001110000001000000000000000000000000000001100
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100
00110000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001100
00111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100
00111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111100
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000400001435016350183501a3501c350183501635014350000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00020000072500525003250012500025000250001250032500525007250000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00050000182701a2701c2701f2702227025270282702a2702c270000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
