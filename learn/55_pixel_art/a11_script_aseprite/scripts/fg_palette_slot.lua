--[[
fg_palette_slot.lua — set foreground color to a fixed palette slot

The teaching version of carbscode's "Quick Color Hotkeys" idea:
one key = one palette color, no mouse trip to the palette.

USAGE: copy this file once per slot you want:
  fg_palette_slot_1.lua  (SLOT = 0)
  fg_palette_slot_2.lua  (SLOT = 1)
  ...
edit SLOT in each copy, bind each to a key (e.g. Alt+1, Alt+2, ...).
Crude? Yes. Yours? Completely. (A real extension with commands and a
package.json is the stretch goal in the lesson.)
]]

local SLOT = 0 -- palette index, 0-based. EDIT THIS PER COPY.

local spr = app.activeSprite
if not spr then return app.alert("No active sprite") end

local pal = spr.palettes[1]
if SLOT >= #pal then
  return app.alert("Palette has only " .. #pal .. " colors (slot " .. SLOT .. " missing)")
end

app.fgColor = pal:getColor(SLOT)
