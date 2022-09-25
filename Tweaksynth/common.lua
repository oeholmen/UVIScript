--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------

local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}

function getNoteNames()
  return notenames
end

-- Used for mapping - does not include octave, only name of note (C, C#...)
function getNoteMapping()
  local noteNumberToNoteName = {}
  local notenamePos = 1
  for i=0,127 do
    table.insert(noteNumberToNoteName, notenames[notenamePos])
    notenamePos = notenamePos + 1
    if notenamePos > #notenames then
      notenamePos = 1
    end
  end
  return noteNumberToNoteName
end

function createScale(scaleDefinition, rootNote)
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
  --print("Scale contains notes:", #scale)
  return scale
end

function randomizeValue(value, limitMin, limitMax, randomizationAmount)
  if randomizationAmount > 0 then
    local changeMax = getChangeMax(limitMax, randomizationAmount)
    local min = value - changeMax
    local max = value + changeMax
    if min < limitMin then
      min = limitMin
    end
    if max > limitMax then
      max = limitMax
    end
    --print("Before randomize value", value)
    value = getRandom(min, max)
    --print("After randomize value/changeMax/min/max", value, changeMax, min, max)
  end
  return value
end

function getSemitonesBetweenNotes(note1, note2)
  return math.max(note1, note2) - math.min(note1, note1)
end

function getNoteAccordingToScale(scale, noteToPlay)
  for _,note in ipairs(scale) do
    if note == noteToPlay then
      return noteToPlay
    elseif note > noteToPlay then
      print("Change from noteToPlay to note", noteToPlay, note)
      return note
    end
  end
  return noteToPlay
end

function transpose(note, min, max)
  --print("Check transpose", note)
  if note < min then
    print("note < min", note, min)
    while note < min do
      note = note + 12
      print("transpose note up", note)
    end
  elseif note > max then
    print("note > max", note, max)
    while note > max do
      note = note - 12
      print("transpose note down", note)
    end
  end
  return note
end

function tableIncludes(theTable, theItem)
  for _,v in pairs(theTable) do
    if v == theItem then
      return true
    end
  end
  return false
end

function getIndexFromValue(value, selection)
  for i,v in ipairs(selection) do
    if v == value then
      return i
    end
  end
  return 1
end

function round(value)
  local int, frac = math.modf(value)
  print("int/frac", int, frac)
  if math.abs(frac) < 0.5 then
    value = int
  elseif value < 0 then
    value = int - 1
  else
    value = int + 1
  end
  return value
end

function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" and min < max then
    return math.random(min, max)
  elseif type(min) == "number" then
    return math.random(min)
  end
  local value = math.random()
  if type(factor) == "number" then
    value = value * factor
  end
  return value
end

function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  return getRandom(100) <= probability
end

function getChangeMax(max, probabilityLevel)
  return math.ceil(max * (probabilityLevel / 100))
end

function getDotted(value)
  return value * 1.5
end

function getTriplet(value)
  return value / 3
end

local resolutions = {
  128, -- "32x" -- 0
  64, -- "16x" -- 1
  32, -- "8x" -- 2
  28, -- "7x" -- 3
  24, -- "6x" -- 4
  20, -- "5x" -- 5
  16, -- "4x" -- 6
  12, -- "3x" -- 7
  8, -- "2x" -- 8
  6, -- "1/1 dot" -- 9
  4, -- "1/1" -- 10
  3, -- "1/2 dot" -- 11
  getTriplet(8), -- "1/1 tri" -- 12
  2, -- "1/2" -- 13
  getDotted(1), -- "1/4 dot", -- 14
  getTriplet(4), -- "1/2 tri", -- 15
  1, -- "1/4", -- 16
  getDotted(0.5), -- "1/8 dot", -- 17
  getTriplet(2), -- "1/4 tri", -- 18
  0.5,  -- "1/8", -- 19
  getDotted(0.25), -- "1/16 dot", -- 20
  getTriplet(1), -- "1/8 tri", -- 21
  0.25, -- "1/16", -- 22
  getDotted(0.125), -- "1/32 dot", -- 23
  getTriplet(0.5), -- "1/16 tri", -- 24
  0.125, -- "1/32" -- 25
  getDotted(0.0625), -- "1/64 dot", -- 26
  getTriplet(0.25), -- "1/32 tri", -- 27
  0.0625, -- "1/64", -- 28
  getTriplet(0.125) -- "1/64 tri" -- 29
}

local resolutionNames = {
  "32x", -- 0
  "16x", -- 1
  "8x", -- 2
  "7x", -- 3
  "6x", -- 4
  "5x", -- 5
  "4x", -- 6
  "3x", -- 7
  "2x", -- 8
  "1/1 dot", -- 9
  "1/1", -- 10
  "1/2 dot", -- 11
  "1/1 tri", -- 12 NY
  "1/2", -- 13
  "1/4 dot", -- 14
  "1/2 tri", -- 15
  "1/4", -- 16
  "1/8 dot", -- 17
  "1/4 tri", -- 18
  "1/8", -- 19
  "1/16 dot", -- 20
  "1/8 tri", -- 21
  "1/16", -- 22
  "1/32 dot", -- 23
  "1/16 tri", -- 24
  "1/32", -- 25
  "1/64 dot", -- 26
  "1/32 tri", -- 27
  "1/64", -- 28
  "1/64 tri" -- 29
}

function getResolution(i)
  return resolutions[i]
end

function getResolutions()
  return resolutions
end

function getResolutionName(i)
  return resolutionNames[i]
end

function getResolutionNames(options, max)
  if type(max) ~= "number" then
    max = #resolutionNames
  end

  local res = {}

  for _,r in ipairs(resolutionNames) do
    table.insert(res, r)
    if i == max then
      break
    end
  end

  -- Add any options
  if type(options) == "table" then
    for _,o in ipairs(options) do
      table.insert(res, o)
    end
  end

  return res
end

function getPlayDuration(duration, gate)
  if type(gate) == "nil" then
    gate = 100
  end
  local maxResolution = resolutions[#resolutions]
  return math.max(maxResolution, duration * (gate / 100)) -- Never shorter than the system max resolution (1/64 tri)
end
