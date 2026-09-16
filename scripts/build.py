"""Build the local-only Know Your Constellation release without deploying it."""
import argparse
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import zipfile

sys.dont_write_bytecode = True
from archive import GAME, LUA, EXE_SHA, GAME_DLL_SHA, ARCHIVE, sha, make_archive, resource_hash
from module import MODULE, REVISION, ROWS_REVISION, TESTED_RESOURCE_SHA, TESTED_ROWS_RESOURCE_SHA, wrapper
from package import package_release

ROOT = Path(__file__).resolve().parents[1]
GUID = '9a9c8423-8f3e-4b7b-9a16-7d0b78ff1a18'
ROWS_GUID = '3b68356c-b11c-431a-aa5a-d7b1ca50b189'
SUMMARY = 'Reveals mission constellations and enemy forecasts on the war table and briefing screen so you can choose your loadout before deployment.'


def run(arguments):
    env = dict(os.environ, LUA_PATH=str(LUA.parent / '?.lua') + ';;')
    process = subprocess.run(list(map(str, arguments)), capture_output=True, text=True, env=env)
    if process.returncode:
        raise RuntimeError(process.stdout + process.stderr)
    return process.stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--rows', action='store_true', help='Build the alternate static rows package')
    args = parser.parse_args()
    build = ROOT / ('build/rows' if args.rows else 'build')
    build.mkdir(parents=True, exist_ok=True)
    for filename, expected in [('bin/helldivers2.exe', EXE_SHA), ('data/game/game.dll', GAME_DLL_SHA)]:
        assert sha((GAME / filename).read_bytes()) == expected, 'Unsupported game build'
    source = build / 'mod.wrapper.lua'
    source.write_text(wrapper(ROOT, GAME_DLL_SHA, EXE_SHA, rows=args.rows), encoding='ascii', newline='\n')
    tests = ''
    suites = ('resolve', 'panel', 'install', 'mission', 'heavy', 'presentation')
    for name in suites + (('rows',) if args.rows else ()):
        tests += run([LUA, ROOT / ('tests/test_' + name + '.lua'), ROOT / 'src'])
    compiled = build / 'mod.ljbc'
    run([LUA, '-bsdW', source, compiled])
    code = compiled.read_bytes()
    assert code[:5] == b'\x1bLJ\x02\x02'
    resource = struct.pack('<II', len(code), 2) + code
    if args.rows:
        assert sha(resource) == TESTED_ROWS_RESOURCE_SHA, 'Rows runtime differs from the in-game verified payload'
        # Prove the shared source still builds the exact tested scrolling runtime.
        baseline_source, baseline_code = build / 'scrolling.wrapper.lua', build / 'scrolling.ljbc'
        baseline_source.write_text(wrapper(ROOT, GAME_DLL_SHA, EXE_SHA), encoding='ascii', newline='\n')
        run([LUA, '-bsdW', baseline_source, baseline_code])
        baseline = baseline_code.read_bytes()
        assert sha(struct.pack('<II', len(baseline), 2) + baseline) == TESTED_RESOURCE_SHA
    else:
        assert sha(resource) == TESTED_RESOURCE_SHA, 'Runtime differs from the in-game tested v3.12 payload'
    revision = ROWS_REVISION if args.rows else REVISION
    tests += run([LUA, ROOT / 'tests/test_package.lua', compiled, revision])
    (build / 'mod.lua.main').write_bytes(resource)
    for suffix, data in [('',make_archive({resource_hash(MODULE):resource})),('.stream',b''),('.gpu_resources',b'')]:
        (build / (ARCHIVE + suffix)).write_bytes(data)
    files = {f'data/{ARCHIVE}{s}':(build / (ARCHIVE+s)).relative_to(ROOT).as_posix()
             for s in ('','.stream','.gpu_resources')}
    name = 'Know Your Constellation Rows' if args.rows else 'Know Your Constellation'
    guid = ROWS_GUID if args.rows else GUID
    summary = SUMMARY + (' Displays the complete forecast in static rows. Enable only one forecast variant.' if args.rows else '')
    report = {'name':name,'slug':name.replace(' ',''),'revision':revision,'guid':guid,
        'description':summary + ' Client-side only. Requires Bingus Shared Loader v12 or newer. Spawns are not guaranteed.',
        'module':MODULE,'game_exe_sha256':EXE_SHA,'game_dll_sha256':GAME_DLL_SHA,
        'runtime_verified':True,'client_only':True,'network_calls':False,'gameplay_memory_writes':False,
        'requires':[{'name':'Bingus Shared Loader','revision':'loader-v12','api':1}],
        'deployment_files':files,'files':{p:sha((ROOT/p).read_bytes()) for p in files.values()},
        'resource_sha256':sha(resource),'offline_tests':tests.strip()}
    if args.rows:
        report.update(version=REVISION.removeprefix('v'), install_instructions='INSTALL-ROWS.txt')
    release = package_release(ROOT,build,report)
    with zipfile.ZipFile(release) as package:
        manifest = json.loads(package.read('manifest.json'))
        assert manifest['Name']==name+' - '+REVISION and manifest['Guid']==guid
        assert manifest['IconPath']==manifest['Options'][0]['Image']=='thumbnail.png'
        archive = package.read('data/'+ARCHIVE)
        entry = struct.unpack_from('<7Q6I',archive,104)
        assert struct.unpack_from('<III',archive)==(0xF0000011,1,1)
        assert entry[0]==resource_hash(MODULE) and archive[entry[2]:entry[2]+entry[7]]==resource
    report['release_sha256']=sha(release.read_bytes())
    (build/'build-report.json').write_text(json.dumps(report,indent=2)+'\n',encoding='ascii')
    (build/'offline-tests.txt').write_text(tests,encoding='ascii')
    print(tests.strip())
    print('PASS: scrolling runtime still matches the in-game tested v3.12 payload')
    if args.rows:
        print('PASS: rows runtime matches the in-game verified payload')
    print('Built '+str(release))


if __name__ == '__main__':
    main()
