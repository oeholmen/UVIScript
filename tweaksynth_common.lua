--------------------------------------------------------------------------------
-- Common functions and variables for tweak synth
--------------------------------------------------------------------------------

print("Starting Synth")

tweakables = {}
storedPatches = {}
storedPatch = {}
patchesMenu = nil -- Must be global so we can save patches from anywhere

--------------------------------------------------------------------------------
-- Synth engine elements
--------------------------------------------------------------------------------

-- KEYGROUPS
local osc1Keygroup = Program.layers[1].keygroups[1]
local osc2Keygroup = Program.layers[2].keygroups[1]
local noiseKeygroup = Program.layers[3].keygroups[1]

-- OSCILLATORS
osc1 = osc1Keygroup.oscillators[1]
osc2 = osc2Keygroup.oscillators[1]
noiseOsc = noiseKeygroup.oscillators[1]

-- MODULATORS
local vibratoLfo = Program.modulations["LFO 1"] -- Vibrato
local lfo1 = osc1Keygroup.modulations["LFO 1"] -- Modulation osc 1
local lfo2 = osc2Keygroup.modulations["LFO 1"] -- Modulation osc 2
local lfo3 = noiseKeygroup.modulations["LFO 1"] -- Modulation noise osc
local ampEnv1 = osc1Keygroup.modulations["Amp. Env"]
local ampEnv2 = osc2Keygroup.modulations["Amp. Env"]
local ampEnvNoise = noiseKeygroup.modulations["Amp. Env"]
local filterEnv1 = osc1Keygroup.modulations["Analog ADSR 1"]
local filterEnv2 = osc2Keygroup.modulations["Analog ADSR 1"]
local filterEnvNoise = noiseKeygroup.modulations["Analog ADSR 1"]

-- MACROS
macros = {
  Program.modulations["Macro 1"],
  Program.modulations["Macro 2"],
  Program.modulations["Macro 3"],
  Program.modulations["Macro 4"],
  Program.modulations["Macro 5"],
  Program.modulations["Macro 6"],
  Program.modulations["Macro 7"],
  Program.modulations["Macro 8"],
  Program.modulations["Macro 9"],
  Program.modulations["Macro 10"],
  Program.modulations["Macro 11"],
  Program.modulations["Macro 12"],
  Program.modulations["Macro 13"],
  Program.modulations["Macro 14"],
  Program.modulations["Macro 15"],
  Program.modulations["Macro 16"],
  Program.modulations["Macro 17"],
  Program.modulations["Macro 18"],
  Program.modulations["Macro 19"],
  Program.modulations["Macro 20"],
  Program.modulations["Macro 21"],
  Program.modulations["Macro 22"],
  Program.modulations["Macro 23"],
  Program.modulations["Macro 24"],
  Program.modulations["Macro 25"],
  Program.modulations["Macro 26"],
  Program.modulations["Macro 27"],
  Program.modulations["Macro 28"],
  Program.modulations["Macro 29"],
  Program.modulations["Macro 30"],
  Program.modulations["Macro 31"],
  Program.modulations["Macro 32"],
  Program.modulations["Macro 33"],
  Program.modulations["Macro 34"],
  Program.modulations["Macro 35"],
  Program.modulations["Macro 36"],
  Program.modulations["Macro 37"],
  Program.modulations["Macro 38"],
  Program.modulations["Macro 39"],
  Program.modulations["Macro 40"],
  Program.modulations["Macro 41"],
  Program.modulations["Macro 42"],
  Program.modulations["Macro 43"],
  Program.modulations["Macro 44"],
  Program.modulations["Macro 45"],
  Program.modulations["Macro 46"],
  Program.modulations["Macro 47"],
  Program.modulations["Macro 48"],
  Program.modulations["Macro 49"],
  Program.modulations["Macro 50"],
  Program.modulations["Macro 51"],
  Program.modulations["Macro 52"],
  Program.modulations["Macro 53"],
  Program.modulations["Macro 54"],
  Program.modulations["Macro 55"],
  Program.modulations["Macro 56"],
  Program.modulations["Macro 57"],
  Program.modulations["Macro 58"],
  Program.modulations["Macro 59"],
  Program.modulations["Macro 60"]
}

--------------------------------------------------------------------------------
-- Name common macros
--------------------------------------------------------------------------------

local filterCutoff = macros[2]
local filterEnvAmount = macros[3]
local lfoFreqKeyFollow2 = macros[4]
local lfoFreqKeyFollow3 = macros[5]
local lfoToDetune = macros[6]
local lfoToWaveSpread1 = macros[7]
local osc1Mix = macros[8]
local osc2Mix = macros[10]
local filterResonance = macros[13]
local delayMix = macros[14]
local reverbMix = macros[15]
local arpeggiator = macros[16]
local lfoToNoiseLpf = macros[18]
local lfoToNoiseHpf = macros[19]
local lfoToNoiseAmp = macros[20]
local chorusMix = macros[21]
local wheelToCutoff = macros[22]
local driveAmount = macros[23]
local atToCutoff = macros[24]
local vibratoAmount = macros[25]
local atToVibrato = macros[26]
local wheelToVibrato = macros[29]
local filterKeyTracking = macros[30]
local lfoToCutoff = macros[31]
local vibratoRate = macros[33]
local maximizer = macros[35]
local noiseMix = macros[36]
local lfoToAmp = macros[37]
local lfoFreqKeyFollow1 = macros[42]
local panSpread = macros[43]
local stereoSpread = macros[44]
local hpfCutoff = macros[50]
local hpfResonance = macros[51]
local hpfKeyTracking = macros[52]
local hpfEnvAmount = macros[53]
local wheelToHpf = macros[54]
local atToHpf = macros[55]
local lfoToHpf = macros[56]

--------------------------------------------------------------------------------
-- Colours and margins
--------------------------------------------------------------------------------

knobColour = "#333355"
osc1Colour = "orange"
osc2Colour = "yellow"
unisonColour = "magenta"
filterColour = "green"
lfoColour = "pink"
filterEnvColour = "red"
ampEnvColour = "teal"
filterEffectsColour = "blue"
vibratoColour = "lightblue"

marginX = 3 -- left/right
marginY = 2 -- top/bottom
height = 60
width = 713

--------------------------------------------------------------------------------
-- STORE / RECALL
--------------------------------------------------------------------------------

function onSave()
  local data = {}
  storedPatch = {} -- Store patch tweaks
  for i,v in ipairs(tweakables) do
    table.insert(storedPatch, {index=i,widget=v.widget.name,value=v.widget.value})
  end
  table.insert(data, storedPatch)
  if #storedPatches > 0 then
    -- Update the initial patch
    table.remove(storedPatches, 1)
    table.insert(storedPatches, 1, storedPatch)
    table.insert(data, storedPatches)
  end
  print("Data stored: ", #data)
  return data
end

function onLoad(data)
  print("Loading data", #data)
  storedPatch = data[1] -- USE FOR DEFAULT VALUES
  print("storedPatch", #storedPatch)
  for i,v in ipairs(storedPatch) do
    print("Loaded: ", v.widget, v.value)
  end
  if #data > 1 then
    storedPatches = data[2]
    populatePatchesMenu()
    print("Loaded stored patches: ", #storedPatches)
  end
end

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

function populatePatchesMenu()
  for i=1,#storedPatches do
    local itemName = "Snapshot "..i
    if i == 1 then
      itemName = itemName.." (stored)"
    end
    patchesMenu:addItem(itemName)
  end
end

function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" then
    local value = math.random(min, max)
    print("Random - value, min, max:", value, min, max)
    return value
  elseif type(min) == "number" then
    local value = math.random(min)
    print("Random - value, min:", value, min)
    return value
  end
  local value = math.random()
  print("Random:", value)
  if type(factor) == "number" then
    value = value * factor
    print("Random by factor:", value, factor)
  end
  return value
end

function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  local value = getRandom(100) <= probability
  print("RandomBoolean:", value, probability)
  return value
end

-- Takes a level of uncertanty and a probability to adjust according to the following rules:
-- The level of uncertanty is between 0 and 100 (0=no uncertanty,100=totaly random)
-- If uncertanty level is high, the probability gets lower
-- If uncertanty level is low, the probability gets higher
-- At uncertanty level 50, no change is made
-- Should return a probability between 0 and 100
function getProbabilityByTweakLevel(tweakLevel, probability)
  print("Probability/TweakLevel-in:", probability, tweakLevel)

  if probability == 100 or probability == 0 or tweakLevel == 50 then
    print("Probability is 100 or 0 or tweak level is 50:", probability)
    return probability
  end

  local factor = 0.5 - tweakLevel / 100
  probability = math.floor(probability + (factor * probability))

  print("Probability-factor:", factor)
  print("Probability-out:", probability)

  return probability
end

function tweakValue(options, value, tweakLevel)
  if type(options.widget.default) ~= "number" or options.noDefaultTweak == true then
    return value
  end
  print("Tweaking value")
  -- Get widget range
  local range = options.widget.max - options.widget.min
  if type(options.defaultTweakRange) == "number" then
    range = options.defaultTweakRange
  end
  print("Value range:", range)
  -- Determine change factor - a low tweaklevel gives a small change - high tweaklevel gives bigger change
  local factor = (0.5 * getRandom()) * ((tweakLevel * 1.5) / 100)
  print("Tweak factor:", factor)
  -- Set the range allowed for value adjustment
  local tweakRange = range * factor
  print("Tweakrange:", tweakRange)
  -- Check if value should be incemented or decremented
  local increment = value - tweakRange < options.widget.min
  local decrement = value + tweakRange > options.widget.max
  if increment then
    print("Incrementing to avoid out of range")
    value = value + tweakRange
  elseif decrement then
    print("Decrementing to avoid out of range")
    value = value - tweakRange
  elseif getRandomBoolean() == true then
    value = value + tweakRange
  else
    value = value - tweakRange
  end
  return value
end

function getValueForTweaking(options, tweakLevel, tweakSource)
  -- Tweak the value from the stored patch (the patch that was stored the last time user saved the program)
  if tweakSource == 2 or (tweakSource == 1 and getRandomBoolean(getProbabilityByTweakLevel(tweakLevel, 50)) == true) then
    for i,v in ipairs(storedPatch) do
      if v.widget == options.widget.name then
        print("Tweaking value from the last stored patch:", v.widget, v.value)
        return tweakValue(options, v.value, tweakLevel)
      end
    end
  end
  -- Or tweak the value from one of the stored patches
  if #storedPatches > 0 and (tweakSource == 3 or (tweakSource == 1 and getRandomBoolean(25) == true)) then
    local index = math.random(#storedPatches)
    for i,v in ipairs(storedPatches[index]) do
      if v.widget == options.widget.name then
        print("Tweaking value from patch:", index, v.widget, v.value)
        return tweakValue(options, v.value, tweakLevel)
      end
    end
  end
  -- Or tweak the current value
  if tweakSource == 4 or (tweakSource == 1 and getRandomBoolean(15) == true) then
    print("Tweaking the current value:", options.widget.value)
    return tweakValue(options, options.widget.value, tweakLevel)
  end
  -- Or tweak the default value
  local value = options.widget.default
  if tweakSource == 5 or (tweakSource == 1 and getRandomBoolean(getProbabilityByTweakLevel(tweakLevel, 25))) == true then
    print("Tweaking the default value:", value)
    return tweakValue(options, value, tweakLevel)
  end
  -- Or use the default value as is
  print("Using the default value without any tweaks:", value)
  return value
end

function getEnvelopeTimeForDuration(options, duration)
  local min = options.widget.default * 10000
  local max = duration * 1000 -- 0.25 = 1/16, 0.5 = 1/8, 1 = 1/4

  if min > max then
    return options.widget.default
  end

  print("Env value min/max:", min/10000, max/10000)

  return getRandom(min, max) / 10000
end

function getEnvelopeTimeByStyle(options, style)
  local index = style - 1
  local attackTimes = {{0.00025,0.0025},{0.001,0.0075},{0.005,0.025},{0.01,0.25},{0.1,0.75},{0.5,2},{1,3}}
  local releaseTimes = {{0.0025,0.01},{0.01,0.075},{0.05,0.125},{0.075,0.35},{0.1,0.75},{0.5,2},{1,3}}
  local min = attackTimes[index][1]
  local max = attackTimes[index][2]

  if options.release == true then
    min = releaseTimes[index][1]
    max = releaseTimes[index][2]
  end
  
  print("getEnvelopeTimeByStyle min/max:", min, max)
  
  return getRandom(min*100000, max*100000)/100000
end

-- Tweak options:
  -- widget = the widget to tweak - the only non-optional parameter
  -- func = the function to execute for getting the value - default is getRandom
  -- factor = a factor to multiply the random value with
  -- floor = the lowest value
  -- ceiling = the highest value
  -- probability = the probability (affected by tweak level) that value is within limits (floor/ceiling) - probability is passed to any custom func
  -- zero = the probability that the value is set to 0
  -- excludeWithDuration = if ran with a duration, this widget is excluded
  -- noDefaultTweak = do not tweak the default/stored value
  -- defaultTweakRange = the range to use when tweaking default/stored value - if not provided, the full range is used
  -- default = the probability that the default/stored value is used (affected by tweak level)
  -- min = min value
  -- max = max value
  -- absoluteLimit = the highest allowed limit - used mainly for safety resons to avoid extreme levels
  -- category = the category the widget belongs to (synthesis, modulation, filter, mixer, effects)
--
-- Example: table.insert(tweakables, {widget=driveKnob,floor=0,ceiling=0.5,probability=90,zero=50})
function tweakWidget(options, tweakLevel, duration, tweakSource, envelopeStyle)
  if type(tweakLevel) ~= "number" then
    tweakLevel = 50
  end
  if type(tweakSource) ~= "number" then
    tweakSource = 1
  end
  if type(envelopeStyle) ~= "number" then
    envelopeStyle = 1
  end
  print("Tweaking widget:", options.widget.name)
  print("Tweak level:", tweakLevel)
  local startValue = options.widget.value
  local endValue = startValue
  print("Start value:", startValue)
  if type(options.func) == "function" then
    endValue = options.func(options.probability)
    print("From func:", endValue, options.probability)
  elseif type(options.zero) == "number" and getRandomBoolean(getProbabilityByTweakLevel(tweakLevel, options.zero)) == true then
    -- Set to zero if probability hits
    endValue = 0
    print("Zero:", options.zero)
  elseif duration > 0 and (options.attack == true or options.release == true) then
    endValue = getEnvelopeTimeForDuration(options, duration)
    print("getEnvelopeTimeForDuration:", endValue)
  elseif envelopeStyle > 1 and (options.attack == true or options.release == true) then
    endValue = getEnvelopeTimeByStyle(options, envelopeStyle)
    print("getEnvelopeTimeByStyle:", endValue)
  elseif (tweakSource > 1 and duration > 0) or getRandomBoolean(tweakLevel/2) == false or (type(options.default) == "number" and getRandomBoolean(getProbabilityByTweakLevel(tweakLevel, options.default)) == true) then
    -- If tweak level is low, there is a high probability of stored/default value being used
    endValue = getValueForTweaking(options, tweakLevel, tweakSource)
    print("getValueForTweaking:", endValue)
  else
    -- Get a random value within min/max limit
    endValue = getRandom(options.min, options.max, options.factor)
    -- Adjust value to within range if probability hits
    if type(options.probability) == "number" and getRandomBoolean(getProbabilityByTweakLevel(tweakLevel, options.probability)) == true then
      local floor = options.widget.min -- Default floor is min
      local ceiling = options.widget.max -- Default ceiling is max
      if type(options.floor) == "number" then
        floor = options.floor
      end
      if type(options.ceiling) == "number" then
        ceiling = options.ceiling
      end
      -- Check values to avoid eternal loop
      if (ceiling - floor) < (options.widget.max / 100) then
        endValue = floor
        print("Value set to floor", floor)
      else
        print("Probability/floor/ceiling:", options.probability, floor, ceiling)
        -- Generate values until we hit the window
        local rounds = 0 -- Try ten times to get a value within the window
        while endValue < floor or endValue > ceiling do
          if rounds > 10 then
            break
          end
          endValue = getRandom(options.min, options.max, options.factor)
          rounds = rounds + 1 -- Increment rounds
        end
      end
    end
    if type(options.bipolar) == "number" and getRandomBoolean(getProbabilityByTweakLevel(tweakLevel, options.bipolar)) == true then
      if getRandom(100) <= options.bipolar then
        endValue = -endValue
        print("Value converted to negative", options.bipolar)
      end
    end
  end
  if type(options.absoluteLimit) == "number" and type(endValue) == "number" and endValue > options.absoluteLimit then
    print("End value limited by absoluteLimit", options.absoluteLimit)
    endValue = options.absoluteLimit
  end
  -- If called without duration, type is not number, or value is unchanged, the value is updated, and function returns
  if duration == 0 or type(duration) ~= "number" or startValue == endValue or type(endValue) ~= "number" then
    options.widget.value = endValue
    print("No duration, not number or unchanged value:", endValue)
    return
  end
  local durationInMilliseconds = beat2ms(duration) * 0.9
  local millisecondsPerStep = 25
  print("Duration of change (beat):", duration)
  print("Duration of change (ms):", durationInMilliseconds)
  print("Change from/to:", startValue, endValue)
  -- diff / durationInMilliseconds
  local diff = math.max(endValue, startValue) - math.min(endValue, startValue)
  local numberOfSteps = durationInMilliseconds / millisecondsPerStep
  local changePerStep = diff / numberOfSteps
  print("Number of steps:", numberOfSteps)
  if durationInMilliseconds <= millisecondsPerStep then
    options.widget.value = endValue
    print("Short duration, skip steps:", endValue)
    return
  end
  if startValue < endValue then
    print("Increment per step:", changePerStep)
    for i = 1, numberOfSteps-1 do
      options.widget.value = options.widget.value + changePerStep
      wait(millisecondsPerStep)
    end
  else
    print("Decrement per step:", changePerStep)
    for i = 1, numberOfSteps-1 do
      options.widget.value = options.widget.value - changePerStep
      wait(millisecondsPerStep)
    end
  end
  options.widget.value = endValue
end

function getDotted(value)
  return value + (value / 2)
end

function getTriplet(value)
  return value  / 3
end

local tweakSources = {"Automatic", "Saved patch", "Stored snapshots", "Current edit", "Default value"}
local resolutions =     { 32,   24,   16,  12,    8,     6,         4,      3,       2, getTriplet(4), getDotted(1), 1, getTriplet(2), getDotted(0.5), 0.5, getTriplet(1), getDotted(0.25), 0.25,  getTriplet(0.5), getDotted(0.125), 0.125}
local resolutionNames = {"8x", "6x", "4x", "3x", "2x", "1/1 dot", "1/1", "1/2 dot", "1/2", "1/2 tri", "1/4 dot",   "1/4", "1/4 tri",   "1/8 dot",     "1/8", "1/8 tri",    "1/16 dot",      "1/16", "1/16 tri",     "1/32 dot",      "1/32"}

function getResolution(i)
  return resolutions[i]
end

function getResolutions()
  return resolutions
end

function getResolutionName(i)
  return resolutionNames[i]
end

function getResolutionNames()
  return resolutionNames
end

function formatTimeInSeconds(value)
  if value < 0.01 then
      return string.format("%0.2f ms", value*1000)
  elseif value < 0.1 then
      return string.format("%0.1f ms", value*1000)
  elseif value < 1 then
      return string.format("%0.0f ms", value*1000)
  else
      return string.format("%0.2f s", value)
  end
end

function formatGainInDb(value)
  if value == 0 then
      return "-inf"
  else
      local dB = 20 * math.log10(value)
      return string.format("%0.1f dB", dB)
  end
end

function isEqual(value1, value2)
  if type(value1) == "number" then
    value1 = string.format("%0.3f", value1)
  end
  if type(value2) == "number" then
    value2 = string.format("%0.3f", value2)
  end
  return value1 == value2
end

function percent(value)
  return string.format("%0.1f %%", (value * 100))
end

function getSyncedValue(value)
  for key, res in pairs(resolutions) do
    print(key, " -- ", res)
    if isEqual(res, value) then
      print(res, "==", value)
      return key - 1
    end
  end
  return 11
end

-- Logarithmic mapping for filter cutoff
-- Filter Max => 20000.
-- Filter Min => 20.
local filterlogmax = math.log(20000.)
local filterlogmin = math.log(20.)
local filterlogrange = filterlogmax-filterlogmin
function filterMapValue(value)
    local newValue = (value * filterlogrange) + filterlogmin
    value = math.exp(newValue)
    return value
end

--------------------------------------------------------------------------------
-- Common Panels
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Mixer Panel
--------------------------------------------------------------------------------

function createMixerPanel()
  local mixerPanel = Panel("Mixer")

  mixerPanel:Label("Mixer")

  local osc1MixKnob = mixerPanel:Knob("Osc1Mix", 0.75, 0, 1)
  osc1MixKnob.displayName = "Osc 1"
  osc1MixKnob.fillColour = knobColour
  osc1MixKnob.outlineColour = osc1Colour
  osc1MixKnob.changed = function(self)
    osc1Mix:setParameter("Value", self.value)
    self.displayText = formatGainInDb(self.value)
  end
  osc1MixKnob:changed()
  table.insert(tweakables, {widget=osc1MixKnob,floor=0.3,ceiling=0.75,probability=100,absoluteLimit=0.8,default=50,category="mixer"})

  local osc2MixKnob = mixerPanel:Knob("Osc2Mix", 0, 0, 1)
  osc2MixKnob.displayName = "Osc 2"
  osc2MixKnob.fillColour = knobColour
  osc2MixKnob.outlineColour = osc2Colour
  osc2MixKnob.changed = function(self)
    osc2Mix:setParameter("Value", self.value)
    self.displayText = formatGainInDb(self.value)
  end
  osc2MixKnob:changed()
  table.insert(tweakables, {widget=osc2MixKnob,floor=0.3,ceiling=0.75,probability=100,absoluteLimit=0.8,category="mixer"})

  local noiseMixKnob = mixerPanel:Knob("NoiseMix", 0, 0, 1)
  noiseMixKnob.displayName = "Noise"
  noiseMixKnob.fillColour = knobColour
  noiseMixKnob.outlineColour = osc2Colour
  noiseMixKnob.changed = function(self)
    noiseMix:setParameter("Value", self.value)
    self.displayText = formatGainInDb(self.value)
  end
  noiseMixKnob:changed()
  table.insert(tweakables, {widget=noiseMixKnob,floor=0.3,ceiling=0.75,probability=100,default=10,absoluteLimit=0.8,category="mixer"})

  local noiseTypes = {"Band", "S&H", "Static1", "Static2", "Violet", "Blue", "White", "Pink", "Brown", "Lorenz", "Rossler", "Crackle", "Logistic", "Dust", "Velvet"}
  local noiseTypeMenu = mixerPanel:Menu("NoiseTypeMenu", noiseTypes)
  noiseTypeMenu.displayName = "Noise Type"
  noiseTypeMenu.selected = 7
  noiseTypeMenu.changed = function(self)
    local value = self.value - 1
    noiseOsc:setParameter("NoiseType", value)
  end
  noiseTypeMenu:changed()
  table.insert(tweakables, {widget=noiseTypeMenu,min=#noiseTypes,category="synthesis"})

  local arpeggiatorButton = mixerPanel:OnOffButton("Arp", false)
  arpeggiatorButton.fillColour = knobColour
  arpeggiatorButton.outlineColour = filterEfectsColour
  arpeggiatorButton.size = {100,(height-15)}
  arpeggiatorButton.changed = function(self)
    local value = -1
    if (self.value == true) then
      value = 1
    end
    arpeggiator:setParameter("Value", value)
  end
  arpeggiatorButton:changed()

  return mixerPanel
end

--------------------------------------------------------------------------------
-- Effects Panel
--------------------------------------------------------------------------------

function createEffectsPanel()
  local effectsPanel = Panel("EffectsPanel")

  effectsPanel:Label("Effects")

  local reverbKnob = effectsPanel:Knob("Reverb", 0, 0, 1)
  reverbKnob.mapper = Mapper.Quadratic
  reverbKnob.fillColour = knobColour
  reverbKnob.outlineColour = filterEffectsColour
  reverbKnob.changed = function(self)
    reverbMix:setParameter("Value", self.value)
  end
  reverbKnob:changed()
  table.insert(tweakables, {widget=reverbKnob,floor=0.1,ceiling=0.6,probability=100,category="effects"})

  local delayKnob = effectsPanel:Knob("Delay", 0, 0, 1)
  delayKnob.mapper = Mapper.Cubic
  delayKnob.fillColour = knobColour
  delayKnob.outlineColour = filterEffectsColour
  delayKnob.changed = function(self)
    delayMix:setParameter("Value", self.value)
  end
  delayKnob:changed()
  table.insert(tweakables, {widget=delayKnob,floor=0.01,ceiling=0.6,probability=100,category="effects"})

  local chorusKnob = effectsPanel:Knob("Chorus", 0, 0, 1)
  chorusKnob.mapper = Mapper.Linear
  chorusKnob.fillColour = knobColour
  chorusKnob.outlineColour = filterEffectsColour
  chorusKnob.changed = function(self)
    chorusMix:setParameter("Value", self.value)
  end
  chorusKnob:changed()
  table.insert(tweakables, {widget=chorusKnob,floor=0.01,ceiling=0.5,probability=60,default=50,category="effects"})

  local driveKnob = effectsPanel:Knob("Drive", 0, 0, 1)
  driveKnob.mapper = Mapper.Cubic
  driveKnob.fillColour = knobColour
  driveKnob.outlineColour = filterEffectsColour
  driveKnob.changed = function(self)
    driveAmount:setParameter("Value", self.value)
  end
  driveKnob:changed()
  table.insert(tweakables, {widget=driveKnob,ceiling=0.4,probability=90,absoluteLimit=0.6,default=50,category="effects"})

  local maximizerButton = effectsPanel:OnOffButton("Maximizer", false)
  maximizerButton.fillColour = knobColour
  maximizerButton.outlineColour = filterEffectsColour
  maximizerButton.size = {100,(height-15)}
  maximizerButton.changed = function(self)
    local value = -1
    if (self.value == true) then
      value = 1
    end
    maximizer:setParameter("Value", value)
  end
  maximizerButton:changed()
  table.insert(tweakables, {widget=maximizerButton,func=getRandomBoolean,probability=10,excludeWithDuration=true,category="effects"})

  return effectsPanel
end

--------------------------------------------------------------------------------
-- Vibrato Panel
--------------------------------------------------------------------------------

function createVibratoPanel()
  local vibratoPanel = Panel("VibratoPanel")

  vibratoPanel:Label("Vibrato")

  local vibratoKnob = vibratoPanel:Knob("VibratoDepth", 0, 0, 1)
  vibratoKnob.displayName="Depth"
  vibratoKnob.fillColour = knobColour
  vibratoKnob.outlineColour = vibratoColour
  vibratoKnob.changed = function(self)
    vibratoAmount:setParameter("Value", self.value)
  end
  vibratoKnob:changed()
  table.insert(tweakables, {widget=vibratoKnob,ceiling=0.5,probability=60,category="synthesis"})

  local vibratoRateKnob = vibratoPanel:Knob("VibratoRate", 0.7, 0, 1)
  vibratoRateKnob.displayName="Rate"
  vibratoRateKnob.fillColour = knobColour
  vibratoRateKnob.outlineColour = vibratoColour
  vibratoRateKnob.changed = function(self)
    vibratoRate:setParameter("Value", self.value)
    if self.value < 0.2 then
      self.displayText = "Very slow"
    elseif self.value < 0.5 then
      self.displayText = "Slow"
    elseif self.value < 0.75 then
      self.displayText = "Medium"
    elseif self.value < 0.85 then
      self.displayText = "Fast"
    else
      self.displayText = "Very fast"
    end
  end
  vibratoRateKnob:changed()
  table.insert(tweakables, {widget=vibratoRateKnob,default=50,category="synthesis"})

  local vibratoRiseKnob = vibratoPanel:Knob("LfoRiseTime", 0, 0, 10)
  vibratoRiseKnob.displayName="Rise Time"
  vibratoRiseKnob.fillColour = knobColour
  vibratoRiseKnob.outlineColour = vibratoColour
  vibratoRiseKnob.mapper = Mapper.Quartic
  vibratoRiseKnob.changed = function(self)
    vibratoLfo:setParameter("RiseTime", self.value)
    self.displayText = formatTimeInSeconds(self.value)
  end
  vibratoRiseKnob:changed()
  table.insert(tweakables, {widget=vibratoRiseKnob,factor=5,default=50,category="synthesis"})

  local wheelToVibratoKnob = vibratoPanel:Knob("WheelToVibrato", 0, 0, 1)
  wheelToVibratoKnob.displayName="Modwheel"
  wheelToVibratoKnob.fillColour = knobColour
  wheelToVibratoKnob.outlineColour = vibratoColour
  wheelToVibratoKnob.changed = function(self)
    wheelToVibrato:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  wheelToVibratoKnob:changed()
  table.insert(tweakables, {widget=wheelToVibratoKnob,excludeWithDuration=true,category="synthesis"})

  local atToVibratoKnob = vibratoPanel:Knob("AftertouchToVibrato", 0, 0, 1)
  atToVibratoKnob.displayName="Aftertouch"
  atToVibratoKnob.fillColour = knobColour
  atToVibratoKnob.outlineColour = vibratoColour
  atToVibratoKnob.changed = function(self)
    atToVibrato:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  atToVibratoKnob:changed()
  table.insert(tweakables, {widget=atToVibratoKnob,excludeWithDuration=true,category="synthesis"})

  return vibratoPanel
end

--------------------------------------------------------------------------------
-- Filter Panels
--------------------------------------------------------------------------------

function createFilterPanel()  
  local filterPanel = Panel("Filter")

  filterPanel:Label("Low-pass Filter")

  local cutoffKnob = filterPanel:Knob("Cutoff", 1, 0, 1)
  cutoffKnob.fillColour = knobColour
  cutoffKnob.outlineColour = filterColour
  cutoffKnob.changed = function(self)
    filterCutoff:setParameter("Value", self.value)
    local value = filterMapValue(self.value)
    if value < 1000 then
        self.displayText = string.format("%0.1f Hz", value)
    else
        self.displayText = string.format("%0.1f kHz", value/1000.)
    end
  end
  cutoffKnob:changed()
  table.insert(tweakables, {widget=cutoffKnob,floor=0.3,ceiling=0.8,probability=75,zero=10,default=35,category="filter"})

  local filterResonanceKnob = filterPanel:Knob("Resonance", 0, 0, 1)
  filterResonanceKnob.fillColour = knobColour
  filterResonanceKnob.outlineColour = filterColour
  filterResonanceKnob.changed = function(self)
    filterResonance:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  filterResonanceKnob:changed()
  table.insert(tweakables, {widget=filterResonanceKnob,floor=0.1,ceiling=0.6,probability=10,default=30,zero=10,absoluteLimit=0.8,category="filter"})

  local filterKeyTrackingKnob = filterPanel:Knob("KeyTracking", 0, 0, 1)
  filterKeyTrackingKnob.displayName = "Key Track"
  filterKeyTrackingKnob.fillColour = knobColour
  filterKeyTrackingKnob.outlineColour = filterColour
  filterKeyTrackingKnob.changed = function(self)
    filterKeyTracking:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  filterKeyTrackingKnob:changed()
  table.insert(tweakables, {widget=filterKeyTrackingKnob,default=40,zero=50,category="filter"})

  local wheelToCutoffKnob = filterPanel:Knob("WheelToCutoff", 0, -1, 1)
  wheelToCutoffKnob.displayName = "Modwheel"
  wheelToCutoffKnob.fillColour = knobColour
  wheelToCutoffKnob.outlineColour = filterColour
  wheelToCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    wheelToCutoff:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  wheelToCutoffKnob:changed()
  table.insert(tweakables, {widget=wheelToCutoffKnob,bipolar=25,excludeWithDuration=true,category="filter"})

  local atToCutoffKnob = filterPanel:Knob("AftertouchToCutoff", 0, -1, 1)
  atToCutoffKnob.displayName = "Aftertouch"
  atToCutoffKnob.fillColour = knobColour
  atToCutoffKnob.outlineColour = filterColour
  atToCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    atToCutoff:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  atToCutoffKnob:changed()
  table.insert(tweakables, {widget=atToCutoffKnob,bipolar=25,excludeWithDuration=true,category="filter"})

  return filterPanel
end

function createHpFilterPanel()
  local hpFilterPanel = Panel("HPFilter")

  hpFilterPanel:Label("High-pass Filter")

  local hpfCutoffKnob = hpFilterPanel:Knob("HPCutoff", 0, 0, 1)
  hpfCutoffKnob.displayName = "Cutoff"
  hpfCutoffKnob.fillColour = knobColour
  hpfCutoffKnob.outlineColour = filterColour
  hpfCutoffKnob.changed = function(self)
    hpfCutoff:setParameter("Value", self.value)
    local value = filterMapValue(self.value)
    if value < 1000 then
        self.displayText = string.format("%0.1f Hz", value)
    else
        self.displayText = string.format("%0.1f kHz", value/1000.)
    end
  end
  hpfCutoffKnob:changed()
  table.insert(tweakables, {widget=hpfCutoffKnob,ceiling=0.5,probability=60,zero=60,category="filter"})

  local hpfResonanceKnob = hpFilterPanel:Knob("HPFResonance", 0, 0, 1)
  hpfResonanceKnob.displayName = "Resonance"
  hpfResonanceKnob.fillColour = knobColour
  hpfResonanceKnob.outlineColour = filterColour
  hpfResonanceKnob.changed = function(self)
    hpfResonance:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  hpfResonanceKnob:changed()
  table.insert(tweakables, {widget=hpfResonanceKnob,ceiling=0.5,probability=75,absoluteLimit=0.8,default=50,category="filter"})

  local hpfKeyTrackingKnob = hpFilterPanel:Knob("HPFKeyTracking", 0, 0, 1)
  hpfKeyTrackingKnob.displayName = "Key Track"
  hpfKeyTrackingKnob.fillColour = knobColour
  hpfKeyTrackingKnob.outlineColour = filterColour
  hpfKeyTrackingKnob.changed = function(self)
    hpfKeyTracking:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  hpfKeyTrackingKnob:changed()
  table.insert(tweakables, {widget=hpfKeyTrackingKnob,category="filter"})

  local wheelToHpfCutoffKnob = hpFilterPanel:Knob("WheelToHpfCutoff", 0, -1, 1)
  wheelToHpfCutoffKnob.displayName = "Modwheel"
  wheelToHpfCutoffKnob.fillColour = knobColour
  wheelToHpfCutoffKnob.outlineColour = filterColour
  wheelToHpfCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    wheelToHpf:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  wheelToHpfCutoffKnob:changed()
  table.insert(tweakables, {widget=wheelToHpfCutoffKnob,bipolar=25,excludeWithDuration=true,category="filter"})

  local atToHpfCutoffKnob = hpFilterPanel:Knob("AftertouchToHpfCutoff", 0, -1, 1)
  atToHpfCutoffKnob.displayName = "Aftertouch"
  atToHpfCutoffKnob.fillColour = knobColour
  atToHpfCutoffKnob.outlineColour = filterColour
  atToHpfCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    atToHpf:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  atToHpfCutoffKnob:changed()
  table.insert(tweakables, {widget=atToHpfCutoffKnob,bipolar=25,excludeWithDuration=true,category="filter"})

  return hpFilterPanel
end

function createFilterEnvPanel()
  local filterEnvPanel = Panel("FilterEnv")

  local activeFilterEnvOsc = 1
  local filterEnvMenu = filterEnvPanel:Menu("FilterEnvOsc", {"All", "Osc 1", "Osc 2", "Noise Osc"})
  filterEnvMenu.displayName = "Filter Envelope"

  local filterAttackKnob = filterEnvPanel:Knob("FAttack", 0.001, 0, 10)
  filterAttackKnob.displayName="Attack"
  filterAttackKnob.fillColour = knobColour
  filterAttackKnob.outlineColour = filterEnvColour
  filterAttackKnob.mapper = Mapper.Quartic
  filterAttackKnob.changed = function(self)
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 2 then
      filterEnv1:setParameter("AttackTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      filterEnv2:setParameter("AttackTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      filterEnvNoise:setParameter("AttackTime", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  filterAttackKnob:changed()
  table.insert(tweakables, {widget=filterAttackKnob,attack=true,floor=0.001,ceiling=0.01,probability=85,default=35,defaultTweakRange=3,category="filter"})

  local filterDecayKnob = filterEnvPanel:Knob("FDecay", 0.050, 0, 10)
  filterDecayKnob.displayName="Decay"
  filterDecayKnob.fillColour = knobColour
  filterDecayKnob.outlineColour = filterEnvColour
  filterDecayKnob.mapper = Mapper.Quartic
  filterDecayKnob.changed = function(self)
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 2 then
      filterEnv1:setParameter("DecayTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      filterEnv2:setParameter("DecayTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      filterEnvNoise:setParameter("DecayTime", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  filterDecayKnob:changed()
  table.insert(tweakables, {widget=filterDecayKnob,factor=3,floor=0.01,ceiling=0.5,probability=50,default=25,category="filter"})

  local filterSustainKnob = filterEnvPanel:Knob("FSustain", 1, 0, 1)
  filterSustainKnob.displayName="Sustain"
  filterSustainKnob.fillColour = knobColour
  filterSustainKnob.outlineColour = filterEnvColour
  filterSustainKnob.changed = function(self)
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 2 then
      filterEnv1:setParameter("SustainLevel", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      filterEnv2:setParameter("SustainLevel", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      filterEnvNoise:setParameter("SustainLevel", self.value)
    end
    self.displayText = percent(self.value)
  end
  filterSustainKnob:changed()
  table.insert(tweakables, {widget=filterSustainKnob,floor=0.1,ceil=0.9,probability=90,default=12,zero=2,category="filter"})

  local filterReleaseKnob = filterEnvPanel:Knob("FRelease", 0.010, 0, 10)
  filterReleaseKnob.displayName="Release"
  filterReleaseKnob.fillColour = knobColour
  filterReleaseKnob.outlineColour = filterEnvColour
  filterReleaseKnob.mapper = Mapper.Quartic
  filterReleaseKnob.changed = function(self)
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 2 then
      filterEnv1:setParameter("ReleaseTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      filterEnv2:setParameter("ReleaseTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      filterEnvNoise:setParameter("ReleaseTime", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  filterReleaseKnob:changed()
  table.insert(tweakables, {widget=filterReleaseKnob,release=true,factor=5,floor=0.01,ceiling=0.8,probability=70,default=35,defaultTweakRange=5,category="filter"})

  local filterVelocityKnob = filterEnvPanel:Knob("VelocityToFilterEnv", 10, 0, 40)
  filterVelocityKnob.displayName="Velocity"
  filterVelocityKnob.fillColour = knobColour
  filterVelocityKnob.outlineColour = filterEnvColour
  filterVelocityKnob.changed = function(self)
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 2 then
      filterEnv1:setParameter("DynamicRange", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      filterEnv2:setParameter("DynamicRange", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      filterEnvNoise:setParameter("DynamicRange", self.value)
    end
  end
  filterVelocityKnob:changed()
  table.insert(tweakables, {widget=filterVelocityKnob,min=40,category="filter"})

  function setFilterEnvKnob(knob, param)
    if activeFilterEnvOsc == 1 then
      knob.enabled = isEqual(filterEnv1:getParameter(param), filterEnv2:getParameter(param)) and isEqual(filterEnv2:getParameter(param), filterEnvNoise:getParameter(param))
      return
    end
    local value
    if activeFilterEnvOsc == 2 then
      value = filterEnv1:getParameter(param)
    elseif activeFilterEnvOsc == 3 then
      value = filterEnv2:getParameter(param)
    elseif activeFilterEnvOsc == 4 then
      value = filterEnvNoise:getParameter(param)
    end
    knob:setValue(value)
    print("setFilterEnvKnob:setValue:", param, value)
    knob.enabled = true
  end

  filterEnvMenu.changed = function(self)
    -- STORE ACTIVE OSCILLATOR
    activeFilterEnvOsc = self.value
    -- SET KNOB VALUES
    setFilterEnvKnob(filterAttackKnob, "AttackTime")
    setFilterEnvKnob(filterDecayKnob, "DecayTime")
    setFilterEnvKnob(filterSustainKnob, "SustainLevel")
    setFilterEnvKnob(filterReleaseKnob, "ReleaseTime")
    setFilterEnvKnob(filterVelocityKnob, "DynamicRange")
  end
  filterEnvMenu:changed()

  return filterEnvPanel
end

function createFilterEnvTargetsPanel()
  local filterEnvTargetsPanel = Panel("FilterEnvTargets")

  filterEnvTargetsPanel:Label("Targets")

  local envAmtKnob = filterEnvTargetsPanel:Knob("EnvelopeAmt", 0, -1, 1)
  envAmtKnob.displayName = "LP-Filter"
  envAmtKnob.fillColour = knobColour
  envAmtKnob.outlineColour = filterColour
  envAmtKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    filterEnvAmount:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  envAmtKnob:changed()
  table.insert(tweakables, {widget=envAmtKnob,bipolar=25,category="filter"})

  local hpfEnvAmtKnob = filterEnvTargetsPanel:Knob("HpfEnvelopeAmt", 0, -1, 1)
  hpfEnvAmtKnob.displayName = "HP-Filter"
  hpfEnvAmtKnob.fillColour = knobColour
  hpfEnvAmtKnob.outlineColour = filterColour
  hpfEnvAmtKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    hpfEnvAmount:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  hpfEnvAmtKnob:changed()
  table.insert(tweakables, {widget=hpfEnvAmtKnob,bipolar=25,category="filter"})

  return filterEnvTargetsPanel
end

--------------------------------------------------------------------------------
-- Amp Env Panel
--------------------------------------------------------------------------------

function createAmpEnvPanel()
  local ampEnvPanel = Panel("ampEnv1")

  local activeAmpEnvOsc = 1
  local ampEnvMenu = ampEnvPanel:Menu("AmpEnvOsc", {"All", "Osc 1", "Osc 2", "Noise Osc"})
  ampEnvMenu.displayName = "Amp Envelope"

  local ampAttackKnob = ampEnvPanel:Knob("Attack", 0.001, 0, 10)
  ampAttackKnob.fillColour = knobColour
  ampAttackKnob.outlineColour = ampEnvColour
  ampAttackKnob.mapper = Mapper.Quartic
  ampAttackKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      ampEnv1:setParameter("AttackTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      ampEnv2:setParameter("AttackTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      ampEnvNoise:setParameter("AttackTime", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  ampAttackKnob:changed()
  table.insert(tweakables, {widget=ampAttackKnob,attack=true,floor=0.001,ceiling=0.01,probability=85,default=50,defaultTweakRange=0.1,category="synthesis"})

  local ampDecayKnob = ampEnvPanel:Knob("Decay", 0.050, 0, 10)
  ampDecayKnob.fillColour = knobColour
  ampDecayKnob.outlineColour = ampEnvColour
  ampDecayKnob.mapper = Mapper.Quartic
  ampDecayKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      ampEnv1:setParameter("DecayTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      ampEnv2:setParameter("DecayTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      ampEnvNoise:setParameter("DecayTime", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  ampDecayKnob:changed()
  table.insert(tweakables, {widget=ampDecayKnob,factor=3,floor=0.01,ceiling=0.5,probability=50,default=25,category="synthesis"})

  local ampSustainKnob = ampEnvPanel:Knob("Sustain", 1, 0, 1)
  ampSustainKnob.fillColour = knobColour
  ampSustainKnob.outlineColour = ampEnvColour
  ampSustainKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      ampEnv1:setParameter("SustainLevel", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      ampEnv2:setParameter("SustainLevel", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      ampEnvNoise:setParameter("SustainLevel", self.value)
    end
    self.displayText = percent(self.value)
  end
  ampSustainKnob:changed()
  table.insert(tweakables, {widget=ampSustainKnob,floor=0.3,ceil=0.9,probability=80,default=60,zero=2,category="synthesis"})

  local ampReleaseKnob = ampEnvPanel:Knob("Release", 0.010, 0, 10)
  ampReleaseKnob.fillColour = knobColour
  ampReleaseKnob.outlineColour = ampEnvColour
  ampReleaseKnob.mapper = Mapper.Quartic
  ampReleaseKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      ampEnv1:setParameter("ReleaseTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      ampEnv2:setParameter("ReleaseTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      ampEnvNoise:setParameter("ReleaseTime", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  ampReleaseKnob:changed()
  table.insert(tweakables, {widget=ampReleaseKnob,release=true,factor=5,floor=0.01,ceiling=0.8,probability=80,default=50,defaultTweakRange=1,category="synthesis"})

  local ampVelocityKnob = ampEnvPanel:Knob("VelocityToAmpEnv", 10, 0, 40)
  ampVelocityKnob.displayName="Velocity"
  ampVelocityKnob.fillColour = knobColour
  ampVelocityKnob.outlineColour = ampEnvColour
  ampVelocityKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      ampEnv1:setParameter("DynamicRange", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      ampEnv2:setParameter("DynamicRange", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      ampEnvNoise:setParameter("DynamicRange", self.value)
    end
  end
  ampVelocityKnob:changed()
  table.insert(tweakables, {widget=ampVelocityKnob,min=40,category="synthesis"})

  function setAmpEnvKnob(knob, param)
    if activeAmpEnvOsc == 1 then
      knob.enabled = isEqual(ampEnv1:getParameter(param), ampEnv2:getParameter(param)) and isEqual(ampEnv2:getParameter(param), ampEnvNoise:getParameter(param))
      return
    end
    local value
    if activeAmpEnvOsc == 2 then
      value = ampEnv1:getParameter(param)
    elseif activeAmpEnvOsc == 3 then
      value = ampEnv2:getParameter(param)
    elseif activeAmpEnvOsc == 4 then
      value = ampEnvNoise:getParameter(param)
    end
    knob:setValue(value)
    print("setAmpEnvKnob:setValue:", param, value)
    knob.enabled = true
  end

  ampEnvMenu.changed = function(self)
    -- STORE ACTIVE OSCILLATOR
    activeAmpEnvOsc = self.value
    -- SET KNOB VALUES
    setAmpEnvKnob(ampAttackKnob, "AttackTime")
    setAmpEnvKnob(ampDecayKnob, "DecayTime")
    setAmpEnvKnob(ampSustainKnob, "SustainLevel")
    setAmpEnvKnob(ampReleaseKnob, "ReleaseTime")
    setAmpEnvKnob(ampVelocityKnob, "DynamicRange")
  end
  ampEnvMenu:changed()

  return ampEnvPanel
end

--------------------------------------------------------------------------------
-- Lfo Panel
--------------------------------------------------------------------------------

function createLfoPanel()
  local lfoPanel = Panel("LFO")

  local activeLfoOsc = 1

  local lfoMenu = lfoPanel:Menu("LfoOsc", {"All", "Osc 1", "Osc 2", "Noise Osc"})
  lfoMenu.displayName = "LFO"

  local waveFormTypes = {"Sinus", "Square", "Triangle", "Ramp Up", "Ramp Down", "Analog Square", "S&H", "Chaos Lorenz", "Chaos Rossler"}
  local waveFormTypeMenu = lfoPanel:Menu("WaveFormTypeMenu", waveFormTypes)
  waveFormTypeMenu.displayName = "Waveform"
  waveFormTypeMenu.selected = 3
  waveFormTypeMenu.changed = function(self)
    local value = self.value - 1
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      lfo1:setParameter("WaveFormType", value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      lfo2:setParameter("WaveFormType", value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      lfo3:setParameter("WaveFormType", value)
    end
  end
  waveFormTypeMenu:changed()
  table.insert(tweakables, {widget=waveFormTypeMenu,min=#waveFormTypes,category="modulation"})

  local lfoFreqKnob = lfoPanel:Knob("LfoFreq", 4.5, 0.1, 20.)
  lfoFreqKnob.displayName = "Freq"
  lfoFreqKnob.fillColour = knobColour
  lfoFreqKnob.outlineColour = lfoColour

  local lfo2SyncButton = lfoPanel:OnOffButton("Lfo2Sync", false)
  lfo2SyncButton.displayName = "Sync"
  lfo2SyncButton.fillColour = knobColour
  lfo2SyncButton.outlineColour = lfoColour
  lfo2SyncButton.width = 75
  lfo2SyncButton.changed = function(self)
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      lfo1:setParameter("SyncToHost", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      lfo2:setParameter("SyncToHost", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      lfo3:setParameter("SyncToHost", self.value)
    end
    if self.value == false then
      lfoFreqKnob.default = 4.5
      lfoFreqKnob.mapper = Mapper.Quadratic
      lfoFreqKnob.changed = function(self)
        if activeLfoOsc == 1 or activeLfoOsc == 2 then
          lfo1:setParameter("Freq", self.value)
        end
        if activeLfoOsc == 1 or activeLfoOsc == 3 then
          lfo2:setParameter("Freq", self.value)
        end
        if activeLfoOsc == 1 or activeLfoOsc == 4 then
          lfo3:setParameter("Freq", self.value)
        end
        self.displayText = string.format("%0.2f Hz", self.value)
      end
      lfoFreqKnob:changed()
    else
      lfoFreqKnob.default = 11
      lfoFreqKnob.mapper = Mapper.Linear
      lfoFreqKnob.changed = function(self)
        local index = math.floor(self.value) + 1
        if activeLfoOsc == 1 or activeLfoOsc == 2 then
          lfo1:setParameter("Freq", getResolution(index))
        end
        if activeLfoOsc == 1 or activeLfoOsc == 3 then
          lfo2:setParameter("Freq", getResolution(index))
        end
        if activeLfoOsc == 1 or activeLfoOsc == 4 then
          lfo3:setParameter("Freq", getResolution(index))
        end
        self.displayText = getResolutionName(index)
      end
      lfoFreqKnob:changed()
    end
  end
  lfo2SyncButton:changed()
  table.insert(tweakables, {widget=lfo2SyncButton,func=getRandomBoolean,category="modulation"})

  table.insert(tweakables, {widget=lfoFreqKnob,factor=20,category="modulation"})

  local lfo2TriggerButton = lfoPanel:OnOffButton("Lfo2Trigger", true)
  lfo2TriggerButton.fillColour = knobColour
  lfo2TriggerButton.outlineColour = lfoColour
  lfo2TriggerButton.width = 75
  lfo2TriggerButton.position = {lfo2SyncButton.x,25}
  lfo2TriggerButton.displayName = "Retrigger"
  lfo2TriggerButton.changed = function(self)
    local mode = 1
    if (self.value == false) then
      mode = 3
    end
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      lfo1:setParameter("Retrigger", mode)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      lfo2:setParameter("Retrigger", mode)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      lfo3:setParameter("Retrigger", mode)
    end
  end
  lfo2TriggerButton:changed()
  table.insert(tweakables, {widget=lfo2TriggerButton,func=getRandomBoolean,category="modulation"})

  local lfoFreqKeyFollowKnob = lfoPanel:Knob("LfoFreqKeyFollow", 0, 0, 1)
  lfoFreqKeyFollowKnob.displayName = "Key Track"
  lfoFreqKeyFollowKnob.fillColour = knobColour
  lfoFreqKeyFollowKnob.outlineColour = lfoColour
  lfoFreqKeyFollowKnob.changed = function(self)
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      lfoFreqKeyFollow1:setParameter("Value", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      lfoFreqKeyFollow2:setParameter("Value", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      lfoFreqKeyFollow3:setParameter("Value", self.value)
    end
    self.displayText = percent(self.value)
  end
  lfoFreqKeyFollowKnob:changed()
  table.insert(tweakables, {widget=lfoFreqKeyFollowKnob,ceiling=0.5,probability=50,default=15,zero=75,category="modulation"})

  local lfoDelayKnob = lfoPanel:Knob("LfoDelay", 0, 0, 10)
  lfoDelayKnob.displayName="Delay"
  lfoDelayKnob.fillColour = knobColour
  lfoDelayKnob.outlineColour = lfoColour
  lfoDelayKnob.mapper = Mapper.Quartic
  lfoDelayKnob.x = lfoMenu.width + 15
  lfoDelayKnob.y = lfoMenu.height + 15
  lfoDelayKnob.changed = function(self)
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      lfo1:setParameter("DelayTime", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      lfo2:setParameter("DelayTime", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      lfo3:setParameter("DelayTime", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  lfoDelayKnob:changed()
  table.insert(tweakables, {widget=lfoDelayKnob,factor=5,ceiling=2,probability=50,default=35,zero=50,category="modulation"})

  local lfoRiseKnob = lfoPanel:Knob("LfoRise", 0, 0, 10)
  lfoRiseKnob.displayName="Rise"
  lfoRiseKnob.fillColour = knobColour
  lfoRiseKnob.outlineColour = lfoColour
  lfoRiseKnob.mapper = Mapper.Quartic
  lfoRiseKnob.x = lfoDelayKnob.x + lfoDelayKnob.width + 15
  lfoRiseKnob.y = lfoDelayKnob.y
  lfoRiseKnob.changed = function(self)
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      lfo1:setParameter("RiseTime", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      lfo2:setParameter("RiseTime", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      lfo3:setParameter("RiseTime", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  lfoRiseKnob:changed()
  table.insert(tweakables, {widget=lfoRiseKnob,factor=5,ceiling=2,probability=50,default=35,zero=50,category="modulation"})

  local lfoSmoothKnob = lfoPanel:Knob("LfoSmooth", 0, 0, 1)
  lfoSmoothKnob.displayName="Smooth"
  lfoSmoothKnob.fillColour = knobColour
  lfoSmoothKnob.outlineColour = lfoColour
  lfoSmoothKnob.mapper = Mapper.Quartic
  lfoSmoothKnob.x = lfoRiseKnob.x + lfoRiseKnob.width + 15
  lfoSmoothKnob.y = lfoRiseKnob.y
  lfoSmoothKnob.changed = function(self)
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      lfo1:setParameter("Smooth", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      lfo2:setParameter("Smooth", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      lfo3:setParameter("Smooth", self.value)
    end
    self.displayText = formatTimeInSeconds(self.value)
  end
  lfoSmoothKnob:changed()
  table.insert(tweakables, {widget=lfoSmoothKnob,ceiling=0.3,default=50,zero=70,category="modulation"})

  local lfoBipolarButton = lfoPanel:OnOffButton("LfoBipolar", true)
  lfoBipolarButton.fillColour = knobColour
  lfoBipolarButton.outlineColour = lfoColour
  lfoBipolarButton.width = 75
  lfoBipolarButton.x = lfoSmoothKnob.x + lfoSmoothKnob.width + 15
  lfoBipolarButton.y = lfoSmoothKnob.y
  lfoBipolarButton.displayName = "Bipolar"
  lfoBipolarButton.changed = function(self)
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      lfo1:setParameter("Bipolar", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      lfo2:setParameter("Bipolar", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      lfo3:setParameter("Bipolar", self.value)
    end
  end
  lfoBipolarButton:changed()
  table.insert(tweakables, {widget=lfoBipolarButton,func=getRandomBoolean,probability=75,category="modulation"})

  function setLfoWidgetValue(widget, param, params)
    if activeLfoOsc == 1 then
      widget.enabled = isEqual(params[1]:getParameter(param), params[2]:getParameter(param)) and isEqual(params[2]:getParameter(param), params[3]:getParameter(param))
      return
    end
    local value
    if activeLfoOsc == 2 then
      value = params[1]:getParameter(param)
    elseif activeLfoOsc == 3 then
      value = params[2]:getParameter(param)
    elseif activeLfoOsc == 4 then
      value = params[3]:getParameter(param)
    end
    if param == "WaveFormType" then
      value = value + 1
    elseif param == "Retrigger" then
      value = value == 1
    elseif param == "Freq" then
      if activeLfoOsc == 2 and params[1]:getParameter("SyncToHost") == true then
        value = getSyncedValue(value)
      elseif activeLfoOsc == 3 and params[2]:getParameter("SyncToHost") == true then
        value = getSyncedValue(value)
      elseif activeLfoOsc == 4 and params[3]:getParameter("SyncToHost") == true then
        value = getSyncedValue(value)
      end
    end
    widget:setValue(value)
    print("setLfoWidgetValue:setValue:", param, value)
    widget.enabled = true
  end

  lfoMenu.changed = function(self)
    -- STORE THE ACTIVE OSCILLATOR
    activeLfoOsc = self.value -- 1 = all oscillators
    --print("LFO - Active oscillator changed:", activeLfoOsc, self.selectedText)
    -- SET LFO WIDGET VALUES PER OSCILLATOR
    local params = {lfo1, lfo2, lfo3}
    setLfoWidgetValue(waveFormTypeMenu, "WaveFormType", params)
    setLfoWidgetValue(lfoDelayKnob, "DelayTime", params)
    setLfoWidgetValue(lfoRiseKnob, "RiseTime", params)
    setLfoWidgetValue(lfo2SyncButton, "SyncToHost", params)
    setLfoWidgetValue(lfo2TriggerButton, "Retrigger", params)
    setLfoWidgetValue(lfoFreqKnob, "Freq", params)
    setLfoWidgetValue(lfoBipolarButton, "Bipolar", params)
    setLfoWidgetValue(lfoSmoothKnob, "Smooth", params)
    setLfoWidgetValue(lfoFreqKeyFollowKnob, "Value", {lfoFreqKeyFollow1, lfoFreqKeyFollow2, lfoFreqKeyFollow3})
  end
  lfoMenu:changed()

  return lfoPanel
end

local lfoNoiseOscOverride = false

function createLfoTargetPanel3()
  local lfoTargetPanel3 = Panel("LfoTargetPanel3")
  lfoTargetPanel3:Label("Noise Osc")

  local lfoToNoiseLpfCutoffKnob = lfoTargetPanel3:Knob("LfoToNoiseLpfCutoff", 0, -1, 1)
  lfoToNoiseLpfCutoffKnob.displayName = "LP-Filter"
  lfoToNoiseLpfCutoffKnob.fillColour = knobColour
  lfoToNoiseLpfCutoffKnob.outlineColour = lfoColour
  lfoToNoiseLpfCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    lfoToNoiseLpf:setParameter("Value", value)
    self.displayText = percent(self.value)
  end

  local lfoToNoiseHpfCutoffKnob = lfoTargetPanel3:Knob("LfoToNoiseHpfCutoff", 0, -1, 1)
  lfoToNoiseHpfCutoffKnob.displayName = "HP-Filter"
  lfoToNoiseHpfCutoffKnob.fillColour = knobColour
  lfoToNoiseHpfCutoffKnob.outlineColour = lfoColour
  lfoToNoiseHpfCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    lfoToNoiseHpf:setParameter("Value", value)
    self.displayText = percent(self.value)
  end

  local lfoToNoiseAmpKnob = lfoTargetPanel3:Knob("LfoToNoiseAmplitude", 0, -1, 1)
  lfoToNoiseAmpKnob.displayName = "Amplitude"
  lfoToNoiseAmpKnob.fillColour = knobColour
  lfoToNoiseAmpKnob.outlineColour = lfoColour
  lfoToNoiseAmpKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    lfoToNoiseAmp:setParameter("Value", value)
    self.displayText = percent(self.value)
  end

  local lfoToNoiseOverrideButton = lfoTargetPanel3:OnOffButton("LfoToNoiseOverride", lfoNoiseOscOverride)
  lfoToNoiseOverrideButton.displayName = "Override"
  lfoToNoiseOverrideButton.changed = function (self)
    lfoNoiseOscOverride = self.value
    lfoToNoiseLpfCutoffKnob.enabled = lfoNoiseOscOverride
    lfoToNoiseLpfCutoffKnob:changed()
    lfoToNoiseHpfCutoffKnob.enabled = lfoNoiseOscOverride
    lfoToNoiseHpfCutoffKnob:changed()
    lfoToNoiseAmpKnob.enabled = lfoNoiseOscOverride
    lfoToNoiseAmpKnob:changed()
    if (lfoNoiseOscOverride == false) then
      lfoToNoiseLpf:setParameter("Value", lfoToCutoff:getParameter("Value"))
      lfoToNoiseHpf:setParameter("Value", lfoToHpf:getParameter("Value"))
      lfoToNoiseAmp:setParameter("Value", lfoToAmp:getParameter("Value"))
    end
  end
  lfoToNoiseOverrideButton:changed()

  table.insert(tweakables, {widget=lfoToNoiseOverrideButton,func=getRandomBoolean,probability=25,category="modulation"})
  table.insert(tweakables, {widget=lfoToNoiseAmpKnob,bipolar=25,category="modulation"})
  table.insert(tweakables, {widget=lfoToNoiseHpfCutoffKnob,bipolar=25,category="modulation"})
  table.insert(tweakables, {widget=lfoToNoiseLpfCutoffKnob,bipolar=25,category="modulation"})

  return lfoTargetPanel3
end

function createLfoTargetPanel()
  local lfoTargetPanel = Panel("LfoTargetPanel")
  lfoTargetPanel:Label("Targets")

  local lfoToCutoffKnob = lfoTargetPanel:Knob("LfoToCutoff", 0, -1, 1)
  lfoToCutoffKnob.displayName = "LP-Filter"
  lfoToCutoffKnob.fillColour = knobColour
  lfoToCutoffKnob.outlineColour = lfoColour
  lfoToCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    lfoToCutoff:setParameter("Value", value)
    if lfoNoiseOscOverride == false then
      lfoToNoiseLpf:setParameter("Value", value)
    end
    self.displayText = percent(self.value)
  end
  lfoToCutoffKnob:changed()

  local lfoToHpfCutoffKnob = lfoTargetPanel:Knob("LfoToHpfCutoff", 0, -1, 1)
  lfoToHpfCutoffKnob.displayName = "HP-Filter"
  lfoToHpfCutoffKnob.fillColour = knobColour
  lfoToHpfCutoffKnob.outlineColour = lfoColour
  lfoToHpfCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    lfoToHpf:setParameter("Value", value)
    if lfoNoiseOscOverride == false then
      lfoToNoiseHpf:setParameter("Value", value)
    end
    self.displayText = percent(self.value)
  end
  lfoToHpfCutoffKnob:changed()

  local lfoToAmpKnob = lfoTargetPanel:Knob("LfoToAmplitude", 0, -1, 1)
  lfoToAmpKnob.displayName = "Amplitude"
  lfoToAmpKnob.fillColour = knobColour
  lfoToAmpKnob.outlineColour = lfoColour
  lfoToAmpKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    lfoToAmp:setParameter("Value", value)
    if lfoNoiseOscOverride == false then
      lfoToNoiseAmp:setParameter("Value", value)
    end
    self.displayText = percent(self.value)
  end
  lfoToAmpKnob:changed()

  local lfoToDetuneKnob = lfoTargetPanel:Knob("LfoToDetune", 0, 0, 1)
  lfoToDetuneKnob.displayName = "Detune"
  lfoToDetuneKnob.fillColour = knobColour
  lfoToDetuneKnob.outlineColour = lfoColour
  lfoToDetuneKnob.changed = function(self)
    lfoToDetune:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  lfoToDetuneKnob:changed()

  table.insert(tweakables, {widget=lfoToDetuneKnob,default=25,ceiling=0.25,probability=30,category="modulation"})
  table.insert(tweakables, {widget=lfoToAmpKnob,bipolar=25,default=30,ceiling,category="modulation"})
  table.insert(tweakables, {widget=lfoToHpfCutoffKnob,bipolar=25,default=30,category="modulation"})
  table.insert(tweakables, {widget=lfoToCutoffKnob,bipolar=25,default=30,category="modulation"})

  return lfoTargetPanel
end

--------------------------------------------------------------------------------
-- Tweak Panel
--------------------------------------------------------------------------------

function createPatchMakerPanel()
  local tweakPanel = Panel("Tweaks")
  tweakPanel.backgroundColour = "#33AA3399"
  tweakPanel.x = marginX
  tweakPanel.y = height * 1.6
  tweakPanel.width = width
  tweakPanel.height = height * 6

  local tweakLevelKnob = tweakPanel:Knob("TweakLevel", 50, 0, 100, true)
  tweakLevelKnob.displayName = "Tweak level"
  tweakLevelKnob.bounds = {10,10,width/3,height*3}

  local tweakSourceMenu = tweakPanel:Menu("TweakSource", tweakSources)
  tweakSourceMenu.displayName = "Tweak source"
  tweakSourceMenu.width = width/4-10
  tweakSourceMenu.x = width/2
  tweakSourceMenu.y = 10

  local envStyleMenu = tweakPanel:Menu("EnvStyle", {"Automatic", "Very short", "Short", "Medium short", "Medium", "Medium long", "Long", "Very long"})
  envStyleMenu.displayName = "Envelope Style"
  envStyleMenu.width = tweakSourceMenu.width
  envStyleMenu.x = tweakSourceMenu.width + tweakSourceMenu.x + 10
  envStyleMenu.y = tweakSourceMenu.y

  -- synthesis, modulation, filter, mixer, effects
  local synthesisButton = tweakPanel:OnOffButton("Synthesis", true)
  synthesisButton.fillColour = knobColour
  synthesisButton.size = {76,35}
  synthesisButton.x = width/2
  synthesisButton.y = tweakSourceMenu.y + tweakSourceMenu.height + 10

  local filterButton = tweakPanel:OnOffButton("Filter", true)
  filterButton.fillColour = knobColour
  filterButton.size = {60,35}
  filterButton.x = synthesisButton.x + synthesisButton.width + marginX
  filterButton.y = synthesisButton.y

  local modulationButton = tweakPanel:OnOffButton("Modulation", true)
  modulationButton.fillColour = knobColour
  modulationButton.size = {76,35}
  modulationButton.x = filterButton.x + filterButton.width + marginX
  modulationButton.y = synthesisButton.y

  local mixerButton = tweakPanel:OnOffButton("Mixer", true)
  mixerButton.fillColour = knobColour
  mixerButton.size = {60,35}
  mixerButton.x = modulationButton.x + modulationButton.width + marginX
  mixerButton.y = synthesisButton.y

  local effectsButton = tweakPanel:OnOffButton("Effects", true)
  effectsButton.fillColour = knobColour
  effectsButton.size = {60,35}
  effectsButton.x = mixerButton.x + mixerButton.width + marginX
  effectsButton.y = synthesisButton.y

  local tweakButton = tweakPanel:Button("Tweak")
  tweakButton.displayName = "Tweak patch"
  tweakButton.bounds = {width/2,synthesisButton.y+synthesisButton.height+10,width/2-10,height*2}
  tweakButton.textColourOff = "white"
  tweakButton.backgroundColourOff = "skyblue"
  tweakButton.changed = function(self)
    print("Start tweaking!")
    for i,v in ipairs(tweakables) do
      local skip = false
      if v.category == "synthesis" and synthesisButton.value == false then
        skip = true
      elseif v.category == "modulation" and modulationButton.value == false then
        skip = true
      elseif v.category == "filter" and filterButton.value == false then
        skip = true
      elseif v.category == "mixer" and mixerButton.value == false then
        skip = true
      elseif v.category == "effects" and effectsButton.value == false then
        skip = true
      end
      if skip == false then
        tweakWidget(v, tweakLevelKnob.value, 0, tweakSourceMenu.value, envStyleMenu.value)
      else
        print("Skipping:", v.widget.name)
      end
    end
    print("Tweaking complete!")
  end

  function setWidgetValue(index, widgetName, value)
    if widgetName == tweakables[index].widget.name then
      tweakables[index].widget.value = value
      print("Set widget value: ", widgetName, tweakables[index].widget.value, value)
    end
  end

  patchesMenu = tweakPanel:Menu("PatchesMenu")
  patchesMenu.x = 10
  patchesMenu.y = tweakLevelKnob.y + tweakLevelKnob.height + 20
  patchesMenu.displayName = "Stored snapshots"
  patchesMenu.changed = function(self)
    local index = self.value
    if #storedPatches == 0 then
      print("No patches")
      return
    end
    if index > #storedPatches then
      print("No patch at index")
      index = #snapshots
    end
    tweaks = storedPatches[index]
    for i,v in ipairs(tweaks) do
      setWidgetValue(v.index, v.widget, v.value)
    end
    print("Tweaks set from patch at index:", index)
  end

  local prevPatchButton = tweakPanel:Button("PrevPatch")
  prevPatchButton.displayName = "<"
  prevPatchButton.x = patchesMenu.x + patchesMenu.width + marginX
  prevPatchButton.y = patchesMenu.y + 25
  prevPatchButton.width = 25
  prevPatchButton.changed = function(self)
    if #storedPatches == 0 then
      print("No patches")
      return
    end
    local value = patchesMenu.value - 1
    if value < 1 then
      value = #storedPatches
    end
    patchesMenu:setValue(value)
  end

  local nextPatchButton = tweakPanel:Button("NextPatch")
  nextPatchButton.displayName = ">"
  nextPatchButton.x = prevPatchButton.x + prevPatchButton.width + marginX
  nextPatchButton.y = prevPatchButton.y
  nextPatchButton.width = 25
  nextPatchButton.changed = function(self)
    if #storedPatches == 0 then
      print("No patches")
      return
    end
    local value = patchesMenu.value + 1
    if value > #storedPatches then
      value = 1
    end
    patchesMenu:setValue(value)
  end

  local managePatchesMenu = tweakPanel:Menu("ManagePatchesMenu", {"Manage...", "Add to snapshots", "Update selected", "Remove selected"})
  managePatchesMenu.x = nextPatchButton.x + nextPatchButton.width + marginX
  managePatchesMenu.y = patchesMenu.y
  managePatchesMenu.displayName = "Manage snapshots"
  managePatchesMenu.changed = function(self)
    if self.value == 1 then
      return
    end
    if self.value == 2 then
      storeNewSnapshot()
    elseif self.value == 3 then
      updateSelectedSnapshot()
    elseif self.value == 4 then
      removeSelectedSnapshot()
    end
    self:setValue(1)
  end

  function updateSelectedSnapshot()
    local selected = patchesMenu.value
    if #storedPatches == 0 then
      return
    end
    local snapshot = {}
    for i,v in ipairs(tweakables) do
      table.insert(snapshot, {index=i,widget=v.widget.name,value=v.widget.value})
    end
    table.remove(storedPatches, selected)
    table.insert(storedPatches, selected, snapshot)
    print("Updating snapshot:", selected)
  end

  function removeSelectedSnapshot()
    local selected = patchesMenu.value
    if #storedPatches == 0 or selected == 1 then
      return
    end
    table.remove(storedPatches, selected)
    patchesMenu:clear()
    populatePatchesMenu()
    print("Remove snapshot:", selected)
    patchesMenu:setValue(#storedPatches)
  end

  function storeNewSnapshot()
    print("Storing patch tweaks...")
    if #storedPatches == 0 then
      table.insert(storedPatches, storedPatch)
    end
    local snapshot = {}
    for i,v in ipairs(tweakables) do
      table.insert(snapshot, {index=i,widget=v.widget.name,value=v.widget.value})
    end
    table.insert(storedPatches, snapshot)
    print("Storing snapshot")
    patchesMenu:clear()
    populatePatchesMenu()
    print("Adding to patchesMenu", index)
    patchesMenu:setValue(#storedPatches)
  end

  local recallStoredPatchButton = tweakPanel:Button("RecallPatch")
  recallStoredPatchButton.displayName = "Recall saved patch"
  recallStoredPatchButton.bounds = {tweakButton.x,tweakButton.y+tweakButton.height+10,tweakButton.width,patchesMenu.height}
  recallStoredPatchButton.textColourOff = "white"
  recallStoredPatchButton.backgroundColourOff = "orange"
  recallStoredPatchButton.changed = function(self)
    print("Recalling stored patch...")
    for i,v in ipairs(storedPatch) do
      setWidgetValue(v.index, v.widget, v.value)
      print("Set value for widget", v.widget.name, v.value)
    end
  end

  local initPatchButton = tweakPanel:Button("InitPatch")
  initPatchButton.displayName = "Initialize patch"
  initPatchButton.bounds = {recallStoredPatchButton.x,recallStoredPatchButton.y+recallStoredPatchButton.height+10,recallStoredPatchButton.width,recallStoredPatchButton.height}
  initPatchButton.textColourOff = "white"
  initPatchButton.backgroundColourOff = "silver"
  initPatchButton.changed = function(self)
    print("Setting default values...")
    for i,v in ipairs(tweakables) do
      v.widget.value = v.widget.default
      print("Set default value for widget", v.widget.name, v.widget.value)
    end
  end

  local clearStoredPatchesButton = tweakPanel:Button("ClearStoredPatches")
  clearStoredPatchesButton.displayName = "Remove all snapshots"
  clearStoredPatchesButton.bounds = {patchesMenu.x,patchesMenu.y+patchesMenu.height+height,patchesMenu.width+managePatchesMenu.width,20}
  clearStoredPatchesButton.backgroundColourOff = "red"
  clearStoredPatchesButton.textColourOff = "white"
  clearStoredPatchesButton.changed = function(self)
    print("Clearing stored snapshots...")
    storedPatches = {}
    patchesMenu:clear()
  end

  return tweakPanel
end

--------------------------------------------------------------------------------
-- Twequencer Panel
--------------------------------------------------------------------------------

function createTwequencerPanel()
  local arpId = 0
  local heldNotes = {}
  local snapshots = {}
  
  local tweqPanel = Panel("Sequencer")
  tweqPanel.backgroundColour = "#33000099"
  tweqPanel.x = marginX
  tweqPanel.y = height * 1.6
  tweqPanel.width = width
  tweqPanel.height = height * 6

  local sequencerPlayMenu = tweqPanel:Menu("SequencerPlay", {"Off", "Mono", "As played", "Random", "Chord"})
  sequencerPlayMenu.displayName = "Play Mode"
  sequencerPlayMenu.width = 120

  local tweakLevelKnob = tweqPanel:Knob("SeqTweakLevel", 0, 0, 100, true)
  tweakLevelKnob.persistent = false
  tweakLevelKnob.displayName = "Tweak Level"
  tweakLevelKnob.x = sequencerPlayMenu.x
  tweakLevelKnob.y = sequencerPlayMenu.y + sequencerPlayMenu.height + 12
  tweakLevelKnob.width = sequencerPlayMenu.width

  local numStepsBox = tweqPanel:NumBox("Steps", 16, 2, 32, true)
  numStepsBox.backgroundColour = "black"
  numStepsBox.textColour = "cyan"
  numStepsBox.arrowColour = "grey"
  numStepsBox.outlineColour = "#1fFFFFFF" -- transparent white

  local seqPitchTable = tweqPanel:Table("Pitch", numStepsBox.value, 0, -12, 12, true)
  seqPitchTable.showPopupDisplay = true
  seqPitchTable.width = 400
  seqPitchTable.x = sequencerPlayMenu.width * 1.2

  local seqVelTable = tweqPanel:Table("Velocity", numStepsBox.value, 100, 1, 127, true)
  seqVelTable.showPopupDisplay = true
  seqVelTable.width = seqPitchTable.width
  seqVelTable.x = seqPitchTable.x
  seqVelTable.y = seqPitchTable.y + seqPitchTable.height + marginY

  local resolution = tweqPanel:Menu{"Resolution", getResolutionNames(), selected=15}
  resolution.x = seqPitchTable.x + seqPitchTable.width + 30
  resolution.backgroundColour = "black"
  resolution.textColour = "cyan"
  resolution.arrowColour = "grey"
  resolution.outlineColour = "#1fFFFFFF" -- transparent white

  local positionTable = tweqPanel:Table("Position", numStepsBox.value, 0, 0, 1, true)
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.width = seqPitchTable.width
  positionTable.x = seqPitchTable.x
  positionTable.y = seqVelTable.y + seqVelTable.height + marginY

  local snapshotsMenu = tweqPanel:Menu("SnapshotsMenu")
  snapshotsMenu.x = positionTable.x
  snapshotsMenu.y = positionTable.y + positionTable.height + marginY
  snapshotsMenu.enabled = false
  snapshotsMenu.displayName = "Snapshots"
  snapshotsMenu.persistent = false
  snapshotsMenu.changed = function(self)
    local index = self.value
    if #snapshots == 0 then
      print("No snapshots")
      return
    end
    if index > #snapshots then
      print("No snapshot at index")
      index = #snapshots
    end
    tweaks = snapshots[index]
    for i,v in ipairs(tweaks) do
      v.widget.value = v.value
    end
    print("Tweaks set from snapshot at index:", index)
  end

  local prevSnapshotButton = tweqPanel:Button("PrevSnapshot")
  prevSnapshotButton.displayName = "<"
  prevSnapshotButton.x = snapshotsMenu.x + snapshotsMenu.width + marginX
  prevSnapshotButton.y = snapshotsMenu.y + 25
  prevSnapshotButton.width = 25
  prevSnapshotButton.enabled = false
  prevSnapshotButton.persistent = false
  prevSnapshotButton.changed = function(self)
    if #snapshots == 0 then
      print("No snapshots")
      return
    end
    local value = snapshotsMenu.value - 1
    if value < 1 then
      value = #snapshots
    end
    snapshotsMenu:setValue(value)
  end
  
  local nextSnapshotButton = tweqPanel:Button("NextSnapshot")
  nextSnapshotButton.displayName = ">"
  nextSnapshotButton.x = prevSnapshotButton.x + prevSnapshotButton.width + marginX
  nextSnapshotButton.y = prevSnapshotButton.y
  nextSnapshotButton.width = 25
  nextSnapshotButton.enabled = false
  nextSnapshotButton.persistent = false
  nextSnapshotButton.changed = function(self)
    if #snapshots == 0 then
      print("No snapshots")
      return
    end
    local value = snapshotsMenu.value + 1
    if value > #snapshots then
      value = 1
    end
    snapshotsMenu:setValue(value)
  end  

  local storeSnapshotButton = tweqPanel:Button("storeSnapshotButton")
  storeSnapshotButton.displayName = "Store snapshot"
  storeSnapshotButton.x = nextSnapshotButton.x + nextSnapshotButton.width + marginX
  storeSnapshotButton.y = nextSnapshotButton.y
  storeSnapshotButton.enabled = false
  storeSnapshotButton.changed = function(self)
    local index = snapshotsMenu.value
    if #snapshots == 0 then
      print("No snapshots")
      return
    end
    if index > #snapshots then
      print("No snapshot at index")
      return
    end
    if #storedPatches == 0 then
      table.insert(storedPatches, storedPatch)
    end
    local snapshot = {}
    for i,v in ipairs(snapshots[index]) do
      table.insert(snapshot, {index=i,widget=v.widget.name,value=v.widget.value})
    end
    table.insert(storedPatches, snapshot)
    print("Storing snapshot")
    patchesMenu:clear()
    populatePatchesMenu()
    print("Tweaks stored from snapshot at index:", index)
  end

  function populateSnapshots()
    snapshots = {}
    snapshotsMenu:clear()
    for i = 1, numStepsBox.value do
      snapshotsMenu:addItem("Step "..i)
      table.insert(snapshots, {})
    end
  end

  numStepsBox.x = resolution.x
  numStepsBox.y = resolution.y + resolution.height + marginY
  numStepsBox.changed = function (self)
    seqPitchTable.length = self.value
    seqVelTable.length = self.value
    positionTable.length = self.value
    populateSnapshots()
  end
  numStepsBox:changed()

  local gate = tweqPanel:Knob("Gate", 0.8, 0, 1)
  gate.x = resolution.x
  gate.y = numStepsBox.y + numStepsBox.height + 12
  gate.changed = function(self)
      self.displayText = percent(self.value)
  end
  gate:changed() -- force update

  sequencerPlayMenu.changed = function (self)
    -- Stop sequencer if turned off
    if self.value == 1 then
      heldNotes = {}
      clearPosition()
      resetTweakLevel()
      arpId = arpId + 1
    end
  end

  local tweakSourceMenu = tweqPanel:Menu("SeqTweakSource", tweakSources)
  tweakSourceMenu.displayName = "Tweak source"
  tweakSourceMenu.x = snapshotsMenu.x
  tweakSourceMenu.y = snapshotsMenu.y + height

  -- synthesis, modulation, filter, mixer, effects
  local synthesisButton = tweqPanel:OnOffButton("SeqSynthesis", true)
  synthesisButton.displayName = "Synthesis"
  synthesisButton.fillColour = knobColour
  synthesisButton.size = {78,35}
  synthesisButton.x = tweakSourceMenu.x
  synthesisButton.y = tweakSourceMenu.y + height

  local filterButton = tweqPanel:OnOffButton("SeqFilter", true)
  filterButton.displayName = "Filter"
  filterButton.fillColour = knobColour
  filterButton.size = {78,35}
  filterButton.x = synthesisButton.x + synthesisButton.width + marginX
  filterButton.y = synthesisButton.y

  local modulationButton = tweqPanel:OnOffButton("SeqModulation", true)
  modulationButton.displayName = "Modulation"
  modulationButton.fillColour = knobColour
  modulationButton.size = {78,35}
  modulationButton.x = filterButton.x + filterButton.width + marginX
  modulationButton.y = synthesisButton.y

  local mixerButton = tweqPanel:OnOffButton("SeqMixer", true)
  mixerButton.displayName = "Mixer"
  mixerButton.fillColour = knobColour
  mixerButton.size = {78,35}
  mixerButton.x = modulationButton.x + modulationButton.width + marginX
  mixerButton.y = synthesisButton.y

  local effectsButton = tweqPanel:OnOffButton("SeqEffects", true)
  effectsButton.displayName = "Effects"
  effectsButton.fillColour = knobColour
  effectsButton.size = {78,35}
  effectsButton.x = mixerButton.x + mixerButton.width + marginX
  effectsButton.y = synthesisButton.y

  function getTweakablesForTwequencer()
    local t = {}
    for i,v in ipairs(tweakables) do
      local skip = false
      if v.category == "synthesis" and synthesisButton.value == false then
        skip = true
      elseif v.category == "modulation" and modulationButton.value == false then
        skip = true
      elseif v.category == "filter" and filterButton.value == false then
        skip = true
      elseif v.category == "mixer" and mixerButton.value == false then
        skip = true
      elseif v.category == "effects" and effectsButton.value == false then
        skip = true
      end
      if skip == true or v.widget.enabled == false or v.excludeWithDuration == true then
        print("Skipping:", v.widget.name)
      else
        table.insert(t, v)
      end
    end
  
    print("Widgets ready:", #t)

    return t
  end

  function resetTweakLevel()
    tweakLevelKnob.value = 0
  end

  function clearPosition()
    for i = 1, numStepsBox.value do
      positionTable:setValue(i, 0)
    end
  end

  function getSpawnsFromResolution(res)
    local factor = res / 21 * getResolution(res) / 2.4
    local num = math.ceil(getResolution(res) / factor)
    print("Number of spawns for resolution", num, getResolution(res))
    return num
  end

  function arpeg(arpId_)
    local index = 0
    local heldNoteIndex = 0
    local tweakablesIndex = 0
    -- START ARP LOOP
    while arpId_ == arpId do
      print("Position index:", index)
      
      -- GET NOTES FOR ARP
      local notes = {}
      local pitchAdjustment = seqPitchTable:getValue(index+1)
      if sequencerPlayMenu.value == 2 then -- MONO
        heldNoteIndex = #heldNotes
        table.insert(notes, heldNotes[heldNoteIndex].note + pitchAdjustment)
      elseif sequencerPlayMenu.value == 3 then -- AS PLAYED
        heldNoteIndex = heldNoteIndex + 1 -- Increment
        if heldNoteIndex > #heldNotes then
          heldNoteIndex = 1
        end
        table.insert(notes, heldNotes[heldNoteIndex].note + pitchAdjustment)
      elseif sequencerPlayMenu.value == 4 then -- RANDOM
        heldNoteIndex = math.random(1, #heldNotes)
        table.insert(notes, heldNotes[heldNoteIndex].note + pitchAdjustment)
      elseif sequencerPlayMenu.value == 5 then -- CHORD
        for i=1,#heldNotes do
          table.insert(notes, heldNotes[i].note + pitchAdjustment)
        end
      end

      -- PLAY NOTE(S)
      local p = getResolution(resolution.value)
      local vel = seqVelTable:getValue(index+1)
      local numSteps = numStepsBox.value
      local currentPosition = (index % numSteps) + 1
      print("Number of steps:", numSteps)
      print("Current pos:", currentPosition)
      for i,note in ipairs(notes) do
        playNote(note, vel, beat2ms(gate.value*p))
      end

      -- UPDATE POSITION TABLE AND INCREMENT POSITION
      positionTable:setValue((index - 1 + numSteps) % numSteps + 1, 0)
      positionTable:setValue(currentPosition, 1)
      index = (index + 1) % numSteps -- increment position

      -- CHECK FOR TWEAKLEVEL
      if tweakLevelKnob.value > 0 then
        -- STORE SNAPSHOT AT CURRENT POS
        snapshotsMenu.enabled = true
        prevSnapshotButton.enabled = true
        nextSnapshotButton.enabled = true
        storeSnapshotButton.enabled = true
        snapshotsMenu:setValue(currentPosition, false)
        local snapshot = {}
        for i,v in ipairs(tweakables) do
          table.insert(snapshot, {widget=v.widget,value=v.widget.value})
        end
        table.remove(snapshots, currentPosition)
        table.insert(snapshots, currentPosition, snapshot)
        print("Updated snapshot at index:", currentPosition)

        -- START TWEAKING
        print("Tweaklevel", tweakLevelKnob.value)
        local tweakablesForTwequencer = getTweakablesForTwequencer()
        if #tweakablesForTwequencer > 0 then
          for i = 1, getSpawnsFromResolution(resolution.value), 1 do
            tweakablesIndex = tweakablesIndex + 1 -- Increment
            if tweakablesIndex > #tweakablesForTwequencer then
              tweakablesIndex = math.random(#tweakablesForTwequencer) -- start over from random index
            end
            spawn(tweakWidget, tweakablesForTwequencer[tweakablesIndex], tweakLevelKnob.value, p)
            print("Spawn tweakWidget i/tweakablesIndex:", i, tweakablesIndex)
          end
        end
      end

      -- WAIT FOR NEXT BEAT
      waitBeat(p)
    end
  end

  function onNote(e)
    print("Note:", e.note, "Velocity:", e.velocity)
    if sequencerPlayMenu.value > 1 then
      table.insert(heldNotes, e)
      if #heldNotes == 1 then
          arpeg(arpId)
      end
    else
      postEvent(e)
    end
  end

  function onRelease(e)
    if sequencerPlayMenu.value > 1 then
      for i,v in ipairs(heldNotes) do
        if v.note == e.note then
          table.remove(heldNotes, i)
          if #heldNotes == 0 then
            clearPosition()
            resetTweakLevel()
            arpId = arpId + 1
          end
          break
        end
      end
    else
      postEvent(e)
    end
  end

  return tweqPanel
end
