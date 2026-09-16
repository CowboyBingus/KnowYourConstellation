local M = {}

function M.possible(snapshot,data)
    if snapshot.faction ~= 2 or not snapshot.complete then return {} end
    local tags = {}
    for _,tag in ipairs(snapshot.tags) do tags[tag]=true end
    local difficulty = snapshot.difficulty
    local function accepts(required)
        if #required == 0 then return true end
        for _,tag in ipairs(required) do if tags[tag] then return true end end
        return false
    end
    local families = {}
    for _,group in ipairs(data.groups) do
        local weight = group.overrides[difficulty]
        if weight == nil then weight = group.weight end
        if difficulty >= group.min and difficulty <= group.max and weight > 0
            and group.players_min <= 4 and group.players_max >= 1 and accepts(group.tags) then
            for _,family in ipairs(group.members) do families[family]=true end
        end
    end
    local resources = {}
    for _,unit in ipairs(data.units) do
        if families[unit.family] and unit.weights[difficulty] > 0 and accepts(unit.tags) then
            local resource = unit.resource
            local priority = 0
            for _=1,5 do
                local best
                for _,rule in ipairs(data.swaps) do
                    if rule.source==resource and tags[rule.tag] and difficulty>=rule.min and difficulty<=rule.max
                        and rule.priority>=priority and (not best or rule.priority>best.priority) then best=rule end
                end
                if not best then break end
                resource=best.target
                priority=best.priority
            end
            if data.labels[resource] then resources[data.labels[resource]]=true end
        end
    end
    local result = {}
    for label in pairs(resources) do result[#result+1]=label end
    table.sort(result)
    return result
end

return M
