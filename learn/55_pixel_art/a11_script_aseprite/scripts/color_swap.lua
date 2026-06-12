--[[
color_swap.lua — swap every FG-color pixel with BG-color (whole sprite)

The teaching version of carbscode's "Color Swap" extension idea:
pick two colors (FG = Alt+click, BG = Alt+right-click), run script,
they trade places everywhere.

Install: copy into Aseprite scripts folder (File > Scripts > Open
Scripts Folder), rescan, bind a key (Edit > Keyboard Shortcuts).

Works on RGB-mode sprites (Sprite > Color Mode > RGB Color).
]]

local spr = app.activeSprite
if not spr then return app.alert("No active sprite") end
if spr.colorMode ~= ColorMode.RGB then
  return app.alert("Switch to RGB color mode first (Sprite > Color Mode)")
end

local pc = app.pixelColor
local fg = app.fgColor
local bg = app.bgColor

local fg_val = pc.rgba(fg.red, fg.green, fg.blue, fg.alpha)
local bg_val = pc.rgba(bg.red, bg.green, bg.blue, bg.alpha)

if fg_val == bg_val then return app.alert("FG and BG are the same color") end

app.transaction(function()
  for _, cel in ipairs(spr.cels) do
    local img = cel.image
    for it in img:pixels() do
      local v = it()
      if v == fg_val then
        it(bg_val)
      elseif v == bg_val then
        it(fg_val)
      end
    end
  end
end)

app.refresh()
