pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- pixels-progress/layout-doctrine
-- doctrine-aware derived cart.
-- level 1: n-family room, three vertical chambers,
-- top transfer then bottom transfer, switchback ledges.
-- level 2: z-family room, three horizontal bands,
-- right gap then left gap, mini reversals + bumps.
-- level 3: m-family room, four vertical strokes,
-- alternating top valleys and low transfer troughs.
-- lava = falling growth-pressure droplets. they land,
-- spread into floor lines, add pixels, and rotate shape.

player={
 x=8,
 y=112,
 dx=0,
 dy=0,
 size=1,
 body={{x=0,y=0}},
 grounded=false,
 jump_armed=true
}

restart_pending=false
level_cleared=false
tries=1
loop_count=0
growth_fx_timer=0
growth_fx_side="right"
growth_fx_kind="hit"
sand={}
sand_spawn_timer=0
sand_base_min=18
sand_base_max=42
out_of_bounds_timer=0
out_of_bounds_latched=false
room_id="n"
next_room_id=nil

floor_y=120
out_of_bounds_y=128

room={}

function _init()
 reset_run()
end

function load_room_n()
 -- n-family: three vertical chambers.
 -- left/middle wall has a notch near the top.
 -- middle/right wall has a notch near the bottom.
 -- inside each chamber, ledges alternate sides so a
 -- single jump cannot skip a tier (face-flip per tier).
 -- lava hazards live in the floor-gutter and the right-chamber
 -- base pocket; the literal floor row stays clean while
 -- size=1 so the legitimate route reads honestly.
 room={
  goal_x=118,
  goal_y=26,
  lava={
   -- left-chamber floor gutter (contamination pool).
   -- first drop starts high enough to claim the second
   -- ledge, leaving the starter ledge clean.
   {x=34,y=84,phase=0.0,cooldown=0},
   {x=22,y=116,phase=0.15,cooldown=0},
   {x=34,y=116,phase=0.3,cooldown=0},
   -- middle-chamber floor gutter, leaving the bottom
   -- transfer notch around x=82..86 unblocked.
   {x=50,y=116,phase=0.45,cooldown=0},
   {x=62,y=116,phase=0.6,cooldown=0},
   {x=74,y=116,phase=0.75,cooldown=0},
   -- top-transfer corruption seam: clipping the notch
   -- corner from below adds and rotates pixels.
   {x=44,y=22,phase=0.1,cooldown=0},
   -- right-chamber base pocket: missed final ascent
   -- lands here, telegraphing "too big for this line".
   {x=100,y=116,phase=0.5,cooldown=0},
   {x=114,y=116,phase=0.85,cooldown=0}
  },
  walls={
   -- left/middle divider, notch at top (rows ~20..26).
   {x=42,y1=28,y2=120},
   -- middle/right divider, notch at bottom (rows ~100..120).
   {x=84,y1=8,y2=100}
  },
  solids={},
  platforms={
   -- left chamber switchback (alternating l/r anchors).
   {x1=2,y=104,x2=16},
   {x1=26,y=88,x2=40},
   {x1=2,y=72,x2=18},
   {x1=24,y=56,x2=40},
   {x1=2,y=40,x2=20},
   -- top transfer: bridge across the wall notch so the
   -- player walks (not jumps) into the middle chamber.
   {x1=22,y=24,x2=44},
   -- middle chamber descent (alternating).
   {x1=44,y=24,x2=60},
   {x1=66,y=40,x2=82},
   {x1=44,y=56,x2=58},
   {x1=68,y=72,x2=82},
   {x1=46,y=88,x2=60},
   {x1=68,y=104,x2=82},
   -- right chamber tighter ascent, ledges crowd the
   -- outer wall to telegraph "this is the proof".
   {x1=86,y=108,x2=98},
   {x1=110,y=92,x2=124},
   {x1=88,y=76,x2=100},
   {x1=108,y=60,x2=124},
   {x1=88,y=44,x2=104},
   {x1=110,y=28,x2=124}
  }
 }
 player.x=8
 player.y=112
end

function load_room_z()
 -- z-family: three horizontal bands.
 -- top/middle barrier has its gap on the right.
 -- middle/bottom barrier has its gap on the left.
 -- each band carries short bumps so the player has to
 -- step-back, re-launch, re-commit (mini reversal).
 -- lava hazards live in the bottom-band left trench, in the
 -- basins downhill of bumps, and on the right-gap underlip.
 room={
  goal_x=120,
  goal_y=110,
  lava={
   -- bottom-band trench along the left wall: pooling
   -- where the player drops in from the left gap.
   {x=2,y=118,phase=0.0,cooldown=0},
   {x=6,y=118,phase=0.2,cooldown=0},
   {x=10,y=118,phase=0.4,cooldown=0},
   -- basins downhill of top-band bumps (geometry-attached,
   -- not floating). a botched hop drops in.
   {x=34,y=42,phase=0.5,cooldown=0},
   {x=74,y=40,phase=0.6,cooldown=0},
   -- basin downhill of middle-band bump.
   {x=54,y=78,phase=0.7,cooldown=0},
   -- right-gap underlip: clipping the corner on the
   -- drop adds and rotates pixels.
   {x=108,y=42,phase=0.85,cooldown=0}
  },
  walls={},
  solids={
   -- top/middle barrier, full width except right gap.
   {x1=0,y1=44,x2=110,y2=48},
   -- top-band bumps (sit on top of the barrier).
   {x1=24,y1=40,x2=32,y2=44},
   {x1=64,y1=38,x2=72,y2=44},
   {x1=88,y1=40,x2=96,y2=44},
   -- middle/bottom barrier, full width except left gap.
   {x1=14,y1=80,x2=127,y2=84},
   -- middle-band bumps.
   {x1=44,y1=76,x2=52,y2=80},
   {x1=88,y1=76,x2=96,y2=80},
   -- bottom-band bumps (squat, just over floor).
   {x1=40,y1=116,x2=48,y2=120},
   {x1=72,y1=116,x2=80,y2=120},
   -- goal landing on the right.
   {x1=110,y1=112,x2=127,y2=120}
  },
  platforms={}
 }
 player.x=8
 player.y=8
end

function load_room_m()
 -- m-family: four vertical strokes.
 -- route climbs, dips, climbs, dips, then descends to lower-right goal.
 -- transfers alternate between high caps and low troughs, making
 -- growth costly because the player must repeatedly fit through
 -- narrow handoffs after changing shape.
 room={
  goal_x=118,
  goal_y=110,
  lava={
   -- trough pressure after first descent.
   {x=36,y=116,phase=0.05,cooldown=0},
   {x=46,y=116,phase=0.25,cooldown=0},
   -- middle valley / second trough pressure.
   {x=66,y=68,phase=0.45,cooldown=0},
   {x=76,y=116,phase=0.65,cooldown=0},
   -- final ascent base pocket.
   {x=98,y=116,phase=0.85,cooldown=0},
   -- high underlip clips: sloppy crest transitions add pixels.
   {x=32,y=28,phase=0.2,cooldown=0},
   {x=78,y=30,phase=0.55,cooldown=0}
  },
  walls={
   -- stroke dividers with alternating top/bottom openings.
   {x=32,y1=34,y2=120},
   {x=64,y1=8,y2=84},
   {x=96,y1=34,y2=120}
  },
  solids={
   -- high cap between the first two strokes.
   {x1=24,y1=30,x2=40,y2=34},
   -- mid valley ledge before second climb.
   {x1=54,y1=84,x2=72,y2=88},
   -- high cap between third and fourth strokes.
   {x1=80,y1=30,x2=104,y2=34}
  },
  platforms={
   -- stroke 1: climb from start.
   {x1=2,y=104,x2=16},
   {x1=18,y=88,x2=30},
   {x1=2,y=72,x2=16},
   {x1=18,y=56,x2=30},
   {x1=4,y=40,x2=20},
   -- stroke 2: descend after high transfer.
   {x1=34,y=40,x2=48},
   {x1=50,y=56,x2=62},
   {x1=34,y=72,x2=48},
   {x1=50,y=88,x2=62},
   {x1=34,y=104,x2=48},
   -- stroke 3: climb out of low trough.
   {x1=66,y=104,x2=80},
   {x1=82,y=88,x2=94},
   {x1=66,y=72,x2=80},
   {x1=82,y=56,x2=94},
   {x1=66,y=40,x2=80},
   -- stroke 4: descend into the lower-right goal.
   {x1=98,y=40,x2=112},
   {x1=114,y=56,x2=126},
   {x1=98,y=72,x2=112},
   {x1=114,y=88,x2=126},
   {x1=100,y=104,x2=126},
   {x1=108,y=112,x2=126}
  }
 }
 player.x=8
 player.y=112
end

function load_current_room()
 if room_id=="z" then
  load_room_z()
 elseif room_id=="m" then
  load_room_m()
 else
  load_room_n()
 end
end

function reset_run()
 load_current_room()
 player.dx=0
 player.dy=0
 player.size=1
 player.body={{x=0,y=0}}
 player.grounded=false
 player.jump_armed=true
 restart_pending=false
 level_cleared=false
 growth_fx_timer=0
 growth_fx_side="right"
 growth_fx_kind="hit"
 sand={}
 sand_spawn_timer=sand_spawn_delay()
 out_of_bounds_timer=0
 out_of_bounds_latched=false
 next_room_id=nil
 init_lava()
end

function init_lava()
 for lava in all(room.lava) do
  lava.spawn_x=lava.x
  lava.spawn_y=lava.y
  lava.dy=0
  lava.cooldown=0
  lava.landed=false
  lava.surface_y=nil
  lava.draw_y=nil
  lava.x1=nil
  lava.x2=nil
 end
end

function lava_surface(lava)
 local left=lava.x
 local right=lava.x+1
 local bottom=lava.y+1
 local next_bottom=bottom+lava.dy
 local hit_y=nil
 local hit_x1=0
 local hit_x2=127
 local hit_draw_y=floor_y+1

 if bottom<=floor_y and next_bottom>=floor_y then
  hit_y=floor_y
 end

 for solid in all(room.solids) do
  if right>=solid.x1 and left<=solid.x2
  and bottom<=solid.y1 and next_bottom>=solid.y1
  and (hit_y==nil or solid.y1<hit_y) then
   hit_y=solid.y1
   hit_x1=solid.x1
   hit_x2=solid.x2
   hit_draw_y=solid.y1
  end
 end

 for platform in all(room.platforms) do
  if right>=platform.x1 and left<=platform.x2
  and bottom<=platform.y and next_bottom>=platform.y
  and (hit_y==nil or platform.y<hit_y) then
   hit_y=platform.y
   hit_x1=platform.x1
   hit_x2=platform.x2
   hit_draw_y=platform.y+1
  end
 end

 return hit_y,hit_x1,hit_x2,hit_draw_y
end

function land_lava(lava,surface_y,surface_x1,surface_x2,draw_y)
 local cx=flr(lava.x)
 lava.x1=max(surface_x1,cx-3)
 lava.x2=min(surface_x2,cx+4)
 if lava.x2<lava.x1 then lava.x2=lava.x1 end
 lava.x=(lava.x1+lava.x2)/2
 lava.surface_y=surface_y
 lava.draw_y=draw_y
 lava.y=surface_y
 lava.dy=0
 lava.landed=true
end

function update_lava()
 for lava in all(room.lava) do
  if lava.cooldown>0 then
   lava.cooldown-=1
  end

  if not lava.landed then
   lava.dy=min(lava.dy+0.18,1.6)
   local hit_y,hit_x1,hit_x2,hit_draw_y=lava_surface(lava)
   if hit_y then
    land_lava(lava,hit_y,hit_x1,hit_x2,hit_draw_y)
   else
    lava.y+=lava.dy
   end
  end
 end
end

function spawn_sand()
 add(sand,{x=flr(rnd(128)),y=0,dy=0.7+rnd(0.5),cooldown=0,resting=false})
end

function sand_surface(grain)
 local bottom=grain.y
 local next_bottom=grain.y+grain.dy
 local hit_y=nil

 if bottom<=floor_y and next_bottom>=floor_y then
  hit_y=floor_y+1
 end

 for solid in all(room.solids) do
  if grain.x>=solid.x1 and grain.x<=solid.x2
  and bottom<=solid.y1 and next_bottom>=solid.y1
  and (hit_y==nil or solid.y1<hit_y) then
   hit_y=solid.y1
  end
 end

 for platform in all(room.platforms) do
  if grain.x>=platform.x1 and grain.x<=platform.x2
  and bottom<=platform.y and next_bottom>=platform.y
  and (hit_y==nil or platform.y<hit_y) then
   hit_y=platform.y+1
  end
 end

 for other in all(sand) do
  if other.resting
  and other.x==grain.x
  and bottom<=other.y-1
  and next_bottom>=other.y-1
  and (hit_y==nil or other.y-1<hit_y) then
   hit_y=other.y-1
  end
 end

 return hit_y
end

function sand_spawn_delay()
 local min_delay=max(4,sand_base_min-(loop_count*2))
 local spread=max(8,sand_base_max-(loop_count*4))
 return min_delay+flr(rnd(spread))
end

function update_sand()
 sand_spawn_timer-=1
 if sand_spawn_timer<=0 then
  spawn_sand()
  sand_spawn_timer=sand_spawn_delay()
 end

 for grain in all(sand) do
  if grain.cooldown>0 then grain.cooldown-=1 end

  if not grain.resting then
   grain.dy=min(grain.dy+0.03,1.6)
   local hit_y=sand_surface(grain)

   if hit_y then
    grain.y=hit_y
    grain.dy=0
    grain.resting=true
    sfx(54)
   else
    grain.y+=grain.dy
    if grain.y>128 then del(sand,grain) end
   end
  end
 end
end

function body_bounds()
 local min_x=999
 local max_x=-999
 local min_y=999
 local max_y=-999

 for part in all(player.body) do
  min_x=min(min_x,part.x)
  max_x=max(max_x,part.x)
  min_y=min(min_y,part.y)
  max_y=max(max_y,part.y)
 end

 return min_x,max_x,min_y,max_y
end

function body_box()
 local min_x,max_x,min_y,max_y=body_bounds()
 return player.x+min_x,player.x+max_x,player.y+min_y,player.y+max_y
end

function normalize_body()
 local min_x,max_x,min_y,max_y=body_bounds()

 if min_x~=0 or min_y~=0 then
  for part in all(player.body) do
   part.x-=min_x
   part.y-=min_y
  end
  player.x+=min_x
  player.y+=min_y
 end

 player.size=max(max_x-min_x+1,max_y-min_y+1)
end

function has_body_part(px,py)
 for part in all(player.body) do
  if part.x==px and part.y==py then
   return true
  end
 end
 return false
end

function body_fits(test_body)
 local min_x=999
 local max_x=-999
 local min_y=999
 local max_y=-999

 for part in all(test_body) do
  min_x=min(min_x,part.x)
  max_x=max(max_x,part.x)
  min_y=min(min_y,part.y)
  max_y=max(max_y,part.y)
 end

 local left=player.x+min_x
 local right=player.x+max_x
 local top=player.y+min_y
 local bottom=player.y+max_y

 if left<0 or right>127 then return false end

 for wall in all(room.walls) do
  if bottom>=wall.y1 and top<=wall.y2 and left<=wall.x and right>=wall.x then
   return false
  end
 end

 for solid in all(room.solids) do
  if right>=solid.x1 and left<=solid.x2 and bottom>solid.y1 and top<=solid.y2 then
   return false
  end
 end

 return true
end

function body_with_candidate(candidate)
 local test_body={}
  for part in all(player.body) do
   add(test_body,{x=part.x,y=part.y})
  end
  add(test_body,{x=candidate.x,y=candidate.y})
  return test_body
end

function side_candidates(side,min_x,max_x,min_y,max_y)
 local candidates={}

 if side=="bottom" then
  for x=min_x,max_x do add(candidates,{x=x,y=max_y+1}) end
  add(candidates,{x=min_x-1,y=max_y+1})
  add(candidates,{x=max_x+1,y=max_y+1})
 elseif side=="top" then
  for x=min_x,max_x do add(candidates,{x=x,y=min_y-1}) end
  add(candidates,{x=min_x-1,y=min_y-1})
  add(candidates,{x=max_x+1,y=min_y-1})
 elseif side=="left" then
  for y=min_y,max_y do add(candidates,{x=min_x-1,y=y}) end
  add(candidates,{x=min_x-1,y=min_y-1})
  add(candidates,{x=min_x-1,y=max_y+1})
 else
  for y=min_y,max_y do add(candidates,{x=max_x+1,y=y}) end
  add(candidates,{x=max_x+1,y=min_y-1})
  add(candidates,{x=max_x+1,y=max_y+1})
 end

 return candidates
end

function first_legal_on_side(side,min_x,max_x,min_y,max_y)
 local candidates=side_candidates(side,min_x,max_x,min_y,max_y)
 for candidate in all(candidates) do
  if not has_body_part(candidate.x,candidate.y) then
   local test_body=body_with_candidate(candidate)
   if body_fits(test_body) then
    return candidate
   end
  end
 end
 return nil
end

function shuffled_fallback_sides(primary)
 local sides={primary}
 local fallback={"top","bottom","left","right"}

 for side in all(fallback) do
  if side~=primary then
   add(sides,side)
  end
 end

 for i=#sides,3,-1 do
  local j=flr(rnd(i-1))+2
  sides[i],sides[j]=sides[j],sides[i]
 end

 return sides
end

function rotated_body(turns)
 local min_x,max_x,min_y,max_y=body_bounds()
 local rotated={}

 for part in all(player.body) do
  local x=part.x-min_x
  local y=part.y-min_y
  local w=max_x-min_x
  local h=max_y-min_y

  if turns==1 then
   add(rotated,{x=h-y,y=x})
  elseif turns==2 then
   add(rotated,{x=w-x,y=h-y})
  else
   add(rotated,{x=y,y=w-x})
  end
 end

 return rotated
end

function shuffle_rotation_turns()
 local turns={1,2,3}
 for i=#turns,2,-1 do
  local j=flr(rnd(i))+1
  turns[i],turns[j]=turns[j],turns[i]
 end
 return turns
end

function rotate_player_shape()
 growth_fx_timer=8
 growth_fx_side="top"
 growth_fx_kind="hit"
 if #player.body<=1 then return end

 local turns=shuffle_rotation_turns()
 for turn in all(turns) do
  local test_body=rotated_body(turn)
  if body_fits(test_body) then
   player.body=test_body
   normalize_body()
   return
  end
 end
end

function attach_growth(side)
 growth_fx_side=side
 growth_fx_kind="hit"
 growth_fx_timer=8

 local min_x,max_x,min_y,max_y=body_bounds()
 local sides=shuffled_fallback_sides(side)

 for dir in all(sides) do
  local candidate=first_legal_on_side(dir,min_x,max_x,min_y,max_y)
  if candidate then
   add(player.body,{x=candidate.x,y=candidate.y})
   normalize_body()
   growth_fx_side=dir
   return
  end
 end
end

function shed_one_jump_pixel()
 if #player.body<=1 then return false end

 local min_x,max_x,min_y,max_y=body_bounds()
 local candidates={}

 for i=1,#player.body do
  local part=player.body[i]
  if part.x==min_x
  or part.x==max_x
  or part.y==min_y
  or part.y==max_y then
   add(candidates,i)
  end
 end

 if #candidates<=0 then return false end

 local idx=candidates[flr(rnd(#candidates))+1]
 deli(player.body,idx)
 normalize_body()
 return true
end

function shed_jump_pixels()
 local rolls=#player.body-1
 local lost=false

 for i=1,rolls do
  if #player.body>1 and rnd(1)<0.22 then
   lost=shed_one_jump_pixel() or lost
  end
 end

 if lost then
  sfx(11)
  growth_fx_timer=10
  growth_fx_side="top"
  growth_fx_kind="shed"
 end
end

function growth_side(growth)
 local prev_x=player.x-player.dx
 local prev_y=player.y-player.dy
 local left,right,top,bottom=body_box()
 local prev_left,prev_right,prev_top,prev_bottom=prev_x,prev_x+player.size-1,prev_y,prev_y+player.size-1

 if prev_bottom<growth.y then return "bottom" end
 if prev_top>growth.y then return "top" end
 if prev_right<growth.x then return "right" end
 if prev_left>growth.x then return "left" end

 local dx=growth.x-((left+right)/2)
 local dy=growth.y-((top+bottom)/2)
 if abs(dx)>abs(dy) then
  return dx<0 and "left" or "right"
 end
 return dy<0 and "top" or "bottom"
end

function _update60()
 if out_of_bounds_latched then
  if btnp(5) then
   tries+=1
   reset_run()
  end
  return
 end

 if level_cleared then
  if restart_pending then
   if btnp(4) then
    tries+=1
    reset_run()
   elseif btnp(5) then
    restart_pending=false
   end
   return
  end

  if level_cleared and next_room_id and btnp(4) then
   if next_room_id=="n" then
    loop_count+=1
   end
   room_id=next_room_id
   reset_run()
   return
  end

  if btnp(5) then
   restart_pending=true
   return
  end

  return
 end

 if restart_pending then
  if btnp(4) then
   tries+=1
   reset_run()
   return
  elseif btnp(5) then
   restart_pending=false
  end
  return
 end

 if(btnp(5)) then
  restart_pending=true
  return
 end

 update_player()
 update_lava()
 update_sand()
 check_lava()
 check_sand()
 check_goal()
 if growth_fx_timer>0 then
  growth_fx_timer-=1
 end
 update_out_of_bounds()
end

function update_player()
 local max_dx=max(0.7,1.2-((player.size-1)*0.08))
 local grav=0.15+((player.size-1)*0.02)
 local target_dx=0
 local response=player.grounded and 0.34 or 0.2
 local drag=player.grounded and 0.58 or 0.94

 if not btn(4) then
  player.jump_armed=true
 end

 if btn(0) then target_dx=-max_dx end
 if btn(1) then target_dx=max_dx end

 if btn(0) or btn(1) then
  player.dx+=(target_dx-player.dx)*response
 else
  player.dx*=drag
  if abs(player.dx)<0.03 then player.dx=0 end
 end

 if player.grounded and player.jump_armed and btn(4) then
  sfx(55)
  shed_jump_pixels()
  player.dy=-2.4+((player.size-1)*0.08)
  player.grounded=false
  player.jump_armed=false
 end

 player.dy+=grav
 player.x+=player.dx
 player.y+=player.dy

 collide_room()
end

function hit_player(side)
 sfx(46)
 attach_growth(side)
 rotate_player_shape()
end

function check_lava()
 local left,right,top,bottom=body_box()

 for lava in all(room.lava) do
  local lava_left=lava.x
  local lava_right=lava.x+1
  local lava_top=lava.y
  local lava_bottom=lava.y+1

  if lava.landed then
   lava_left=lava.x1
   lava_right=lava.x2
   lava_top=lava.surface_y
   lava_bottom=lava.draw_y
  end

  if lava.cooldown<=0
  and right>=lava_left
  and left<=lava_right
  and bottom>=lava_top
  and top<=lava_bottom then
   lava.cooldown=24
   if lava.landed then
    hit_player("top")
   else
    hit_player(growth_side(lava))
   end
  end
 end
end

function check_sand()
 local left,right,top,bottom=body_box()

 for grain in all(sand) do
  if not grain.resting
  and grain.cooldown<=0
  and right>=grain.x-1
  and left<=grain.x+1
  and bottom>=grain.y-1
  and top<=grain.y+1 then
   grain.cooldown=24
   hit_player(growth_side(grain))
   del(sand,grain)
  end
 end
end

function next_room_for(id)
 if id=="n" then return "z" end
 if id=="z" then return "m" end
 return "n"
end

function check_goal()
 local left,right,top,bottom=body_box()
 if right>=room.goal_x-2
 and left<=room.goal_x+2
 and bottom>=room.goal_y-2
 and top<=room.goal_y+2 then
  sfx(42)
  level_cleared=true
  next_room_id=next_room_for(room_id)
  player.dx=0
  player.dy=0
 end
end

function update_out_of_bounds()
 local _,_,_,bottom=body_box()
 if bottom>out_of_bounds_y then
  out_of_bounds_timer+=1
  if out_of_bounds_timer>=4 then
   sfx(16)
   out_of_bounds_latched=true
   player.dx=0
   player.dy=0
  end
 else
  out_of_bounds_timer=0
 end
end

function collide_room()
 local prev_x=player.x-player.dx
 local prev_y=player.y-player.dy
 local min_x,max_x,min_y,max_y=body_bounds()
 local left,right,top,bottom=body_box()
 local prev_left=prev_x+min_x
 local prev_right=prev_x+max_x
 local prev_top=prev_y+min_y
 local prev_bottom=prev_y+max_y
 player.grounded=false

 if left<0 then
  player.x-=left
  player.dx=0
  left,right,top,bottom=body_box()
 end
 if right>127 then
  player.x-=right-127
  player.dx=0
  left,right,top,bottom=body_box()
 end

 for wall in all(room.walls) do
  if bottom>=wall.y1 and top<=wall.y2 then
   if player.dx>0 and prev_right<wall.x and right>=wall.x then
    player.x=wall.x-max_x-1
    player.dx=0
    left,right,top,bottom=body_box()
   elseif player.dx<0 and prev_left>wall.x and left<=wall.x then
    player.x=wall.x-min_x+1
    player.dx=0
    left,right,top,bottom=body_box()
   end
  end
 end

 for solid in all(room.solids) do
  if bottom>=solid.y1 and top<=solid.y2 then
   if player.dx>0 and prev_right<solid.x1 and right>=solid.x1 then
    player.x=solid.x1-max_x-1
    player.dx=0
    left,right,top,bottom=body_box()
   elseif player.dx<0 and prev_left>solid.x2 and left<=solid.x2 then
    player.x=solid.x2-min_x+1
    player.dx=0
    left,right,top,bottom=body_box()
   end
  end
 end

 for grain in all(sand) do
  local sand_y=grain.y-1
  if grain.resting
  and player.dy>=0
  and prev_bottom<=sand_y
  and bottom>=sand_y
  and right>=grain.x
  and left<=grain.x then
   player.y=sand_y-max_y
   player.dy=0
   player.grounded=true
   left,right,top,bottom=body_box()
  end
 end

 if player.dy>=0 and prev_bottom<=floor_y and bottom>=floor_y then
  player.y=floor_y-max_y
  player.dy=0
  player.grounded=true
  left,right,top,bottom=body_box()
 end

 for solid in all(room.solids) do
  if right>=solid.x1 and left<=solid.x2 then
   if player.dy>=0 and prev_bottom<=solid.y1 and bottom>=solid.y1 then
    player.y=solid.y1-max_y
    player.dy=0
    player.grounded=true
    left,right,top,bottom=body_box()
   elseif player.dy<0 and prev_top>solid.y2 and top<=solid.y2 then
    player.y=solid.y2-min_y+1
    player.dy=0
    left,right,top,bottom=body_box()
   end
  end
 end

 for platform in all(room.platforms) do
  if player.dy>=0
  and prev_bottom<=platform.y
  and bottom>=platform.y
  and right>=platform.x1
  and left<=platform.x2 then
   player.y=platform.y-max_y
   player.dy=0
   player.grounded=true
   left,right,top,bottom=body_box()
  end
 end

end

function _draw()
 cls(1)
 draw_room()
 draw_sand()
 draw_player()
 pset(room.goal_x,room.goal_y,11)
 print("z jump",104,2,6)
 print("x restart",92,9,6)
 print("tries:"..tries,96,16,10)
 print("loop:"..loop_count,96,23,9)
 if level_cleared then
  rectfill(22,46,105,78,0)
  rect(22,46,105,78,11)
  print("goal reached",38,54,11)
  if next_room_id then
   print("z continue",36,62,11)
   print("x retry",44,70,7)
  else
   print("x retry",44,62,7)
  end
  if restart_pending then
   print("z confirm",42,70,11)
  end
 end
 if out_of_bounds_latched then
  rectfill(24,46,103,70,0)
  rect(24,46,103,70,8)
  print("falling out",38,54,8)
  print("x restart",42,62,7)
 elseif out_of_bounds_timer>0 then
  rectfill(24,46,103,70,0)
  rect(24,46,103,70,8)
  print("falling out",38,54,8)
  print("run collapsing",30,62,9)
 end
 if restart_pending and not out_of_bounds_latched then
  rectfill(16,48,111,80,0)
  rect(16,48,111,80,7)
  print("restart run?",34,56,7)
  print("z confirm",34,64,11)
  print("x cancel",34,72,8)
 end
end

function draw_player()
 for part in all(player.body) do
  pset(player.x+part.x,player.y+part.y,7)
 end

 if growth_fx_timer>0 then
  local left,right,top,bottom=body_box()

  if growth_fx_kind=="shed" then
   for i=1,5 do
    local fx_x=flr(rnd(right-left+1))+left
    local fx_y=top-1-i-flr(rnd(2))
    pset(fx_x,fx_y,(i%2==0) and 12 or 7)
   end
   circ(left+(right-left)/2,top-2,1,12)
  else
   for i=1,6 do
    local fx_x=player.x
    local fx_y=player.y

    if growth_fx_side=="bottom" then
     fx_x=flr(rnd(right-left+1))+left
     fx_y=bottom+flr(rnd(3))-1
    elseif growth_fx_side=="top" then
     fx_x=flr(rnd(right-left+1))+left
     fx_y=top-flr(rnd(3))+1
    elseif growth_fx_side=="left" then
     fx_x=left-flr(rnd(3))+1
     fx_y=flr(rnd(bottom-top+1))+top
    else
     fx_x=right+flr(rnd(3))-1
     fx_y=flr(rnd(bottom-top+1))+top
    end

    pset(fx_x,fx_y,(i%2==0) and 8 or 10)
   end
  end
 end
end

function draw_sand()
 for grain in all(sand) do
  pset(grain.x,grain.y,grain.resting and 9 or 10)
 end
end

function draw_room()
 line(0,floor_y+1,127,floor_y+1,5)

 for solid in all(room.solids) do
  rectfill(solid.x1,solid.y1+1,solid.x2,solid.y2,5)
  line(solid.x1,solid.y1,solid.x2,solid.y1,13)
 end

 for wall in all(room.walls) do
  line(wall.x,wall.y1,wall.x,wall.y2,13)
 end

 for platform in all(room.platforms) do
  rectfill(platform.x1,platform.y+1,platform.x2,platform.y+3,5)
  line(platform.x1,platform.y,platform.x2,platform.y,13)
 end

 for lava in all(room.lava) do
  local pulse=(sin(time()+lava.phase*6.283)*0.5)+0.5
  local color=pulse>0.5 and 8 or 10
  if lava.cooldown>0 then color=2 end

  if lava.landed then
   rectfill(lava.x1,lava.draw_y,lava.x2,lava.draw_y,color)
   for x=lava.x1,lava.x2,3 do
    pset(x,lava.draw_y,7)
   end
  else
   rectfill(lava.x,lava.y,lava.x+1,lava.y+1,color)
   pset(lava.x+1,lava.y+1,7)
  end
 end
end
__label__
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111666111116661616166616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111116111111611616166616161
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111161111111611616161616661
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111611111111611616161616111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111666111116611166161616111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111616111116661666116616661666166616661
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111616111116161611161111611616161611611
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111161111116611661166611611666166111611
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111616111116161611111611611616161611611
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111616111116161666166111611616161611611
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d11111111111aaa1aaa1aaa1aaa11aa11111a1a11111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d111111111111a11a1a11a11a111a1111a11a1a11111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d111111111111a11aa111a11aa11aaa11111aaa11111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d111111111111a11a1a11a11a11111a11a1111a11111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d111111111111a11a1a1aaa1aaa1aa11111111a11111
111111111111111111111111111111111111111111111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111191111111119111111111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111191991111111119911111111191111119111111911111111111111111111111d1111111111191111991199199911111999111111111
11111111111111111111119d99ddddd99dd99dd99dd9dd9ddd9dd9d9dddd911111111111111111111111d1111111111191119191919191911911911111111111
111111111111111111111199999995999999995997899595999559599995911111111111111111111111d1111111111191119191919199911111999111111111
111111111111111111111155555555555555555555555555555555555555511111111111111111111111d1111111111191119191919191111991119111111111
111111111111111111111155555555555555555555555555555555555555511111111111111111111111d1111111111199919911991191111191999111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111d9dd9d99ddddddd111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111999599999995559111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111555555555555555111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111555555555555555111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111a11111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111911111911111111111111111111111111111d11111111111111111111111111191111111111111d1111111111111111111111111111111111111111111
119dd99d9dd999ddd9dd9111111111111111111111d11111111111111111111111dddd9dddd9ddddd9d1d1111111111111111111111111111111111111111111
119559999559995959999111111111111111111111d11111111111111111111111599595959959555951d1111111111111111111911111111111111111111111
115555555555555555555111111111111111111111d11111111111111111111111555555555555555551d1111111111111111111911111111111111111111111
115555555555555555555111111111111111111111d11111111111111111111111555555555555555551d1111111111919111111911111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d111ddddd9d9d99dd9dd911111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1119555599999999955911111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1115555555555555555511111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1115555555555555555511111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111ddddddddddddddddd1d1ddddddddddddddd1111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111555555555555555551d15555555555555551111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111555555555555555551d15555555555555551111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111555555555555555551d15555555555555551111111111111111111111111d1111111111111111111111191111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d111111111111111111111119dddddddddddddddd111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111199555555555555555111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111155555555555555555111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111155555555555555555111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
11ddddddddddddddddd11111111111111111111111d1111111111111111111111111ddddddddddddddd1d1111111111111111111111111111111111111111111
115555555555555555511111111111111111111111d11111111111111111111111115555555555555551d1111111111111111111111111111111111111111111
115555555555555555511111111111111111111111d11111111111111111111111115555555555555551d1111111111111111111111111111111111111111111
115555555555555555511111111111111111111111d11111111111111111111111115555555555555551d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d111ddddddddddddd111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1115555555555555111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1115555555555555111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1115555555555555111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
11111111111111111111111111ddddddddddddddd1d111ddddddddddddddd11111111111111111111111d1111111111111111111111111111111111111111111
11111111111111111111111111555557aa7aa7a551d11155555555555555511111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111115555555555555551d11155555555555555511111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111115555555555555551d11155555555555555511111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111ddddddddddddddd111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111555555555555555111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111555555555555555111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111555555555555555111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d11111111111111111111111111111111111111111d1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11ddddddddddddddd1111111111111111111111111d1111111111111111111111111ddddddddddddddd111111111111111111111111111111111111111111111
115555555555555551111111111111111111111111d1111111111111111111111111555555555555555111111111111111111111111111111111111111111111
115555555555555551111111111111111111111111d1111111111111111111111111555555555555555111111111111111111111111111111111111111111111
115555555555555551111111111111111111111111d1111111111111111111111111555555555555555111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111d9ddddddddddd11111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111995555555555511111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111555555555555511111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111555555555555511111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d111111111111111111111111111111111111111111a111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111d1111111111111111111911111111111111111111111111111111111111111111111111111111111111111
191111111111111111111111111111111111111111d1111111111111111111911111111111111111111111111111111111111111111111111111111111111111
191111111111111111111111111111111111111111d1111111111111111111911111111111111111111111111111111111111111111111111111111111111111
191111117111111111111911111111111111111111d1111111111111111111911111111111111111111111111111111111111111111911111111111111111111
99555555555555555557897887855557887887855555555788788785555789989985555788788785555995555555555557aa7aa7a5595557aa7aa7a555555599
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111

__sfx__
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000180251f535260452a55512604176011b6011f601226012560128601296012b601296012760124601216011f6011c601186011560113601116010f6010e60500500005000050000500005000050000500
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00010000287770c700257770c700257670c700237570c700237570c700217470c700217370c7001e7370c7001c7270c7001c7170c70019717127050c700127050070000700007000070000700007000070000700
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0005000011574160741357418074155641a064165641b054185541d0541a7541f5441b044217441d544220441f744245342103426734220242772424014297140070400704007040070400704007040070400704
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000600001c36311000103331031310303107031070513005306041070310705000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000300001d61506323156002d60001600016000160002600026000360003600036000d60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000100000c0150c0050c005110350c0050c0050c00516055000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
00 00000000

