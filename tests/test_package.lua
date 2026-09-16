-- Compiled wrapper startup is lazy and the shared guard permits one instance.
local path,revision=assert(arg[1]),assert(arg[2])
local calls,stops,libraries=0,0,0
local ffi=setmetatable({cdef=function() end,load=function()
    libraries=libraries+1
    error('No game runtime in package test')
end}, {__index=require('ffi')})
local env=setmetatable({os={},print=function() end}, {__index=_G})
env._G=env
env.require=function(name) return name=='ffi' and ffi or require(name) end
env.update=function(dt,marker) calls=calls+1 return 1,nil,marker end
env.shutdown=function() stops=stops+1 end
local function load() setfenv(assert(loadfile(path)),env)() end
load()
local callback=env.update
assert(env.EnemyIntelligence.revision==revision and env.EnemyIntelligence.status=='starting')
assert(libraries==0,'Loading the wrapper must not access the game before the first update')
load()
assert(env.update==callback,'Loading the same module twice must not install another callback')
local a,b,c=env.update(.01,'marker')
assert(a==1 and b==nil and c=='marker' and calls==1)
assert(env.EnemyIntelligence.status:find('disabled:',1,true))
env.update(.01)
assert(libraries==1,'Failed initialization must stay disabled without repeated library loads')
env.shutdown()
assert(stops==1)
print('PASS: compiled package revision, lazy startup, shared one-copy guard and callback preservation')
