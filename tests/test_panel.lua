local source=assert(arg[1])
local panel=assert(loadfile(source..'/panel.lua'))()
local model=assert(loadfile(source..'/model.lua'))()
local catalogue=assert(loadfile(source..'/catalogue.lua'))()
local main,overlay={},{}
local worlds={main,overlay}
local width,height=3440,1440
local created,destroyed,updates,serial=0,0,0,0
local metric_calls,metric_characters=0,0
local rects,texts={},{}
local engine={Application={},World={},Gui={},Vector2={},IdString64={},Material={}}
setmetatable(engine.Vector2,{__call=function(_,x,y) return {x=x,y=y} end})
engine.Vector3=function(x,y,z) return {x=x,y=y,z=z} end
engine.Vector2.x=function(v) return v.x end
engine.Color=function(a,r,g,b) return {a=a,r=r,g=g,b=b} end
engine.IdString64.from_hex=function(value) assert(#value==16) return {hash=value} end
engine.Application.worlds=function() return worlds end
engine.Application.main_world=function() return main end
engine.World.create_screen_gui=function(w)
    assert(w==overlay)
    created=created+1
    rects={}
    return {id=created}
end
engine.World.destroy_gui=function(w,g) assert(w==overlay and g) destroyed=destroyed+1 end
engine.Gui.resolution=function() return width,height end
engine.Gui.material=function(g,m)
    assert(m.hash=='9f85b87d3ff20cbb')
    g.material=g.material or {gui=g,scalars={}}
    return g.material
end
engine.Material.set_texture=function(m,slot,texture)
    assert(slot.hash=='88bac99b00000000' and texture.hash=='d1ebb991c79f934b')
    m.atlas=texture.hash
end
engine.Material.set_scalar=function(m,slot,value) m.scalars[slot.hash]=value end
engine.Material.set_vector2=function(m,slot,value)
    assert(slot.hash=='e13777ce00000000' and value.x==1 and value.y==-1)
    m.range=true
end
engine.Material.set_vector4=function(m,slot,value)
    assert(slot.hash=='7701209e00000000' and value.a==0 and value.r==0 and value.g==0 and value.b==0)
    m.shadow=true
end
engine.Gui.rect=function(g,p,s,c)
    assert(p.x>=0 and p.y>=0 and s.x>0 and c.a>0)
    rects[#rects+1]={p=p,s=s,c=c}
    return #rects
end
engine.Gui.update_rect=function(g,id,p,s,c)
    assert(rects[id] and p.x>=0 and p.y>=0 and s.x>0)
    rects[id]={p=p,s=s,c=c}
end
local function span(t,size)
    local result=0
    local previous
    for c in t:gmatch('.') do
        result=result+size*(c=='W' and .9 or c=='I' and .25 or c==' ' and .3 or .55)
        if previous=='E' and c=='N' then result=result-.06*size end
        previous=c
    end
    return result
end
engine.Gui.text_extents=function(g,t,f,s)
    metric_calls=metric_calls+1
    metric_characters=metric_characters+#t
    assert(f.hash=='b56d2abac5d17df2', 'Native font ID lost')
    -- Ink bounds exclude trailing spaces and include side bearings. They
    -- are deliberately different from the caret, including zero advances.
    return {x=-.08*s},{x=span(t:gsub(' +$',''),s)+.04*s},{x=span(t,s)}
end
local function record(g,t,f,s,m,p,c)
    model.ascii(t)
    assert(g.material and g.material.atlas and g.material.range and g.material.shadow,
        'Native font material must be configured before drawing')
    for _,hash in ipairs({'8035c266','5e8455fe','309e7783','82b803a8'}) do
        assert(g.material.scalars[hash..'00000000']==0)
    end
    assert(f.hash=='b56d2abac5d17df2' and m.hash=='9f85b87d3ff20cbb')
    assert(p.x>=0 and p.x+span(t,s)<=width+1 and p.y<=height)
    texts[#texts+1]={text=t,p=p,size=s}
end
engine.Gui.text=function(...)
    record(...)
    serial=serial+1
    return serial
end
engine.Gui.update_text=function(g,id,...)
    assert(type(id)=='number')
    updates=updates+1
    record(g,...)
end
local function anchor()
    local s=math.min(width/1920,height/1080)
    return {x=(width-math.min(width,height*16/9))/2+54*s,y=height-510*s,w=533*s,h=371*s,
        scale=s,font='b56d2abac5d17df2',material='9f85b87d3ff20cbb',atlas='d1ebb991c79f934b'}
end
local surface=panel.new(engine)
for _,res in ipairs({{1280,720},{1920,1080},{2560,1440},{3440,1440},{5120,1440},{1280,1024}}) do
    width,height=unpack(res)
    local a=anchor()
    local box=panel.layout(width,height,a)
    assert(box.x==a.x and box.w==a.w and math.abs(box.y+box.h-box.border-a.y)<.001)
    surface:clear()
    for id in pairs(catalogue) do
        local m=model.make({key=tostring(id),screen='map',difficulty=10,tags={id},complete=false},catalogue)
        assert(surface:show(m,1/60,a))
        assert(#rects==8,'Inset body, four borders, two clipping margins and translucent rim required')
        assert(rects[3].p.y==box.y and rects[3].s.x==box.w,'Bottom border missing')
        assert(rects[5].p.x==box.x+box.w-box.border,'Right border misaligned')
        assert(rects[2].p.y==a.y,'The top stroke must share the native bottom border')
        assert(rects[1].p.x==box.x+box.inset and rects[1].p.y==box.y+box.inset)
        assert(rects[1].s.x==box.w-2*box.inset and rects[1].s.y==box.h-2*box.inset)
        assert(rects[1].c.r==15 and rects[1].c.g==20 and rects[1].c.b==30 and rects[1].c.a==255,
            'The body must use the native menu palette')
        assert(rects[2].c.r==255 and rects[2].c.g==185 and rects[2].c.b==0,
            'The outline must use native gold rather than the brighter heading color')
        assert(rects[8].c.a==204 and rects[8].c.r==0 and rects[8].p.z<rects[1].p.z,
            'The inset rim must remain translucent behind the opaque body')
        assert(rects[6].p.x==box.x+box.inset and rects[6].s.x==box.padding-box.inset)
        assert(rects[7].p.x+rects[7].s.x==box.x+box.w-box.inset,
            'Marquee clipping masks must not paint over the translucent rim')
        assert(#surface.cache_order<=8,'Report metric cache must remain bounded')
    end
end
-- Client previews use the left planet frame, including when its height changes.
for _,res in ipairs({{1280,720},{1920,1080},{3440,1440},{5120,1440},{1280,1024}}) do
    width,height=unpack(res)
    local s=math.min(width/1920,height/1080)
    local moving={x=54*s,y=300*s,w=533*s,h=350*s,scale=s,client=true,active=true,
        font='b56d2abac5d17df2',material='9f85b87d3ff20cbb',atlas='d1ebb991c79f934b'}
    local box=panel.layout(width,height,moving)
    assert(math.abs(box.y+box.h-box.border-moving.y)<.001,'Client forecast must share the planet frame border')
    surface:clear()
    local preview_model=model.make({key='joinable',screen='map',difficulty=10,tags={23},complete=true},catalogue)
    surface:show(preview_model,0,moving)
    local preview_gui=surface.gui
    for _=1,30 do
        moving.y=moving.y+s
        moving.h=moving.h-s
        surface:show(preview_model,1/60,moving)
        local expected=panel.layout(width,height,moving)
        assert(surface.gui==preview_gui and rects[1].p.x==expected.x+expected.inset
            and rects[1].p.y==expected.y+expected.inset,
            'Planet panel layout changes must move the existing forecast frame without recreating it')
    end
end
width,height=3440,1440
local a=anchor()
local m=model.make({key='new',screen='briefing',difficulty=10,tags={1,11},complete=true,
    heavies={'Bile Titans'}},catalogue)
assert(m.marquee:find('BILE BUGS') and m.marquee:find('DRAGONROACH ACTIVITY') and m.marquee:find('Bile Titans'))
surface:clear()
surface:show(m,0,a)
local before,first=created,texts[#texts]
assert(first.text=='' and math.abs(first.p.x-(a.x+a.w-30*a.scale))<.001,
    'First display must start hidden at the right edge')
surface:show(m,1/60,a)
surface:show(m,1/60,a)
assert(texts[#texts].p.x<first.p.x,'Marquee did not move left')
assert(texts[#texts].text=='[','Section marker must enter before the rest of the marquee')
local entry=surface.distance/surface.metrics.width
local changed=model.make({key='another',screen='briefing',difficulty=10,tags={3},complete=true},catalogue)
surface:show(changed,0,a)
assert(math.abs(surface.distance/surface.metrics.width-entry)<.000001,
    'Switching missions during entry restarted the marquee')
for _=1,180 do surface:show(changed,1/60,a) end
assert(texts[#texts].text:find('[HUNTER SWARMS]',1,true)==1,'Mission switch retained stale text')
surface:show(m,0,a)
before=created
for _=1,2400 do
    surface:show(m,1/60,a)
    local draw=texts[#texts]
    assert(draw.p.x>=a.x+3*a.scale and draw.p.x+span(draw.text,draw.size)<=a.x+a.w-3*a.scale,
        'Marquee leaked outside the native panel width')
end
assert(created==before and updates>2400,'Animated text must reuse the retained GUI')
local t1,x1=panel.window(surface.metrics,0,300)
local t2,x2=panel.window(surface.metrics,surface.metrics.period,300)
assert(t1==t2 and x1==x2,'Marquee loop is discontinuous')
assert(math.abs(surface.metrics.period-span(m.marquee..'      ',20*a.scale))<.001,
    'Marquee period must include trailing space advances')
for i=1,#surface.metrics.text do
    assert(math.abs(surface.metrics.edges[i+1]-span(surface.metrics.text:sub(1,i),20*a.scale))<.001,
        'Cached repeated-cycle carets differ from full-prefix proportional font measurements')
end
assert(surface.distance>0,'Test must reach the repeating portion of the marquee')
local phase=(surface.distance%surface.metrics.period)/surface.metrics.period
for _,next_model in ipairs({changed,m,changed,m}) do
    surface:show(next_model,0,a)
    assert(math.abs(surface.distance/surface.metrics.period-phase)<.000001,
        'Rapid mission switches must preserve relative scroll progress across different lengths')
end
before=created
local preliminary=model.make({key=m.key,screen=m.screen,difficulty=10,tags={1,11},complete=false},catalogue)
surface.distance=200
for _,refresh in ipairs({preliminary,m,preliminary,m}) do
    surface:show(refresh,0,a)
    assert(math.abs(surface.distance-200)<.001,
        'A same-mission intel refresh must not remap the scroll position')
end
assert(created==before,'Intel refreshes must reuse the GUI')
local warm_calls=metric_calls
for _,refresh in ipairs({preliminary,m,preliminary,m}) do surface:show(refresh,0,a) end
assert(metric_calls-warm_calls<=8,'Revisited reports must reuse their measured glyph positions')
warm_calls=metric_calls
a.x=a.x+15
a.y=a.y-24
surface:show(m,0,a)
assert(created==before and rects[1].p.x==a.x+7*a.scale,'Native movement must update retained rectangles')
assert(metric_calls==warm_calls,'Moving the native panel must not remeasure text')
local changed_footer={key=m.key,screen=m.screen,marquee=m.marquee,label=m.label,footer='Spawns are not guaranteed.'}
surface:show(changed_footer,0,a)
assert(created==before and metric_calls-warm_calls<=2,'Footer changes must not rebuild marquee metrics')
surface:clear()
assert(not surface.distance and not surface.gui)
surface:show(m,0,a)
assert(texts[#texts].text=='' and surface.distance<0,'Reopening must enter from the right')
surface:clear()
local cold_calls,cold_characters=metric_calls,metric_characters
surface:show(m,0,a)
assert(metric_calls-cold_calls<=#m.marquee+10,'Cold reports must only measure one cycle of prefixes')
assert(metric_characters-cold_characters < (#m.marquee+10)^2,
    'Repeated copies must not multiply cold font measurement work')
surface.distance=200
local saved_metrics,saved_cache=surface.metrics,surface.cache
local suspended_destroyed,suspended_created=destroyed,created
local saved_gui,saved_label,saved_footer=surface.gui,surface.label_id,surface.footer_id
local saved_rects=surface.rect_ids
warm_calls=metric_calls
surface:suspend(a)
surface:suspend(a)
assert(surface.gui==saved_gui and destroyed==suspended_destroyed and created==suspended_created,
    'Pending intel must not blink by destroying or recreating the forecast GUI')
assert(surface.label_id==saved_label and surface.footer_id==saved_footer and surface.rect_ids==saved_rects,
    'Pending intel must retain the heading, disclaimer and border elements')
assert(texts[#texts].text=='' and metric_calls==warm_calls,
    'Pending intel must clear stale enemy names without measuring a placeholder report')
assert(surface.distance==200 and surface.metrics==saved_metrics and surface.cache==saved_cache,
    'Pending mission data must retain scroll position and cached measurements')
a.x=a.x+3
assert(surface:suspend(a))
assert(rects[1].p.x==a.x+7*a.scale and surface.gui==saved_gui and metric_calls==warm_calls,
    'The retained panel must follow the native anchor while waiting')
surface:show(m,0,a)
assert(surface.distance==200 and metric_calls==warm_calls and surface.gui==saved_gui,
    'Resolved data must resume in the same GUI without a jump or remeasurement')
assert(texts[#texts].text~='','Resolved report did not restore its marquee')
surface:suspend(a)
local suspended_phase=surface.distance/surface.metrics.period
surface:show(changed,0,a)
assert(math.abs(surface.distance/surface.metrics.period-suspended_phase)<.000001,
    'A new resolved mission must preserve relative progress across a suspended interval')
surface:suspend(a)
overlay={}
worlds={main,overlay}
surface:show(m,0,a)
assert(surface.distance<0,'A changed world must still restart from the right after suspension')
worlds={main}
surface:show(m,0,a)
assert(not surface.gui and destroyed>0)
local closed_created=created
assert(not surface:suspend(a) and not surface.gui and created==closed_created,
    'Pending intel must not reopen a closed panel before the first complete report')
print('PASS: persistent pending frame, stale text clearing, resume continuity, bounded metric reuse, right-edge entry, proportional carets, clipping and cleanup at six resolutions')
