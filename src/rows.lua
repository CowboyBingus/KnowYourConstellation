-- Alternate view of the existing report model. Mission rules stay shared.
return function(base)
    local M = {}
    local function ascii(text)
        assert(type(text)=='string' and not text:find('[^\32-\126]') and not text:find(';',1,true),
            'Unsupported display text')
        return text
    end
    function M.rows(marquee)
        local text=assert(ascii(marquee):match('^(.*)    /// END REPORT ///$'), 'Invalid forecast report')
        assert(#text<=4096, 'Forecast exceeds row bounds')
        local rows,at={},1
        while true do
            local split=text:find('    //    ',at,true)
            local row=text:sub(at,split and split-1 or #text)
            assert(row:match('^%[.+%] .+$'), 'Invalid forecast row')
            rows[#rows+1]=row
            if not split then break end
            at=split+10
        end
        assert(#rows<=32, 'Too many forecast rows')
        return rows
    end
    function M.wrap(text,width,measure)
        local lines,line={},''
        for word in text:gmatch('%S+') do
            local next_line=line=='' and word or line..' '..word
            if measure(next_line)<=width then line=next_line else
                if line~='' then lines[#lines+1]=line end
                line=measure(word)<=width and word or ''
                for i=1,line=='' and #word or 0 do
                    local candidate=line..word:sub(i,i)
                    if measure(candidate)>width then
                        assert(line~='', 'Forecast column too narrow')
                        lines[#lines+1]=line
                        line=word:sub(i,i)
                    else line=candidate end
                end
            end
        end
        if line~='' then lines[#lines+1]=line end
        return lines
    end
    local function placement(width,height,anchor,box,h)
        local s=box.scale
        if h<=anchor.y-9*s then
            return {x=anchor.x,y=anchor.y-h+box.border,w=box.w,h=h,side=false}
        end
        -- Tall reports stay attached to the fixed native frame, using the
        -- space beside it rather than extending beyond the bottom edge.
        local x=anchor.x+anchor.w+12*s
        if x+box.w>width-12*s then x=anchor.x-box.w-12*s end
        local top=math.min(height-12*s,anchor.y+anchor.h)
        assert(x>=0 and x+box.w<=width and h<=top-12*s, 'Forecast rows exceed viewport')
        return {x=x,y=top-h,w=box.w,h=h,side=true}
    end
    function M.new(engine)
        local self={cache={},order={},text_ids={},rect_ids={}}
        local App,World,Gui=engine.Application,engine.World,engine.Gui
        local function worlds() return assert(App.worlds(), 'UI worlds unavailable') end
        local function contains(list,value)
            for _,v in ipairs(list) do if v==value then return true end end
            return false
        end
        local function destroy()
            if self.gui and contains(worlds(),self.world) then World.destroy_gui(self.world,self.gui) end
            self.gui,self.world,self.font_signature,self.draw_signature=nil,nil,nil,nil
            self.text_ids,self.rect_ids={},{}
            self.label_id,self.footer_id=nil,nil
        end
        function self:clear()
            destroy()
            self.content,self.label,self.footer,self.geometry=nil,nil,nil,nil
            self.cache,self.order={},{}
        end
        local function colour(a,r,g,b) return engine.Color(a,r,g,b) end
        local function vector(x,y,z) return engine.Vector3(x,y,z or 0) end
        local function fit(model,font,box,anchor,width,height)
            local key=table.concat({model.marquee,anchor.font,box.scale,box.w},'|')
            local choices=self.cache[key]
            if not choices then
                choices={}
                self.cache[key]=choices
                self.order[#self.order+1]=key
                if #self.order>8 then self.cache[table.remove(self.order,1)]=nil end
            end
            if not choices.rows then choices.rows=M.rows(model.marquee) end
            local rows=choices.rows
            local available=box.w-2*box.padding
            local function candidate(size)
                if choices[size] then return choices[size] end
                local lines,top={},49*box.scale
                local measure_cache={}
                local function measure(text)
                    if not measure_cache[text] then
                        local lo,hi,caret=Gui.text_extents(self.gui,text,font,size)
                        assert(lo and hi and caret, 'Font metrics unavailable')
                        measure_cache[text]=math.max(engine.Vector2.x(hi),engine.Vector2.x(caret))
                            -math.min(0,engine.Vector2.x(lo))
                    end
                    return measure_cache[text]
                end
                for row_index,row in ipairs(rows) do
                    for _,text in ipairs(M.wrap(row,available,measure)) do
                        lines[#lines+1]={text=text,top=top}
                        top=top+size*1.2
                    end
                    if row_index<#rows then top=top+5*box.scale end
                end
                local h=lines[#lines].top+33*box.scale
                choices[size]={lines=lines,size=size,h=h}
                return choices[size]
            end
            local result
            for _,size in ipairs({20,18,16,14}) do
                local test=candidate(size*box.scale)
                if test.h<=anchor.y-9*box.scale then result=test break end
            end
            if not result then
                local top=math.min(height-12*box.scale,anchor.y+anchor.h)
                for _,size in ipairs({20,18,16,14,12}) do
                    local test=candidate(size*box.scale)
                    if test.h<=top-12*box.scale then result=test break end
                end
            end
            assert(result, 'Forecast rows exceed viewport')
            placement(width,height,anchor,box,result.h)
            return result
        end
        function self:show(model,dt,anchor)
            local main,target=App.main_world(),nil
            for _,world in ipairs(worlds()) do if world~=main then target=world break end end
            if not target then self:clear() return false end
            if self.world and self.world~=target then self:clear() end
            local width,height=Gui.resolution()
            local box=base.layout(width,height,anchor)
            local font=engine.IdString64.from_hex(anchor.font)
            local material=engine.IdString64.from_hex(anchor.material)
            local font_signature=table.concat({anchor.font,anchor.material,anchor.atlas},'|')
            if not self.gui or self.font_signature~=font_signature then
                destroy()
                self.gui=assert(World.create_screen_gui(target,'scale',1,1), 'Could not create forecast rows')
                self.world=target
                local ink=assert(Gui.material(self.gui,material), 'Font material unavailable')
                local function slot(hash) return engine.IdString64.from_hex(hash..'00000000') end
                for _,hash in ipairs({'8035c266','5e8455fe','309e7783','82b803a8'}) do
                    engine.Material.set_scalar(ink,slot(hash),0)
                end
                engine.Material.set_vector2(ink,slot('e13777ce'),engine.Vector2(1,-1))
                engine.Material.set_vector4(ink,slot('7701209e'),colour(0,0,0,0))
                engine.Material.set_texture(ink,slot('88bac99b'),engine.IdString64.from_hex(anchor.atlas))
                self.font_signature=font_signature
            end
            if model.marquee then self.content=fit(model,font,box,anchor,width,height) end
            local content=assert(self.content, 'No complete row report')
            local geometry=placement(width,height,anchor,box,content.h)
            local label,footer=ascii(model.label),ascii(model.footer)
            local signature=table.concat({model.marquee or '',label,footer,geometry.x,geometry.y,box.w,content.h,content.size,box.scale},'|')
            if signature==self.draw_signature then return true end
            local x,y,w,h,s,b,i,p=geometry.x,geometry.y,box.w,content.h,box.scale,box.border,box.inset,box.padding
            local function rect(index,rx,ry,rw,rh,z,ink)
                local pos,size=vector(rx,ry,z),engine.Vector2(rw,rh)
                if self.rect_ids[index] then Gui.update_rect(self.gui,self.rect_ids[index],pos,size,ink)
                else self.rect_ids[index]=assert(Gui.rect(self.gui,pos,size,ink)) end
            end
            local border,background=colour(255,255,185,0),colour(255,15,20,30)
            rect(1,x+i,y+i,w-2*i,h-2*i,901,background)
            rect(2,x,y+h-b,w,b,904,border)
            rect(3,x,y,w,b,904,border)
            rect(4,x,y,b,h,904,border)
            rect(5,x+w-b,y,b,h,904,border)
            rect(6,x+b,y+b,w-2*b,h-2*b,900,colour(204,0,0,0))
            local function text(id,value,size,top,ink)
                local pos=vector(x+p,y+h-top,902)
                if id then Gui.update_text(self.gui,id,value,font,size,material,pos,ink) return id end
                return assert(Gui.text(self.gui,value,font,size,material,pos,ink))
            end
            local function caption(value,size)
                local lo,hi=Gui.text_extents(self.gui,value,font,size)
                local measured=engine.Vector2.x(hi)-engine.Vector2.x(lo)
                if measured>w-2*p then size=size*(w-2*p)/measured end
                assert(size>=10*s, 'Forecast caption exceeds panel width')
                return size
            end
            self.label_id=text(self.label_id,label,caption(label,box.title_size),24*s,colour(255,255,213,0))
            self.footer_id=text(self.footer_id,footer,caption(footer,box.small_size),h-14*s,colour(255,179,198,205))
            for index=1,math.max(#content.lines,#self.text_ids) do
                local line=content.lines[index]
                self.text_ids[index]=text(self.text_ids[index],model.marquee and line and line.text or '',
                    content.size,line and line.top or 49*s,colour(255,240,243,245))
            end
            self.label,self.footer,self.geometry=label,footer,geometry
            self.draw_signature=signature
            return true
        end
        function self:suspend(anchor)
            if not self.gui then return false end
            return self:show({label=self.label,footer=self.footer},0,anchor)
        end
        return self
    end
    return M
end
