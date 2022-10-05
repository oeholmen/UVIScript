-------------------------------------------------------------------------------
-- Random note generator
-------------------------------------------------------------------------------

require "common"

local isRunning = false
local playingNotes = {} -- Keep track of incoming notes, to avoid dupicates
local resolutionTypes = getResolutionsByType()
local maxResolutionIndex = 26

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"
--local menuBackgroundColour = "01011F"
--local menuArrowColour = "66" .. labelTextColour
--local menuOutlineColour = "5f" .. widgetTextColour
--local knobFillColour = "E6D5B8" -- Light

setBackgroundColour(backgroundColour)

local widgetWidth = 120

local panel = Panel("Bouncer")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 60

local label = panel:Label("Label")
label.text = "Random Note"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 125

--[[ local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Start Duration"
waitResolution.tooltip = "Start duration"
waitResolution.selected = 17
waitResolution.width = widgetWidth / 1.5
waitResolution.x = label.x + label.width + 15
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local minResolution = panel:Menu("MinResolution", getResolutionNames())
minResolution.displayName = "Resolution Min"
minResolution.tooltip = ""
minResolution.selected = 26
minResolution.width = widgetWidth / 1.5
minResolution.x = waitResolution.x + waitResolution.width + 10
minResolution.backgroundColour = menuBackgroundColour
minResolution.textColour = widgetTextColour
minResolution.arrowColour = menuArrowColour
minResolution.outlineColour = menuOutlineColour ]]

local repeatProbability = panel:NumBox("Probability", 0, 0, 100, true)
repeatProbability.unit = Unit.Percent
repeatProbability.displayName = "Note Repeat"
repeatProbability.tooltip = "Probability that a note will repeat"
repeatProbability.textColour = widgetTextColour
repeatProbability.backgroundColour = widgetBackgroundColour
repeatProbability.y = label.y
repeatProbability.x = label.x + label.width + 30
repeatProbability.width = widgetWidth

local noteRandomization = panel:NumBox("NoteRandomization", 25, 0, 100, true)
noteRandomization.unit = Unit.Percent
noteRandomization.textColour = widgetTextColour
noteRandomization.backgroundColour = widgetBackgroundColour
noteRandomization.displayName = "Note Move"
noteRandomization.tooltip = "Note movement amount"
noteRandomization.width = widgetWidth
noteRandomization.x = repeatProbability.x
noteRandomization.y = repeatProbability.y + repeatProbability.height + 5

local gateInput = panel:NumBox("Gate", 90, 0, 100, true)
gateInput.unit = Unit.Percent
gateInput.textColour = widgetTextColour
gateInput.backgroundColour = widgetBackgroundColour
gateInput.displayName = "Gate"
gateInput.tooltip = "Note gate"
gateInput.width = widgetWidth
gateInput.x = repeatProbability.x + repeatProbability.width + 10
gateInput.y = repeatProbability.y

local gateRandomization = panel:NumBox("GateRand", 0, 0, 100, true)
gateRandomization.unit = Unit.Percent
gateRandomization.textColour = widgetTextColour
gateRandomization.backgroundColour = widgetBackgroundColour
gateRandomization.displayName = "Gate Rand"
gateRandomization.tooltip = "Gate randomization amount"
gateRandomization.width = widgetWidth
gateRandomization.x = gateInput.x
gateRandomization.y = gateInput.y + gateInput.height + 5

local noteMin = panel:NumBox("NoteMin", 21, 0, 127, true)
noteMin.unit = Unit.MidiKey
noteMin.textColour = widgetTextColour
noteMin.backgroundColour = widgetBackgroundColour
noteMin.displayName = "Min Note"
noteMin.tooltip = "Lowest note - notes below this are transposed to closest octave within range"
noteMin.width = widgetWidth
noteMin.x = gateRandomization.x + gateRandomization.width + 10
noteMin.y = gateInput.y

local noteMax = panel:NumBox("NoteMax", 108, 0, 127, true)
noteMax.unit = Unit.MidiKey
noteMax.textColour = widgetTextColour
noteMax.backgroundColour = widgetBackgroundColour
noteMax.displayName = "Max Note"
noteMax.tooltip = "Highest note - notes above this are transposed to closest octave within range"
noteMax.width = widgetWidth
noteMax.x = noteMin.x
noteMax.y = noteMin.y + noteMin.height + 5

-- Range must be at least one octave
noteMin.changed = function(self)
  noteMax:setRange((self.value+12), 127)
end

noteMax.changed = function(self)
  noteMin:setRange(0, (self.value-12))
end

function getResolutionIndex(currentResolutionIndex, currentType, typeRepeats, resolutionRepeats, storedDurations)
  local changeResolutionTypeProbability = 0
  local changeResolutionProbability = 0

  typeRepeats = typeRepeats + 1 -- Increment repeats
  resolutionRepeats = resolutionRepeats + 1 -- Increment repeats

  print("resolutionRepeats % currentType", resolutionRepeats, currentType, resolutionRepeats % currentType)

  if type(currentResolutionIndex) == "nil" then
    changeResolutionProbability = 100
  elseif resolutionRepeats % currentType == 0 then
    -- Change res type prob
    changeResolutionTypeProbability = math.min(100, ((currentType ^ 2) * (typeRepeats ^ 2)))
    print("changeResolutionTypeProbability increased to", changeResolutionTypeProbability)

    -- Change res prob
    local resolution = getResolution(currentResolutionIndex)
    local factor = resolution * (resolutionRepeats ^ 2)
    changeResolutionProbability = math.min(100, (resolutionRepeats * factor))
    print("factor, resolution, resolutionRepeats", factor, resolution, resolutionRepeats)
    print("changeResolutionProbability increased to", changeResolutionProbability)
  end

  local changeResolution = getRandomBoolean(changeResolutionProbability)
  local changeResolutionType = getRandomBoolean(changeResolutionTypeProbability)
  if changeResolution then
    print("changeResolution", changeResolution)
    resolutionRepeats = 0 -- Reset resolution repeats
  elseif changeResolutionType then
    changeResolution = true
    -- TODO Set next type using probability from current type
    local available = {1,2,3}
    -- Remove previous resolution type to avoid repeat
    table.remove(available, currentType)
    currentType = getRandomFromTable(available)
    typeRepeats = 0 -- Reset type repeats
    resolutionRepeats = 0 -- Reset resolution repeats
    print("changeType", currentType)
  end

  if changeResolution then
    print("changeResolution before", currentResolutionIndex)
    local current = {}
    for _,v in ipairs(resolutionTypes[currentType]) do
      -- Remove previous resolution to avoid repeat
      if v ~= currentResolutionIndex then
        table.insert(current, v)
      end
    end

    currentResolutionIndex = getRandomFromTable(current)
    if currentResolutionIndex > maxResolutionIndex then
      print("currentResolutionIndex > maxResolutionIndex", currentResolutionIndex, maxResolutionIndex)
      print("#current, current[1], current[#current]", #current, current[1], current[#current])
      currentResolutionIndex = current[1]
    end
    print("changeResolution after", currentResolutionIndex)
  else
    print("Repeat resolution", currentResolutionIndex)
  end

  -- TODO Save resolution history and check sync at regular intervals (2x or other)
  -- TODO Disabled until we have a reset option
  --table.insert(storedDurations, getResolution(currentResolutionIndex))

  return currentResolutionIndex, currentType, typeRepeats, resolutionRepeats, storedDurations
end

function generateNote(note)
  if type(note) == "nil" then
    note = 64
  end
  local min = math.min(noteMin.value, noteMax.value)
  local max = math.max(noteMin.value, noteMax.value)
  local maxRounds = 100
  repeat
    note = randomizeValue(note, min, max, noteRandomization.value)
    maxRounds = maxRounds - 1
  until tableIncludes(playingNotes, note) == false or maxRounds < 1
  return note
end

function play()
  local note = nil
  local storedDurations = {}
  local currentResolutionIndex = nil
  local currentType = 1 -- even
  local typeRepeats = 0
  local resolutionRepeats = 0
  while isRunning do
    if type(note) == "nil" or getRandomBoolean(repeatProbability.value) == false then
      note = generateNote(note)
    end
    if type(currentResolutionIndex) == "nil" or getRandomBoolean(50) then -- TODO Param?
      currentResolutionIndex, currentType, typeRepeats, resolutionRepeats, storedDurations = getResolutionIndex(currentResolutionIndex, currentType, typeRepeats, resolutionRepeats, storedDurations)
    end
    local gate = randomizeValue(gateInput.value, gateInput.min, gateInput.max, gateRandomization.value)
    local duration = getResolution(currentResolutionIndex)
    playNote(note, 64, beat2ms(getPlayDuration(duration, gate)))
    waitBeat(duration)
  end
end

function onNote(e)
  table.insert(playingNotes, e.note)
  postEvent(e)
end

function onRelease(e)
  local index = getIndexFromValue(e.note, playingNotes)
  if type(index) == "number" then
    table.remove(playingNotes, index)
  end
  postEvent(e)
end

function onTransport(start)
  if start and isRunning == false then
    isRunning = true
    spawn(play)
  else
    isRunning = false
  end
end
