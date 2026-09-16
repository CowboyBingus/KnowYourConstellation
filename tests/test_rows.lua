local source=assert(arg[1])
local base=assert(loadfile(source..'/panel.lua'))()
local panel=assert(loadfile(source..'/rows.lua'))()(base)
local model=assert(loadfile(source..'/model.lua'))()
local catalogue=assert(loadfile(source..'/catalogue.lua'))()
local width,height=3440,1440
local main,overlay={},{}
local worlds={main,overlay}
local created,destroyed,measured,drawn=0,0,0,0
local rects,texts={},{}
local engine={Application={},World={},Gui={},Material={},Vector2={},IdString64={}}
setmetatable(engine.Vector2,{__call=function(_,x,y) return {x=x,y=y} end})
engine.Vector2.x=function(v) return v.x end
engine.Vector3=function(x,y,z) return {x=x,y=y,z=z} end
engine.Color=function(a,r,g,b) return {a=a,r=r,g=g,b=b} end
engine.IdString64.from_hex=function(hash) return {hash=hash} end
engine.Application.main_world=function() return main end
engine.Application.worlds=function() return worlds end
engine.Gui.resolution=function() return width,height end
engine.World.create_screen_gui=function(w)
    assert(w==overlay)
    created=created+1
    rects,texts={},{}
    return {}
end
engine.World.destroy_gui=function(w,g) assert(w==overlay and g) destroyed=destroyed+1 end
engine.Gui.material=function(g,m)
    assert(m.hash=='9f85b87d3ff20cbb')
    g.ink={scalars={}}
    return g.ink
end
engine.Material.set_scalar=function(m,key,value) m.scalars[key.hash]=value end
engine.Material.set_vector2=function(m,key,value)
    assert(key.hash=='e13777ce00000000' and value.x==1 and value.y==-1)
    m.range=true
end
engine.Material.set_vector4=function(m,key,value)
    assert(key.hash=='7701209e00000000' and value.a==0)
    m.shadow=true
end
engine.Material.set_texture=function(m,key,value)
    assert(key.hash=='88bac99b00000000' and value.hash=='d1ebb991c79f934b')
    m.atlas=true
end
local function span(text,size)
    local n=0
    for c in text:gmatch('.') do n=n+size*(c=='W' and .9 or c=='I' and .25 or c==' ' and .3 or .55) end
    return n
end
engine.Gui.text_extents=function(g,text,font,size)
    measured=measured+1
    assert(font.hash=='b56d2abac5d17df2')
    return {x=-.08*size},{x=span(text,size)+.04*size},{x=span(text,size)}
end
local function rectangle(pos,size,colour)
    assert(pos.x>=0 and pos.y>=0 and pos.x+size.x<=width+1 and pos.y+size.y<=height+1)
    return {p=pos,s=size,c=colour}
end
engine.Gui.rect=function(g,p,s,c) rects[#rects+1]=rectangle(p,s,c) return #rects end
engine.Gui.update_rect=function(g,id,p,s,c) rects[id]=rectangle(p,s,c) end
local function text(g,value,font,size,material,pos,colour)
    model.ascii(value)
    assert(g.ink.atlas and g.ink.range and g.ink.shadow)
    for _,hash in ipairs({'8035c266','5e8455fe','309e7783','82b803a8'}) do assert(g.ink.scalars[hash..'00000000']==0) end
    assert(font.hash=='b56d2abac5d17df2' and material.hash=='9f85b87d3ff20cbb')
    assert(pos.x>=0 and pos.y>=0 and pos.y+size<=height and pos.x+span(value,size)<=width+1)
    drawn=drawn+1
    return {value=value,size=size,p=pos,c=colour}
end
engine.Gui.text=function(...) texts[#texts+1]=text(...) return #texts end
engine.Gui.update_text=function(g,id,...) texts[id]=text(g,...) end
local function anchor()
    local s=math.min(width/1920,height/1080)
    return {x=(width-math.min(width,height*16/9))/2+54*s,y=height-510*s,w=533*s,h=371*s,
        scale=s,font='b56d2abac5d17df2',material='9f85b87d3ff20cbb',atlas='d1ebb991c79f934b'}
end
local function report(tags,key)
    return model.make({key=key or 'mission',screen='map',difficulty=10,complete=true,tags=tags,
        heavies={'Bile Titans','Dragonroaches','Gloom Bile Titans'}},catalogue)
end
local function visible(surface)
    local parts={}
    for _,id in ipairs(surface.text_ids) do parts[#parts+1]=texts[id].value end
    return table.concat(parts,' '):gsub('%s+',' '):gsub(' $','')
end
local function expected(m) return table.concat(panel.rows(m.marquee),' '):gsub('%s+',' ') end
local surface=panel.new(engine)
for _,res in ipairs({{1280,720},{1920,1080},{2560,1440},{3440,1440},{5120,1440},{1280,1024}}) do
    width,height=unpack(res)
    local a=anchor()
    surface:clear()
    for id=1,30 do
        local m=report({id})
        assert(surface:show(m,0,a) and visible(surface)==expected(m),'First frame must show every row and enemy')
        assert(not visible(surface):find('END REPORT',1,true))
        assert(#rects==6 and rects[1].c.r==15 and rects[1].c.g==20 and rects[1].c.b==30)
        assert(rects[2].c.r==255 and rects[2].c.g==185 and rects[2].c.b==0 and rects[6].c.a==204)
        for _,line in ipairs(surface.content.lines) do
            assert(span(line.text,surface.content.size)<=a.w-60*a.scale, 'Wrapped text escaped its column')
        end
    end
    local all={}
    for id=1,30 do all[#all+1]=id end
    local many=report(all)
    assert(surface:show(many,0,a) and visible(surface)==expected(many),'Tall reports must not truncate or paginate')
    local shallow=anchor()
    shallow.y,shallow.h=140*a.scale,height-160*a.scale
    assert(surface:show(many,0,shallow) and visible(surface)==expected(many))
    assert(surface.geometry.side,'Reports that cannot fit below need the space beside the native frame')
    local one=report({1},'one')
    surface:show(one,0,a)
    assert(visible(surface)==expected(one),'Shrinking reports must clear unused text IDs')
    assert(not surface.geometry.side and math.abs(rects[2].p.y-a.y)<.001,'Ordinary rows share the native bottom border')
    local old_created,old_measured,old_drawn=created,measured,drawn
    for _=1,120 do surface:show(one,1/60,a) end
    assert(created==old_created and measured==old_measured and drawn==old_drawn,'Static rows must not redraw or remeasure every frame')
    local saved_gui=surface.gui
    surface:suspend(a)
    assert(visible(surface)=='' and surface.gui==saved_gui,'Pending reports clear enemy rows without blinking the frame')
    a.x=a.x+3
    surface:suspend(a)
    surface:show(one,0,a)
    assert(visible(surface)==expected(one) and surface.gui==saved_gui,'Resolved report must reuse the retained GUI')
    assert(measured-old_measured<=6,'Native movement must reuse wrapped text measurements')
    surface:clear()
    assert(not surface.gui and not surface:suspend(a),'Unhover or closed panels cannot retain or recreate chrome')
end
assert(not pcall(panel.rows,'invalid report'))
local wrapped=panel.wrap(string.rep('W',80),40,function(value) return #value*10 end)
assert(table.concat(wrapped)==string.rep('W',80),'Long tokens must wrap without losing characters')
local a=anchor()
surface:show(report({1}),0,a)
overlay={}
worlds={main,overlay}
surface:show(report({3}),0,a)
assert(visible(surface)==expected(report({3})))
worlds={main}
assert(not surface:show(report({3}),0,a) and not surface.gui)
assert(destroyed>0)

-- Exercise the real installer and renderer together through menu transitions.
worlds={main,overlay}
local screen,key,ready,complete,hovered='map','hosted',true,true,true
local native=anchor()
local reader={}
function reader:screen() return screen end
function reader:descriptor() return {key=key,screen=screen,controller_matches=true},hovered end
function reader:sample()
    return {key=key,screen=screen,tags={1,5},difficulty=10,complete=complete,controller_matches=true}
end
local env=setmetatable({stingray=engine,print=function() end,os={}}, {__index=_G})
env._G=env
local install=assert(loadfile(source..'/install.lua'))()
setfenv(install,env)(function()
    return {module=function() return 1 end,module_hash=function() return 'supported' end}
end,{new=function() return reader end},{},catalogue,model,{new=function() return surface end},
    {revision='rows-test',game_sha256='supported',exe_sha256='supported'},nil,nil,
    {new=function() return {sample=function() return ready and native or nil end} end})
env.update(.01)
assert(surface.gui and visible(surface)==expected(model.make(reader:sample(),catalogue)))
local saved_gui=surface.gui
key,complete='new-hosted',false
env.update(.01)
assert(surface.gui==saved_gui and visible(surface)=='','Pending missions must blank rows without recreating chrome')
complete=true
env.update(.101)
assert(surface.gui==saved_gui and visible(surface)==expected(model.make(reader:sample(),catalogue)))
screen,ready='briefing',false
env.update(0)
assert(not surface.gui,'Pod entry must hide the rows panel')
ready=true
env.update(.01)
assert(surface.gui and visible(surface)~='','Ready briefing must show all rows immediately')
ready=false
env.update(0)
assert(not surface.gui,'Loadout must hide rows and frame together')
screen,key,ready='map','joinable',true
native.client,native.active=true,true
env.update(.01)
assert(surface.gui)
hovered=false
env.update(0)
assert(not surface.gui,'Client unhover must destroy all rows and chrome on the same frame')
env.update(.5)
assert(not surface.gui,'Dismissed rows cannot reappear from a refresh')
hovered=true
env.update(.01)
assert(surface.gui and visible(surface)~='')
env.shutdown()
assert(not surface.gui and env.EnemyIntelligence.failures==0)
print('PASS: all 30 constellations and heavy rows, six resolutions, complete first-frame text, wrapping, tall-panel fallback, native style, retained updates, pending clearing and installer visibility integration')
