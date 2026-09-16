"""Build the local-only Know Your Constellation release without deploying it."""
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import zipfile

sys.dont_write_bytecode = True
from archive import GAME, LUA, EXE_SHA, GAME_DLL_SHA, ARCHIVE, sha, make_archive, resource_hash
from module import MODULE, REVISION, TESTED_RESOURCE_SHA, wrapper
from package import package_release

ROOT = Path(__file__).resolve().parents[1]
GUID = '9a9c8423-8f3e-4b7b-9a16-7d0b78ff1a18'
SUMMARY = 'Reveals mission constellations and enemy forecasts on the war table and briefing screen so you can choose your loadout before deployment.'


def run(arguments):
    env = dict(os.environ, LUA_PATH=str(LUA.parent / '?.lua') + ';;')
    process = subprocess.run(list(map(str, arguments)), capture_output=True, text=True, env=env)
    if process.returncode:
        raise RuntimeError(process.stdout + process.stderr)
    return process.stdout


def main():
    build = ROOT / 'build'
    build.mkdir(exist_ok=True)
    for filename, expected in [('bin/helldivers2.exe', EXE_SHA), ('data/game/game.dll', GAME_DLL_SHA)]:
        assert sha((GAME / filename).read_bytes()) == expected, 'Unsupported game build'
    source = build / 'mod.wrapper.lua'
    source.write_text(wrapper(ROOT, GAME_DLL_SHA, EXE_SHA), encoding='ascii', newline='\n')
    tests = ''
    for name in ('resolve', 'panel', 'install', 'mission', 'heavy', 'presentation'):
        tests += run([LUA, ROOT / ('tests/test_' + name + '.lua'), ROOT / 'src'])
    compiled = build / 'mod.ljbc'
    run([LUA, '-bsdW', source, compiled])
    code = compiled.read_bytes()
    assert code[:5] == b'\x1bLJ\x02\x02'
    resource = struct.pack('<II', len(code), 2) + code
    assert sha(resource) == TESTED_RESOURCE_SHA, 'Runtime differs from the in-game tested v3.12 payload'
    (build / 'mod.lua.main').write_bytes(resource)
    for suffix, data in [('',make_archive({resource_hash(MODULE):resource})),('.stream',b''),('.gpu_resources',b'')]:
        (build / (ARCHIVE + suffix)).write_bytes(data)
    files = {f'data/{ARCHIVE}{s}':f'build/{ARCHIVE}{s}' for s in ('','.stream','.gpu_resources')}
    report = {'name':'Know Your Constellation','slug':'KnowYourConstellation','revision':REVISION,'guid':GUID,
        'description':SUMMARY + ' Client-side only. Requires Bingus Shared Loader v12 or newer. Spawns are not guaranteed.',
        'module':MODULE,'game_exe_sha256':EXE_SHA,'game_dll_sha256':GAME_DLL_SHA,
        'runtime_verified':True,'client_only':True,'network_calls':False,'gameplay_memory_writes':False,
        'requires':[{'name':'Bingus Shared Loader','revision':'loader-v12','api':1}],
        'deployment_files':files,'files':{p:sha((ROOT/p).read_bytes()) for p in files.values()},
        'resource_sha256':TESTED_RESOURCE_SHA,'offline_tests':tests.strip()}
    release = package_release(ROOT,build,report)
    with zipfile.ZipFile(release) as package:
        manifest = json.loads(package.read('manifest.json'))
        assert manifest['Name']=='Know Your Constellation - v3.12' and manifest['Guid']==GUID
        assert manifest['IconPath']==manifest['Options'][0]['Image']=='thumbnail.png'
        archive = package.read('data/'+ARCHIVE)
        entry = struct.unpack_from('<7Q6I',archive,104)
        assert struct.unpack_from('<III',archive)==(0xF0000011,1,1)
        assert entry[0]==resource_hash(MODULE) and archive[entry[2]:entry[2]+entry[7]]==resource
    report['release_sha256']=sha(release.read_bytes())
    (build/'build-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='ascii')
    (build/'offline-tests.txt').write_text(tests,encoding='ascii')
    print(tests.strip())
    print('PASS: renamed package preserves the in-game tested runtime exactly')
    print('Built '+str(release))


if __name__ == '__main__':
    main()
