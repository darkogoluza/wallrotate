"""Tests for wallrotate's daily-pick and time-of-day logic. Not installed.

Run:  python3 tests/test_wallrotate.py      (or: pytest tests/)
"""
import importlib.machinery, importlib.util, os

_path = os.path.join(os.path.dirname(__file__), "..", "wallrotate")
_loader = importlib.machinery.SourceFileLoader("wallrotate", _path)  # script has no .py extension
wr = importlib.util.module_from_spec(importlib.util.spec_from_loader("wallrotate", _loader))
_loader.exec_module(wr)


def at(entry, hhmm):
    return wr.choice_for_time(entry, wr.minutes(hhmm))


def test_group_variant_by_time():
    tahoe = {"name": "T", "variants": [{"from": "20:30", "file": "night"}, {"from": "05:30", "file": "dawn"},
                                       {"from": "08:00", "file": "day"}, {"from": "18:00", "file": "dusk"}]}
    assert at(tahoe, "03:00")["file"] == "night"  # before the first variant: last night's
    assert at(tahoe, "05:30")["file"] == "dawn"
    assert at(tahoe, "12:00")["file"] == "day"
    assert at(tahoe, "19:00")["file"] == "dusk"
    assert at(tahoe, "23:59")["file"] == "night"
    assert at({"file": "solo"}, "00:00")["file"] == "solo"


def test_settings_override():
    g = {"transition": "wipe", "natural_blend": False,
         "variants": [{"from": "06:00", "file": "a"}, {"from": "18:00", "file": "b", "transition": "grow"}]}
    assert at(g, "07:00")["transition"] == "wipe"  # entry setting
    assert at(g, "19:00")["transition"] == "grow"  # variant overrides it
    s = wr.settings({"transition": "fade", "transition_fps": 60, "wallpapers": []}, at(g, "19:00"))
    assert s == {"transition": "grow", "transition_fps": 60, "natural_blend": False}


def test_day_changes_and_rounds():
    entries = [{"file": "a"}, {"file": "b"}]
    e, st = wr.pick_entry(entries, {"date": "2026-01-01", "key": "a", "shown": ["a"]}, "2026-01-02")
    assert e["file"] == "b" and st == {"date": "2026-01-02", "key": "b", "shown": ["a", "b"]}
    assert wr.pick_entry(entries, st, "2026-01-02")[1] == st  # stable within the day
    e, st2 = wr.pick_entry(entries, st, "2026-01-05")  # 3 days off = one change; round done -> new round
    assert e["file"] == "a" and st2["shown"] == ["a"]  # a new round never repeats yesterday's
    assert wr.pick_entry([{"file": "only"}], {"key": "only"}, "2026-01-03")[0]["file"] == "only"


def test_equal_turns():
    many = [{"file": str(i)} for i in range(10)]
    st, counts = {}, {}
    for day in range(50):  # 5 full rounds
        e, st = wr.pick_entry(many, st, f"d{day}")
        counts[e["file"]] = counts.get(e["file"], 0) + 1
    assert set(counts.values()) == {5}, counts


def test_config_edits_and_old_state():
    e, st = wr.pick_entry([{"file": "x"}, {"file": "new"}], {"key": "x", "shown": ["x", "gone"]}, "d1")
    assert e["file"] == "new" and st["shown"] == ["x", "new"]  # removed forgotten, new joins
    entries = [{"file": "a"}, {"file": "b"}]
    assert wr.pick_entry(entries, {"date": "d1", "key": "a"}, "d1")[1]["shown"] == ["a"]  # pre-shuffle state
    assert wr.pick_entry(entries, {"date": "d0", "key": "a"}, "d1")[1]["shown"][-1] in ("a", "b")


def test_fade_video_last_frame():
    assert wr.last_frame_t(1, 60) == round(59 / 60, 6)  # blend must be 100% on the last frame
    assert wr.last_frame_t(2, 30) == round(59 / 30, 6)


if __name__ == "__main__":
    tests = [f for n, f in sorted(globals().items()) if n.startswith("test_")]
    for t in tests:
        t()
    print(f"{len(tests)} tests passed")
