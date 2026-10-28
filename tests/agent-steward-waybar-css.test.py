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
reference_css = """
#reference { background: @base0C; border-radius: 4px; }
#reference.critical { background: @base08; }
#reference.unknown { background: @base01; }
"""
css = (colors + "\n" + Path(sys.argv[1]).read_text() + reference_css).encode()
assert load(provider, css, len(css), None), "Quota stylesheet must be valid GTK CSS"


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
width = bind("gtk_widget_get_preferred_width", None, [pointer, pointer, pointer])
queue_resize = bind("gtk_widget_queue_resize", None, [pointer])
add_class = bind("gtk_style_context_add_class", None, [pointer, string])
remove_class = bind("gtk_style_context_remove_class", None, [pointer, string])


def natural_width(label):
    # CSS changes on this unparented widget do not invalidate its cached size.
    queue_resize(label)
    minimum, natural = integer(), integer()
    width(label, ctypes.byref(minimum), ctypes.byref(natural))
    return natural.value


surface_new = bind("cairo_image_surface_create", pointer, [integer, integer, integer])
cairo_new = bind("cairo_create", pointer, [pointer])
render = bind("gtk_render_background", None, [pointer, pointer] + [ctypes.c_double] * 4)
flush = bind("cairo_surface_flush", None, [pointer])
image_data = bind("cairo_image_surface_get_data", pointer, [pointer])
cairo_destroy = bind("cairo_destroy", None, [pointer])
surface_destroy = bind("cairo_surface_destroy", None, [pointer])


def background_pixels(context):
    surface = surface_new(0, 20, 20)
    cairo = cairo_new(surface)
    render(context, cairo, 0, 0, 20, 20)
    flush(surface)
    pixels = ctypes.string_at(image_data(surface), 20 * 20 * 4)
    cairo_destroy(cairo)
    surface_destroy(surface)
    return pixels


reference = bind("gtk_label_new", pointer, [string])(b"Reference")
bind("gtk_widget_set_name", None, [pointer, string])(reference, b"reference")
reference_context = bind("gtk_widget_get_style_context", pointer, [pointer])(reference)
bind("gtk_style_context_add_provider", None, [pointer, pointer, ctypes.c_uint])(
    reference_context, provider, 600
)

for index, text in enumerate((b"Codex 65%", b"Gemini 80%")):
    label = bind("gtk_label_new", pointer, [string])(text)
    bind("gtk_widget_set_name", None, [pointer, string])(
        label, f"custom-agent-steward-{index}".encode()
    )
    bind("gtk_widget_show", None, [pointer])(label)
    context = bind("gtk_widget_get_style_context", pointer, [pointer])(label)
    original = natural_width(label)
    assert original > 0
    bind("gtk_style_context_add_provider", None, [pointer, pointer, ctypes.c_uint])(
        context, provider, 600
    )
    for state, background, foreground in [
        (b"healthy", 12, 0),
        (b"critical", 8, 0),
        (b"unknown", 1, 4),
    ]:
        add_class(context, state)
        assert natural_width(label) == original + 16, (
            "Each quota block must add 6px padding and 2px margin per side"
        )
        for getter, expected in [
            (get_padding, (6, 6, 0, 0)),
            (get_margin, (2, 2, 0, 0)),
        ]:
            spacing = Border()
            getter(context, 0, ctypes.byref(spacing))
            actual = tuple(
                getattr(spacing, edge) for edge in ("left", "right", "top", "bottom")
            )
            assert actual == expected, f"{index}/{state!r}: {actual} != {expected}"
        add_class(reference_context, state)
        assert background_pixels(context) == background_pixels(reference_context), (
            "Rendered colors and 4px corners must match the other Waybar blocks"
        )
        remove_class(reference_context, state)
        for getter, expected in [
            (get_background, background),
            (get_foreground, foreground),
        ]:
            color = RGBA()
            getter(context, 0, ctypes.byref(color))
            actual = tuple(
                round(getattr(color, channel) * 255)
                for channel in ("red", "green", "blue")
            )
            assert actual == (expected,) * 3, (
                f"{index}/{state!r}: wrong palette {actual}"
            )
            assert color.alpha == 1
        remove_class(context, state)
print("GTK quota blocks match Waybar padding, margins, corners and per-pool colors")
