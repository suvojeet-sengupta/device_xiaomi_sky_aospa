import os, subprocess, shutil, glob
home = os.path.expanduser("~")
P = f"{home}/work/k66/sky-kernel-6.6"
rel = open(f"{home}/work/k66/out/include/config/kernel.release").read().strip()
ALL = {}
for f in glob.glob(f"{home}/work/k66/modules-install/lib/modules/{rel}/**/*.ko", recursive=True):
    ALL.setdefault(os.path.basename(f).replace("-", "_"), f)
def n(x): return x.replace("-", "_")
_dep = {}
def deps(name):
    if name not in _dep:
        out = subprocess.run(["modinfo", "-F", "depends", ALL[name]], capture_output=True, text=True).stdout.strip()
        _dep[name] = [n(d) + ".ko" for d in out.split(",") if d]
    return _dep[name]
def closure(names):
    seen, order = set(), []
    def visit(m):
        if m in seen: return
        seen.add(m)
        if m not in ALL: raise SystemExit(f"unknown module {m}")
        for d in deps(m): visit(d)
        order.append(m)
    for m in names: visit(n(m))
    return order
def fname(m): return os.path.basename(ALL[m])
def read(p): return [l.strip() for l in open(p) if l.strip() and not l.startswith("#")]
gki = {n(x) for x in read(f"{P}/gki_dlkm/modules.load")}
for d, lists in [("vendor_ramdisk", ["modules.load", "modules.load.recovery"]), ("vendor_dlkm", ["modules.load"])]:
    files = set()
    for lst in lists:
        p = f"{P}/{d}/{lst}"
        old = read(p)
        new = closure(old)
        added = [m for m in new if m not in {n(x) for x in old}]
        open(p, "w").write("\n".join(fname(m) for m in new) + "\n")
        files |= set(new)
        print(f"{d}/{lst}: {len(old)} -> {len(new)} (+{len(added)}; from gki: {len([a for a in added if a in gki])})")
    for f in os.listdir(f"{P}/{d}"):
        if f.endswith(".ko"): os.remove(f"{P}/{d}/{f}")
    for m in files: shutil.copy2(ALL[m], f"{P}/{d}/{fname(m)}")
    print(f"{d}: {len(files)} ko")
