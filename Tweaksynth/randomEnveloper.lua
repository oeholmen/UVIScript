-----------------------------------------------------------------------
-- A script modulator that creates random multi-envelopes over time.
-----------------------------------------------------------------------

require "subdivision"

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

local maxSteps = panel:NumBox("MaxSteps", 1, 1, 8, true)
maxSteps.displayName = "Max Steps"
maxSteps.tooltip = "Set the maximum number of steps that can be tied"
maxSteps.textColour = widgetTextColour
maxSteps.backgroundColour = widgetBackgroundColour
maxSteps.width = widgetWidth
maxSteps.x = 10
maxSteps.y = secondRowY

local minLevel = panel:NumBox("MinLevel", 50, 0, 100, true)
minLevel.unit = Unit.Percent
minLevel.displayName = "Spike Level"
minLevel.tooltip = "Set the minimum level for spikes"
minLevel.textColour = widgetTextColour
minLevel.backgroundColour = widgetBackgroundColour
minLevel.x = maxSteps.x + maxSteps.width + 10
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
  local minResolution = 0.25 -- 1/16 - The fastest accepted resolution -- TODO Parameter for this?
  local resolution = getResolution(waitResolution.value)
  local subdivisions = {{value=true}}
  local subdivision, subDivDuration, remainderDuration, stop = getSubdivision(resolution, 1, minResolution, rythm.value, subdivisions, false, 0)
  return subDivDuration
end

-- https://www.uvi.net/uviscript/class_mapper.html
-- Linear: param = min + (max-min)*pos 
-- Exponential: param = min * (max/min)^pos
-- Exponential: return 10 * (controllerValue/max)^4 (controllerValueToWidgetValue)
-- TweakSynth line 808
function modulateExponential(modulationTime, startValue, endValue, voiceId)
  local millisecondsPerStep = 20
  print("Duration of modulation (ms):", modulationTime)
  print("Change from/to:", startValue, endValue)
  if modulationTime <= (millisecondsPerStep*9) then
    print("Short duration, modulate linear:")
    modulateLinear(modulationTime, startValue, endValue, voiceId)
    return
  end

  local diff = math.max(endValue, startValue) - math.min(endValue, startValue)

  local parts = {
    {duration=0.5,startValue=startValue,endValue=diff*0.2},
    {duration=0.3,startValue=diff*0.2,endValue=diff*0.2+diff*0.3},
    {duration=0.3,startValue=diff*0.2+diff*0.3,endValue=endValue},
  }

  for i,v in ipairs(parts) do
    local remainingTime = modulationTime * v.duration
    local diff = math.max(v.endValue, v.startValue) - math.min(v.endValue, v.startValue)
    local numberOfSteps = remainingTime / millisecondsPerStep
    local changePerStep = diff / numberOfSteps
    print("i, diff, numberOfSteps, changePerStep", i, diff, numberOfSteps, changePerStep)
  
    local currentValue = v.startValue
    if v.startValue < v.endValue then
      while remainingTime > 0 do
        print("currentValue, endValue", currentValue, v.endValue)
        local change = changePerStep
        nextValue = math.min((currentValue + change), v.endValue)
        modulateLinear(millisecondsPerStep, currentValue, nextValue, voiceId)
        wait(millisecondsPerStep)
        currentValue = nextValue -- Increment current value
        if remainingTime - millisecondsPerStep <= 0 then
          modulateLinear(remainingTime, currentValue, v.endValue, voiceId)
        end
        remainingTime = remainingTime - millisecondsPerStep
      end
    else
      modulateLinear(modulationTime, v.startValue, v.endValue, voiceId)
    end
  end
end

function modulateLinear(modulationTime, startValue, endValue, voiceId)
  print("sendScriptModulation2 startValue, endValue, modulationTime", startValue, endValue, modulationTime)
  sendScriptModulation2(sourceIndex.value, startValue, endValue, modulationTime, voiceId)
end

function attackDecay(targetVal, stepDuration, voiceId)
  -- FIND ATTACK TIME
  local attackValue = attack.value
  if attackValue == 0 then
    attackValue = getRandom(3,30) -- TODO Parameter for this?
  end
  local attackTime = stepDuration * (attackValue / 100)
  if getRandomBoolean(100) then
    -- LINEAR
    modulateLinear(attackTime, 0, targetVal, voiceId)
  else
    -- EXPONENTIAL
    spawn(modulateExponential, attackTime, 0, targetVal, voiceId)
  end
  wait(attackTime)
  local restDuration = stepDuration - attackTime
  if restDuration > 1 then
    -- FIND DECAY TIME
    local decayValue = decay.value
    if decayValue == 0 then
      decayValue = getRandom(30,100) -- TODO Parameter for this?
    end
    local decayTime = restDuration * (decayValue / 100)
    modulateLinear(decayTime, targetVal, 0, voiceId)
  end
  wait(restDuration)
end

function doModulation(voiceId)
  local steps = 1
  if maxSteps.value > 1 then
    steps = getRandom(1,maxSteps.value)
  end
  local duration = beat2ms(getDuration()) * steps
  local val = 1 -- SPIKE LEVEL
  if minLevel.value < 100 then
    val = getRandom(math.max(1, minLevel.value), 100) / 100
  end
  if getRandomBoolean(bipolar.value) then
    val = -val
  end
  -- Do the attack/decay phase
  attackDecay(val, duration, voiceId)
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
