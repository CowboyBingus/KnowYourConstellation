local source = assert(arg[1])
local resolve = assert(loadfile(source..'/resolve.lua'))()
local catalogue = assert(loadfile(source..'/catalogue.lua'))()
local model = assert(loadfile(source..'/model.lua'))()
local function settings(weights)
    local ids = {1,2,3,5,7,6}
    local rows = {}
    for i,id in ipairs(ids) do rows[i] = {id=id,weight=weights[i],only_when_empty=false} end
    return {draws=1,candidates=rows,blockers={},fallback=0}
end
local low = settings({1,0.5,1,0.7,0.7,1})
local high = settings({1,0.8,1,0.2,0.5,1})
-- Settings are replaced below by recorded values generated from each native
-- capture. The comparisons exercise unsigned RNG output and float32 rounding.
local fixture = assert(loadfile(source..'/../tests/fixtures/seeds.lua'))()
for _, row in ipairs(fixture) do
    local got = resolve.base(row.seed,row.settings,row.initial)
    assert(table.concat(got,',') == table.concat(row.expected,','), 'Recorded seed mismatch: '..row.seed)
end
local fallback = {draws=1,candidates={},blockers={26,27,28,29,0},fallback=27}
assert(resolve.base(3,fallback,{})[1] == 27)
assert(table.concat(resolve.base(3,fallback,{26}),',') == '26')
local filtered = resolve.filter({1,11,9},1,{[9]=true})
assert(#filtered == 1 and filtered[1] == 11)
assert(not pcall(resolve.base,1,{draws=17,candidates={},blockers={},fallback=0},{}))
for id, entry in pairs(catalogue) do
    assert(id >= 1 and id <= 31)
    model.ascii(entry[1])
    model.ascii(entry[2])
end
local m = model.make({key='mission',screen='map',difficulty=10,tags={1,11},complete=false},catalogue)
assert(m.footer:find('incomplete'))
assert(m.marquee=='[BILE BUGS] Bile Spewers, Spitters, Bile Warriors    //    '..
    '[DRAGONROACH ACTIVITY] Dragon unit enabled by mission modifier    /// END REPORT ///')
assert(not pcall(model.ascii,'bad'..string.char(226,128,148)))
assert(not pcall(model.ascii,'bad'..string.char(59)))
local standard=model.make({key='standard',screen='map',difficulty=1,tags={},complete=true},catalogue)
assert(standard.marquee=='[STANDARD FORCES] No special constellation selected    /// END REPORT ///')
local unavailable=model.make({key='pending',screen='map',difficulty=1,tags={},complete=false},catalogue)
assert(unavailable.marquee:find('COMPOSITION UNAVAILABLE',1,true),
    'Unresolved data must not be presented as a standard composition')
print('PASS: recorded seed predictions, fallback, exclusions, modifier display and ASCII text')
assert(resolve.from_native(0)==0 and resolve.from_native(1)==31)
for id=2,31 do assert(resolve.from_native(id)==id-1) end
assert(not pcall(resolve.from_native,32))
assert(table.concat(resolve.filter({1,11,9},{[1]=true,[11]=true},{}),',')=='9')
