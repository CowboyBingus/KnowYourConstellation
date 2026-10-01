local source = assert(arg[1])
local install = assert(loadfile(source..'/install.lua'))()
local model = assert(loadfile(source..'/model.lua'))()
local resolve = assert(loadfile(source..'/resolve.lua'))()
local roster = assert(loadfile(source..'/roster.lua'))()
local roster_data = assert(loadfile(source..'/roster_data.lua'))()
local text = assert(loadfile(source..'/bingus_text.lua'))()
local english = assert(loadfile(source..'/../locales/en.lua'))()
local env = setmetatable({stingray={Gui={},World={}},print=function() end,os={},io=io}, {__index=_G})
env._G = env
env.update = function() end
setfenv(install,env)(function() error('No game') end,{},resolve,roster,roster_data,model,{},
    {revision='test',game_sha256='same',exe_sha256='same'},{},text,{en=english,bundled={}})
-- Published before the first frame, so other mods can check it while loading.
local exported = assert(env.EnemyIntelligence.roster,'Roster export missing')
assert(exported.api==1 and exported.build==roster_data.build)
assert(exported.from_native(1)==31 and exported.from_native(9)==8 and exported.from_native(0)==0)
assert(exported.title(8)=='PREDATOR STRAIN' and exported.title(31)=='HORDE' and exported.title(0)==nil)

-- Same result as the panel's roster, with English names instead of indexes.
local snapshot = {faction=2,difficulty=10,tags={exported.from_native(9)}}
local expected = roster.compute(roster_data,snapshot)
local result = exported.forecast(snapshot)
assert(#result.large==#expected.large and #result.small==#expected.small and #result.large>0)
for i,entry in ipairs(expected.large) do
    assert(result.large[i].name==roster_data.names[entry[1]][1] and result.large[i].ticks==entry[2])
end
for i,name in ipairs(expected.small) do assert(result.small[i]==roster_data.names[name][1]) end
local predators = false
for _,name in ipairs(result.small) do predators = predators or name=='Predator Hunters' end
assert(predators,'Predator Strain must replace Hunters with Predator Hunters')

-- Modifiers pass through, and invalid input raises for the caller's pcall.
assert(pcall(exported.forecast,snapshot,{},{}))
assert(not pcall(exported.forecast,{faction=9,difficulty=10,tags={}}),'Unknown faction must raise')
assert(not pcall(exported.forecast,{faction=2,difficulty=11,tags={}}),'Invalid difficulty must raise')
print('PASS: roster export api, titles, tag conversion and forecast parity')
