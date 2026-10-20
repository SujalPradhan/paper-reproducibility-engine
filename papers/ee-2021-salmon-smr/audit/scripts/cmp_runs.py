import json, sys
def load(p):
    d = json.load(open(p)); d["run"].pop("runtime_s", None)
    for s in d["run"].get("author_scripts", {}).values(): s.pop("time_s", None)
    return d
base = load(sys.argv[1])
for p in sys.argv[2:]:
    d = load(p); print(p, "IDENTICAL" if d == base else "DIFFERENT")
    if d != base:
        for a, b in zip(base["claims"], d["claims"]):
            if a != b: print("  ", a["id"], {k: (a.get(k), b.get(k)) for k in a if a.get(k) != b.get(k)})
        if base["run"] != d["run"]: print("   run block differs:", {k:(base['run'].get(k), d['run'].get(k)) for k in base['run'] if base['run'].get(k)!=d['run'].get(k)})
