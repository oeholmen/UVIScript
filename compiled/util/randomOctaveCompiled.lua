-- util/randomOctave -- 
--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------

local function getRandom(min, max, factor)
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

local function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  return getRandom(100) <= probability
end

local function getChangeMax(max, probabilityLevel)
  return math.ceil(max * (probabilityLevel / 100))
end

local function getIndexFromValue(value, selection)
  for i,v in ipairs(selection) do
    if v == value then
      return i
    end
  end
  return nil
end

local function randomizeValue(value, limitMin, limitMax, randomizationAmount)
  if randomizationAmount > 0 then
    local limitRange = limitMax - limitMin
    local changeMax = getChangeMax(limitRange, randomizationAmount)
    local min = math.max(limitMin, (value - changeMax))
    local max = math.min(limitMax, (value + changeMax))
    --print("Before randomize value", value)
    value = getRandom(min, max)
    --print("After randomize value/changeMax/min/max", value, changeMax, min, max)
  end
  return value
end

local function round(value)
  local int, frac = math.modf(value)
  --print("int/frac", int, frac)
  if math.abs(frac) < 0.5 then
    value = int
  elseif value < 0 then
    value = int - 1
  else
    value = int + 1
  end
  return value
end

local function tableIncludes(theTable, theItem)
  return type(getIndexFromValue(theItem, theTable)) == "number"
end

local function getRandomFromTable(theTable, except)
  if #theTable == 0 then
    return nil
  end
  if #theTable == 1 then
    return theTable[1]
  end
  local index = getRandom(#theTable)
  local value = theTable[index]
  --print("getRandomFromTable index, value", index, value)
  if type(except) ~= "nil" then
    local maxRounds = 10
    while value == except and maxRounds > 0 do
      value = theTable[getRandom(#theTable)]
      maxRounds = maxRounds - 1
      --print("getRandomFromTable except, maxRounds", except, maxRounds)
    end
  end
  return value
end

local function trimStartAndEnd(s)
  return s:match("^%s*(.-)%s*$")
end

local function inc(val, inc, max, reset)
  if type(inc) ~= "number" then
    inc = 1
  end
  if type(reset) ~= "number" then
    reset = 1
  end
  val = val + inc
  if type(max) == "number" and val > max then
    val = reset
  end
  return val
end

local gem = {
  inc = inc,
  round = round,
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getRandomBoolean = getRandomBoolean,
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
}

-------------------------------------------------------------------------------
-- Transpose incoming notes to octave
-------------------------------------------------------------------------------



local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F8B400"

setBackgroundColour(backgroundColour)

local widgetWidth = 110

local panel = Panel("Octave")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 36

local label = panel:Label("Label")
label.text = "Random octave"
label.tooltip = "Set a random octave within the given range on incoming notes"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 140

local probability = panel:NumBox("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Probability that incoming notes will be transposed"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
probability.y = label.y
probability.x = label.x + label.width + 50
probability.width = widgetWidth

local octaveRange = panel:NumBox("OctaveRange", 1, 1, 4, true)
octaveRange.textColour = widgetTextColour
octaveRange.backgroundColour = widgetBackgroundColour
octaveRange.displayName = "Octave"
octaveRange.tooltip = "Set the available range for octaves"
octaveRange.width = widgetWidth
octaveRange.x = probability.x + probability.width + 10
octaveRange.y = probability.y

local bipolar = panel:OnOffButton("Bipolar", true)
bipolar.displayName = "Bipolar"
bipolar.tooltip = "Use both positive and negative octave"
bipolar.backgroundColourOff = "#ff084486"
bipolar.backgroundColourOn = "#ff02ACFE"
bipolar.textColourOff = "#ff22FFFF"
bipolar.textColourOn = "#efFFFFFF"
bipolar.fillColour = "#dd000061"
bipolar.width = widgetWidth
bipolar.x = octaveRange.x + octaveRange.width + 10
bipolar.y = octaveRange.y

function setOctave(note)
  if gem.getRandomBoolean(probability.value) == false then
    print("Note was note transposed", note)
    return note
  end
  local octave = octaveRange.default
  if octaveRange.value > 1 then
    octave = gem.getRandom(octaveRange.value)
  end
  if bipolar.value and gem.getRandomBoolean() then
    octave = -octave
  end
  local transposedNote = note + (octave * 12)
  if transposedNote > 127 or transposedNote < 0 then
    print("Out of range, note, transposedNote", note, transposedNote)
    return note
  end
  print("Note was transposed, note, transposedNote, octave", note, transposedNote, octave)
  return transposedNote
end

function onNote(e)
  local note = setOctave(e.note)
  playNote(note, e.velocity)
end
