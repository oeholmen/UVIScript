--------------------------------------------------------------------------------
-- TweakSynth
--------------------------------------------------------------------------------

local tweakables = {}
local storedPatches = {}
local storedPatch = {}
local patchesMenu = nil

--------------------------------------------------------------------------------
-- Synth engine elements
--------------------------------------------------------------------------------

-- LAYERS
local osc1Layer = Program.layers[1]
local osc2Layer = Program.layers[2]
local noiseLayer = Program.layers[3]

-- KEYGROUPS
local osc1Keygroup = osc1Layer.keygroups[1]
local osc2Keygroup = osc2Layer.keygroups[1]
local noiseKeygroup = noiseLayer.keygroups[1]

-- OSCILLATORS
local osc1 = osc1Keygroup.oscillators[1]
local osc2 = osc2Keygroup.oscillators[1]
local noiseOsc = noiseKeygroup.oscillators[1]

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

-- Korg Minilogue has the Xpander Filter on insert 3
local filterInsert1 = osc1Keygroup.inserts[3]
local filterInsert2 = osc2Keygroup.inserts[3]
local filterInsert3 = noiseKeygroup.inserts[3]

-- MACROS
local macros = {
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
  Program.modulations["Macro 60"],
  Program.modulations["Macro 61"],
  Program.modulations["Macro 62"],
  Program.modulations["Macro 63"]
}

local isAnalog = osc1.type == "MinBlepGenerator" and osc2.type == "MinBlepGenerator"
local isAnalog3Osc = osc1.type == "MinBlepGeneratorStack" and osc2.type == "MinBlepGenerator"
local isAnalogStack = osc1.type == "MinBlepGeneratorStack" and osc2.type == "MinBlepGeneratorStack"
local isWavetable = osc1.type == "WaveTableOscillator" and osc2.type == "WaveTableOscillator"
local isAdditive = osc1.type == "Additive" and osc2.type == "Additive"
local isFM = osc1.type == "FmOscillator" and osc2.type == "FmOscillator"
local isMinilogue = filterInsert1 and filterInsert1.type == "XpanderFilter"

-- SET SOME PARAMETER VALUES (OVERRIDE FALCON DEFAULT VALUES)
local polyphony = 16
Program:setParameter("Polyphony", polyphony)

if isAdditive then
  osc1:setParameter("CombFreq", 0.5)
  osc2:setParameter("CombFreq", 0.5)
  osc1:setParameter("FilterType", 3)
  osc2:setParameter("FilterType", 3)
  osc1:setParameter("SafeBass", true)
  osc2:setParameter("SafeBass", true)
end

print("Starting TweakSynth!")
print("Oscillator 1:", osc1.type)
print("Oscillator 2:", osc2.type)

if isMinilogue then
  print("Loading Korg Minilogue Midi CC mappings!")
end

--------------------------------------------------------------------------------
-- Name common macros
--------------------------------------------------------------------------------

local osc1Shape = macros[1]
local filterCutoff = macros[2]
local filterEnvAmount = macros[3]
local lfoFreqKeyFollow2 = macros[4]
local lfoFreqKeyFollow3 = macros[5]
local lfoToDetune = macros[6]
local osc1Mix = macros[8]
local osc2Shape = macros[9]
local osc2Mix = macros[10]
local osc2Detune = macros[11]
local osc2Pitch = macros[12]
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
local osc1LfoToPWM = macros[27]
local osc2LfoToPWM = macros[28]
local wheelToVibrato = macros[29]
local filterKeyTracking = macros[30]
local lfoToCutoff = macros[31]
local unisonDetune = macros[32]
local vibratoRate = macros[33]
local maximizer = macros[35]
local noiseMix = macros[36]
local lfoToAmp = macros[37]
local lfoFreqKeyFollow1 = macros[42]
local panSpread = macros[43]
local stereoSpread = macros[44]
local osc1Pitch = macros[45]
local lfoToPitchOsc1 = macros[46]
local lfoToPitchOsc2 = macros[47]
local filterEnvToPitchOsc1 = macros[48]
local filterEnvToPitchOsc2 = macros[49]
local hpfCutoff = macros[50]
local hpfResonance = macros[51]
local hpfKeyTracking = macros[52]
local hpfEnvAmount = macros[53]
local wheelToHpf = macros[54]
local atToHpf = macros[55]
local lfoToHpf = macros[56]
local phasorMix = macros[61]
local wheelToLfo = macros[62]

-- Name additive macros
local additiveMacros = {
  osc2EvenOdd = macros[7],
  lfoToOsc1Cutoff = macros[17],
  unisonVoices = macros[34],
  lfoToEvenOdd1 = macros[38],
  lfoToEvenOdd2 = macros[39],
  osc1FilterCutoff = macros[40],
  osc2FilterCutoff = macros[41],
  osc1EvenOdd = macros[57],
  filterEnvToCutoff1 = macros[58],
  filterEnvToCutoff2 = macros[59],
  lfoToOsc2Cutoff = macros[60]
}

-- Name analog macros
local analogMacros = {
  osc3LfoToPWM = macros[7],
  subOscMix = macros[17],
  randomPhaseStart = macros[34],
  lfoToHardsync1 = macros[38],
  lfoToHardsync2 = macros[39],
  filterEnvToHardsync1 = macros[40],
  filterEnvToHardsync2 = macros[41],
  lfoToPitchOsc3 = macros[57],
  atToHardsync1 = macros[58],
  filterEnvToPitchOsc3 = macros[59],
  filterDb = macros[60]
}

-- Name wavetable macros
local wavetableMacros = {
  lfoToWaveSpread1 = macros[7], 
  lfoToWaveSpread2 = macros[17], 
  unisonVoices = macros[34],
  lfoToWT1 = macros[38],
  lfoToWT2 = macros[39],
  filterEnvToWT1 = macros[40],
  filterEnvToWT2 = macros[41],
  waveSpread = macros[57],
  wheelToShape1 = macros[58],
  wheelToShape2 = macros[59],
  atToShape1 = macros[60],
  filterDb = macros[63]
}

-- Name FM macros
local FMMacros = {
  filterEnvToOsc1OpDLevel = macros[1],
  lfoToOsc1OpBLevel = macros[7],
  filterEnvToOsc2OpDLevel = macros[9],
  lfoToOsc1OpCLevel = macros[17],
  lfoToOsc1OpDLevel = macros[34],
  lfoToOsc2OpBLevel = macros[27],
  lfoToOsc2OpCLevel = macros[28],
  lfoToOsc2OpDLevel = macros[38],
  lfoToOsc1Feedback = macros[39],
  filterEnvToOsc1OpBLevel = macros[40],
  filterEnvToOsc1OpCLevel = macros[41],
  filterEnvToOsc2OpBLevel = macros[57],
  filterEnvToOsc2OpCLevel = macros[58],
  lfoToOsc2Feedback = macros[59],
  filterDb = macros[60],
  filterType = macros[63]
}

--------------------------------------------------------------------------------
-- Colours and margins
--------------------------------------------------------------------------------

local buttonAlpha = 0.9
local buttonBackgroundColourOff = "#ff084486"
local buttonBackgroundColourOn = "#ff02ACFE"
local buttonTextColourOff = "#ff22FFFF"
local buttonTextColourOn = "#efFFFFFF"

local outlineColour = "#FFB5FF"
local bgColor = "00000000"
local knobColour = "#dd000061"
local osc1Colour = outlineColour
local osc2Colour = outlineColour
local unisonColour = outlineColour
local filterColour = outlineColour
local lfoColour = outlineColour
local filterEnvColour = outlineColour
local ampEnvColour = outlineColour
local filterEffectsColour = outlineColour
local vibratoColour = outlineColour
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = bgColor

local marginX = 3 -- left/right
local marginY = 0 -- top/bottom
local height = 66
local width = 714

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
    table.insert(data, storedPatches)
  end
  print("Data stored: ", #data)
  return data
end

function onLoad(data)
  print("Loading data", #data)
  storedPatch = data[1] -- USE FOR DEFAULT VALUES
  print("storedPatch", #storedPatch)
  for _,v in ipairs(storedPatch) do
    print("Loaded: ", v.widget, v.value)
  end
  if type(data[2]) ~= "nil" then
    storedPatches = data[2]
    populatePatchesMenu()
    print("Loaded stored patches: ", #storedPatches)
  end
end

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

-- Topologies for FM synth
local topologies = {"D->C->B->A", "D+C->B->A", "C->B,B+D->A", "D->B+C->A", "D->C->A+B", "D->C->B,A", "B+C+D->A", "B->A,D->C", "D->A+B+C", "A,B,D->C", "A,B,C,D"}

-- Default probability that a tweakable will be skipped - used by twequencer and can be adjusted in settings for each parameter
local defaultSkipProbability = 0

-- Set maxLevel based on topology:
-- topology 0-3 > A
-- topology 4-5 > A+B
-- topology 6 > A
-- topology 7 > A+C
-- topology 8-9 > A+B+C
-- topology 10 > A+B+C+D
function getMaxFromTopology(op, topology)
  if op == 2 then
    if topology == 4 or topology == 5 or topology > 7 then
      return 1
    end
  end

  if op == 3 and topology > 6 then
    return 1
  end

  if op == 4 and topology == 10 then
    return 1
  end

  return 20
end

function initPatch()
  --print("Setting default values...")
  for _,v in ipairs(tweakables) do
    if v.widget.name == "NoiseType" then
      v.widget.value = 7
    else
      v.widget.value = v.widget.default
    end
    --print("Set default value for widget", v.widget.name, v.widget.value)
  end
end

function setWidgetValue(index, widgetName, value)
  if tweakables[index] and widgetName == tweakables[index].widget.name then
    tweakables[index].widget.value = value
    print("Set widget value: ", widgetName, tweakables[index].widget.value, value)
  end
end

function setWidgetTargetValue(index, widgetName, value)
  if tweakables[index] and widgetName == tweakables[index].widget.name then
    tweakables[index].targetValue = value
    print("Set target value: ", widgetName, value)
  end
end

function recallStoredPatch()
  print("Recalling stored patch...")
  for _,v in ipairs(storedPatch) do
    setWidgetValue(v.index, v.widget, v.value)
    print("Set value for widget", v.widget.name, v.value)
  end
end

function populatePatchesMenu()
  for i=1,#storedPatches do
    local itemName = "Snapshot "..i
    patchesMenu:addItem(itemName)
  end
end

function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" then
    local value = math.random(min, max)
    --print("Random - value, min, max:", value, min, max)
    return value
  elseif type(min) == "number" then
    local value = math.random(min)
    --print("Random - value, min:", value, min)
    return value
  end
  local value = math.random()
  --print("Random:", value)
  if type(factor) == "number" then
    value = value * factor
    --print("Random by factor:", value, factor)
  end
  return value
end

function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  local value = getRandom(100) <= probability
  --print("RandomBoolean:", value, probability)
  return value
end

-- Returns a probability that is derived from the given tweaklevel. The probability returned is reduced less the higher the tweak level is.
-- *NOTE* Use this when you want something to be more likely to occur on high tweak levels.
-- Tweaklevel 90 gives a probability of 81: 90 * 0.9 = 81 (reduced by 9)
-- Tweaklevel 30 gives a probability of 9: 30 * 0.3 = 9 (reduced by 21)
function getProbabilityFromTweakLevel(tweakLevel)
  return tweakLevel * (tweakLevel / 100)
end

-- Takes a level of uncertanty, a probability and an optional weight.
-- *NOTE* Use this when you want something to be more likely to occur on low tweak levels.
-- The given probability is adjusted according to the following rules:
-- The level of uncertanty (tweaklevel) is between 0 and 100 (0=no uncertanty,100=totaly random)
-- The given probability is between 0 and 100 (0=no chance, 100=always)
-- The given weight is above -50 and below 50, 0 is nutral weight (<0=lighter weight, probability less affected by tweaklevel, >0=stronger weight - probability more affected by tweaklevel)
-- If uncertanty level is high, the probability gets lower, adjusted by the weight
-- If uncertanty level is low, the probability gets higher, adjusted by the weight
-- At uncertanty level 50, no change is made
-- Should return a probability between 0 and 100
-- probility = p, tweaklevel = l:
  -- p + (0.5 - l/100) * p
-- A tweaklevel of 90 will adjust a probability of 80 like so (when no weight is given):
  -- factor = 0.5 - (90/100) = 0.5 - 0.9 = -0.4
  -- probability = 80 + (-0.4 * 80) = 80 + -32 = 48
-- A tweaklevel of 100 will adjust a probability of 50 in half:
  -- factor = 0.5 - (100/100) = 0.5 - 1 = -0.5
  -- probability = 50 + (-0.5 * 50) = 50 + -25 = 25
-- A tweaklevel of 30 will adjust a probability of 80 like so (when no weight is given):
  -- factor = 0.5 - (30/100) = 0.5 - 0.3 = 0.2
  -- probability = 80 + (0.2 * 80) = 80 + 16 = 96
-- A tweaklevel of 30 will adjust a probability of 80 with a weight of 25 like so:
  -- factor = 0.5 - (30/100) = 0.5 - 0.3 = 0.2
  -- factor = 0.2 + 0.025 = 0.225
  -- probability = 80 + (0.225 * 80) = 80 + 18 = 98
-- A tweaklevel of 30 will adjust a probability of 80 with a weight of 50 like so:
  -- factor = 0.5 - (30/100) = 0.5 - 0.3 = 0.2
  -- factor = 0.2 + 0.05 = 0.25
  -- probability = 80 + (0.25 * 80) = 80 + 20 = 100
-- A tweaklevel of 30 will adjust a probability of 80 with a weight of 0.1 like so:
  -- factor = 0.5 - (30/100) = 0.5 - 0.3 = 0.2
  -- factor = 0.2 + 0.01 = 0.21
  -- probability = 80 + (0.21 * 80) = 80 + 16.8 = 96.8 = 97
  -- x+(0.5-(y/100))
function adjustProbabilityByTweakLevel(tweakLevel, probability, weight)
  print("Probability/TweakLevel/Weight-in:", probability, tweakLevel, weight)

  -- If probability is 100, no adjustments are made
  if probability == 100 then
    --print("Probability is 100")
    return probability
  end

  -- Set default weight if not provided
  if type(weight) ~= "number" then
    weight = 0
  end

  -- Set the factor
  local factor = 0.5 - (tweakLevel / 100)

  -- Adjust for weight
  if factor > 0 then
    factor = factor + (weight / 1000)
  else
    factor = factor - (weight / 1000)
  end

  -- Calculate adjusted probability
  probability = math.floor(probability + (factor * probability))

  -- Ensure not above max
  if probability > 100 then
    probability = 100
  end

  -- Ensure not below min
  if probability < 0 then
    probability = 0
  end

  --print("Probability-weight:", weight)
  --print("Probability-factor:", factor)
  --print("Probability-out:", probability)

  return probability
end

function tweakValue(options, value, tweakLevel)
  if type(options.widget.default) ~= "number" or (type(options.default) == "number" and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, options.default))) then
    if options.widget.name == "NoiseType" then
      value = 7
    end
    return value
  end
  print("Tweaking value:", value)
  -- Get range limits
  local floor = options.widget.min -- Default floor is widget min
  local ceiling = options.widget.max -- Default ceiling is widget max
  -- Adjust value to within set range if probability hits
  if type(options.probability) == "number" and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, options.probability)) then
    if type(options.floor) == "number" then
      floor = options.floor
    end
    if type(options.ceiling) == "number" then
      ceiling = options.ceiling
    end
    print("Probability/floor/ceiling:", options.probability, floor, ceiling)
  end

  -- If probability is set to 100, we are forced to stay within the given range
  local forceRange = type(options.probability) == "number" and options.probability == 100

  -- If probability hits, we get a random value within the limits
  if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, 30, 15)) then
    print("Random limited range")
    return getValueBetween(floor, ceiling, value, options)
  end
  
  -- If probability hits, we get a random value within the full range
  if getRandomBoolean(getProbabilityFromTweakLevel(tweakLevel)) and forceRange == false then
    print("Random full range")
    return getRandom(options.min, options.max, options.factor)
  end

  -- Get widget range
  local range = ceiling - floor
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

function getEnvelopeTimeForDuration(options, duration)
  local min = options.widget.default * 10000 -- 0,001*10000 = 10
  local max = duration -- Duration is 0.25 = 1/16, 0.5 = 1/8, 1 = 1/4

  if options.release == true or options.decay == true then
    max = duration * 2
  end

  max = max * 1000 -- 0,25 * 1000 = 250

  if min > max then
    print("getEnvelopeTimeForDuration using default value:", options.widget.default)
    return options.widget.default
  end

  print("getEnvelopeTimeForDuration duration/min/max:", duration, min/10000, max/10000)

  return getRandom(min, max) / 10000
end

function getEnvelopeTimeByStyle(options, style)
  local index = style - 1
  -- {"Automatic", "Very short", "Short", "Medium short", "Medium", "Medium long", "Long", "Very long"}
  local attackTimes = {{0.00025,0.0025},{0.001,0.0075},{0.005,0.025},{0.01,0.25},{0.1,0.75},{0.5,2},{1.1,3.5}}
  local decayTimes = {{0.025,0.25},{0.1,0.5},{0.2,0.6},{0.4,1.2},{0.9,2.5},{1.5,3.5},{2.5,5.5}}
  local releaseTimes = {{0.0025,0.01},{0.01,0.075},{0.05,0.125},{0.075,0.35},{0.1,0.75},{0.5,2},{0.9,2.5}}
  local min = attackTimes[index][1]
  local max = attackTimes[index][2]

  if options.release == true then
    min = releaseTimes[index][1]
    max = releaseTimes[index][2]
  elseif options.decay == true then
    min = decayTimes[index][1]
    max = decayTimes[index][2]
  end
  
  print("getEnvelopeTimeByStyle min/max:", min, max)
  
  return getRandom(min*100000, max*100000)/100000
end

function getModulationFreqByStyle(options, style)
  local index = style - 1
  local freq = {{15.5,20.},{12.5,16.5},{8.5,13.5},{5.,9.5},{3.1,7.1},{1.5,3.5},{0.1,2.5}}
  local min = freq[index][1]
  local max = freq[index][2]
  
  print("getModulationFreqByStyle min/max:", min, max)
  
  return getRandom(min, max)
end

function getValueBetween(floor, ceiling, originalValue, options, maxRounds)
  -- Set startvalue
  local value = originalValue
  
  -- Generate values until we hit the window
  local rounds = 0 -- Counter for rounds
  
  -- Set options if not provided
  if type(options) == "nil" then
    options = {}
  end

  -- Set max rounds if not provided
  if type(maxRounds) ~= "number" then
    maxRounds = 25
  end

  print("getValueBetween floor, ceiling, startvalue, maxrounds:", floor, ceiling, value, maxRounds)
  while rounds < maxRounds and (value < floor or value > ceiling) do
    value = getRandom(options.min, options.max, options.factor)
    rounds = rounds + 1 -- Increment rounds
  end
  
  -- Return the new value if we hit the target
  if value >= floor and value <= ceiling then
    print("getValueBetween found value in rounds:", value, rounds)
    return value
  end

  return originalValue
end

-- Get the widgets to tweak
function getTweakables(tweakLevel, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton, twequencer)
  if type(twequencer) ~= "boolean" then
    -- Set twequencer to false, if not given as an argument
    twequencer = false
  end
  local t = {}
  for _,v in ipairs(tweakables) do
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
    -- If we are getting tweakables for the twequencer, some random parameters should be skipped
    if type(v.skipProbability) ~= "number" then
      v.skipProbability = defaultSkipProbability
    end
    local probability = adjustProbabilityByTweakLevel(tweakLevel, v.skipProbability, 5) -- Used for random skip
    if skip == false and twequencer == true then
      skip = getRandomBoolean(probability)
    end
    v.targetValue = v.widget.value -- Ensure a target value is set
    if skip == true or v.widget.enabled == false or (twequencer == true and v.excludeWithTwequencer == true) then
      print("Skipping:", v.widget.name)
    else
      table.insert(t, v)
    end
  end

  print("Widgets ready:", #t)

  return t
end

-- Perform tweak
function tweakWidget(options, duration, useDuration)
  if type(duration) ~= "number" then
    -- Set duration to 0, if not given as an argument
    duration = 0
  end
  if type(useDuration) ~= "boolean" then
    -- Set useDuration to false, if not given as an argument
    useDuration = false
  end
  if type(options.widget.useDuration) == "boolean" then
    -- Override useDuration if set in options for this widget
    useDuration = options.useDuration
  end
  if type(options.targetValue) == "nil" then
    options.targetValue = options.widget.value
  end
  print("******************** Tweaking:", options.widget.name, "********************")
  local startValue = options.widget.value
  local endValue = options.targetValue
  print("Start value:", startValue)
  print("End value:", endValue)
  if startValue == endValue then
    print("No change")
    return
  end
  if duration == 0 or useDuration == false or type(endValue) ~= "number" then
    options.widget.value = endValue
    print("Tweaking without duration")
    return
  end
  local durationInMilliseconds = beat2ms(duration) -- * 0.8
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
      if startValue > endValue then
        break
      end
      options.widget.value = options.widget.value + changePerStep
      wait(millisecondsPerStep)
    end
  else
    print("Decrement per step:", changePerStep)
    for i = 1, numberOfSteps-1 do
      if startValue < endValue then
        break
      end
      options.widget.value = options.widget.value - changePerStep
      wait(millisecondsPerStep)
    end
  end
  options.widget.value = endValue
  print("Tweak widget/startValue/endValue/duration:", options.widget.name, startValue, endValue, duration)
end

-- Tweak options:
  -- widget = the widget to tweak - the only non-optional parameter
  -- func = the function to execute for getting the value - default is getRandom
  -- factor = a factor to multiply the random value with
  -- floor = the lowest value
  -- ceiling = the highest value
  -- probability = the probability (affected by tweak level) that value is within limits (floor/ceiling) - probability is passed to any custom func
  -- zero = the probability that the value is set to 0
  -- excludeWithTwequencer = if ran with twequencer, this widget is excluded
  -- useDuration = if ran with a duration, this widget will tweak it's value over the length of the given duration
  -- defaultTweakRange = the range to use when tweaking default/stored value - if not provided, the full range is used
  -- default = the probability that the default/stored value is used (affected by tweak level)
  -- min = min value
  -- max = max value
  -- fmLevel = tweak as fm operator level if probability hits
  -- valueFilter = a table of allowed values. Incoming values are adjusted to the closest value of the valuefilter.
  -- absoluteLimit = the highest allowed limit - used mainly for safety resons to avoid extreme levels
  -- category = the category the widget belongs to (synthesis, modulation, filter, mixer, effects)
--
-- Example: table.insert(tweakables, {widget=driveKnob,floor=0,ceiling=0.5,probability=90,zero=50,useDuration=true})
function getTweakSuggestion(options, tweakLevel, envelopeStyle, modulationStyle, duration)
  if type(tweakLevel) ~= "number" then
    tweakLevel = 50
  end
  if type(envelopeStyle) ~= "number" then
    envelopeStyle = 1
  end
  if type(modulationStyle) ~= "number" then
    modulationStyle = 1
  end
  if type(duration) ~= "number" then
    duration = 0
  end
  print("******************** Getting tweak suggestion:", options.widget.name, "********************")
  print("Tweak level:", tweakLevel)
  local startValue = options.widget.value
  local endValue = startValue
  print("Start value:", startValue)
  print("Envelope style:", envelopeStyle)
  if type(options.func) == "function" then
    endValue = options.func(options.probability)
    print("From func:", endValue, options.probability)
  elseif type(options.zero) == "number" and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, options.zero)) then
    -- Set to zero if probability hits
    endValue = 0
    print("Zero:", options.zero)
  elseif type(options.default) == "number" and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, options.default)) then
    -- Set to the default value if probability hits
    endValue = options.widget.default
    print("Default:", options.default)
  elseif modulationStyle > 1 and (options.widget.name == 'LfoFreq') then
    endValue = getModulationFreqByStyle(options, modulationStyle)
    print("getModulationFreqByStyle:", endValue)
  elseif envelopeStyle > 1 and (options.attack == true or options.decay == true or options.release == true) then
    endValue = getEnvelopeTimeByStyle(options, envelopeStyle)
    print("getEnvelopeTimeByStyle:", endValue)
  elseif duration > 0 and envelopeStyle == 1 and (options.attack == true or options.decay == true or options.release == true) then
    -- Tweak like normal if probability hits
    if type(options.probability) == "number" and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, options.probability)) then
      endValue = tweakValue(options, startValue, tweakLevel)
      print("getEnvelopeTime:", endValue)
    else
      endValue = getEnvelopeTimeForDuration(options, duration)
      print("getEnvelopeTimeForDuration:", endValue)
    end
  elseif type(options.fmLevel) == "number" and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, options.fmLevel)) then
    endValue = getRandom(nil, nil, options.widget.max)
    print("FM Operator Level: (max/endValue)", options.widget.max, endValue)
  else
    endValue = tweakValue(options, startValue, tweakLevel)
    print("Found tweakValue:", endValue)
  end
  if type(options.valueFilter) == "table" then
    print("Applying valueFilter to:", endValue)
    endValue = applyValueFilter(options.valueFilter, endValue)
  end
  if type(options.bipolar) == "number" and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, options.bipolar)) then
    if getRandom(100) <= options.bipolar then
      endValue = -endValue
      print("Value converted to negative", options.bipolar)
    end
  end
  if type(options.absoluteLimit) == "number" and type(endValue) == "number" and endValue > options.absoluteLimit then
    print("End value limited by absoluteLimit", options.absoluteLimit)
    endValue = options.absoluteLimit
  end
  print("Tweak endValue:", endValue)
  return endValue
end

-- Verify the suggested settings to avoid unwanted side effects
function verifySettings(tweakLevel, selectedTweakables, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton, automaticSequencerRunning)
  if type(automaticSequencerRunning) ~= "boolean" then
    automaticSequencerRunning = false
  end
  if modulationButton.value == true then
    if (automaticSequencerRunning and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, 75))) or getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevel, 20)) then
      for _,v in ipairs(selectedTweakables) do
        if v.category == "modulation" then
          if automaticSequencerRunning then
            v.widget.value = v.widget.default
          end
          v.targetValue = v.widget.default
        end
      end
    end
  end
  -- Verify unison/opLevel settings
  if synthesisButton.value == true then
    verifyOpLevelSettings(selectedTweakables)
    verifyUnisonSettings(selectedTweakables)
  end
  -- Verify filter settings
  if filterButton.value == true then
    verifyFilterSettings(selectedTweakables)
  end
  -- Verify mixer settings
  if mixerButton.value == true then
    verifyMixerSettings(selectedTweakables)
  end
end

function verifyOpLevelSettings(selectedTweakables)
  if isFM == false then
    return
  end
  local max = 1

  print("--- Checking Osc 1 Operator Levels ---")
  local Osc1Topology = getTweakable("Osc1Topology", selectedTweakables)
  local Osc1OpBLvl = getTweakable("Osc1LevelOpB", selectedTweakables)
  local Osc1OpCLvl = getTweakable("Osc1LevelOpC", selectedTweakables)
  local Osc1OpDLvl = getTweakable("Osc1LevelOpD", selectedTweakables)

  max = getMaxFromTopology(2, Osc1Topology.targetValue)
  if max < Osc1OpBLvl.targetValue then
    Osc1OpBLvl.targetValue = max
    print("Osc1OpBLvlm was adjusted to max", max)
  end

  max = getMaxFromTopology(3, Osc1Topology.targetValue)
  if max < Osc1OpCLvl.targetValue then
    Osc1OpCLvl.targetValue = max
    print("Osc1OpCLvl was adjusted to max", max)
  end

  max = getMaxFromTopology(4, Osc1Topology.targetValue)
  if max < Osc1OpDLvl.targetValue then
    Osc1OpDLvl.targetValue = max
    print("Osc1OpDLvl was adjusted to max", max)
  end
  
  print("--- Checking Osc 2 Operator Levels ---")
  local Osc2Topology = getTweakable("Osc2Topology", selectedTweakables)
  local Osc2OpBLvl = getTweakable("Osc2LevelOpB", selectedTweakables)
  local Osc2OpCLvl = getTweakable("Osc2LevelOpC", selectedTweakables)
  local Osc2OpDLvl = getTweakable("Osc2LevelOpD", selectedTweakables)

  max = getMaxFromTopology(2, Osc2Topology.targetValue)
  if max < Osc2OpBLvl.targetValue then
    Osc2OpBLvl.targetValue = max
    print("Osc2OpBLvl was adjusted to max", max)
  end

  max = getMaxFromTopology(3, Osc2Topology.targetValue)
  if max < Osc2OpCLvl.targetValue then
    Osc2OpCLvl.targetValue = max
    print("Osc2OpCLvl was adjusted to max", max)
  end

  max = getMaxFromTopology(4, Osc2Topology.targetValue)
  if max < Osc2OpDLvl.targetValue then
    Osc2OpDLvl.targetValue = max
    print("Osc2OpDLvl was adjusted to max", max)
  end
end

function verifyUnisonSettings(selectedTweakables)
  local UnisonVoices = getTweakable("UnisonVoices", selectedTweakables)
  local UnisonDetune = getTweakable("UnisonDetune", selectedTweakables)

  if type(UnisonVoices) == "nil" or type(UnisonDetune) == "nil" then
    return
  end

  local factor = UnisonVoices.targetValue * 0.1

  print("--- Checking Unison Settings ---")
  print("UnisonVoices:", UnisonVoices.targetValue)
  print("UnisonDetune:", UnisonDetune.targetValue)
  print("Factor:", factor)

  if UnisonVoices.targetValue == 1 then
    UnisonDetune.targetValue = UnisonDetune.default
    print("Unison off - detune set to default value:", UnisonDetune.targetValue)
  elseif UnisonDetune.targetValue > factor then
    local floor = UnisonDetune.default / 2
    local ceiling = UnisonDetune.default + factor
    UnisonDetune.targetValue = getValueBetween(floor, ceiling, UnisonDetune.targetValue)
    print("UnisonDetune adjusted to:", UnisonDetune.targetValue)
  else
    print("Unison Settings OK")
  end
end

function verifyMixerSettings(selectedTweakables)
  local Osc1Mix = getTweakable("Osc1Mix", selectedTweakables)
  local Osc2Mix = getTweakable("Osc2Mix", selectedTweakables)
  local Osc3Mix = getTweakable("Osc3Mix", selectedTweakables)
  local SubOscMix = getTweakable("SubOscMix", selectedTweakables)

  print("--- Checking Mixer Settings ---")
  print("Osc1Mix:", Osc1Mix.targetValue)
  print("Osc2Mix:", Osc2Mix.targetValue)

  if Osc3Mix then
    print("Osc3Mix:", Osc3Mix.targetValue)

    if Osc3Mix.targetValue > 0 and Osc3Mix.targetValue < 0.6 then
      Osc3Mix.targetValue = getValueBetween(0.65, 0.8, Osc3Mix.targetValue)
      print("Osc3Mix adjusted to:", Osc3Mix.targetValue)
    end
  end

  if SubOscMix then
    print("SubOscMix:", SubOscMix.targetValue)

    if SubOscMix.targetValue > 0.2 and SubOscMix.targetValue < 0.7 then
      SubOscMix.targetValue = getValueBetween(0.7, 0.9, SubOscMix.targetValue)
      print("SubOscMix adjusted to:", SubOscMix.targetValue)
    elseif SubOscMix.targetValue < 0.2 then
      SubOscMix.targetValue = 0
      print("SubOscMix adjusted to:", SubOscMix.targetValue)
    end
  end

  if Osc2Mix.targetValue == 0 and Osc1Mix.targetValue < 0.6 then
    Osc1Mix.targetValue = getValueBetween(0.65, 0.8, Osc1Mix.targetValue)
    print("Osc1Mix adjusted to:", Osc1Mix.targetValue)
  elseif Osc1Mix.targetValue < 0.6 and Osc2Mix.targetValue < 0.6 then
    Osc1Mix.targetValue = getValueBetween(0.6, 0.8, Osc1Mix.targetValue)
    print("Osc1Mix adjusted to:", Osc1Mix.targetValue)
    Osc2Mix.targetValue = getValueBetween(0.6, 0.8, Osc2Mix.targetValue)
    print("Osc2Mix adjusted to:", Osc2Mix.targetValue)
  elseif Osc1Mix.targetValue < 0.6 or Osc2Mix.targetValue < 0.6 then
    if math.min(Osc1Mix.targetValue, Osc2Mix.targetValue) == Osc1Mix.targetValue then
      Osc1Mix.targetValue = getValueBetween(0.6, 0.8, Osc1Mix.targetValue)
      print("Osc1Mix adjusted to:", Osc1Mix.targetValue)
    else
      Osc2Mix.targetValue = getValueBetween(0.6, 0.8, Osc2Mix.targetValue)
      print("Osc2Mix adjusted to:", Osc2Mix.targetValue)
    end
  else
    print("Mixer Settings OK")
  end
end

--[[ function getTweakable(name, selectedTweakables)
  for _,v in ipairs(selectedTweakables) do
    if v.widget.name == name then
      return v
    end
  end
end ]]

function getTweakable(name, selectedTweakables)
  for _,v in ipairs(tweakables) do
    if v.widget.name == name then
      return v
    end
  end
end

function verifyFilterSettings(selectedTweakables)
  local Cutoff = getTweakable("Cutoff", selectedTweakables)
  local HpfCutoff = getTweakable("HpfCutoff", selectedTweakables)
  local EnvelopeAmt = getTweakable("EnvelopeAmt", selectedTweakables)
  local HpfEnvelopeAmt = getTweakable("HpfEnvelopeAmt", selectedTweakables)
  local FAttack = getTweakable("FAttack", selectedTweakables)
  local changes = 0
  local envelopeAmtValue = EnvelopeAmt.targetValue
  local cutoffValue = Cutoff.targetValue
  local hpfEnvelopeAmtValue = HpfEnvelopeAmt.targetValue
  local attackValue = FAttack.targetValue

  print("--- Checking Filter Settings ---")
  print("Filter Cutoff:", cutoffValue)
  print("Filter EnvelopeAmt:", envelopeAmtValue)
  print("Filter HpfCutoff:", HpfCutoff.targetValue)
  print("Filter HpfEnvelopeAmt:", hpfEnvelopeAmtValue)
  print("Filter FAttack:", attackValue)

  -- Reduce cutoff if env amount is high
  if cutoffValue == 1 and envelopeAmtValue > 0.3 then
    cutoffValue = getValueBetween(0.2, 0.8, cutoffValue)
  end

  -- Increase env amount of cutoff is low
  if cutoffValue < 0.25 and envelopeAmtValue < 0.25 then
    --cutoffValue = getValueBetween(0.1, 0.6, cutoffValue)
    envelopeAmtValue = getValueBetween(0.65, 0.95, envelopeAmtValue)
  end
  
  -- Reduce long attack time if cutoff is low and env amt is high
  if cutoffValue < 0.05 and envelopeAmtValue > 0.75 and attackValue > 0.75 then
    attackValue = getValueBetween(0.01, 0.7, attackValue)
  end

  -- Check hpf amt
  if HpfCutoff.targetValue > 0.65 and hpfEnvelopeAmtValue >= 0 then
    hpfEnvelopeAmtValue = -(getValueBetween(0.1, 0.8, attackValue))
  end

  -- Set cutoff value if changed
  if cutoffValue ~= Cutoff.targetValue then
    print("Adjusting lfp cutoff to:", cutoffValue)
    Cutoff.targetValue = cutoffValue
    changes = changes + 1
  end

  if envelopeAmtValue ~= EnvelopeAmt.targetValue then
    print("Adjusting lfp env amount to:", envelopeAmtValue)
    EnvelopeAmt.targetValue = envelopeAmtValue
    changes = changes + 1
  end

  if attackValue ~= FAttack.targetValue then
    print("Adjusting filter env attack to:", attackValue)
    FAttack.targetValue = attackValue
    changes = changes + 1
  end

  if hpfEnvelopeAmtValue ~= HpfEnvelopeAmt.targetValue then
    print("Adjusting hpf env amt to:", hpfEnvelopeAmtValue)
    HpfEnvelopeAmt.targetValue = hpfEnvelopeAmtValue
    changes = changes + 1
  end

  if changes == 0 then
    print("Filter Settings OK")
  end
end

function applyValueFilter(valueFilter, startValue)
  local endValue = startValue
  local index = 0
  -- Try to find value in filter
  for i,v in ipairs(valueFilter) do
    if endValue == v then
      index = i
      break
    end
  end
  -- If value is not found in the value filter, we select a random value from the filter
  if index == 0 then
    if #valueFilter > 1 then
      index = getRandom(#valueFilter)
    else
      index = 1
    end
  end
  endValue = valueFilter[index]

  if endValue ~= startValue then
    print("Value adjusted by valueFilter to:", endValue)
  else
    print("No adjustments were made by the valueFilter")
  end

  return endValue
end

function getDotted(value)
  return value + (value / 2)
end

function getTriplet(value)
  return value  / 3
end

local selectedArpResolutions = {} -- Must be at the global level
local selectedSeqResolutions = {} -- Must be at the global level
local resolutions = {
  128, -- "32x" -- 0
  64, -- "16x" -- 1
  32, -- "8x" -- 2
  28, -- "7x" -- 3
  24, -- "6x" -- 4
  20, -- "5x" -- 5
  16, -- "4x" -- 6 <---- FROM HERE: ADD 1 to index to get arp res
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
local even = {}
local dot = {}
local tri = {}
local waveforms = {"Saw", "Square", "Triangle", "Sine", "Noise", "Pulse"}

function setResGroups()
  local i = 11 -- Start at 1/1 (pos 11)
  while true do
    table.insert(even, i)
    i = i + 1
    if i >= #resolutions then
      return
    end
    table.insert(dot, i)
    i = i + 1
    if i >= #resolutions then
      return
    end
    table.insert(tri, i)
    i = i + 1
    if i >= #resolutions then
      return
    end
  end
end
setResGroups()

function getResolutionIndex(i)
  if i > #resolutions then
    -- If Random is selected, we pick one of the selected resolutions
    local activeResolutions = {}
    for j,v in ipairs(selectedSeqResolutions) do
      if v == true then
        table.insert(activeResolutions, j)
      end
    end
    if #activeResolutions > 0 then
      i = activeResolutions[getRandom(#activeResolutions)]
      print("activeResolutions", #activeResolutions, i, resolutionNames[i])
    else
      i = getRandom(#resolutions)
    end
  end
  return i
end

function getResolution(i)
  i = getResolutionIndex(i)
  print("getResolution", resolutionNames[i])
  return resolutions[i]
end

function getResolutionName(i)
  return resolutionNames[i]
end

function getResolutionNames(options)
  local res = {}

  for _,r in ipairs(resolutionNames) do
    table.insert(res, r)
  end

  -- Add any options
  if type(options) == "table" then
    for _,o in ipairs(options) do
      table.insert(res, o)
    end
  end

  return res
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

function getWidget(name)
  for _,v in ipairs(tweakables) do
    if v.widget.name == name then
      return v.widget
    end
  end
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
-- Page Panel
--------------------------------------------------------------------------------

local pagePanel = Panel("PagePanel")
pagePanel.backgroundColour = "#cf000000"
pagePanel.x = 0
pagePanel.y = 340
pagePanel.width = 720
pagePanel.height = 38

local pageButtonSize = {97,27}
local spacing = 3
local pageButtonAlpha = 1
local pageButtonBackgroundColourOff = "#9f4A053B"
local pageButtonBackgroundColourOn = "#cfC722AF"
local pageButtonTextColourOff = "silver"
local pageButtonTextColourOn = "white"

local patchmakerPageButton = pagePanel:OnOffButton("PatchmakerPage", true)
patchmakerPageButton.alpha = pageButtonAlpha
patchmakerPageButton.backgroundColourOff = pageButtonBackgroundColourOff
patchmakerPageButton.backgroundColourOn = pageButtonBackgroundColourOn
patchmakerPageButton.textColourOff = pageButtonTextColourOff
patchmakerPageButton.textColourOn = pageButtonTextColourOn
patchmakerPageButton.displayName = "Patchmaker"
patchmakerPageButton.persistent = false
patchmakerPageButton.size = pageButtonSize
patchmakerPageButton.x = spacing

local twequencerPageButton = pagePanel:OnOffButton("TwequencerPage", false)
twequencerPageButton.alpha = pageButtonAlpha
twequencerPageButton.backgroundColourOff = pageButtonBackgroundColourOff
twequencerPageButton.backgroundColourOn = pageButtonBackgroundColourOn
twequencerPageButton.textColourOff = pageButtonTextColourOff
twequencerPageButton.textColourOn = pageButtonTextColourOn
twequencerPageButton.displayName = "Twequencer"
twequencerPageButton.persistent = false
twequencerPageButton.size = pageButtonSize
twequencerPageButton.x = patchmakerPageButton.x + patchmakerPageButton.width + spacing

local synthesisPageButton = pagePanel:OnOffButton("SynthesisPage", false)
synthesisPageButton.alpha = pageButtonAlpha
synthesisPageButton.backgroundColourOff = pageButtonBackgroundColourOff
synthesisPageButton.backgroundColourOn = pageButtonBackgroundColourOn
synthesisPageButton.textColourOff = pageButtonTextColourOff
synthesisPageButton.textColourOn = pageButtonTextColourOn
synthesisPageButton.displayName = "Synthesis"
synthesisPageButton.persistent = false
synthesisPageButton.size = pageButtonSize
synthesisPageButton.x = twequencerPageButton.x + twequencerPageButton.width + spacing

local filterPageButton = pagePanel:OnOffButton("FilterPage", false)
filterPageButton.alpha = pageButtonAlpha
filterPageButton.backgroundColourOff = pageButtonBackgroundColourOff
filterPageButton.backgroundColourOn = pageButtonBackgroundColourOn
filterPageButton.textColourOff = pageButtonTextColourOff
filterPageButton.textColourOn = pageButtonTextColourOn
filterPageButton.displayName = "Filters"
filterPageButton.persistent = false
filterPageButton.size = pageButtonSize
filterPageButton.x = synthesisPageButton.x + synthesisPageButton.width + spacing

local modulationPageButton = pagePanel:OnOffButton("ModulationPage", false)
modulationPageButton.alpha = pageButtonAlpha
modulationPageButton.backgroundColourOff = pageButtonBackgroundColourOff
modulationPageButton.backgroundColourOn = pageButtonBackgroundColourOn
modulationPageButton.textColourOff = pageButtonTextColourOff
modulationPageButton.textColourOn = pageButtonTextColourOn
modulationPageButton.displayName = "Modulation"
modulationPageButton.persistent = false
modulationPageButton.size = pageButtonSize
modulationPageButton.x = filterPageButton.x + filterPageButton.width + spacing

local effectsPageButton = pagePanel:OnOffButton("EffectsPage", false)
effectsPageButton.alpha = pageButtonAlpha
effectsPageButton.backgroundColourOff = pageButtonBackgroundColourOff
effectsPageButton.backgroundColourOn = pageButtonBackgroundColourOn
effectsPageButton.textColourOff = pageButtonTextColourOff
effectsPageButton.textColourOn = pageButtonTextColourOn
effectsPageButton.displayName = "Effects"
effectsPageButton.persistent = false
effectsPageButton.size = pageButtonSize
effectsPageButton.x = modulationPageButton.x + modulationPageButton.width + spacing

local settingsPageButton = pagePanel:OnOffButton("SettingsPage", false)
settingsPageButton.alpha = pageButtonAlpha
settingsPageButton.backgroundColourOff = pageButtonBackgroundColourOff
settingsPageButton.backgroundColourOn = pageButtonBackgroundColourOn
settingsPageButton.textColourOff = pageButtonTextColourOff
settingsPageButton.textColourOn = pageButtonTextColourOn
settingsPageButton.displayName = "Settings"
settingsPageButton.persistent = false
settingsPageButton.size = pageButtonSize
settingsPageButton.x = effectsPageButton.x + effectsPageButton.width + spacing

--------------------------------------------------------------------------------
-- Osc Panel Functions
--------------------------------------------------------------------------------

function createStackOscPanel(oscPanel, oscillatorNumber)
  local maxOscillators = 8
  local osc

  if oscillatorNumber == 1 then
    osc = osc1
  else
    osc = osc2
  end

  local stackShapeKnob = oscPanel:Knob("Osc"..oscillatorNumber.."Wave", 1, 1, 6, true)
  stackShapeKnob.displayName = "Waveform"
  stackShapeKnob.fillColour = knobColour
  stackShapeKnob.outlineColour = osc1Colour
  stackShapeKnob.changed = function(self)
    for i=1,maxOscillators do
      osc:setParameter("Waveform"..i, self.value)
    end
    self.displayText = waveforms[self.value]
  end
  stackShapeKnob:changed()
  table.insert(tweakables, {widget=stackShapeKnob,min=6,default=10,useDuration=true,category="synthesis"})

  local stackOctKnob = oscPanel:Knob("Osc"..oscillatorNumber.."Octave", 0, -2, 2, true)
  stackOctKnob.displayName = "Octave"
  stackOctKnob.fillColour = knobColour
  stackOctKnob.outlineColour = osc1Colour
  stackOctKnob.changed = function(self)
    for i=1,maxOscillators do
      osc:setParameter("Octave"..i, self.value)
    end
  end
  stackOctKnob:changed()
  table.insert(tweakables, {widget=stackOctKnob,min=-2,max=2,default=80,zero=25,category="synthesis"})

  local stackPitchKnob = oscPanel:Knob("PitchStack"..oscillatorNumber.."Osc", 0, -48, 48)
  stackPitchKnob.displayName = "Pitch"
  stackPitchKnob.mapper = Mapper.Quadratic
  stackPitchKnob.fillColour = knobColour
  stackPitchKnob.outlineColour = osc1Colour
  stackPitchKnob.changed = function(self)
    for i=1,maxOscillators do
      osc:setParameter("Pitch"..i, self.value)
    end
  end
  stackPitchKnob:changed()
  table.insert(tweakables, {widget=stackPitchKnob,min=-24,max=24,valueFilter={-24,-12,-5,0,7,12,19,24},floor=-12,ceiling=12,probability=75,default=50,zero=50,useDuration=true,category="synthesis"})
end

function setStackVoices(oscillators, unisonDetune, stereoSpread, phaseSpread)
  for i=1,8 do
    osc1:setParameter("Bypass"..i, (oscillators<i))
    osc1:setParameter("Gain"..i, 1 - ((oscillators/10) / 2))
    osc2:setParameter("Bypass"..i, (oscillators<i))
    osc2:setParameter("Gain"..i, 1 - ((oscillators/10) / 2))
  end

  -- DETUNE
  if oscillators == 1 then
    osc1:setParameter("FineTune1", 0)
    osc2:setParameter("FineTune1", 0)
  else
    local spreadPerOscillator = (unisonDetune * 100) / oscillators
    local currentSpread = spreadPerOscillator
    for i=1,oscillators do
      local spreadValue = currentSpread
      local spreadValueOsc1 = spreadValue
      local spreadValueOsc2 = spreadValue
      if i%2 == 0 then
        spreadValueOsc1 = -(spreadValue)
        spreadValueOsc2 = spreadValue
        currentSpread = currentSpread + spreadPerOscillator
      else
        spreadValueOsc1 = spreadValue
        spreadValueOsc2 = -(spreadValue)
      end
      osc1:setParameter("FineTune"..i, spreadValueOsc1)
      osc2:setParameter("FineTune"..i, spreadValueOsc2)
    end
  end

  -- STEREO SPREAD
  if oscillators == 1 then
    osc1:setParameter("Pan1", 0)
    osc2:setParameter("Pan1", 0)
  else
    local spreadPerOscillator = stereoSpread / oscillators
    local currentSpread = spreadPerOscillator
    for i=1,oscillators do
      local spreadValue = currentSpread
      local spreadValueOsc1 = spreadValue
      local spreadValueOsc2 = spreadValue
      if i%2 == 0 then
        spreadValueOsc1 = -(spreadValue)
        spreadValueOsc2 = spreadValue
        currentSpread = currentSpread + spreadPerOscillator
      else
        spreadValueOsc1 = spreadValue
        spreadValueOsc2 = -(spreadValue)
      end
      osc1:setParameter("Pan"..i, spreadValueOsc1)
      osc2:setParameter("Pan"..i, spreadValueOsc2)
    end
  end

  -- PHASE SPREAD
  if oscillators == 1 then
    osc1:setParameter("StartPhase1", 0)
    osc2:setParameter("StartPhase1", 0)
  else
    local spreadPerOscillator = phaseSpread / oscillators
    local currentSpread = spreadPerOscillator
    for i=1,oscillators do
      --print("currentSpread:", currentSpread, i)
      osc1:setParameter("StartPhase1"..i, spreadValue)
      osc2:setParameter("StartPhase1"..i, spreadValue)
      currentSpread = currentSpread + spreadPerOscillator
    end
  end
end

local analog3OscSoloButtons = {}
function createAnalog3OscPanel(oscPanel, oscillatorNumber)
  local muteOscButton = oscPanel:OnOffButton("MuteOsc"..oscillatorNumber, false)
  muteOscButton.x = 5
  muteOscButton.y = 25
  muteOscButton.tooltip = "Mute Osc "..oscillatorNumber
  muteOscButton.displayName = "Mute"
  muteOscButton.width = 40
  muteOscButton.alpha = buttonAlpha
  muteOscButton.backgroundColourOff = buttonBackgroundColourOff
  muteOscButton.backgroundColourOn = buttonBackgroundColourOn
  muteOscButton.textColourOff = buttonTextColourOff
  muteOscButton.textColourOn = buttonTextColourOn
  muteOscButton.changed = function(self)
    osc1:setParameter("Bypass"..oscillatorNumber, self.value)
  end
  muteOscButton:changed()

  local soloOscButton = oscPanel:OnOffButton("SoloOsc"..oscillatorNumber, false)
  soloOscButton.x = muteOscButton.x + muteOscButton.width + 5
  soloOscButton.y = muteOscButton.y
  soloOscButton.tooltip = "Solo Osc "..oscillatorNumber
  soloOscButton.displayName = "Solo"
  soloOscButton.width = 40
  soloOscButton.alpha = buttonAlpha
  soloOscButton.backgroundColourOff = buttonBackgroundColourOff
  soloOscButton.backgroundColourOn = buttonBackgroundColourOn
  soloOscButton.textColourOff = buttonTextColourOff
  soloOscButton.textColourOn = buttonTextColourOn
  soloOscButton.changed = function(self)
    local hasSoloedOscs = false
    for i=1,3 do
      local bypass = true
      if analog3OscSoloButtons[i].value == true then
        bypass = false
        hasSoloedOscs = true
      end
      osc1:setParameter("Bypass"..i, bypass)
    end
    -- If no soloed oscillators remain, all bypasses must be cleared
    if hasSoloedOscs == false then
      for i=1,3 do
        osc1:setParameter("Bypass"..i, false)
      end
    end
  end
  table.insert(analog3OscSoloButtons, soloOscButton)

  local oscShapeKnob = oscPanel:Knob("Osc"..oscillatorNumber.."Wave", 1, 1, 6, true)
  oscShapeKnob.displayName = "Waveform"
  oscShapeKnob.fillColour = knobColour
  oscShapeKnob.outlineColour = osc1Colour
  oscShapeKnob.changed = function(self)
    osc1:setParameter("Waveform"..oscillatorNumber, self.value)
    self.displayText = waveforms[self.value]
  end
  oscShapeKnob:changed()
  table.insert(tweakables, {widget=oscShapeKnob,min=6,default=10,category="synthesis"})
    
  local oscPhaseKnob = oscPanel:Knob("Osc"..oscillatorNumber.."StartPhase", 0, 0, 1)
  oscPhaseKnob.displayName = "Start Phase"
  oscPhaseKnob.fillColour = knobColour
  oscPhaseKnob.outlineColour = osc1Colour
  oscPhaseKnob.changed = function(self)
    osc1:setParameter("StartPhase"..oscillatorNumber, self.value)
    self.displayText = percent(self.value)
  end
  oscPhaseKnob:changed()
  table.insert(tweakables, {widget=oscPhaseKnob,default=50,category="synthesis"})
  
  local oscOctKnob = oscPanel:Knob("Osc"..oscillatorNumber.."Oct", 0, -2, 2, true)
  oscOctKnob.displayName = "Octave"
  oscOctKnob.fillColour = knobColour
  oscOctKnob.outlineColour = osc1Colour
  oscOctKnob.changed = function(self)
    osc1:setParameter("Octave"..oscillatorNumber, self.value)
    if oscillatorNumber == 1 then
      local factor = 1 / 4
      local value = (self.value * factor) + 0.5
      osc2Pitch:setParameter("Value", value)
      print("Setting sub oct:", value)
    end
  end
  oscOctKnob:changed()
  table.insert(tweakables, {widget=oscOctKnob,min=-2,max=2,default=80,zero=25,category="synthesis"})
  
  local oscPitchKnob = oscPanel:Knob("Osc"..oscillatorNumber.."Pitch", 0, -24, 24, (oscillatorNumber==1))
  oscPitchKnob.displayName = "Pitch"
  oscPitchKnob.fillColour = knobColour
  oscPitchKnob.outlineColour = osc1Colour
  if oscillatorNumber > 1 then
    oscPitchKnob.mapper = Mapper.Quadratic
  end
  oscPitchKnob.changed = function(self)
    osc1:setParameter("Pitch"..oscillatorNumber, self.value)
    if oscillatorNumber == 1 then
      local factor = 1 / 48
      local value = (self.value * factor) + 0.5
      osc2Pitch:setParameter("Value", value)
      print("Setting sub pitch:", value)
    end
  end
  oscPitchKnob:changed()
  if oscillatorNumber > 1 then
    table.insert(tweakables, {widget=oscPitchKnob,min=-24,max=24,valueFilter={-24,-12,-5,0,7,12,19,24},floor=-12,ceiling=12,probability=75,default=50,zero=50,useDuration=true,category="synthesis"})
  end

  if oscillatorNumber > 1 then
    local syncButton = oscPanel:OnOffButton("SyncOsc"..oscillatorNumber.."ToOsc1", false)
    syncButton.tooltip = "Sync to Osc 1"
    syncButton.displayName = "Hardsync"
    syncButton.width = 80
    syncButton.alpha = buttonAlpha
    syncButton.backgroundColourOff = buttonBackgroundColourOff
    syncButton.backgroundColourOn = buttonBackgroundColourOn
    syncButton.textColourOff = buttonTextColourOff
    syncButton.textColourOn = buttonTextColourOn
    syncButton.changed = function(self)
      osc1:setParameter("SyncMode"..oscillatorNumber, self.value)
    end
    syncButton:changed()
    table.insert(tweakables, {widget=syncButton,func=getRandomBoolean,probability=20,category="synthesis"})
  end
end

--------------------------------------------------------------------------------
-- Osc 1
--------------------------------------------------------------------------------

function createOsc1Panel()
  local osc1Panel = Panel("Osc1Panel")

  if isAnalogStack then
    osc1Panel:Label("Osc 1")
    createStackOscPanel(osc1Panel, 1)
  elseif isAnalog3Osc then
    osc1Panel:Label("Osc 1")
    createAnalog3OscPanel(osc1Panel, 1)
  elseif isFM then
    local osc1LevelKnobs = {}
    local osc1RatioKnobs = {}

    local opMenu = osc1Panel:Menu("OpOsc1", {"Op A", "Op B", "Op C", "Op D"})
    opMenu.displayName = "Osc 1"
    opMenu.backgroundColour = menuBackgroundColour
    opMenu.textColour = menuTextColour
    opMenu.arrowColour = menuArrowColour
    opMenu.outlineColour = menuOutlineColour
    opMenu.changed = function(self)
      for i=1,4 do
        osc1LevelKnobs[i].visible = i == self.value
        osc1RatioKnobs[i].visible = i == self.value
      end
    end

    local osc1TopologyKnob = osc1Panel:Knob("Osc1Topology", 0, 0, 10, true)
    osc1TopologyKnob.displayName = "Topology"
    osc1TopologyKnob.fillColour = knobColour
    osc1TopologyKnob.outlineColour = osc1Colour
    osc1TopologyKnob.changed = function(self)
      osc1:setParameter("Topology", self.value)
      self.displayText = topologies[self.value+1]
      -- Set max level for level knobs based on topology
      for i=2,4 do
        local max = getMaxFromTopology(i, self.value)
        if max ~= osc1LevelKnobs[i].max then
          osc1LevelKnobs[i]:setRange(0, max)
          osc1LevelKnobs[i]:setValue(1)
        end
      end
    end
    table.insert(tweakables, {widget=osc1TopologyKnob,default=10,factor=10,category="synthesis"})

    local osc1LevelKnobA = osc1Panel:Knob("Osc1LevelOpA", 1, 0, 1)
    osc1LevelKnobA.displayName = "Level A"
    osc1LevelKnobA.fillColour = knobColour
    osc1LevelKnobA.outlineColour = osc1Colour
    osc1LevelKnobA.y = osc1TopologyKnob.y
    osc1LevelKnobA.x = osc1TopologyKnob.x + osc1TopologyKnob.width + marginX
    osc1LevelKnobA.changed = function(self)
      osc1:setParameter("LevelA", self.value)
    end
    osc1LevelKnobA:changed()
    table.insert(osc1LevelKnobs, osc1LevelKnobA)
    table.insert(tweakables, {widget=osc1LevelKnobA,default=80,floor=0.85,ceil=1,probability=96,category="synthesis"})

    local osc1LevelKnobB = osc1Panel:Knob("Osc1LevelOpB", 1, 0, 20)
    osc1LevelKnobB.displayName = "Level B"
    osc1LevelKnobB.fillColour = knobColour
    osc1LevelKnobB.outlineColour = osc1Colour
    osc1LevelKnobB.y = osc1TopologyKnob.y
    osc1LevelKnobB.x = osc1TopologyKnob.x + osc1TopologyKnob.width + marginX
    osc1LevelKnobB.changed = function(self)
      osc1:setParameter("LevelB", self.value)
    end
    osc1LevelKnobB:changed()
    table.insert(osc1LevelKnobs, osc1LevelKnobB)
    table.insert(tweakables, {widget=osc1LevelKnobB,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=3,fmLevel=25,category="synthesis"})

    local osc1LevelKnobC = osc1Panel:Knob("Osc1LevelOpC", 1, 0, 20)
    osc1LevelKnobC.displayName = "Level C"
    osc1LevelKnobC.fillColour = knobColour
    osc1LevelKnobC.outlineColour = osc1Colour
    osc1LevelKnobC.y = osc1TopologyKnob.y
    osc1LevelKnobC.x = osc1TopologyKnob.x + osc1TopologyKnob.width + marginX
    osc1LevelKnobC.changed = function(self)
      osc1:setParameter("LevelC", self.value)
    end
    osc1LevelKnobC:changed()
    table.insert(osc1LevelKnobs, osc1LevelKnobC)
    table.insert(tweakables, {widget=osc1LevelKnobC,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=6,fmLevel=25,category="synthesis"})

    local osc1LevelKnobD = osc1Panel:Knob("Osc1LevelOpD", 1, 0, 20)
    osc1LevelKnobD.displayName = "Level D"
    osc1LevelKnobD.fillColour = knobColour
    osc1LevelKnobD.outlineColour = osc1Colour
    osc1LevelKnobD.y = osc1TopologyKnob.y
    osc1LevelKnobD.x = osc1TopologyKnob.x + osc1TopologyKnob.width + marginX
    osc1LevelKnobD.changed = function(self)
      osc1:setParameter("LevelD", self.value)
    end
    osc1LevelKnobD:changed()
    table.insert(osc1LevelKnobs, osc1LevelKnobD)
    table.insert(tweakables, {widget=osc1LevelKnobD,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=9,fmLevel=25,category="synthesis"})

    for i=1,4 do
      local op = 'A'
      local probability = 80
      if i == 2 then
        op = 'B'
        probability = 70
      elseif i == 3 then
        op = 'C'
        probability = 60
      elseif i == 4 then
        op = 'D'
        probability = 50
      end
      local osc1RatioKnob = osc1Panel:Knob("Osc1RatioOp"..op, 1, 1, 40, true)
      osc1RatioKnob.displayName = "Ratio "..op
      osc1RatioKnob.fillColour = knobColour
      osc1RatioKnob.outlineColour = osc1Colour
      osc1RatioKnob.y = osc1TopologyKnob.y
      osc1RatioKnob.x = osc1TopologyKnob.x + (osc1TopologyKnob.width * 2) + (marginX * 2)
      osc1RatioKnob.changed = function(self)
        osc1:setParameter("Ratio"..op, self.value)
        self.displayText = self.value..'x'
      end
      osc1RatioKnob:changed()
      table.insert(osc1RatioKnobs, osc1RatioKnob)
      table.insert(tweakables, {widget=osc1RatioKnob,default=50,factor=40,floor=1,ceiling=8,probability=probability,category="synthesis"})
    end

    local osc1PitchKnob = osc1Panel:Knob("Osc1Pitch", 0, -2, 2, true)
    osc1PitchKnob.displayName = "Octave"
    osc1PitchKnob.fillColour = knobColour
    osc1PitchKnob.outlineColour = osc1Colour
    osc1PitchKnob.changed = function(self)
      local factor = 1 / 4
      local value = (self.value * factor) + 0.5
      osc1Pitch:setParameter("Value", value)
    end
    osc1PitchKnob:changed()
    table.insert(tweakables, {widget=osc1PitchKnob,min=-2,max=2,default=80,zero=25,category="synthesis"})

    local osc1FeedbackKnob = osc1Panel:Knob("Osc1Feedback", 0, 0, 1)
    osc1FeedbackKnob.displayName = "Feedback"
    osc1FeedbackKnob.fillColour = knobColour
    osc1FeedbackKnob.outlineColour = osc1Colour
    osc1FeedbackKnob.changed = function(self)
      osc1:setParameter("Feedback", self.value)
      self.displayText = percent(self.value)
    end
    osc1FeedbackKnob:changed()
    table.insert(tweakables, {widget=osc1FeedbackKnob,default=60,category="synthesis"})

    osc1TopologyKnob:changed()
    opMenu:changed()
else
    osc1Panel:Label("Osc 1")
    if isAnalog then
      local osc1ShapeKnob = osc1Panel:Knob("Osc1Wave", 1, 1, 6, true)
      osc1ShapeKnob.displayName = "Waveform"
      osc1ShapeKnob.fillColour = knobColour
      osc1ShapeKnob.outlineColour = osc1Colour
      osc1ShapeKnob.changed = function(self)
        osc1:setParameter("Waveform", self.value)
        self.displayText = waveforms[self.value]
      end
      osc1ShapeKnob:changed()
      table.insert(tweakables, {widget=osc1ShapeKnob,min=6,default=10,category="synthesis"})
    elseif isWavetable then
      local osc1ShapeKnob = osc1Panel:Knob("Osc1Wave", 0, 0, 1)
      osc1ShapeKnob.displayName = "Wave"
      osc1ShapeKnob.fillColour = knobColour
      osc1ShapeKnob.outlineColour = osc1Colour
      osc1ShapeKnob.changed = function(self)
        osc1Shape:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      osc1ShapeKnob:changed()
      table.insert(tweakables, {widget=osc1ShapeKnob,default=10,useDuration=true,category="synthesis"})
    elseif isAdditive then
      local osc1PartialsKnob = osc1Panel:Knob("Osc1Partials", 1, 1, 256, true)
      osc1PartialsKnob.displayName = "Max Partials"
      osc1PartialsKnob.fillColour = knobColour
      osc1PartialsKnob.outlineColour = osc1Colour
      osc1PartialsKnob.changed = function(self)
        local factor = 1 / 256
        local value = self.value * factor
        if self.value == 1 then
          value = 0
        end
        osc1Shape:setParameter("Value", value)
      end
      osc1PartialsKnob:changed()
      table.insert(tweakables, {widget=osc1PartialsKnob,min=256,floor=2,ceiling=64,probability=70,useDuration=true,category="synthesis"})

      local osc1EvenOddKnob = osc1Panel:Knob("Osc1EvenOdd", 0, -1, 1)
      osc1EvenOddKnob.displayName = "Even/Odd"
      osc1EvenOddKnob.fillColour = knobColour
      osc1EvenOddKnob.outlineColour = osc1Colour
      osc1EvenOddKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["osc1EvenOdd"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      osc1EvenOddKnob:changed()
      table.insert(tweakables, {widget=osc1EvenOddKnob,bipolar=50,default=10,useDuration=true,category="synthesis"})
    end
    
    if isAnalog or isWavetable then
      local osc1PhaseKnob = osc1Panel:Knob("Osc1StartPhase", 0, 0, 1)
      osc1PhaseKnob.displayName = "Start Phase"
      osc1PhaseKnob.fillColour = knobColour
      osc1PhaseKnob.outlineColour = osc1Colour
      osc1PhaseKnob.changed = function(self)
        osc1:setParameter("StartPhase", self.value)
        self.displayText = percent(self.value)
      end
      osc1PhaseKnob:changed()
      table.insert(tweakables, {widget=osc1PhaseKnob,default=50,useDuration=true,category="synthesis"})
    elseif isAdditive then
      local osc1CutoffKnob = osc1Panel:Knob("Osc1Cutoff", 1, 0, 1)
      osc1CutoffKnob.displayName = "Cutoff"
      osc1CutoffKnob.fillColour = knobColour
      osc1CutoffKnob.outlineColour = osc1Colour
      osc1CutoffKnob.changed = function(self)
        additiveMacros["osc1FilterCutoff"]:setParameter("Value", self.value)
        local value = filterMapValue(self.value)
        if value < 1000 then
            self.displayText = string.format("%0.1f Hz", value)
        else
            self.displayText = string.format("%0.1f kHz", value/1000.)
        end
      end
      osc1CutoffKnob:changed()
      table.insert(tweakables, {widget=osc1CutoffKnob,floor=0.6,ceiling=1.0,probability=80,default=50,useDuration=true,category="synthesis"})
    end
    
    local osc1PitchKnob = osc1Panel:Knob("Osc1Pitch", 0, -2, 2, true)
    osc1PitchKnob.displayName = "Octave"
    osc1PitchKnob.fillColour = knobColour
    osc1PitchKnob.outlineColour = osc1Colour
    osc1PitchKnob.changed = function(self)
      local factor = 1 / 4
      local value = (self.value * factor) + 0.5
      osc1Pitch:setParameter("Value", value)
    end
    osc1PitchKnob:changed()
    table.insert(tweakables, {widget=osc1PitchKnob,min=-2,max=2,default=80,zero=25,category="synthesis"})

    if isAnalog then
      local hardsyncKnob = osc1Panel:Knob("HardsyncOsc1", 0, 0, 36)
      hardsyncKnob.displayName = "Hardsync"
      hardsyncKnob.mapper = Mapper.Quadratic
      hardsyncKnob.fillColour = knobColour
      hardsyncKnob.outlineColour = osc1Colour
      hardsyncKnob.changed = function(self)
        osc1:setParameter("HardSyncShift", self.value)
      end
      hardsyncKnob:changed()
      table.insert(tweakables, {widget=hardsyncKnob,ceiling=12,probability=80,min=36,zero=50,default=50,useDuration=true,category="synthesis"})

      local atToHardsycKnob = osc1Panel:Knob("AtToHarsyncosc1", 0, 0, 1)
      atToHardsycKnob.displayName = "AT->Sync"
      atToHardsycKnob.fillColour = knobColour
      atToHardsycKnob.outlineColour = filterColour
      atToHardsycKnob.changed = function(self)
        analogMacros["atToHardsync1"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      atToHardsycKnob:changed()
      table.insert(tweakables, {widget=atToHardsycKnob,zero=25,default=25,excludeWithTwequencer=true,category="synthesis"})
    elseif isWavetable then
      local aftertouchToWaveKnob = osc1Panel:Knob("AftertouchToWave1", 0, -1, 1)
      aftertouchToWaveKnob.displayName = "AT->Wave"
      aftertouchToWaveKnob.fillColour = knobColour
      aftertouchToWaveKnob.outlineColour = filterColour
      aftertouchToWaveKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["atToShape1"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      aftertouchToWaveKnob:changed()
      table.insert(tweakables, {widget=aftertouchToWaveKnob,bipolar=25,floor=0.5,ceiling=0.8,probability=60,default=50,excludeWithTwequencer=true,category="synthesis"})

      local wheelToWaveKnob = osc1Panel:Knob("WheelToWave1", 0, -1, 1)
      wheelToWaveKnob.displayName = "Wheel->Wave"
      wheelToWaveKnob.fillColour = knobColour
      wheelToWaveKnob.outlineColour = filterColour
      wheelToWaveKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["wheelToShape1"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      wheelToWaveKnob:changed()
      table.insert(tweakables, {widget=wheelToWaveKnob,bipolar=25,floor=0.3,ceiling=0.5,probability=60,default=50,excludeWithTwequencer=true,category="synthesis"})
    elseif isAdditive then
      local harmShiftKnob = osc1Panel:Knob("HarmShift1", 0, 0, 48)
      harmShiftKnob.displayName = "Harm. Shift"
      harmShiftKnob.fillColour = knobColour
      harmShiftKnob.outlineColour = filterColour
      harmShiftKnob.changed = function(self)
        osc1:setParameter("HarmShift", self.value)
      end
      harmShiftKnob:changed()
      table.insert(tweakables, {widget=harmShiftKnob,ceiling=12,probability=60,default=80,zero=20,useDuration=true,category="synthesis"})
    end
  end

  return osc1Panel
end

local osc1Panel = createOsc1Panel()

--------------------------------------------------------------------------------
-- Osc 2
--------------------------------------------------------------------------------

function createOsc2Panel()
  local osc2Panel = Panel("Osc2Panel")

  if isAnalogStack then
    osc2Panel:Label("Osc 2")
    createStackOscPanel(osc2Panel, 2)
  elseif isAnalog3Osc then
    osc2Panel:Label("Osc 2")
    createAnalog3OscPanel(osc2Panel, 2)
  elseif isFM then
    local osc2LevelKnobs = {}
    local osc2RatioKnobs = {}

    local opMenu = osc2Panel:Menu("OpOsc2", {"Op A", "Op B", "Op C", "Op D"})
    opMenu.displayName = "Osc 2"
    opMenu.backgroundColour = menuBackgroundColour
    opMenu.textColour = menuTextColour
    opMenu.arrowColour = menuArrowColour
    opMenu.outlineColour = menuOutlineColour
    opMenu.changed = function(self)
      for i=1,4 do
        osc2LevelKnobs[i].visible = i == self.value
        osc2RatioKnobs[i].visible = i == self.value
      end
    end

    local osc2TopologyKnob = osc2Panel:Knob("Osc2Topology", 0, 0, 10, true)
    osc2TopologyKnob.displayName = "Topology"
    osc2TopologyKnob.fillColour = knobColour
    osc2TopologyKnob.outlineColour = osc1Colour
    osc2TopologyKnob.changed = function(self)
      osc2:setParameter("Topology", self.value)
      self.displayText = topologies[self.value+1]
      -- Set max level for level knobs based on topology
      for i=2,4 do
        local max = getMaxFromTopology(i, self.value)
        if max ~= osc2LevelKnobs[i].max then
          osc2LevelKnobs[i]:setRange(0, max)
          osc2LevelKnobs[i]:setValue(1)
        end
      end
    end
    table.insert(tweakables, {widget=osc2TopologyKnob,default=10,factor=10,category="synthesis"})

    local osc2LevelKnobA = osc2Panel:Knob("Osc2LevelOpA", 1, 0, 1)
    osc2LevelKnobA.displayName = "Level A"
    osc2LevelKnobA.fillColour = knobColour
    osc2LevelKnobA.outlineColour = osc2Colour
    osc2LevelKnobA.y = osc2TopologyKnob.y
    osc2LevelKnobA.x = osc2TopologyKnob.x + osc2TopologyKnob.width + marginX
    osc2LevelKnobA.changed = function(self)
      osc2:setParameter("LevelA", self.value)
    end
    osc2LevelKnobA:changed()
    table.insert(osc2LevelKnobs, osc2LevelKnobA)
    table.insert(tweakables, {widget=osc2LevelKnobA,default=80,floor=0.8,ceil=1,probability=90,category="synthesis"})

    local osc2LevelKnobB = osc2Panel:Knob("Osc2LevelOpB", 1, 0, 20)
    osc2LevelKnobB.displayName = "Level B"
    osc2LevelKnobB.fillColour = knobColour
    osc2LevelKnobB.outlineColour = osc2Colour
    osc2LevelKnobB.y = osc2TopologyKnob.y
    osc2LevelKnobB.x = osc2TopologyKnob.x + osc2TopologyKnob.width + marginX
    osc2LevelKnobB.changed = function(self)
      osc2:setParameter("LevelB", self.value)
    end
    osc2LevelKnobB:changed()
    table.insert(osc2LevelKnobs, osc2LevelKnobB)
    table.insert(tweakables, {widget=osc2LevelKnobB,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=3,fmLevel=25,category="synthesis"})

    local osc2LevelKnobC = osc2Panel:Knob("Osc2LevelOpC", 1, 0, 20)
    osc2LevelKnobC.displayName = "Level C"
    osc2LevelKnobC.fillColour = knobColour
    osc2LevelKnobC.outlineColour = osc2Colour
    osc2LevelKnobC.y = osc2TopologyKnob.y
    osc2LevelKnobC.x = osc2TopologyKnob.x + osc2TopologyKnob.width + marginX
    osc2LevelKnobC.changed = function(self)
      osc2:setParameter("LevelC", self.value)
    end
    osc2LevelKnobC:changed()
    table.insert(osc2LevelKnobs, osc2LevelKnobC)
    table.insert(tweakables, {widget=osc2LevelKnobC,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=6,fmLevel=25,category="synthesis"})

    local osc2LevelKnobD = osc2Panel:Knob("Osc2LevelOpD", 1, 0, 20)
    osc2LevelKnobD.displayName = "Level D"
    osc2LevelKnobD.fillColour = knobColour
    osc2LevelKnobD.outlineColour = osc2Colour
    osc2LevelKnobD.y = osc2TopologyKnob.y
    osc2LevelKnobD.x = osc2TopologyKnob.x + osc2TopologyKnob.width + marginX
    osc2LevelKnobD.changed = function(self)
      osc2:setParameter("LevelD", self.value)
    end
    osc2LevelKnobD:changed()
    table.insert(osc2LevelKnobs, osc2LevelKnobD)
    table.insert(tweakables, {widget=osc2LevelKnobD,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=9,fmLevel=25,category="synthesis"})

    for i=1,4 do
      local op = 'A'
      local probability = 80
      if i == 2 then
        op = 'B'
        probability = 70
      elseif i == 3 then
        op = 'C'
        probability = 60
      elseif i == 4 then
        op = 'D'
        probability = 50
      end
      local osc2RatioKnob = osc2Panel:Knob("Osc2RatioOp"..op, 1, 1, 40, true)
      osc2RatioKnob.displayName = "Ratio "..op
      osc2RatioKnob.fillColour = knobColour
      osc2RatioKnob.outlineColour = osc2Colour
      osc2RatioKnob.y = osc2TopologyKnob.y
      osc2RatioKnob.x = osc2TopologyKnob.x + (osc2TopologyKnob.width * 2) + (marginX * 2)
      osc2RatioKnob.changed = function(self)
        osc2:setParameter("Ratio"..op, self.value)
        self.displayText = self.value..'x'
      end
      osc2RatioKnob:changed()
      table.insert(osc2RatioKnobs, osc2RatioKnob)
      table.insert(tweakables, {widget=osc2RatioKnob,default=50,factor=40,floor=1,ceiling=8,probability=probability,category="synthesis"})
    end

    local osc2PitchKnob = osc2Panel:Knob("Osc2Pitch", 0, -24, 24, true)
    osc2PitchKnob.displayName = "Pitch"
    osc2PitchKnob.fillColour = knobColour
    osc2PitchKnob.outlineColour = osc2Colour
    osc2PitchKnob.changed = function(self)
      local factor = 1 / 48
      local value = (self.value * factor) + 0.5
      osc2Pitch:setParameter("Value", value)
    end
    osc2PitchKnob:changed()
    table.insert(tweakables, {widget=osc2PitchKnob,min=-24,max=24,valueFilter={-24,-12,-5,0,7,12,19,24},floor=-12,ceiling=12,probability=75,default=50,zero=50,useDuration=true,category="synthesis"})

    local osc2FeedbackKnob = osc2Panel:Knob("Osc2Feedback", 0, 0, 1)
    osc2FeedbackKnob.displayName = "Feedback"
    osc2FeedbackKnob.fillColour = knobColour
    osc2FeedbackKnob.outlineColour = osc2Colour
    osc2FeedbackKnob.changed = function(self)
      osc2:setParameter("Feedback", self.value)
      self.displayText = percent(self.value)
    end
    osc2FeedbackKnob:changed()
    table.insert(tweakables, {widget=osc2FeedbackKnob,default=60,category="synthesis"})

    osc2TopologyKnob:changed()
    opMenu:changed()
  else
    osc2Panel:Label("Osc 2")
    if isAnalog then
      local osc2ShapeKnob = osc2Panel:Knob("Osc2Wave", 1, 1, 6, true)
      osc2ShapeKnob.displayName = "Waveform"
      osc2ShapeKnob.fillColour = knobColour
      osc2ShapeKnob.outlineColour = osc2Colour
      osc2ShapeKnob.changed = function(self)
        osc2:setParameter("Waveform", self.value)
        self.displayText = waveforms[self.value]
      end
      osc2ShapeKnob:changed()
      table.insert(tweakables, {widget=osc2ShapeKnob,min=6,default=10,category="synthesis"})
    elseif isWavetable then
      local osc2ShapeKnob = osc2Panel:Knob("Osc2Wave", 0, 0, 1)
      osc2ShapeKnob.displayName = "Wave"
      osc2ShapeKnob.fillColour = knobColour
      osc2ShapeKnob.outlineColour = osc2Colour
      osc2ShapeKnob.changed = function(self)
        osc2Shape:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      osc2ShapeKnob:changed()
      table.insert(tweakables, {widget=osc2ShapeKnob,default=10,useDuration=true,category="synthesis"})
    elseif isAdditive then
      local osc2PartialsKnob = osc2Panel:Knob("Osc2Partials", 1, 1, 256, true)
      osc2PartialsKnob.displayName = "Max Partials"
      osc2PartialsKnob.fillColour = knobColour
      osc2PartialsKnob.outlineColour = osc1Colour
      osc2PartialsKnob.changed = function(self)
        local factor = 1 / 256
        local value = self.value * factor
        if self.value == 1 then
          value = 0
        end
        osc2Shape:setParameter("Value", value)
      end
      osc2PartialsKnob:changed()
      table.insert(tweakables, {widget=osc2PartialsKnob,min=256,floor=2,ceiling=64,probability=70,useDuration=true,category="synthesis"})

      local osc2EvenOddKnob = osc2Panel:Knob("Osc2EvenOdd", 0, -1, 1)
      osc2EvenOddKnob.displayName = "Even/Odd"
      osc2EvenOddKnob.fillColour = knobColour
      osc2EvenOddKnob.outlineColour = osc1Colour
      osc2EvenOddKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["osc2EvenOdd"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      osc2EvenOddKnob:changed()
      table.insert(tweakables, {widget=osc2EvenOddKnob,bipolar=50,default=10,useDuration=true,category="synthesis"})
    end

    if isAnalog or isWavetable then
      local osc2PhaseKnob = osc2Panel:Knob("Osc2StartPhase", 0, 0, 1)
      osc2PhaseKnob.displayName = "Start Phase"
      osc2PhaseKnob.fillColour = knobColour
      osc2PhaseKnob.outlineColour = osc2Colour
      osc2PhaseKnob.changed = function(self)
        osc2:setParameter("StartPhase", self.value)
        self.displayText = percent(self.value)
      end
      osc2PhaseKnob:changed()
      table.insert(tweakables, {widget=osc2PhaseKnob,default=50,useDuration=true,category="synthesis"})
    elseif isAdditive then
      local osc2CutoffKnob = osc2Panel:Knob("Osc2Cutoff", 1, 0, 1)
      osc2CutoffKnob.displayName = "Cutoff"
      osc2CutoffKnob.fillColour = knobColour
      osc2CutoffKnob.outlineColour = osc1Colour
      osc2CutoffKnob.changed = function(self)
        additiveMacros["osc2FilterCutoff"]:setParameter("Value", self.value)
        local value = filterMapValue(self.value)
        if value < 1000 then
            self.displayText = string.format("%0.1f Hz", value)
        else
            self.displayText = string.format("%0.1f kHz", value/1000.)
        end
      end
      osc2CutoffKnob:changed()
      table.insert(tweakables, {widget=osc2CutoffKnob,floor=0.6,ceiling=1.0,probability=80,default=50,useDuration=true,category="synthesis"})
    end

    local osc2PitchKnob = osc2Panel:Knob("Osc2Pitch", 0, -24, 24, true)
    osc2PitchKnob.displayName = "Pitch"
    osc2PitchKnob.fillColour = knobColour
    osc2PitchKnob.outlineColour = osc2Colour
    osc2PitchKnob.changed = function(self)
      local factor = 1 / 48
      local value = (self.value * factor) + 0.5
      osc2Pitch:setParameter("Value", value)
    end
    osc2PitchKnob:changed()
    table.insert(tweakables, {widget=osc2PitchKnob,min=-24,max=24,valueFilter={-24,-12,-5,0,7,12,19,24},floor=-12,ceiling=12,probability=75,default=50,zero=50,useDuration=true,category="synthesis"})

    if isAnalog or isWavetable or isAdditive then
      local osc2DetuneKnob = osc2Panel:Knob("Osc2FinePitch", 0, 0, 1)
      osc2DetuneKnob.displayName = "Fine Pitch"
      osc2DetuneKnob.fillColour = knobColour
      osc2DetuneKnob.outlineColour = osc2Colour
      osc2DetuneKnob.changed = function(self)
        osc2Detune:setParameter("Value", self.value)
      end
      osc2DetuneKnob:changed()
      table.insert(tweakables, {widget=osc2DetuneKnob,ceiling=0.25,probability=90,default=50,defaultTweakRange=0.15,zero=25,absoluteLimit=0.4,useDuration=true,category="synthesis"})
    end

    if isAnalog then
      local hardsyncKnob = osc2Panel:Knob("HardsyncOsc2", 0, 0, 36)
      hardsyncKnob.displayName = "Hardsync"
      hardsyncKnob.mapper = Mapper.Quadratic
      hardsyncKnob.fillColour = knobColour
      hardsyncKnob.outlineColour = osc1Colour
      hardsyncKnob.changed = function(self)
        osc2:setParameter("HardSyncShift", self.value)
      end
      hardsyncKnob:changed()
      table.insert(tweakables, {widget=hardsyncKnob,ceiling=12,probability=80,min=36,zero=75,default=50,useDuration=true,category="synthesis"})
    elseif isWavetable then
      local wheelToWaveKnob = osc2Panel:Knob("WheelToWave2", 0, -1, 1)
      wheelToWaveKnob.displayName = "Wheel->Wave"
      wheelToWaveKnob.fillColour = knobColour
      wheelToWaveKnob.outlineColour = filterColour
      wheelToWaveKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["wheelToShape2"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      wheelToWaveKnob:changed()
      table.insert(tweakables, {widget=wheelToWaveKnob,bipolar=25,excludeWithTwequencer=true,category="synthesis"})
    end
  end

  return osc2Panel
end

local osc2Panel = createOsc2Panel()

--------------------------------------------------------------------------------
-- Osc 3
--------------------------------------------------------------------------------

function createOsc3Panel()
  local osc3Panel = Panel("Osc3Panel")
  osc3Panel:Label("Osc 3")

  createAnalog3OscPanel(osc3Panel, 3)

  return osc3Panel
end

local osc3Panel
if isAnalog3Osc then
  osc3Panel = createOsc3Panel()
end

--------------------------------------------------------------------------------
-- Mixer
--------------------------------------------------------------------------------

local arpeggiatorButton

function createMixerPanel()
  local mixerPanel = Panel("Mixer")
  mixerPanel.backgroundColour = "#91000000"
  mixerPanel.x = 0
  mixerPanel.y = 378
  mixerPanel.width = 720
  mixerPanel.height = 102

  local mixerLabel = mixerPanel:Label("Mixer")
  mixerLabel.y = 5
  mixerLabel.x = 10
  mixerLabel.width = 70 -- Overrides below

  local knobSize = {100,40} -- Overrides below
  local marginRight = 10 -- Overrides below

  if isAnalog3Osc then
    mixerLabel.width = 60
    marginRight = 1
    knobSize = {95,40}
  elseif isAdditive then
    knobSize = {110,40}
  end

  local osc1MixKnob = mixerPanel:Knob("Osc1Mix", 0.75, 0, 1)
  osc1MixKnob.displayName = "Osc 1"
  osc1MixKnob.x = mixerLabel.x + mixerLabel.width + marginRight
  osc1MixKnob.y = mixerLabel.y
  osc1MixKnob.size = knobSize
  osc1MixKnob.fillColour = knobColour
  osc1MixKnob.outlineColour = osc1Colour
  osc1MixKnob.changed = function(self)
    osc1Mix:setParameter("Value", self.value)
    self.displayText = formatGainInDb(self.value)
  end
  osc1MixKnob:changed()
  table.insert(tweakables, {widget=osc1MixKnob,floor=0.5,ceiling=0.75,probability=100,absoluteLimit=0.8,default=50,useDuration=true,category="mixer"})

  local osc2MixKnob = mixerPanel:Knob("Osc2Mix", 0, 0, 1)
  osc2MixKnob.displayName = "Osc 2"
  osc2MixKnob.y = mixerLabel.y
  osc2MixKnob.x = osc1MixKnob.x + osc1MixKnob.width + marginRight
  osc2MixKnob.size = knobSize
  osc2MixKnob.fillColour = knobColour
  osc2MixKnob.outlineColour = osc2Colour
  osc2MixKnob.changed = function(self)
    osc2Mix:setParameter("Value", self.value)
    self.displayText = formatGainInDb(self.value)
  end
  osc2MixKnob:changed()
  table.insert(tweakables, {widget=osc2MixKnob,floor=0.5,ceiling=0.75,probability=100,absoluteLimit=0.8,zero=10,default=5,useDuration=true,category="mixer"})

  local subOscWaveformKnob
  if isAnalog3Osc then
    local osc3MixKnob = mixerPanel:Knob("Osc3Mix", 0, 0, 1)
    osc3MixKnob.displayName = "Osc 3"
    osc3MixKnob.y = mixerLabel.y
    osc3MixKnob.x = osc2MixKnob.x + osc2MixKnob.width + marginRight
    osc3MixKnob.size = knobSize
    osc3MixKnob.fillColour = knobColour
    osc3MixKnob.outlineColour = osc2Colour
    osc3MixKnob.changed = function(self)
      osc1:setParameter("Gain3", self.value)
      self.displayText = formatGainInDb(self.value)
    end
    osc3MixKnob:changed()
    table.insert(tweakables, {widget=osc3MixKnob,floor=0.5,ceiling=0.75,probability=100,absoluteLimit=0.8,zero=25,default=10,category="mixer"})

    local subOscMixKnob = mixerPanel:Knob("SubOscMix", 0, 0, 1)
    subOscMixKnob.displayName = "Sub"
    subOscMixKnob.y = mixerLabel.y
    subOscMixKnob.x = osc3MixKnob.x + osc3MixKnob.width + marginRight
    subOscMixKnob.size = {90,knobSize[2]}
    subOscMixKnob.fillColour = knobColour
    subOscMixKnob.outlineColour = osc2Colour
    subOscMixKnob.changed = function(self)
      analogMacros["subOscMix"]:setParameter("Value", self.value)
      self.displayText = formatGainInDb(self.value)
    end
    subOscMixKnob:changed()
    table.insert(tweakables, {widget=subOscMixKnob,floor=0.4,ceiling=0.75,probability=100,absoluteLimit=0.8,zero=10,default=5,useDuration=true,category="mixer"})

    subOscWaveformKnob = mixerPanel:Knob("SubOscWaveform", 3, 1, 4, true)
    subOscWaveformKnob.displayName = "SubWave"
    subOscWaveformKnob.y = mixerLabel.y
    subOscWaveformKnob.x = subOscMixKnob.x + subOscMixKnob.width + marginRight
    subOscWaveformKnob.size = knobSize
    subOscWaveformKnob.fillColour = knobColour
    subOscWaveformKnob.outlineColour = osc2Colour
    subOscWaveformKnob.changed = function(self)
      osc2:setParameter("Waveform", self.value)
      self.displayText = waveforms[self.value]
     end
    subOscWaveformKnob:changed()
    table.insert(tweakables, {widget=subOscWaveformKnob,min=4,default=75,category="synthesis"})
  end

  local noiseTypeMenu
  local noiseMixKnob = mixerPanel:Knob("NoiseMix", 0, 0, 1)
  noiseMixKnob.displayName = "Noise"
  if isAnalog3Osc then
    noiseMixKnob.y = 50
    noiseMixKnob.x = 630
  else
    noiseMixKnob.y = mixerLabel.y
    noiseMixKnob.x = osc2MixKnob.x + osc2MixKnob.width + marginRight
  end
  noiseMixKnob.size = knobSize
  noiseMixKnob.fillColour = knobColour
  noiseMixKnob.outlineColour = osc2Colour
  noiseMixKnob.changed = function(self)
    noiseMix:setParameter("Value", self.value)
    self.displayText = formatGainInDb(self.value)
  end
  noiseMixKnob:changed()
  table.insert(tweakables, {widget=noiseMixKnob,floor=0.3,ceiling=0.75,probability=100,default=5,zero=10,absoluteLimit=0.8,useDuration=true,category="mixer"})
  
  if isAnalog or isAnalogStack or isWavetable or isAdditive or isFM then
    local noiseTypes = {"Band", "S&H", "Static1", "Static2", "Violet", "Blue", "White", "Pink", "Brown", "Lorenz", "Rossler", "Crackle", "Logistic", "Dust", "Velvet"}
    noiseTypeMenu = mixerPanel:Menu("NoiseType", noiseTypes)
    noiseTypeMenu.y = 2
    noiseTypeMenu.x = noiseMixKnob.x + noiseMixKnob.width + marginRight
    noiseTypeMenu.width = 75
    noiseTypeMenu.backgroundColour = menuBackgroundColour
    noiseTypeMenu.textColour = menuTextColour
    noiseTypeMenu.arrowColour = menuArrowColour
    noiseTypeMenu.outlineColour = menuOutlineColour
    noiseTypeMenu.displayName = "Noise Type"
    noiseTypeMenu.selected = 7
    noiseTypeMenu.changed = function(self)
      local value = self.value - 1
      noiseOsc:setParameter("NoiseType", value)
    end
    noiseTypeMenu:changed()
    table.insert(tweakables, {widget=noiseTypeMenu,min=#noiseTypes,default=75,valueFilter={5,6,7,8,9},category="synthesis"})
  end

  local panSpreadKnob = mixerPanel:Knob("PanSpread", 0, 0, 1)
  panSpreadKnob.displayName = "Pan Spread"
  panSpreadKnob.y = mixerLabel.y
  if subOscWaveformKnob then
    panSpreadKnob.x = subOscWaveformKnob.x + subOscWaveformKnob.width - marginRight
  else
    panSpreadKnob.x = noiseTypeMenu.x + noiseTypeMenu.width + marginRight
  end
  panSpreadKnob.size = knobSize
  panSpreadKnob.fillColour = knobColour
  panSpreadKnob.outlineColour = unisonColour
  panSpreadKnob.changed = function(self)
    panSpread:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  panSpreadKnob:changed()
  table.insert(tweakables, {widget=panSpreadKnob,ceiling=0.6,probability=70,default=30,useDuration=true,category="mixer"})

  arpeggiatorButton = mixerPanel:OnOffButton("Arp", false)
  --arpeggiatorButton.showLabel = true
  arpeggiatorButton.y = mixerLabel.y
  arpeggiatorButton.x = 655 --620
  arpeggiatorButton.alpha = buttonAlpha
  arpeggiatorButton.backgroundColourOff = buttonBackgroundColourOff
  arpeggiatorButton.backgroundColourOn = buttonBackgroundColourOn
  arpeggiatorButton.textColourOff = buttonTextColourOff
  arpeggiatorButton.textColourOn = buttonTextColourOn
  --arpeggiatorButton.normalImage = "resources/button_off.png"
  --arpeggiatorButton.pressedImage = "resources/button_on.png"
  arpeggiatorButton.width = 50 --80
  arpeggiatorButton.height = 40
  arpeggiatorButton.changed = function(self)
    local value = -1
    if self.value == true then
      value = 1
    end
    arpeggiator:setParameter("Value", value)
  end
  arpeggiatorButton:changed()

  local randomPhaseStartKnob
  if isAnalog or isAnalogStack or isAnalog3Osc then
    randomPhaseStartKnob = mixerPanel:Knob("RandomPhaseStart", 0, 0, 1)
    randomPhaseStartKnob.displayName = "Rand Phase"
    randomPhaseStartKnob.y = 50
    randomPhaseStartKnob.x = mixerLabel.x
    randomPhaseStartKnob.size = knobSize
    randomPhaseStartKnob.fillColour = knobColour
    randomPhaseStartKnob.outlineColour = unisonColour
    randomPhaseStartKnob.changed = function(self)
      if isAnalogStack then
        for i=1,8 do
          osc1:setParameter("StartPhase"..i, (getRandom()*self.value))
          osc2:setParameter("StartPhase"..i, (getRandom()*self.value))
        end
      else
        analogMacros["randomPhaseStart"]:setParameter("Value", self.value)
      end
      self.displayText = percent(self.value)
    end
    randomPhaseStartKnob:changed()
    table.insert(tweakables, {widget=randomPhaseStartKnob,ceiling=0.3,probability=70,default=30,zero=30,useDuration=true,category="synthesis"})
  end

  local playModes = {"Poly", "Poly Portamento", "Mono Retrigger", "Mono Portamento", "Mono Portamento Slide"}
  local playModeMenu = mixerPanel:Menu("PlayModeMenu", playModes)
  if randomPhaseStartKnob then
    playModeMenu.y = randomPhaseStartKnob.y
    playModeMenu.x = randomPhaseStartKnob.x + randomPhaseStartKnob.width + marginRight
  else
    playModeMenu.y = 50
    playModeMenu.x = mixerLabel.x
  end
  playModeMenu.width = 120
  playModeMenu.backgroundColour = menuBackgroundColour
  playModeMenu.textColour = menuTextColour
  playModeMenu.arrowColour = menuArrowColour
  playModeMenu.outlineColour = menuOutlineColour
  playModeMenu.displayName = "Play Mode"
  playModeMenu.selected = 1
  playModeMenu.changed = function(self)
    local value = self.value - 1
    osc1Layer:setParameter("PlayMode", value)
    osc2Layer:setParameter("PlayMode", value)
    noiseLayer:setParameter("PlayMode", value)
  end
  playModeMenu:changed()
  table.insert(tweakables, {widget=playModeMenu,min=#playModes,default=75,excludeWithTwequencer=true,category="synthesis"})

  local portamentoTimeKnob = mixerPanel:Knob("PortamentoTime", 0.03, 0, 10)
  portamentoTimeKnob.displayName = "Glide Time"
  portamentoTimeKnob.y = playModeMenu.y
  portamentoTimeKnob.x = playModeMenu.x + playModeMenu.width + marginRight
  portamentoTimeKnob.size = knobSize
  portamentoTimeKnob.fillColour = knobColour
  portamentoTimeKnob.outlineColour = osc2Colour
  portamentoTimeKnob.mapper = Mapper.Quartic
  portamentoTimeKnob.changed = function(self)
    osc1Layer:setParameter("PortamentoTime", self.value)
    osc2Layer:setParameter("PortamentoTime", self.value)
    noiseLayer:setParameter("PortamentoTime", self.value)
    self.displayText = formatTimeInSeconds(self.value)
  end
  portamentoTimeKnob:changed()
  table.insert(tweakables, {widget=portamentoTimeKnob,floor=0.03,ceiling=0.15,probability=95,default=50,excludeWithTwequencer=true,category="synthesis"})

  local unisonVoicesMax = 8
  if isAdditive then
    unisonVoicesMax = 3
  end

  local unisonVoicesKnob = mixerPanel:Knob("UnisonVoices", 1, 1, unisonVoicesMax, true)
  local unisonDetuneKnob = mixerPanel:Knob("UnisonDetune", 0.1, 0, 1)
  local stereoSpreadKnob = mixerPanel:Knob("StereoSpread", 0, 0, 1)

  unisonVoicesKnob.displayName = "Unison"
  unisonVoicesKnob.y = playModeMenu.y
  unisonVoicesKnob.x = portamentoTimeKnob.x + portamentoTimeKnob.width + marginRight
  unisonVoicesKnob.size = knobSize
  unisonVoicesKnob.fillColour = knobColour
  unisonVoicesKnob.outlineColour = unisonColour

  unisonDetuneKnob.displayName = "Detune"
  unisonDetuneKnob.y = playModeMenu.y
  unisonDetuneKnob.x = unisonVoicesKnob.x + unisonVoicesKnob.width + marginRight
  unisonDetuneKnob.size = knobSize
  unisonDetuneKnob.fillColour = knobColour
  unisonDetuneKnob.outlineColour = unisonColour
  unisonDetuneKnob.changed = function(self)
    if isAnalogStack then
      setStackVoices(unisonVoicesKnob.value, self.value, stereoSpreadKnob.value, randomPhaseStartKnob.value)
    else
      unisonDetune:setParameter("Value", self.value)
    end
    self.displayText = percent(self.value)
  end
  unisonDetuneKnob:changed()
  table.insert(tweakables, {widget=unisonDetuneKnob,ceiling=0.3,probability=90,default=80,tweakRange=0.2,useDuration=true,excludeWithTwequencer=true,category="synthesis"})

  if isAdditive then
    stereoSpreadKnob.displayName = "Beating"
  else
    stereoSpreadKnob.displayName = "Stereo Spread"
  end
  stereoSpreadKnob.y = playModeMenu.y
  stereoSpreadKnob.x = unisonDetuneKnob.x + unisonDetuneKnob.width + marginRight
  stereoSpreadKnob.size = knobSize
  stereoSpreadKnob.width = 120
  stereoSpreadKnob.fillColour = knobColour
  stereoSpreadKnob.outlineColour = unisonColour
  stereoSpreadKnob.changed = function(self)
    if isAnalogStack then
      setStackVoices(unisonVoicesKnob.value, unisonDetuneKnob.value, self.value, randomPhaseStartKnob.value)
    else
      stereoSpread:setParameter("Value", self.value)
    end
    self.displayText = percent(self.value)
  end
  stereoSpreadKnob:changed()
  table.insert(tweakables, {widget=stereoSpreadKnob,ceiling=0.5,probability=40,default=40,useDuration=true,excludeWithTwequencer=true,category="synthesis"})

  local waveSpreadKnob
  if isWavetable then
    waveSpreadKnob = mixerPanel:Knob("WaveSpread", 0, 0, 1)
    waveSpreadKnob.displayName = "Wave Spread"
    waveSpreadKnob.y = playModeMenu.y
    waveSpreadKnob.x = stereoSpreadKnob.x + stereoSpreadKnob.width + marginRight
    waveSpreadKnob.size = knobSize
    waveSpreadKnob.fillColour = knobColour
    waveSpreadKnob.outlineColour = unisonColour
    waveSpreadKnob.changed = function(self)
      wavetableMacros["waveSpread"]:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    waveSpreadKnob:changed()
    table.insert(tweakables, {widget=waveSpreadKnob,ceiling=0.5,probability=30,default=30,useDuration=true,excludeWithTwequencer=true,category="synthesis"})
  end

  unisonVoicesKnob.changed = function(self)
    local unisonActive = false
    if isAnalog then
      osc1:setParameter("NumOscillators", self.value)
      osc2:setParameter("NumOscillators", self.value)
    elseif isAnalogStack then
      setStackVoices(self.value, unisonDetuneKnob.value, stereoSpreadKnob.value, randomPhaseStartKnob.value)
    elseif isWavetable or isAdditive then
      local factor = 1 / (unisonVoicesMax + 1)
      local value = factor * self.value
      wavetableMacros["unisonVoices"]:setParameter("Value", value)
    elseif isAnalog3Osc then
      osc1Layer:setParameter("NumVoicesPerNote", self.value)
      osc2:setParameter("NumOscillators", self.value)  
    elseif isFM then
      osc1Layer:setParameter("NumVoicesPerNote", self.value)
      osc2Layer:setParameter("NumVoicesPerNote", self.value)
    end
    if self.value == 1 then
      self.displayText = "Off"
    else
      self.displayText = tostring(self.value)
      unisonActive = true
    end
    unisonDetuneKnob.enabled = unisonActive
    stereoSpreadKnob.enabled = unisonActive
    if waveSpreadKnob then
      waveSpreadKnob.enabled = unisonActive
    end
    noiseOsc:setParameter("Stereo", unisonActive)
  end
  unisonVoicesKnob:changed()
  table.insert(tweakables, {widget=unisonVoicesKnob,min=unisonVoicesMax,default=25,excludeWithTwequencer=true,category="synthesis"})

  return mixerPanel
end

local mixerPanel = createMixerPanel()

--------------------------------------------------------------------------------
-- Low-pass Filter
--------------------------------------------------------------------------------

function createFilterPanel()  
  local filterPanel = Panel("Filter")

  if isFM then
    local types = {"Low Pass", "High Pass", "Band Pass", "Notch", "Low Shelf", "High Shelf", "Peak"}
    local filterTypeMenu = filterPanel:Menu("FilterType", types)
    filterTypeMenu.backgroundColour = menuBackgroundColour
    filterTypeMenu.textColour = menuTextColour
    filterTypeMenu.arrowColour = menuArrowColour
    filterTypeMenu.outlineColour = menuOutlineColour
    filterTypeMenu.displayName = "Filter"
    filterTypeMenu.changed = function(self)
      local factor = 1 / #types
      local value = (self.value - 0.5) * factor
      FMMacros["filterType"]:setParameter("Value", value)
    end
    filterTypeMenu:changed()
    table.insert(tweakables, {widget=filterTypeMenu,min=#types,default=85,category="filter"})

    local slopes = {"6dB", "12dB", "18dB", "24dB", "36dB", "48dB", "72dB", "96dB"}
    local filterDbMenu = filterPanel:Menu("FilterDb", slopes)
    filterDbMenu.backgroundColour = menuBackgroundColour
    filterDbMenu.textColour = menuTextColour
    filterDbMenu.arrowColour = menuArrowColour
    filterDbMenu.outlineColour = menuOutlineColour
    filterDbMenu.showLabel = false
    filterDbMenu.selected = 4
    filterDbMenu.height = 18
    filterDbMenu.x = filterTypeMenu.x
    filterDbMenu.y = filterTypeMenu.y + filterTypeMenu.height + (marginY*2)
    filterDbMenu.changed = function(self)
      local factor = 1 / #slopes
      local value = (self.value - 0.5) * factor
      FMMacros["filterDb"]:setParameter("Value", value)
      local resonanceKnob = getWidget("Resonance")
      if resonanceKnob then
        resonanceKnob.enabled = self.value > 1
      end
    end
    filterDbMenu:changed()
    table.insert(tweakables, {widget=filterDbMenu,min=#slopes,default=85,category="filter"})
  elseif isAnalog or isWavetable or isAnalog3Osc then
    local slopes = {"24dB", "12dB"}
    if isMinilogue then
      slopes = {"4-pole", "2-pole"}
    end
    local filterDbMenu = filterPanel:Menu("FilterDb", slopes)
    filterDbMenu.backgroundColour = menuBackgroundColour
    filterDbMenu.textColour = menuTextColour
    filterDbMenu.arrowColour = menuArrowColour
    filterDbMenu.outlineColour = menuOutlineColour
    filterDbMenu.displayName = "Low-pass Filter"
    filterDbMenu.changed = function(self)
      if isMinilogue then
        local value = self.value
        if self.value == 2 then
          value = 1
        else
          value = 3
        end
        filterInsert1:setParameter("Mode", value)
        filterInsert2:setParameter("Mode", value)
        filterInsert3:setParameter("Mode", value)
      else
        local value = -1
        if self.value == 2 then
          value = 1
        end
        if isWavetable then
          wavetableMacros["filterDb"]:setParameter("Value", value)
        else
          analogMacros["filterDb"]:setParameter("Value", value)
        end
      end
    end
    filterDbMenu:changed()
    table.insert(tweakables, {widget=filterDbMenu,min=#slopes,default=70,category="filter"})
  else
    filterPanel:Label("Low-pass Filter")
  end

  local cutoffKnob = filterPanel:Knob("Cutoff", 1, 0, 1)
  cutoffKnob.displayName = "Cutoff"
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
  table.insert(tweakables, {widget=cutoffKnob,floor=0.3,ceiling=0.7,probability=85,zero=25,default=35,useDuration=true,category="filter"})

  local filterResonanceKnob = filterPanel:Knob("Resonance", 0, 0, 1)
  filterResonanceKnob.fillColour = knobColour
  filterResonanceKnob.outlineColour = filterColour
  filterResonanceKnob.changed = function(self)
    filterResonance:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  filterResonanceKnob:changed()
  table.insert(tweakables, {widget=filterResonanceKnob,floor=0.1,ceiling=0.6,probability=60,default=0,zero=30,absoluteLimit=0.8,useDuration=true,category="filter"})

  local filterKeyTrackingKnob = filterPanel:Knob("KeyTracking", 0, 0, 1)
  filterKeyTrackingKnob.displayName = "Key Track"
  filterKeyTrackingKnob.fillColour = knobColour
  filterKeyTrackingKnob.outlineColour = filterColour
  filterKeyTrackingKnob.changed = function(self)
    filterKeyTracking:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  filterKeyTrackingKnob:changed()
  table.insert(tweakables, {widget=filterKeyTrackingKnob,default=40,zero=50,excludeWithTwequencer=true,category="filter"})

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
  table.insert(tweakables, {widget=wheelToCutoffKnob,bipolar=25,floor=0.2,ceiling=0.4,probability=50,excludeWithTwequencer=true,category="filter"})

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
  table.insert(tweakables, {widget=atToCutoffKnob,bipolar=25,floor=0.3,ceiling=0.6,probability=50,excludeWithTwequencer=true,category="filter"})

  return filterPanel
end

local filterPanel = createFilterPanel()

--------------------------------------------------------------------------------
-- High-pass Filter
--------------------------------------------------------------------------------

function createHpFilterPanel()
  local hpFilterPanel = Panel("HPFilter")

  hpFilterPanel:Label("High-pass Filter")

  local hpfCutoffKnob = hpFilterPanel:Knob("HpfCutoff", 0, 0, 1)
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
  table.insert(tweakables, {widget=hpfCutoffKnob,ceiling=0.4,probability=90,zero=60,default=20,useDuration=true,category="filter"})

  local hpfResonanceKnob = hpFilterPanel:Knob("HpfResonance", 0, 0, 1)
  hpfResonanceKnob.displayName = "Resonance"
  hpfResonanceKnob.fillColour = knobColour
  hpfResonanceKnob.outlineColour = filterColour
  hpfResonanceKnob.changed = function(self)
    hpfResonance:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  hpfResonanceKnob:changed()
  table.insert(tweakables, {widget=hpfResonanceKnob,ceiling=0.5,probability=80,absoluteLimit=0.8,default=50,useDuration=true,category="filter"})

  local hpfKeyTrackingKnob = hpFilterPanel:Knob("HpfKeyTracking", 0, 0, 1)
  hpfKeyTrackingKnob.displayName = "Key Track"
  hpfKeyTrackingKnob.fillColour = knobColour
  hpfKeyTrackingKnob.outlineColour = filterColour
  hpfKeyTrackingKnob.changed = function(self)
    hpfKeyTracking:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  hpfKeyTrackingKnob:changed()
  table.insert(tweakables, {widget=hpfKeyTrackingKnob,floor=0.2,ceiling=0.8,probability=50,excludeWithTwequencer=true,category="filter"})

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
  table.insert(tweakables, {widget=wheelToHpfCutoffKnob,bipolar=25,floor=0.2,ceiling=0.4,probability=30,excludeWithTwequencer=true,category="filter"})

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
  table.insert(tweakables, {widget=atToHpfCutoffKnob,bipolar=25,floor=0.3,ceiling=0.7,probability=30,excludeWithTwequencer=true,category="filter"})

  return hpFilterPanel
end

local hpFilterPanel = createHpFilterPanel()

--------------------------------------------------------------------------------
-- Filter Env
--------------------------------------------------------------------------------

function createFilterEnvPanel()
  local filterEnvPanel = Panel("FilterEnv")

  local activeFilterEnvOsc = 1
  local filterEnvMenu
  if isAnalog3Osc == true then
    filterEnvPanel:Label("Filter Envelope")
  else
    filterEnvMenu = filterEnvPanel:Menu("FilterEnvOsc", {"All", "Osc 1", "Osc 2", "Noise Osc"})
    filterEnvMenu.backgroundColour = menuBackgroundColour
    filterEnvMenu.textColour = menuTextColour
    filterEnvMenu.arrowColour = menuArrowColour
    filterEnvMenu.outlineColour = menuOutlineColour
    filterEnvMenu.displayName = "Filter Envelope"
  end

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
  table.insert(tweakables, {widget=filterAttackKnob,attack=true,floor=0.001,ceiling=0.01,probability=85,default=35,defaultTweakRange=3,useDuration=false,category="filter"})

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
  table.insert(tweakables, {widget=filterDecayKnob,factor=3,decay=true,floor=0.01,ceiling=0.75,probability=50,default=10,useDuration=false,category="filter"})

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
  table.insert(tweakables, {widget=filterSustainKnob,floor=0.1,ceil=0.7,probability=80,default=5,zero=15,useDuration=false,category="filter"})

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
  table.insert(tweakables, {widget=filterReleaseKnob,release=true,factor=3,floor=0.01,ceiling=0.8,probability=70,default=35,defaultTweakRange=2,useDuration=true,category="filter"})

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
  table.insert(tweakables, {widget=filterVelocityKnob,floor=5,ceiling=25,probability=80,min=40,default=70,useDuration=true,category="filter"})

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

  if filterEnvMenu then
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
  end

  return filterEnvPanel
end

local filterEnvPanel = createFilterEnvPanel()

--------------------------------------------------------------------------------
-- Filter Env Targets
--------------------------------------------------------------------------------

function createFilterEnvTargetsPanel()
  local filterEnvTargetsPanel = Panel("FilterEnvTargets")

  filterEnvTargetsPanel:Label("Filter Env ->")

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
  table.insert(tweakables, {widget=envAmtKnob,bipolar=5,floor=0.3,ceiling=0.9,probability=60,default=3,zero=3,useDuration=true,category="filter"})

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
  table.insert(tweakables, {widget=hpfEnvAmtKnob,absoluteLimit=0.8,floor=0.1,ceiling=0.3,probability=90,zero=25,default=25,bipolar=25,useDuration=true,category="filter"})

  return filterEnvTargetsPanel
end

function createFilterEnvOscTargetsPanel()
  local filterEnvOscTargetsPanel = Panel("FilterEnvOscTargets")

  if isAnalog3Osc then
    filterEnvOscTargetsPanel:Label("Filter Env -> Osc ->")

    local filterEnvToPitchOsc1Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToPitchOsc1", 0, 0, 48)
    filterEnvToPitchOsc1Knob.displayName = "Pitch 1"
    filterEnvToPitchOsc1Knob.mapper = Mapper.Quadratic
    filterEnvToPitchOsc1Knob.fillColour = knobColour
    filterEnvToPitchOsc1Knob.outlineColour = filterEnvColour
    filterEnvToPitchOsc1Knob.changed = function(self)
      local factor = 1 / 48
      local value = self.value * factor
      filterEnvToPitchOsc1:setParameter("Value", value)
    end
    filterEnvToPitchOsc1Knob:changed()
    table.insert(tweakables, {widget=filterEnvToPitchOsc1Knob,ceiling=0.1,probability=90,default=80,zero=30,category="filter"})

    -- TODO Adjust if hardsync enabled
    local filterEnvToPitchOsc2Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToPitchOsc2", 0, 0, 48)
    filterEnvToPitchOsc2Knob.displayName = "Pitch 2"
    filterEnvToPitchOsc2Knob.mapper = Mapper.Quadratic
    filterEnvToPitchOsc2Knob.fillColour = knobColour
    filterEnvToPitchOsc2Knob.outlineColour = filterEnvColour
    filterEnvToPitchOsc2Knob.changed = function(self)
      local factor = 1 / 48
      local value = self.value * factor
      filterEnvToPitchOsc2:setParameter("Value", value)
    end
    filterEnvToPitchOsc2Knob:changed()
    table.insert(tweakables, {widget=filterEnvToPitchOsc2Knob,ceiling=0.1,probability=85,default=75,zero=25,category="filter"})

    -- TODO Adjust if hardsync enabled
    local filterEnvToPitchOsc3Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToPitchOsc3", 0, 0, 48)
    filterEnvToPitchOsc3Knob.displayName = "Pitch 3"
    filterEnvToPitchOsc3Knob.mapper = Mapper.Quadratic
    filterEnvToPitchOsc3Knob.fillColour = knobColour
    filterEnvToPitchOsc3Knob.outlineColour = filterEnvColour
    filterEnvToPitchOsc3Knob.changed = function(self)
      local factor = 1 / 48
      local value = self.value * factor
      analogMacros["filterEnvToPitchOsc3"]:setParameter("Value", value)
    end
    filterEnvToPitchOsc3Knob:changed()
    table.insert(tweakables, {widget=filterEnvToPitchOsc3Knob,ceiling=0.1,probability=85,default=75,zero=25,category="filter"})
  elseif isFM then
    local filterEnvToOsc1OpBLevelKnob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvToOpBLevel", 0, 0, 1)
    filterEnvToOsc1OpBLevelKnob.displayName = "Osc1 OpB Lvl"
    filterEnvToOsc1OpBLevelKnob.fillColour = knobColour
    filterEnvToOsc1OpBLevelKnob.outlineColour = lfoColour
    filterEnvToOsc1OpBLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc1OpBLevel"]:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    filterEnvToOsc1OpBLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc1OpBLevelKnob,default=50,zero=30,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc1OpCLevelKnob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvToOpCLevel", 0, 0, 1)
    filterEnvToOsc1OpCLevelKnob.displayName = "Osc1 OpC Lvl"
    filterEnvToOsc1OpCLevelKnob.fillColour = knobColour
    filterEnvToOsc1OpCLevelKnob.outlineColour = lfoColour
    filterEnvToOsc1OpCLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc1OpCLevel"]:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    filterEnvToOsc1OpCLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc1OpCLevelKnob,default=60,zero=40,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc1OpDLevelKnob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvToOpDLevel", 0, 0, 1)
    filterEnvToOsc1OpDLevelKnob.displayName = "Osc1 OpD Lvl"
    filterEnvToOsc1OpDLevelKnob.fillColour = knobColour
    filterEnvToOsc1OpDLevelKnob.outlineColour = lfoColour
    filterEnvToOsc1OpDLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc1OpDLevel"]:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    filterEnvToOsc1OpDLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc1OpDLevelKnob,default=70,zero=50,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc2OpBLevelKnob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvToOpBLevel", 0, 0, 1)
    filterEnvToOsc2OpBLevelKnob.displayName = "Osc2 OpB Lvl"
    filterEnvToOsc2OpBLevelKnob.fillColour = knobColour
    filterEnvToOsc2OpBLevelKnob.outlineColour = lfoColour
    filterEnvToOsc2OpBLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc2OpBLevel"]:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    filterEnvToOsc2OpBLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc2OpBLevelKnob,default=50,zero=30,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc2OpCLevelKnob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvToOpCLevel", 0, 0, 1)
    filterEnvToOsc2OpCLevelKnob.displayName = "Osc2 OpC Lvl"
    filterEnvToOsc2OpCLevelKnob.fillColour = knobColour
    filterEnvToOsc2OpCLevelKnob.outlineColour = lfoColour
    filterEnvToOsc2OpCLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc2OpCLevel"]:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    filterEnvToOsc2OpCLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc2OpCLevelKnob,default=60,zero=40,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc2OpDLevelKnob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvToOpDLevel", 0, 0, 1)
    filterEnvToOsc2OpDLevelKnob.displayName = "Osc2 OpD Lvl"
    filterEnvToOsc2OpDLevelKnob.fillColour = knobColour
    filterEnvToOsc2OpDLevelKnob.outlineColour = lfoColour
    filterEnvToOsc2OpDLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc2OpDLevel"]:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    filterEnvToOsc2OpDLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc2OpDLevelKnob,default=70,zero=50,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})
  elseif isAnalog or isAdditive or isWavetable then
    filterEnvOscTargetsPanel:Label("Filter Env -> Osc 1 ->")

    if isAnalog then
      local filterEnvToHardsync1Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToHardsync1", 0, 0, 1)
      filterEnvToHardsync1Knob.displayName = "Hardsync"
      filterEnvToHardsync1Knob.fillColour = knobColour
      filterEnvToHardsync1Knob.outlineColour = filterEnvColour
      filterEnvToHardsync1Knob.changed = function(self)
        analogMacros["filterEnvToHardsync1"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      filterEnvToHardsync1Knob:changed()
      table.insert(tweakables, {widget=filterEnvToHardsync1Knob,zero=50,default=70,ceiling=0.5,probability=80,useDuration=true,category="filter"})
    elseif isWavetable then
      local filterEnvToWT1Knob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvToIndex", 0, -1, 1)
      filterEnvToWT1Knob.displayName = "Waveindex"
      filterEnvToWT1Knob.fillColour = knobColour
      filterEnvToWT1Knob.outlineColour = lfoColour
      filterEnvToWT1Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["filterEnvToWT1"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      filterEnvToWT1Knob:changed()
      table.insert(tweakables, {widget=filterEnvToWT1Knob,bipolar=25,useDuration=true,category="filter"})
    elseif isAdditive then
      local oscFilterEnvAmtKnob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvelopeAmt", 0, -1, 1)
      oscFilterEnvAmtKnob.displayName = "Cutoff"
      oscFilterEnvAmtKnob.fillColour = knobColour
      oscFilterEnvAmtKnob.outlineColour = filterColour
      oscFilterEnvAmtKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["filterEnvToCutoff1"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      oscFilterEnvAmtKnob:changed()
      table.insert(tweakables, {widget=oscFilterEnvAmtKnob,bipolar=25,floor=0,ceiling=0.8,probability=30,useDuration=true,category="filter"})
    end

    local filterEnvToPitchOsc1Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToPitchOsc1", 0, 0, 48)
    filterEnvToPitchOsc1Knob.displayName = "Pitch"
    filterEnvToPitchOsc1Knob.mapper = Mapper.Quadratic
    filterEnvToPitchOsc1Knob.fillColour = knobColour
    filterEnvToPitchOsc1Knob.outlineColour = filterEnvColour
    filterEnvToPitchOsc1Knob.changed = function(self)
      local factor = 1 / 48
      local value = self.value * factor
      filterEnvToPitchOsc1:setParameter("Value", value)
    end
    filterEnvToPitchOsc1Knob:changed()
    table.insert(tweakables, {widget=filterEnvToPitchOsc1Knob,ceiling=0.8,probability=90,default=80,zero=10,useDuration=true,category="filter"})

    filterEnvOscTargetsPanel:Label("Filter Env -> Osc 2 ->")

    if isAnalog then
      local filterEnvToHardsync2Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToHardsync2", 0, 0, 1)
      filterEnvToHardsync2Knob.displayName = "Hardsync"
      filterEnvToHardsync2Knob.fillColour = knobColour
      filterEnvToHardsync2Knob.outlineColour = filterEnvColour
      filterEnvToHardsync2Knob.changed = function(self)
        analogMacros["filterEnvToHardsync2"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      filterEnvToHardsync2Knob:changed()
      table.insert(tweakables, {widget=filterEnvToHardsync2Knob,zero=50,default=70,floor=0.1,ceiling=0.4,probability=90,useDuration=true,category="filter"})
    elseif isWavetable then
      local filterEnvToWT2Knob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvToIndex", 0, -1, 1)
      filterEnvToWT2Knob.displayName = "Waveindex"
      filterEnvToWT2Knob.fillColour = knobColour
      filterEnvToWT2Knob.outlineColour = lfoColour
      filterEnvToWT2Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["filterEnvToWT2"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      filterEnvToWT2Knob:changed()
      table.insert(tweakables, {widget=filterEnvToWT2Knob,bipolar=25,zero=25,floor=0.2,ceiling=0.7,probability=20,useDuration=true,category="filter"})
    elseif isAdditive then
      local oscFilterEnvAmtKnob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvelopeAmt", 0, -1, 1)
      oscFilterEnvAmtKnob.displayName = "Cutoff"
      oscFilterEnvAmtKnob.fillColour = knobColour
      oscFilterEnvAmtKnob.outlineColour = filterColour
      oscFilterEnvAmtKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["filterEnvToCutoff2"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      oscFilterEnvAmtKnob:changed()
      table.insert(tweakables, {widget=oscFilterEnvAmtKnob,bipolar=25,default=25,floor=0.1,ceiling=0.6,probability=10,useDuration=true,category="filter"})
    end

    local filterEnvToPitchOsc2Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToPitchOsc2", 0, 0, 48)
    filterEnvToPitchOsc2Knob.displayName = "Pitch"
    filterEnvToPitchOsc2Knob.mapper = Mapper.Quadratic
    filterEnvToPitchOsc2Knob.fillColour = knobColour
    filterEnvToPitchOsc2Knob.outlineColour = filterEnvColour
    filterEnvToPitchOsc2Knob.changed = function(self)
      local factor = 1 / 48
      local value = self.value * factor
      filterEnvToPitchOsc2:setParameter("Value", value)
    end
    filterEnvToPitchOsc2Knob:changed()
    table.insert(tweakables, {widget=filterEnvToPitchOsc2Knob,ceiling=0.1,probability=85,default=75,zero=25,useDuration=true,category="filter"})
  end

  return filterEnvOscTargetsPanel
end

local filterEnvTargetsPanel = createFilterEnvTargetsPanel()
local filterEnvOscTargetsPanel = createFilterEnvOscTargetsPanel()

--------------------------------------------------------------------------------
-- LFO
--------------------------------------------------------------------------------

function createLfoPanel()
  local lfoPanel = Panel("LFO")

  local activeLfoOsc = 1

  local lfoMenu
  if isAnalog3Osc == true then
    lfoPanel:Label("LFO")
  else
    lfoMenu = lfoPanel:Menu("LfoOsc", {"All", "Osc 1", "Osc 2", "Noise Osc"})
    lfoMenu.backgroundColour = menuBackgroundColour
    lfoMenu.textColour = menuTextColour
    lfoMenu.arrowColour = menuArrowColour
    lfoMenu.outlineColour = menuOutlineColour
    lfoMenu.displayName = "LFO"
  end

  local waveFormTypes = {"Sinus", "Square", "Triangle", "Ramp Up", "Ramp Down", "Analog Square", "S&H", "Chaos Lorenz", "Chaos Rossler"}
  local waveFormTypeMenu = lfoPanel:Menu("WaveFormTypeMenu", waveFormTypes)
  waveFormTypeMenu.backgroundColour = menuBackgroundColour
  waveFormTypeMenu.textColour = menuTextColour
  waveFormTypeMenu.arrowColour = menuArrowColour
  waveFormTypeMenu.outlineColour = menuOutlineColour
  waveFormTypeMenu.displayName = "Waveform"
  waveFormTypeMenu.selected = 1
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
  lfo2SyncButton.alpha = buttonAlpha
  lfo2SyncButton.backgroundColourOff = buttonBackgroundColourOff
  lfo2SyncButton.backgroundColourOn = buttonBackgroundColourOn
  lfo2SyncButton.textColourOff = buttonTextColourOff
  lfo2SyncButton.textColourOn = buttonTextColourOn
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
      lfoFreqKnob.default = 13
      lfoFreqKnob.mapper = Mapper.Linear
      lfoFreqKnob.changed = function(self)
        -- Uses beat ratio when synced: 4 is 1/1, 0.25 is 1/16
        local index = math.floor(self.value) + 7
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
  table.insert(tweakables, {widget=lfo2SyncButton,func=getRandomBoolean,excludeWithTwequencer=true,category="modulation"})

  table.insert(tweakables, {widget=lfoFreqKnob,factor=20,floor=0.1,ceiling=0.5,probability=25,useDuration=true,category="modulation"})

  local lfo2TriggerButton = lfoPanel:OnOffButton("Lfo2Trigger", true)
  lfo2TriggerButton.alpha = buttonAlpha
  lfo2TriggerButton.backgroundColourOff = buttonBackgroundColourOff
  lfo2TriggerButton.backgroundColourOn = buttonBackgroundColourOn
  lfo2TriggerButton.textColourOff = buttonTextColourOff
  lfo2TriggerButton.textColourOn = buttonTextColourOn
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
  table.insert(tweakables, {widget=lfoFreqKeyFollowKnob,ceiling=0.5,probability=50,default=15,zero=75,excludeWithTwequencer=true,category="modulation"})

  local lfoDelayKnob = lfoPanel:Knob("LfoDelay", 0, 0, 10)
  lfoDelayKnob.displayName="Delay"
  lfoDelayKnob.fillColour = knobColour
  lfoDelayKnob.outlineColour = lfoColour
  lfoDelayKnob.mapper = Mapper.Quartic
  lfoDelayKnob.x = waveFormTypeMenu.x
  lfoDelayKnob.y = 70
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
  table.insert(tweakables, {widget=lfoDelayKnob,factor=5,ceiling=2,probability=50,default=35,zero=50,useDuration=true,category="modulation"})

  local lfoRiseKnob = lfoPanel:Knob("LfoRise", 0, 0, 10)
  lfoRiseKnob.displayName="Rise"
  lfoRiseKnob.fillColour = knobColour
  lfoRiseKnob.outlineColour = lfoColour
  lfoRiseKnob.mapper = Mapper.Quartic
  lfoRiseKnob.x = lfoFreqKnob.x
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
  table.insert(tweakables, {widget=lfoRiseKnob,factor=5,ceiling=2,probability=50,default=35,zero=50,useDuration=true,category="modulation"})

  local lfoSmoothKnob = lfoPanel:Knob("LfoSmooth", 0, 0, 1)
  lfoSmoothKnob.displayName="Smooth"
  lfoSmoothKnob.fillColour = knobColour
  lfoSmoothKnob.outlineColour = lfoColour
  lfoSmoothKnob.mapper = Mapper.Quartic
  lfoSmoothKnob.x = lfo2SyncButton.x
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
  table.insert(tweakables, {widget=lfoSmoothKnob,ceiling=0.3,probability=50,default=50,zero=70,useDuration=true,category="modulation"})

  local lfoBipolarButton = lfoPanel:OnOffButton("LfoBipolar", true)
  lfoBipolarButton.alpha = buttonAlpha
  lfoBipolarButton.backgroundColourOff = buttonBackgroundColourOff
  lfoBipolarButton.backgroundColourOn = buttonBackgroundColourOn
  lfoBipolarButton.textColourOff = buttonTextColourOff
  lfoBipolarButton.textColourOn = buttonTextColourOn
  lfoBipolarButton.width = 75
  lfoBipolarButton.x = lfoFreqKeyFollowKnob.x
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

  if lfoMenu then
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
  end

  return lfoPanel
end

local lfoPanel = createLfoPanel()

--------------------------------------------------------------------------------
-- LFO Targets
--------------------------------------------------------------------------------

function createLfoTargetPanel()
  local lfoNoiseOscOverride = false
  local activeLfoTargetOsc = 1
  local lfoTargetPanel = Panel("LfoTargetPanel")
  
  local lfoTargetOscMenu
  if isAnalog3Osc == true then
    lfoTargetPanel:Label("LFO ->")
  else
    lfoTargetOscMenu = lfoTargetPanel:Menu("LfoTargetOsc", {"All", "Noise Osc"})
    lfoTargetOscMenu.backgroundColour = menuBackgroundColour
    lfoTargetOscMenu.textColour = menuTextColour
    lfoTargetOscMenu.arrowColour = menuArrowColour
    lfoTargetOscMenu.outlineColour = menuOutlineColour
    lfoTargetOscMenu.displayName = "LFO ->"
  end

  ------- OSC 1+2 ----------

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
  table.insert(tweakables, {widget=lfoToCutoffKnob,bipolar=25,default=30,floor=0.01,ceiling=0.35,probability=50,useDuration=true,category="modulation"})

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
  table.insert(tweakables, {widget=lfoToHpfCutoffKnob,bipolar=25,default=50,floor=0.1,ceiling=0.3,probability=50,useDuration=true,category="modulation"})

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
  table.insert(tweakables, {widget=lfoToAmpKnob,bipolar=25,default=60,floor=0.3,ceiling=0.8,probability=50,useDuration=true,category="modulation"})

  local lfoToDetuneKnob = lfoTargetPanel:Knob("LfoToDetune", 0, 0, 1)
  lfoToDetuneKnob.displayName = "Detune"
  lfoToDetuneKnob.fillColour = knobColour
  lfoToDetuneKnob.outlineColour = lfoColour
  lfoToDetuneKnob.changed = function(self)
    lfoToDetune:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  lfoToDetuneKnob:changed()
  table.insert(tweakables, {widget=lfoToDetuneKnob,default=50,ceiling=0.25,probability=30,useDuration=true,category="modulation"})

  local wheelToLfoKnob = lfoTargetPanel:Knob("WheelToLfo", 0, 0, 1)
  wheelToLfoKnob.displayName = "Via Wheel"
  wheelToLfoKnob.fillColour = knobColour
  wheelToLfoKnob.outlineColour = lfoColour
  wheelToLfoKnob.changed = function(self)
    wheelToLfo:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  wheelToLfoKnob:changed()
  table.insert(tweakables, {widget=wheelToLfoKnob,default=75,floor=0.5,ceiling=1.0,probability=50,excludeWithTwequencer=true,category="modulation"})

  ------- NOISE OSC ----------

  if lfoTargetOscMenu then
    local lfoToNoiseLpfCutoffKnob = lfoTargetPanel:Knob("LfoToNoiseLpfCutoff", 0, -1, 1)
    lfoToNoiseLpfCutoffKnob.displayName = "LP-Filter"
    lfoToNoiseLpfCutoffKnob.x = lfoToCutoffKnob.x
    lfoToNoiseLpfCutoffKnob.y = lfoToCutoffKnob.y
    lfoToNoiseLpfCutoffKnob.fillColour = knobColour
    lfoToNoiseLpfCutoffKnob.outlineColour = lfoColour
    lfoToNoiseLpfCutoffKnob.changed = function(self)
      local value = (self.value + 1) * 0.5
      lfoToNoiseLpf:setParameter("Value", value)
      self.displayText = percent(self.value)
    end

    local lfoToNoiseHpfCutoffKnob = lfoTargetPanel:Knob("LfoToNoiseHpfCutoff", 0, -1, 1)
    lfoToNoiseHpfCutoffKnob.displayName = "HP-Filter"
    lfoToNoiseHpfCutoffKnob.x = lfoToHpfCutoffKnob.x
    lfoToNoiseHpfCutoffKnob.y = lfoToHpfCutoffKnob.y
    lfoToNoiseHpfCutoffKnob.fillColour = knobColour
    lfoToNoiseHpfCutoffKnob.outlineColour = lfoColour
    lfoToNoiseHpfCutoffKnob.changed = function(self)
      local value = (self.value + 1) * 0.5
      lfoToNoiseHpf:setParameter("Value", value)
      self.displayText = percent(self.value)
    end

    local lfoToNoiseAmpKnob = lfoTargetPanel:Knob("LfoToNoiseAmplitude", 0, -1, 1)
    lfoToNoiseAmpKnob.displayName = "Amplitude"
    lfoToNoiseAmpKnob.x = lfoToAmpKnob.x
    lfoToNoiseAmpKnob.y = lfoToAmpKnob.y
    lfoToNoiseAmpKnob.fillColour = knobColour
    lfoToNoiseAmpKnob.outlineColour = lfoColour
    lfoToNoiseAmpKnob.changed = function(self)
      local value = (self.value + 1) * 0.5
      lfoToNoiseAmp:setParameter("Value", value)
      self.displayText = percent(self.value)
    end

    local lfoToNoiseOverrideButton = lfoTargetPanel:OnOffButton("LfoToNoiseOverride", lfoNoiseOscOverride)
    lfoToNoiseOverrideButton.displayName = "Unlink"
    lfoToNoiseOverrideButton.x = lfoToDetuneKnob.x
    lfoToNoiseOverrideButton.y = lfoToDetuneKnob.y
    lfoToNoiseOverrideButton.width = 75
    lfoToNoiseOverrideButton.changed = function(self)
      lfoNoiseOscOverride = self.value
      lfoToNoiseLpfCutoffKnob.enabled = lfoNoiseOscOverride
      lfoToNoiseLpfCutoffKnob:changed()
      lfoToNoiseHpfCutoffKnob.enabled = lfoNoiseOscOverride
      lfoToNoiseHpfCutoffKnob:changed()
      lfoToNoiseAmpKnob.enabled = lfoNoiseOscOverride
      lfoToNoiseAmpKnob:changed()
      if lfoNoiseOscOverride == false then
        lfoTargetOscMenu.items = {"All", "Noise Osc"}
        lfoToNoiseLpf:setParameter("Value", lfoToCutoff:getParameter("Value"))
        lfoToNoiseHpf:setParameter("Value", lfoToHpf:getParameter("Value"))
        lfoToNoiseAmp:setParameter("Value", lfoToAmp:getParameter("Value"))
      else
        lfoTargetOscMenu.items = {"Osc 1+2", "Noise Osc"}
      end
    end
    lfoToNoiseOverrideButton:changed()

    table.insert(tweakables, {widget=lfoToNoiseOverrideButton,func=getRandomBoolean,probability=25,category="modulation"})
    table.insert(tweakables, {widget=lfoToNoiseAmpKnob,bipolar=25,category="modulation"})
    table.insert(tweakables, {widget=lfoToNoiseHpfCutoffKnob,bipolar=25,useDuration=true,category="modulation"})
    table.insert(tweakables, {widget=lfoToNoiseLpfCutoffKnob,bipolar=25,useDuration=true,category="modulation"})

    lfoTargetOscMenu.changed = function(self)
      if self.value == 1 then
        lfoToDetuneKnob.visible = true
        lfoToAmpKnob.visible = true
        lfoToHpfCutoffKnob.visible = true
        lfoToCutoffKnob.visible = true

        lfoToNoiseOverrideButton.visible = false
        lfoToNoiseAmpKnob.visible = false
        lfoToNoiseHpfCutoffKnob.visible = false
        lfoToNoiseLpfCutoffKnob.visible = false
      else
        lfoToDetuneKnob.visible = false
        lfoToAmpKnob.visible = false
        lfoToHpfCutoffKnob.visible = false
        lfoToCutoffKnob.visible = false

        lfoToNoiseOverrideButton.visible = true
        lfoToNoiseAmpKnob.visible = true
        lfoToNoiseHpfCutoffKnob.visible = true
        lfoToNoiseLpfCutoffKnob.visible = true
      end
    end

    lfoTargetOscMenu:changed()
  end

  return lfoTargetPanel
end

local lfoTargetPanel = createLfoTargetPanel()

--------------------------------------------------------------------------------
-- LFO Targets Osc 1
--------------------------------------------------------------------------------

function createLfoTargetPanel1()
  local lfoTargetPanel1 = Panel("LfoTargetPanel1")

  if isAnalog3Osc then
    lfoTargetPanel1:Label("LFO -> Osc ->")

    local osc1LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOsc1PWM", 0, 0, 0.5)
    osc1LfoToPWMKnob.displayName = "PWM 1"
    osc1LfoToPWMKnob.mapper = Mapper.Quadratic
    osc1LfoToPWMKnob.fillColour = knobColour
    osc1LfoToPWMKnob.outlineColour = lfoColour
    osc1LfoToPWMKnob.changed = function(self)
      osc1LfoToPWM:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    osc1LfoToPWMKnob:changed()
    table.insert(tweakables, {widget=osc1LfoToPWMKnob,ceiling=0.25,probability=90,default=60,useDuration=true,category="modulation"})

    local osc2LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOsc2PWM", 0, 0, 0.5)
    osc2LfoToPWMKnob.displayName = "PWM 2"
    osc2LfoToPWMKnob.mapper = Mapper.Quadratic
    osc2LfoToPWMKnob.fillColour = knobColour
    osc2LfoToPWMKnob.outlineColour = lfoColour
    osc2LfoToPWMKnob.changed = function(self)
      osc2LfoToPWM:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    osc2LfoToPWMKnob:changed()
    table.insert(tweakables, {widget=osc2LfoToPWMKnob,ceiling=0.25,probability=90,default=60,useDuration=true,category="modulation"})

    local osc3LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOsc3PWM", 0, 0, 0.5)
    osc3LfoToPWMKnob.displayName = "PWM 3"
    osc3LfoToPWMKnob.mapper = Mapper.Quadratic
    osc3LfoToPWMKnob.fillColour = knobColour
    osc3LfoToPWMKnob.outlineColour = lfoColour
    osc3LfoToPWMKnob.changed = function(self)
      analogMacros["osc3LfoToPWM"]:setParameter("Value", self.value)
      self.displayText = percent(self.value)
    end
    osc3LfoToPWMKnob:changed()
    table.insert(tweakables, {widget=osc3LfoToPWMKnob,ceiling=0.25,probability=90,default=60,useDuration=true,category="modulation"})
  else
    lfoTargetPanel1:Label("LFO -> Osc 1 ->")

    if isAnalog or isAdditive or isWavetable or isAnalogStack then
      local osc1LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOsc1PWM", 0, 0, 0.5)
      osc1LfoToPWMKnob.displayName = "PWM"
      osc1LfoToPWMKnob.mapper = Mapper.Quadratic
      osc1LfoToPWMKnob.fillColour = knobColour
      osc1LfoToPWMKnob.outlineColour = lfoColour
      osc1LfoToPWMKnob.changed = function(self)
        osc1LfoToPWM:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      osc1LfoToPWMKnob:changed()
      table.insert(tweakables, {widget=osc1LfoToPWMKnob,ceiling=0.25,probability=90,default=50,useDuration=true,category="modulation"})
    end

    if isAnalog then
      local lfoToHardsync1Knob = lfoTargetPanel1:Knob("LfoToHardsync1", 0, 0, 1)
      lfoToHardsync1Knob.displayName = "Hardsync"
      lfoToHardsync1Knob.fillColour = knobColour
      lfoToHardsync1Knob.outlineColour = lfoColour
      lfoToHardsync1Knob.changed = function(self)
        analogMacros["lfoToHardsync1"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToHardsync1Knob:changed()
      table.insert(tweakables, {widget=lfoToHardsync1Knob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,useDuration=true,category="modulation"})
    elseif isAdditive then
      local lfoToEvenOdd1Knob = lfoTargetPanel1:Knob("LfoToEvenOdd1", 0, 0, 1)
      lfoToEvenOdd1Knob.displayName = "Even/Odd"
      lfoToEvenOdd1Knob.fillColour = knobColour
      lfoToEvenOdd1Knob.outlineColour = lfoColour
      lfoToEvenOdd1Knob.changed = function(self)
        additiveMacros["lfoToEvenOdd1"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToEvenOdd1Knob:changed()
      table.insert(tweakables, {widget=lfoToEvenOdd1Knob,zero=50,default=70,floor=0.3,ceiling=0.9,probability=20,category="modulation"})

      local lfoToCutoffKnob = lfoTargetPanel1:Knob("LfoToOsc1Cutoff", 0, -1, 1)
      lfoToCutoffKnob.displayName = "Cutoff"
      lfoToCutoffKnob.fillColour = knobColour
      lfoToCutoffKnob.outlineColour = lfoColour
      lfoToCutoffKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["lfoToOsc1Cutoff"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      lfoToCutoffKnob:changed()
      table.insert(tweakables, {widget=lfoToCutoffKnob,bipolar=25,default=30,floor=0.1,ceiling=0.5,probability=20,useDuration=true,category="modulation"})
    elseif isWavetable then
      local lfoToWT1Knob = lfoTargetPanel1:Knob("Osc1LfoToWaveIndex", 0, -1, 1)
      lfoToWT1Knob.displayName = "Waveindex"
      lfoToWT1Knob.fillColour = knobColour
      lfoToWT1Knob.outlineColour = lfoColour
      lfoToWT1Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["lfoToWT1"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      lfoToWT1Knob:changed()
      table.insert(tweakables, {widget=lfoToWT1Knob,bipolar=25,default=25,floor=0.3,ceiling=0.9,probability=20,useDuration=true,category="modulation"})

      local lfoToWaveSpread1Knob = lfoTargetPanel1:Knob("LfoToWaveSpreadOsc1", 0, -1, 1)
      lfoToWaveSpread1Knob.displayName = "WaveSpread"
      lfoToWaveSpread1Knob.fillColour = knobColour
      lfoToWaveSpread1Knob.outlineColour = lfoColour
      lfoToWaveSpread1Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["lfoToWaveSpread1"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      lfoToWaveSpread1Knob:changed()
      table.insert(tweakables, {widget=lfoToWaveSpread1Knob,bipolar=80,default=50,ceiling=0.4,probability=30,useDuration=true,category="modulation"})
    elseif isFM then
      local lfoToOsc1OpBLevelKnob = lfoTargetPanel1:Knob("LfoToOsc1OpBLevelKnob", 0, 0, 1)
      lfoToOsc1OpBLevelKnob.displayName = "Op B Level"
      lfoToOsc1OpBLevelKnob.fillColour = knobColour
      lfoToOsc1OpBLevelKnob.outlineColour = lfoColour
      lfoToOsc1OpBLevelKnob.changed = function(self)
        FMMacros["lfoToOsc1OpBLevel"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToOsc1OpBLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1OpBLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc1OpCLevelKnob = lfoTargetPanel1:Knob("LfoToOsc1OpCLevelKnob", 0, 0, 1)
      lfoToOsc1OpCLevelKnob.displayName = "Op C Level"
      lfoToOsc1OpCLevelKnob.fillColour = knobColour
      lfoToOsc1OpCLevelKnob.outlineColour = lfoColour
      lfoToOsc1OpCLevelKnob.changed = function(self)
        FMMacros["lfoToOsc1OpCLevel"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToOsc1OpCLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1OpCLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc1OpDLevelKnob = lfoTargetPanel1:Knob("LfoToOsc1OpDLevelKnob", 0, 0, 1)
      lfoToOsc1OpDLevelKnob.displayName = "Op D Level"
      lfoToOsc1OpDLevelKnob.fillColour = knobColour
      lfoToOsc1OpDLevelKnob.outlineColour = lfoColour
      lfoToOsc1OpDLevelKnob.changed = function(self)
        FMMacros["lfoToOsc1OpDLevel"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToOsc1OpDLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1OpDLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc1FeedbackKnob = lfoTargetPanel1:Knob("LfoToOsc1Feedback", 0, 0, 1)
      lfoToOsc1FeedbackKnob.displayName = "Feedback"
      lfoToOsc1FeedbackKnob.fillColour = knobColour
      lfoToOsc1FeedbackKnob.outlineColour = lfoColour
      lfoToOsc1FeedbackKnob.changed = function(self)
        FMMacros["lfoToOsc1Feedback"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToOsc1FeedbackKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1FeedbackKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})
    end

    if isAnalog or isAdditive or isWavetable or isFM then
      local lfoToPitchOsc1Knob = lfoTargetPanel1:Knob("LfoToPitchOsc1Knob", 0, 0, 48)
      lfoToPitchOsc1Knob.displayName = "Pitch"
      lfoToPitchOsc1Knob.mapper = Mapper.Quadratic
      lfoToPitchOsc1Knob.fillColour = knobColour
      lfoToPitchOsc1Knob.outlineColour = lfoColour
      lfoToPitchOsc1Knob.changed = function(self)
        local factor = 1 / 48
        local value = (self.value * factor)
        lfoToPitchOsc1:setParameter("Value", value)
      end
      lfoToPitchOsc1Knob:changed()
      table.insert(tweakables, {widget=lfoToPitchOsc1Knob,ceiling=0.1,probability=75,default=75,zero=50,useDuration=true,category="modulation"})
    end
  end

  return lfoTargetPanel1
end

local lfoTargetPanel1 = createLfoTargetPanel1()

--------------------------------------------------------------------------------
-- LFO Targets Osc 2
--------------------------------------------------------------------------------

function createLfoTargetPanel2()
  local lfoTargetPanel2 = Panel("LfoTargetPanel2")

  if isAnalog3Osc then
    lfoTargetPanel2:Label("LFO -> Osc ->")

    local lfoToPitchOsc1Knob = lfoTargetPanel2:Knob("LfoToPitchOsc1Knob", 0, 0, 48)
    lfoToPitchOsc1Knob.displayName = "Pitch 1"
    lfoToPitchOsc1Knob.mapper = Mapper.Quadratic
    lfoToPitchOsc1Knob.fillColour = knobColour
    lfoToPitchOsc1Knob.outlineColour = lfoColour
    lfoToPitchOsc1Knob.changed = function(self)
      local factor = 1 / 48
      local value = (self.value * factor)
      lfoToPitchOsc1:setParameter("Value", value)
    end
    lfoToPitchOsc1Knob:changed()
    table.insert(tweakables, {widget=lfoToPitchOsc1Knob,ceiling=0.1,probability=80,default=80,zero=50,useDuration=true,category="modulation"})

    -- TODO Validate pitch modulation - if hard sync is enabled, ceiling can be higher
    local lfoToPitchOsc2Knob = lfoTargetPanel2:Knob("LfoToPitchOsc2Knob", 0, 0, 48)
    lfoToPitchOsc2Knob.displayName = "Pitch 2"
    lfoToPitchOsc2Knob.mapper = Mapper.Quadratic
    lfoToPitchOsc2Knob.fillColour = knobColour
    lfoToPitchOsc2Knob.outlineColour = lfoColour
    lfoToPitchOsc2Knob.changed = function(self)
      local factor = 1 / 48
      local value = (self.value * factor)
      lfoToPitchOsc2:setParameter("Value", value)
    end
    lfoToPitchOsc2Knob:changed()
    table.insert(tweakables, {widget=lfoToPitchOsc2Knob,ceiling=0.1,probability=75,default=80,zero=30,useDuration=true,category="modulation"})

    -- TODO Validate pitch modulation - if hard sync is enabled, ceiling can be higher
    local lfoToPitchOsc3Knob = lfoTargetPanel2:Knob("LfoToPitchOsc3Knob", 0, 0, 48)
    lfoToPitchOsc3Knob.displayName = "Pitch 3"
    lfoToPitchOsc3Knob.mapper = Mapper.Quadratic
    lfoToPitchOsc3Knob.fillColour = knobColour
    lfoToPitchOsc3Knob.outlineColour = lfoColour
    lfoToPitchOsc3Knob.changed = function(self)
      local factor = 1 / 48
      local value = (self.value * factor)
      analogMacros["lfoToPitchOsc3"]:setParameter("Value", value)
    end
    lfoToPitchOsc3Knob:changed()
    table.insert(tweakables, {widget=lfoToPitchOsc3Knob,ceiling=0.1,probability=75,default=80,zero=30,useDuration=true,category="modulation"})
  else
    lfoTargetPanel2:Label("LFO -> Osc 2 ->")

    if isAnalog or isAdditive or isWavetable or isAnalogStack then
      local osc2LfoToPWMKnob = lfoTargetPanel2:Knob("LfoToOsc2PWM", 0, 0, 0.5)
      osc2LfoToPWMKnob.displayName = "PWM"
      osc2LfoToPWMKnob.mapper = Mapper.Quadratic
      osc2LfoToPWMKnob.fillColour = knobColour
      osc2LfoToPWMKnob.outlineColour = lfoColour
      osc2LfoToPWMKnob.changed = function(self)
        osc2LfoToPWM:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      osc2LfoToPWMKnob:changed()
      table.insert(tweakables, {widget=osc2LfoToPWMKnob,ceiling=0.25,probability=90,default=50,useDuration=true,category="modulation"})
    end

    if isAnalog then
      local lfoToHardsync2Knob = lfoTargetPanel2:Knob("LfoToHardsync2", 0, 0, 1)
      lfoToHardsync2Knob.displayName = "Hardsync"
      lfoToHardsync2Knob.fillColour = knobColour
      lfoToHardsync2Knob.outlineColour = lfoColour
      lfoToHardsync2Knob.changed = function(self)
        analogMacros["lfoToHardsync2"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToHardsync2Knob:changed()
      table.insert(tweakables, {widget=lfoToHardsync2Knob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=20,useDuration=true,category="modulation"})
    elseif isAdditive then
      local lfoToEvenOdd2Knob = lfoTargetPanel2:Knob("LfoToEvenOdd2", 0, 0, 1)
      lfoToEvenOdd2Knob.displayName = "Even/Odd"
      lfoToEvenOdd2Knob.fillColour = knobColour
      lfoToEvenOdd2Knob.outlineColour = lfoColour
      lfoToEvenOdd2Knob.changed = function(self)
        additiveMacros["lfoToEvenOdd2"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToEvenOdd2Knob:changed()
      table.insert(tweakables, {widget=lfoToEvenOdd2Knob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToCutoffKnob = lfoTargetPanel2:Knob("LfoToOsc2Cutoff", 0, -1, 1)
      lfoToCutoffKnob.displayName = "Cutoff"
      lfoToCutoffKnob.fillColour = knobColour
      lfoToCutoffKnob.outlineColour = lfoColour
      lfoToCutoffKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["lfoToOsc2Cutoff"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      lfoToCutoffKnob:changed()
      table.insert(tweakables, {widget=lfoToCutoffKnob,bipolar=25,default=30,floor=0.1,ceiling=0.6,probability=20,useDuration=true,category="modulation"})
    elseif isWavetable then
      local lfoToWT2Knob = lfoTargetPanel2:Knob("Osc2LfoToWaveIndex", 0, -1, 1)
      lfoToWT2Knob.displayName = "Waveindex"
      lfoToWT2Knob.fillColour = knobColour
      lfoToWT2Knob.outlineColour = lfoColour
      lfoToWT2Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["lfoToWT2"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      lfoToWT2Knob:changed()
      table.insert(tweakables, {widget=lfoToWT2Knob,bipolar=25,default=25,floor=0.1,ceiling=0.9,probability=30,useDuration=true,category="modulation"})

      local lfoToWaveSpread2Knob = lfoTargetPanel2:Knob("LfoToWaveSpreadOsc2", 0, -1, 1)
      lfoToWaveSpread2Knob.displayName = "WaveSpread"
      lfoToWaveSpread2Knob.fillColour = knobColour
      lfoToWaveSpread2Knob.outlineColour = lfoColour
      lfoToWaveSpread2Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["lfoToWaveSpread2"]:setParameter("Value", value)
        self.displayText = percent(self.value)
      end
      lfoToWaveSpread2Knob:changed()
      table.insert(tweakables, {widget=lfoToWaveSpread2Knob,bipolar=80,default=50,floor=0.3,ceiling=0.7,probability=25,useDuration=true,category="modulation"})
    elseif isFM then
      local lfoToOsc2OpBLevelKnob = lfoTargetPanel2:Knob("LfoToOsc2OpBLevelKnob", 0, 0, 1)
      lfoToOsc2OpBLevelKnob.displayName = "Op B Level"
      lfoToOsc2OpBLevelKnob.fillColour = knobColour
      lfoToOsc2OpBLevelKnob.outlineColour = lfoColour
      lfoToOsc2OpBLevelKnob.changed = function(self)
        FMMacros["lfoToOsc2OpBLevel"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToOsc2OpBLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2OpBLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc2OpCLevelKnob = lfoTargetPanel2:Knob("LfoToOsc2OpCLevelKnob", 0, 0, 1)
      lfoToOsc2OpCLevelKnob.displayName = "Op C Level"
      lfoToOsc2OpCLevelKnob.fillColour = knobColour
      lfoToOsc2OpCLevelKnob.outlineColour = lfoColour
      lfoToOsc2OpCLevelKnob.changed = function(self)
        FMMacros["lfoToOsc2OpCLevel"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToOsc2OpCLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2OpCLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc2OpDLevelKnob = lfoTargetPanel2:Knob("LfoToOsc2OpDLevelKnob", 0, 0, 1)
      lfoToOsc2OpDLevelKnob.displayName = "Op D Level"
      lfoToOsc2OpDLevelKnob.fillColour = knobColour
      lfoToOsc2OpDLevelKnob.outlineColour = lfoColour
      lfoToOsc2OpDLevelKnob.changed = function(self)
        FMMacros["lfoToOsc2OpDLevel"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToOsc2OpDLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2OpDLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc2FeedbackKnob = lfoTargetPanel2:Knob("LfoToOsc2Feedback", 0, 0, 1)
      lfoToOsc2FeedbackKnob.displayName = "Feedback"
      lfoToOsc2FeedbackKnob.fillColour = knobColour
      lfoToOsc2FeedbackKnob.outlineColour = lfoColour
      lfoToOsc2FeedbackKnob.changed = function(self)
        FMMacros["lfoToOsc2Feedback"]:setParameter("Value", self.value)
        self.displayText = percent(self.value)
      end
      lfoToOsc2FeedbackKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2FeedbackKnob,default=50,floor=0.1,ceiling=0.3,probability=50,category="modulation"})
    end

    if isAnalog or isAdditive or isWavetable or isFM then
      local lfoToPitchOsc2Knob = lfoTargetPanel2:Knob("LfoToPitchOsc2Knob", 0, 0, 48)
      lfoToPitchOsc2Knob.displayName = "Pitch"
      lfoToPitchOsc2Knob.mapper = Mapper.Quadratic
      lfoToPitchOsc2Knob.fillColour = knobColour
      lfoToPitchOsc2Knob.outlineColour = lfoColour
      lfoToPitchOsc2Knob.changed = function(self)
        local factor = 1 / 48
        local value = (self.value * factor)
        lfoToPitchOsc2:setParameter("Value", value)
      end
      lfoToPitchOsc2Knob:changed()
      table.insert(tweakables, {widget=lfoToPitchOsc2Knob,ceiling=0.1,probability=75,default=80,zero=30,useDuration=true,category="modulation"})
    end
  end

  return lfoTargetPanel2
end

local lfoTargetPanel2 = createLfoTargetPanel2()

--------------------------------------------------------------------------------
-- Amp Env
--------------------------------------------------------------------------------

function createAmpEnvPanel()
  local ampEnvPanel = Panel("ampEnv1")

  local activeAmpEnvOsc = 1
  local ampEnvMenu
  if isAnalog3Osc == true then
    ampEnvPanel:Label("Amp Envelope")
  else
    ampEnvMenu = ampEnvPanel:Menu("AmpEnvOsc", {"All", "Osc 1", "Osc 2", "Noise Osc"})
    ampEnvMenu.displayName = "Amp Envelope"
    ampEnvMenu.backgroundColour = menuBackgroundColour
    ampEnvMenu.textColour = menuTextColour
    ampEnvMenu.arrowColour = menuArrowColour
    ampEnvMenu.outlineColour = menuOutlineColour
  end

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
  table.insert(tweakables, {widget=ampAttackKnob,attack=true,floor=0.001,ceiling=0.01,probability=85,default=20,defaultTweakRange=0.1,useDuration=false,category="synthesis"})

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
  table.insert(tweakables, {widget=ampDecayKnob,factor=3,decay=true,floor=0.01,ceiling=0.5,probability=50,default=25,useDuration=false,category="synthesis"})

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
  table.insert(tweakables, {widget=ampSustainKnob,floor=0.3,ceil=0.9,probability=80,default=60,zero=2,useDuration=false,category="synthesis"})

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
  table.insert(tweakables, {widget=ampReleaseKnob,release=true,factor=2,floor=0.01,ceiling=0.5,probability=90,default=30,defaultTweakRange=1,useDuration=false,category="synthesis"})

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
  table.insert(tweakables, {widget=ampVelocityKnob,min=40,floor=5,ceiling=25,probability=80,default=70,useDuration=true,category="synthesis"})

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

  if ampEnvMenu then
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
  end

  return ampEnvPanel
end

local ampEnvPanel = createAmpEnvPanel()

--------------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------------

function createEffectsPanel()
  local effectsPanel = Panel("EffectsPanel")

  local knobSize = {150,100}

  local effectsLabel = effectsPanel:Label("Effects")
  effectsLabel.x = 10
  effectsLabel.y = 10

  local bypassFxButton = effectsPanel:OnOffButton("BypassEffects", false)
  bypassFxButton.width = 60
  bypassFxButton.x = 640
  bypassFxButton.y = effectsLabel.y
  bypassFxButton.tooltip = "Bypass all effects"
  bypassFxButton.displayName = "Bypass"
  bypassFxButton.alpha = buttonAlpha
  bypassFxButton.backgroundColourOff = buttonBackgroundColourOff
  bypassFxButton.backgroundColourOn = buttonBackgroundColourOn
  bypassFxButton.textColourOff = buttonTextColourOff
  bypassFxButton.textColourOn = buttonTextColourOn
  bypassFxButton.changed = function(self)
    Program:setParameter("BypassInsertFX", self.value)
    if self.value then
      effectsPageButton.displayName = "Effects (Bypassed)"
    else
      effectsPageButton.displayName = "Effects"
    end
    print("BypassInsertFX:", self.value)
  end
  bypassFxButton:changed()

  local reverbKnob = effectsPanel:Knob("Reverb", 0, 0, 1)
  reverbKnob.x = 100
  reverbKnob.y = 50
  reverbKnob.size = knobSize
  reverbKnob.mapper = Mapper.Quadratic
  reverbKnob.fillColour = knobColour
  reverbKnob.outlineColour = filterEffectsColour
  reverbKnob.changed = function(self)
    reverbMix:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  reverbKnob:changed()
  table.insert(tweakables, {widget=reverbKnob,floor=0.1,ceiling=0.6,probability=100,useDuration=true,category="effects"})

  local delayKnob = effectsPanel:Knob("Delay", 0, 0, 1)
  delayKnob.size = knobSize
  delayKnob.x = 300
  delayKnob.y = reverbKnob.y
  delayKnob.mapper = Mapper.Quadratic
  delayKnob.fillColour = knobColour
  delayKnob.outlineColour = filterEffectsColour
  delayKnob.changed = function(self)
    delayMix:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  delayKnob:changed()
  table.insert(tweakables, {widget=delayKnob,floor=0.01,ceiling=0.6,probability=100,useDuration=true,category="effects"})

  local phasorMixKnob = effectsPanel:Knob("Phasor", 0, 0, 1)
  phasorMixKnob.size = knobSize
  phasorMixKnob.x = 500
  phasorMixKnob.y = reverbKnob.y
  phasorMixKnob.mapper = Mapper.Quadratic
  phasorMixKnob.fillColour = knobColour
  phasorMixKnob.outlineColour = filterEffectsColour
  phasorMixKnob.changed = function(self)
    phasorMix:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  phasorMixKnob:changed()
  table.insert(tweakables, {widget=phasorMixKnob,default=80,zero=50,ceiling=0.75,probability=20,useDuration=true,category="effects"})

  local chorusKnob = effectsPanel:Knob("Chorus", 0, 0, 1)
  chorusKnob.size = knobSize
  chorusKnob.x = reverbKnob.x
  chorusKnob.y = delayKnob.y + delayKnob.height + 20
  chorusKnob.mapper = Mapper.Quadratic
  chorusKnob.fillColour = knobColour
  chorusKnob.outlineColour = filterEffectsColour
  chorusKnob.changed = function(self)
    chorusMix:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  chorusKnob:changed()
  table.insert(tweakables, {widget=chorusKnob,floor=0.01,ceiling=0.5,probability=60,default=50,useDuration=true,category="effects"})

  local driveKnob = effectsPanel:Knob("Drive", 0, 0, 1)
  driveKnob.size = knobSize
  driveKnob.x = delayKnob.x
  driveKnob.y = chorusKnob.y
  driveKnob.mapper = Mapper.Quadratic
  driveKnob.fillColour = knobColour
  driveKnob.outlineColour = filterEffectsColour
  driveKnob.changed = function(self)
    driveAmount:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  driveKnob:changed()
  table.insert(tweakables, {widget=driveKnob,ceiling=0.25,probability=90,absoluteLimit=0.6,default=60,useDuration=true,category="effects"})

  local maximizerButton = effectsPanel:OnOffButton("Maximizer", false)
  maximizerButton.alpha = buttonAlpha
  maximizerButton.backgroundColourOff = buttonBackgroundColourOff
  maximizerButton.backgroundColourOn = buttonBackgroundColourOn
  maximizerButton.textColourOff = buttonTextColourOff
  maximizerButton.textColourOn = buttonTextColourOn
  maximizerButton.size = {phasorMixKnob.width,phasorMixKnob.height-25}
  maximizerButton.x = phasorMixKnob.x
  maximizerButton.y = chorusKnob.y + 10
  maximizerButton.changed = function(self)
    local value = -1
    if self.value == true then
      value = 1
    end
    maximizer:setParameter("Value", value)
  end
  maximizerButton:changed()
  table.insert(tweakables, {widget=maximizerButton,func=getRandomBoolean,probability=10,excludeWithTwequencer=true,category="effects"})

  return effectsPanel
end

local effectsPanel = createEffectsPanel()

--------------------------------------------------------------------------------
-- Vibrato
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
  table.insert(tweakables, {widget=vibratoKnob,ceiling=0.5,probability=70,zero=40,default=20,useDuration=true,category="synthesis"})

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
  table.insert(tweakables, {widget=vibratoRateKnob,default=50,floor=0.5,ceiling=0.8,probability=50,useDuration=true,category="synthesis"})

  local vibratoRiseKnob = vibratoPanel:Knob("VibratoRiseTime", 0, 0, 10)
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
  table.insert(tweakables, {widget=wheelToVibratoKnob,default=50,floor=0.6,ceiling=0.85,probability=60,excludeWithTwequencer=true,category="synthesis"})

  local atToVibratoKnob = vibratoPanel:Knob("AftertouchToVibrato", 0, 0, 1)
  atToVibratoKnob.displayName="Aftertouch"
  atToVibratoKnob.fillColour = knobColour
  atToVibratoKnob.outlineColour = vibratoColour
  atToVibratoKnob.changed = function(self)
    atToVibrato:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  atToVibratoKnob:changed()
  table.insert(tweakables, {widget=atToVibratoKnob,default=50,floor=0.7,ceiling=0.9,probability=70,excludeWithTwequencer=true,category="synthesis"})

  return vibratoPanel
end

local vibratoPanel = createVibratoPanel()

--------------------------------------------------------------------------------
-- Tweak Panel
--------------------------------------------------------------------------------

local tweakButton
local tweakLevelKnob
local envStyleMenu

function storeNewSnapshot()
  print("Storing patch tweaks...")
  local patch = {}
  for i,v in ipairs(tweakables) do
    table.insert(patch, {index=i,widget=v.widget.name,value=v.widget.value})
  end
  table.insert(storedPatches, patch)
  print("Storing patch")
  patchesMenu:clear()
  populatePatchesMenu()
  print("Adding to patchesMenu", index)
  patchesMenu:setValue(#storedPatches)
end

function createPatchMakerPanel()
  local tweakPanel = Panel("Tweaks")
  tweakPanel.backgroundColour = bgColor
  tweakPanel.x = marginX
  tweakPanel.y = 10
  tweakPanel.width = width
  tweakPanel.height = 320

  tweakLevelKnob = tweakPanel:Knob("TweakLevel", 50, 0, 100, true)
  tweakLevelKnob.fillColour = knobColour
  tweakLevelKnob.outlineColour = outlineColour
  tweakLevelKnob.displayName = "Tweak Level"
  tweakLevelKnob.bounds = {70,10,300,150}

  tweakButton = tweakPanel:Button("Tweak")
  tweakButton.persistent = false
  tweakButton.alpha = buttonAlpha
  tweakButton.backgroundColourOff = buttonBackgroundColourOff
  tweakButton.backgroundColourOn = buttonBackgroundColourOn
  tweakButton.textColourOff = buttonTextColourOff
  tweakButton.textColourOn = buttonTextColourOn
  tweakButton.displayName = "Tweak Patch"
  tweakButton.bounds = {width/2,10,345,tweakLevelKnob.height}

  patchesMenu = tweakPanel:Menu("PatchesMenu")
  patchesMenu.persistent = false
  patchesMenu.backgroundColour = menuBackgroundColour
  patchesMenu.textColour = menuTextColour
  patchesMenu.arrowColour = menuArrowColour
  patchesMenu.outlineColour = menuOutlineColour
  patchesMenu.x = 10
  patchesMenu.y = 200
  patchesMenu.displayName = "Stored Snapshots"
  patchesMenu.changed = function(self)
    local index = self.value
    if #storedPatches == 0 then
      print("No patches")
      return
    end
    if index > #storedPatches then
      print("No patch at index")
      index = #storedPatches
    end
    tweaks = storedPatches[index]
    for _,v in ipairs(tweaks) do
      setWidgetValue(v.index, v.widget, v.value)
    end
    print("Tweaks set from patch at index:", index)
  end

  local prevPatchButton = tweakPanel:Button("PrevPatch")
  prevPatchButton.alpha = buttonAlpha
  prevPatchButton.persistent = false
  prevPatchButton.backgroundColourOff = buttonBackgroundColourOff
  prevPatchButton.backgroundColourOn = buttonBackgroundColourOn
  prevPatchButton.textColourOff = buttonTextColourOff
  prevPatchButton.textColourOn = buttonTextColourOn
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
  nextPatchButton.persistent = false
  nextPatchButton.alpha = buttonAlpha
  nextPatchButton.backgroundColourOff = buttonBackgroundColourOff
  nextPatchButton.backgroundColourOn = buttonBackgroundColourOn
  nextPatchButton.textColourOff = buttonTextColourOff
  nextPatchButton.textColourOn = buttonTextColourOn
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

  local actions = {"Choose...", "Add to snapshots", "Update selected snapshot", "Recall saved patch", "Initialize patch", "--- DANGERZONE ---", "Remove selected", "Remove all snapshots"}
  local managePatchesMenu = tweakPanel:Menu("ManagePatchesMenu", actions)
  managePatchesMenu.persistent = false
  managePatchesMenu.backgroundColour = menuBackgroundColour
  managePatchesMenu.textColour = menuTextColour
  managePatchesMenu.arrowColour = menuArrowColour
  managePatchesMenu.outlineColour = menuOutlineColour
  managePatchesMenu.x = nextPatchButton.x + nextPatchButton.width + marginX
  managePatchesMenu.y = patchesMenu.y
  managePatchesMenu.displayName = "Actions"
  managePatchesMenu.changed = function(self)
    if self.value == 1 then
      return
    end
    if self.value == 2 then
      storeNewSnapshot()
    elseif self.value == 3 then
      updateSelectedSnapshot()
    elseif self.value == 4 then
      recallStoredPatch()
    elseif self.value == 5 then
      initPatch()
    elseif self.value == 7 then
      removeSelectedSnapshot()
    elseif self.value == 8 then
      clearStoredPatches()
    end
    self:setValue(1)
  end

  local modStyleMenu = tweakPanel:Menu("ModulationStyle", {"Automatic", "Very fast", "Fast", "Medium fast", "Medium", "Medium slow", "Slow", "Very slow"})
  modStyleMenu.backgroundColour = menuBackgroundColour
  modStyleMenu.textColour = menuTextColour
  modStyleMenu.arrowColour = menuArrowColour
  modStyleMenu.outlineColour = menuOutlineColour
  modStyleMenu.displayName = "Modulation Style"
  modStyleMenu.x = width/2
  modStyleMenu.y = patchesMenu.y
  modStyleMenu.width = width/4-10

  envStyleMenu = tweakPanel:Menu("EnvStyle", {"Automatic", "Very short", "Short", "Medium short", "Medium", "Medium long", "Long", "Very long"})
  envStyleMenu.backgroundColour = menuBackgroundColour
  envStyleMenu.textColour = menuTextColour
  envStyleMenu.arrowColour = menuArrowColour
  envStyleMenu.outlineColour = menuOutlineColour
  envStyleMenu.displayName = "Envelope Style"
  envStyleMenu.width = modStyleMenu.width
  envStyleMenu.x = modStyleMenu.width + modStyleMenu.x + 10
  envStyleMenu.y = modStyleMenu.y

  local scopeLabel = tweakPanel:Label("Tweak Scope")
  scopeLabel.x = modStyleMenu.x
  scopeLabel.y = modStyleMenu.y + modStyleMenu.height + 10

  -- SCOPE BUTTONS - synthesis, modulation, filter, mixer, effects
  local synthesisButton = tweakPanel:OnOffButton("Synthesis", true)
  synthesisButton.alpha = buttonAlpha
  synthesisButton.backgroundColourOff = buttonBackgroundColourOff
  synthesisButton.backgroundColourOn = buttonBackgroundColourOn
  synthesisButton.textColourOff = buttonTextColourOff
  synthesisButton.textColourOn = buttonTextColourOn
  synthesisButton.size = {76,35}
  synthesisButton.x = width/2
  synthesisButton.y = scopeLabel.y + scopeLabel.height + 10

  local filterButton = tweakPanel:OnOffButton("Filter", true)
  filterButton.alpha = buttonAlpha
  filterButton.backgroundColourOff = buttonBackgroundColourOff
  filterButton.backgroundColourOn = buttonBackgroundColourOn
  filterButton.textColourOff = buttonTextColourOff
  filterButton.textColourOn = buttonTextColourOn
  filterButton.size = {60,35}
  filterButton.x = synthesisButton.x + synthesisButton.width + marginX
  filterButton.y = synthesisButton.y

  local modulationButton = tweakPanel:OnOffButton("Modulation", false)
  modulationButton.alpha = buttonAlpha
  modulationButton.backgroundColourOff = buttonBackgroundColourOff
  modulationButton.backgroundColourOn = buttonBackgroundColourOn
  modulationButton.textColourOff = buttonTextColourOff
  modulationButton.textColourOn = buttonTextColourOn
  modulationButton.size = {76,35}
  modulationButton.x = filterButton.x + filterButton.width + marginX
  modulationButton.y = synthesisButton.y

  local effectsButton = tweakPanel:OnOffButton("Effects", true)
  effectsButton.alpha = buttonAlpha
  effectsButton.backgroundColourOff = buttonBackgroundColourOff
  effectsButton.backgroundColourOn = buttonBackgroundColourOn
  effectsButton.textColourOff = buttonTextColourOff
  effectsButton.textColourOn = buttonTextColourOn
  effectsButton.size = {60,35}
  effectsButton.x = modulationButton.x + modulationButton.width + marginX
  effectsButton.y = synthesisButton.y

  local mixerButton = tweakPanel:OnOffButton("Mixer", true)
  mixerButton.alpha = buttonAlpha
  mixerButton.backgroundColourOff = buttonBackgroundColourOff
  mixerButton.backgroundColourOn = buttonBackgroundColourOn
  mixerButton.textColourOff = buttonTextColourOff
  mixerButton.textColourOn = buttonTextColourOn
  mixerButton.size = {60,35}
  mixerButton.x = effectsButton.x + effectsButton.width + marginX
  mixerButton.y = synthesisButton.y

  -- ARP TWEAK BUTTON
  tweakArpeggiatorButton = tweakPanel:Button("TweakArp")
  tweakArpeggiatorButton.persistent = false
  tweakArpeggiatorButton.alpha = buttonAlpha
  tweakArpeggiatorButton.backgroundColourOff = buttonBackgroundColourOff
  tweakArpeggiatorButton.backgroundColourOn = buttonBackgroundColourOn
  tweakArpeggiatorButton.textColourOff = buttonTextColourOff
  tweakArpeggiatorButton.textColourOn = buttonTextColourOn
  tweakArpeggiatorButton.displayName = "Tweak Arpeggiator"
  tweakArpeggiatorButton.bounds = {0,0,190,synthesisButton.height*1.3}
  tweakArpeggiatorButton.x = 10
  tweakArpeggiatorButton.y = synthesisButton.y - (synthesisButton.height*0.3)

  local tweakArpResMenu = tweakPanel:Menu("TweakArpResolution", {"Auto", "Even", "Dot", "Tri", "Lock"})
  tweakArpResMenu.backgroundColour = menuBackgroundColour
  tweakArpResMenu.textColour = menuTextColour
  tweakArpResMenu.arrowColour = menuArrowColour
  tweakArpResMenu.outlineColour = menuOutlineColour
  tweakArpResMenu.displayName = "Arp Resolution"
  tweakArpResMenu.height = tweakArpeggiatorButton.height
  tweakArpResMenu.x = tweakArpeggiatorButton.x + tweakArpeggiatorButton.width + 10
  tweakArpResMenu.y = tweakArpeggiatorButton.y
  tweakArpResMenu.width = 80

  tweakArpeggiatorButton.changed = function(self)
    doArpTweaks(tweakArpResMenu.value)
  end

  tweakButton.changed = function(self)
    print("Find widgets to tweak")
    local widgetsForTweaking = getTweakables(tweakLevelKnob.value, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton)
    -- Get the tweak suggestions
    for _,v in ipairs(widgetsForTweaking) do
      -- TODO Add waveform filter to tweak panel?
      --[[ if string.match(v.widget.name, 'Osc%dWave') or v.widget.name == "SubOscWaveform" then
        v.valueFilter = valueFilter
      end ]]
      v.targetValue = getTweakSuggestion(v, tweakLevelKnob.value, envStyleMenu.value, modStyleMenu.value)
    end
    verifySettings(tweakLevelKnob.value, widgetsForTweaking, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton)
    -- Perform the suggested tweaks
    print("Start tweaking!")
    for _,v in ipairs(widgetsForTweaking) do
      tweakWidget(v)
    end
    print("Tweaking complete!")
  end

  function clearStoredPatches()
    print("Clearing stored snapshots...")
    storedPatches = {}
    patchesMenu:clear()
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

  return tweakPanel
end

--------------------------------------------------------------------------------
-- Twequencer Panel
--------------------------------------------------------------------------------

local velocityRandomizationAmount = 0
local gateRandomizationAmount = 0
local tieRandomizationAmount = 0
local partRandomizationAmount = 0
local polyphonyWhenArp = 5

function createTwequencerPanel()
  local arpId = 0
  local heldNotes = {}
  local snapshots = {}
  local snapshotPosition = 1
  local maxSnapshots = 500 -- TODO Make it possible to set in UI?
  local automaticSequencerRunning = false
  local notenames = {"C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"}
  local noteNumberToNoteName = {} -- Used for mapping - does not include octave, only name of note (C, C#...)
  local notenamePos = 1
  for i=0,127 do
    local name = notenames[notenamePos] .. (math.floor(i/12)-2) .. " (" .. i .. ")"
    table.insert(noteNumberToNoteName, notenames[notenamePos])
    notenamePos = notenamePos + 1
    if notenamePos > #notenames then
      notenamePos = 1
    end
  end
  
  local tweqPanel = Panel("Sequencer")
  tweqPanel.backgroundColour = bgColor
  tweqPanel.x = marginX
  tweqPanel.y = 10
  tweqPanel.width = width
  tweqPanel.height = 320

  local tweakLevelKnob = tweqPanel:Knob("SeqTweakLevel", 50, 0, 100, true)
  tweakLevelKnob.fillColour = knobColour
  tweakLevelKnob.outlineColour = outlineColour
  tweakLevelKnob.displayName = "Tweak Level"
  tweakLevelKnob.width = 120
  tweakLevelKnob.y = 10

  local sequencerPlayMenu = tweqPanel:Menu("SequencerPlay", {"Off", "Mono", "As Played", "Random", "Chord", "Random Chord", "Alternate", "Generate"})
  sequencerPlayMenu.backgroundColour = menuBackgroundColour
  sequencerPlayMenu.textColour = menuTextColour
  sequencerPlayMenu.arrowColour = menuArrowColour
  sequencerPlayMenu.outlineColour = menuOutlineColour
  sequencerPlayMenu.displayName = "Sequencer Mode"
  sequencerPlayMenu.x = tweakLevelKnob.x
  sequencerPlayMenu.y = tweakLevelKnob.y + tweakLevelKnob.height + 6
  sequencerPlayMenu.width = tweakLevelKnob.width

  local tweakModeMenu = tweqPanel:Menu("TweakMode", {"Off", "Tweak over time", "Tweak", "Morph between stored snapshots"})
  tweakModeMenu.backgroundColour = menuBackgroundColour
  tweakModeMenu.textColour = menuTextColour
  tweakModeMenu.arrowColour = menuArrowColour
  tweakModeMenu.outlineColour = menuOutlineColour
  tweakModeMenu.displayName = "Tweak Mode"
  tweakModeMenu.x = sequencerPlayMenu.x
  tweakModeMenu.y = sequencerPlayMenu.y + sequencerPlayMenu.height + 6
  tweakModeMenu.width = sequencerPlayMenu.width
  --[[ tweakModeMenu.changed = function (self)
    tweakLevelKnob.enabled = self.value == 2 or self.value == 3
  end
  tweakModeMenu:changed() ]]

  local envStyleMenu = tweqPanel:Menu("SeqEnvStyle", {"Automatic", "Very short", "Short", "Medium short", "Medium", "Medium long", "Long", "Very long"})
  envStyleMenu.backgroundColour = menuBackgroundColour
  envStyleMenu.textColour = menuTextColour
  envStyleMenu.arrowColour = menuArrowColour
  envStyleMenu.outlineColour = menuOutlineColour
  envStyleMenu.displayName = "Envelope Style"
  envStyleMenu.x = tweakModeMenu.x
  envStyleMenu.y = tweakModeMenu.y + tweakModeMenu.height + 6
  envStyleMenu.width = tweakModeMenu.width

  local modStyleMenu = tweqPanel:Menu("ModStyle", {"Automatic", "Very fast", "Fast", "Medium fast", "Medium", "Medium slow", "Slow", "Very slow"})
  modStyleMenu.backgroundColour = menuBackgroundColour
  modStyleMenu.textColour = menuTextColour
  modStyleMenu.arrowColour = menuArrowColour
  modStyleMenu.outlineColour = menuOutlineColour
  modStyleMenu.displayName = "Modulation Style"
  modStyleMenu.x = tweakModeMenu.x
  modStyleMenu.y = envStyleMenu.y + envStyleMenu.height + 6
  modStyleMenu.width = envStyleMenu.width

  local waveformMenu
  if isAnalog or isAnalog3Osc or isAnalogStack then
    waveformMenu = tweqPanel:Menu("AllowedWaveforms", {"All", "Saw/Square", "Triangle/Sine", "Square/Triangle", "Saw/Sq/Tri/Sine"})
    waveformMenu.backgroundColour = menuBackgroundColour
    waveformMenu.textColour = menuTextColour
    waveformMenu.arrowColour = menuArrowColour
    waveformMenu.outlineColour = menuOutlineColour
    waveformMenu.displayName = "Allowed Waveforms"
    waveformMenu.x = modStyleMenu.x
    waveformMenu.y = modStyleMenu.y + modStyleMenu.height + 6
    waveformMenu.width = modStyleMenu.width
  end

  local partsTable = tweqPanel:Table("Parts", 1, 0, 0, 1, true)
  partsTable.enabled = false
  partsTable.persistent = false
  partsTable.fillStyle = "solid"
  partsTable.backgroundColour = menuArrowColour
  partsTable.sliderColour = outlineColour
  partsTable.width = 400
  partsTable.height = 10
  partsTable.x = sequencerPlayMenu.width * 1.2
  partsTable.y = 0

  local positionTable = tweqPanel:Table("Position", 4, 0, 0, 1, true)
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.fillStyle = "solid"
  positionTable.backgroundColour = menuTextColour
  positionTable.sliderColour = outlineColour
  positionTable.width = partsTable.width
  positionTable.height = partsTable.height
  positionTable.x = partsTable.x
  positionTable.y = partsTable.y + partsTable.height

  local rightMenuWidth = 140
  local rightMenuX = 565

  local snapshotsMenu = tweqPanel:Menu("SnapshotsMenu")
  snapshotsMenu.backgroundColour = menuBackgroundColour
  snapshotsMenu.textColour = menuTextColour
  snapshotsMenu.arrowColour = menuArrowColour
  snapshotsMenu.outlineColour = menuOutlineColour
  snapshotsMenu.x = rightMenuX
  snapshotsMenu.y = 0
  snapshotsMenu.width = 90
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
    for _,v in ipairs(tweaks) do
      v.widget.value = v.value
    end
    print("Tweaks set from snapshot at index:", index)
  end

  local prevSnapshotButton = tweqPanel:Button("PrevSnapshot")
  prevSnapshotButton.alpha = buttonAlpha
  prevSnapshotButton.backgroundColourOff = buttonBackgroundColourOff
  prevSnapshotButton.backgroundColourOn = buttonBackgroundColourOn
  prevSnapshotButton.textColourOff = buttonTextColourOff
  prevSnapshotButton.textColourOn = buttonTextColourOn
  prevSnapshotButton.displayName = "<"
  prevSnapshotButton.x = snapshotsMenu.x + snapshotsMenu.width + marginX
  prevSnapshotButton.y = snapshotsMenu.y + 25
  prevSnapshotButton.width = 20
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
  nextSnapshotButton.alpha = buttonAlpha
  nextSnapshotButton.backgroundColourOff = buttonBackgroundColourOff
  nextSnapshotButton.backgroundColourOn = buttonBackgroundColourOn
  nextSnapshotButton.textColourOff = buttonTextColourOff
  nextSnapshotButton.textColourOn = buttonTextColourOn
  nextSnapshotButton.displayName = ">"
  nextSnapshotButton.x = prevSnapshotButton.x + prevSnapshotButton.width + marginX
  nextSnapshotButton.y = prevSnapshotButton.y
  nextSnapshotButton.width = 20
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

  function storeSnapshot(index)
    if #snapshots == 0 then
      print("No snapshots")
      return
    end
    if index > #snapshots then
      print("No snapshot at index")
      return
    end
    --[[ if #storedPatches == 0 then
      table.insert(storedPatches, storedPatch)
    end ]]
    local patch = {}
    for i,v in ipairs(snapshots[index]) do
      table.insert(patch, {index=i,widget=v.widget.name,value=v.widget.value})
    end
    table.insert(storedPatches, patch)
    print("Storing snapshot")
    patchesMenu:clear()
    populatePatchesMenu()
    print("Tweaks stored from snapshot at index:", index)
  end

  function clearSnapshots()
    snapshots = {}
    snapshotsMenu:clear()
    snapshotPosition = 1
  end

  local actions = {"Choose...", "Store selected snapshot", "Recall saved patch", "Initialize patch", "Clear rounds"}
  local manageSnapshotsMenu = tweqPanel:Menu("ManageSnapshotsMenu", actions)
  manageSnapshotsMenu.persistent = false
  manageSnapshotsMenu.backgroundColour = menuBackgroundColour
  manageSnapshotsMenu.textColour = menuTextColour
  manageSnapshotsMenu.arrowColour = menuArrowColour
  manageSnapshotsMenu.outlineColour = menuOutlineColour
  manageSnapshotsMenu.x = rightMenuX
  manageSnapshotsMenu.y = snapshotsMenu.y + snapshotsMenu.height + 1
  manageSnapshotsMenu.displayName = "Actions"
  manageSnapshotsMenu.width = rightMenuWidth
  manageSnapshotsMenu.changed = function(self)
    if self.value == 1 then
      return
    end
    if self.value == 2 then
      storeSnapshot(snapshotsMenu.value)
    elseif self.value == 3 then
      recallStoredPatch()
    elseif self.value == 4 then
      initPatch()
    elseif self.value == 5 then
      clearSnapshots()
    end
    self:setValue(1)
  end

  local roundResolution = tweqPanel:Menu("RoundDuration", getResolutionNames({"Follow Step"}))
  local resolution = tweqPanel:Menu("Resolution", getResolutionNames({"Random"}))

  local numStepsBox = tweqPanel:NumBox("Steps", 4, 1, 256, true)
  numStepsBox.tooltip = "The Number of steps in each round"
  numStepsBox.backgroundColour = menuBackgroundColour
  numStepsBox.textColour = menuTextColour
  numStepsBox.arrowColour = menuArrowColour
  numStepsBox.outlineColour = menuOutlineColour
  numStepsBox.width = rightMenuWidth - 65

  local numPartsBox = tweqPanel:NumBox("Parts", 1, 1, 16, true)
  numPartsBox.tooltip = "The Number of parts in the sequence"
  numPartsBox.backgroundColour = menuBackgroundColour
  numPartsBox.textColour = menuTextColour
  numPartsBox.arrowColour = menuArrowColour
  numPartsBox.outlineColour = menuOutlineColour
  numPartsBox.width = rightMenuWidth - numStepsBox.width

  function clearPosition()
    for i = 1, numStepsBox.value * numPartsBox.value do
      positionTable:setValue(i, 0)
    end
    for i = 1, numPartsBox.value do
      partsTable:setValue(i, 0)
    end
  end

  function setNumSteps(stepDuration)
    -- If follow step is selected, we do not need to do anything - no num step change
    if roundResolution.value > #resolutions then
      return
    end

    if type(stepDuration) == "nil" then
      stepDuration = getResolution(resolution.value)
    end

    local roundDuration = getResolution(roundResolution.value)
    local numSteps = roundDuration / stepDuration
    print("stepDuration/roundDuration/numSteps", stepDuration,roundDuration,numSteps)
    if numSteps > numStepsBox.max then
      numStepsBox:setRange(1, numSteps)
    end
    numStepsBox:setValue(numSteps)
  end

  roundResolution.displayName = "Part Duration"
  roundResolution.tooltip = "Set the duration of a part."
  roundResolution.selected = #resolutions + 1
  roundResolution.x = rightMenuX
  roundResolution.y = manageSnapshotsMenu.y + manageSnapshotsMenu.height + 1
  roundResolution.width = rightMenuWidth
  roundResolution.backgroundColour = menuBackgroundColour
  roundResolution.textColour = menuTextColour
  roundResolution.arrowColour = menuArrowColour
  roundResolution.outlineColour = menuOutlineColour
  roundResolution.changed = function(self)
    if self.value > #resolutions then
      numStepsBox.enabled = true
    else
      numStepsBox.enabled = false
      setNumSteps()
    end
  end

  resolution.displayName = "Step Resolution"
  resolution.selected = 20
  resolution.x = roundResolution.x
  resolution.y = roundResolution.y + roundResolution.height + 5
  resolution.width = rightMenuWidth
  resolution.backgroundColour = menuBackgroundColour
  resolution.arrowColour = menuArrowColour
  resolution.outlineColour = menuOutlineColour
  resolution.changed = function(self)
    setNumSteps()
  end

  local arpOnOffButton = tweqPanel:OnOffButton("ArpOnOff", false)
  arpOnOffButton.alpha = buttonAlpha
  arpOnOffButton.backgroundColourOff = buttonBackgroundColourOff
  arpOnOffButton.backgroundColourOn = buttonBackgroundColourOn
  arpOnOffButton.textColourOff = buttonTextColourOff
  arpOnOffButton.textColourOn = buttonTextColourOn
  arpOnOffButton.displayName = "Arp on/off"
  arpOnOffButton.fillColour = knobColour
  arpOnOffButton.size = {rightMenuWidth,25}

  local tweakArpButton = tweqPanel:OnOffButton("TweakArpOnOff", false)
  tweakArpButton.alpha = buttonAlpha
  tweakArpButton.backgroundColourOff = buttonBackgroundColourOff
  tweakArpButton.backgroundColourOn = buttonBackgroundColourOn
  tweakArpButton.textColourOff = buttonTextColourOff
  tweakArpButton.textColourOn = buttonTextColourOn
  tweakArpButton.displayName = "Tweak Arp"
  tweakArpButton.fillColour = knobColour
  tweakArpButton.size = {rightMenuWidth/2,arpOnOffButton.height}

  local holdButton = tweqPanel:OnOffButton("HoldOnOff", false)
  holdButton.alpha = buttonAlpha
  holdButton.backgroundColourOff = buttonBackgroundColourOff
  holdButton.backgroundColourOn = buttonBackgroundColourOn
  holdButton.textColourOff = buttonTextColourOff
  holdButton.textColourOn = buttonTextColourOn
  holdButton.displayName = "Hold"
  holdButton.fillColour = knobColour
  holdButton.size = {rightMenuWidth,arpOnOffButton.height}
  holdButton.changed = function(self)
    if self.value == false then
      heldNotes = {}
      clearPosition()
      resetTweakLevel()
      arpId = arpId + 1
      if automaticSequencerRunning == true then
        arpeggiatorButton.value = false
        automaticSequencerRunning = false
      end
    end
  end

  --[[ local settingsButton = tweqPanel:Button("TweqSettings")
  settingsButton.displayName = "Settings"
  settingsButton.fillColour = knobColour
  settingsButton.size = {rightMenuWidth,arpOnOffButton.height}
  settingsButton.changed = function()
    setPage(7)
  end ]]

  local seqPitchTable = tweqPanel:Table("Pitch", numStepsBox.value, 0, -12, 12, true)
  seqPitchTable.showPopupDisplay = true
  seqPitchTable.showLabel = true
  seqPitchTable.fillStyle = "gloss"
  seqPitchTable.sliderColour = menuArrowColour
  seqPitchTable.width = positionTable.width
  seqPitchTable.height = 90
  seqPitchTable.x = positionTable.x
  seqPitchTable.y = positionTable.y + positionTable.height + 45

  local tieStepTable = tweqPanel:Table("TieStep", numStepsBox.value, 0, 0, 1, true)
  tieStepTable.tooltip = "Tie with next step"
  tieStepTable.fillStyle = "solid"
  tieStepTable.backgroundColour = "black"
  tieStepTable.showLabel = false
  tieStepTable.sliderColour = menuTextColour
  tieStepTable.width = positionTable.width
  tieStepTable.height = 8
  tieStepTable.x = seqPitchTable.x
  tieStepTable.y = seqPitchTable.y + seqPitchTable.height + 2

  local seqVelTable = tweqPanel:Table("Velocity", numStepsBox.value, 100, 1, 127, true)
  seqVelTable.tooltip = "Set step velocity. Randomization available in settings."
  seqVelTable.showPopupDisplay = true
  seqVelTable.showLabel = true
  seqVelTable.fillStyle = "gloss"
  seqVelTable.sliderColour = menuArrowColour
  seqVelTable.width = tieStepTable.width
  seqVelTable.height = 70
  seqVelTable.x = tieStepTable.x
  seqVelTable.y = tieStepTable.y + tieStepTable.height + 5

  local seqGateTable = tweqPanel:Table("Gate", numStepsBox.value, 100, 0, 100, true)
  seqGateTable.tooltip = "Set step gate length. Randomization available in settings."
  seqGateTable.showPopupDisplay = true
  seqGateTable.showLabel = true
  seqGateTable.fillStyle = "gloss"
  seqGateTable.sliderColour = menuArrowColour
  seqGateTable.width = seqPitchTable.width
  seqGateTable.height = 70
  seqGateTable.x = seqVelTable.x
  seqGateTable.y = seqVelTable.y + seqVelTable.height + 5

  local arpResMenu = tweqPanel:Menu("ArpResolution", {"Auto", "Even", "Dot", "Tri", "Lock"})
  arpResMenu.backgroundColour = menuBackgroundColour
  arpResMenu.textColour = menuTextColour
  arpResMenu.arrowColour = menuArrowColour
  arpResMenu.outlineColour = menuOutlineColour
  arpResMenu.showLabel = false
  arpResMenu.height = tweakArpButton.height
  arpResMenu.width = (rightMenuWidth/2) - 4

  -- Handle keys
  local generateKey = tweqPanel:Menu("GenerateKey", notenames)
  generateKey.displayName = "Key"
  generateKey.visible = false
  generateKey.width = 95
  generateKey.x = positionTable.x
  generateKey.y = positionTable.y + positionTable.height + 50
  generateKey.backgroundColour = menuBackgroundColour
  generateKey.textColour = menuTextColour
  generateKey.arrowColour = menuArrowColour
  generateKey.outlineColour = menuOutlineColour

  -- Handle scales
  local scale = {}
  local filteredScale = {}
  local scaleDefinitions = {{1},{2,2,1,2,2,2,1}, {2,1,2,2,1,2,2}, {2,1,2,2,2,1,2}, {2}, {2,2,3,2,3}, {3,2,2,3,2}}
  local generateScale = tweqPanel:Menu("GenerateScale", {"12 tone", "Major", "Minor", "Dorian", "Whole tone", "Major Pentatonic", "Minor Pentatonic"})
  generateScale.displayName = "Scale"
  generateScale.visible = false
  generateScale.width = 115
  generateScale.x = generateKey.x + generateKey.width + 5
  generateScale.y = generateKey.y
  generateScale.backgroundColour = menuBackgroundColour
  generateScale.textColour = menuTextColour
  generateScale.arrowColour = menuArrowColour
  generateScale.outlineColour = menuOutlineColour

  local droneMenu = tweqPanel:Menu("DroneMenu", {"No drone", "Lowest note", "Lowest root", "Lowest held", "Random held"})
  droneMenu.showLabel = false
  droneMenu.backgroundColour = menuBackgroundColour
  droneMenu.textColour = menuTextColour
  droneMenu.arrowColour = menuArrowColour
  droneMenu.outlineColour = menuOutlineColour
  droneMenu.tooltip = "Set a low drone"
  droneMenu.visible = false
  droneMenu.x = positionTable.x
  droneMenu.y = generateKey.y + generateKey.height + 3
  droneMenu.width = generateKey.width

  local generateMin = tweqPanel:NumBox("GenerateMin", 21, 0, 127, true)
  generateMin.unit = Unit.MidiKey
  generateMin.showPopupDisplay = true
  generateMin.showLabel = true
  generateMin.fillStyle = "gloss"
  generateMin.sliderColour = menuArrowColour
  generateMin.displayName = "Lowest note"
  generateMin.visible = false
  generateMin.x = droneMenu.x + droneMenu.width + 5
  generateMin.y = droneMenu.y
  generateMin.width = generateScale.width

  droneMenu.height = generateMin.height

  local droneHighMenu = tweqPanel:Menu("DroneHighMenu", {"No drone", "Highest note", "Highest root", "Highest held"})
  droneHighMenu.showLabel = false
  droneHighMenu.backgroundColour = menuBackgroundColour
  droneHighMenu.textColour = menuTextColour
  droneHighMenu.arrowColour = menuArrowColour
  droneHighMenu.outlineColour = menuOutlineColour
  droneHighMenu.tooltip = "Set a high drone"
  droneHighMenu.visible = false
  droneHighMenu.x = droneMenu.x
  droneHighMenu.y = droneMenu.y + droneMenu.height + 3
  droneHighMenu.width = droneMenu.width
  droneHighMenu.height = droneMenu.height

  local generateMax = tweqPanel:NumBox("GenerateMax", 108, 0, 127, true)
  generateMax.unit = Unit.MidiKey
  generateMax.showPopupDisplay = true
  generateMax.showLabel = true
  generateMax.fillStyle = "gloss"
  generateMax.sliderColour = menuArrowColour
  generateMax.displayName = "Highest note"
  generateMax.visible = false
  generateMax.x = droneHighMenu.x + droneHighMenu.width + 5
  generateMax.y = droneHighMenu.y
  generateMax.width = generateMin.width

  function createFilteredScale()
    local filtered = {}
    if #scale > 0 then
      -- TODO Check that low notes are root / five
      -- Filter out notes outside min/max
      local minNote = math.min(generateMin.value, generateMax.value)
      local maxNote = math.max(generateMin.value, generateMax.value)  
      for i=1,#scale do
        if scale[i] >= minNote and scale[i] <= maxNote then
          table.insert(filtered, scale[i])
          --print("Insert to filtered scale note", scale[i])
        end
      end
    end
    print("Filtered scale contains notes:", #filtered)
    return filtered
  end

  function createScale()
    local scaleTable = {}
    if generateScale.value == 1 then
      return scaleTable
    end
    -- Find scale definition
    local definition = scaleDefinitions[generateScale.value]
    -- Find root note
    local root = generateKey.value - 1
    -- Find notes for scale
    local pos = 0
    while root < 128 do
      table.insert(scaleTable, root)
      --print("Insert to scale:", root)
      pos = pos + 1
      root = root + definition[pos]
      if pos == #definition then
        pos = 0
      end
    end
    print("Generated scale contains notes:", #scaleTable)
    return scaleTable
  end

  function isRootNote(note)
    -- Find root note index
    local rootIndex = generateKey.value
    local noteIndex = note + 1 -- note index is 1 higher than note number
    print("Check isRootNote", rootIndex-1, note, noteNumberToNoteName[rootIndex], noteNumberToNoteName[noteIndex])
    return noteNumberToNoteName[rootIndex] == noteNumberToNoteName[noteIndex]
  end

  generateScale.changed = function(self)
    scale = createScale()
    filteredScale = createFilteredScale()
  end

  generateKey.changed = function(self)
    scale = createScale()
    filteredScale = createFilteredScale()
  end

  generateMin.changed = function(self)
    filteredScale = createFilteredScale()
    generateMax:setRange(self.value+1, 127)
  end
  generateMin:changed()

  generateMax.changed = function(self)
    filteredScale = createFilteredScale()
    generateMin:setRange(0, self.value-1)
  end
  generateMax:changed()

  local generatePolyphony = tweqPanel:NumBox("GeneratePolyphony", 1, 0, 16, true)
  generatePolyphony.displayName = "Polyphony"
  generatePolyphony.tooltip = "How many notes are played at once"
  generatePolyphony.backgroundColour = menuBackgroundColour
  generatePolyphony.textColour = menuTextColour
  generatePolyphony.arrowColour = menuArrowColour
  generatePolyphony.outlineColour = menuOutlineColour
  generatePolyphony.visible = false
  generatePolyphony.width = 160
  generatePolyphony.x = 386
  generatePolyphony.y = generateKey.y + 27

  local generateMinNoteSteps = tweqPanel:NumBox("GenerateMinNoteSteps", 1, 1, 1, true)
  generateMinNoteSteps.displayName = "Min Note Steps"
  generateMinNoteSteps.tooltip = "The minimum number of steps can a note last"
  generateMinNoteSteps.backgroundColour = menuBackgroundColour
  generateMinNoteSteps.textColour = menuTextColour
  generateMinNoteSteps.arrowColour = menuArrowColour
  generateMinNoteSteps.outlineColour = menuOutlineColour
  generateMinNoteSteps.visible = false
  generateMinNoteSteps.enabled = false
  generateMinNoteSteps.width = generatePolyphony.width
  generateMinNoteSteps.x = generatePolyphony.x
  generateMinNoteSteps.y = generatePolyphony.y + generatePolyphony.height + 3

  local generateMaxNoteSteps = tweqPanel:NumBox("GenerateMaxNoteSteps", 1, 1, 128, true)
  generateMaxNoteSteps.displayName = "Max Note Steps"
  generateMaxNoteSteps.tooltip = "The maximium number of steps can a note last"
  generateMaxNoteSteps.backgroundColour = menuBackgroundColour
  generateMaxNoteSteps.textColour = menuTextColour
  generateMaxNoteSteps.arrowColour = menuArrowColour
  generateMaxNoteSteps.outlineColour = menuOutlineColour
  generateMaxNoteSteps.visible = false
  generateMaxNoteSteps.width = generatePolyphony.width
  generateMaxNoteSteps.x = generateMinNoteSteps.x
  generateMaxNoteSteps.y = generateMinNoteSteps.y + generateMinNoteSteps.height + 3
  generateMaxNoteSteps.changed = function(self)
    generateMinNoteSteps:setRange(1, self.value)
    generateMinNoteSteps.enabled = self.value > 1
  end

  numStepsBox.x = resolution.x
  numStepsBox.y = resolution.y + resolution.height + 4
  numStepsBox.changed = function(self)
    seqPitchTable.length = self.value * numPartsBox.value
    tieStepTable.length = self.value * numPartsBox.value
    seqVelTable.length = self.value * numPartsBox.value
    seqGateTable.length = self.value * numPartsBox.value
    positionTable.length = self.value * numPartsBox.value
    clearPosition()
  end
  numStepsBox:changed()

  numPartsBox.x = numStepsBox.x + numStepsBox.width
  numPartsBox.y = numStepsBox.y
  numPartsBox.changed = function(self)
    seqPitchTable.length = self.value * numStepsBox.value
    tieStepTable.length = self.value * numStepsBox.value
    seqVelTable.length = self.value * numStepsBox.value
    seqGateTable.length = self.value * numStepsBox.value
    positionTable.length = self.value * numStepsBox.value
    partsTable.length = self.value
    clearPosition()
  end

  arpOnOffButton.x = resolution.x
  arpOnOffButton.y = numStepsBox.y + numStepsBox.height + 5

  tweakArpButton.x = arpOnOffButton.x
  tweakArpButton.y = arpOnOffButton.y + arpOnOffButton.height + 5

  arpResMenu.x = tweakArpButton.x + (rightMenuWidth/2) + 5
  arpResMenu.y = tweakArpButton.y

  holdButton.x = tweakArpButton.x
  holdButton.y = tweakArpButton.y + tweakArpButton.height + 5

  --settingsButton.x = holdButton.x
  --settingsButton.y = holdButton.y + holdButton.height + 4

  sequencerPlayMenu.changed = function(self)
    -- Stop sequencer if turned off
    if self.value == 1 then
      heldNotes = {}
      clearPosition()
      resetTweakLevel()
      arpId = arpId + 1
      if automaticSequencerRunning == true then
        arpeggiatorButton.value = false
        automaticSequencerRunning = false
      end
    end
    -- If generate is active, hide the pitch table
    local showGenerate = self.value == 8
    seqPitchTable.visible = showGenerate == false
    tieStepTable.visible = showGenerate == false
    --[[ snapshotsMenu.visible = showGenerate == false
    manageSnapshotsMenu.visible = showGenerate == false
    prevSnapshotButton.visible = showGenerate == false
    nextSnapshotButton.visible = showGenerate == false ]]
    generateMin.visible = showGenerate
    droneMenu.visible = showGenerate
    droneHighMenu.visible = showGenerate
    generateMax.visible = showGenerate
    generateKey.visible = showGenerate
    generateScale.visible = showGenerate
    generatePolyphony.visible = showGenerate
    generateMinNoteSteps.visible = showGenerate
    generateMaxNoteSteps.visible = showGenerate
  end

  --[[ local scopeLabel = tweqPanel:Label("Tweak Scope")
  scopeLabel.x = positionTable.x
  scopeLabel.y = positionTable.y + positionTable.height + 10 ]]

  -- synthesis, modulation, filter, mixer, effects
  local synthesisButton = tweqPanel:OnOffButton("SeqSynthesis", true)
  synthesisButton.alpha = buttonAlpha
  synthesisButton.backgroundColourOff = buttonBackgroundColourOff
  synthesisButton.backgroundColourOn = buttonBackgroundColourOn
  synthesisButton.textColourOff = buttonTextColourOff
  synthesisButton.textColourOn = buttonTextColourOn
  synthesisButton.displayName = "Synthesis"
  synthesisButton.fillColour = knobColour
  synthesisButton.size = {78,30}
  synthesisButton.x = positionTable.x
  synthesisButton.y = positionTable.y + positionTable.height + 10

  local filterButton = tweqPanel:OnOffButton("SeqFilter", true)
  filterButton.alpha = buttonAlpha
  filterButton.backgroundColourOff = buttonBackgroundColourOff
  filterButton.backgroundColourOn = buttonBackgroundColourOn
  filterButton.textColourOff = buttonTextColourOff
  filterButton.textColourOn = buttonTextColourOn
  filterButton.displayName = "Filter"
  filterButton.fillColour = knobColour
  filterButton.size = synthesisButton.size
  filterButton.x = synthesisButton.x + synthesisButton.width + marginX
  filterButton.y = synthesisButton.y

  local modulationButton = tweqPanel:OnOffButton("SeqModulation", false)
  modulationButton.alpha = buttonAlpha
  modulationButton.backgroundColourOff = buttonBackgroundColourOff
  modulationButton.backgroundColourOn = buttonBackgroundColourOn
  modulationButton.textColourOff = buttonTextColourOff
  modulationButton.textColourOn = buttonTextColourOn
  modulationButton.displayName = "Modulation"
  modulationButton.fillColour = knobColour
  modulationButton.size = synthesisButton.size
  modulationButton.x = filterButton.x + filterButton.width + marginX
  modulationButton.y = synthesisButton.y

  local effectsButton = tweqPanel:OnOffButton("SeqEffects", true)
  effectsButton.alpha = buttonAlpha
  effectsButton.backgroundColourOff = buttonBackgroundColourOff
  effectsButton.backgroundColourOn = buttonBackgroundColourOn
  effectsButton.textColourOff = buttonTextColourOff
  effectsButton.textColourOn = buttonTextColourOn
  effectsButton.displayName = "Effects"
  effectsButton.fillColour = knobColour
  effectsButton.size = synthesisButton.size
  effectsButton.x = modulationButton.x + modulationButton.width + marginX
  effectsButton.y = synthesisButton.y

  local mixerButton = tweqPanel:OnOffButton("SeqMixer", true)
  mixerButton.alpha = buttonAlpha
  mixerButton.backgroundColourOff = buttonBackgroundColourOff
  mixerButton.backgroundColourOn = buttonBackgroundColourOn
  mixerButton.textColourOff = buttonTextColourOff
  mixerButton.textColourOn = buttonTextColourOn
  mixerButton.displayName = "Mixer"
  mixerButton.fillColour = knobColour
  mixerButton.size = synthesisButton.size
  mixerButton.x = effectsButton.x + effectsButton.width + marginX
  mixerButton.y = synthesisButton.y

  function resetTweakLevel()
    --tweakLevelKnob.value = 0
  end

  function notesInclude(notesTable, note)
    for _,value in pairs(notesTable) do
      if value.note == note then
        return true
      end
    end
    return false
  end

  function generateNoteToPlay()
    if #filteredScale > 0 then
      local pos = getRandom(#filteredScale)
      return filteredScale[pos]
    end

    local minNote = math.min(generateMin.value, generateMax.value)
    local maxNote = math.max(generateMin.value, generateMax.value)
    return getRandom(minNote, maxNote)
  end

  function arpeg(arpId_)
    local index = 0
    local currentStep = 0 -- Holds the current step in the round that is being played
    local notes = {} -- Holds the playing notes - notes are removed when they are finished playing
    local heldNoteIndex = 0
    local tweakablesIndex = 0
    local stepDuration = getResolution(resolution.value)
    local roundDuration = stepDuration * numStepsBox.value * numPartsBox.value
    -- If a fixed round duration is selected, get the resolution
    if roundResolution.value <= #resolutions then
      roundDuration = getResolution(roundResolution.value) * numPartsBox.value
    end
    -- START ARP LOOP
    while arpId_ == arpId do
      -- SET VALUES
      local useDuration = tweakModeMenu.value == 2
      local arpOnOff = arpOnOffButton.value
      local tweakArp = tweakArpButton.value
      local envelopeStyle = envStyleMenu.value
      local modulationStyle = modStyleMenu.value
      local numParts = numPartsBox.value
      local numStepsPerPart = numStepsBox.value
      local numSteps = numStepsPerPart * numParts
      local currentPosition = (index % numSteps) + 1 -- 11 % 4 = 3
      local currentPartPosition = math.floor(index / numStepsPerPart) + 1 -- 5 / 4 = 1.25 = 1 + 1 = 2
      local tweakablesForTwequencer = {}
      local sequencerMode = sequencerPlayMenu.value

      -- Increment step counter
      currentStep = currentStep + 1
      if currentStep > numSteps then
        currentStep = 1
      end

      -- Check if we are at the start of a part
      if index % numStepsPerPart == 0 and partRandomizationAmount > 0 then
        print("Start of part!")
        -- Randomize parts within the set limit
        print("currentPartPosition before", currentPartPosition)
        print("currentPosition before", currentPosition)
        print("index before", index)
        currentPartPosition = getRandom(numParts)
        -- Find the current pos and index
        currentPosition = (numStepsPerPart * currentPartPosition) - (numStepsPerPart - 1)
        index = currentPosition - 1
        print("currentPartPosition after", currentPartPosition)
        print("currentPosition after", currentPosition)
        print("index after", index)
      end

      -- Randomize gate and velocity at pos 1
      if currentStep == 1 then
        -- Get step duration
        local i = getResolutionIndex(resolution.value)
        stepDuration = resolutions[i]
        
        -- Set numsteps for the current duration (if follow step is not selected - checked in the function)
        setNumSteps(stepDuration)
        numStepsPerPart = numStepsBox.value
        numSteps = numStepsPerPart * numParts
        
        -- Display the randomly selected resolution that is currently selected
        if resolution.value > #resolutions then
          resolution:setItem(#resolutions+1, "Random (".. getResolutionName(i) ..")")
        end

        -- Randomize gate within the set limit
        if gateRandomizationAmount > 0 then
          print("gateRandomizationAmount", gateRandomizationAmount)
          local changeMax = math.ceil(seqGateTable.max * gateRandomizationAmount)
          print("seqGateTable.min", seqGateTable.min)
          print("seqGateTable.max", seqGateTable.max)
          print("changeMax", changeMax)
          for i=1,numSteps do
            if getRandomBoolean() then
              local currentVal = seqGateTable:getValue(i)
              print("currentVal", currentVal)
              local min = currentVal - changeMax
              local max = currentVal + changeMax
              if min < seqGateTable.min then
                min = seqGateTable.min
              end
              if max > seqGateTable.max then
                max = seqGateTable.max
              end
              print("seqGateTable:setValue(i, getRandom(min, max))", i, min, max)
              seqGateTable:setValue(i, getRandom(min, max))
            end
          end
        end
        -- Randomize vel within the set limit
        if velocityRandomizationAmount > 0 then
          print("velocityRandomizationAmount", velocityRandomizationAmount)
          local changeMax = math.ceil(seqVelTable.max * velocityRandomizationAmount)
          print("seqVelTable.min", seqVelTable.min)
          print("seqVelTable.max", seqVelTable.max)
          print("changeMax", changeMax)
          for i=1,numSteps do
            if getRandomBoolean() then
              local currentVal = seqVelTable:getValue(i)
              print("currentVal", currentVal)
              local min = currentVal - changeMax
              local max = currentVal + changeMax
              if min < seqVelTable.min then
                min = seqVelTable.min
              end
              if max > seqVelTable.max then
                max = seqVelTable.max
              end
              print("seqVelTable:setValue(i, getRandom(min, max))", i, min, max)
              seqVelTable:setValue(i, getRandom(min, max))
            end
          end
        end
        -- Randomize ties within the set limit
        if tieRandomizationAmount > 0 then
          for i=1,numSteps do
            if getRandomBoolean(tieRandomizationAmount) then
              tieStepTable:setValue(i,1)
            else
              tieStepTable:setValue(i,0)
            end
          end
        end
      end

      -- Set values pt 2
      local vel = seqVelTable:getValue(currentPosition) -- get velocity
      local gate = seqGateTable:getValue(currentPosition) / 100 -- get gate
      local pitchAdjustment = seqPitchTable:getValue(currentPosition)
      local tieNext = tieStepTable:getValue(currentPosition)
      local tweakDuration = stepDuration * (numSteps - 1)

      print("Current index:", index)
      print("Steps:", numSteps)
      print("Steps per part:", numStepsPerPart)
      print("Current step pos:", currentPosition)
      print("Parts:", numParts)
      print("Current part pos:", currentPartPosition)
      print("Snapshot pos:", snapshotPosition)
      print("Step duration:", stepDuration)
      print("Round duration:", roundDuration)
      print("Tweak duration:", tweakDuration)

      -- Check prevoius step for tie - do not play note if tied from prev note!
      local shouldAddNote = tieStepTable:getValue(currentPosition - 1) ~= 1 or sequencerMode == 8 -- ALways true in generate mode

      -- If gate is zero no notes will play on this step
      if gate > 0 and shouldAddNote == true then

        -- note: the note to play
        -- gate: gate length
        -- vel: note velocity
        -- steps: the duration of the note in steps
        -- stepCounter: the counter for how many steps the note has lasted so far

        local noteSteps = 1
        -- Check tie to next step -- not used in generate
        if tieNext == 1 then
          local tmp = currentPosition
          while tieStepTable:getValue(tmp) == 1 and tmp < numSteps do
            noteSteps = noteSteps + 1
            tmp = tmp + 1
          end
        end
        -- ALTERNATE alternates between the other sequencer modes, except generate
        if sequencerMode == 7 then
          sequencerMode = getRandom(2,6)
        end
        if sequencerMode == 2 then -- MONO
          -- MONO plays the last note in held notes
          heldNoteIndex = #heldNotes
          table.insert(notes, {note=heldNotes[heldNoteIndex].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
        elseif sequencerMode == 3 then -- AS PLAYED
          -- AS PLAYED plays one note at a time in the order they where held down
          heldNoteIndex = heldNoteIndex + 1 -- Increment
          if heldNoteIndex > #heldNotes then
            heldNoteIndex = 1
          end
          table.insert(notes, {note=heldNotes[heldNoteIndex].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
        elseif sequencerMode == 4 then -- RANDOM
          -- RANDOM plays a random note from the held notes
          heldNoteIndex = getRandom(#heldNotes)
          table.insert(notes, {note=heldNotes[heldNoteIndex].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
        elseif sequencerMode == 5 then -- CHORD
          -- CHORD plays all the held notes at once
          for i=1,#heldNotes do
            table.insert(notes, {note=heldNotes[i].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
          end
        elseif sequencerMode == 6 then -- RANDOM CHORD
          -- RANDOM CHORD plays a random chord using notes from held noted
          local numberOfNotes = getRandom(math.min(6, #heldNotes))
          if numberOfNotes == #heldNotes then
            for i=1,#heldNotes do
              table.insert(notes, {note=heldNotes[i].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
            end
          else
            while #notes < numberOfNotes do
              local noteToPlay = getRandom(#heldNotes)
              if notesInclude(notes, noteToPlay) == false then
                table.insert(notes, {note=heldNotes[noteToPlay].note+pitchAdjustment,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
              end
            end
          end
        elseif sequencerMode == 8 then -- GENERATE
          -- GENERATE plays random notes from the selected scale
          -- Number of simultainious notes are set by generatePolyphony
          local numberOfNotes = generatePolyphony.value -- Default is "mono"
          if numberOfNotes > 1 and generateMaxNoteSteps.value > 1 then
            numberOfNotes = getRandom(generatePolyphony.value)
          end
          -- Use arp polyphony setting if arpeggiator is running
          if arpeggiatorButton.value == true then
            numberOfNotes = polyphonyWhenArp
          end
          -- On step one, always add the base note first (unless low drone is active) (setting for this?)
          local isLowDroneActive = droneMenu.visible and droneMenu.value > 1
          if currentStep == 1 and isLowDroneActive == false and notesInclude(notes, generateMin.value) == false then
            noteSteps = getRandom(generateMinNoteSteps.value,generateMaxNoteSteps.value)
            table.insert(notes, {note=generateMin.value,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
          end
          -- Check how many notes are already playing, and remove number from numberOfNotes if more than max polyphony
          if numberOfNotes + #notes > generatePolyphony.value then
            numberOfNotes = numberOfNotes - #notes
          end
          for i=1,numberOfNotes do
            local noteToPlay = generateNoteToPlay()
            if notesInclude(notes, noteToPlay) == false then
              noteSteps = getRandom(generateMinNoteSteps.value,generateMaxNoteSteps.value)
              table.insert(notes, {note=noteToPlay,gate=gate,vel=vel,steps=noteSteps,stepCounter=0})
              print("Insert to notes note/steps/gate", noteToPlay, noteSteps, gate)
            end
          end
        end
      end

      -- ACTIONS FOR POSITION 1
      if currentStep == 1 then

        -- STOP THE AUTOMATIC SEQUENCER IF RUNNING
        if automaticSequencerRunning == true then
          arpeggiatorButton.value = false
          automaticSequencerRunning = false
        end
        
        -- CHECK IF THE SEQUENCER SHOULD BE STARTED OR IS ALREADY RUNNING
        if (arpOnOff == true and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 50))) or (tweakArp == true and arpeggiatorButton.value == true) then
          envelopeStyle = getRandom(2,3)
          if tweakArp == true then
            doArpTweaks(arpResMenu.value)
          end
          if arpOnOff == true then
            arpeggiatorButton.value = true
            automaticSequencerRunning = true
          end
        end

        -- CHECK FOR TWEAKLEVEL
        if tweakLevelKnob.value > 0 and (tweakModeMenu.value == 2 or tweakModeMenu.value == 3) then
          tweakablesForTwequencer = getTweakables(tweakLevelKnob.value, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton, true)
          if #tweakablesForTwequencer > 0 then
            -- Update snapshots menu
            snapshotsMenu.enabled = true
            prevSnapshotButton.enabled = true
            nextSnapshotButton.enabled = true
            snapshotsMenu:setValue(snapshotPosition, false)
            
            -- Check for allowed waveforms
            -- {1:"All", 2:"Saw/Square", 3:"Triangle/Sine", 4:"Square/Triangle", 5:"Saw/Sq/Tri/Sine", 6:"Saw", 7:"Square", 8:"Triangle", 9:"Sine", 10:"Noise", 11:"Pulse"}
            -- local waveforms = {1:"Saw", 2:"Square", 3:"Triangle", 4:"Sine", 5:"Noise", 6:"Pulse"}
            local valueFilter = nil
            if waveformMenu then
              local allowedWaveforms = waveformMenu.value
              if allowedWaveforms == 2 then
                valueFilter = {1,2}
              elseif allowedWaveforms == 3 then
                valueFilter = {3,4}
              elseif allowedWaveforms == 4 then
                valueFilter = {2,3}
              elseif allowedWaveforms == 5 then
                valueFilter = {1,2,3,4}
              end
            end

            -- Tweak
            print("Tweaking at level", tweakLevelKnob.value)
            -- Get tweak suggestions
            for _,v in ipairs(tweakablesForTwequencer) do
              if string.match(v.widget.name, 'Osc%dWave') or v.widget.name == "SubOscWaveform" then
                v.valueFilter = valueFilter
              end
              -- Some special treatment for modulation parameters in twequencer
              if v.widget.name == "Lfo2Trigger" then
                -- Lfo2Trigger should always be on to avoid noise when LfoFreq changes
                v.targetValue = true
              elseif v.category == "modulation" and v.widget.name ~= "LfoFreq" and v.widget.name ~= "LfoToCutoff" and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 50)) then
                if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 50)) == getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 50)) then
                  -- Do not change the value of modulation parameters so often for twequencer
                  v.targetValue = v.widget.value
                else
                  -- Use default value more often for modulation parameters in twequencer
                  v.targetValue = v.widget.default
                end
              else
                --v.targetValue = getTweakSuggestionLegacy(v, tweakLevelKnob.value, envelopeStyle, modulationStyle, stepDuration)
                v.targetValue = getTweakSuggestion(v, tweakLevelKnob.value, envelopeStyle, modulationStyle, stepDuration)
              end
            end
            -- Verify tweak suggestions
            verifySettings(tweakLevelKnob.value, tweakablesForTwequencer, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton, automaticSequencerRunning)
            -- Store the tweaks
            storeRoundTweaks()
            -- Do the tweaking
            for _,v in ipairs(tweakablesForTwequencer) do
              run(tweakWidget, v, tweakDuration, (useDuration == true and type(v.useDuration) == "boolean" and v.useDuration == true))
              --[[ if useDuration == true and type(v.useDuration) == "boolean" and v.useDuration == true then
                spawn(tweakWidget, v, tweakDuration, useDuration)
              else
                tweakWidget(v)
              end ]]
            end
          end
        elseif tweakModeMenu.value == 4 and #storedPatches > 1 then
          -- Morph between snapshots
          local storedPatchIndex = getRandom(#storedPatches)
          print("Morphing to snapshot at index", storedPatchIndex)
          tweaks = storedPatches[storedPatchIndex]
          for _,v in ipairs(tweaks) do
            setWidgetTargetValue(v.index, v.widget, v.value)
          end
          for _,v in ipairs(tweakables) do
            run(tweakWidget, v, tweakDuration, (type(v.useDuration) == "boolean" and v.useDuration == true))
          end
        end
      end

      -- PLAY DRONE(S) ON POS 1 HOLDING ALL STEPS
      local isLowDroneActive = droneMenu.visible and droneMenu.value > 1
      local isHighDroneActive = droneHighMenu.visible and droneHighMenu.value > 1
      if currentStep == 1 and (isLowDroneActive or isHighDroneActive) then
        -- 2 = lowest, 3 = lowest in scale, 4 = lowest held
        local droneDuration = beat2ms(roundDuration)
        local minNote = generateMin.value
        local maxNote = generateMax.value
        
        -- PLAY LOW DRONE ---
        -- Options: {"Off", "Lowest note", "Lowest root", "Lowest held", "Random held"}
        local droneNoteLow = minNote -- default lowest
        if isLowDroneActive then
          if droneMenu.value == 3 then
            -- Get lowest root note in scale
            while(isRootNote(droneNoteLow) == false and droneNoteLow <= maxNote)
            do
              droneNoteLow = droneNoteLow + 1 -- increment note
            end
          elseif droneMenu.value == 4 then
            -- Get the lowest held note
            if #heldNotes > 0 then
              droneNoteLow = heldNotes[1].note
            end
          elseif droneMenu.value == 5 then
            -- Random - get a random note from held notes
            if #heldNotes > 0 then
              droneNoteLow = heldNotes[getRandom(#heldNotes)].note
            end
          end
          print("Playing low drone", droneNoteLow, droneDuration)
          playNote(droneNoteLow, vel, droneDuration)
        end

        -- PLAY HIGH DRONE ---
        local droneNoteHigh = maxNote -- default highest
        if isHighDroneActive then
          if droneHighMenu.value == 3 then
            -- Get highest root note in scale
            while(isRootNote(droneNoteHigh) == false and droneNoteHigh >= minNote)
            do
              droneNoteHigh = droneNoteHigh - 1 -- decrement note
            end
          elseif droneHighMenu.value == 4 then
            -- Get the highest held note
            droneNoteHigh = heldNotes[#heldNotes].note
          end
          if droneNoteHigh ~= droneNoteLow then
            print("Playing high drone", droneNoteHigh, droneDuration)
            playNote(droneNoteHigh, vel, droneDuration)
          end
        end
      end

      -- PLAY NOTE(S)
      print("Ready to play notes", #notes)
      for _,note in ipairs(notes) do
        print("Check note/stepCounter", note.note, note.stepCounter)
        -- Start playing when step counter is 0 (add an extra check for gate even though no notes should be added when gate is zero)
        if note.stepCounter == 0 and note.gate > 0 then
          -- Play the note for the number of steps that are set
          playNote(note.note, note.vel, beat2ms(stepDuration * note.gate * note.steps))
          print("Playing note/stepDuration/steps", note.note, stepDuration * note.gate, note.steps)
        end
        -- Increment step counter
        note.stepCounter = note.stepCounter + 1
        print("Increment note step counter", note.stepCounter)
      end

      -- REMOVE COMPLETED NOTES
      local keep = {}
      for _,note in ipairs(notes) do
        if note.steps > note.stepCounter then
          -- Keep note if more steps than counter is currently on
          table.insert(keep, note)
        end
      end
      notes = keep -- Refresh notes table

      clearPosition()
      -- UPDATE POSITION TABLE
      positionTable:setValue(currentPosition, 1)
      -- UPDATE PART TABLE
      partsTable:setValue(currentPartPosition, 1)
      -- INCREMENT POSITION
      index = (index + 1) % numSteps -- increment position

      -- WAIT FOR NEXT BEAT
      waitBeat(stepDuration)
    end
  end

  function getArpOctave()
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 40)) then
      return getRandom(-1,1)
    end
    return 0 -- default
  end

  function getArpNumStrike()
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 25)) then
      return getRandom(4)
    end
    return 1 -- default
  end

  function getArpMode()
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 20)) then
      return getRandom(0,26)
    end
    return 0 -- default
  end

  function getArpNumSteps()
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 10)) then
      return getRandom(128)
    end
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 20)) then
      return getRandom(32)
    end
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 50)) then
      return 16
    end
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 50)) then
      return 8
    end
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 50)) then
      return 4
    end
    return getRandom(16) -- default 16
  end

  -- TODO Resolution should depend on step length?
  -- 0 = 32x
  -- 1 = 16x
  -- 2 = 8x
  -- 3 = 7x
  -- 4 = 6x
  -- 5 = 5x
  -- 6 = 4x
  -- 7 = 3x
  -- 8 = 2x
  -- 9 = 1/1 dot
  ----------------
  -- 10 = 1/1
  -- 11 = 1/2 dot
  -- 12 = 1/1 tri
  -- 13 = 1/2
  -- 14 = 1/4 dot
  -- 15 = 1/2 tri
  -- 16 = 1/4
  -- 17 = 1/8 dot
  -- 18 = 1/4 tri
  -- 19 = 1/8
  -- 20 = 1/16 dot
  -- 21 = 1/8 tri
  -- 22 = 1/16 - default
  -- 23 = 1/32 dot
  -- 24 = 1/16 tri
  -- 25 = 1/32
  -- 26 = 1/64 dot
  -- 27 = 1/32 tri
  -- 28 = 1/64
  ----------------
  -- 29 = 1/64 tri
  ----------------
  -- default 22
  function getArpResolution(resolutionOption)
    if resolutionOption == 1 then
      local activeResolutions = {}
      for i,v in ipairs(selectedArpResolutions) do
        if v == true then
          table.insert(activeResolutions, i)
        end
      end
      if #activeResolutions > 0 then
        return activeResolutions[getRandom(#activeResolutions)] - 1
      else
        return getRandom(28)
      end
    end
    local position = resolutionOption + 14 -- resolutionOption will be 2 = even, 3 = dot, 4 = tri, so default starts at 16 (1/4)
    local resMax = 25 -- Max 1/32
    local resOptions = {}
    if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 25)) then
      position = position - 6
      resMax = 28
    end
    -- Create table of resolution options
    while position <= resMax do
      table.insert(resOptions, position) -- insert current position in resolution options table
      print("Insert arp resolution", position)
      position = position + 3 -- increment position
    end
    -- Pick a random index from resolution options table
    local index = getRandom(#resOptions)
    print("Selected arp res options index", index)
    return resOptions[index]
  end

  function doArpTweaks(resolutionOption)
    if type(resolutionOption) ~= "number" then
      resolutionOption = 1
    end
    local pos = 2 -- Start search for arpeggiator at this position (tweaksynth will be first)
    local arp = Program.eventProcessors[pos] -- get the event processor at the current position
    while arp.type ~= "Arpeggiator" do
      pos = pos + 1 -- increment pos
      arp = Program.eventProcessors[pos] -- get the event processor at the current position
    end
    local arpNumSteps = getArpNumSteps() -- get the number of steps to set for the arpeggiator
    arp:setParameter("NumSteps", arpNumSteps)
    if resolutionOption < 5 then -- 5 = lock - no change
      arp:setParameter("Resolution", getArpResolution(resolutionOption))
    end
    arp:setParameter("Mode", getArpMode())
    arp:setParameter("NumStrike", getArpNumStrike())
    arp:setParameter("Octave", getArpOctave())
    arp:setParameter("ArpVelocityBlend", getRandom())
    arp:setParameter("StepLength", 1)
    for i=0,arpNumSteps do
      if i > 0 and getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 30)) then
        arp:setParameter("Step"..i.."State", getRandom(0,3)) -- 0-3 def 0
      else
        arp:setParameter("Step"..i.."State", 1) -- 0-3 def 0
      end
      if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 50)) then
        arp:setParameter("Step"..i.."Size", getRandom()) -- 0-1 def 1
      else
        arp:setParameter("Step"..i.."Size", 1) -- 0-1 def 1
      end
      if getRandomBoolean(adjustProbabilityByTweakLevel(tweakLevelKnob.value, 30)) then
        arp:setParameter("Step"..i.."Level", getRandom()) -- 0-1 def 1
      else
        arp:setParameter("Step"..i.."Level", getRandom(60,100) / 100) -- 0-1 def 1
      end
    end
  end

  function storeRoundTweaks()
    if maxSnapshots > 0 then
      local snapshot = {}
      for _,v in ipairs(tweakables) do
        --table.insert(snapshot, {widget=v.widget,value=v.widget.value})
        table.insert(snapshot, {widget=v.widget,value=v.targetValue})
      end
      table.remove(snapshots, snapshotPosition)
      table.insert(snapshots, snapshotPosition, snapshot)
      print("Updated snapshot at index:", snapshotPosition)
      if #snapshotsMenu.items < snapshotPosition then
        snapshotsMenu:addItem("Round "..snapshotPosition)
      else
        snapshotsMenu:setItem(snapshotPosition, "Round "..snapshotPosition)
      end
      snapshotPosition = snapshotPosition + 1 -- increment snapshot position
      if snapshotPosition > maxSnapshots then
        snapshotPosition = 1
      end
    end
  end

  function onNote(e)
    if sequencerPlayMenu.value > 1 then
      if holdButton.value == true then
        for i,v in ipairs(heldNotes) do
          if v.note == e.note then
            if #heldNotes > 1 then
              table.remove(heldNotes, i)
            end
            return
          end
        end
      end
      table.insert(heldNotes, e)
      if #heldNotes == 1 then
          arpeg(arpId)
      end
    else
      postEvent(e)
    end
  end

  function onRelease(e)
    if holdButton.value == false then
      for i,v in ipairs(heldNotes) do
        if v.note == e.note then
          table.remove(heldNotes, i)
          if #heldNotes == 0 then
            clearPosition()
            resetTweakLevel()
            arpId = arpId + 1
          end
        end
      end
      if automaticSequencerRunning == true then
        arpeggiatorButton.value = false
        automaticSequencerRunning = false
      end
      postEvent(e)
    end
  end

  return tweqPanel
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local settingsPanel = Panel("Settings")
local seqResPanel = Panel("TwequencerResolutions")
local arpResPanel = Panel("ArpeggiatorResolutions")
local velGateRandPanel = Panel("VelGateRandomization")
local settingsPageMenu = settingsPanel:Menu("SettingsPageMenu", {"synthesis", "filter", "modulation", "effects+mixer", "arp+seq"})

function createSettingsPanel()
  settingsPanel.backgroundColour = bgColor
  settingsPanel.x = marginX
  settingsPanel.y = 10
  settingsPanel.width = width
  settingsPanel.height = 320

  local categories = settingsPageMenu.items
  local widgets = {}
  local selectedTweakable = nil
  local seqResolutionButtons = {}
  local arpResolutionButtons = {}

  -- Set all the given buttons to the provided value
  -- If value is omitted, the setting is randomized
  function setAll(buttons, value)
    local randomize = type(value) == "nil"
    for _,btn in ipairs(buttons) do
      if randomize then
        value = getRandomBoolean()
      end
      btn.value = value
    end
  end

  local label = settingsPanel:Label("TweakSynth Settings")
  label.displayName = label.name
  label.showLabel = true
  label.x = 0
  label.y = 0
  label.height = 25
  label.width = 200

  settingsPageMenu.width = 100
  settingsPageMenu.height = 25
  settingsPageMenu.x = 200
  settingsPageMenu.y = label.y
  settingsPageMenu.showLabel = false
  settingsPageMenu.persistent = false
  settingsPageMenu.changed = function(self)
    changeSettingsPage(self.value)
  end

  local allOffButton = settingsPanel:Button("AllOffButton")
  allOffButton.persistent = false
  allOffButton.displayName = "All off"
  allOffButton.width = 60
  allOffButton.height = 25
  allOffButton.x = settingsPageMenu.x + settingsPageMenu.width + 10
  allOffButton.y = label.y
  allOffButton.changed = function(self)
    -- page 5 = arp+seq page
    if settingsPageMenu.value == 5 then
      setAll(seqResolutionButtons, false)
      setAll(arpResolutionButtons, false)
      return
    end
    for _,v in ipairs(widgets) do
      local isPage = false
      if settingsPageMenu.value == 4 then
        isPage = v.category == "effects" or v.category == "mixer"
      else
        isPage = v.category == categories[settingsPageMenu.value]
      end
      if isPage then
        v.button:setValue(false)
      end
    end
  end

  local allOnButton = settingsPanel:Button("AllOnButton")
  allOnButton.persistent = false
  allOnButton.displayName = "All on"
  allOnButton.width = allOffButton.width
  allOnButton.height = 25
  allOnButton.x = allOffButton.x + allOffButton.width + 10
  allOnButton.y = label.y
  allOnButton.changed = function(self)
    -- page 5 = arp+seq page
    if settingsPageMenu.value == 5 then
      setAll(seqResolutionButtons, true)
      setAll(arpResolutionButtons, true)
      return
    end
    for _,v in ipairs(widgets) do
      local isPage = false
      if settingsPageMenu.value == 4 then
        isPage = v.category == "effects" or v.category == "mixer"
      else
        isPage = v.category == categories[settingsPageMenu.value]
      end
      if isPage then
        v.button:setValue(true)
      end
    end
  end

  local allRandButton = settingsPanel:Button("AllRandButton")
  allRandButton.persistent = false
  allRandButton.displayName = "Rnd all"
  allRandButton.width = allOffButton.width
  allRandButton.height = 25
  allRandButton.x = allOnButton.x + allOnButton.width + 10
  allRandButton.y = label.y
  allRandButton.changed = function(self)
    -- page 5 = arp+seq page
    if settingsPageMenu.value == 5 then
      setAll(seqResolutionButtons)
      setAll(arpResolutionButtons)
      return
    end
    for _,v in ipairs(widgets) do
      local isPage = false
      if settingsPageMenu.value == 4 then
        isPage = v.category == "effects" or v.category == "mixer"
      else
        isPage = v.category == categories[settingsPageMenu.value]
      end
      if isPage then
        v.button:setValue(getRandomBoolean())
      end
    end
  end

  local skipSetter = settingsPanel:NumBox("Skip", 0, 0, 100, true)
  skipSetter.displayName = "Skip probability"
  skipSetter.persistent = false
  skipSetter.backgroundColour = menuBackgroundColour
  skipSetter.textColour = menuTextColour
  skipSetter.arrowColour = menuArrowColour
  skipSetter.outlineColour = menuOutlineColour
  skipSetter.tooltip = "Set skip probability for all tweakables on this page"
  skipSetter.width = 120
  skipSetter.height = 25
  skipSetter.x = allRandButton.x + allRandButton.width + 10
  skipSetter.y = label.y
  skipSetter.changed = function(self)
    for _,v in ipairs(widgets) do
      local isPage = false
      if settingsPageMenu.value == 4 then
        isPage = v.category == "effects" or v.category == "mixer"
      else
        isPage = v.category == categories[settingsPageMenu.value]
      end
      if isPage then
        v.knob1:setValue(self.value)
      end
    end
  end

  local closeButton = settingsPanel:Button("CloseSettings")
  closeButton.persistent = false
  closeButton.displayName = "Back"
  closeButton.width = allOffButton.width
  closeButton.height = 25
  closeButton.y = label.y
  closeButton.x = skipSetter.x + skipSetter.width + 10
  closeButton.changed = function()
    if type(selectedTweakable) ~= "nil" then
      selectedTweakable = nil
      settingsPageMenu:changed()
    else
      setPage(4)
    end
  end

  -- Options:
    -- widget = the widget to tweak - the only non-optional parameter
    -- func = the function to execute for getting the value - default is getRandom
    -- factor = a factor to multiply the random value with
    -- floor = the lowest value
    -- ceiling = the highest value
    -- probability = the probability (affected by tweak level) that value is within limits (floor/ceiling) - probability is passed to any custom func
    -- zero = the probability that the value is set to 0
    -- excludeWithTwequencer = if ran with twequencer, this widget is excluded
    -- useDuration = if ran with a duration, this widget will tweak it's value over the length of the given duration
    -- defaultTweakRange = the range to use when tweaking default/stored value - if not provided, the full range is used
    -- default = the probability that the default/stored value is used (affected by tweak level)
    -- min = min value
    -- max = max value
    -- fmLevel = tweak as fm operator level if probability hits
    -- valueFilter = a table of allowed values. Incoming values are adjusted to the closest value of the valuefilter.
    -- absoluteLimit = the highest allowed limit - used mainly for safety resons to avoid extreme levels
    -- category = the category the widget belongs to (synthesis, modulation, filter, mixer, effects)
  function showSelectedTweakable(selectedWidget)
    print("showSelectedTweakable-selectedWidget", selectedWidget.name)
    print("showSelectedTweakable-selectedTweakable", selectedTweakable.widget.name)

    if type(selectedTweakable.widget.min) == "number" then
      print("widget.min", selectedTweakable.widget.min)
    end

    if type(selectedTweakable.widget.max) == "number" then
      print("widget.max", selectedTweakable.widget.max)
    end

    if type(selectedTweakable.widget.default) == "number" then
      print("widget.default", selectedTweakable.widget.default)
    end

    settingsPageMenu.visible = false
    allOffButton.visible = false
    allOnButton.visible = false
    allRandButton.visible = false
    skipSetter.visible = false
    
    -- Show edit widgets
    selectedWidget.probabilityKnob.visible = true
    selectedWidget.floorKnob.visible = true
    selectedWidget.ceilKnob.visible = true
    selectedWidget.defaultKnob.visible = true
    selectedWidget.zeroKnob.visible = true
    selectedWidget.bipolarKnob.visible = true
    
    -- Set page label
    label.displayName = "Edit " .. selectedTweakable.widget.displayName .. " (" .. selectedTweakable.widget.name .. ")"

    -- Toggle active button
    selectedWidget.button.visible = true
    selectedWidget.button.x = 50
    selectedWidget.button.y = 50
    selectedWidget.button.size = {120,60}

    -- Skip probability knob
    selectedWidget.knob1.visible = true
    selectedWidget.knob1.x = selectedWidget.button.x + selectedWidget.button.width + 90
    selectedWidget.knob1.y = selectedWidget.button.y
    selectedWidget.knob1.displayName = "Skip probability"
    selectedWidget.knob1.showLabel = true
    selectedWidget.knob1.showValue = true
    selectedWidget.knob1.size = selectedWidget.probabilityKnob.size

    -- POSITION THE WIDGETS

    -- Row 2 --
    selectedWidget.defaultKnob.x = 50
    selectedWidget.defaultKnob.y = selectedWidget.knob1.y + selectedWidget.knob1.height + 25

    selectedWidget.zeroKnob.x = selectedWidget.defaultKnob.x + selectedWidget.defaultKnob.width + 10
    selectedWidget.zeroKnob.y = selectedWidget.defaultKnob.y

    selectedWidget.bipolarKnob.x = selectedWidget.zeroKnob.x + selectedWidget.zeroKnob.width + 10
    selectedWidget.bipolarKnob.y = selectedWidget.zeroKnob.y

    -- Row 3 --
    selectedWidget.probabilityKnob.x = 50
    selectedWidget.probabilityKnob.y = selectedWidget.defaultKnob.y + selectedWidget.defaultKnob.height + 25

    selectedWidget.floorKnob.x = selectedWidget.probabilityKnob.x + selectedWidget.probabilityKnob.width + 10
    selectedWidget.floorKnob.y = selectedWidget.probabilityKnob.y

    selectedWidget.ceilKnob.x = selectedWidget.floorKnob.x + selectedWidget.floorKnob.width + 10
    selectedWidget.ceilKnob.y = selectedWidget.floorKnob.y
  end
  
  function hideSelectedTweakable()
    settingsPageMenu.visible = true
    allOffButton.visible = true
    allOnButton.visible = true
    allRandButton.visible = true
    skipSetter.visible = true
    label.displayName = label.name
  end

  for i,v in ipairs(tweakables) do
    if type(v.skipProbability) ~= "number" then
      v.skipProbability = defaultSkipProbability
    end
    local knob1 = settingsPanel:Knob(v.widget.name .. 'Knob1_' .. i, v.skipProbability, 0, 100, true)
    knob1.displayName = v.widget.name
    knob1.tooltip = "Skip probability"
    knob1.fillColour = knobColour
    knob1.visible = false
    knob1.changed = function(self)
      self.displayText = "Skip probability: " .. self.value .. "%"
      v.skipProbability = self.value
    end
    knob1:changed()

    local editBtn = settingsPanel:Button('EditBtn' .. i)
    editBtn.displayName = "Edit"
    editBtn.tooltip = "Edit details"
    editBtn.persistent = false
    editBtn.visible = false
    editBtn.size = {40,30}
    editBtn.changed = function(self)
      local isVisible = false
      local selectedWidget = nil
      for j,w in ipairs(widgets) do
        w.button.visible = isVisible
        w.knob1.visible = isVisible
        w.editBtn.visible = isVisible
        if j == i then
          selectedTweakable = v
          selectedWidget = w
          print("selectedTweakable", selectedTweakable.widget.name)
          print("selectedWidget", selectedWidget.name)
        end
      end
      showSelectedTweakable(selectedWidget)
    end

    local exclude = type(v.excludeWithTwequencer) == "boolean" and v.excludeWithTwequencer == true
    local btn = settingsPanel:OnOffButton(v.widget.name .. 'Btn' .. i, (exclude == false))
    btn.displayName = v.widget.name
    btn.tooltip = "Activate/deactivate tweakable in twequencer"
    btn.alpha = buttonAlpha
    btn.visible = false
    btn.backgroundColourOff = buttonBackgroundColourOff
    btn.backgroundColourOn = buttonBackgroundColourOn
    btn.textColourOff = buttonTextColourOff
    btn.textColourOn = buttonTextColourOn
    btn.changed = function(self)
      v.excludeWithTwequencer = self.value == false
    end
    btn:changed()

    -- Widgets for details view
    local probabilityKnob = settingsPanel:Knob('ProbabilityKnob' .. i, 0, 0, 100, true)
    probabilityKnob.visible = false
    probabilityKnob.displayName = "Probability"
    probabilityKnob.fillColour = knobColour
    probabilityKnob.size = {200,60}

    local defaultKnob = settingsPanel:Knob('DefaultKnob' .. i, 0, 0, 100, true)
    defaultKnob.visible = false
    defaultKnob.displayName = "Default value probability"
    defaultKnob.tooltip = "Probability of default value being set on the controller"
    defaultKnob.fillColour = knobColour
    defaultKnob.size = probabilityKnob.size
    --print("default", v.default)
    if type(v.default) == "number" then
      defaultKnob.value = v.default
    end
    defaultKnob.changed = function(self)
      self.displayText = self.value .. "%"
      v.default = self.value
    end
    defaultKnob:changed()

    local zeroKnob = settingsPanel:Knob('ZeroKnob' .. i, 0, 0, 100, true)
    zeroKnob.visible = false
    zeroKnob.displayName = "Probability of zero"
    zeroKnob.tooltip = "Probability of zero (0) being set"
    zeroKnob.fillColour = knobColour
    zeroKnob.size = probabilityKnob.size
    if type(v.zero) == "number" then
      --print("zero", v.zero)
      zeroKnob.value = v.zero
      zeroKnob.changed = function(self)
        self.displayText = self.value .. "%"
        v.zero = self.value
      end
      zeroKnob:changed()
    else
      zeroKnob.enabled = false
    end

    local bipolarKnob = settingsPanel:Knob('BipolarKnob' .. i, 0, 0, 100, true)
    bipolarKnob.visible = false
    bipolarKnob.displayName = "Bipolar probability"
    bipolarKnob.tooltip = "Probability of value being changed to negative for bipolar controllers"
    bipolarKnob.fillColour = knobColour
    bipolarKnob.size = probabilityKnob.size
    if type(v.bipolar) == "number" then
      --print("bipolar", v.bipolar)
      bipolarKnob.value = v.bipolar
      bipolarKnob.changed = function(self)
        self.displayText = self.value .. "%"
        v.bipolar = self.value
      end
      bipolarKnob:changed()
    else
      bipolarKnob.enabled = false
    end

    local min = 0
    local max = 1
    local default = 0
    local isEnabled = false
    if type(v.widget.default) == "number" and type(v.probability) == "number" and (type(v.floor) == "number" or type(v.ceiling) == "number") then
      default = v.widget.default
      min = v.widget.min
      max = v.widget.max
      isEnabled = true
    end

    probabilityKnob.enabled = isEnabled
    if isEnabled then
      probabilityKnob.value = v.probability
      probabilityKnob.changed = function(self)
        self.tooltip = "Probability that value is within limits (floor/ceiling)"
        self.displayText = self.value .. "%"
        v.probability = self.value
      end
      probabilityKnob:changed()
    end

    local floorKnob = settingsPanel:Knob('FloorKnob' .. i, default, min, max)
    floorKnob.visible = false
    floorKnob.enabled = isEnabled
    floorKnob.displayName = "Floor"
    floorKnob.fillColour = knobColour
    floorKnob.size = probabilityKnob.size
    if type(v.floor) == "number" then
      --print("floor", v.floor)
      floorKnob.value = v.floor
    else
      floorKnob.enabled = isEnabled
    end

    if isEnabled then
      floorKnob.mapper = v.widget.mapper
      floorKnob.changed = function(self)
        if v.widget.displayName == "Cutoff" then
          local value = filterMapValue(self.value)
          if value < 1000 then
              self.displayText = string.format("%0.1f Hz", value)
          else
              self.displayText = string.format("%0.1f kHz", value/1000.)
          end
        elseif v.widget.name:sub(-3) == "Mix" then
          self.displayText = formatGainInDb(self.value)
        elseif v.attack == true or v.release == true or v.decay == true then
          self.displayText = formatTimeInSeconds(self.value)
        elseif (self.min == 0 or self.min == -1) and self.max == 1 then
          self.displayText = percent(self.value)
        end
        v.floor = self.value
      end
      floorKnob:changed()
    end

    local ceilKnob = settingsPanel:Knob('CeilKnob' .. i, max, min, max)
    ceilKnob.visible = false
    ceilKnob.enabled = isEnabled
    ceilKnob.displayName = "Ceiling"
    ceilKnob.fillColour = knobColour
    ceilKnob.size = probabilityKnob.size
    if type(v.ceiling) == "number" then
      --print("ceiling", v.ceiling)
      ceilKnob.value = v.ceiling
    else
      ceilKnob.enabled = isEnabled
    end

    if isEnabled then
      ceilKnob.mapper = v.widget.mapper
      ceilKnob.changed = function(self)
        if v.widget.displayName == "Cutoff" then
          local value = filterMapValue(self.value)
          if value < 1000 then
              self.displayText = string.format("%0.1f Hz", value)
          else
              self.displayText = string.format("%0.1f kHz", value/1000.)
          end
        elseif v.widget.name:sub(-3) == "Mix" then
          self.displayText = formatGainInDb(self.value)
        elseif v.attack == true or v.release == true or v.decay == true then
          self.displayText = formatTimeInSeconds(self.value)
        elseif (self.min == 0 or self.min == -1) and self.max == 1 then
          self.displayText = percent(self.value)
        end
        v.ceiling = self.value
      end
      ceilKnob:changed()
    end

    table.insert(widgets, {
      button=btn,
      knob1=knob1,
      editBtn=editBtn,
      floorKnob=floorKnob,
      ceilKnob=ceilKnob,
      probabilityKnob=probabilityKnob,
      defaultKnob=defaultKnob,
      zeroKnob=zeroKnob,
      bipolarKnob=bipolarKnob,
      name=v.widget.name,
      category=v.category,
    })
  end

  -- Create twequencer resolution buttons
  seqResPanel.x = 0
  seqResPanel.y = 60
  seqResPanel.width = width
  seqResPanel.height = 95
  seqResPanel.visible = false

  local seqResLabel = seqResPanel:Label("Twequencer resolutions")
  seqResLabel.showLabel = true
  seqResLabel.width = 150

  local selectBtnSize = {80,20}

  local seqResBtnOn = seqResPanel:Button("SeqResBtnOn")
  seqResBtnOn.displayName = "Select all"
  seqResBtnOn.persistent = false
  seqResBtnOn.showLabel = false
  seqResBtnOn.size = selectBtnSize
  seqResBtnOn.x = seqResLabel.width
  seqResBtnOn.changed = function(self)
    setAll(seqResolutionButtons, true)
  end

  local seqResBtnOff = seqResPanel:Button("SeqResBtnOff")
  seqResBtnOff.displayName = "Select none"
  seqResBtnOff.persistent = false
  seqResBtnOff.showLabel = false
  seqResBtnOff.size = selectBtnSize
  seqResBtnOff.x = seqResBtnOn.x + seqResBtnOn.width + 3
  seqResBtnOff.changed = function(self)
    setAll(seqResolutionButtons, false)
  end

  local selectEvenResBtn = seqResPanel:Button("SelectEvenResBtn")
  selectEvenResBtn.persistent = false
  selectEvenResBtn.displayName = "Select even"
  selectEvenResBtn.size = selectBtnSize
  selectEvenResBtn.x = seqResBtnOff.x + seqResBtnOff.width + 3
  selectEvenResBtn.changed = function(self)
    --setAll(seqResolutionButtons, false)
    for _,e in ipairs(even) do
      seqResolutionButtons[e].value = true
    end
  end

  local selectDotResBtn = seqResPanel:Button("SelectDotResBtn")
  selectDotResBtn.persistent = false
  selectDotResBtn.displayName = "Select dotted"
  selectDotResBtn.size = selectBtnSize
  selectDotResBtn.x = selectEvenResBtn.x + selectEvenResBtn.width + 3
  selectDotResBtn.changed = function(self)
    --setAll(seqResolutionButtons, false)
    for _,e in ipairs(dot) do
      seqResolutionButtons[e].value = true
    end
  end

  local selectTriResBtn = seqResPanel:Button("SelectTriResBtn")
  selectTriResBtn.displayName = "Select tri"
  selectTriResBtn.persistent = false
  selectTriResBtn.size = selectBtnSize
  selectTriResBtn.x = selectDotResBtn.x + selectDotResBtn.width + 3
  selectTriResBtn.changed = function(self)
    --setAll(seqResolutionButtons, false)
    for _,e in ipairs(tri) do
      seqResolutionButtons[e].value = true
    end
  end

  local seqResBtnRandomize = seqResPanel:Button("SeqResBtnRandomize")
  seqResBtnRandomize.displayName = "Select random"
  seqResBtnRandomize.persistent = false
  seqResBtnRandomize.showLabel = false
  seqResBtnRandomize.size = selectBtnSize
  seqResBtnRandomize.x = selectTriResBtn.x + selectTriResBtn.width + 3
  seqResBtnRandomize.changed = function(self)
    setAll(seqResolutionButtons)
  end

  for i=1, #resolutions do
    local resBtnIsSelected = i > 6 and (i > #selectedSeqResolutions or selectedSeqResolutions[i])
    local btn = seqResPanel:OnOffButton("ResBtn" .. i, resBtnIsSelected)
    btn.displayName = resolutionNames[i]
    btn.tooltip = "Activate/deactivate resolution in twequencer"
    btn.alpha = buttonAlpha
    btn.backgroundColourOff = buttonBackgroundColourOff
    btn.backgroundColourOn = buttonBackgroundColourOn
    btn.textColourOff = buttonTextColourOff
    btn.textColourOn = buttonTextColourOn
    btn.size = {46,25}
    btn.changed = function(self)
      if i > #selectedSeqResolutions then
        table.insert(selectedSeqResolutions, self.value)
      else
        selectedSeqResolutions[i] = self.value
      end
    end
    btn:changed()
    table.insert(seqResolutionButtons, btn)
  end

  -- Create arpeggiator resolution buttons
  arpResPanel.x = 0
  arpResPanel.y = seqResPanel.y + seqResPanel.height
  arpResPanel.width = width
  arpResPanel.height = seqResPanel.height
  arpResPanel.visible = false

  local arpResLabel = arpResPanel:Label("Arpeggiator resolutions")
  arpResLabel.showLabel = true
  arpResLabel.width = seqResLabel.width

  local arpResBtnOn = arpResPanel:Button("ArpResBtnOn")
  arpResBtnOn.persistent = false
  arpResBtnOn.displayName = "Select all"
  arpResBtnOn.showLabel = false
  arpResBtnOn.size = selectBtnSize
  arpResBtnOn.x = arpResLabel.width
  arpResBtnOn.changed = function(self)
    setAll(arpResolutionButtons, true)
  end

  local arpResBtnOff = arpResPanel:Button("ArpResBtnOff")
  arpResBtnOff.persistent = false
  arpResBtnOff.displayName = "Select none"
  arpResBtnOff.showLabel = false
  arpResBtnOff.size = selectBtnSize
  arpResBtnOff.x = arpResBtnOn.x + arpResBtnOn.width + 3
  arpResBtnOff.changed = function(self)
    setAll(arpResolutionButtons, false)
  end

  local selectEvenArpResBtn = arpResPanel:Button("SelectEvenArpResBtn")
  selectEvenArpResBtn.persistent = false
  selectEvenArpResBtn.displayName = "Select even"
  selectEvenArpResBtn.size = selectBtnSize
  selectEvenArpResBtn.x = arpResBtnOff.x + arpResBtnOff.width + 3
  selectEvenArpResBtn.changed = function(self)
    --setAll(arpResolutionButtons, false)
    for _,e in ipairs(even) do
      arpResolutionButtons[e].value = true
    end
  end

  local selectDotArpResBtn = arpResPanel:Button("SelectDotArpResBtn")
  selectDotArpResBtn.persistent = false
  selectDotArpResBtn.displayName = "Select dotted"
  selectDotArpResBtn.size = selectBtnSize
  selectDotArpResBtn.x = selectEvenArpResBtn.x + selectEvenArpResBtn.width + 3
  selectDotArpResBtn.changed = function(self)
    --setAll(arpResolutionButtons, false)
    for _,e in ipairs(dot) do
      arpResolutionButtons[e].value = true
    end
  end

  local selectTriArpResBtn = arpResPanel:Button("SelectTriArpResBtn")
  selectTriArpResBtn.persistent = false
  selectTriArpResBtn.displayName = "Select tri"
  selectTriArpResBtn.size = selectBtnSize
  selectTriArpResBtn.x = selectDotArpResBtn.x + selectDotArpResBtn.width + 3
  selectTriArpResBtn.changed = function(self)
    --setAll(arpResolutionButtons, false)
    for _,e in ipairs(tri) do
      arpResolutionButtons[e].value = true
    end
  end

  local arpResBtnRandomize = arpResPanel:Button("ArpResBtnRandomize")
  arpResBtnRandomize.persistent = false
  arpResBtnRandomize.displayName = "Select random"
  arpResBtnRandomize.showLabel = false
  arpResBtnRandomize.size = selectBtnSize
  arpResBtnRandomize.x = selectTriArpResBtn.x + selectTriArpResBtn.width + 3
  arpResBtnRandomize.changed = function(self)
    setAll(arpResolutionButtons)
  end

  for i=1, #resolutions do
    local resBtnIsSelected = i > 6 and (i > #selectedArpResolutions or selectedArpResolutions[i])
    local btn = arpResPanel:OnOffButton("ArpResBtn" .. i, resBtnIsSelected)
    btn.displayName = resolutionNames[i]
    btn.tooltip = "Activate/deactivate resolution in arpeggiator"
    btn.alpha = buttonAlpha
    btn.backgroundColourOff = buttonBackgroundColourOff
    btn.backgroundColourOn = buttonBackgroundColourOn
    btn.textColourOff = buttonTextColourOff
    btn.textColourOn = buttonTextColourOn
    btn.size = {46,25}
    btn.changed = function(self)
      if i > #selectedArpResolutions then
        table.insert(selectedArpResolutions, self.value)
      else
        selectedArpResolutions[i] = self.value
      end
    end
    btn:changed()
    table.insert(arpResolutionButtons, btn)
  end

  -- Create knobs for velocity and gate randomization
  velGateRandPanel.x = 0
  velGateRandPanel.y = arpResPanel.y + arpResPanel.height
  velGateRandPanel.width = width
  velGateRandPanel.height = arpResPanel.height
  velGateRandPanel.visible = false

  local velGateRandLabel = velGateRandPanel:Label("Twequencer randomization")
  velGateRandLabel.showLabel = true
  velGateRandLabel.width = width

  local velRandKnob = velGateRandPanel:Knob("VelocityRandomization", 0, 0, 1)
  velRandKnob.displayName = "Velocity"
  velRandKnob.tooltip = "Amount of radomization applied to sequencer velocity"
  velRandKnob.unit = Unit.PercentNormalized
  velRandKnob.width = 100
  velRandKnob.changed = function(self)
    velocityRandomizationAmount = self.value
  end

  local gateRandKnob = velGateRandPanel:Knob("GateRandomization", 0, 0, 1)
  gateRandKnob.displayName = "Gate"
  gateRandKnob.tooltip = "Amount of radomization applied to sequencer gate"
  gateRandKnob.unit = Unit.PercentNormalized
  gateRandKnob.width = 100
  gateRandKnob.changed = function(self)
    gateRandomizationAmount = self.value
  end

  local tieRandKnob = velGateRandPanel:Knob("TieRandomization", 0, 0, 100, true)
  tieRandKnob.displayName = "Tie"
  tieRandKnob.tooltip = "Amount of radomization applied to ties"
  tieRandKnob.unit = Unit.Percent
  tieRandKnob.width = 100
  tieRandKnob.changed = function(self)
    tieRandomizationAmount = self.value
  end

  local partRandKnob = velGateRandPanel:Knob("PartRandomization", 0, 0, 100, true)
  partRandKnob.displayName = "Part"
  partRandKnob.tooltip = "Amount of radomization applied to parts"
  partRandKnob.unit = Unit.Percent
  partRandKnob.width = 100
  partRandKnob.changed = function(self)
    partRandomizationAmount = self.value
  end

  local polyphonyWhenArpKnob = velGateRandPanel:Knob("PolyphonyWhenArpKnob", polyphonyWhenArp, 1, 16, true)
  polyphonyWhenArpKnob.displayName = "Polyphony (arp on)"
  polyphonyWhenArpKnob.tooltip = "Adjust the number of generated notes when arp is active"
  polyphonyWhenArpKnob.width = 150
  polyphonyWhenArpKnob.changed = function(self)
    polyphonyWhenArp = self.value
  end

  function changeSettingsPage(page)
    local perColumn = 4
    local rowCounter = 0
    local columnCounter = 0
    hideSelectedTweakable()
    for _,v in ipairs(widgets) do
      local isVisible = false
      if page == 4 then
        isVisible = v.category == "effects" or v.category == "mixer"
      else
        isVisible = v.category == categories[page]
      end
      v.button.visible = isVisible
      v.knob1.visible = isVisible
      v.editBtn.visible = isVisible
      v.floorKnob.visible = false
      v.ceilKnob.visible = false
      v.defaultKnob.visible = false
      v.zeroKnob.visible = false
      v.probabilityKnob.visible = false
      v.bipolarKnob.visible = false
      if isVisible then
        v.editBtn.x = 180 * columnCounter + 10
        v.editBtn.y = (40 * rowCounter) + 50
        v.button.x = v.editBtn.x + 42
        v.button.y = v.editBtn.y
        v.button.size = {90,30}
        v.knob1.size = {30,30}
        v.knob1.x = v.button.x + 93
        v.knob1.y = v.button.y
        v.knob1.showLabel = false
        v.knob1.showValue = false
        v.knob1.showPopupDisplay = true
        columnCounter = columnCounter + 1
        if columnCounter >= perColumn then
          columnCounter = 0
          rowCounter = rowCounter + 1
        end
      end
    end
    -- Arp+seq
    if page == 5 then
      --toggleButton.enabled = false
      skipSetter.enabled = false
      seqResPanel.visible = true
      arpResPanel.visible = true
      velGateRandPanel.visible = true
      settingsPanel.height = seqResPanel.y
      perColumn = 15
      for _,btn in ipairs(seqResolutionButtons) do
        btn.x = btn.width * columnCounter + 10
        btn.y = (btn.height * rowCounter) + 30
        columnCounter = columnCounter + 1
        if columnCounter >= perColumn then
          columnCounter = 0
          rowCounter = rowCounter + 1
        end
      end
      rowCounter = 0
      columnCounter = 0
      for _,btn in ipairs(arpResolutionButtons) do
        btn.x = btn.width * columnCounter + 10
        btn.y = (btn.height * rowCounter) + 30
        columnCounter = columnCounter + 1
        if columnCounter >= perColumn then
          columnCounter = 0
          rowCounter = rowCounter + 1
        end
      end
    else
      --toggleButton.enabled = true
      skipSetter.enabled = true
      seqResPanel.visible = false
      arpResPanel.visible = false
      velGateRandPanel.visible = false
      settingsPanel.height = 320
    end
  end

  settingsPageMenu:changed()
end

createSettingsPanel()

--------------------------------------------------------------------------------
-- Set up pages
--------------------------------------------------------------------------------

function setupSynthesisPage()
  local synthesisHeight

  if osc3Panel then
    synthesisHeight = height
  else
    synthesisHeight = height * 1.25
  end

  osc1Panel.backgroundColour = bgColor
  osc1Panel.x = marginX
  osc1Panel.y = 10
  osc1Panel.width = width
  osc1Panel.height = synthesisHeight

  osc2Panel.backgroundColour = bgColor
  osc2Panel.x = marginX
  osc2Panel.y = osc1Panel.y + osc1Panel.height + marginY
  osc2Panel.width = width
  osc2Panel.height = synthesisHeight

  if osc3Panel then
    osc3Panel.backgroundColour = bgColor
    osc3Panel.x = marginX
    osc3Panel.y = osc2Panel.y + osc2Panel.height + marginY
    osc3Panel.width = width
    osc3Panel.height = synthesisHeight
  end

  vibratoPanel.backgroundColour = bgColor
  vibratoPanel.x = marginX
  if osc3Panel then
    vibratoPanel.y = osc3Panel.y + osc3Panel.height + marginY
  else
    vibratoPanel.y = osc2Panel.y + osc2Panel.height + marginY
  end
  vibratoPanel.width = width
  vibratoPanel.height = synthesisHeight

  ampEnvPanel.backgroundColour = bgColor
  ampEnvPanel.x = marginX
  ampEnvPanel.y = vibratoPanel.y + vibratoPanel.height + marginY
  ampEnvPanel.width = width
  ampEnvPanel.height = synthesisHeight
end

function setupFilterPage()
  filterPanel.backgroundColour = bgColor
  filterPanel.x = marginX
  filterPanel.y = 10
  filterPanel.width = width
  filterPanel.height = height

  hpFilterPanel.backgroundColour = bgColor
  hpFilterPanel.x = marginX
  hpFilterPanel.y = filterPanel.y + height + marginY
  hpFilterPanel.width = width
  hpFilterPanel.height = height

  filterEnvPanel.backgroundColour = bgColor
  filterEnvPanel.x = marginX
  filterEnvPanel.y = hpFilterPanel.y + height + marginY
  filterEnvPanel.width = width
  filterEnvPanel.height = height

  filterEnvTargetsPanel.backgroundColour = bgColor
  filterEnvTargetsPanel.x = marginX
  filterEnvTargetsPanel.y = filterEnvPanel.y + height + marginY
  filterEnvTargetsPanel.width = width
  filterEnvTargetsPanel.height = height

  filterEnvOscTargetsPanel.backgroundColour = bgColor
  filterEnvOscTargetsPanel.x = marginX
  filterEnvOscTargetsPanel.y = filterEnvTargetsPanel.y + height
  filterEnvOscTargetsPanel.width = width
  filterEnvOscTargetsPanel.height = height
end

function setupModulationPage()
  lfoPanel.backgroundColour = bgColor
  lfoPanel.x = marginX
  lfoPanel.y = 10
  lfoPanel.width = width
  lfoPanel.height = height * 2

  lfoTargetPanel.backgroundColour = bgColor
  lfoTargetPanel.x = marginX
  lfoTargetPanel.y = lfoPanel.y + lfoPanel.height + marginY
  lfoTargetPanel.width = width
  lfoTargetPanel.height = height

  lfoTargetPanel1.backgroundColour = bgColor
  lfoTargetPanel1.x = marginX
  lfoTargetPanel1.y = lfoTargetPanel.y + height
  lfoTargetPanel1.width = width
  lfoTargetPanel1.height = height

  lfoTargetPanel2.backgroundColour = bgColor
  lfoTargetPanel2.x = marginX
  lfoTargetPanel2.y = lfoTargetPanel1.y + height
  lfoTargetPanel2.width = width
  lfoTargetPanel2.height = height
end

function setupEffectsPage()
  effectsPanel.backgroundColour = bgColor
  effectsPanel.x = marginX
  effectsPanel.y = marginY
  effectsPanel.width = width
  effectsPanel.height = 310
end

setupSynthesisPage()
setupFilterPage()
setupModulationPage()
setupEffectsPage()

local tweqPanel = createTwequencerPanel()

local tweakPanel = createPatchMakerPanel()

--------------------------------------------------------------------------------
-- Map Midi CC for HW (Minilogue)
--------------------------------------------------------------------------------

function mapMinilogueCC()
  local activeLfoTarget = {cutoff = true, pwm = false, hardsync = false}
  local activeLfoTargetValue = 64

  function controllerValueToWidgetValue(controllerValue, bipolar, factor)
    local max = 127
    if bipolar == 1 then
      max = max / 2
    end
    local widgetValue = (controllerValue / max) - bipolar
    if controllerValue == 64 then
      if bipolar == 0 then
        widgetValue = 0.5
      else
        widgetValue = 0
      end
    end
    if type(factor) == "number" then
      widgetValue = widgetValue * factor
    end
    return widgetValue
  end
  
  function setLfoTargetValue()
    if activeLfoTarget.cutoff == true then
      getWidget("LfoToCutoff").value = controllerValueToWidgetValue(activeLfoTargetValue, 1)
    else
      getWidget("LfoToCutoff").value = 0
    end
    
    if activeLfoTarget.pwm == true then
      getWidget("LfoToOsc1PWM").value = controllerValueToWidgetValue(activeLfoTargetValue, 0, 0.5)
      getWidget("LfoToOsc2PWM").value = controllerValueToWidgetValue(activeLfoTargetValue, 0, 0.5)
    else
      getWidget("LfoToOsc1PWM").value = 0
      getWidget("LfoToOsc2PWM").value = 0
    end

    if activeLfoTarget.hardsync == true then
      getWidget("LfoToHardsync1").value = controllerValueToWidgetValue(activeLfoTargetValue, 0)
      getWidget("LfoToHardsync2").value = controllerValueToWidgetValue(activeLfoTargetValue, 0)
    else
      getWidget("LfoToHardsync1").value = 0
      getWidget("LfoToHardsync2").value = 0
    end
  end

  function onController(e)
    print(e)
    local controllerToWidgetMap = {
      CC16 = {name = "Attack", page = synthesisPageButton},
      CC17 = {name = "Decay", page = synthesisPageButton},
      CC18 = {name = "Sustain", bipolar = 0, page = synthesisPageButton},
      CC19 = {name = "Release", page = synthesisPageButton},
      CC20 = {name = "FAttack", page = filterPageButton},
      CC21 = {name = "FDecay", page = filterPageButton},
      CC22 = {name = "FSustain", bipolar = 0, page = filterPageButton},
      CC23 = {name = "FRelease", page = filterPageButton},
      CC24 = {name = "LfoFreq", bipolar = 0, page = modulationPageButton, factor = 20}, -- LFO RATE
      CC26 = {name = "LfoToTargetKnob", bipolar = 0, page = modulationPageButton}, -- LFO INT
      CC27 = {name = "Drive", bipolar = 0, page = effectsPageButton}, -- Voice Mode Depth > Drive
      CC29 = {name = "HpfCutoff", bipolar = 0, page = filterPageButton}, -- HI PASS CUTOFF
      CC30 = {name = "HpfEnvelopeAmt", bipolar = 1, page = filterPageButton}, -- TIME
      CC31 = {name = "TweakLevel", bipolar = 0, page = patchmakerPageButton, factor = 100}, -- FEEDBACK > Tweak level
      CC33 = {name = "NoiseMix", bipolar = 0}, -- NOISE
      CC34 = {name = "Osc1StartPhase", bipolar = 0, page = synthesisPageButton}, -- VCO 1 PITCH > Start Phase 1
      CC35 = {name = "Osc2FinePitch", bipolar = 0, page = synthesisPageButton}, -- VCO 2 PITCH > Fine pitch
      CC36 = {name = "HardsyncOsc1", bipolar = 0, page = synthesisPageButton, factor = 36}, -- VCO1 SHAPE > Hardsync 1
      CC37 = {name = "HardsyncOsc2", bipolar = 0, page = synthesisPageButton, factor = 36}, -- VCO2 SHAPE > Hardsync 2
      CC39 = {name = "Osc1Mix", bipolar = 0}, -- VCO1
      CC40 = {name = "Osc2Mix", bipolar = 0}, -- VCO2
      CC41 = {name = "FilterEnvToHardsync1", bipolar = 0, page = filterPageButton}, -- CROSS MOD DEPTH > Osc 1 Hardsync FEnv Amt
      CC42 = {name = "FilterEnvToHardsync2", bipolar = 0, page = filterPageButton}, -- PITCH EG INT > Osc 2 Hardsync FEnv Amt
      CC43 = {name = "Cutoff", bipolar = 0, page = filterPageButton}, -- CUTOFF > Cutoff
      CC44 = {name = "Resonance", bipolar = 0, page = filterPageButton}, -- RESONANCE > Resonance
      CC45 = {name = "EnvelopeAmt", bipolar = 1, page = filterPageButton}, -- EG INT > Cutoff filter env amount
      CC48 = {name = "Osc1Pitch", bipolar = 0, page = synthesisPageButton}, -- VCO 1 OCTAVE
      CC49 = {name = "Osc2Pitch", bipolar = 0, page = synthesisPageButton}, -- VCO 2 OCTAVE
      CC50 = {name = "Osc1Wave", bipolar = 0, page = synthesisPageButton}, -- VCO 1 WAVE
      CC51 = {name = "Osc2Wave", bipolar = 0, page = synthesisPageButton}, -- VCO 2 WAVE
      CC56 = {name = "ActiveLfoTargetSelector", bipolar = 0, page = modulationPageButton}, -- TARGET
      CC57 = {name = "LfoRetrigger", bipolar = 0, page = modulationPageButton}, -- EG MOD > LFO Retrigger/Sync
      CC58 = {name = "WaveFormTypeMenu", bipolar = 0, page = modulationPageButton}, -- LFO WAVE
      CC80 = {name = "VibratoDepth", bipolar = 0, page = synthesisPageButton}, -- RING
      CC81 = {name = "Arp", bipolar = 0}, -- SYNC > Arp on/off
      CC82 = {name = "VelocityToFilterEnv", bipolar = 0, page = filterPageButton, factor = 20}, -- VELOCITY
      CC83 = {name = "KeyTracking", bipolar = 0, page = filterPageButton}, -- KEY TRACK
      CC84 = {name = "FilterDb", bipolar = 0, page = filterPageButton}, -- 2/4-POLE
      CC88 = {name = "Tweak", bipolar = 0} -- OUTPUT ROUTING > Tweak button
    }

    local key = "CC" .. e.controller
    local cc = controllerToWidgetMap[key];
    
    if cc then
      if cc.page then
        cc.page:setValue(true)
      end
      if type(cc.bipolar) ~= "number" then
        postEvent(e)
        return
      end
      local value = controllerValueToWidgetValue(e.value, cc.bipolar, cc.factor)
      print("Value in/out:", e.value, value)

      if cc.name == "Arp" then
        arpeggiatorButton:setValue(value == 1)
        return
      end
      if cc.name == "ActiveLfoTargetSelector" then
        if value == 1 then
          -- HARDSYNC
          activeLfoTarget.cutoff = false
          activeLfoTarget.pwm = false
          activeLfoTarget.hardsync = true
        elseif value == 0.5 then
          -- PWM
          activeLfoTarget.cutoff = false
          activeLfoTarget.pwm = true
          activeLfoTarget.hardsync = false
        else
          -- CUTOFF
          activeLfoTarget.cutoff = true
          activeLfoTarget.pwm = false
          activeLfoTarget.hardsync = false
        end
        setLfoTargetValue()
        return
      end
      if cc.name == "LfoToTargetKnob" then
        activeLfoTargetValue = e.value
        setLfoTargetValue()
        return
      end
      if cc.name == "TweakLevel" then
        tweakLevelKnob.value = value
        return
      end
      if cc.name == "Tweak" then
        if value == 1 then
          initPatch()
        else
          storeNewSnapshot()
          tweakButton:push(true)
        end
        return
      end
      if cc.name == "LfoRetrigger" then
        local retrigger = getWidget("Lfo2Trigger")
        local sync = getWidget("Lfo2Sync")
        if value == 0 then
          retrigger:setValue(true)
          sync:setValue(false)
        elseif value == 1 then
          retrigger:setValue(false)
          sync:setValue(true)
        else
          retrigger:setValue(false)
          sync:setValue(false)
        end
        return
      end
      if cc.name == "FilterDb" then
        if value == 0 then
          value = 2
        end
      end
      if cc.name == "VibratoDepth" and value == 1 then
        value = 0.3
      end
      if cc.name == "Osc1Wave" or cc.name == "Osc2Wave" then
        if value == 0 then
          value = 2
        elseif value < 1 then
          value = 3
        end
      end
      if cc.name == "Osc1Pitch" then
        if value == 1 then
          value = 2
        elseif value > 0.6 then
          value = 1
        elseif value > 0.3 then
          value = 0
        else
          value = -1
        end
      end
      if cc.name == "Osc2Pitch" then
        if value == 1 then
          value = 24
        elseif value > 0.6 then
          value = 12
        elseif value > 0.3 then
          value = 0
        else
          value = -12
        end
      end
      if cc.name == "WaveFormTypeMenu" then
        if value == 0 then
          value = 6
        elseif value == 1 then
          value = 5
        else
          value = 3
        end
      end
      print("Setting value:", value)
      local widget = getWidget(cc.name)
      widget.value = value
      return
    end

    postEvent(e)
  end
end

if isMinilogue then
  mapMinilogueCC()
end

--------------------------------------------------------------------------------
-- Set pages
--------------------------------------------------------------------------------

function setPage(page)
  osc1Panel.visible = page == 1
  osc2Panel.visible = page == 1
  if osc3Panel then
    osc3Panel.visible = page == 1
  end
  vibratoPanel.visible = page == 1
  ampEnvPanel.visible = page == 1
  
  filterPanel.visible = page == 2
  hpFilterPanel.visible = page == 2
  filterEnvPanel.visible = page == 2
  filterEnvTargetsPanel.visible = page == 2
  filterEnvOscTargetsPanel.visible = page == 2
  
  lfoPanel.visible = page == 3
  lfoTargetPanel.visible = page == 3
  lfoTargetPanel1.visible = page == 3
  lfoTargetPanel2.visible = page == 3

  tweqPanel.visible = page == 4
  
  tweakPanel.visible = page == 5

  effectsPanel.visible = page == 6

  if page == 7 then
    settingsPanel.visible = true
    settingsPageMenu:changed()
  else
    settingsPanel.visible = false
    seqResPanel.visible = false
    arpResPanel.visible = false
    velGateRandPanel.visible = false
  end
end

synthesisPageButton.changed = function(self)
  filterPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(1)
end

filterPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(2)
end

modulationPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(3)
end

twequencerPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(4)
end

patchmakerPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(5)
end

effectsPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(6)
end

settingsPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  setPage(7)
end

-- Set start page
patchmakerPageButton:changed()
--twequencerPageButton:changed()
--setPage(7) -- Twequencer Settings Page

--[[ meter = AudioMeter("OutputLevel", Program, false, 0, true)
meter.bounds = {0, 320, 720, 20}
meter["0dBColour"] = "red"
meter["3dBColour"] = "orange"
meter["6dBColour"] = "blue"
meter["10dBColour"] = "green" ]]

setSize(720, 480)

setBackground("./resources/bluesquares.png")

makePerformanceView()
