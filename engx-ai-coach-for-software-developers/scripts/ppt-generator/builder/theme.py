"""
builder/theme.py
────────────────
Defines light and dark colour palettes and named accent colours.
Each theme is a plain dict so callers can do:  T = get_theme("light"); T["BG"]
"""

from pptx.dml.color import RGBColor


def _rgb(hex_str: str) -> RGBColor:
    h = hex_str.lstrip("#")
    return RGBColor(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))


# ── Named accent colours (shared across themes) ──────────────────────────────
ACCENTS = {
    "orange":  _rgb("FA6400"),
    "blue":    _rgb("1565C0"),
    "teal":    _rgb("00838F"),
    "green":   _rgb("2E7D32"),
    "red":     _rgb("C62828"),
    "purple":  _rgb("6A1B9A"),
    "gold":    _rgb("F9A825"),
}

ACCENT_LIGHT = {
    "orange": _rgb("FFF3E0"),
    "blue":   _rgb("E3F0FF"),
    "teal":   _rgb("E0F7F8"),
    "green":  _rgb("E8F5E9"),
    "red":    _rgb("FCECEC"),
    "purple": _rgb("F3E5F5"),
    "gold":   _rgb("FFFDE7"),
}

# ── Light theme ───────────────────────────────────────────────────────────────
LIGHT = {
    "BG":       _rgb("FAFAFD"),
    "WHITE":    _rgb("FFFFFF"),
    "NAVY":     _rgb("0D0D35"),
    "DARK":     _rgb("222244"),
    "GRAY":     _rgb("666688"),
    "LGRAY":    _rgb("BBBBCC"),
    "LINE":     _rgb("DDDDEE"),
    "CARD":     _rgb("F0F2F8"),
    "CODE_BG":  _rgb("1E1E38"),
    "CODE_FG":  _rgb("CCDDEE"),
    "ORANGE":   ACCENTS["orange"],
    "LRED":     _rgb("FCECEC"),
    "LGREEN":   _rgb("E8F5E9"),
    "RED":      ACCENTS["red"],
    "GREEN":    ACCENTS["green"],
    "name":     "light",
}

# ── Dark theme ────────────────────────────────────────────────────────────────
DARK = {
    "BG":       _rgb("0D0D2E"),
    "WHITE":    _rgb("FFFFFF"),
    "NAVY":     _rgb("FFFFFF"),       # text colour on dark = white
    "DARK":     _rgb("CCCCCC"),
    "GRAY":     _rgb("888888"),
    "LGRAY":    _rgb("555555"),
    "LINE":     _rgb("2A2A50"),
    "CARD":     _rgb("181842"),
    "CODE_BG":  _rgb("141428"),
    "CODE_FG":  _rgb("CCDDEE"),
    "ORANGE":   ACCENTS["orange"],
    "LRED":     _rgb("2A1010"),
    "LGREEN":   _rgb("0D2010"),
    "RED":      _rgb("EF5350"),
    "GREEN":    _rgb("4CAF50"),
    "name":     "dark",
}


def get_theme(name: str) -> dict:
    """Return the theme dict for 'light' or 'dark'."""
    return LIGHT if name == "light" else DARK


def accent_color(name: str) -> RGBColor:
    """Return the main RGBColor for a named accent (orange, blue, teal …)."""
    return ACCENTS.get(name, ACCENTS["orange"])


def accent_light(name: str) -> RGBColor:
    """Return the light-tint RGBColor for a named accent."""
    return ACCENT_LIGHT.get(name, ACCENT_LIGHT["orange"])
