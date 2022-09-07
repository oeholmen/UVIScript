-----------------------------------------------------------------------------------------
-- A script modulator that sends a random value at the given time, if probability hits.
-----------------------------------------------------------------------------------------

require "common"

local isRunning = false
local heldNotes = {}

local backgroundColour = "303030" -- Light or Dark
local widgetBackgroundColour = "01011F" -- Dark
local widgetTextColour = "FF9551" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local panel = Panel("Toggle")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 40

local label = panel:Label("Label")
label.text = "Random change"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"

local probability = panel:NumBox("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that change will happen"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
probability.x = sourceIndex.x + sourceIndex.width + 10

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Duration"
waitResolution.tooltip = "The duration between changes"
waitResolution.selected = 11
waitResolution.showLabel = false
waitResolution.height = 20
waitResolution.width = 75
waitResolution.backgroundColour = widgetBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour
waitResolution.x = probability.x + probability.width + 10

local rampTime = panel:NumBox("RampTime", 0, 0, 100, true)
rampTime.unit = Unit.Percent
rampTime.displayName = "Ramp Time"
rampTime.tooltip = "Change time relative to the selected duration"
rampTime.textColour = widgetTextColour
rampTime.backgroundColour = widgetBackgroundColour
rampTime.x = waitResolution.x + waitResolution.width + 10

local bipolar = panel:NumBox("Bipolar", 50, 0, 100, true)
bipolar.unit = Unit.Percent
bipolar.displayName = "Bipolar"
bipolar.tooltip = "Set the probability that the returned value will be negative"
bipolar.textColour = widgetTextColour
bipolar.backgroundColour = widgetBackgroundColour
bipolar.x = rampTime.x + rampTime.width + 10

function arpeg()
  while isRunning do
    local duration = getResolution(waitResolution.value)
    if getRandomBoolean(probability.value) then
      local val = getRandom()
      if getRandomBoolean(bipolar.value) then
        val = -val
      end
      local rampDuration = math.max(20, (beat2ms(duration) * (rampTime.value / 100)))
      sendScriptModulation(sourceIndex.value, val, rampDuration)
    end
    waitBeat(duration)
  end
end

function onNote(e)
  postEvent(e)
  table.insert(heldNotes, e)
  if #heldNotes == 1 and isRunning == false then
    isRunning = true
    arpeg()
  end
end

function onRelease(e)
  postEvent(e)
  for i,v in ipairs(heldNotes) do
    if v.note == e.note then
      table.remove(heldNotes, i)
    end
  end
  if #heldNotes == 0 then
    isRunning = false
  end
end
