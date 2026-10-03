import ctypes
import sys
from pathlib import Path

gtk = ctypes.CDLL(sys.argv[2])


def bind(name, result, arguments):
    function = getattr(gtk, name)
    function.restype = result
    function.argtypes = arguments
    return function


pointer = ctypes.c_void_p
string = ctypes.c_char_p
integer = ctypes.c_int
init = bind("gtk_init_check", integer, [pointer, pointer])
assert init(None, None), "GTK test display unavailable"
provider = bind("gtk_css_provider_new", pointer, [])()
load = bind(
    "gtk_css_provider_load_from_data",
    integer,
    [pointer, string, ctypes.c_ssize_t, pointer],
)
colors = "\n".join(
    f"@define-color base{index:02X} #{index:02X}{index:02X}{index:02X};"
    for index in range(16)
)
css = (colors + "\n" + Path(sys.argv[1]).read_text()).encode()
assert load(provider, css, len(css), None), "Quota stylesheet must be valid GTK CSS"

label = bind("gtk_label_new", pointer, [string])(
    b"Codex 65% \xc2\xb7 xAI 42% \xc2\xb7 Gemini 80%"
)
bind("gtk_widget_set_name", None, [pointer, string])(label, b"custom-agent-steward")
bind("gtk_widget_show", None, [pointer])(label)
context = bind("gtk_widget_get_style_context", pointer, [pointer])(label)
width = bind("gtk_widget_get_preferred_width", None, [pointer, pointer, pointer])
queue_resize = bind("gtk_widget_queue_resize", None, [pointer])


def natural_width():
    # CSS changes on this unparented widget do not invalidate its cached size.
    queue_resize(label)
    minimum, natural = integer(), integer()
    width(label, ctypes.byref(minimum), ctypes.byref(natural))
    return natural.value


original = natural_width()
assert original > 0
bind("gtk_style_context_add_provider", None, [pointer, pointer, ctypes.c_uint])(
    context, provider, 600
)
assert natural_width() == original + 4, (
    "Quota styling must add only 2px padding per side"
)
add_class = bind("gtk_style_context_add_class", None, [pointer, string])
remove_class = bind("gtk_style_context_remove_class", None, [pointer, string])


class RGBA(ctypes.Structure):
    _fields_ = [
        (channel, ctypes.c_double) for channel in ("red", "green", "blue", "alpha")
    ]


class Border(ctypes.Structure):
    _fields_ = [(edge, ctypes.c_int16) for edge in ("left", "right", "top", "bottom")]


get_padding = bind(
    "gtk_style_context_get_padding", None, [pointer, ctypes.c_uint, pointer]
)
get_margin = bind(
    "gtk_style_context_get_margin", None, [pointer, ctypes.c_uint, pointer]
)
get_background = bind(
    "gtk_style_context_get_background_color", None, [pointer, ctypes.c_uint, pointer]
)
get_foreground = bind(
    "gtk_style_context_get_color", None, [pointer, ctypes.c_uint, pointer]
)
for state, background, foreground in [
    (b"healthy", 12, 0),
    (b"warning", 10, 0),
    (b"critical", 8, 0),
    (b"unknown", 1, 4),
]:
    add_class(context, state)
    assert natural_width() == original + 4, (
        f"{state!r} styling must preserve the small padding"
    )
    for getter, expected in [(get_padding, (2, 2, 0, 0)), (get_margin, (0, 0, 0, 0))]:
        spacing = Border()
        getter(context, 0, ctypes.byref(spacing))
        actual = tuple(
            getattr(spacing, edge) for edge in ("left", "right", "top", "bottom")
        )
        assert actual == expected, (
            f"{state!r}: expected spacing {expected}, got {actual}"
        )
    for getter, expected in [
        (get_background, background),
        (get_foreground, foreground),
    ]:
        color = RGBA()
        getter(context, 0, ctypes.byref(color))
        actual = tuple(
            round(getattr(color, channel) * 255) for channel in ("red", "green", "blue")
        )
        assert actual == (expected,) * 3, (
            f"{state!r}: expected palette {expected}, got {actual}"
        )
        assert color.alpha == 1
    remove_class(context, state)
print("GTK CSS parses; state background/text colors and compact widths verified")
