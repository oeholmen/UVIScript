-------------------------------------------------------------------------------
-- Play note with a bouncing effect
-------------------------------------------------------------------------------

require "common"

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "66ff99" -- Light
local labelTextColour = "black"
local labelBackgoundColour = "F637EC"
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour
local knobFillColour = "E6D5B8" -- Light

setBackgroundColour(backgroundColour)

local widgetWidth = 110

local panel = Panel("Bouncer")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 60

local label = panel:Label("Label")
label.text = "Note Bouncer"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 120

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Start Duration"
waitResolution.tooltip = "Start duration"
waitResolution.selected = 17
waitResolution.width = widgetWidth / 1.5
waitResolution.x = label.x + label.width + 15
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local waitResolutionMin = panel:Menu("WaitResolutionMin", getResolutionNames())
waitResolutionMin.displayName = "Stop Duration"
waitResolutionMin.tooltip = "End duration"
waitResolutionMin.selected = 26
waitResolutionMin.width = widgetWidth / 1.5
waitResolutionMin.x = waitResolution.x + waitResolution.width + 10
waitResolutionMin.backgroundColour = menuBackgroundColour
waitResolutionMin.textColour = widgetTextColour
waitResolutionMin.arrowColour = menuArrowColour
waitResolutionMin.outlineColour = menuOutlineColour

local probability = panel:NumBox("Probability", 100, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Probability of bounce in incoming notes"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
probability.y = waitResolutionMin.y + 25
probability.x = waitResolutionMin.x + waitResolutionMin.width + 10
probability.width = widgetWidth
probability.height = 20

local noteRandomization = panel:NumBox("NoteRandomization", 0, 0, 100, true)
noteRandomization.unit = Unit.Percent
noteRandomization.textColour = widgetTextColour
noteRandomization.backgroundColour = widgetBackgroundColour
noteRandomization.displayName = "Note Move"
noteRandomization.tooltip = "Random note movement amount - a small amount gives small steps between notes"
noteRandomization.width = widgetWidth
noteRandomization.x = probability.x + probability.width + 10
noteRandomization.y = probability.y

local octaveRange = panel:NumBox("OctaveRange", 1, 1, 4, true)
octaveRange.textColour = widgetTextColour
octaveRange.backgroundColour = widgetBackgroundColour
octaveRange.displayName = "Octave"
octaveRange.tooltip = "Octave range for note movement"
octaveRange.width = widgetWidth / 1.5
octaveRange.x = noteRandomization.x + noteRandomization.width + 10
octaveRange.y = noteRandomization.y

local loop = panel:OnOffButton("Loop")
loop.displayName = "Loop"
loop.backgroundColourOff = "#ff084486"
loop.backgroundColourOn = "#ff02ACFE"
loop.textColourOff = "#ff22FFFF"
loop.textColourOn = "#efFFFFFF"
loop.fillColour = "#dd000061"
loop.width = widgetWidth / 2
loop.x = octaveRange.x + octaveRange.width + 10
loop.y = octaveRange.y

function getStartResolutionIndex()
  if waitResolution.value < waitResolutionMin.value then
    return math.min(waitResolutionMin.value, waitResolution.value)
  else
    return math.max(waitResolutionMin.value, waitResolution.value)
  end
end

function getDuration(isRising, currentResolutionIndex)
  local minResolution = math.max(waitResolutionMin.value, waitResolution.value)
  local maxResolution = math.min(waitResolutionMin.value, waitResolution.value)
  if isRising == true then
    currentResolutionIndex = currentResolutionIndex + 1
    if currentResolutionIndex > minResolution then
      currentResolutionIndex = minResolution
      isRising = false
    end
  else
    currentResolutionIndex = currentResolutionIndex - 1
    if currentResolutionIndex < maxResolution then
      currentResolutionIndex = maxResolution
      isRising = true
    end
  end
  return isRising, currentResolutionIndex
end

function generateNote(e)
  local note = e.note
  local range = octaveRange.value * 12
  local min = math.max(0, (note-range))
  local max = math.min(127, (note+range))
  return randomizeValue(note, min, max, noteRandomization.value)
end

function bounce(e)
  local isRising = waitResolution.value < waitResolutionMin.value
  local currentResolutionIndex = getStartResolutionIndex()
  local duration = getResolution(currentResolutionIndex)
  local note = e.note
  local round = 1
  while isKeyDown(e.note) do
    if round > 1 then
      note = generateNote(e)
    end
    local velocity = randomizeValue(e.velocity, 1, 127, 9)
    playNote(note, velocity, beat2ms(duration))
    waitBeat(duration)
    isRising, currentResolutionIndex = getDuration(isRising, currentResolutionIndex)
    if loop.value == false and (currentResolutionIndex == waitResolution.value or currentResolutionIndex == waitResolutionMin.value) then
      postEvent(e)
      break
    end
    duration = getResolution(currentResolutionIndex)
    round = round + 1
  end
end

function onNote(e)
  if getRandomBoolean(probability.value) then
    spawn(bounce, e)
  else
    postEvent(e)
  end
end
