#!/usr/bin/env python3
import hashlib
import os
import re
import struct
import sys
from collections import defaultdict

ROOT = sys.argv[1]
SHT_SYMTAB = 2


class Ko:
    def __init__(self, path):
        self.path = path
        self.file = os.path.basename(path)
        data = open(path, 'rb').read()
        self.sha = hashlib.sha1(data).hexdigest()
        shoff, = struct.unpack_from('<Q', data, 0x28)
        shentsize, shnum, shstrndx = struct.unpack_from('<HHH', data, 0x3A)
        secs = []
        for i in range(shnum):
            secs.append(struct.unpack_from('<IIQQQQIIQQ', data, shoff + i * shentsize))
        shstr = secs[shstrndx]
        def secname(s):
            off = shstr[4] + s[0]
            return data[off:data.index(b'\0', off)].decode()
        names = [secname(s) for s in secs]
        self.sections = names

        self.modinfo = defaultdict(list)
        if '.modinfo' in names:
            s = secs[names.index('.modinfo')]
            for kv in data[s[4]:s[4] + s[5]].split(b'\0'):
                if b'=' in kv:
                    k, v = kv.decode(errors='replace').split('=', 1)
                    self.modinfo[k].append(v)
        self.name = self.modinfo.get('name', [self.file[:-3]])[0].replace('-', '_')
        self.vermagic = self.modinfo.get('vermagic', [''])[0]
        deps = self.modinfo.get('depends', [''])[0]
        self.depends = [d.replace('-', '_') for d in deps.split(',') if d]

        self.versions = {}
        if '__versions' in names:
            s = secs[names.index('__versions')]
            blob = data[s[4]:s[4] + s[5]]
            for off in range(0, len(blob), 64):
                crc, = struct.unpack_from('<Q', blob, off)
                n = blob[off + 8:off + 64]
                self.versions[n[:n.index(b'\0')].decode()] = crc & 0xffffffff

        self.undef, self.weak_undef, self.exports, self.crcs = set(), set(), set(), {}
        for s in secs:
            if s[1] != SHT_SYMTAB:
                continue
            strtab = secs[s[6]]
            for off in range(s[4], s[4] + s[5], 24):
                st_name, st_info, st_other, st_shndx, st_value, st_size = struct.unpack_from('<IBBHQQ', data, off)
                if not st_name:
                    continue
                o = strtab[4] + st_name
                n = data[o:data.index(b'\0', o)].decode()
                bind = st_info >> 4
                if st_shndx == 0:
                    if bind == 2:
                        self.weak_undef.add(n)
                    elif bind == 1:
                        self.undef.add(n)
                elif n.startswith('__ksymtab_'):
                    self.exports.add(n[len('__ksymtab_'):])
                elif n.startswith('__crc_') and st_shndx < len(secs):
                    cs = secs[st_shndx]
                    self.crcs[n[len('__crc_'):]] = struct.unpack_from('<I', data, cs[4] + st_value)[0]
        self.signed = data.endswith(b'~Module signature appended~\n')


def read_list(p):
    if not os.path.exists(p):
        return []
    return [l.strip() for l in open(p) if l.strip() and not l.startswith('#')]


def read_blocklist(p):
    out = set()
    for l in read_list(p):
        parts = l.split()
        if len(parts) == 2 and parts[0] == 'blocklist':
            out.add(parts[1].replace('-', '_').removesuffix('.ko'))
    return out


sets = {}
SYSDIR = 'system_dlkm' if os.path.isdir(os.path.join(ROOT, 'system_dlkm')) else 'gki_dlkm'
for d in ('vendor_ramdisk', 'vendor_dlkm', SYSDIR):
    sets[d] = {f: Ko(os.path.join(ROOT, d, f)) for f in sorted(os.listdir(os.path.join(ROOT, d))) if f.endswith('.ko')}

vmlinux_crc = {}
symvers_crc = {}
for l in open(os.path.join(ROOT, 'Module.symvers')):
    p = l.rstrip('\n').split('\t')
    if len(p) < 3:
        continue
    crc, sym, mod = int(p[0], 16), p[1], p[2]
    symvers_crc[sym] = crc
    if mod == 'vmlinux':
        vmlinux_crc[sym] = crc

image = open(os.path.join(ROOT, 'Image'), 'rb').read()
m = re.search(rb'Linux version (\S+)', image)
release = m.group(1).decode()

problems = defaultdict(list)

print(f'Kernel release: {release}')
print(f'vmlinux exports: {len(vmlinux_crc)}')
for d, mods in sets.items():
    print(f'{d}: {len(mods)} modules')

vermagics = defaultdict(list)
for d, mods in sets.items():
    for f, k in mods.items():
        vermagics[k.vermagic].append(f'{d}/{f}')
print('\n== vermagic')
for v, fs in vermagics.items():
    ok = v.split(' ')[0] == release
    print(f'  {"OK " if ok else "BAD"} {len(fs):4d} x "{v}"')
    if not ok:
        problems['vermagic'] += fs[:20]

print('\n== duplicate file names across dirs')
by_file = defaultdict(dict)
for d, mods in sets.items():
    for f, k in mods.items():
        by_file[f][d] = k.sha
dups = {f: v for f, v in by_file.items() if len(v) > 1}
diff = {f: v for f, v in dups.items() if len(set(v.values())) > 1}
print(f'  {len(dups)} names in more than one dir, {len(diff)} differ in content')
for f, v in sorted(diff.items())[:30]:
    print(f'    DIFFERS {f}: {", ".join(v)}')
    problems['dup-differs'].append(f)


def simulate(stage, load_files, pool, preloaded, blocklist):
    print(f'\n== {stage}: {len(load_files)} in load list')
    by_name = {}
    for f, k in pool.items():
        by_name.setdefault(k.name, k)
    loaded = {}
    missing_files = [f for f in load_files if f not in pool]
    for f in missing_files:
        print(f'  MISSING FILE {f}')
        problems[stage].append(f'missing file {f}')
    for f in load_files:
        if f in pool:
            loaded[pool[f].name] = pool[f]

    blocked = [f for f in load_files if f in pool and pool[f].name in blocklist]
    for f in blocked:
        print(f'  BLOCKLISTED but in load list: {f}')

    pulled = {}
    queue = list(loaded.values())
    while queue:
        k = queue.pop()
        for dep in k.depends:
            if dep in loaded or dep in pulled or dep in preloaded:
                continue
            if dep in by_name:
                pulled[dep] = by_name[dep]
                queue.append(by_name[dep])
    for n, k in sorted(pulled.items()):
        print(f'  pulled in as dependency (not in load list): {k.file}')

    active = dict(preloaded)
    active.update(loaded)
    active.update(pulled)

    exporters = {}
    for n, k in active.items():
        for s in k.exports:
            exporters.setdefault(s, k)

    bad = 0
    for n, k in sorted({**loaded, **pulled}.items()):
        issues = []
        for dep in k.depends:
            if dep not in active:
                where = [d for d, mods in sets.items() if any(x.name == dep for x in mods.values())]
                issues.append(f'depends on {dep} which is not available here (found in: {", ".join(where) or "nowhere"})')
            elif dep in blocklist:
                issues.append(f'depends on blocklisted {dep}')
        unresolved = sorted(s for s in k.undef if s not in vmlinux_crc and s not in exporters)
        if unresolved:
            issues.append(f'{len(unresolved)} unresolved symbols: {" ".join(unresolved[:8])}{" ..." if len(unresolved) > 8 else ""}')
        crc_bad = []
        for s, crc in k.versions.items():
            if s == 'module_layout':
                continue
            if s in vmlinux_crc:
                want = vmlinux_crc[s]
            elif s in exporters and s in exporters[s].crcs:
                want = exporters[s].crcs[s]
            elif s in symvers_crc:
                want = symvers_crc[s]
            else:
                continue
            if want != crc:
                crc_bad.append(s)
        if crc_bad:
            issues.append(f'{len(crc_bad)} CRC mismatches: {" ".join(sorted(crc_bad)[:8])}')
        if issues:
            bad += 1
            print(f'  FAIL {k.file}')
            for i in issues:
                print(f'       {i}')
            problems[stage].append(k.file)
    print(f'  -> {len(loaded) + len(pulled) - bad} OK, {bad} FAIL')
    return active


vr = sets['vendor_ramdisk']
vd = sets['vendor_dlkm']
gk = sets[SYSDIR]
if SYSDIR == 'system_dlkm':
    ramdisk_pool = dict(vr)
else:
    ramdisk_pool = {}
    for f in read_list(os.path.join(ROOT, 'vendor_ramdisk/modules.load')):
        if f in vr:
            ramdisk_pool[f] = vr[f]
    for f in read_list(os.path.join(ROOT, 'vendor_dlkm/modules.load')):
        if f in vd:
            ramdisk_pool.setdefault(f, vd[f])

bl = read_blocklist(os.path.join(ROOT, 'vendor_dlkm/modules.blocklist'))
sbl = read_blocklist(os.path.join(ROOT, 'vendor_dlkm/system_dlkm.modules.blocklist'))
print(f'\nvendor blocklist: {len(bl)}, system_dlkm blocklist: {len(sbl)} ({", ".join(sorted(sbl))})')

first = simulate('FIRST STAGE (vendor_boot ramdisk)',
                 read_list(os.path.join(ROOT, 'vendor_ramdisk/modules.load')), ramdisk_pool, {}, bl)

rec_files = read_list(os.path.join(ROOT, 'vendor_ramdisk/modules.load.recovery'))
simulate('RECOVERY (vendor_boot ramdisk, recovery load list)', rec_files, ramdisk_pool, {}, bl)
not_shipped = [f for f in rec_files if f not in ramdisk_pool]
if not_shipped:
    print(f'  NOTE: {len(not_shipped)} recovery modules are only in vendor_ramdisk/ but not packed into the ramdisk: {" ".join(not_shipped[:20])}')

second_pool = dict(gk)
second_pool.update(vd)
second_load = read_list(os.path.join(ROOT, SYSDIR, 'modules.load')) + read_list(os.path.join(ROOT, 'vendor_dlkm/modules.load'))
second = simulate('SECOND STAGE (system_dlkm + vendor_dlkm)', second_load, second_pool, first, bl | sbl)
ondemand = [f for f in vd if f not in second_load]
simulate('ON-DEMAND vendor_dlkm modules (not in any load list)', ondemand, second_pool, second, set())

print('\n== module signatures')
for d, mods in sets.items():
    signed = sum(1 for k in mods.values() if k.signed)
    print(f'  {d}: {signed}/{len(mods)} signed')

print('\n== summary')
if not any(problems.values()):
    print('  no problems found')
for k, v in problems.items():
    print(f'  {k}: {len(v)}')
