import re, pathlib
mods = {
 "module1":("01-intro-to-r.Rmd",["assign-exercise","class-demo","confirm-load","head-exercise","str-exercise","summary-exercise","str-review","dollar-demo","dollar-exercise"]),
 "module2":("02-data-import.Rmd",["account-quiz","section-link-quiz","project-quiz","import-practice","head-lab-data","str-lab-data","summary-lab-data","first-plot"]),
 "module3":("03-refresher.Rmd",[f"q{i}" for i in (7,8)]),
 "module4":("04-wrangle-visualize.Rmd",[f"q{i}" for i in range(1,12)]),
 "module5":("05-groups.Rmd",[f"q{i}" for i in range(1,5)]+[f"mc{i}" for i in range(1,5)]),
 "module6":("06-regression.Rmd",[f"q{i}" for i in range(1,6)]),
 "module7":("07-two-way-anova.Rmd",[f"q{i}" for i in range(1,4)]),
 "module8":("08-ancova.Rmd",[f"q{i}" for i in range(1,5)]),
 "module9":("09-choosing-a-test.Rmd",[f"q{i}" for i in range(1,4)]),
 "module10":("10-joining-data.Rmd",[f"q{i}" for i in range(1,6)]),
}
hdr = re.compile(r"^```\{r\s+([A-Za-z0-9_.-]+)([^}]*)\}")
for mod,(f,expected) in mods.items():
    t = pathlib.Path(f).read_text()
    ex, chk, quest = set(), set(), set()
    for ln in t.split("\n"):
        m = hdr.match(ln)
        if not m: continue
        lab, opts = m.group(1), m.group(2)
        if "exercise=TRUE" in opts.replace(" ",""): ex.add(lab)
        if lab.endswith("-check"): chk.add(lab[:-6])
        if re.search(r"echo\s*=\s*FALSE", opts) and lab.startswith(("mc","quiz")): quest.add(lab)
    gradeable = (ex & chk) | quest
    miss = [e for e in expected if e not in gradeable]
    extra = sorted(gradeable - set(expected))
    has_qsub = "question_submission" in t
    flag = "OK " if not miss and not extra else "!! "
    print(f"{flag}{mod:9s} {f:26s} expect {len(expected):2d} | gradeable {len(gradeable):2d} | qsub_handler={has_qsub}")
    if miss:  print(f"     MISSING from file : {miss}")
    if extra: print(f"     in file, NOT graded: {extra}")
