------------------------------------------------------------------------
-- Pitch offset randomly adjusts the pitch offset of the incoming note
------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local notes = require "includes.notes"
local noteNumberToNoteName = notes.getNoteMapping()
local noteNames = {"All notes"}

for _,v in ipairs(notes.getNoteNames()) do
  table.insert(noteNames, v)
end

widgets.panel({
  width = 720,
  height = 50
})

widgets.setSection({
  width = 123,
  cols = 8,
  x = 15,
  y = 18,
  xSpacing = 15,
  ySpacing = 5,
})

local label = widgets.label("Pitch offset", {
  alpha = 0.75,
  fontSize = 24,
  backgroundColour = "transparent",
  backgroundColourWhenEditing = "white",
  textColourWhenEditing = "black",
  textColour = "865DFF",
})

local noteFilter = widgets.menu("Note filter", noteNames, {
  tooltip = "Only adjust if incoming note is the selected note",
  width = 90,
  showLabel = false,
})

local probability = widgets.numBox("Probability", 50, {
  tooltip = "Set the probability that the pitch of incomming note will be adjusted",
  unit = Unit.Percent,
})

local upDownProbability = widgets.numBox("Up/Down", 50, {
  tooltip = "Set the up/down probability. 0 = always down, 50 = equal chance, 100 = always up.",
  unit = Unit.Percent,
})

local minInput = widgets.numBox('Min', 0, {
  tooltip = "Minimum pitch offset adjustment",
  width = 75,
  min = 0,
  max = 12,
  integer = true,
})

local maxInput = widgets.numBox('Max', 1, {
  tooltip = "Maximum pitch offset adjustment",
  width = 75,
  min = 0,
  max = 12,
  integer = true,
})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function adjustPitch(note)
  local noteIndex = note + 1
  local noteFilterMatch = noteFilter.value == 1 or noteNumberToNoteName[noteIndex] == noteNames[noteFilter.value]
  if gem.getRandomBoolean(probability.value) == false or noteFilterMatch == false then
    --print("No change: notenumber, notename, notefilter", note, noteNumberToNoteName[noteIndex], noteNames[noteFilter.value])
    return note
  end
  local min = math.min(minInput.value, maxInput.value)
  local max = math.max(minInput.value, maxInput.value)
  print("min, max", min, max)
  local offset = 0
  if min == max then
    offset = min
  elseif max == 1 then
    if gem.getRandomBoolean() then
      offset = max
    else
      offset = min
    end
  else
    offset = gem.getRandom(min, max)
  end
  if offset > 0 and gem.getRandomBoolean(upDownProbability.value) == false then
    offset = -offset
  end
  noteIndex = note + offset + 1
  print("offset, note", offset, noteNumberToNoteName[noteIndex])
  return note + offset
end

function onNote(e)
  e.note = adjustPitch(e.note)
  postEvent(e)
end
