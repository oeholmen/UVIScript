--------------------------------------------------------------------------------
-- Common Scales
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

-- Make sure these are in sync with the scale names
-- Scales are defined by distance to the next step
local scaleDefinitions = {
  {def={2,2,1,2,2,2,1},name="7 Notes/Major (Ionian)",},
  {def={2,1,2,2,1,2,2},name="7 Notes/Minor (Aeolian)",},
  {def={2,1,2,2,2,1,2},name="7 Notes/Dorian",},
  {def={1,2,2,2,1,2,2},name="7 Notes/Phrygian",},
  {def={2,2,2,1,2,2,1},name="7 Notes/Lydian",},
  {def={2,2,1,2,2,1,2},name="7 Notes/Mixolydian",},
  {def={1,2,2,1,2,2,2},name="7 Notes/Locrian",},
  {def={2,2,2,1,2,1,2},name="7 Notes/Acoustic",},
  {def={2,1,2,1,1,3,2},name="7 Notes/Blues",},
  {def={1,2,1,3,1,2,2},name="7 Notes/Alterated",},
  {def={2,1,3,1,1,3,1},name="7 Notes/Maqam Saba",},
  {def={1,3,1,2,3,1,1},name="7 Notes/Persian",},
  {def={1,3,1,2,1,3,1},name="7 Notes/Arabic",},
  {def={2,1,3,1,1,2,2},name="7 Notes/Hungarian",},
  {def={2,2,3,2,3},name="5 Notes/Major Pentatonic",},
  {def={3,2,2,3,2},name="5 Notes/Minor Pentatonic",},
  {def={1,4,1,4,2},name="5 Notes/Hirajoshi",},
  {def={1,4,2,1,4},name="5 Notes/Miyako-Bushi",},
  {def={1,4,3,2,2},name="5 Notes/Iwato",},
  {def={2,2,1,2,2},name="5 Notes/Ritsu",},
  {def={2,1,4,2,1},name="5 Notes/Kumoi",},
  {def={1,3,1,2,3},name="5 Notes/Maqam Hijaz",},
  {def={2,1,4,1,2},name="5 Notes/Maqam Bayati",},
  {def={3},name="Diminished",},
  {def={2},name="Whole tone",},
  {def={1},name="Chomatic",},
}

local function getScaleNames()
  local items = {}
  for _,s in ipairs(scaleDefinitions) do
    table.insert(items, s.name)
  end
  return items
end

local function getScaleDefinitions()
  local items = {}
  for _,s in ipairs(scaleDefinitions) do
    table.insert(items, s.def)
  end
  return items
end

local function getTextFromScaleDefinition(scaleDefinition)
  if type(scaleDefinition) == nil or #scaleDefinition == 0 then
    return ""
  end
  return table.concat(scaleDefinition, ",")
end

local function createRandomScale(resolve, probability)
  if type(resolve) == "nil" then
    resolve = 12 -- The sum of the definition should resolve to this
  end
  if type(probability) == "nil" then
    probability = 50 -- Probability that the selected interval is 1 or 2
  end
  local sum = 0 -- Current scale definion sum
  local maxSum = 24
  local intervals1 = {1,2}
  local intervals2 = {1,2,3,4}
  local scaleDefinition = {}
  repeat
    local interval = 1
    if gem.getRandomBoolean(probability) then
      interval = gem.getRandomFromTable(intervals1)
    else
      interval = gem.getRandomFromTable(intervals2)
    end
    table.insert(scaleDefinition, interval)
    sum = gem.inc(sum, interval)
  until #scaleDefinition > 3 and (resolve % sum == 0 or maxSum % sum == 0 or sum >= maxSum)
  return scaleDefinition
end

local function getScaleDefinitionFromText(scaleText)
  local scale = {}
  if string.len(scaleText) > 0 then
    for w in string.gmatch(scaleText, "%d+") do
      table.insert(scale, tonumber(w))
    end
    print("Get scale from input", #scale)
  end
  return scale
end

local function getScaleDefinitionIndex(scaleDefinition)
  -- Check if we find a scale definition that matches the given definition
  if type(scaleDefinition) == "table" then
    scaleDefinition = getTextFromScaleDefinition(scaleDefinition)
  end
  for i,v in ipairs(scaleDefinitions) do
    if scaleDefinition == getTextFromScaleDefinition(v.def) then
      print("getScaleDefinitionIndex: found scale", v.name)
      return i
    end
  end
end

local function getScaleInputTooltip(scaleDefinition)
  local sum = gem.sum(scaleDefinition)
  local tooltip = "Scales are defined by setting semitones up from the previous note. The current scale has " .. #scaleDefinition .. " notes and the definition sum is " .. sum
  if 12 % sum == 0 then
    tooltip = tooltip .. ", whitch resolves every octave."
  else
    tooltip = tooltip .. ", whitch does not resolve every octave."
  end
  return tooltip
end

local function getScaleWidget(options, i)
  -- Scale widget
  if type(options) == "nil" then
    options = {}
  end
  if type(i) == "nil" then
    i = ""
  end
  options.name = gem.getValueOrDefault(options.name, "Scale" .. i)
  options.tooltip = gem.getValueOrDefault(options.tooltip, "Select a scale")
  options.hierarchical = true
  options.showLabel = gem.getValueOrDefault(options.showLabel, true)
  return widgets.menu("Scale", #scaleDefinitions, getScaleNames(), options)
end

local function getScaleInputWidget(scaleDefinition, width, i)
  -- Scale input widget
  if type(i) == "nil" then
    i = ""
  end
  local options = {
    name = "ScaleInput" .. i,
    tooltip = getScaleInputTooltip(scaleDefinition),
    editable = true,
    backgroundColour = "black",
    backgroundColourWhenEditing = "white",
    textColourWhenEditing = "black",
    textColour = "white",
  }
  if type(width) == "number" then
    options.width = width
  end
  return widgets.label(getTextFromScaleDefinition(scaleDefinition), options)
end

local function handleScaleInputChanged(self, scaleMenu)
  print("scaleInput.changed", self.text)
  local scaleDefinition = getScaleDefinitionFromText(self.text)
  if #scaleDefinition == 0 then
    -- Ensure we have a scale...
    print("No scale def. Using default scale.")
    scaleDefinition = scaleDefinitions[#scaleDefinitions]
    scaleMenu:setValue(#scaleDefinitions)
    return handleScaleInputChanged(self, scaleMenu)
  end
  self.tooltip = getScaleInputTooltip(scaleDefinition)
  return scaleDefinition
end

return {--scales--
  widget = getScaleWidget,
  inputWidget = getScaleInputWidget,
  getScaleInputTooltip = getScaleInputTooltip,
  getScaleDefinitionIndex = getScaleDefinitionIndex,
  handleScaleInputChanged = handleScaleInputChanged,
  getTextFromScaleDefinition = getTextFromScaleDefinition,
  getScaleDefinitionFromText = getScaleDefinitionFromText,
  getScaleDefinitions = getScaleDefinitions,
  getScaleNames = getScaleNames,
  createRandomScale = createRandomScale,
  createScale = function(scaleDefinition, rootNote, maxNote)
    if type(maxNote) ~= "number" then
      maxNote = 127
    end
    while rootNote < 0 do
      rootNote = rootNote + 12
      print("Transpose root note up to within range", rootNote)
    end
    while maxNote > 127 do
      maxNote = maxNote - 12
      print("Transpose max note down to within range", maxNote)
    end
    local scale = {}
    -- Find notes for scale
    local pos = 1
    while rootNote <= maxNote do
      table.insert(scale, rootNote)
      rootNote = rootNote + scaleDefinition[pos]
      pos = pos + 1
      if pos > #scaleDefinition then
        pos = 1
      end
    end
    return scale
  end
}
