--------------------------------------------------------------------------------
-- Common Scales
--------------------------------------------------------------------------------

-- Make sure these are in sync with the scale names
-- Scales are defined by distance to the next step
local scaleDefinitions = {
  {2,2,1,2,2,2,1}, -- Major (Ionian mode)
  {2,1,2,2,1,2,2}, -- Minor (Aeolian mode)
  {2,1,2,2,2,1,2}, -- Dorian mode
  {1,2,2,2,1,2,2}, -- Phrygian mode
  {2,2,2,1,2,2,1}, -- Lydian mode
  {2,2,1,2,2,1,2}, -- Mixolydian mode
  {1,2,2,1,2,2,2}, -- Locrian mode
  {2,2,2,1,2,1,2}, -- Acoustic
  {2,1,2,1,1,3,2}, -- Blues
  {1,2,1,3,1,2,2}, -- Alterated
  {2,2,3,2,3}, -- Major Pentatonic
  {3,2,2,3,2}, -- Minor Pentatonic
  {3}, -- Diminished
  {2}, -- Whole tone scale
  {1}, -- Chomatic
}

local scaleNames = {
  "Major (Ionian)",
  "Minor (Aeolian)",
  "Dorian",
  "Phrygian",
  "Lydian",
  "Mixolydian",
  "Locrian",
  "Acoustic",
  "Blues",
  "Alterated",
  "Major Pentatonic",
  "Minor Pentatonic",
  "Diminished",
  "Whole tone",
  "Chomatic",
}

return {
  getScaleDefinitions = function()
    return scaleDefinitions
  end,

  getScaleNames = function()
    return scaleNames
  end,

  createScale = function(scaleDefinition, rootNote)
    local scale = {}
    -- Find notes for scale
    local pos = 0
    while rootNote < 128 do
      table.insert(scale, rootNote)
      pos = pos + 1
      rootNote = rootNote + scaleDefinition[pos]
      if pos == #scaleDefinition then
        pos = 0
      end
    end
    return scale
  end
}
