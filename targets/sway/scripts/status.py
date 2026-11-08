#!/usr/bin/env python3
"""LCARS-style status blocks for swaybar, using the i3bar JSON protocol.

Standard library only, so the bar works without i3status or waybar.

Mouse actions:
  COMMS    left: nmtui         right: toggle IP and traffic rates
  SHIELDS  left: toggle the NetworkManager WireGuard connection
  BT       left: toggle power  right: Bluetooth settings
  CPU/MEM  left: open or close htop sorted by that resource
  DISK     left: disk usage analyzer
  MIC      left: toggle mute
  VOL      left: toggle mute   right: sound settings   scroll: change
  LUM      scroll: change
  - / +    left: step the value between them, on either side of VOL and LUM
  power    left: cycle power profile   right: power settings
  clock    left: open or close the calendar
"""
import html
import json
import os
import shutil
import subprocess
import sys
import threading
import time

ORANGE, PEACH, LAVENDER, VIOLET = "#FF9900", "#FFCC99", "#CC99CC", "#9977AA"
BLUE, RED, BLACK = "#9999FF", "#CC4444", "#000000"

INTERVAL = 2
SLOW_INTERVAL = 10  # seconds; for state that needs slower external commands
POWER = "/sys/class/power_supply"
NET = "/sys/class/net"
BACKLIGHT = "/sys/class/backlight"
THERMAL = "/sys/class/thermal"
SCRIPTS = os.path.dirname(os.path.abspath(__file__))
PROFILES = ["power-saver", "balanced", "performance"]
PROFILE_LABELS = {"power-saver": " SAVER", "performance": " PERF"}

LEFT, RIGHT, SCROLL_UP, SCROLL_DOWN = 1, 3, 4, 5

# Monochrome icons, drawn in the block's black text colour. U+FE0E in icon()
# stops Pango from switching emoji-presentation characters to Noto Color Emoji.
ICON_FONT = "Symbola"
ICONS = {
    "comms": "\U0001F4F6",  # antenna bars
    "vpn": "\U0001F6E1",  # shield
    "bt": "\u16D2",  # runic berkanan, the Bluetooth logo's B
    "cpu": "\u2699",  # gear
    "mem": "\u25A4",  # lined square
    "disk": "\U0001F4BE",  # floppy
    "mic": "\U0001F3A4",  # microphone
    "volume": "\U0001F50A",  # speaker
    "lum": "\U0001F506",  # bright button
    "power": "\U0001F50B",  # battery
    "clock": "\U0001F553",  # clock face
}
MUTED_ICON = "\U0001F507"  # crossed-out speaker

redraw = threading.Event()  # draw now rather than at the next interval
poke = threading.Event()  # refresh the slow state now
slow = {"links": {}, "wireguard": None, "wireguard_up": False, "bt": None, "profile": ""}
show_net_detail = False


def read(path, default=""):
    try:
        with open(path) as f:
            return f.read().strip()
    except OSError:
        return default


def run(*cmd, timeout=2):
    try:
        return subprocess.run(
            cmd, capture_output=True, text=True, timeout=timeout,
            stdin=subprocess.DEVNULL,
        ).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def spawn(*cmd):
    """Start an app through sway, detached from the bar. Arguments can't contain spaces."""
    run("swaymsg", "exec", "--", *cmd)


def terminal(*cmd, cols=100, lines=30, app_id="lcars-float"):
    """Run a command in a floating foot; sway floats app_ids containing lcars-float."""
    spawn("foot", "--app-id", app_id, "--window-size-chars", f"{cols}x{lines}", *cmd)


def toggle_terminal(name, *cmd, **size):
    """Close this block's popup if it's open, otherwise open it."""
    app_id = f"lcars-float-{name}"
    closed = subprocess.run(
        ["swaymsg", f'[app_id="^{app_id}$"] kill'],
        capture_output=True, stdin=subprocess.DEVNULL, timeout=2,
    ).returncode == 0  # swaymsg fails when no window matches
    if not closed:
        terminal(*cmd, app_id=app_id, **size)


def settings(panel):
    # gnome-control-center refuses to start outside a GNOME desktop.
    spawn("env", "XDG_CURRENT_DESKTOP=GNOME", "gnome-control-center", panel)


def icon(char):
    return f"<span font_family='{ICON_FONT}' font_weight='normal'>{char}\uFE0E</span> "


def block(name, text, color, glyph=None):
    glyph = glyph or ICONS.get(name)
    return {
        "name": name,
        "full_text": f"  {icon(glyph) if glyph else ''}{html.escape(text)}  ",
        "markup": "pango",
        "color": BLACK,
        "background": color,
        "border": BLACK,
        "separator": False,
        "separator_block_width": 3,
    }


def stepper(name, middle):
    """A value block between buttons that lower and raise it."""
    return [
        block(f"{name}-down", "\u2212", LAVENDER),
        middle,
        block(f"{name}-up", "+", LAVENDER),
    ]


def human(num):
    """Format a byte count compactly: 950, 30K, 1.2M, 45G."""
    for unit in ("", "K", "M", "G"):
        if num < 1024 or unit == "G":
            return f"{num:.1f}{unit}" if unit and num < 10 else f"{num:.0f}{unit}"
        num /= 1024
    return ""


# Slow state, refreshed on its own thread so it can never stall the bar.


def update_links():
    links = {}
    for dev in os.listdir(NET):
        if read(f"{NET}/{dev}/operstate") == "up":
            out = run("nmcli", "-g", "GENERAL.CONNECTION,IP4.ADDRESS", "device", "show", dev)
            lines = out.splitlines() + ["", ""]
            links[dev] = (lines[0], lines[1].split(" | ")[0].split("/")[0])
    slow["links"] = links


def update_wireguard():
    name, up = None, False
    out = run("nmcli", "-t", "-f", "NAME,TYPE,ACTIVE", "connection", "show")
    for line in out.splitlines():
        fields = line.rsplit(":", 2)
        if len(fields) == 3 and fields[1] == "wireguard":
            # Prefer reporting the active connection if several are defined.
            if name is None or fields[2] == "yes":
                name, up = fields[0], fields[2] == "yes"
    slow["wireguard"], slow["wireguard_up"] = name, up


def update_bluetooth():
    shown = run("bluetoothctl", "show")
    if not shown:
        slow["bt"] = None  # no controller or no bluetoothd
    elif "Powered: yes" not in shown:
        slow["bt"] = ""
    else:
        # Lines look like "Device AA:BB:CC:DD:EE:FF Some Name".
        devices = run("bluetoothctl", "devices", "Connected").splitlines()
        names = [d.split(" ", 2)[2] for d in devices if d.count(" ") >= 2]
        slow["bt"] = names[0] if names else "ON"


def slow_loop():
    updates = [
        update_links,
        update_wireguard,
        update_bluetooth,
        lambda: slow.update(profile=run("powerprofilesctl", "get")),
    ]
    while True:
        for update in updates:
            try:
                update()
            except Exception as e:
                print(f"status.py: {e!r}", file=sys.stderr, flush=True)
        redraw.set()
        poke.wait(SLOW_INTERVAL)
        poke.clear()


# Blocks


class Comms:
    """Connected wifi network or ethernet, with signal and optional detail."""

    def __init__(self):
        self.dev = None
        self.last = (0.0, 0, 0)
        self.rates = (0.0, 0.0)

    @staticmethod
    def _signal(dev):
        # Link quality in /proc/net/wireless runs from 0 to 70.
        for line in read("/proc/net/wireless").splitlines():
            if line.strip().startswith(f"{dev}:"):
                return min(100, round(float(line.split()[2].rstrip(".")) * 100 / 70))
        return None

    def _sample_rates(self, dev):
        now = time.monotonic()
        rx = int(read(f"{NET}/{dev}/statistics/rx_bytes", "0"))
        tx = int(read(f"{NET}/{dev}/statistics/tx_bytes", "0"))
        elapsed = now - self.last[0]
        if dev != self.dev:
            self.dev, self.rates = dev, (0.0, 0.0)
        elif elapsed < 1:  # an early redraw from a click
            return
        else:
            self.rates = ((rx - self.last[1]) / elapsed, (tx - self.last[2]) / elapsed)
        self.last = (now, rx, tx)

    def block(self):
        devs = sorted(os.listdir(NET))
        up = [d for d in devs if read(f"{NET}/{d}/operstate") == "up"]
        wifi = [d for d in up if os.path.isdir(f"{NET}/{d}/wireless")]
        wired = [d for d in up if d.startswith(("en", "eth"))]
        if wifi:
            dev = wifi[0]
            name = slow["links"].get(dev, ("", ""))[0] or dev
            signal = self._signal(dev)
            label = f"COMMS {name}" + (f" {signal}%" if signal is not None else "")
        elif wired:
            dev = wired[0]
            label = "COMMS WIRED"
        else:
            return block("comms", "COMMS OFFLINE", RED)
        self._sample_rates(dev)
        if show_net_detail:
            ip = slow["links"].get(dev, ("", ""))[1]
            down, up_rate = self.rates
            label += f" {ip} DN {human(down)} UP {human(up_rate)}"
        return block("comms", label.upper(), BLUE)


def vpn():
    """Any tunnel interface counts as up, even one NetworkManager doesn't manage."""
    tunnels = [d for d in os.listdir(NET) if read(f"{NET}/{d}/type") == "65534"]
    if tunnels or slow["wireguard_up"]:
        return block("vpn", "SHIELDS UP", LAVENDER)
    if slow["wireguard"]:
        return block("vpn", "SHIELDS DOWN", RED)
    return None


def bluetooth():
    state = slow["bt"]
    if state is None:
        return None
    if state == "":
        return block("bt", "BT OFF", VIOLET)
    return block("bt", f"BT {state}".upper(), BLUE)


def find_cpu_temp():
    try:
        zones = os.listdir(THERMAL)
    except OSError:
        return None
    for zone in zones:
        if read(f"{THERMAL}/{zone}/type") == "x86_pkg_temp":
            return f"{THERMAL}/{zone}/temp"
    return None


class Cpu:
    def __init__(self):
        self.last = self._sample()
        self.last_time = time.monotonic()
        self.pct = 0
        self.temp_path = find_cpu_temp()

    @staticmethod
    def _sample():
        fields = [int(x) for x in read("/proc/stat").splitlines()[0].split()[1:]]
        return sum(fields), fields[3] + fields[4]  # total, idle + iowait

    def block(self):
        # An early redraw from a click would measure a uselessly short window.
        if time.monotonic() - self.last_time >= 1:
            now = self._sample()
            total = now[0] - self.last[0]
            idle = now[1] - self.last[1]
            self.last, self.last_time = now, time.monotonic()
            self.pct = round(100 * (total - idle) / total) if total else 0
        text = f"CPU {self.pct:02d}%"
        temp = 0
        if self.temp_path:
            temp = round(int(read(self.temp_path, "0")) / 1000)
            text += f" {temp}°"
        return block("cpu", text, RED if self.pct >= 85 or temp >= 90 else ORANGE)


def memory():
    info = {}
    for line in read("/proc/meminfo").splitlines():
        key, _, rest = line.partition(":")
        info[key] = int(rest.split()[0])
    pct = round(100 * (1 - info["MemAvailable"] / info["MemTotal"]))
    return block("mem", f"MEM {pct:02d}%", RED if pct >= 90 else PEACH)


def disk():
    use = shutil.disk_usage(os.path.expanduser("~"))
    pct = round(100 * use.used / use.total)
    return block("disk", f"DISK {human(use.free)} FREE", RED if pct >= 90 else LAVENDER)


def backlight_pct():
    """Display brightness as a percentage, or None without a usable backlight."""
    devices = os.listdir(BACKLIGHT) if os.path.isdir(BACKLIGHT) else []
    if not devices:
        return None
    dev = f"{BACKLIGHT}/{sorted(devices)[0]}"
    maximum = int(read(f"{dev}/max_brightness", "0"))
    if not maximum:
        return None
    return round(100 * int(read(f"{dev}/brightness", "0")) / maximum)


def brightness():
    pct = backlight_pct()
    return None if pct is None else stepper("lum", block("lum", f"LUM {pct}%", PEACH))


def power():
    now = full = rate = 0
    on_mains = charging = False
    # Desktops and VMs may have no power supplies at all. Adapter names vary
    # (AC, ADP1, ACAD), and batteries report energy_* or charge_*.
    devices = sorted(os.listdir(POWER)) if os.path.isdir(POWER) else []
    for dev in devices:
        kind = read(f"{POWER}/{dev}/type")
        if kind == "Mains" and read(f"{POWER}/{dev}/online") == "1":
            on_mains = True
        elif kind == "Battery" and read(f"{POWER}/{dev}/scope") != "Device":
            charging = charging or read(f"{POWER}/{dev}/status") == "Charging"
            for unit, rate_file in (("energy", "power_now"), ("charge", "current_now")):
                if os.path.exists(f"{POWER}/{dev}/{unit}_now"):
                    now += int(read(f"{POWER}/{dev}/{unit}_now", "0"))
                    full += int(read(f"{POWER}/{dev}/{unit}_full", "0"))
                    rate += int(read(f"{POWER}/{dev}/{rate_file}", "0"))
                    break
    if not full:
        return None
    pct = round(100 * now / full)
    label = "CHG" if charging else "AC" if on_mains else "BAT"
    text = f"{label} {pct}%"
    # Time to full while charging, time to empty on battery.
    remaining = (full - now if charging else now if not on_mains else 0) / rate if rate else 0
    if 0 < remaining < 24:
        text += f" {int(remaining)}:{int(remaining * 60) % 60:02d}"
    text += PROFILE_LABELS.get(slow["profile"], "")
    return block("power", text, RED if pct <= 15 and not on_mains else VIOLET)


def microphone():
    out = run("wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@")
    if not out:
        return None
    if "[MUTED]" in out:
        return block("mic", "MIC OFF", VIOLET)
    if run("pactl", "list", "short", "source-outputs"):
        return block("mic", "MIC LIVE", RED)
    return block("mic", "MIC ON", LAVENDER)


def volume():
    out = run("wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@")  # "Volume: 0.74 [MUTED]"
    parts = out.split()
    if len(parts) < 2:
        return None
    if "[MUTED]" in out:
        return stepper("volume", block("volume", "VOL MUTED", RED, MUTED_ICON))
    return stepper("volume", block("volume", f"VOL {round(float(parts[1]) * 100)}%", BLUE))


def clock():
    return block("clock", time.strftime("%a %d %b W%V %H:%M").upper(), ORANGE)


# Click handling


def toggle_net_detail():
    global show_net_detail
    show_net_detail = not show_net_detail


def toggle_wireguard():
    if slow["wireguard"]:
        verb = "down" if slow["wireguard_up"] else "up"
        run("nmcli", "connection", verb, slow["wireguard"], timeout=20)


def toggle_bluetooth():
    state = "on" if slow["bt"] == "" else "off"
    run("bluetoothctl", "power", state, timeout=5)


def cycle_profile():
    current = slow["profile"]
    index = PROFILES.index(current) if current in PROFILES else 0
    run("powerprofilesctl", "set", PROFILES[(index + 1) % len(PROFILES)])


def volume_up():
    run(f"{SCRIPTS}/volume.sh", "up")


def volume_down():
    run(f"{SCRIPTS}/volume.sh", "down")


ACTIONS = {
    ("comms", LEFT): lambda: terminal("nmtui"),
    ("comms", RIGHT): toggle_net_detail,
    ("vpn", LEFT): toggle_wireguard,
    ("bt", LEFT): toggle_bluetooth,
    ("bt", RIGHT): lambda: settings("bluetooth"),
    ("cpu", LEFT): lambda: toggle_terminal("cpu", "htop", "-s", "PERCENT_CPU"),
    ("mem", LEFT): lambda: toggle_terminal("mem", "htop", "-s", "PERCENT_MEM"),
    ("disk", LEFT): lambda: spawn("baobab", os.path.expanduser("~")),
    ("mic", LEFT): lambda: run("wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"),
    ("volume", LEFT): lambda: run(f"{SCRIPTS}/volume.sh", "mute"),
    ("volume", RIGHT): lambda: settings("sound"),
    ("volume", SCROLL_UP): volume_up,
    ("volume", SCROLL_DOWN): volume_down,
    ("volume-down", LEFT): volume_down,
    ("volume-up", LEFT): volume_up,
    ("lum", SCROLL_UP): lambda: run(f"{SCRIPTS}/brightness.sh", "+5"),
    ("lum", SCROLL_DOWN): lambda: run(f"{SCRIPTS}/brightness.sh", "-5"),
    ("lum-down", LEFT): lambda: run(f"{SCRIPTS}/brightness.sh", "-5"),
    ("lum-up", LEFT): lambda: run(f"{SCRIPTS}/brightness.sh", "+5"),
    ("power", LEFT): cycle_profile,
    ("power", RIGHT): lambda: settings("power"),
    ("clock", LEFT): lambda: toggle_terminal("clock", "--hold", "python3", "-m", "calendar", cols=72, lines=38),
}


def act(action):
    try:
        action()
    finally:
        poke.set()
        redraw.set()


def handle_click(line):
    """swaybar sends an endless JSON array: '[', then one object per line, comma-led."""
    line = line.strip().lstrip("[,").strip()
    if not line:
        return
    try:
        event = json.loads(line)
    except ValueError:
        return
    action = ACTIONS.get((event.get("name"), event.get("button")))
    if action:
        # On its own thread, because some actions (like VPN changes) take seconds.
        threading.Thread(target=act, args=(action,), daemon=True).start()


def read_clicks():
    for line in sys.stdin:
        handle_click(line)


def safe(fn):
    """A failing block just disappears, rather than killing the whole bar."""
    try:
        return fn()
    except Exception as e:
        print(f"status.py: {fn}: {e!r}", file=sys.stderr, flush=True)
        return None


def main():
    print(json.dumps({"version": 1, "click_events": True}), flush=True)
    print("[", flush=True)
    comms, cpu = Comms(), Cpu()
    threading.Thread(target=read_clicks, daemon=True).start()
    threading.Thread(target=slow_loop, daemon=True).start()
    sources = [
        comms.block, vpn, bluetooth, cpu.block, memory, disk,
        microphone, volume, brightness, power, clock,
    ]
    while True:
        blocks = []
        for source in sources:
            result = safe(source)  # a block, a list of blocks, or None
            if isinstance(result, list):
                blocks.extend(result)
            elif result:
                blocks.append(result)
        print(json.dumps(blocks) + ",", flush=True)
        redraw.wait(INTERVAL)
        redraw.clear()


if __name__ == "__main__":
    main()
