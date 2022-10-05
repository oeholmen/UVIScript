-------------------------------------------------------------------------------
-- Random note generator
-------------------------------------------------------------------------------

require "common"

local isRunning = false
local playingNotes = {} -- Keep track of incoming notes, to avoid dupicates

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"

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

--[[ local resolutionNames = {
  "32x", -- 1
  "16x", -- 2
  "8x", -- 3
  "7x", -- 4
  "6x", -- 5
  "5x", -- 6
  "4x", -- 7
  "3x", -- 8
  "2x", -- 9
  "1/1 dot", -- 10
  "1/1", -- 11
  "1/2 dot", -- 12
  "1/1 tri", -- 13
  "1/2", -- 14
  "1/4 dot", -- 15
  "1/2 tri", -- 16
  "1/4", -- 17
  "1/8 dot", -- 18
  "1/4 tri", -- 19
  "1/8", -- 20
  "1/16 dot", -- 21
  "1/8 tri", -- 22
  "1/16", -- 23
  "1/32 dot", -- 24
  "1/16 tri", -- 25
  "1/32", -- 26
  "1/64 dot", -- 27
  "1/32 tri", -- 28
  "1/64", -- 29
  "1/64 tri" -- 30
} ]]
-- TODO Auto generate fragments?
function getSelectedFragments()
  -- fragment = the resolutions
  -- p = probability if include
  -- r = repeat probability
  -- d = repeat probability decay
  local resolutionFragments = {
    {fragment={9},           p=9,   r=1,    d=100}, -- 2x
    {fragment={11},          p=12,  r=2,    d=100}, -- 1/1
    {fragment={14},          p=15,  r=3,    d=100}, -- 1/2
    {fragment={17},          p=21,  r=15,   d=50},  -- 1/4
    {fragment={20},          p=50,  r=100,  d=50},  -- 1/8
    {fragment={23},          p=100, r=100,  d=1},   -- 1/16
    {fragment={23,23,20},    p=100, r=100,  d=3},   -- 1/16 + 1/16 + 1/8
    {fragment={23,20,23},    p=100, r=100,  d=3},   -- 1/16 + 1/8 + 1/16
    {fragment={15,20},       p=100, r=100,  d=15},  -- 1/4 dot + 1/8
    {fragment={15,23,23},    p=100, r=100,  d=3},   -- 1/4 dot + 1/16 * 2
    {fragment={15,20,20},    p=100, r=100,  d=3},   -- 1/4 + 1/8 + 1/8
    {fragment={15,22,22,22}, p=30,  r=100,  d=3},   -- 1/4 + 1/8 tri * 3
    {fragment={22,22,22},    p=30,  r=90,   d=3},   -- 1/8 tri * 3
  }
  local selectedFragments = {}
  for _,v in ipairs(resolutionFragments) do
    if getRandomBoolean(v.p) then
      table.insert(selectedFragments, v)
    end
  end
  print("selectedFragments", #selectedFragments)
  if #selectedFragments == 0 then
    return resolutionFragments
  end
  return selectedFragments
end

function getFragment()
  return getRandomFromTable(getSelectedFragments())
end

function getResolutionIndex(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment)
  if type(activeFragment) == "nil" then
    activeFragment = getFragment()
    fragmentRepeatProbability = activeFragment.r
  end

  if (reverseFragment == false and fragmentPos == #activeFragment.fragment) or (reverseFragment and fragmentPos == 1) then
    -- END OF FRAGMENT
    if getRandomBoolean(fragmentRepeatProbability) then
      -- REPEAT FRAGMENT
      fragmentRepeatProbability = fragmentRepeatProbability - (fragmentRepeatProbability * (activeFragment.d / 100))
      print("REPEAT FRAGMENT, fragmentRepeatProbability", fragmentRepeatProbability)
    else
      -- CHANGE FRAGMENT
      activeFragment = getFragment()
      fragmentRepeatProbability = activeFragment.r
      print("CHANGE FRAGMENT, #fragment, fragmentRepeatProbability", #activeFragment.fragment, fragmentRepeatProbability)
    end
    -- REVERSE
    reverseFragment = getRandomBoolean() -- TODO Parameter or from fragment def?
    if reverseFragment then
      fragmentPos = #activeFragment.fragment
    else
      fragmentPos = 1
    end
    print("SET fragmentPos, reverseFragment", fragmentPos, reverseFragment)
  else
    -- INCREMENT FRAGMENT POS
    local increment = 1
    if reverseFragment then
      increment = -increment
    end
    fragmentPos = fragmentPos + increment
    print("INCREMENT FRAGMENT POS", fragmentPos)
  end

  print("RETURN resolutionIndex", activeFragment.fragment[fragmentPos])

  return activeFragment.fragment[fragmentPos], activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment
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
  local activeFragment = nil -- The fragment currently playing
  local fragmentPos = 0 -- Position in the active fragment
  local fragmentRepeatProbability = 0
  local currentResolutionIndex = nil
  local reverseFragment = false
  while isRunning do
    if type(note) == "nil" or getRandomBoolean(repeatProbability.value) == false then
      note = generateNote(note)
    end
    currentResolutionIndex, activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment = getResolutionIndex(activeFragment, fragmentPos, fragmentRepeatProbability, reverseFragment)
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
