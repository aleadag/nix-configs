local colors = require("colors")

local mode_indicator = sbar.add("item", "mode_indicator", {
  drawing = false,
  background = {
    color = colors.bg1,
    border_color = colors.bg2,
    border_width = 2,
    corner_radius = 9,
    height = 26,
  },
  label = {
    color = colors.white,
    padding_left = 10,
    padding_right = 10,
    font = {
      style = "Bold",
      size = 13.0,
    },
  },
  icon = { drawing = false },
  padding_right = 5,
  padding_left = 5,
})
