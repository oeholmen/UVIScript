-------------------------------------------------------------------------------
-- A script modulator for a bouncing effect
-------------------------------------------------------------------------------

require "../includes/common"

local isRunning = false
local heldNotes = {}

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

local widgetWidth = 100

local panel = Panel("Bouncer")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 60

local label = panel:Label("Label")
label.text = "Bouncer"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 80

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Start Duration"
waitResolution.tooltip = "Start duration"
waitResolution.selected = 17
waitResolution.width = widgetWidth
waitResolution.x = label.x + label.width + 15
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local waitResolutionMin = panel:Menu("WaitResolutionMin", getResolutionNames())
waitResolutionMin.displayName = "Stop Duration"
waitResolutionMin.tooltip = "End duration"
waitResolutionMin.selected = 23
waitResolutionMin.width = widgetWidth
waitResolutionMin.x = waitResolution.x + waitResolution.width + 10
waitResolutionMin.backgroundColour = menuBackgroundColour
waitResolutionMin.textColour = widgetTextColour
waitResolutionMin.arrowColour = menuArrowColour
waitResolutionMin.outlineColour = menuOutlineColour

local rampTime = panel:NumBox("RampTime", 100, 0, 100, true)
rampTime.unit = Unit.Percent
rampTime.displayName = "Smooth"
rampTime.tooltip = "Transition time between bounces"
rampTime.textColour = widgetTextColour
rampTime.backgroundColour = widgetBackgroundColour
rampTime.y = 30
rampTime.x = waitResolutionMin.x + waitResolutionMin.width + 10
rampTime.width = widgetWidth
rampTime.height = 20

local probability = panel:NumBox("Probability", 100, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Probability of advancing to the next bounce"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
probability.y = rampTime.y
probability.x = rampTime.x + rampTime.width + 10
probability.width = widgetWidth
probability.height = 20

local bipolar = panel:OnOffButton("Bipolar", true)
bipolar.displayName = "Bipolar"
bipolar.backgroundColourOff = "#ff084486"
bipolar.backgroundColourOn = "#ff02ACFE"
bipolar.textColourOff = "#ff22FFFF"
bipolar.textColourOn = "#efFFFFFF"
bipolar.fillColour = "#dd000061"
bipolar.width = 60
bipolar.x = probability.x + probability.width + 10
bipolar.y = rampTime.y

local legato = panel:OnOffButton("Legato", false)
legato.displayName = "Legato"
legato.backgroundColourOff = "#ff084486"
legato.backgroundColourOn = "#ff02ACFE"
legato.textColourOff = "#ff22FFFF"
legato.textColourOn = "#efFFFFFF"
legato.fillColour = "#dd000061"
legato.size = {90,20}
legato.x = panel.width - legato.width
legato.y = rampTime.y

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"
sourceIndex.size = legato.size
sourceIndex.x = panel.width - sourceIndex.width

function getCurrentResolutionIndex(isRising)
  if isRising == true then
    return math.min(waitResolutionMin.value, waitResolution.value)
  else
    return math.max(waitResolutionMin.value, waitResolution.value)
  end
end

function getDuration(isRising, currentResolutionIndex)
  local minResolution = math.max(waitResolutionMin.value, waitResolution.value)
  local maxResolution = math.min(waitResolutionMin.value, waitResolution.value)
  local duration = getResolution(currentResolutionIndex)
  if getRandomBoolean(probability.value) == true then
    if isRising == true then
      currentResolutionIndex = currentResolutionIndex + 1
      if currentResolutionIndex > minResolution then
        currentResolutionIndex = minResolution
        isRising = false -- Stop if not loop
      end
    else
      currentResolutionIndex = currentResolutionIndex - 1
      if currentResolutionIndex < maxResolution then
        currentResolutionIndex = maxResolution
        isRising = true -- Stop if not loop
      end
    end
  end
  return duration, isRising, currentResolutionIndex
end

function doModulation(duration, voiceId)
  local rampValue = rampTime.value / 100
  local rampDuration = beat2ms(duration) * rampValue
  local high = 1
  local low = 0
  if bipolar.value == true then
    low = -1
  end
  sendScriptModulation(sourceIndex.value, high, rampDuration, voiceId)
  waitBeat(duration)
  sendScriptModulation(sourceIndex.value, low, rampDuration, voiceId)
  waitBeat(duration)
end

function hasVoiceId(voiceId)
  for _,v in ipairs(heldNotes) do
    if v == voiceId then
      return true
    end
  end
  return false
end

function modulateVoice(voiceId)
  local isRising = waitResolution.value < waitResolutionMin.value
  local currentResolutionIndex = getCurrentResolutionIndex(isRising)
  local duration = 0
  while hasVoiceId(voiceId) do
    duration, isRising, currentResolutionIndex = getDuration(isRising, currentResolutionIndex)
    doModulation(duration, voiceId)
  end
end

function modulateBroadcast()
  local isRising = waitResolution.value < waitResolutionMin.value
  local currentResolutionIndex = getCurrentResolutionIndex(isRising)
  local duration = 0
  while #heldNotes > 0 do
    duration, isRising, currentResolutionIndex = getDuration(isRising, currentResolutionIndex)
    doModulation(duration)
  end
end

function remove(voiceId)
  for i,v in ipairs(heldNotes) do
    if v == voiceId then
      table.remove(heldNotes, i)
    end
  end
end

function onNote(e)
  local voiceId = postEvent(e)
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
  remove(voiceId)
end
