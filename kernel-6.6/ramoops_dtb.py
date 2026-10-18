import os, struct, subprocess, sys, tempfile

src, dst = sys.argv[1], sys.argv[2]
data = open(src, 'rb').read()
blobs, off = [], 0
while off < len(data):
    magic, size = struct.unpack_from('>II', data, off)
    if magic != 0xd00dfeed:
        sys.exit(f'bad magic at {off:#x}')
    blobs.append(data[off:off + size])
    off += size
print(f'{len(blobs)} dtbs in {src}')

out = b''
with tempfile.TemporaryDirectory() as t:
    for i, b in enumerate(blobs):
        p = os.path.join(t, f'{i}.dtb')
        open(p, 'wb').write(b)
        nodes = subprocess.run(['fdtget', '-l', p, '/soc'], capture_output=True, text=True).stdout.split()
        path = None
        for cand in ['/qcom_ramoops', '/soc/qcom_ramoops']:
            r = subprocess.run(['fdtget', '-t', 'x', p, cand, 'pmsg-size'], capture_output=True, text=True)
            if r.returncode == 0:
                path = cand
                break
        if not path:
            dts = subprocess.run(['dtc', '-I', 'dtb', '-O', 'dts', p], capture_output=True, text=True).stdout
            sys.exit(f'dtb {i}: qcom_ramoops node not found')
        region = subprocess.run(['fdtget', '-t', 'x', p, '/reserved-memory/ramoops_region', 'size'], capture_output=True, text=True).stdout.split()
        before = subprocess.run(['fdtget', '-t', 'x', p, path, 'pmsg-size'], capture_output=True, text=True).stdout.strip()
        subprocess.run(['fdtput', '-t', 'x', p, path, 'console-size', '100000'], check=True)
        subprocess.run(['fdtput', '-t', 'x', p, path, 'pmsg-size', '100000'], check=True)
        after = [subprocess.run(['fdtget', '-t', 'x', p, path, k], capture_output=True, text=True).stdout.strip() for k in ('console-size', 'pmsg-size')]
        print(f'dtb {i}: {path} region={region} pmsg {before} -> console={after[0]} pmsg={after[1]}')
        out += open(p, 'rb').read()
open(dst, 'wb').write(out)
