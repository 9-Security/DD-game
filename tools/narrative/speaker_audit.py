import json, re, glob, os
ROOT = "/home/user/dd-game"
NAMES = ["艾洛恩", "芙蕾雅", "里克特", "茵芮", "黎安娜", "國王", "瑟維恩"]
novel_text = {}
for f in glob.glob(f"{ROOT}/design/narrative/novel/chapter0*.md") + glob.glob(f"{ROOT}/design/narrative/novel/chapter07_*.md"):
    novel_text[os.path.basename(f)] = open(f, encoding="utf-8").read()
allnovel = "\n".join(novel_text.values())
def norm(t):
    return re.sub(r"[「」『』，。！？、：；…—\s\*「」]", "", t)
allnorm = norm(allnovel)
# explicit tag: a speaker name next to a speech verb in the same or adjacent line
verbs = "說問答喊道低聲輕聲開口笑想回應".replace("", "")
tag_re = re.compile("(" + "|".join(NAMES) + ")(?:[^\n「」]{0,6}?)(說|問|答|喊|道|低聲|輕聲|開口|回答|回應|答道|說道|問道)")
results = []
for path in sorted(glob.glob(f"{ROOT}/assets/data/dialogue/*.json")):
    d = json.load(open(path, encoding="utf-8"))
    fname = os.path.basename(path)
    for scene in d["scenes"]:
        for line in scene["lines"]:
            spk = line["speaker"]
            if spk == "旁白":
                continue
            text = line["text"]
            n = norm(text)
            found = n[:14] and n[:14] in allnorm
            # look for an explicit tag with the same speaker near the quoted text
            tagged = False
            if found:
                for name, fn in [(None, None)]:
                    pass
                for m in re.finditer(re.escape(text[:10]), allnovel):
                    window = allnovel[max(0, m.start() - 80): m.end() + 80]
                    if spk in window and tag_re.search(window):
                        tagged = True
                        break
            status = "tagged" if tagged else ("quoted-untagged" if found else "not-in-novel")
            results.append((fname, scene["id"], spk, text[:40], status))
from collections import Counter
print(Counter(r[4] for r in results))
print()
for r in results:
    if r[4] != "tagged":
        print(r[4][:6], r[0][:14], r[1][-22:], r[2], "|", r[3])
