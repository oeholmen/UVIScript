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
label.text = "Random Change"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"
sourceIndex.width = 85

local probability = panel:NumBox("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that change will happen"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
probability.x = sourceIndex.x + sourceIndex.width + 10
probability.width = 100

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Duration"
waitResolution.tooltip = "The duration between changes"
waitResolution.selected = 20
waitResolution.showLabel = false
waitResolution.height = 20
waitResolution.width = 60
waitResolution.backgroundColour = widgetBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour
waitResolution.x = probability.x + probability.width + 10

local rampTime = panel:NumBox("RampTime", 0, 0, 100, true)
rampTime.unit = Unit.Percent
rampTime.displayName = "Smooth"
rampTime.tooltip = "Change transition time relative to the selected duration - Set 0 to get random amounts each round"
rampTime.textColour = widgetTextColour
rampTime.backgroundColour = widgetBackgroundColour
rampTime.x = waitResolution.x + waitResolution.width + 10
rampTime.width = 100

local bipolar = panel:NumBox("Bipolar", 50, 0, 100, true)
bipolar.unit = Unit.Percent
bipolar.displayName = "Bipolar"
bipolar.tooltip = "Set the probability that the returned value will be negative"
bipolar.textColour = widgetTextColour
bipolar.backgroundColour = widgetBackgroundColour
bipolar.x = rampTime.x + rampTime.width + 10
bipolar.width = 100

local legato = panel:OnOffButton("Legato", false)
legato.displayName = "Legato"
legato.backgroundColourOff = "#ff084486"
legato.backgroundColourOn = "#ff02ACFE"
legato.textColourOff = "#ff22FFFF"
legato.textColourOn = "#efFFFFFF"
legato.fillColour = "#dd000061"
legato.size = {75,22}
legato.x = bipolar.x + bipolar.width + 10
legato.y = 3

function hasVoiceId(voiceId)
  for _,v in ipairs(heldNotes) do
    if v == voiceId then
      return true
    end
  end
  return false
end

function doModulation(voiceId)
  local duration = getResolution(waitResolution.value)
  if getRandomBoolean(probability.value) then
    local val = getRandom()
    if getRandomBoolean(bipolar.value) then
      val = -val
    end
    local rampValue = rampTime.value / 100
    local rampDuration = beat2ms(duration) * rampValue
    sendScriptModulation(sourceIndex.value, val, rampDuration, voiceId)
  end
  waitBeat(duration)
end

function modulateVoice(voiceId)
  while hasVoiceId(voiceId) do
    doModulation(voiceId)
  end
end

function modulateBroadcast()
  while #heldNotes > 0 do
    doModulation()
  end
end

function onNote(e)
  local voiceId = postEvent(e)
  print("onNote voiceId", voiceId)
  table.insert(heldNotes, voiceId)
  if legato.value == true then
    if #heldNotes == 1 then
      modulateBroadcast()
    end
  else
    spawn(modulateVoice, voiceId)
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  print("onRelease voiceId", voiceId)
  for i,v in ipairs(heldNotes) do
    if v == voiceId then
      table.remove(heldNotes, i)
    end
  end
end
