local icons = require("icons")
local colors = require("colors")
local settings = require("settings")

local caffeine = sbar.add("item", "widgets.caffeine", {
  position = "right",
  icon = {
    font = {
      style = settings.font.style_map["Regular"],
      size = 19.0,
    },
    string = icons.caffeine.off,
    color = colors.grey,
  },
  label = { drawing = false },
  update_freq = 60,
})

-- Helper function to update caffeine icon state
local function update_caffeine_state(is_running)
  caffeine:set({
    icon = {
      string = is_running and icons.caffeine.on or icons.caffeine.off,
      color = is_running and colors.red or colors.grey,
    }
  })
end

-- Toggle caffeine function
local function toggle_caffeine(env)
  sbar.exec("pgrep caffeinate", function(result)
    local is_running = result ~= ""
    if is_running then
      sbar.exec("killall caffeinate")
      update_caffeine_state(false)
    else
      sbar.exec("caffeinate -d & disown")
      update_caffeine_state(true)
    end
  end)
end

-- Subscribe to mouse click events
caffeine:subscribe("mouse.clicked", toggle_caffeine)

-- Subscribe to custom event for external triggering (e.g. from skhd)
sbar.add("event", "toggle_caffeine")
caffeine:subscribe("toggle_caffeine", toggle_caffeine)

-- Check initial state and set appropriate icon
caffeine:subscribe("routine", function()
  sbar.exec("pgrep caffeinate", function(result)
    local is_running = result ~= ""
    update_caffeine_state(is_running)
  end)
end)

-- Background around the caffeine item
sbar.add("bracket", "widgets.caffeine.bracket", { caffeine.name }, {
  background = { color = colors.bg1 }
})

-- Padding to match other widgets
sbar.add("item", "widgets.caffeine.padding", {
  position = "right",
  width = settings.group_paddings
})
