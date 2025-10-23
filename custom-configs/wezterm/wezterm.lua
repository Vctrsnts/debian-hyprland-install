--- wezterm.lua
--- __      __      _
--- \ \    / /__ __| |_ ___ _ _ _ __
---  \ \/\/ / -_)_ /  _/ -_) '_| '  \
---   \_/\_/\___/__|\__\___|_| |_|_|_|
---
--- My Wezterm config file

local wezterm = require 'wezterm'
local act = wezterm.action

local config = {}
if wezterm.config_builder then config = wezterm.config_builder() end

--- Default Program Settings
config.default_prog = {"/bin/bash"}

--- Color Settings
config.color_scheme = "Tokyo Night"
config.colors = {
  cursor_bg = "white",
  cursor_border = "white"
}

--- Font Settings
config.font_size = 10.5
--- config.line_height = 1.2
config.font = wezterm.font("JetBrains Mono")
--- config.default_cursor_style = "BlinkingBar"

--- Apparence Settings
config.window_background_opacity = 0.90
config.window_padding = {
  left = 10,
  right = 10,
  top = 10,
  bottom = 10,
}
config.default_workspace = "home"
config.window_decorations = "RESIZE"
config.scrollback_lines = 10000

--- Key Settings
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
  -- Dividir el terminal
  { key = "v", mods = "LEADER", action = act{ SplitVertical = {domain = "CurrentPaneDomain" }}},
  { key = "h", mods = "LEADER", action = act{ SplitHorizontal = {domain = "CurrentPaneDomain" }}},

  -- Crear una nueva pestaña
  { key = "t", mods = "LEADER", action = act{ SpawnTab = "CurrentPaneDomain" }},

  -- Cambiar entre pestañas
  { key = "LeftArrow", mods = "CTRL|SUPER", action = act{ ActivatePaneDirection = "Next" }},
  { key = "RightArrow", mods = "CTRL|SUPER", action = act{ ActivatePaneDirection = "Prev" }}
}

--- Tabs Settings
config.inactive_pane_hsb = {
  saturation = 0.54,
  brightness = 0.2
}
config.use_fancy_tab_bar = false
config.status_update_interval = 1000
config.tab_bar_at_bottom = false

-- I can use the tab navigator (LDR t), but I also want to quickly navigate tabs with index
for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = act.ActivateTab(i - 1)
  })
end

--- Decoration Settings
wezterm.on("update-status", function(window, pane)
  -- Workspace name
  local stat = window:active_workspace()
  local stat_color = "#f7768e"
  -- It's a little silly to have workspace name all the time
  -- Utilize this to display LDR or current key table name
  if window:active_key_table() then
    stat = window:active_key_table()
    stat_color = "#7dcfff"
  end
  if window:leader_is_active() then
    stat = "LDR"
    stat_color = "#bb9af7"
  end

  local basename = function(s)
    -- Nothing a little regex can't fix
    return string.gsub(s, "(.*[/\\])(.*)", "%2")
  end

  -- Current working directory
  local cwd = pane:get_current_working_dir()
  if cwd then
    if type(cwd) == "userdata" then
      -- Wezterm introduced the URL object in 20240127-113634-bbcac864
      cwd = basename(cwd.file_path)
    else
      -- 20230712-072601-f4abf8fd or earlier version
      cwd = basename(cwd)
    end
  else
    cwd = ""
  end

  -- Current command
  local cmd = pane:get_foreground_process_name()
  -- CWD and CMD could be nil (e.g. viewing log using Ctrl-Alt-l)
  cmd = cmd and basename(cmd) or ""

  -- Time
  local time = wezterm.strftime("%H:%M")

  -- Left status (left of the tab line)
  window:set_left_status(wezterm.format({
    { Foreground = { Color = stat_color } },
    { Text = "  " },
    { Text = wezterm.nerdfonts.oct_table .. "  " .. stat },
    { Text = " |" },
  }))

  -- Right status
  window:set_right_status(wezterm.format({
    { Text = wezterm.nerdfonts.md_folder .. "  " .. cwd },
    { Text = " | " },
    { Foreground = { Color = "#e0af68" } },
    { Text = wezterm.nerdfonts.fa_code .. "  " .. cmd },
    "ResetAttributes",
    { Text = " | " },
    { Text = wezterm.nerdfonts.md_clock .. "  " .. time },
    { Text = "  " },
  }))
end)

--- Mouse Settings
config.mouse_bindings = {
  { event = { Up = { streak = 1, button = "Right" } }, mods = "NONE", action = act{ PasteFrom = "PrimarySelection" } },
}

return config

---return {
---  status_update_interval = 1, 

---  font_rules = {
---    {
---      intensity = "Bold",
---      font = wezterm.font_with_fallback({"Fira Code", "Monospace"})
---    },
---  },

---   use_fancy_tab_bar = true, -- Mostrar una barra de pestañas con los nombres de las pestañas
---  tab_bar_at_bottom = false, -- Coloca la barra de pestañas en la parte superior (cambiar a `true` si prefieres abajo)
---  hide_tab_bar_if_only_one_tab = true,

---  inactive_pane_hsb = {
---    saturation = 0.8,
---    brightness = 0.1,
---  },
  
--- Teclas de acceso rápido
---  keys = {
---    -- Dividir el terminal
---    {key="v", mods="CTRL|SUPER", action=act{SplitVertical={domain="CurrentPaneDomain"}}},
---    {key="h", mods="CTRL|SUPER", action=act{SplitHorizontal={domain="CurrentPaneDomain"}}},

---    -- Crear una nueva pestaña
---    {key="t", mods="CTRL|SHIFT", action=wezterm.action{SpawnTab="CurrentPaneDomain"}},

---    -- Cambiar entre pestañas
---    {key="LeftArrow", mods="CTRL|SUPER", action=act{ActivatePaneDirection="Next"}},
---    {key="RightArrow", mods="CTRL|SUPER", action=act{ActivatePaneDirection="Prev"}}
---  },
---}
