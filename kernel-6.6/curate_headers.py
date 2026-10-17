import os, shutil
home = os.path.expanduser("~")
B = f"{home}/aospa/bionic/libc/kernel/uapi"
OLD = f"{home}/work/sky-kernel-prebuilt/kernel-headers"
NEW = f"{home}/work/k66/sky-kernel-6.6/kernel-headers"
OUT = NEW + ".curated"

def files(root):
    out = set()
    for r, _, fs in os.walk(root):
        for f in fs:
            out.add(os.path.relpath(os.path.join(r, f), root))
    return out

def in_bionic(rel):
    if rel.startswith("asm/"):
        return True
    return os.path.exists(os.path.join(B, rel))

old, new = files(OLD), files(NEW)
keep_new = {f for f in new if (f in old) or (not in_bionic(f) and not f.startswith(("asm-generic/", "asm/")))}
keep_old = {f for f in old if f not in new}
shutil.rmtree(OUT, ignore_errors=True)
for f in sorted(keep_new):
    d = os.path.join(OUT, f); os.makedirs(os.path.dirname(d), exist_ok=True); shutil.copy2(os.path.join(NEW, f), d)
for f in sorted(keep_old):
    d = os.path.join(OUT, f); os.makedirs(os.path.dirname(d), exist_ok=True); shutil.copy2(os.path.join(OLD, f), d)
print("6.6 files kept:", len(keep_new), "| 5.10-only kept:", len(keep_old), "| dropped:", len(new) - len(keep_new))
print("5.10-only:", " ".join(sorted(keep_old)))
print("top dirs:", sorted({f.split('/')[0] for f in keep_new | keep_old}))
