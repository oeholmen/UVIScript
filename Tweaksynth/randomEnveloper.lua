-----------------------------------------------------------------------
-- A script modulator that creates random multi-envelopes over time.
-----------------------------------------------------------------------

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
local secondRowY = 40
local widgetWidth = 105

setBackgroundColour(backgroundColour)

local panel = Panel("Toggle")
panel.backgroundColour = backgroundColour
panel.x = 10
panel.y = 10
panel.width = 700
panel.height = 80

local label = panel:Label("Label")
label.text = "Random Enveloper"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.width = 165
label.x = 0
label.y = 0

local sourceIndex = panel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.backgroundColour = widgetBackgroundColour
sourceIndex.textColour = widgetTextColour
sourceIndex.displayName = "Event Id"
sourceIndex.width = 100
sourceIndex.x = label.x + label.width + 10
sourceIndex.y = 0

local waitResolution = panel:Menu("WaitResolution", getResolutionNames())
waitResolution.displayName = "Duration"
waitResolution.tooltip = "The duration between changes"
waitResolution.selected = 20
waitResolution.showLabel = false
waitResolution.height = 20
waitResolution.width = 75
waitResolution.backgroundColour = widgetBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour
waitResolution.x = sourceIndex.x + sourceIndex.width + 10
waitResolution.y = 0

local legato = panel:OnOffButton("Legato", false)
legato.displayName = "Legato"
legato.backgroundColourOff = "#ff084486"
legato.backgroundColourOn = "#ff02ACFE"
legato.textColourOff = "#ff22FFFF"
legato.textColourOn = "#efFFFFFF"
legato.fillColour = "#dd000061"
legato.width = 60
legato.x = panel.width - legato.width
legato.y = 0

local probability = panel:NumBox("Probability", 100, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that the step will trigger"
probability.textColour = widgetTextColour
probability.backgroundColour = widgetBackgroundColour
probability.width = widgetWidth
probability.x = 10
probability.y = secondRowY

local minLevel = panel:NumBox("MinLevel", 50, 0, 100, true)
minLevel.unit = Unit.Percent
minLevel.displayName = "Spike Level"
minLevel.tooltip = "Set the lowest level for spikes"
minLevel.textColour = widgetTextColour
minLevel.backgroundColour = widgetBackgroundColour
minLevel.x = probability.x + probability.width + 10
minLevel.y = secondRowY
minLevel.width = widgetWidth

local attack = panel:NumBox("Attack", 0, 0, 100, true)
attack.unit = Unit.Percent
attack.displayName = "Attack"
attack.tooltip = "Set attack as percentage of duration - 0 = random variation"
attack.textColour = widgetTextColour
attack.backgroundColour = widgetBackgroundColour
attack.x = minLevel.x + minLevel.width + 10
attack.y = secondRowY
attack.width = widgetWidth

local decay = panel:NumBox("Decay", 0, 0, 100, true)
decay.unit = Unit.Percent
decay.displayName = "Decay"
decay.tooltip = "Set decay as percentage of rest duration - 0 = random variation"
decay.textColour = widgetTextColour
decay.backgroundColour = widgetBackgroundColour
decay.x = attack.x + attack.width + 10
decay.y = secondRowY
decay.width = widgetWidth

local bipolar = panel:NumBox("Bipolar", 0, 0, 100, true)
bipolar.unit = Unit.Percent
bipolar.displayName = "Bipolar"
bipolar.tooltip = "Set the probability that the returned value will be negative"
bipolar.textColour = widgetTextColour
bipolar.backgroundColour = widgetBackgroundColour
bipolar.x = decay.x + decay.width + 10
bipolar.y = secondRowY
bipolar.width = widgetWidth

local rythm = panel:NumBox("Rythm", 0, 0, 100, true)
rythm.unit = Unit.Percent
rythm.displayName = "Rythm"
rythm.tooltip = "Set the probability that rythmic variation will occur"
rythm.textColour = widgetTextColour
rythm.backgroundColour = widgetBackgroundColour
rythm.x = bipolar.x + bipolar.width + 10
rythm.y = secondRowY
rythm.width = widgetWidth

function hasVoiceId(voiceId)
  for _,v in ipairs(heldNotes) do
    if v == voiceId then
      return true
    end
  end
  return false
end

function getDuration()
  local resolution = getResolution(waitResolution.value)
  if getRandomBoolean(rythm.value) then
    local subDivs = {.5,2,3,4} -- TODO Add param for this (rythmic variation)?
    return getPlayDuration(resolution / subDivs[getRandom(#subDivs)])
  end
  return resolution
end

function attackDecay(targetVal, attackDuration, stepDuration)
  sendScriptModulation2(sourceIndex.value, 0, targetVal, attackDuration, voiceId)
  wait(attackDuration)
  local restDuration = stepDuration - attackDuration
  if restDuration > 1 then
    local decayValue = decay.value / 100 -- ATTACK
    if decayValue == 0 then
      decayValue = getRandom()
    end
    local decayDuration = restDuration * decayValue
    --local decayDuration = getRandom(1, restDuration)
    print("stepDuration, attackDuration, restDuration, decayDuration", stepDuration, attackDuration, restDuration, decayDuration)
    sendScriptModulation2(sourceIndex.value, targetVal, 0, decayDuration, voiceId)
  end
end

function doModulation(voiceId)
  local duration = getDuration()
  if getRandomBoolean(probability.value) then
    local val = 1 -- SPIKE LEVEL
    if minLevel.value < 100 then
      val = getRandom(math.max(1, minLevel.value), 100) / 100
    end
    if getRandomBoolean(bipolar.value) then
      val = -val
    end
    local attackValue = attack.value / 100 -- ATTACK
    if attackValue == 0 then
      attackValue = getRandom() -- TODO Parameter for this?
    end
    local attackDuration = beat2ms(duration) * attackValue
    -- Send the attack
    run(attackDecay, val, attackDuration, beat2ms(duration))
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
  --print("onNote voiceId", voiceId)
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
  --print("onRelease voiceId", voiceId)
  for i,v in ipairs(heldNotes) do
    if v == voiceId then
      table.remove(heldNotes, i)
    end
  end
end
