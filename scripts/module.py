"""Build the stable runtime wrapper shared by standalone and megapack builds."""
REVISION = 'v3.12'
MODULE = 'mods/cowboybingus/enemy_intelligence'
TESTED_RESOURCE_SHA = '8B0929FB67A59AD5D950D231D059650894DE0472F053FC1F86DF8DFD0F01A60E'


def wrapper(root, game_sha, exe_sha):
    result = ''
    for variable, filename in [('create_api','read_api'), ('resolve','resolve'), ('mission','mission'),
                               ('catalogue','catalogue'), ('model','model'), ('panel','panel'), ('install','install'),
                               ('heavy','heavy'), ('heavy_data','heavy_data'), ('presentation','presentation')]:
        source = (root / 'src' / (filename + '.lua')).read_text(encoding='ascii')
        for forbidden in ('WriteProcessMemory', 'VirtualProtect', 'VirtualAlloc', 'CreateRemoteThread',
                          'Network.', 'RPC.', "ffi.cast('void (*"):
            assert forbidden not in source, 'Unexpected side effect API: ' + forbidden
        result += 'local ' + variable + ' = (function()\n' + source + '\nend)()\n'
    result += "install(create_api,mission,resolve,catalogue,model,panel,{revision='" + REVISION
    result += "',game_sha256='" + game_sha + "',exe_sha256='" + exe_sha + "'},heavy,heavy_data,presentation)\n"
    return result
