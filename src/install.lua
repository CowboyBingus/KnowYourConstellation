return function(create_api,mission,resolve,catalogue,model,panel,build,heavy,heavy_data,presentation)
    if rawget(_G,'EnemyIntelligence') then return end
    local state = {revision=build.revision,status='starting',reads=0,frames=0,failures=0}
    rawset(_G,'EnemyIntelligence',state)
    local api,source,surface,current,view
    local started, elapsed = false, 0
    local selected_key,selected_screen,controller_matches
    local previous = update
    local function report(message)
        if state.status == message then return end
        state.status = message
        print('[EnemyIntelligence] '..message)
        pcall(function()
            local directory = os.getenv('LOCALAPPDATA')
            if not directory then return end
            local file = io.open(directory..'/EnemyIntelligence.log','w')
            if file then
                file:write(build.revision..'\n'..message..'\n')
                file:close()
            end
        end)
    end
    local function initialize()
        if started then return source ~= nil end
        started = true
        local ok,why = pcall(function()
            api = create_api()
            local game,exe = assert(api.module('game.dll')),assert(api.module(nil))
            assert(api.module_hash(game) == build.game_sha256, 'Unsupported game module')
            assert(api.module_hash(exe) == build.exe_sha256, 'Unsupported executable')
            assert(stingray and stingray.Gui and stingray.World, 'Game GUI unavailable')
            source = mission.new(api,game,resolve)
            surface = panel.new(stingray)
            view = presentation.new(api,game)
        end)
        if not ok then
            source = nil
            report('disabled: '..tostring(why))
            return false
        end
        report('ready')
        return true
    end
    local function reset_selection()
        current,selected_key,selected_screen,controller_matches = nil,nil,nil,nil
        elapsed = 0
        state.key,state.screen,state.complete = nil,nil,false
    end
    local function select(descriptor)
        if not descriptor then
            current,selected_key,controller_matches = nil,nil,false
            state.key,state.complete = nil,false
            elapsed = 0
            return
        end
        local changed = selected_key ~= descriptor.key or selected_screen ~= descriptor.screen
        if changed then
            if selected_screen and selected_screen ~= descriptor.screen then surface:clear() end
            current = nil
        end
        -- Check identity every frame. Resolve immediately when the controller
        -- catches up, then poll unresolved inputs at a bounded 100 ms cadence.
        if changed or descriptor.controller_matches and not controller_matches then elapsed = 0.5 end
        controller_matches = descriptor.controller_matches == true
        if not controller_matches then current = nil end
        selected_key,selected_screen = descriptor.key,descriptor.screen
        state.key,state.screen = selected_key,selected_screen
    end
    local function frame(dt)
        if not initialize() then return end
        state.frames = state.frames+1
        local screen = source:screen()
        local anchor = screen and view:sample(screen)
        if not anchor then
            reset_selection()
            surface:clear()
            report('hidden')
            return
        end
        if selected_screen and selected_screen~=screen then
            reset_selection()
            surface:clear()
        end
        selected_screen,state.screen = screen,screen
        local descriptor,hovered = source:descriptor(screen)
        -- Native selection ends before the card's fade. Hide immediately on
        -- unhover, but retain the frame while a hovered mission is loading.
        if anchor.client and (hovered==false or hovered==nil and not anchor.active) then
            reset_selection()
            surface:clear()
            report('hidden')
            return
        end
        select(descriptor)
        elapsed = elapsed + math.max(0,dt or 0)
        if controller_matches and elapsed >= (current and 0.5 or 0.1) then
            elapsed = 0
            local snapshot = source:sample(screen)
            state.reads = state.reads+1
            if source:screen() ~= screen then
                reset_selection()
                surface:clear()
                report('hidden')
                return
            end
            local latest,latest_hovered = source:descriptor(screen)
            if anchor.client and latest_hovered==false then
                reset_selection()
                surface:clear()
                report('hidden')
                return
            end
            select(latest)
            current = nil
            -- Publish the marquee and footer together, only from a complete
            -- snapshot belonging to the selection both before and after reads.
            if snapshot and snapshot.complete == true and snapshot.controller_matches == true and controller_matches
                and snapshot.key == descriptor.key and snapshot.key == selected_key
                and snapshot.screen == screen and selected_screen == screen then
                if heavy then snapshot.heavies = heavy.possible(snapshot,heavy_data) end
                current = model.make(snapshot,catalogue)
            end
        end
        state.complete = current ~= nil
        if not current then
            surface:suspend(anchor)
            report('waiting for mission data '..screen..' '..(selected_key or 'preview loading'))
            return
        end
        local drawn = surface:show(current,dt,anchor)
        report((drawn and 'visible ' or 'waiting for GUI ')..screen..' '..current.key..' composition rules resolved')
    end
    local function after(dt,...)
        local ok,why = pcall(frame,dt)
        if not ok then
            state.failures = state.failures+1
            reset_selection()
            if surface then pcall(function() surface:clear() end) end
            report('hidden: '..tostring(why))
        end
        return ...
    end
    update = function(dt,...)
        if previous then return after(dt,previous(dt,...)) end
        after(dt)
    end
    local old_shutdown = shutdown
    shutdown = function(...)
        if surface then pcall(function() surface:clear() end) end
        if old_shutdown then return old_shutdown(...) end
    end
end
