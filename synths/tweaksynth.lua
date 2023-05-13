--------------------------------------------------------------------------------
-- TweakSynth
--------------------------------------------------------------------------------

local gem = require "includes.common"
local resolutions = require "includes.resolutions"

local tweakables = {}
local storedPatches = {}
local storedPatch = {}
local patchesMenu = nil
local snapshots = {} -- Snapshots stored for each round in twequencer
local snapshotPosition = 1
local snapshotsMenu = nil
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the twequencer

--------------------------------------------------------------------------------
-- Synth engine elements
--------------------------------------------------------------------------------

-- KEYGROUPS
local synthKeygroups = {
  Program.layers[1].keygroups[1],
  Program.layers[2].keygroups[1],
  Program.layers[3].keygroups[1],
}

-- OSCILLATORS
local synthOscillators = {
  synthKeygroups[1].oscillators[1],
  synthKeygroups[2].oscillators[1],
  synthKeygroups[3].oscillators[1],
}

-- MODULATORS
local synthModulators = {
  vibratoLfo = Program.modulations["LFO 1"],
  lfo1 = synthKeygroups[1].modulations["LFO 1"],
  lfo2 = synthKeygroups[2].modulations["LFO 1"],
  lfo3 = synthKeygroups[3].modulations["LFO 1"],
  ampEnv1 = synthKeygroups[1].modulations["Amp. Env"],
  ampEnv2 = synthKeygroups[2].modulations["Amp. Env"],
  ampEnvNoise = synthKeygroups[3].modulations["Amp. Env"],
  filterEnv1 = synthKeygroups[1].modulations["Analog ADSR 1"],
  filterEnv2 = synthKeygroups[2].modulations["Analog ADSR 1"],
  filterEnvNoise = synthKeygroups[3].modulations["Analog ADSR 1"],
}

-- Korg Minilogue has the Xpander Filter on insert 3
local filterInserts = {
  synthKeygroups[1].inserts[3],
  synthKeygroups[2].inserts[3],
  synthKeygroups[3].inserts[3],
}

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

local synthTypes = {
  isAnalog = synthOscillators[1].type == "MinBlepGenerator" and synthOscillators[2].type == "MinBlepGenerator",
  isAnalog3Osc = synthOscillators[1].type == "MinBlepGeneratorStack" and synthOscillators[2].type == "MinBlepGenerator",
  isAnalogStack = synthOscillators[1].type == "MinBlepGeneratorStack" and synthOscillators[2].type == "MinBlepGeneratorStack",
  isWavetable = synthOscillators[1].type == "WaveTableOscillator" and synthOscillators[2].type == "WaveTableOscillator",
  isAdditive = synthOscillators[1].type == "Additive" and synthOscillators[2].type == "Additive",
  isFM = synthOscillators[1].type == "FmOscillator" and synthOscillators[2].type == "FmOscillator",
  isDrum = synthOscillators[1].type == "DrumOscillator" and synthOscillators[2].type == "DrumOscillator",
  isMinilogue = filterInserts[1] and filterInserts[1].type == "XpanderFilter",
}

-- SET SOME PARAMETER VALUES (OVERRIDE FALCON DEFAULT VALUES)
Program:setParameter("Polyphony", 16)

if synthTypes.isAdditive then
  synthOscillators[1]:setParameter("CombFreq", 0.5)
  synthOscillators[2]:setParameter("CombFreq", 0.5)
  synthOscillators[1]:setParameter("FilterType", 3)
  synthOscillators[2]:setParameter("FilterType", 3)
  synthOscillators[1]:setParameter("SafeBass", true)
  synthOscillators[2]:setParameter("SafeBass", true)
end

print("Starting TweakSynth!")
print("Oscillator 1:", synthOscillators[1].type)
print("Oscillator 2:", synthOscillators[2].type)

--------------------------------------------------------------------------------
-- Name common macros
--------------------------------------------------------------------------------

local commonMacros = {
  osc1Shape = macros[1],
  filterCutoff = macros[2],
  filterEnvAmount = macros[3],
  lfoFreqKeyFollow2 = macros[4],
  lfoFreqKeyFollow3 = macros[5],
  lfoToDetune = macros[6],
  osc1Mix = macros[8],
  osc2Shape = macros[9],
  osc2Mix = macros[10],
  osc2Detune = macros[11],
  osc2Pitch = macros[12],
  filterResonance = macros[13],
  delayMix = macros[14],
  reverbMix = macros[15],
  arpeggiator = macros[16],
  lfoToNoiseLpf = macros[18],
  lfoToNoiseHpf = macros[19],
  lfoToNoiseAmp = macros[20],
  chorusMix = macros[21],
  wheelToCutoff = macros[22],
  driveAmount = macros[23],
  atToCutoff = macros[24],
  vibratoAmount = macros[25],
  atToVibrato = macros[26],
  osc1LfoToPWM = macros[27],
  osc2LfoToPWM = macros[28],
  wheelToVibrato = macros[29],
  filterKeyTracking = macros[30],
  lfoToCutoff = macros[31],
  unisonDetune = macros[32],
  vibratoRate = macros[33],
  maximizer = macros[35],
  noiseMix = macros[36],
  lfoToAmp = macros[37],
  lfoFreqKeyFollow1 = macros[42],
  panSpread = macros[43],
  stereoSpread = macros[44],
  osc1Pitch = macros[45],
  lfoToPitchOsc1 = macros[46],
  lfoToPitchOsc2 = macros[47],
  filterEnvToPitchOsc1 = macros[48],
  filterEnvToPitchOsc2 = macros[49],
  hpfCutoff = macros[50],
  hpfResonance = macros[51],
  hpfKeyTracking = macros[52],
  hpfEnvAmount = macros[53],
  wheelToHpf = macros[54],
  atToHpf = macros[55],
  lfoToHpf = macros[56],
  phasorMix = macros[61],
  wheelToLfo = macros[62],
}

-- Additive macros
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

-- Analog macros
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

-- Drum macros
local drumMacros = {
  lfoToOsc1Freq = macros[1],
  lfoToNoise1Mix = macros[7],
  lfoToOsc2Freq = macros[9],
  lfoToNoise2Mix = macros[17],
  lfoToNoise1Cutoff = macros[27],
  lfoToNoise2Cutoff = macros[28],
  lfoToDistortion1 = macros[34],
  lfoToOsc1ModDepth = macros[38],
  lfoToOsc2ModDepth = macros[39],
  osc1PitchModRate = macros[40],
  osc2PitchModRate = macros[41],
  filterEnvToNoise1Cutoff = macros[57],
  filterEnvToNoise2Cutoff = macros[58],
  lfoToDistortion2 = macros[59],
  filterDb = macros[60]
}

-- Wavetable macros
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

-- FM macros
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
local bgColor = "#00000000"
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
-- Helper functions
--------------------------------------------------------------------------------

-- Topologies for FM synth
local topologies = {"D->C->B->A", "D+C->B->A", "C->B,B+D->A", "D->B+C->A", "D->C->A+B", "D->C->B,A", "B+C+D->A", "B->A,D->C", "D->A+B+C", "A,B,D->C", "A,B,C,D"}

local helpers = {}

helpers.getDrumOscFrequencyFilterValues = function()
  -- Get multiples of the base value (32.6875 = C0)
  local baseVal = 32.6875
  local maxVal = baseVal * 500
  local values = {}
  while baseVal < maxVal do
    table.insert(values, baseVal)
    baseVal = baseVal * 2
  end
  return values
end

-- Set maxLevel based on topology:
-- topology 0-3 > A
-- topology 4-5 > A+B
-- topology 6 > A
-- topology 7 > A+C
-- topology 8-9 > A+B+C
-- topology 10 > A+B+C+D
helpers.getMaxFromTopology = function(op, topology)
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

helpers.initPatch = function()
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

helpers.setWidgetValue = function(index, widgetName, value)
  if tweakables[index] and widgetName == tweakables[index].widget.name then
    tweakables[index].widget.value = value
    print("Set widget value: ", widgetName, tweakables[index].widget.value, value)
  end
end

--[[ helpers.setWidgetTargetValue = function(index, widgetName, value)
  if tweakables[index] and widgetName == tweakables[index].widget.name then
    tweakables[index].targetValue = value
    print("Set target value: ", widgetName, value)
  end
end ]]

helpers.recallStoredPatch = function()
  print("Recalling stored patch...")
  for _,v in ipairs(storedPatch) do
    helpers.setWidgetValue(v.index, v.widget, v.value)
  end
end

helpers.populatePatchesMenu = function()
  for i=1,#storedPatches do
    local itemName = "Patch "..i
    patchesMenu:addItem(itemName)
  end
end

-- Returns a probability that is derived from the given tweaklevel. The probability returned is reduced less the higher the tweak level is.
-- *NOTE* Use this when you want something to be more likely to occur on high tweak levels.
-- Tweaklevel 90 gives a probability of 81: 90 * 0.9 = 81 (reduced by 9)
-- Tweaklevel 30 gives a probability of 9: 30 * 0.3 = 9 (reduced by 21)
--[[ local function getProbabilityFromTweakLevel(tweakLevel)
  return tweakLevel * (tweakLevel / 100)
end ]]

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
helpers.adjustProbabilityByTweakLevel = function(tweakLevel, probability, weight)
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

helpers.tweakValue = function(options, value, tweakLevel)
  if type(options.widget.default) ~= "number" or (type(options.default) == "number" and gem.getRandomBoolean(helpers.adjustProbabilityByTweakLevel(tweakLevel, options.default))) then
    if options.widget.name == "NoiseType" then
      value = 7
    end
    return value
  end
  if type(options.factor) == "nil" then
    options.factor = 1
  end
  print("Tweaking value:", value)
  -- If probability is set to 100, we are forced to stay within the given range
  local forceRange = type(options.probability) == "number" and options.probability == 100
  -- Get range limits
  local floor = options.widget.min -- Default floor is widget min
  local ceiling = options.widget.max -- Default ceiling is widget max
  -- Get value within set range if probability hits
  if forceRange or type(options.probability) == "number" and gem.getRandomBoolean(helpers.adjustProbabilityByTweakLevel(tweakLevel, options.probability)) then
    if type(options.floor) == "number" then
      floor = options.floor * options.factor
    end
    if type(options.ceiling) == "number" then
      ceiling = options.ceiling * options.factor
    end
    print("Probability/floor/ceiling:", options.probability, floor, ceiling)
    -- Get widget range
    local range = ceiling - floor
    if type(options.defaultTweakRange) == "number" and forceRange == false then
      range = options.defaultTweakRange
    end
    print("Value range:", range)
    -- Determine change factor - a low tweaklevel gives a small change - high tweaklevel gives bigger change
    local factor = (0.5 * gem.getRandom()) * ((tweakLevel * 1.5) / 100)
    print("Tweak factor:", factor)
    -- Set the range allowed for value adjustment
    local tweakRange = range * factor
    print("Tweakrange:", tweakRange)
    local minVal = options.widget.min
    local maxVal = options.widget.max
    if forceRange or (type(options.probability) == "number" and gem.getRandomBoolean(helpers.adjustProbabilityByTweakLevel(tweakLevel, options.probability))) then
      minVal = floor
      maxVal = ceiling
    end
    if (value - tweakRange) < minVal then
      while (value - tweakRange) < minVal do
        print("Incrementing to avoid out of range")
        value = value + tweakRange
      end
    elseif (value + tweakRange) > maxVal then
      while (value + tweakRange) > maxVal do
        print("Decrementing to avoid out of range")
        value = value - tweakRange
      end
    elseif gem.getRandomBoolean() == true then
      print("Incrementing value")
      value = value + tweakRange
    else
      print("Decrementing value")
      value = value - tweakRange
    end
    if forceRange then
      if value > maxVal then
        print("Set max")
        value = maxVal
      elseif value < minVal then
        print("Set min")
        value = minVal
      end
    end
    if options.integer == true then
      value = gem.round(value)
    end
    return value
  end

  -- Get a random value within the full range
  print("Random full range")
  return gem.getRandom(options.min, options.max, options.factor)
end

helpers.getEnvelopeTimeForDuration = function(options, duration)
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

  return gem.getRandom(min, max) / 10000
end

helpers.getEnvelopeTimeByStyle = function(options, style)
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
  
  return gem.getRandom(min*100000, max*100000)/100000
end

helpers.getModulationFreqByStyle = function(options, style)
  local index = style - 1
  local freq = {{15.5,20.},{12.5,16.5},{8.5,13.5},{5.,9.5},{3.1,7.1},{1.5,3.5},{0.1,2.5}}
  local min = freq[index][1]
  local max = freq[index][2]
  
  print("getModulationFreqByStyle min/max:", min, max)
  
  return gem.getRandom(min, max)
end

helpers.getValueBetween = function(floor, ceiling, originalValue, options, maxRounds)
  -- Set startvalue
  local value = originalValue
  
  -- Generate values until we hit the window
  local rounds = 0 -- Counter for rounds
  
  -- Set options if not provided
  if type(options) == "nil" then
    options = {}
  end

  -- Set default factor
  if type(options.factor) == "nil" then
    options.factor = 1
  end

  -- Set max rounds if not provided
  if type(maxRounds) ~= "number" then
    maxRounds = 25
  end

  print("getValueBetween floor, ceiling, startvalue, maxrounds:", floor, ceiling, value, maxRounds)
  while rounds < maxRounds and (value < floor or value > ceiling) do
    value = gem.getRandom(floor, ceiling, options.factor)
    rounds = rounds + 1 -- Increment rounds
  end

  -- Return the new value if we hit the target
  if value >= (floor*options.factor) and value <= (ceiling*options.factor) then
    print("getValueBetween found value in rounds:", value, rounds)
    return value
  end

  -- Set value to ceiling if above the given ceiling
  if value > ceiling then
    return ceiling * options.factor
  end

  -- Otherwise we return the floor
  return floor * options.factor
end

-- Get the widgets to tweak - Scope {"All", "Settings", "Random"}
helpers.getTweakables = function(tweakLevel, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton, scope)
  print("getTweakables with scope", scope)
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
    -- Check skip
    if scope > 1 then
      -- Use skip probability from settings
      if type(v.skipProbability) ~= "number" then
        v.skipProbability = 0
      end
      -- Used for random skip
      local probability = 50
      if scope == 2 then
        if v.excludeWhenTweaking == true then
          -- Always skip if excluded
          probability = 100
        else
          -- Use skip probability from settings
          probability = helpers.adjustProbabilityByTweakLevel(tweakLevel, v.skipProbability, 5)
        end
      end
      if skip == false then
        skip = gem.getRandomBoolean(probability)
      end
    end
    -- Ensure a target value is set
    v.targetValue = v.widget.value
    -- Skip if required
    if skip == true or v.widget.enabled == false then
      print("Skipping:", v.widget.name)
    else
      table.insert(t, v)
    end
  end

  print("Widgets ready:", #t)

  return t
end

-- Perform tweak
helpers.tweakWidget = function(options, duration, useDuration, tweakLevel)
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
  local durationInMilliseconds = beat2ms(duration)
  local millisecondsPerStep = 25
  print("Duration of change (beat):", duration)
  print("Duration of change (ms):", durationInMilliseconds)
  print("Change from/to:", startValue, endValue)
  local diff = math.max(endValue, startValue) - math.min(endValue, startValue)
  local numberOfSteps = math.floor(durationInMilliseconds / millisecondsPerStep)
  if gem.getRandomBoolean(tweakLevel) then
    -- Randomize tweak num steps
    numberOfSteps = gem.getRandom(numberOfSteps)
  end
  local changePerStep = diff / numberOfSteps
  print("Number of steps:", numberOfSteps)
  if durationInMilliseconds <= millisecondsPerStep then
    options.widget.value = endValue
    print("Short duration, skip steps:", endValue)
    return
  end
  local actualDuration = 0
  local isRising = startValue < endValue
  if isRising == false then
    changePerStep = -changePerStep
  end
  print("Change per step:", changePerStep)
  for i=1,numberOfSteps do
    if isPlaying == false or (isRising and startValue > endValue) or (isRising == false and startValue < endValue) then
      break
    end
    options.widget.value = gem.inc(options.widget.value, changePerStep)
    wait(millisecondsPerStep)
    actualDuration = actualDuration + millisecondsPerStep
  end
  print("******************** Duration complete:", options.widget.name, "********************")
  print("Value after duration actual/endValue", options.widget.value, endValue)
  options.widget.value = endValue
  print("Tweak startValue/endValue/duration/actualDuration:", startValue, endValue, duration, ms2beat(actualDuration))
end

helpers.applyValueFilter = function(valueFilter, startValue)
  table.sort(valueFilter) -- Ensure filter is sorted
  local endValue = startValue
  local index = 0
  local sortedFilter = {}
  -- Check value filter range
  if endValue < valueFilter[1] then
    -- Out of range - use lowest
    index = 1
  elseif endValue > valueFilter[#valueFilter] then
    -- Out of range - use highest
    index = #valueFilter
  end
  -- Try to find value in filter
  if index == 0 then
    for i,v in ipairs(valueFilter) do
      table.insert(sortedFilter, v)
      if endValue == v then
        index = i
        break
      end
    end
  end
  -- If value is not found in the value filter, we find the closest match
  if index == 0 then
    table.insert(sortedFilter, endValue)
    table.sort(sortedFilter)
    for i,v in ipairs(sortedFilter) do
      print("valueFilter sorted i/v", i, v)
      if v == endValue then
        -- Check nearest value
        local diffPrev = v - sortedFilter[i-1]
        local diffNext = sortedFilter[i+1] - v
        print("diffPrev, diffNext", diffPrev, diffNext)
        if diffPrev < diffNext then
          -- Get the index pos before
          index = i - 1
        else
          -- Get the index pos after
          -- We select i because we are iteration over sortedFilter that includes the endValue
          index = i
        end
        break
      end
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

-- Tweak options:
  -- widget = the widget to tweak - the only non-optional parameter
  -- func = the function to execute for getting the value - default is getRandom
  -- factor = a factor to multiply the random value with
  -- floor = the lowest value
  -- ceiling = the highest value
  -- probability = the probability (affected by tweak level) that value is within limits (floor/ceiling) - probability is passed to any custom func
  -- zero = the probability that the value is set to 0
  -- excludeWhenTweaking = this widget is skipped when tweaking
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
helpers.getTweakSuggestion = function(options, tweakLevel, envelopeStyle, modulationStyle, duration)
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
  elseif type(options.zero) == "number" and gem.getRandomBoolean(helpers.adjustProbabilityByTweakLevel(tweakLevel, options.zero)) then
    -- Set to zero if probability hits
    endValue = 0
    print("Zero:", options.zero)
  elseif type(options.default) == "number" and gem.getRandomBoolean(helpers.adjustProbabilityByTweakLevel(tweakLevel, options.default)) then
    -- Set to the default value if probability hits
    endValue = options.widget.default
    print("Default:", options.default)
  elseif modulationStyle > 1 and options.widget.name == 'LfoFreq' then
    endValue = helpers.getModulationFreqByStyle(options, modulationStyle)
    print("getModulationFreqByStyle:", endValue)
  elseif envelopeStyle > 1 and (options.attack == true or options.decay == true or options.release == true) then
    endValue = helpers.getEnvelopeTimeByStyle(options, envelopeStyle)
    print("getEnvelopeTimeByStyle:", endValue)
  elseif duration > 0 and envelopeStyle == 1 and (options.attack == true or options.decay == true or options.release == true) then
    -- Tweak like normal if probability hits
    if type(options.probability) == "number" and gem.getRandomBoolean(helpers.adjustProbabilityByTweakLevel(tweakLevel, options.probability)) then
      endValue = helpers.tweakValue(options, startValue, tweakLevel)
      print("getEnvelopeTime:", endValue)
    else
      endValue = helpers.getEnvelopeTimeForDuration(options, duration)
      print("getEnvelopeTimeForDuration:", endValue)
    end
  elseif type(options.fmLevel) == "number" and gem.getRandomBoolean(helpers.adjustProbabilityByTweakLevel(tweakLevel, options.fmLevel)) then
    endValue = gem.getRandom(nil, nil, options.widget.max)
    print("FM Operator Level: (max/endValue)", options.widget.max, endValue)
  else
    endValue = helpers.tweakValue(options, startValue, tweakLevel)
    print("Found tweakValue:", endValue)
  end
  if type(options.valueFilter) == "table" then
    print("Applying valueFilter to:", endValue)
    endValue = helpers.applyValueFilter(options.valueFilter, endValue)
  end
  if type(options.bipolar) == "number" and gem.getRandomBoolean(helpers.adjustProbabilityByTweakLevel(tweakLevel, options.bipolar)) then
    if gem.getRandom(100) <= options.bipolar then
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

helpers.getTweakable = function(name, selectedTweakables)
  for _,v in ipairs(tweakables) do
    if v.widget.name == name then
      return v
    end
  end
end

helpers.verifyModulationSettings = function(selectedTweakables)
  local LfoFreq = helpers.getTweakable("LfoFreq", selectedTweakables)
  local Lfo2Trigger = helpers.getTweakable("Lfo2Trigger", selectedTweakables)
  -- Lfo2Trigger should be on to avoid noise if LfoFreq has any changes
  if LfoFreq.targetValue ~= LfoFreq.widget.value then
    Lfo2Trigger.targetValue = true
  end
end

helpers.verifyFilterSettings = function(selectedTweakables)
  local Cutoff = helpers.getTweakable("Cutoff", selectedTweakables)
  local HpfCutoff = helpers.getTweakable("HpfCutoff", selectedTweakables)
  local EnvelopeAmt = helpers.getTweakable("EnvelopeAmt", selectedTweakables)
  local HpfEnvelopeAmt = helpers.getTweakable("HpfEnvelopeAmt", selectedTweakables)
  local FAttack = helpers.getTweakable("FAttack", selectedTweakables)
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
    cutoffValue = helpers.getValueBetween(0.2, 0.8, cutoffValue)
  end

  -- Increase env amount of cutoff is low
  if cutoffValue < 0.25 and envelopeAmtValue < 0.25 then
    --cutoffValue = getValueBetween(0.1, 0.6, cutoffValue)
    envelopeAmtValue = helpers.getValueBetween(0.65, 0.95, envelopeAmtValue)
  end
  
  -- Reduce long attack time if cutoff is low and env amt is high
  if cutoffValue < 0.05 and envelopeAmtValue > 0.75 and attackValue > 0.75 then
    attackValue = helpers.getValueBetween(0.01, 0.7, attackValue)
  end

  -- Check hpf amt
  if HpfCutoff.targetValue > 0.65 and hpfEnvelopeAmtValue >= 0 then
    hpfEnvelopeAmtValue = -(helpers.getValueBetween(0.1, 0.8, attackValue))
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

helpers.verifyOpLevelSettings = function(selectedTweakables)
  if synthTypes.isFM == false then
    return
  end
  local max = 1

  print("--- Checking Osc 1 Operator Levels ---")
  local Osc1Topology = helpers.getTweakable("Osc1Topology", selectedTweakables)
  local Osc1OpBLvl = helpers.getTweakable("Osc1LevelOpB", selectedTweakables)
  local Osc1OpCLvl = helpers.getTweakable("Osc1LevelOpC", selectedTweakables)
  local Osc1OpDLvl = helpers.getTweakable("Osc1LevelOpD", selectedTweakables)

  max = helpers.getMaxFromTopology(2, Osc1Topology.targetValue)
  if max < Osc1OpBLvl.targetValue then
    Osc1OpBLvl.targetValue = max
    print("Osc1OpBLvlm was adjusted to max", max)
  end

  max = helpers.getMaxFromTopology(3, Osc1Topology.targetValue)
  if max < Osc1OpCLvl.targetValue then
    Osc1OpCLvl.targetValue = max
    print("Osc1OpCLvl was adjusted to max", max)
  end

  max = helpers.getMaxFromTopology(4, Osc1Topology.targetValue)
  if max < Osc1OpDLvl.targetValue then
    Osc1OpDLvl.targetValue = max
    print("Osc1OpDLvl was adjusted to max", max)
  end
  
  print("--- Checking Osc 2 Operator Levels ---")
  local Osc2Topology = helpers.getTweakable("Osc2Topology", selectedTweakables)
  local Osc2OpBLvl = helpers.getTweakable("Osc2LevelOpB", selectedTweakables)
  local Osc2OpCLvl = helpers.getTweakable("Osc2LevelOpC", selectedTweakables)
  local Osc2OpDLvl = helpers.getTweakable("Osc2LevelOpD", selectedTweakables)

  max = helpers.getMaxFromTopology(2, Osc2Topology.targetValue)
  if max < Osc2OpBLvl.targetValue then
    Osc2OpBLvl.targetValue = max
    print("Osc2OpBLvl was adjusted to max", max)
  end

  max = helpers.getMaxFromTopology(3, Osc2Topology.targetValue)
  if max < Osc2OpCLvl.targetValue then
    Osc2OpCLvl.targetValue = max
    print("Osc2OpCLvl was adjusted to max", max)
  end

  max = helpers.getMaxFromTopology(4, Osc2Topology.targetValue)
  if max < Osc2OpDLvl.targetValue then
    Osc2OpDLvl.targetValue = max
    print("Osc2OpDLvl was adjusted to max", max)
  end
end

helpers.verifyUnisonSettings = function(selectedTweakables)
  local UnisonVoices = helpers.getTweakable("UnisonVoices", selectedTweakables)
  local UnisonDetune = helpers.getTweakable("UnisonDetune", selectedTweakables)

  if type(UnisonVoices) == "nil" or type(UnisonDetune) == "nil" then
    return
  end

  local factor = UnisonVoices.targetValue * 0.1

  print("--- Checking Unison Settings ---")
  print("UnisonVoices:", UnisonVoices.targetValue)
  print("UnisonDetune:", UnisonDetune.targetValue)
  print("Factor:", factor)

  if UnisonVoices.targetValue == 1 then
    UnisonDetune.targetValue = UnisonDetune.widget.default
    print("Unison off - detune set to default value:", UnisonDetune.targetValue)
  elseif UnisonDetune.targetValue > factor then
    local floor = UnisonDetune.widget.default / 2
    local ceiling = UnisonDetune.widget.default + factor
    UnisonDetune.targetValue = helpers.getValueBetween(floor, ceiling, UnisonDetune.targetValue)
    print("UnisonDetune adjusted to:", UnisonDetune.targetValue)
  else
    print("Unison Settings OK")
  end
end

helpers.verifyMixerSettings = function(selectedTweakables)
  local Osc1Mix = helpers.getTweakable("Osc1Mix", selectedTweakables)
  local Osc2Mix = helpers.getTweakable("Osc2Mix", selectedTweakables)
  local Osc3Mix = helpers.getTweakable("Osc3Mix", selectedTweakables)
  local SubOscMix = helpers.getTweakable("SubOscMix", selectedTweakables)

  print("--- Checking Mixer Settings ---")
  print("Osc1Mix:", Osc1Mix.targetValue)
  print("Osc2Mix:", Osc2Mix.targetValue)

  if Osc3Mix then
    print("Osc3Mix:", Osc3Mix.targetValue)

    if Osc3Mix.targetValue > 0 and Osc3Mix.targetValue < 0.6 then
      Osc3Mix.targetValue = helpers.getValueBetween(0.65, 0.8, Osc3Mix.targetValue)
      print("Osc3Mix adjusted to:", Osc3Mix.targetValue)
    end
  end

  if SubOscMix then
    print("SubOscMix:", SubOscMix.targetValue)

    if SubOscMix.targetValue > 0.2 and SubOscMix.targetValue < 0.7 then
      SubOscMix.targetValue = helpers.getValueBetween(0.7, 0.9, SubOscMix.targetValue)
      print("SubOscMix adjusted to:", SubOscMix.targetValue)
    elseif SubOscMix.targetValue < 0.2 then
      SubOscMix.targetValue = 0
      print("SubOscMix adjusted to:", SubOscMix.targetValue)
    end
  end

  if Osc2Mix.targetValue == 0 and Osc1Mix.targetValue < 0.6 then
    Osc1Mix.targetValue = helpers.getValueBetween(0.65, 0.8, Osc1Mix.targetValue)
    print("Osc1Mix adjusted to:", Osc1Mix.targetValue)
  elseif Osc1Mix.targetValue < 0.6 and Osc2Mix.targetValue < 0.6 then
    Osc1Mix.targetValue = helpers.getValueBetween(0.6, 0.8, Osc1Mix.targetValue)
    print("Osc1Mix adjusted to:", Osc1Mix.targetValue)
    Osc2Mix.targetValue = helpers.getValueBetween(0.6, 0.8, Osc2Mix.targetValue)
    print("Osc2Mix adjusted to:", Osc2Mix.targetValue)
  elseif Osc1Mix.targetValue < 0.6 or Osc2Mix.targetValue < 0.6 then
    if math.min(Osc1Mix.targetValue, Osc2Mix.targetValue) == Osc1Mix.targetValue then
      Osc1Mix.targetValue = helpers.getValueBetween(0.6, 0.8, Osc1Mix.targetValue)
      print("Osc1Mix adjusted to:", Osc1Mix.targetValue)
    else
      Osc2Mix.targetValue = helpers.getValueBetween(0.6, 0.8, Osc2Mix.targetValue)
      print("Osc2Mix adjusted to:", Osc2Mix.targetValue)
    end
  else
    print("Mixer Settings OK")
  end
end

-- Verify the suggested settings to avoid unwanted side effects
helpers.verifySettings = function(tweakLevel, selectedTweakables, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton)
  -- Verify modulation settings
  if modulationButton.value == true then
    helpers.verifyModulationSettings(selectedTweakables)
  end
  -- Verify unison/opLevel settings
  if synthesisButton.value == true then
    helpers.verifyOpLevelSettings(selectedTweakables)
    helpers.verifyUnisonSettings(selectedTweakables)
  end
  -- Verify filter settings
  if filterButton.value == true then
    helpers.verifyFilterSettings(selectedTweakables)
  end
  -- Verify mixer settings
  if mixerButton.value == true then
    helpers.verifyMixerSettings(selectedTweakables)
  end
end

local waveforms = {"Saw", "Square", "Triangle", "Sine", "Noise", "Pulse"}
if synthTypes.isDrum then
  waveforms = {"Sine", "Triangle", "Saw", "Pulse"}
end

helpers.formatTimeInSeconds = function(value)
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

helpers.formatGainInDb = function(value)
  if value == 0 then
      return "-inf"
  else
      local dB = 20 * math.log10(value)
      return string.format("%0.1f dB", dB)
  end
end

helpers.isEqual = function(value1, value2)
  if type(value1) == "number" then
    value1 = string.format("%0.3f", value1)
  end
  if type(value2) == "number" then
    value2 = string.format("%0.3f", value2)
  end
  return value1 == value2
end

helpers.getWidget = function(name)
  for _,v in ipairs(tweakables) do
    if v.widget.name == name then
      return v.widget
    end
  end
end

helpers.getSyncedValue = function(value)
  for i,v in ipairs(resolutions.getResolutions()) do
    print(i, " -- ", v)
    if helpers.isEqual(v, value) then
      print(v, "==", value)
      return i
    end
  end
  return 11
end

-- Logarithmic mapping for filter cutoff
-- Filter Max => 20000.
-- Filter Min => 20.
helpers.filterMapValue = function(value)
  local filterlogmax = math.log(20000.)
  local filterlogmin = math.log(20.)
  local filterlogrange = filterlogmax-filterlogmin  
  local newValue = (value * filterlogrange) + filterlogmin
  return math.exp(newValue)
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

local pageButtonSettings = {
  size = {97,27},
  spacing = 3,
  alpha = 1,
  backgroundColourOff = "#9f4A053B",
  backgroundColourOn = "#cfC722AF",
  textColourOff = "silver",
  textColourOn = "white"  ,
}

local patchmakerPageButton = pagePanel:OnOffButton("PatchmakerPage", true)
patchmakerPageButton.alpha = pageButtonSettings.alpha
patchmakerPageButton.backgroundColourOff = pageButtonSettings.backgroundColourOff
patchmakerPageButton.backgroundColourOn = pageButtonSettings.backgroundColourOn
patchmakerPageButton.textColourOff = pageButtonSettings.textColourOff
patchmakerPageButton.textColourOn = pageButtonSettings.textColourOn
patchmakerPageButton.displayName = "Patchmaker"
patchmakerPageButton.persistent = false
patchmakerPageButton.size = pageButtonSettings.size
patchmakerPageButton.x = pageButtonSettings.spacing

local twequencerPageButton = pagePanel:OnOffButton("TwequencerPage", false)
twequencerPageButton.alpha = pageButtonSettings.alpha
twequencerPageButton.backgroundColourOff = pageButtonSettings.backgroundColourOff
twequencerPageButton.backgroundColourOn = pageButtonSettings.backgroundColourOn
twequencerPageButton.textColourOff = pageButtonSettings.textColourOff
twequencerPageButton.textColourOn = pageButtonSettings.textColourOn
twequencerPageButton.displayName = "Twequencer"
twequencerPageButton.persistent = false
twequencerPageButton.size = pageButtonSettings.size
twequencerPageButton.x = patchmakerPageButton.x + patchmakerPageButton.width + pageButtonSettings.spacing

local synthesisPageButton = pagePanel:OnOffButton("SynthesisPage", false)
synthesisPageButton.alpha = pageButtonSettings.alpha
synthesisPageButton.backgroundColourOff = pageButtonSettings.backgroundColourOff
synthesisPageButton.backgroundColourOn = pageButtonSettings.backgroundColourOn
synthesisPageButton.textColourOff = pageButtonSettings.textColourOff
synthesisPageButton.textColourOn = pageButtonSettings.textColourOn
synthesisPageButton.displayName = "Synthesis"
synthesisPageButton.persistent = false
synthesisPageButton.size = pageButtonSettings.size
synthesisPageButton.x = twequencerPageButton.x + twequencerPageButton.width + pageButtonSettings.spacing

local filterPageButton = pagePanel:OnOffButton("FilterPage", false)
filterPageButton.alpha = pageButtonSettings.alpha
filterPageButton.backgroundColourOff = pageButtonSettings.backgroundColourOff
filterPageButton.backgroundColourOn = pageButtonSettings.backgroundColourOn
filterPageButton.textColourOff = pageButtonSettings.textColourOff
filterPageButton.textColourOn = pageButtonSettings.textColourOn
filterPageButton.displayName = "Filters"
filterPageButton.persistent = false
filterPageButton.size = pageButtonSettings.size
filterPageButton.x = synthesisPageButton.x + synthesisPageButton.width + pageButtonSettings.spacing

local modulationPageButton = pagePanel:OnOffButton("ModulationPage", false)
modulationPageButton.alpha = pageButtonSettings.alpha
modulationPageButton.backgroundColourOff = pageButtonSettings.backgroundColourOff
modulationPageButton.backgroundColourOn = pageButtonSettings.backgroundColourOn
modulationPageButton.textColourOff = pageButtonSettings.textColourOff
modulationPageButton.textColourOn = pageButtonSettings.textColourOn
modulationPageButton.displayName = "Modulation"
modulationPageButton.persistent = false
modulationPageButton.size = pageButtonSettings.size
modulationPageButton.x = filterPageButton.x + filterPageButton.width + pageButtonSettings.spacing

local effectsPageButton = pagePanel:OnOffButton("EffectsPage", false)
effectsPageButton.alpha = pageButtonSettings.alpha
effectsPageButton.backgroundColourOff = pageButtonSettings.backgroundColourOff
effectsPageButton.backgroundColourOn = pageButtonSettings.backgroundColourOn
effectsPageButton.textColourOff = pageButtonSettings.textColourOff
effectsPageButton.textColourOn = pageButtonSettings.textColourOn
effectsPageButton.displayName = "Effects"
effectsPageButton.persistent = false
effectsPageButton.size = pageButtonSettings.size
effectsPageButton.x = modulationPageButton.x + modulationPageButton.width + pageButtonSettings.spacing

local settingsPageButton = pagePanel:OnOffButton("SettingsPage", false)
settingsPageButton.alpha = pageButtonSettings.alpha
settingsPageButton.backgroundColourOff = pageButtonSettings.backgroundColourOff
settingsPageButton.backgroundColourOn = pageButtonSettings.backgroundColourOn
settingsPageButton.textColourOff = pageButtonSettings.textColourOff
settingsPageButton.textColourOn = pageButtonSettings.textColourOn
settingsPageButton.displayName = "Settings"
settingsPageButton.persistent = false
settingsPageButton.size = pageButtonSettings.size
settingsPageButton.x = effectsPageButton.x + effectsPageButton.width + pageButtonSettings.spacing

--------------------------------------------------------------------------------
-- Osc Panel Functions
--------------------------------------------------------------------------------

local panelCreators = {}

panelCreators.createStackOscPanel = function(oscPanel, oscillatorNumber)
  local maxOscillators = 8
  local osc

  if oscillatorNumber == 1 then
    osc = synthOscillators[1]
  else
    osc = synthOscillators[2]
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

local analog3OscSoloButtons = {}
panelCreators.createAnalog3OscPanel = function(oscPanel, oscillatorNumber)
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
    synthOscillators[1]:setParameter("Bypass"..oscillatorNumber, self.value)
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
      synthOscillators[1]:setParameter("Bypass"..i, bypass)
    end
    -- If no soloed oscillators remain, all bypasses must be cleared
    if hasSoloedOscs == false then
      for i=1,3 do
        synthOscillators[1]:setParameter("Bypass"..i, false)
      end
    end
  end
  table.insert(analog3OscSoloButtons, soloOscButton)

  local oscShapeKnob = oscPanel:Knob("Osc"..oscillatorNumber.."Wave", 1, 1, 6, true)
  oscShapeKnob.displayName = "Waveform"
  oscShapeKnob.fillColour = knobColour
  oscShapeKnob.outlineColour = osc1Colour
  oscShapeKnob.changed = function(self)
    synthOscillators[1]:setParameter("Waveform"..oscillatorNumber, self.value)
    self.displayText = waveforms[self.value]
  end
  oscShapeKnob:changed()
  table.insert(tweakables, {widget=oscShapeKnob,min=6,default=10,category="synthesis"})
    
  local oscPhaseKnob = oscPanel:Knob("Osc"..oscillatorNumber.."StartPhase", 0, 0, 1)
  oscPhaseKnob.unit = Unit.PercentNormalized
  oscPhaseKnob.displayName = "Start Phase"
  oscPhaseKnob.fillColour = knobColour
  oscPhaseKnob.outlineColour = osc1Colour
  oscPhaseKnob.changed = function(self)
    synthOscillators[1]:setParameter("StartPhase"..oscillatorNumber, self.value)
  end
  oscPhaseKnob:changed()
  table.insert(tweakables, {widget=oscPhaseKnob,default=50,category="synthesis"})
  
  local oscOctKnob = oscPanel:Knob("Osc"..oscillatorNumber.."Oct", 0, -2, 2, true)
  oscOctKnob.displayName = "Octave"
  oscOctKnob.fillColour = knobColour
  oscOctKnob.outlineColour = osc1Colour
  oscOctKnob.changed = function(self)
    synthOscillators[1]:setParameter("Octave"..oscillatorNumber, self.value)
    if oscillatorNumber == 1 then
      local factor = 1 / 4
      local value = (self.value * factor) + 0.5
      commonMacros.osc2Pitch:setParameter("Value", value)
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
    synthOscillators[1]:setParameter("Pitch"..oscillatorNumber, self.value)
    if oscillatorNumber == 1 then
      local factor = 1 / 48
      local value = (self.value * factor) + 0.5
      commonMacros.osc2Pitch:setParameter("Value", value)
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
      synthOscillators[1]:setParameter("SyncMode"..oscillatorNumber, self.value)
    end
    syncButton:changed()
    table.insert(tweakables, {widget=syncButton,func=getRandomBoolean,probability=20,category="synthesis"})
  end
end

--------------------------------------------------------------------------------
-- Osc 1
--------------------------------------------------------------------------------

panelCreators.createOsc1Panel = function()
  local osc1Panel = Panel("Osc1Panel")

  if synthTypes.isAnalogStack then
    osc1Panel:Label("Osc 1")
    panelCreators.createStackOscPanel(osc1Panel, 1)
  elseif synthTypes.isAnalog3Osc then
    osc1Panel:Label("Osc 1")
    panelCreators.createAnalog3OscPanel(osc1Panel, 1)
  elseif synthTypes.isFM then
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
      synthOscillators[1]:setParameter("Topology", self.value)
      self.displayText = topologies[self.value+1]
      -- Set max level for level knobs based on topology
      for i=2,4 do
        local max = helpers.getMaxFromTopology(i, self.value)
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
      synthOscillators[1]:setParameter("LevelA", self.value)
    end
    osc1LevelKnobA:changed()
    table.insert(osc1LevelKnobs, osc1LevelKnobA)
    table.insert(tweakables, {widget=osc1LevelKnobA,default=80,floor=0.85,ceil=1,probability=96,useDuration=true,category="synthesis"})

    local osc1LevelKnobB = osc1Panel:Knob("Osc1LevelOpB", 1, 0, 20)
    osc1LevelKnobB.displayName = "Level B"
    osc1LevelKnobB.fillColour = knobColour
    osc1LevelKnobB.outlineColour = osc1Colour
    osc1LevelKnobB.y = osc1TopologyKnob.y
    osc1LevelKnobB.x = osc1TopologyKnob.x + osc1TopologyKnob.width + marginX
    osc1LevelKnobB.changed = function(self)
      synthOscillators[1]:setParameter("LevelB", self.value)
    end
    osc1LevelKnobB:changed()
    table.insert(osc1LevelKnobs, osc1LevelKnobB)
    table.insert(tweakables, {widget=osc1LevelKnobB,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=3,fmLevel=25,useDuration=true,category="synthesis"})

    local osc1LevelKnobC = osc1Panel:Knob("Osc1LevelOpC", 1, 0, 20)
    osc1LevelKnobC.displayName = "Level C"
    osc1LevelKnobC.fillColour = knobColour
    osc1LevelKnobC.outlineColour = osc1Colour
    osc1LevelKnobC.y = osc1TopologyKnob.y
    osc1LevelKnobC.x = osc1TopologyKnob.x + osc1TopologyKnob.width + marginX
    osc1LevelKnobC.changed = function(self)
      synthOscillators[1]:setParameter("LevelC", self.value)
    end
    osc1LevelKnobC:changed()
    table.insert(osc1LevelKnobs, osc1LevelKnobC)
    table.insert(tweakables, {widget=osc1LevelKnobC,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=6,fmLevel=25,useDuration=true,category="synthesis"})

    local osc1LevelKnobD = osc1Panel:Knob("Osc1LevelOpD", 1, 0, 20)
    osc1LevelKnobD.displayName = "Level D"
    osc1LevelKnobD.fillColour = knobColour
    osc1LevelKnobD.outlineColour = osc1Colour
    osc1LevelKnobD.y = osc1TopologyKnob.y
    osc1LevelKnobD.x = osc1TopologyKnob.x + osc1TopologyKnob.width + marginX
    osc1LevelKnobD.changed = function(self)
      synthOscillators[1]:setParameter("LevelD", self.value)
    end
    osc1LevelKnobD:changed()
    table.insert(osc1LevelKnobs, osc1LevelKnobD)
    table.insert(tweakables, {widget=osc1LevelKnobD,default=50,zero=5,floor=0.5,ceil=1,probability=96,useDuration=true,defaultTweakRange=9,fmLevel=25,category="synthesis"})

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
        synthOscillators[1]:setParameter("Ratio"..op, self.value)
        self.displayText = self.value..'x'
      end
      osc1RatioKnob:changed()
      table.insert(osc1RatioKnobs, osc1RatioKnob)
      table.insert(tweakables, {widget=osc1RatioKnob,default=50,min=1,max=40,floor=1,ceiling=8,probability=probability,useDuration=true,category="synthesis"})
    end

    local osc1PitchKnob = osc1Panel:Knob("Osc1Pitch", 0, -2, 2, true)
    osc1PitchKnob.displayName = "Octave"
    osc1PitchKnob.fillColour = knobColour
    osc1PitchKnob.outlineColour = osc1Colour
    osc1PitchKnob.changed = function(self)
      local factor = 1 / 4
      local value = (self.value * factor) + 0.5
      commonMacros.osc1Pitch:setParameter("Value", value)
    end
    osc1PitchKnob:changed()
    table.insert(tweakables, {widget=osc1PitchKnob,min=-2,max=2,default=80,zero=25,category="synthesis"})

    local osc1FeedbackKnob = osc1Panel:Knob("Osc1Feedback", 0, 0, 1)
    osc1FeedbackKnob.unit = Unit.PercentNormalized
    osc1FeedbackKnob.displayName = "Feedback"
    osc1FeedbackKnob.fillColour = knobColour
    osc1FeedbackKnob.outlineColour = osc1Colour
    osc1FeedbackKnob.changed = function(self)
      synthOscillators[1]:setParameter("Feedback", self.value)
    end
    osc1FeedbackKnob:changed()
    table.insert(tweakables, {widget=osc1FeedbackKnob,default=60,floor=0.1,ceiling=0.6,probability=50,useDuration=true,category="synthesis"})

    osc1TopologyKnob:changed()
    opMenu:changed()
  else
    osc1Panel:Label("Osc 1")

    if synthTypes.isAnalog or synthTypes.isDrum then
      local osc1ShapeKnob = osc1Panel:Knob("Osc1Wave", 1, 1, #waveforms, true)
      osc1ShapeKnob.displayName = "Waveform"
      osc1ShapeKnob.fillColour = knobColour
      osc1ShapeKnob.outlineColour = osc1Colour
      osc1ShapeKnob.changed = function(self)
        local value = self.value
        if synthTypes.isDrum then
          value = value - 1
        end
        synthOscillators[1]:setParameter("Waveform", value)
        self.displayText = waveforms[self.value]
      end
      osc1ShapeKnob:changed()
      table.insert(tweakables, {widget=osc1ShapeKnob,min=6,default=10,category="synthesis"})
    elseif synthTypes.isWavetable then
      local osc1ShapeKnob = osc1Panel:Knob("Osc1WaveIndex", 0, 0, 1)
      osc1ShapeKnob.unit = Unit.PercentNormalized
      osc1ShapeKnob.displayName = "Wave"
      osc1ShapeKnob.fillColour = knobColour
      osc1ShapeKnob.outlineColour = osc1Colour
      osc1ShapeKnob.changed = function(self)
        commonMacros.osc1Shape:setParameter("Value", self.value)
      end
      osc1ShapeKnob:changed()
      table.insert(tweakables, {widget=osc1ShapeKnob,default=10,zero=5,probability=50,floor=0.3,ceil=0.6,useDuration=true,category="synthesis"})
    elseif synthTypes.isAdditive then
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
        commonMacros.osc1Shape:setParameter("Value", value)
      end
      osc1PartialsKnob:changed()
      table.insert(tweakables, {widget=osc1PartialsKnob,min=256,floor=2,ceiling=64,probability=70,useDuration=true,category="synthesis"})

      local osc1EvenOddKnob = osc1Panel:Knob("Osc1EvenOdd", 0, -1, 1)
      osc1EvenOddKnob.unit = Unit.PercentNormalized
      osc1EvenOddKnob.displayName = "Even/Odd"
      osc1EvenOddKnob.fillColour = knobColour
      osc1EvenOddKnob.outlineColour = osc1Colour
      osc1EvenOddKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["osc1EvenOdd"]:setParameter("Value", value)
      end
      osc1EvenOddKnob:changed()
      table.insert(tweakables, {widget=osc1EvenOddKnob,bipolar=50,default=10,floor=0.3,ceiling=0.9,probability=50,useDuration=true,category="synthesis"})
    end

    if synthTypes.isAnalog or synthTypes.isWavetable then
      local osc1PhaseKnob = osc1Panel:Knob("Osc1StartPhase", 0, 0, 1)
      osc1PhaseKnob.unit = Unit.PercentNormalized
      osc1PhaseKnob.displayName = "Start Phase"
      osc1PhaseKnob.fillColour = knobColour
      osc1PhaseKnob.outlineColour = osc1Colour
      osc1PhaseKnob.changed = function(self)
        synthOscillators[1]:setParameter("StartPhase", self.value)
      end
      osc1PhaseKnob:changed()
      table.insert(tweakables, {widget=osc1PhaseKnob,default=50,probability=50,floor=0,ceiling=0.5,useDuration=true,category="synthesis"})
    elseif synthTypes.isDrum then
      local osc1PitchModType = osc1Panel:Menu("Osc1PitchModType", {"Exponential", "Sine", "Noise"})
      --osc1PitchModType.x = osc1PitchModType.width
      --osc1PitchModType.y = osc1PitchModType.height + 5
      osc1PitchModType.displayName = "Mod Type"
      osc1PitchModType.backgroundColour = menuBackgroundColour
      osc1PitchModType.textColour = menuTextColour
      osc1PitchModType.arrowColour = menuArrowColour
      osc1PitchModType.outlineColour = menuOutlineColour
      osc1PitchModType.changed = function(self)
        synthOscillators[1]:setParameter("PitchModType", (self.value - 1))
      end
      osc1PitchModType:changed()
      table.insert(tweakables, {widget=osc1PitchModType,min=#osc1PitchModType.items,default=30,useDuration=false,category="synthesis"})

      local osc1PitchModRateKnob = osc1Panel:Knob("Osc1PitchModRate", .5, 0, 1)
      osc1PitchModRateKnob.displayName = "Mod Rate"
      --osc1PitchModRateKnob.mapper = Mapper.Quartic
      osc1PitchModRateKnob.unit = Unit.Hertz
      osc1PitchModRateKnob.fillColour = knobColour
      osc1PitchModRateKnob.outlineColour = osc1Colour
      osc1PitchModRateKnob.changed = function(self)
        drumMacros["osc1PitchModRate"]:setParameter("Value", self.value)
        local value = helpers.filterMapValue(self.value)
        if value < 1000 then
            self.displayText = string.format("%0.1f Hz", value)
        else
            self.displayText = string.format("%0.1f kHz", value/1000.)
        end
      end
      osc1PitchModRateKnob:changed()
      table.insert(tweakables, {widget=osc1PitchModRateKnob,floor=0.25,ceiling=.75,probability=75,default=75,useDuration=true,category="synthesis"})

      local osc1PitchModAmount = osc1Panel:Knob("Osc1PitchModAmount", 0, -96, 96)
      osc1PitchModAmount.displayName = "Mod Depth"
      osc1PitchModAmount.fillColour = knobColour
      osc1PitchModAmount.outlineColour = osc1Colour
      osc1PitchModAmount.changed = function(self)
        synthOscillators[1]:setParameter("PitchModAmount", self.value)
      end
      osc1PitchModAmount:changed()
      table.insert(tweakables, {widget=osc1PitchModAmount,zero=30,default=75,useDuration=true,category="synthesis"})

      local osc1ModVelSensKnob = osc1Panel:Knob("Osc1ModVelSens", 0, 0, 1)
      osc1ModVelSensKnob.unit = Unit.PercentNormalized
      osc1ModVelSensKnob.displayName = "Mod Vel Sens"
      osc1ModVelSensKnob.fillColour = knobColour
      osc1ModVelSensKnob.outlineColour = filterColour
      osc1ModVelSensKnob.changed = function(self)
        synthOscillators[1]:setParameter("ModVelSens", self.value)
      end
      osc1ModVelSensKnob:changed()
      table.insert(tweakables, {widget=osc1ModVelSensKnob,floor=0.,ceiling=.5,probability=80,zero=50,default=50,useDuration=true,category="synthesis"})

      local osc1NoiseMixKnob = osc1Panel:Knob("Osc1NoiseAmount", .5, 0, 1)
      osc1NoiseMixKnob.displayName = "Noise Mix"
      osc1NoiseMixKnob.y = osc1NoiseMixKnob.height + 10
      osc1NoiseMixKnob.unit = Unit.PercentNormalized
      osc1NoiseMixKnob.fillColour = knobColour
      osc1NoiseMixKnob.outlineColour = osc1Colour
      osc1NoiseMixKnob.changed = function(self)
        synthOscillators[1]:setParameter("Mix", self.value)
      end
      osc1NoiseMixKnob:changed()
      table.insert(tweakables, {widget=osc1NoiseMixKnob,floor=0,ceiling=.75,probability=80,default=50,zero=25,useDuration=true,category="synthesis"})    

      local osc1CutoffKnob = osc1Panel:Knob("Osc1Cutoff", 1000., 20., 20000.)
      osc1CutoffKnob.displayName = "Noise Cutoff"
      osc1CutoffKnob.mapper = Mapper.Exponential
      osc1CutoffKnob.unit = Unit.Hertz
      osc1CutoffKnob.fillColour = knobColour
      osc1CutoffKnob.outlineColour = osc1Colour
      osc1CutoffKnob.changed = function(self)
        synthOscillators[1]:setParameter("NoiseFilterFreq", self.value)
      end
      osc1CutoffKnob:changed()
      table.insert(tweakables, {widget=osc1CutoffKnob,floor=500,probability=75,default=75,useDuration=true,category="synthesis"})

      local osc1Distortion = osc1Panel:Knob("Osc1Distortion", 0, 0, 1)
      osc1Distortion.unit = Unit.PercentNormalized
      osc1Distortion.displayName = "Distortion"
      osc1Distortion.fillColour = knobColour
      osc1Distortion.outlineColour = filterColour
      osc1Distortion.changed = function(self)
        synthOscillators[1]:setParameter("Distortion", self.value)
      end
      osc1Distortion:changed()
      table.insert(tweakables, {widget=osc1Distortion,floor=0.,ceiling=.5,probability=80,zero=25,default=25,useDuration=true,category="synthesis"})

      local osc1FreqKnob = osc1Panel:Knob("Osc1Freq", 523, 20, 20000)
      osc1FreqKnob.unit = Unit.Hertz
      osc1FreqKnob.mapper = Mapper.Exponential
      osc1FreqKnob.displayName = "Frequency"
      osc1FreqKnob.fillColour = knobColour
      osc1FreqKnob.outlineColour = osc1Colour
      osc1FreqKnob.changed = function(self)
        -- Base: 523 = C4
        synthOscillators[1]:setParameter("OscFreq", self.value)
      end
      osc1FreqKnob:changed()
      local valueFilter = helpers.getDrumOscFrequencyFilterValues()
      table.insert(tweakables, {widget=osc1FreqKnob,ceiling=valueFilter[#valueFilter],probability=75,default=50,valueFilter=valueFilter,category="synthesis"})
    elseif synthTypes.isAdditive then
      local osc1CutoffKnob = osc1Panel:Knob("Osc1Cutoff", 1, 0, 1)
      osc1CutoffKnob.displayName = "Cutoff"
      osc1CutoffKnob.fillColour = knobColour
      osc1CutoffKnob.outlineColour = osc1Colour
      osc1CutoffKnob.changed = function(self)
        additiveMacros["osc1FilterCutoff"]:setParameter("Value", self.value)
        local value = helpers.filterMapValue(self.value)
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
      commonMacros.osc1Pitch:setParameter("Value", value)
    end
    osc1PitchKnob:changed()
    table.insert(tweakables, {widget=osc1PitchKnob,min=-2,max=2,default=80,zero=25,category="synthesis"})

    if synthTypes.isAnalog then
      local hardsyncKnob = osc1Panel:Knob("HardsyncOsc1", 0, 0, 36)
      hardsyncKnob.displayName = "Hardsync"
      hardsyncKnob.mapper = Mapper.Quadratic
      hardsyncKnob.fillColour = knobColour
      hardsyncKnob.outlineColour = osc1Colour
      hardsyncKnob.changed = function(self)
        synthOscillators[1]:setParameter("HardSyncShift", self.value)
      end
      hardsyncKnob:changed()
      table.insert(tweakables, {widget=hardsyncKnob,ceiling=12,probability=80,min=36,zero=50,default=50,useDuration=true,category="synthesis"})

      local atToHardsycKnob = osc1Panel:Knob("AtToHarsyncosc1", 0, 0, 1)
      atToHardsycKnob.unit = Unit.PercentNormalized
      atToHardsycKnob.displayName = "AT->Sync"
      atToHardsycKnob.fillColour = knobColour
      atToHardsycKnob.outlineColour = filterColour
      atToHardsycKnob.changed = function(self)
        analogMacros["atToHardsync1"]:setParameter("Value", self.value)
      end
      atToHardsycKnob:changed()
      table.insert(tweakables, {widget=atToHardsycKnob,zero=25,default=25,excludeWhenTweaking=true,category="synthesis"})
    elseif synthTypes.isWavetable then
      local aftertouchToWaveKnob = osc1Panel:Knob("AftertouchToWave1", 0, -1, 1)
      aftertouchToWaveKnob.unit = Unit.PercentNormalized
      aftertouchToWaveKnob.displayName = "AT->Wave"
      aftertouchToWaveKnob.fillColour = knobColour
      aftertouchToWaveKnob.outlineColour = filterColour
      aftertouchToWaveKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["atToShape1"]:setParameter("Value", value)
      end
      aftertouchToWaveKnob:changed()
      table.insert(tweakables, {widget=aftertouchToWaveKnob,bipolar=25,floor=0.5,ceiling=0.8,probability=60,default=50,excludeWhenTweaking=true,category="synthesis"})

      local wheelToWaveKnob = osc1Panel:Knob("WheelToWave1", 0, -1, 1)
      wheelToWaveKnob.unit = Unit.PercentNormalized
      wheelToWaveKnob.displayName = "Wheel->Wave"
      wheelToWaveKnob.fillColour = knobColour
      wheelToWaveKnob.outlineColour = filterColour
      wheelToWaveKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["wheelToShape1"]:setParameter("Value", value)
      end
      wheelToWaveKnob:changed()
      table.insert(tweakables, {widget=wheelToWaveKnob,bipolar=25,floor=0.3,ceiling=0.5,probability=60,default=50,excludeWhenTweaking=true,category="synthesis"})
    elseif synthTypes.isAdditive then
      local harmShiftKnob = osc1Panel:Knob("HarmShift1", 0, 0, 48)
      harmShiftKnob.displayName = "Harm. Shift"
      harmShiftKnob.fillColour = knobColour
      harmShiftKnob.outlineColour = filterColour
      harmShiftKnob.changed = function(self)
        synthOscillators[1]:setParameter("HarmShift", self.value)
      end
      harmShiftKnob:changed()
      table.insert(tweakables, {widget=harmShiftKnob,ceiling=12,probability=60,default=80,zero=20,useDuration=true,category="synthesis"})
    end
  end

  return osc1Panel
end

local osc1Panel = panelCreators.createOsc1Panel()

--------------------------------------------------------------------------------
-- Osc 2
--------------------------------------------------------------------------------

panelCreators.createOsc2Panel = function()
  local osc2Panel = Panel("Osc2Panel")

  if synthTypes.isAnalogStack then
    osc2Panel:Label("Osc 2")
    panelCreators.createStackOscPanel(osc2Panel, 2)
  elseif synthTypes.isAnalog3Osc then
    osc2Panel:Label("Osc 2")
    panelCreators.createAnalog3OscPanel(osc2Panel, 2)
  elseif synthTypes.isFM then
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
      synthOscillators[2]:setParameter("Topology", self.value)
      self.displayText = topologies[self.value+1]
      -- Set max level for level knobs based on topology
      for i=2,4 do
        local max = helpers.getMaxFromTopology(i, self.value)
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
      synthOscillators[2]:setParameter("LevelA", self.value)
    end
    osc2LevelKnobA:changed()
    table.insert(osc2LevelKnobs, osc2LevelKnobA)
    table.insert(tweakables, {widget=osc2LevelKnobA,default=80,floor=0.8,ceil=1,probability=90,useDuration=true,category="synthesis"})

    local osc2LevelKnobB = osc2Panel:Knob("Osc2LevelOpB", 1, 0, 20)
    osc2LevelKnobB.displayName = "Level B"
    osc2LevelKnobB.fillColour = knobColour
    osc2LevelKnobB.outlineColour = osc2Colour
    osc2LevelKnobB.y = osc2TopologyKnob.y
    osc2LevelKnobB.x = osc2TopologyKnob.x + osc2TopologyKnob.width + marginX
    osc2LevelKnobB.changed = function(self)
      synthOscillators[2]:setParameter("LevelB", self.value)
    end
    osc2LevelKnobB:changed()
    table.insert(osc2LevelKnobs, osc2LevelKnobB)
    table.insert(tweakables, {widget=osc2LevelKnobB,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=3,fmLevel=25,useDuration=true,category="synthesis"})

    local osc2LevelKnobC = osc2Panel:Knob("Osc2LevelOpC", 1, 0, 20)
    osc2LevelKnobC.displayName = "Level C"
    osc2LevelKnobC.fillColour = knobColour
    osc2LevelKnobC.outlineColour = osc2Colour
    osc2LevelKnobC.y = osc2TopologyKnob.y
    osc2LevelKnobC.x = osc2TopologyKnob.x + osc2TopologyKnob.width + marginX
    osc2LevelKnobC.changed = function(self)
      synthOscillators[2]:setParameter("LevelC", self.value)
    end
    osc2LevelKnobC:changed()
    table.insert(osc2LevelKnobs, osc2LevelKnobC)
    table.insert(tweakables, {widget=osc2LevelKnobC,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=6,fmLevel=25,useDuration=true,category="synthesis"})

    local osc2LevelKnobD = osc2Panel:Knob("Osc2LevelOpD", 1, 0, 20)
    osc2LevelKnobD.displayName = "Level D"
    osc2LevelKnobD.fillColour = knobColour
    osc2LevelKnobD.outlineColour = osc2Colour
    osc2LevelKnobD.y = osc2TopologyKnob.y
    osc2LevelKnobD.x = osc2TopologyKnob.x + osc2TopologyKnob.width + marginX
    osc2LevelKnobD.changed = function(self)
      synthOscillators[2]:setParameter("LevelD", self.value)
    end
    osc2LevelKnobD:changed()
    table.insert(osc2LevelKnobs, osc2LevelKnobD)
    table.insert(tweakables, {widget=osc2LevelKnobD,default=50,zero=5,floor=0.5,ceil=1,probability=96,defaultTweakRange=9,fmLevel=25,useDuration=true,category="synthesis"})

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
        synthOscillators[2]:setParameter("Ratio"..op, self.value)
        self.displayText = self.value..'x'
      end
      osc2RatioKnob:changed()
      table.insert(osc2RatioKnobs, osc2RatioKnob)
      table.insert(tweakables, {widget=osc2RatioKnob,default=50,min=1,max=40,floor=1,ceiling=8,probability=probability,category="synthesis"})
    end

    local osc2PitchKnob = osc2Panel:Knob("Osc2Pitch", 0, -24, 24, true)
    osc2PitchKnob.displayName = "Pitch"
    osc2PitchKnob.fillColour = knobColour
    osc2PitchKnob.outlineColour = osc2Colour
    osc2PitchKnob.changed = function(self)
      local factor = 1 / 48
      local value = (self.value * factor) + 0.5
      commonMacros.osc2Pitch:setParameter("Value", value)
    end
    osc2PitchKnob:changed()
    table.insert(tweakables, {widget=osc2PitchKnob,min=-24,max=24,integer=true,valueFilter={-24,-12,-5,0,7,12,19,24},floor=-12,ceiling=12,probability=75,default=50,zero=50,useDuration=true,category="synthesis"})

    local osc2FeedbackKnob = osc2Panel:Knob("Osc2Feedback", 0, 0, 1)
    osc2FeedbackKnob.unit = Unit.PercentNormalized
    osc2FeedbackKnob.displayName = "Feedback"
    osc2FeedbackKnob.fillColour = knobColour
    osc2FeedbackKnob.outlineColour = osc2Colour
    osc2FeedbackKnob.changed = function(self)
      synthOscillators[2]:setParameter("Feedback", self.value)
    end
    osc2FeedbackKnob:changed()
    table.insert(tweakables, {widget=osc2FeedbackKnob,default=60,floor=0.1,ceiling=0.6,probability=50,useDuration=true,category="synthesis"})

    osc2TopologyKnob:changed()
    opMenu:changed()
  else
    osc2Panel:Label("Osc 2")

    if synthTypes.isAnalog or synthTypes.isDrum then
      local osc2ShapeKnob = osc2Panel:Knob("Osc2Wave", 1, 1, #waveforms, true)
      osc2ShapeKnob.displayName = "Waveform"
      osc2ShapeKnob.fillColour = knobColour
      osc2ShapeKnob.outlineColour = osc2Colour
      osc2ShapeKnob.changed = function(self)
        local value = self.value
        if synthTypes.isDrum then
          value = value - 1
        end
        synthOscillators[2]:setParameter("Waveform", value)
        self.displayText = waveforms[self.value]
      end
      osc2ShapeKnob:changed()
      table.insert(tweakables, {widget=osc2ShapeKnob,min=max,default=10,category="synthesis"})
    elseif synthTypes.isWavetable then
      local osc2ShapeKnob = osc2Panel:Knob("Osc2WaveIndex", 0, 0, 1)
      osc2ShapeKnob.unit = Unit.PercentNormalized
      osc2ShapeKnob.displayName = "Wave"
      osc2ShapeKnob.fillColour = knobColour
      osc2ShapeKnob.outlineColour = osc2Colour
      osc2ShapeKnob.changed = function(self)
        commonMacros.osc2Shape:setParameter("Value", self.value)
      end
      osc2ShapeKnob:changed()
      table.insert(tweakables, {widget=osc2ShapeKnob,default=10,zero=5,probability=50,floor=0.3,ceil=0.6,useDuration=true,category="synthesis"})
    elseif synthTypes.isAdditive then
      local osc2PartialsKnob = osc2Panel:Knob("Osc2Partials", 1, 1, 256, true)
      osc2PartialsKnob.displayName = "Max Partials"
      osc2PartialsKnob.fillColour = knobColour
      osc2PartialsKnob.outlineColour = osc2Colour
      osc2PartialsKnob.changed = function(self)
        local factor = 1 / 256
        local value = self.value * factor
        if self.value == 1 then
          value = 0
        end
        commonMacros.osc2Shape:setParameter("Value", value)
      end
      osc2PartialsKnob:changed()
      table.insert(tweakables, {widget=osc2PartialsKnob,min=256,floor=2,ceiling=64,probability=70,useDuration=true,category="synthesis"})

      local osc2EvenOddKnob = osc2Panel:Knob("Osc2EvenOdd", 0, -1, 1)
      osc2EvenOddKnob.unit = Unit.PercentNormalized
      osc2EvenOddKnob.displayName = "Even/Odd"
      osc2EvenOddKnob.fillColour = knobColour
      osc2EvenOddKnob.outlineColour = osc2Colour
      osc2EvenOddKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["osc2EvenOdd"]:setParameter("Value", value)
      end
      osc2EvenOddKnob:changed()
      table.insert(tweakables, {widget=osc2EvenOddKnob,bipolar=50,floor=0.3,ceiling=0.9,probability=50,default=10,useDuration=true,category="synthesis"})
    end

    if synthTypes.isAnalog or synthTypes.isWavetable then
      local osc2PhaseKnob = osc2Panel:Knob("Osc2StartPhase", 0, 0, 1)
      osc2PhaseKnob.unit = Unit.PercentNormalized
      osc2PhaseKnob.displayName = "Start Phase"
      osc2PhaseKnob.fillColour = knobColour
      osc2PhaseKnob.outlineColour = osc2Colour
      osc2PhaseKnob.changed = function(self)
        synthOscillators[2]:setParameter("StartPhase", self.value)
      end
      osc2PhaseKnob:changed()
      table.insert(tweakables, {widget=osc2PhaseKnob,default=50,probability=50,floor=0.5,ceiling=1,useDuration=true,category="synthesis"})
    elseif synthTypes.isDrum then
      local osc2PitchModType = osc2Panel:Menu("Osc2PitchModType", {"Exponential", "Sine", "Noise"})
      --osc2PitchModType.x = osc2PitchModType.width
      --osc2PitchModType.y = osc2PitchModType.height + 5
      osc2PitchModType.displayName = "Mod Type"
      osc2PitchModType.backgroundColour = menuBackgroundColour
      osc2PitchModType.textColour = menuTextColour
      osc2PitchModType.arrowColour = menuArrowColour
      osc2PitchModType.outlineColour = menuOutlineColour
      osc2PitchModType.changed = function(self)
        synthOscillators[2]:setParameter("PitchModType", (self.value - 1))
      end
      osc2PitchModType:changed()
      table.insert(tweakables, {widget=osc2PitchModType,min=#osc2PitchModType.items,default=30,useDuration=false,category="synthesis"})

      local osc2PitchModRateKnob = osc2Panel:Knob("Osc2PitchModRate", .5, 0, 1)
      osc2PitchModRateKnob.displayName = "Mod Rate"
      --osc2PitchModRateKnob.mapper = Mapper.Quartic
      osc2PitchModRateKnob.unit = Unit.Hertz
      osc2PitchModRateKnob.fillColour = knobColour
      osc2PitchModRateKnob.outlineColour = osc2Colour
      osc2PitchModRateKnob.changed = function(self)
        drumMacros["osc2PitchModRate"]:setParameter("Value", self.value)
        local value = helpers.filterMapValue(self.value)
        if value < 1000 then
            self.displayText = string.format("%0.1f Hz", value)
        else
            self.displayText = string.format("%0.1f kHz", value/1000.)
        end
      end
      osc2PitchModRateKnob:changed()
      table.insert(tweakables, {widget=osc2PitchModRateKnob,floor=0.25,ceiling=.75,probability=75,default=75,useDuration=true,category="synthesis"})

      local osc2PitchModAmount = osc2Panel:Knob("Osc2PitchModAmount", 0, -96, 96)
      osc2PitchModAmount.displayName = "Mod Depth"
      osc2PitchModAmount.fillColour = knobColour
      osc2PitchModAmount.outlineColour = osc2Colour
      osc2PitchModAmount.changed = function(self)
        synthOscillators[2]:setParameter("PitchModAmount", self.value)
      end
      osc2PitchModAmount:changed()
      table.insert(tweakables, {widget=osc2PitchModAmount,zero=30,default=75,useDuration=true,category="synthesis"})

      local osc2ModVelSensKnob = osc2Panel:Knob("Osc2ModVelSens", 0, 0, 1)
      osc2ModVelSensKnob.unit = Unit.PercentNormalized
      osc2ModVelSensKnob.displayName = "Mod Vel Sens"
      osc2ModVelSensKnob.fillColour = knobColour
      osc2ModVelSensKnob.outlineColour = filterColour
      osc2ModVelSensKnob.changed = function(self)
        synthOscillators[2]:setParameter("ModVelSens", self.value)
      end
      osc2ModVelSensKnob:changed()
      table.insert(tweakables, {widget=osc2ModVelSensKnob,floor=0.,ceiling=.5,probability=80,zero=50,default=50,useDuration=true,category="synthesis"})

      local osc2NoiseMixKnob = osc2Panel:Knob("Osc2NoiseAmount", .5, 0, 1)
      osc2NoiseMixKnob.displayName = "Noise Mix"
      osc2NoiseMixKnob.y = osc2NoiseMixKnob.height + 10
      osc2NoiseMixKnob.unit = Unit.PercentNormalized
      osc2NoiseMixKnob.fillColour = knobColour
      osc2NoiseMixKnob.outlineColour = osc1Colour
      osc2NoiseMixKnob.changed = function(self)
        synthOscillators[2]:setParameter("Mix", self.value)
      end
      osc2NoiseMixKnob:changed()
      table.insert(tweakables, {widget=osc2NoiseMixKnob,floor=0,ceiling=.75,probability=80,default=50,zero=25,useDuration=true,category="synthesis"})

      local osc2CutoffKnob = osc2Panel:Knob("Osc2Cutoff", 1000., 20., 20000.)
      osc2CutoffKnob.displayName = "Noise Cutoff"
      osc2CutoffKnob.mapper = Mapper.Exponential
      osc2CutoffKnob.unit = Unit.Hertz
      osc2CutoffKnob.fillColour = knobColour
      osc2CutoffKnob.outlineColour = osc2Colour
      osc2CutoffKnob.changed = function(self)
        synthOscillators[2]:setParameter("NoiseFilterFreq", self.value)
      end
      osc2CutoffKnob:changed()
      table.insert(tweakables, {widget=osc2CutoffKnob,floor=500,probability=75,default=75,useDuration=true,category="synthesis"})

      local osc2Distortion = osc2Panel:Knob("Osc2Distortion", 0, 0, 1)
      osc2Distortion.unit = Unit.PercentNormalized
      osc2Distortion.displayName = "Distortion"
      osc2Distortion.fillColour = knobColour
      osc2Distortion.outlineColour = filterColour
      osc2Distortion.changed = function(self)
        synthOscillators[2]:setParameter("Distortion", self.value)
      end
      osc2Distortion:changed()
      table.insert(tweakables, {widget=osc2Distortion,floor=0.,ceiling=.5,probability=80,zero=25,default=25,useDuration=true,category="synthesis"})

      local osc2FreqKnob = osc2Panel:Knob("Osc2Freq", 523, 20, 20000)
      osc2FreqKnob.unit = Unit.Hertz
      osc2FreqKnob.mapper = Mapper.Exponential
      osc2FreqKnob.displayName = "Frequency"
      osc2FreqKnob.fillColour = knobColour
      osc2FreqKnob.outlineColour = osc2Colour
      osc2FreqKnob.changed = function(self)
        synthOscillators[2]:setParameter("OscFreq", self.value)
      end
      osc2FreqKnob:changed()
      local valueFilter = helpers.getDrumOscFrequencyFilterValues()
      table.insert(tweakables, {widget=osc2FreqKnob,ceiling=valueFilter[#valueFilter],probability=75,default=50,valueFilter=valueFilter,category="synthesis"})
    elseif synthTypes.isAdditive then
      local osc2CutoffKnob = osc2Panel:Knob("Osc2Cutoff", 1, 0, 1)
      osc2CutoffKnob.displayName = "Cutoff"
      osc2CutoffKnob.fillColour = knobColour
      osc2CutoffKnob.outlineColour = osc2Colour
      osc2CutoffKnob.changed = function(self)
        additiveMacros["osc2FilterCutoff"]:setParameter("Value", self.value)
        local value = helpers.filterMapValue(self.value)
        if value < 1000 then
            self.displayText = string.format("%0.1f Hz", value)
        else
            self.displayText = string.format("%0.1f kHz", value/1000.)
        end
      end
      osc2CutoffKnob:changed()
      table.insert(tweakables, {widget=osc2CutoffKnob,floor=0.6,ceiling=1.0,probability=80,default=50,useDuration=true,category="synthesis"})
    end

    --if synthTypes.isDrum == false then
      local osc2PitchKnob = osc2Panel:Knob("Osc2Pitch", 0, -24, 24, true)
      osc2PitchKnob.displayName = "Pitch"
      osc2PitchKnob.fillColour = knobColour
      osc2PitchKnob.outlineColour = osc2Colour
      osc2PitchKnob.changed = function(self)
        local factor = 1 / 48
        local value = (self.value * factor) + 0.5
        commonMacros.osc2Pitch:setParameter("Value", value)
      end
      osc2PitchKnob:changed()
      table.insert(tweakables, {widget=osc2PitchKnob,min=-24,max=24,integer=true,valueFilter={-24,-12,-5,0,7,12,19,24},floor=-12,ceiling=12,probability=75,default=50,zero=50,useDuration=true,category="synthesis"})
    --end

    if synthTypes.isAnalog or synthTypes.isDrum or synthTypes.isWavetable or synthTypes.isAdditive then
      local osc2DetuneKnob = osc2Panel:Knob("Osc2FinePitch", 0, 0, 1)
      osc2DetuneKnob.displayName = "Fine Pitch"
      osc2DetuneKnob.fillColour = knobColour
      osc2DetuneKnob.outlineColour = osc2Colour
      osc2DetuneKnob.changed = function(self)
        commonMacros.osc2Detune:setParameter("Value", self.value)
      end
      osc2DetuneKnob:changed()
      table.insert(tweakables, {widget=osc2DetuneKnob,ceiling=0.25,probability=90,default=50,defaultTweakRange=0.15,zero=25,absoluteLimit=0.4,useDuration=true,category="synthesis"})
    end

    if synthTypes.isAnalog then
      local hardsyncKnob = osc2Panel:Knob("HardsyncOsc2", 0, 0, 36)
      hardsyncKnob.displayName = "Hardsync"
      hardsyncKnob.mapper = Mapper.Quadratic
      hardsyncKnob.fillColour = knobColour
      hardsyncKnob.outlineColour = osc2Colour
      hardsyncKnob.changed = function(self)
        synthOscillators[2]:setParameter("HardSyncShift", self.value)
      end
      hardsyncKnob:changed()
      table.insert(tweakables, {widget=hardsyncKnob,ceiling=12,probability=80,min=36,zero=75,default=50,useDuration=true,category="synthesis"})
    elseif synthTypes.isWavetable then
      local wheelToWaveKnob = osc2Panel:Knob("WheelToWave2", 0, -1, 1)
      wheelToWaveKnob.unit = Unit.PercentNormalized
      wheelToWaveKnob.displayName = "Wheel->Wave"
      wheelToWaveKnob.fillColour = knobColour
      wheelToWaveKnob.outlineColour = filterColour
      wheelToWaveKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["wheelToShape2"]:setParameter("Value", value)
      end
      wheelToWaveKnob:changed()
      table.insert(tweakables, {widget=wheelToWaveKnob,bipolar=25,excludeWhenTweaking=true,category="synthesis"})
    end
  end

  return osc2Panel
end

local osc2Panel = panelCreators.createOsc2Panel()

--------------------------------------------------------------------------------
-- Osc 3
--------------------------------------------------------------------------------

panelCreators.createOsc3Panel = function()
  local osc3Panel = Panel("Osc3Panel")
  osc3Panel:Label("Osc 3")

  panelCreators.createAnalog3OscPanel(osc3Panel, 3)

  return osc3Panel
end

local osc3Panel
if synthTypes.isAnalog3Osc then
  osc3Panel = panelCreators.createOsc3Panel()
end

--------------------------------------------------------------------------------
-- Low-pass Filter
--------------------------------------------------------------------------------

panelCreators.createFilterPanel = function()
  local filterPanel = Panel("Filter")

  if synthTypes.isFM then
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
      local resonanceKnob = helpers.getWidget("Resonance")
      if resonanceKnob then
        resonanceKnob.enabled = self.value > 1
      end
    end
    filterDbMenu:changed()
    table.insert(tweakables, {widget=filterDbMenu,min=#slopes,default=85,category="filter"})
  elseif synthTypes.isAnalog or synthTypes.isDrum or synthTypes.isWavetable or synthTypes.isAnalog3Osc then
    local slopes = {"24dB", "12dB"}
    if synthTypes.isMinilogue then
      slopes = {"4-pole", "2-pole"}
    end
    local filterDbMenu = filterPanel:Menu("FilterDb", slopes)
    filterDbMenu.backgroundColour = menuBackgroundColour
    filterDbMenu.textColour = menuTextColour
    filterDbMenu.arrowColour = menuArrowColour
    filterDbMenu.outlineColour = menuOutlineColour
    filterDbMenu.displayName = "Low-pass Filter"
    filterDbMenu.changed = function(self)
      if synthTypes.isMinilogue then
        local value = self.value
        if self.value == 2 then
          value = 1
        else
          value = 3
        end
        filterInserts[1]:setParameter("Mode", value)
        filterInserts[2]:setParameter("Mode", value)
        filterInserts[3]:setParameter("Mode", value)
      else
        local value = -1
        if self.value == 2 then
          value = 1
        end
        if synthTypes.isWavetable then
          wavetableMacros["filterDb"]:setParameter("Value", value)
        elseif synthTypes.isDrum then
          drumMacros["filterDb"]:setParameter("Value", value)
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
    commonMacros.filterCutoff:setParameter("Value", self.value)
    local value = helpers.filterMapValue(self.value)
    if value < 1000 then
        self.displayText = string.format("%0.1f Hz", value)
    else
        self.displayText = string.format("%0.1f kHz", value/1000.)
    end
  end
  cutoffKnob:changed()
  table.insert(tweakables, {widget=cutoffKnob,floor=0.3,ceiling=0.7,probability=85,zero=25,default=35,useDuration=true,category="filter"})

  local filterResonanceKnob = filterPanel:Knob("Resonance", 0, 0, 1)
  filterResonanceKnob.unit = Unit.PercentNormalized
  filterResonanceKnob.fillColour = knobColour
  filterResonanceKnob.outlineColour = filterColour
  filterResonanceKnob.changed = function(self)
    commonMacros.filterResonance:setParameter("Value", self.value)
  end
  filterResonanceKnob:changed()
  table.insert(tweakables, {widget=filterResonanceKnob,floor=0.1,ceiling=0.6,probability=60,default=0,zero=30,absoluteLimit=0.8,useDuration=true,category="filter"})

  local filterKeyTrackingKnob = filterPanel:Knob("KeyTracking", 0, 0, 1)
  filterKeyTrackingKnob.unit = Unit.PercentNormalized
  filterKeyTrackingKnob.displayName = "Key Track"
  filterKeyTrackingKnob.fillColour = knobColour
  filterKeyTrackingKnob.outlineColour = filterColour
  filterKeyTrackingKnob.changed = function(self)
    commonMacros.filterKeyTracking:setParameter("Value", self.value)
  end
  filterKeyTrackingKnob:changed()
  table.insert(tweakables, {widget=filterKeyTrackingKnob,default=40,zero=50,excludeWhenTweaking=true,category="filter"})

  local wheelToCutoffKnob = filterPanel:Knob("WheelToCutoff", 0, -1, 1)
  wheelToCutoffKnob.unit = Unit.PercentNormalized
  wheelToCutoffKnob.displayName = "Modwheel"
  wheelToCutoffKnob.fillColour = knobColour
  wheelToCutoffKnob.outlineColour = filterColour
  wheelToCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.wheelToCutoff:setParameter("Value", value)
  end
  wheelToCutoffKnob:changed()
  table.insert(tweakables, {widget=wheelToCutoffKnob,bipolar=25,floor=0.2,ceiling=0.4,probability=50,excludeWhenTweaking=true,category="filter"})

  local atToCutoffKnob = filterPanel:Knob("AftertouchToCutoff", 0, -1, 1)
  atToCutoffKnob.unit = Unit.PercentNormalized
  atToCutoffKnob.displayName = "Aftertouch"
  atToCutoffKnob.fillColour = knobColour
  atToCutoffKnob.outlineColour = filterColour
  atToCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.atToCutoff:setParameter("Value", value)
  end
  atToCutoffKnob:changed()
  table.insert(tweakables, {widget=atToCutoffKnob,bipolar=25,floor=0.3,ceiling=0.6,probability=50,excludeWhenTweaking=true,category="filter"})

  return filterPanel
end

local filterPanel = panelCreators.createFilterPanel()

--------------------------------------------------------------------------------
-- High-pass Filter
--------------------------------------------------------------------------------

panelCreators.createHpFilterPanel = function()
  local hpFilterPanel = Panel("HPFilter")

  hpFilterPanel:Label("High-pass Filter")

  local hpfCutoffKnob = hpFilterPanel:Knob("HpfCutoff", 0, 0, 1)
  hpfCutoffKnob.displayName = "Cutoff"
  hpfCutoffKnob.fillColour = knobColour
  hpfCutoffKnob.outlineColour = filterColour
  hpfCutoffKnob.changed = function(self)
    commonMacros.hpfCutoff:setParameter("Value", self.value)
    local value = helpers.filterMapValue(self.value)
    if value < 1000 then
        self.displayText = string.format("%0.1f Hz", value)
    else
        self.displayText = string.format("%0.1f kHz", value/1000.)
    end
  end
  hpfCutoffKnob:changed()
  table.insert(tweakables, {widget=hpfCutoffKnob,ceiling=0.4,probability=90,zero=60,default=20,useDuration=true,category="filter"})

  local hpfResonanceKnob = hpFilterPanel:Knob("HpfResonance", 0, 0, 1)
  hpfResonanceKnob.unit = Unit.PercentNormalized
  hpfResonanceKnob.displayName = "Resonance"
  hpfResonanceKnob.fillColour = knobColour
  hpfResonanceKnob.outlineColour = filterColour
  hpfResonanceKnob.changed = function(self)
    commonMacros.hpfResonance:setParameter("Value", self.value)
  end
  hpfResonanceKnob:changed()
  table.insert(tweakables, {widget=hpfResonanceKnob,ceiling=0.5,probability=80,absoluteLimit=0.8,default=50,useDuration=true,category="filter"})

  local hpfKeyTrackingKnob = hpFilterPanel:Knob("HpfKeyTracking", 0, 0, 1)
  hpfKeyTrackingKnob.unit = Unit.PercentNormalized
  hpfKeyTrackingKnob.displayName = "Key Track"
  hpfKeyTrackingKnob.fillColour = knobColour
  hpfKeyTrackingKnob.outlineColour = filterColour
  hpfKeyTrackingKnob.changed = function(self)
    commonMacros.hpfKeyTracking:setParameter("Value", self.value)
  end
  hpfKeyTrackingKnob:changed()
  table.insert(tweakables, {widget=hpfKeyTrackingKnob,floor=0.2,ceiling=0.8,probability=50,excludeWhenTweaking=true,category="filter"})

  local wheelToHpfCutoffKnob = hpFilterPanel:Knob("WheelToHpfCutoff", 0, -1, 1)
  wheelToHpfCutoffKnob.unit = Unit.PercentNormalized
  wheelToHpfCutoffKnob.displayName = "Modwheel"
  wheelToHpfCutoffKnob.fillColour = knobColour
  wheelToHpfCutoffKnob.outlineColour = filterColour
  wheelToHpfCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.wheelToHpf:setParameter("Value", value)
  end
  wheelToHpfCutoffKnob:changed()
  table.insert(tweakables, {widget=wheelToHpfCutoffKnob,bipolar=25,floor=0.2,ceiling=0.4,probability=30,excludeWhenTweaking=true,category="filter"})

  local atToHpfCutoffKnob = hpFilterPanel:Knob("AftertouchToHpfCutoff", 0, -1, 1)
  atToHpfCutoffKnob.unit = Unit.PercentNormalized
  atToHpfCutoffKnob.displayName = "Aftertouch"
  atToHpfCutoffKnob.fillColour = knobColour
  atToHpfCutoffKnob.outlineColour = filterColour
  atToHpfCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.atToHpf:setParameter("Value", value)
  end
  atToHpfCutoffKnob:changed()
  table.insert(tweakables, {widget=atToHpfCutoffKnob,bipolar=25,floor=0.3,ceiling=0.7,probability=30,excludeWhenTweaking=true,category="filter"})

  return hpFilterPanel
end

local hpFilterPanel = panelCreators.createHpFilterPanel()

--------------------------------------------------------------------------------
-- Filter Env
--------------------------------------------------------------------------------

panelCreators.createFilterEnvPanel = function()
  local filterEnvPanel = Panel("FilterEnv")

  local activeFilterEnvOsc = 1
  local filterEnvMenu
  if synthTypes.isAnalog3Osc == true then
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
      synthModulators.filterEnv1:setParameter("AttackTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      synthModulators.filterEnv2:setParameter("AttackTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      synthModulators.filterEnvNoise:setParameter("AttackTime", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  filterAttackKnob:changed()
  table.insert(tweakables, {widget=filterAttackKnob,attack=true,floor=0.001,ceiling=0.01,probability=85,default=35,defaultTweakRange=0.3,useDuration=false,category="filter"})

  local filterDecayKnob = filterEnvPanel:Knob("FDecay", 0.050, 0, 10)
  filterDecayKnob.displayName="Decay"
  filterDecayKnob.fillColour = knobColour
  filterDecayKnob.outlineColour = filterEnvColour
  filterDecayKnob.mapper = Mapper.Quartic
  filterDecayKnob.changed = function(self)
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 2 then
      synthModulators.filterEnv1:setParameter("DecayTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      synthModulators.filterEnv2:setParameter("DecayTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      synthModulators.filterEnvNoise:setParameter("DecayTime", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  filterDecayKnob:changed()
  table.insert(tweakables, {widget=filterDecayKnob,decay=true,floor=0.01,ceiling=0.75,probability=50,default=10,useDuration=false,category="filter"})

  local filterSustainKnob = filterEnvPanel:Knob("FSustain", 1, 0, 1)
  filterSustainKnob.unit = Unit.PercentNormalized
  filterSustainKnob.displayName="Sustain"
  filterSustainKnob.fillColour = knobColour
  filterSustainKnob.outlineColour = filterEnvColour
  filterSustainKnob.changed = function(self)
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 2 then
      synthModulators.filterEnv1:setParameter("SustainLevel", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      synthModulators.filterEnv2:setParameter("SustainLevel", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      synthModulators.filterEnvNoise:setParameter("SustainLevel", self.value)
    end
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
      synthModulators.filterEnv1:setParameter("ReleaseTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      synthModulators.filterEnv2:setParameter("ReleaseTime", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      synthModulators.filterEnvNoise:setParameter("ReleaseTime", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  filterReleaseKnob:changed()
  table.insert(tweakables, {widget=filterReleaseKnob,release=true,floor=0.01,ceiling=0.8,probability=70,default=35,defaultTweakRange=2,useDuration=true,category="filter"})

  local filterVelocityKnob = filterEnvPanel:Knob("VelocityToFilterEnv", 10, 0, 40)
  filterVelocityKnob.displayName="Velocity"
  filterVelocityKnob.fillColour = knobColour
  filterVelocityKnob.outlineColour = filterEnvColour
  filterVelocityKnob.changed = function(self)
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 2 then
      synthModulators.filterEnv1:setParameter("DynamicRange", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 3 then
      synthModulators.filterEnv2:setParameter("DynamicRange", self.value)
    end
    if activeFilterEnvOsc == 1 or activeFilterEnvOsc == 4 then
      synthModulators.filterEnvNoise:setParameter("DynamicRange", self.value)
    end
  end
  filterVelocityKnob:changed()
  table.insert(tweakables, {widget=filterVelocityKnob,floor=5,ceiling=25,probability=80,min=40,default=70,useDuration=true,category="filter"})

  function setFilterEnvKnob(knob, param)
    if activeFilterEnvOsc == 1 then
      knob.enabled = helpers.isEqual(synthModulators.filterEnv1:getParameter(param), synthModulators.filterEnv2:getParameter(param)) and helpers.isEqual(synthModulators.filterEnv2:getParameter(param), synthModulators.filterEnvNoise:getParameter(param))
      return
    end
    local value
    if activeFilterEnvOsc == 2 then
      value = synthModulators.filterEnv1:getParameter(param)
    elseif activeFilterEnvOsc == 3 then
      value = synthModulators.filterEnv2:getParameter(param)
    elseif activeFilterEnvOsc == 4 then
      value = synthModulators.filterEnvNoise:getParameter(param)
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

local filterEnvPanel = panelCreators.createFilterEnvPanel()

--------------------------------------------------------------------------------
-- Filter Env Targets
--------------------------------------------------------------------------------

panelCreators.createFilterEnvTargetsPanel = function()
  local filterEnvTargetsPanel = Panel("FilterEnvTargets")

  filterEnvTargetsPanel:Label("Filter Env ->")

  local envAmtKnob = filterEnvTargetsPanel:Knob("EnvelopeAmt", 0, -1, 1)
  envAmtKnob.unit = Unit.PercentNormalized
  envAmtKnob.displayName = "LP-Filter"
  envAmtKnob.fillColour = knobColour
  envAmtKnob.outlineColour = filterColour
  envAmtKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.filterEnvAmount:setParameter("Value", value)
  end
  envAmtKnob:changed()
  table.insert(tweakables, {widget=envAmtKnob,bipolar=5,floor=0.3,ceiling=0.9,probability=60,default=3,zero=3,useDuration=true,category="filter"})

  local hpfEnvAmtKnob = filterEnvTargetsPanel:Knob("HpfEnvelopeAmt", 0, -1, 1)
  hpfEnvAmtKnob.unit = Unit.PercentNormalized
  hpfEnvAmtKnob.displayName = "HP-Filter"
  hpfEnvAmtKnob.fillColour = knobColour
  hpfEnvAmtKnob.outlineColour = filterColour
  hpfEnvAmtKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.hpfEnvAmount:setParameter("Value", value)
  end
  hpfEnvAmtKnob:changed()
  table.insert(tweakables, {widget=hpfEnvAmtKnob,absoluteLimit=0.8,floor=0.1,ceiling=0.3,probability=90,zero=25,default=25,bipolar=25,useDuration=true,category="filter"})

  return filterEnvTargetsPanel
end

panelCreators.createFilterEnvOscTargetsPanel = function()
  local filterEnvOscTargetsPanel = Panel("FilterEnvOscTargets")

  if synthTypes.isAnalog3Osc then
    filterEnvOscTargetsPanel:Label("Filter Env -> Osc ->")

    local filterEnvToPitchOsc1Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToPitchOsc1", 0, 0, 48)
    filterEnvToPitchOsc1Knob.displayName = "Pitch 1"
    filterEnvToPitchOsc1Knob.mapper = Mapper.Quadratic
    filterEnvToPitchOsc1Knob.fillColour = knobColour
    filterEnvToPitchOsc1Knob.outlineColour = filterEnvColour
    filterEnvToPitchOsc1Knob.changed = function(self)
      local factor = 1 / 48
      local value = self.value * factor
      commonMacros.filterEnvToPitchOsc1:setParameter("Value", value)
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
      commonMacros.filterEnvToPitchOsc2:setParameter("Value", value)
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
  elseif synthTypes.isFM then
    local filterEnvToOsc1OpBLevelKnob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvToOpBLevel", 0, 0, 1)
    filterEnvToOsc1OpBLevelKnob.unit = Unit.PercentNormalized
    filterEnvToOsc1OpBLevelKnob.displayName = "Osc1 OpB Lvl"
    filterEnvToOsc1OpBLevelKnob.fillColour = knobColour
    filterEnvToOsc1OpBLevelKnob.outlineColour = lfoColour
    filterEnvToOsc1OpBLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc1OpBLevel"]:setParameter("Value", self.value)
    end
    filterEnvToOsc1OpBLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc1OpBLevelKnob,default=50,zero=30,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc1OpCLevelKnob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvToOpCLevel", 0, 0, 1)
    filterEnvToOsc1OpCLevelKnob.unit = Unit.PercentNormalized
    filterEnvToOsc1OpCLevelKnob.displayName = "Osc1 OpC Lvl"
    filterEnvToOsc1OpCLevelKnob.fillColour = knobColour
    filterEnvToOsc1OpCLevelKnob.outlineColour = lfoColour
    filterEnvToOsc1OpCLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc1OpCLevel"]:setParameter("Value", self.value)
    end
    filterEnvToOsc1OpCLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc1OpCLevelKnob,default=60,zero=40,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc1OpDLevelKnob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvToOpDLevel", 0, 0, 1)
    filterEnvToOsc1OpDLevelKnob.unit = Unit.PercentNormalized
    filterEnvToOsc1OpDLevelKnob.displayName = "Osc1 OpD Lvl"
    filterEnvToOsc1OpDLevelKnob.fillColour = knobColour
    filterEnvToOsc1OpDLevelKnob.outlineColour = lfoColour
    filterEnvToOsc1OpDLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc1OpDLevel"]:setParameter("Value", self.value)
    end
    filterEnvToOsc1OpDLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc1OpDLevelKnob,default=70,zero=50,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc2OpBLevelKnob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvToOpBLevel", 0, 0, 1)
    filterEnvToOsc2OpBLevelKnob.unit = Unit.PercentNormalized
    filterEnvToOsc2OpBLevelKnob.displayName = "Osc2 OpB Lvl"
    filterEnvToOsc2OpBLevelKnob.fillColour = knobColour
    filterEnvToOsc2OpBLevelKnob.outlineColour = lfoColour
    filterEnvToOsc2OpBLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc2OpBLevel"]:setParameter("Value", self.value)
    end
    filterEnvToOsc2OpBLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc2OpBLevelKnob,default=50,zero=30,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc2OpCLevelKnob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvToOpCLevel", 0, 0, 1)
    filterEnvToOsc2OpCLevelKnob.unit = Unit.PercentNormalized
    filterEnvToOsc2OpCLevelKnob.displayName = "Osc2 OpC Lvl"
    filterEnvToOsc2OpCLevelKnob.fillColour = knobColour
    filterEnvToOsc2OpCLevelKnob.outlineColour = lfoColour
    filterEnvToOsc2OpCLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc2OpCLevel"]:setParameter("Value", self.value)
    end
    filterEnvToOsc2OpCLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc2OpCLevelKnob,default=60,zero=40,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})

    local filterEnvToOsc2OpDLevelKnob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvToOpDLevel", 0, 0, 1)
    filterEnvToOsc2OpDLevelKnob.unit = Unit.PercentNormalized
    filterEnvToOsc2OpDLevelKnob.displayName = "Osc2 OpD Lvl"
    filterEnvToOsc2OpDLevelKnob.fillColour = knobColour
    filterEnvToOsc2OpDLevelKnob.outlineColour = lfoColour
    filterEnvToOsc2OpDLevelKnob.changed = function(self)
      FMMacros["filterEnvToOsc2OpDLevel"]:setParameter("Value", self.value)
    end
    filterEnvToOsc2OpDLevelKnob:changed()
    table.insert(tweakables, {widget=filterEnvToOsc2OpDLevelKnob,default=70,zero=50,floor=0.1,ceiling=0.6,probability=30,useDuration=true,category="filter"})
  elseif synthTypes.isAnalog or synthTypes.isDrum or synthTypes.isAdditive or synthTypes.isWavetable then
    filterEnvOscTargetsPanel:Label("Filter Env -> Osc 1 ->")

    if synthTypes.isAnalog then
      local filterEnvToHardsync1Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToHardsync1", 0, 0, 1)
      filterEnvToHardsync1Knob.unit = Unit.PercentNormalized
      filterEnvToHardsync1Knob.displayName = "Hardsync"
      filterEnvToHardsync1Knob.fillColour = knobColour
      filterEnvToHardsync1Knob.outlineColour = filterEnvColour
      filterEnvToHardsync1Knob.changed = function(self)
        analogMacros["filterEnvToHardsync1"]:setParameter("Value", self.value)
      end
      filterEnvToHardsync1Knob:changed()
      table.insert(tweakables, {widget=filterEnvToHardsync1Knob,zero=50,default=70,ceiling=0.5,probability=80,useDuration=true,category="filter"})
    elseif synthTypes.isDrum then
      local filterEnvToNoise1CutoffKnob = filterEnvOscTargetsPanel:Knob("FilterEnvToNoise1Cutoff", 0, -1, 1)
      filterEnvToNoise1CutoffKnob.unit = Unit.PercentNormalized
      filterEnvToNoise1CutoffKnob.displayName = "Noise Cutoff"
      filterEnvToNoise1CutoffKnob.fillColour = knobColour
      filterEnvToNoise1CutoffKnob.outlineColour = filterEnvColour
      filterEnvToNoise1CutoffKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["filterEnvToNoise1Cutoff"]:setParameter("Value", value)
      end
      filterEnvToNoise1CutoffKnob:changed()
      table.insert(tweakables, {widget=filterEnvToNoise1CutoffKnob,zero=50,default=70,ceiling=0.5,probability=80,useDuration=true,category="filter"})
    elseif synthTypes.isWavetable then
      local filterEnvToWT1Knob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvToIndex", 0, -1, 1)
      filterEnvToWT1Knob.unit = Unit.PercentNormalized
      filterEnvToWT1Knob.displayName = "Waveindex"
      filterEnvToWT1Knob.fillColour = knobColour
      filterEnvToWT1Knob.outlineColour = lfoColour
      filterEnvToWT1Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["filterEnvToWT1"]:setParameter("Value", value)
      end
      filterEnvToWT1Knob:changed()
      table.insert(tweakables, {widget=filterEnvToWT1Knob,bipolar=25,useDuration=true,category="filter"})
    elseif synthTypes.isAdditive then
      local oscFilterEnvAmtKnob = filterEnvOscTargetsPanel:Knob("Osc1FilterEnvelopeAmt", 0, -1, 1)
      oscFilterEnvAmtKnob.unit = Unit.PercentNormalized
      oscFilterEnvAmtKnob.displayName = "Cutoff"
      oscFilterEnvAmtKnob.fillColour = knobColour
      oscFilterEnvAmtKnob.outlineColour = filterColour
      oscFilterEnvAmtKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["filterEnvToCutoff1"]:setParameter("Value", value)
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
      commonMacros.filterEnvToPitchOsc1:setParameter("Value", value)
    end
    filterEnvToPitchOsc1Knob:changed()
    table.insert(tweakables, {widget=filterEnvToPitchOsc1Knob,ceiling=0.8,probability=90,default=80,zero=10,useDuration=true,category="filter"})

    filterEnvOscTargetsPanel:Label("Filter Env -> Osc 2 ->")

    if synthTypes.isAnalog then
      local filterEnvToHardsync2Knob = filterEnvOscTargetsPanel:Knob("FilterEnvToHardsync2", 0, 0, 1)
      filterEnvToHardsync2Knob.unit = Unit.PercentNormalized
      filterEnvToHardsync2Knob.displayName = "Hardsync"
      filterEnvToHardsync2Knob.fillColour = knobColour
      filterEnvToHardsync2Knob.outlineColour = filterEnvColour
      filterEnvToHardsync2Knob.changed = function(self)
        analogMacros["filterEnvToHardsync2"]:setParameter("Value", self.value)
      end
      filterEnvToHardsync2Knob:changed()
      table.insert(tweakables, {widget=filterEnvToHardsync2Knob,zero=50,default=70,floor=0.1,ceiling=0.4,probability=90,useDuration=true,category="filter"})
    elseif synthTypes.isDrum then
      local filterEnvToNoise2CutoffKnob = filterEnvOscTargetsPanel:Knob("FilterEnvToNoise2Cutoff", 0, -1, 1)
      filterEnvToNoise2CutoffKnob.unit = Unit.PercentNormalized
      filterEnvToNoise2CutoffKnob.displayName = "Noise Cutoff"
      filterEnvToNoise2CutoffKnob.fillColour = knobColour
      filterEnvToNoise2CutoffKnob.outlineColour = filterEnvColour
      filterEnvToNoise2CutoffKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["filterEnvToNoise2Cutoff"]:setParameter("Value", value)
      end
      filterEnvToNoise2CutoffKnob:changed()
      table.insert(tweakables, {widget=filterEnvToNoise2CutoffKnob,zero=50,default=70,ceiling=0.5,probability=80,useDuration=true,category="filter"})
    elseif synthTypes.isWavetable then
      local filterEnvToWT2Knob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvToIndex", 0, -1, 1)
      filterEnvToWT2Knob.unit = Unit.PercentNormalized
      filterEnvToWT2Knob.displayName = "Waveindex"
      filterEnvToWT2Knob.fillColour = knobColour
      filterEnvToWT2Knob.outlineColour = lfoColour
      filterEnvToWT2Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["filterEnvToWT2"]:setParameter("Value", value)
      end
      filterEnvToWT2Knob:changed()
      table.insert(tweakables, {widget=filterEnvToWT2Knob,bipolar=25,zero=25,floor=0.2,ceiling=0.7,probability=20,useDuration=true,category="filter"})
    elseif synthTypes.isAdditive then
      local oscFilterEnvAmtKnob = filterEnvOscTargetsPanel:Knob("Osc2FilterEnvelopeAmt", 0, -1, 1)
      oscFilterEnvAmtKnob.unit = Unit.PercentNormalized
      oscFilterEnvAmtKnob.displayName = "Cutoff"
      oscFilterEnvAmtKnob.fillColour = knobColour
      oscFilterEnvAmtKnob.outlineColour = filterColour
      oscFilterEnvAmtKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["filterEnvToCutoff2"]:setParameter("Value", value)
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
      commonMacros.filterEnvToPitchOsc2:setParameter("Value", value)
    end
    filterEnvToPitchOsc2Knob:changed()
    table.insert(tweakables, {widget=filterEnvToPitchOsc2Knob,ceiling=0.1,probability=85,default=75,zero=25,useDuration=true,category="filter"})
  end

  return filterEnvOscTargetsPanel
end

local filterEnvTargetsPanel = panelCreators.createFilterEnvTargetsPanel()
local filterEnvOscTargetsPanel = panelCreators.createFilterEnvOscTargetsPanel()

--------------------------------------------------------------------------------
-- LFO
--------------------------------------------------------------------------------

panelCreators.createLfoPanel = function()
  local lfoPanel = Panel("LFO")

  local activeLfoOsc = 1

  local lfoMenu
  if synthTypes.isAnalog3Osc == true then
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
      synthModulators.lfo1:setParameter("WaveFormType", value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      synthModulators.lfo2:setParameter("WaveFormType", value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      synthModulators.lfo3:setParameter("WaveFormType", value)
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
      synthModulators.lfo1:setParameter("SyncToHost", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      synthModulators.lfo2:setParameter("SyncToHost", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      synthModulators.lfo3:setParameter("SyncToHost", self.value)
    end
    if self.value == false then
      lfoFreqKnob:setRange(0.1, 20.)
      lfoFreqKnob.default = 4.5
      lfoFreqKnob.mapper = Mapper.Quadratic
      lfoFreqKnob.changed = function(self)
        --print("Sync off, value in", self.value)
        if activeLfoOsc == 1 or activeLfoOsc == 2 then
          synthModulators.lfo1:setParameter("Freq", self.value)
        end
        if activeLfoOsc == 1 or activeLfoOsc == 3 then
          synthModulators.lfo2:setParameter("Freq", self.value)
        end
        if activeLfoOsc == 1 or activeLfoOsc == 4 then
          synthModulators.lfo3:setParameter("Freq", self.value)
        end
        self.displayText = string.format("%0.2f Hz", self.value)
      end
      lfoFreqKnob:setValue(lfoFreqKnob.default)
    else
      -- Uses beat ratio when synced: 4 is 1/1, 0.25 is 1/16
      lfoFreqKnob:setRange(1, #resolutions.getResolutions())
      lfoFreqKnob.default = 20
      lfoFreqKnob.mapper = Mapper.Linear
      lfoFreqKnob.changed = function(self)
        --print("Sync on, value in", self.value)
        local index = math.floor(self.value)
        --print("Sync on, resolution index", index)
        local resolution = resolutions.getResolution(index)
        --print("Sync on, resolution", resolution)
        if activeLfoOsc == 1 or activeLfoOsc == 2 then
          synthModulators.lfo1:setParameter("Freq", resolution)
        end
        if activeLfoOsc == 1 or activeLfoOsc == 3 then
          synthModulators.lfo2:setParameter("Freq", resolution)
        end
        if activeLfoOsc == 1 or activeLfoOsc == 4 then
          synthModulators.lfo3:setParameter("Freq", resolution)
        end
        self.displayText = resolutions.getResolutionName(index)
      end
      lfoFreqKnob:setValue(lfoFreqKnob.default)
    end
  end
  lfo2SyncButton:changed()
  table.insert(tweakables, {widget=lfo2SyncButton,func=getRandomBoolean,excludeWhenTweaking=true,category="modulation"})
  table.insert(tweakables, {widget=lfoFreqKnob,floor=0.1,ceiling=9.5,probability=25,useDuration=true,category="modulation"})

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
      synthModulators.lfo1:setParameter("Retrigger", mode)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      synthModulators.lfo2:setParameter("Retrigger", mode)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      synthModulators.lfo3:setParameter("Retrigger", mode)
    end
  end
  lfo2TriggerButton:changed()
  table.insert(tweakables, {widget=lfo2TriggerButton,func=getRandomBoolean,category="modulation"})

  local lfoFreqKeyFollowKnob = lfoPanel:Knob("LfoFreqKeyFollow", 0, 0, 1)
  lfoFreqKeyFollowKnob.unit = Unit.PercentNormalized
  lfoFreqKeyFollowKnob.displayName = "Key Track"
  lfoFreqKeyFollowKnob.fillColour = knobColour
  lfoFreqKeyFollowKnob.outlineColour = lfoColour
  lfoFreqKeyFollowKnob.changed = function(self)
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      commonMacros.lfoFreqKeyFollow1:setParameter("Value", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      commonMacros.lfoFreqKeyFollow2:setParameter("Value", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      commonMacros.lfoFreqKeyFollow3:setParameter("Value", self.value)
    end
  end
  lfoFreqKeyFollowKnob:changed()
  table.insert(tweakables, {widget=lfoFreqKeyFollowKnob,ceiling=0.5,probability=50,default=15,zero=75,excludeWhenTweaking=true,category="modulation"})

  local lfoDelayKnob = lfoPanel:Knob("LfoDelay", 0, 0, 10)
  lfoDelayKnob.displayName="Delay"
  lfoDelayKnob.fillColour = knobColour
  lfoDelayKnob.outlineColour = lfoColour
  lfoDelayKnob.mapper = Mapper.Quartic
  lfoDelayKnob.x = waveFormTypeMenu.x
  lfoDelayKnob.y = 70
  lfoDelayKnob.changed = function(self)
    if activeLfoOsc == 1 or activeLfoOsc == 2 then
      synthModulators.lfo1:setParameter("DelayTime", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      synthModulators.lfo2:setParameter("DelayTime", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      synthModulators.lfo3:setParameter("DelayTime", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
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
      synthModulators.lfo1:setParameter("RiseTime", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      synthModulators.lfo2:setParameter("RiseTime", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      synthModulators.lfo3:setParameter("RiseTime", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
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
      synthModulators.lfo1:setParameter("Smooth", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      synthModulators.lfo2:setParameter("Smooth", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      synthModulators.lfo3:setParameter("Smooth", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
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
      synthModulators.lfo1:setParameter("Bipolar", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 3 then
      synthModulators.lfo2:setParameter("Bipolar", self.value)
    end
    if activeLfoOsc == 1 or activeLfoOsc == 4 then
      synthModulators.lfo3:setParameter("Bipolar", self.value)
    end
  end
  lfoBipolarButton:changed()
  table.insert(tweakables, {widget=lfoBipolarButton,func=getRandomBoolean,probability=75,category="modulation"})

  function setLfoWidgetValue(widget, param, params)
    if activeLfoOsc == 1 then
      widget.enabled = helpers.isEqual(params[1]:getParameter(param), params[2]:getParameter(param)) and helpers.isEqual(params[2]:getParameter(param), params[3]:getParameter(param))
      return
    end
    local lfoIndex = activeLfoOsc - 1
    local value
    value = params[lfoIndex]:getParameter(param)
    --[[ if activeLfoOsc == 2 then
      value = params[1]:getParameter(param)
    elseif activeLfoOsc == 3 then
      value = params[2]:getParameter(param)
    elseif activeLfoOsc == 4 then
      value = params[3]:getParameter(param)
    end ]]
    if param == "WaveFormType" then
      value = value + 1
    elseif param == "Retrigger" then
      value = value == 1
    elseif param == "Freq" then
      if params[lfoIndex]:getParameter("SyncToHost") == true then
        value = helpers.getSyncedValue(value)
      end
      --[[ if activeLfoOsc == 2 and params[1]:getParameter("SyncToHost") == true then
        value = helpers.getSyncedValue(value)
      elseif activeLfoOsc == 3 and params[2]:getParameter("SyncToHost") == true then
        value = helpers.getSyncedValue(value)
      elseif activeLfoOsc == 4 and params[3]:getParameter("SyncToHost") == true then
        value = helpers.getSyncedValue(value)
      end ]]
    end
    widget:setValue(value)
    print("setLfoWidgetValue:setValue:", param, value)
    widget.enabled = true
  end

  if type(lfoMenu) ~= "nil" then
    lfoMenu.changed = function(self)
      -- STORE THE ACTIVE OSCILLATOR
      activeLfoOsc = self.value -- 1 = all oscillators
      --print("LFO - Active oscillator changed:", activeLfoOsc, self.selectedText)
      -- SET LFO WIDGET VALUES PER OSCILLATOR
      local params = {synthModulators.lfo1, synthModulators.lfo2, synthModulators.lfo3}
      setLfoWidgetValue(waveFormTypeMenu, "WaveFormType", params)
      setLfoWidgetValue(lfoDelayKnob, "DelayTime", params)
      setLfoWidgetValue(lfoRiseKnob, "RiseTime", params)
      setLfoWidgetValue(lfo2SyncButton, "SyncToHost", params)
      setLfoWidgetValue(lfo2TriggerButton, "Retrigger", params)
      setLfoWidgetValue(lfoFreqKnob, "Freq", params)
      setLfoWidgetValue(lfoBipolarButton, "Bipolar", params)
      setLfoWidgetValue(lfoSmoothKnob, "Smooth", params)
      setLfoWidgetValue(lfoFreqKeyFollowKnob, "Value", {commonMacros.lfoFreqKeyFollow1, commonMacros.lfoFreqKeyFollow2, commonMacros.lfoFreqKeyFollow3})
    end
    lfoMenu:changed()
  end

  return lfoPanel
end

local lfoPanel = panelCreators.createLfoPanel()

--------------------------------------------------------------------------------
-- LFO Targets
--------------------------------------------------------------------------------

panelCreators.createLfoTargetPanel = function()
  local lfoNoiseOscOverride = false
  local activeLfoTargetOsc = 1
  local lfoTargetPanel = Panel("LfoTargetPanel")
  
  local lfoTargetOscMenu
  if synthTypes.isAnalog3Osc == true then
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
  lfoToCutoffKnob.unit = Unit.PercentNormalized
  lfoToCutoffKnob.displayName = "LP-Filter"
  lfoToCutoffKnob.fillColour = knobColour
  lfoToCutoffKnob.outlineColour = lfoColour
  lfoToCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.lfoToCutoff:setParameter("Value", value)
    if lfoNoiseOscOverride == false then
      commonMacros.lfoToNoiseLpf:setParameter("Value", value)
    end
  end
  lfoToCutoffKnob:changed()
  table.insert(tweakables, {widget=lfoToCutoffKnob,bipolar=25,default=30,floor=0.01,ceiling=0.35,probability=50,useDuration=true,category="modulation"})

  local lfoToHpfCutoffKnob = lfoTargetPanel:Knob("LfoToHpfCutoff", 0, -1, 1)
  lfoToHpfCutoffKnob.unit = Unit.PercentNormalized
  lfoToHpfCutoffKnob.displayName = "HP-Filter"
  lfoToHpfCutoffKnob.fillColour = knobColour
  lfoToHpfCutoffKnob.outlineColour = lfoColour
  lfoToHpfCutoffKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.lfoToHpf:setParameter("Value", value)
    if lfoNoiseOscOverride == false then
      commonMacros.lfoToNoiseHpf:setParameter("Value", value)
    end
  end
  lfoToHpfCutoffKnob:changed()
  table.insert(tweakables, {widget=lfoToHpfCutoffKnob,bipolar=25,default=50,floor=0.1,ceiling=0.3,probability=50,useDuration=true,category="modulation"})

  local lfoToAmpKnob = lfoTargetPanel:Knob("LfoToAmplitude", 0, -1, 1)
  lfoToAmpKnob.unit = Unit.PercentNormalized
  lfoToAmpKnob.displayName = "Amplitude"
  lfoToAmpKnob.fillColour = knobColour
  lfoToAmpKnob.outlineColour = lfoColour
  lfoToAmpKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    commonMacros.lfoToAmp:setParameter("Value", value)
    if lfoNoiseOscOverride == false then
      commonMacros.lfoToNoiseAmp:setParameter("Value", value)
    end
  end
  lfoToAmpKnob:changed()
  table.insert(tweakables, {widget=lfoToAmpKnob,bipolar=25,default=60,floor=0.3,ceiling=0.8,probability=50,useDuration=true,category="modulation"})

  local lfoToDetuneKnob = lfoTargetPanel:Knob("LfoToFilterEnvDecay", 0, 0, 1)
  lfoToDetuneKnob.unit = Unit.PercentNormalized
  lfoToDetuneKnob.displayName = "FDecay"
  lfoToDetuneKnob.tooltip = "LFO to filter envelope decay"
  lfoToDetuneKnob.fillColour = knobColour
  lfoToDetuneKnob.outlineColour = lfoColour
  lfoToDetuneKnob.changed = function(self)
    commonMacros.lfoToDetune:setParameter("Value", self.value)
  end
  lfoToDetuneKnob:changed()
  table.insert(tweakables, {widget=lfoToDetuneKnob,default=50,ceiling=0.25,probability=30,useDuration=true,category="modulation"})

  local wheelToLfoKnob = lfoTargetPanel:Knob("WheelToLfo", 0, 0, 1)
  wheelToLfoKnob.unit = Unit.PercentNormalized
  wheelToLfoKnob.displayName = "Via Wheel"
  wheelToLfoKnob.fillColour = knobColour
  wheelToLfoKnob.outlineColour = lfoColour
  wheelToLfoKnob.changed = function(self)
    commonMacros.wheelToLfo:setParameter("Value", self.value)
  end
  wheelToLfoKnob:changed()
  table.insert(tweakables, {widget=wheelToLfoKnob,default=75,floor=0.5,ceiling=1.0,probability=50,excludeWhenTweaking=true,category="modulation"})

  ------- NOISE OSC ----------

  if lfoTargetOscMenu then
    local lfoToNoiseLpfCutoffKnob = lfoTargetPanel:Knob("LfoToNoiseLpfCutoff", 0, -1, 1)
    lfoToNoiseLpfCutoffKnob.unit = Unit.PercentNormalized
    lfoToNoiseLpfCutoffKnob.displayName = "LP-Filter"
    lfoToNoiseLpfCutoffKnob.x = lfoToCutoffKnob.x
    lfoToNoiseLpfCutoffKnob.y = lfoToCutoffKnob.y
    lfoToNoiseLpfCutoffKnob.fillColour = knobColour
    lfoToNoiseLpfCutoffKnob.outlineColour = lfoColour
    lfoToNoiseLpfCutoffKnob.changed = function(self)
      local value = (self.value + 1) * 0.5
      commonMacros.lfoToNoiseLpf:setParameter("Value", value)
    end

    local lfoToNoiseHpfCutoffKnob = lfoTargetPanel:Knob("LfoToNoiseHpfCutoff", 0, -1, 1)
    lfoToNoiseHpfCutoffKnob.unit = Unit.PercentNormalized
    lfoToNoiseHpfCutoffKnob.displayName = "HP-Filter"
    lfoToNoiseHpfCutoffKnob.x = lfoToHpfCutoffKnob.x
    lfoToNoiseHpfCutoffKnob.y = lfoToHpfCutoffKnob.y
    lfoToNoiseHpfCutoffKnob.fillColour = knobColour
    lfoToNoiseHpfCutoffKnob.outlineColour = lfoColour
    lfoToNoiseHpfCutoffKnob.changed = function(self)
      local value = (self.value + 1) * 0.5
      commonMacros.lfoToNoiseHpf:setParameter("Value", value)
    end

    local lfoToNoiseAmpKnob = lfoTargetPanel:Knob("LfoToNoiseAmplitude", 0, -1, 1)
    lfoToNoiseAmpKnob.unit = Unit.PercentNormalized
    lfoToNoiseAmpKnob.displayName = "Amplitude"
    lfoToNoiseAmpKnob.x = lfoToAmpKnob.x
    lfoToNoiseAmpKnob.y = lfoToAmpKnob.y
    lfoToNoiseAmpKnob.fillColour = knobColour
    lfoToNoiseAmpKnob.outlineColour = lfoColour
    lfoToNoiseAmpKnob.changed = function(self)
      local value = (self.value + 1) * 0.5
      commonMacros.lfoToNoiseAmp:setParameter("Value", value)
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
        commonMacros.lfoToNoiseLpf:setParameter("Value", commonMacros.lfoToCutoff:getParameter("Value"))
        commonMacros.lfoToNoiseHpf:setParameter("Value", commonMacros.lfoToHpf:getParameter("Value"))
        commonMacros.lfoToNoiseAmp:setParameter("Value", commonMacros.lfoToAmp:getParameter("Value"))
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

local lfoTargetPanel = panelCreators.createLfoTargetPanel()

--------------------------------------------------------------------------------
-- LFO Targets Osc 1
--------------------------------------------------------------------------------

panelCreators.createLfoTargetPanel1 = function()
  local lfoTargetPanel1 = Panel("LfoTargetPanel1")

  if synthTypes.isAnalog3Osc then
    lfoTargetPanel1:Label("LFO -> Osc ->")

    local osc1LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOscPWM1", 0, 0, 0.5)
    osc1LfoToPWMKnob.unit = Unit.PercentNormalized
    osc1LfoToPWMKnob.displayName = "PWM 1"
    osc1LfoToPWMKnob.mapper = Mapper.Quadratic
    osc1LfoToPWMKnob.fillColour = knobColour
    osc1LfoToPWMKnob.outlineColour = lfoColour
    osc1LfoToPWMKnob.changed = function(self)
      commonMacros.osc1LfoToPWM:setParameter("Value", self.value)
    end
    osc1LfoToPWMKnob:changed()
    table.insert(tweakables, {widget=osc1LfoToPWMKnob,ceiling=0.25,probability=90,default=60,useDuration=true,category="modulation"})

    local osc2LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOscPWM2", 0, 0, 0.5)
    osc2LfoToPWMKnob.unit = Unit.PercentNormalized
    osc2LfoToPWMKnob.displayName = "PWM 2"
    osc2LfoToPWMKnob.mapper = Mapper.Quadratic
    osc2LfoToPWMKnob.fillColour = knobColour
    osc2LfoToPWMKnob.outlineColour = lfoColour
    osc2LfoToPWMKnob.changed = function(self)
      commonMacros.osc2LfoToPWM:setParameter("Value", self.value)
    end
    osc2LfoToPWMKnob:changed()
    table.insert(tweakables, {widget=osc2LfoToPWMKnob,ceiling=0.25,probability=90,default=60,useDuration=true,category="modulation"})

    local osc3LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOsc3PWM", 0, 0, 0.5)
    osc3LfoToPWMKnob.unit = Unit.PercentNormalized
    osc3LfoToPWMKnob.displayName = "PWM 3"
    osc3LfoToPWMKnob.mapper = Mapper.Quadratic
    osc3LfoToPWMKnob.fillColour = knobColour
    osc3LfoToPWMKnob.outlineColour = lfoColour
    osc3LfoToPWMKnob.changed = function(self)
      analogMacros["osc3LfoToPWM"]:setParameter("Value", self.value)
    end
    osc3LfoToPWMKnob:changed()
    table.insert(tweakables, {widget=osc3LfoToPWMKnob,ceiling=0.25,probability=90,default=60,useDuration=true,category="modulation"})
  else
    lfoTargetPanel1:Label("LFO -> Osc 1 ->")

    if synthTypes.isAnalog or synthTypes.isAdditive or synthTypes.isWavetable or synthTypes.isAnalogStack then
      local osc1LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOscPWM1", 0, 0, 0.5)
      osc1LfoToPWMKnob.unit = Unit.PercentNormalized
      osc1LfoToPWMKnob.displayName = "PWM"
      osc1LfoToPWMKnob.mapper = Mapper.Quadratic
      osc1LfoToPWMKnob.fillColour = knobColour
      osc1LfoToPWMKnob.outlineColour = lfoColour
      osc1LfoToPWMKnob.changed = function(self)
        commonMacros.osc1LfoToPWM:setParameter("Value", self.value)
      end
      osc1LfoToPWMKnob:changed()
      table.insert(tweakables, {widget=osc1LfoToPWMKnob,ceiling=0.25,probability=90,default=50,useDuration=true,category="modulation"})
    end

    if synthTypes.isAnalog then
      local lfoToHardsync1Knob = lfoTargetPanel1:Knob("LfoToHardsync1", 0, 0, 1)
      lfoToHardsync1Knob.unit = Unit.PercentNormalized
      lfoToHardsync1Knob.displayName = "Hardsync"
      lfoToHardsync1Knob.fillColour = knobColour
      lfoToHardsync1Knob.outlineColour = lfoColour
      lfoToHardsync1Knob.changed = function(self)
        analogMacros["lfoToHardsync1"]:setParameter("Value", self.value)
      end
      lfoToHardsync1Knob:changed()
      table.insert(tweakables, {widget=lfoToHardsync1Knob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,useDuration=true,category="modulation"})
    elseif synthTypes.isAdditive then
      local lfoToEvenOdd1Knob = lfoTargetPanel1:Knob("LfoToEvenOdd1", 0, 0, 1)
      lfoToEvenOdd1Knob.unit = Unit.PercentNormalized
      lfoToEvenOdd1Knob.displayName = "Even/Odd"
      lfoToEvenOdd1Knob.fillColour = knobColour
      lfoToEvenOdd1Knob.outlineColour = lfoColour
      lfoToEvenOdd1Knob.changed = function(self)
        additiveMacros["lfoToEvenOdd1"]:setParameter("Value", self.value)
      end
      lfoToEvenOdd1Knob:changed()
      table.insert(tweakables, {widget=lfoToEvenOdd1Knob,zero=50,default=70,floor=0.3,ceiling=0.9,probability=20,category="modulation"})

      local lfoToCutoffKnob = lfoTargetPanel1:Knob("LfoToOsc1Cutoff", 0, -1, 1)
      lfoToCutoffKnob.unit = Unit.PercentNormalized
      lfoToCutoffKnob.displayName = "Cutoff"
      lfoToCutoffKnob.fillColour = knobColour
      lfoToCutoffKnob.outlineColour = lfoColour
      lfoToCutoffKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["lfoToOsc1Cutoff"]:setParameter("Value", value)
      end
      lfoToCutoffKnob:changed()
      table.insert(tweakables, {widget=lfoToCutoffKnob,bipolar=25,default=30,floor=0.1,ceiling=0.5,probability=20,useDuration=true,category="modulation"})
    elseif synthTypes.isDrum then
      local lfoToOsc1ModDepthKnob = lfoTargetPanel1:Knob("LfoToOsc1ModDepth", 0, -1, 1)
      lfoToOsc1ModDepthKnob.unit = Unit.PercentNormalized
      lfoToOsc1ModDepthKnob.displayName = "Mod Depth"
      lfoToOsc1ModDepthKnob.fillColour = knobColour
      lfoToOsc1ModDepthKnob.outlineColour = lfoColour
      lfoToOsc1ModDepthKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["lfoToOsc1ModDepth"]:setParameter("Value", value)
      end
      lfoToOsc1ModDepthKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1ModDepthKnob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,biploar=15,useDuration=true,category="modulation"})

      local lfoToNoise1MixKnob = lfoTargetPanel1:Knob("LfoToNoiseMix1", 0, -1, 1)
      lfoToNoise1MixKnob.unit = Unit.PercentNormalized
      lfoToNoise1MixKnob.displayName = "Noise Mix"
      lfoToNoise1MixKnob.fillColour = knobColour
      lfoToNoise1MixKnob.outlineColour = lfoColour
      lfoToNoise1MixKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["lfoToNoise1Mix"]:setParameter("Value", value)
      end
      lfoToNoise1MixKnob:changed()
      table.insert(tweakables, {widget=lfoToNoise1MixKnob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,bipolar=15,useDuration=true,category="modulation"})

      local lfoToNoise1CutoffKnob = lfoTargetPanel1:Knob("LfoToNoise1Cutoff", 0, -1, 1)
      lfoToNoise1CutoffKnob.unit = Unit.PercentNormalized
      lfoToNoise1CutoffKnob.displayName = "Noise Cutoff"
      lfoToNoise1CutoffKnob.fillColour = knobColour
      lfoToNoise1CutoffKnob.outlineColour = lfoColour
      lfoToNoise1CutoffKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["lfoToNoise1Cutoff"]:setParameter("Value", value)
      end
      lfoToNoise1CutoffKnob:changed()
      table.insert(tweakables, {widget=lfoToNoise1CutoffKnob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,bipolar=15,useDuration=true,category="modulation"})

      local lfoToOsc1FreqKnob = lfoTargetPanel1:Knob("LfoToOscFreq1", 0, -1, 1)
      lfoToOsc1FreqKnob.unit = Unit.PercentNormalized
      lfoToOsc1FreqKnob.displayName = "Frequency"
      lfoToOsc1FreqKnob.fillColour = knobColour
      lfoToOsc1FreqKnob.outlineColour = lfoColour
      lfoToOsc1FreqKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["lfoToOsc1Freq"]:setParameter("Value", value)
      end
      lfoToOsc1FreqKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1FreqKnob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,bipolar=15,useDuration=true,category="modulation"})

      local lfoToDistortion1Knob = lfoTargetPanel1:Knob("LfoToDistortion1", 0, 0, 1)
      lfoToDistortion1Knob.unit = Unit.PercentNormalized
      lfoToDistortion1Knob.displayName = "Distortion"
      lfoToDistortion1Knob.fillColour = knobColour
      lfoToDistortion1Knob.outlineColour = lfoColour
      lfoToDistortion1Knob.changed = function(self)
        drumMacros["lfoToDistortion1"]:setParameter("Value", self.value)
      end
      lfoToDistortion1Knob:changed()
      table.insert(tweakables, {widget=lfoToDistortion1Knob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,useDuration=true,category="modulation"})
    elseif synthTypes.isWavetable then
      local lfoToWT1Knob = lfoTargetPanel1:Knob("LfoToWaveIndex1", 0, -1, 1)
      lfoToWT1Knob.unit = Unit.PercentNormalized
      lfoToWT1Knob.displayName = "Waveindex"
      lfoToWT1Knob.fillColour = knobColour
      lfoToWT1Knob.outlineColour = lfoColour
      lfoToWT1Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["lfoToWT1"]:setParameter("Value", value)
      end
      lfoToWT1Knob:changed()
      table.insert(tweakables, {widget=lfoToWT1Knob,bipolar=25,default=25,floor=0.3,ceiling=0.9,probability=20,useDuration=true,category="modulation"})

      local lfoToWaveSpread1Knob = lfoTargetPanel1:Knob("LfoToWaveSpreadOsc1", 0, -1, 1)
      lfoToWaveSpread1Knob.unit = Unit.PercentNormalized
      lfoToWaveSpread1Knob.displayName = "WaveSpread"
      lfoToWaveSpread1Knob.fillColour = knobColour
      lfoToWaveSpread1Knob.outlineColour = lfoColour
      lfoToWaveSpread1Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["lfoToWaveSpread1"]:setParameter("Value", value)
      end
      lfoToWaveSpread1Knob:changed()
      table.insert(tweakables, {widget=lfoToWaveSpread1Knob,bipolar=80,default=50,ceiling=0.4,probability=30,useDuration=true,category="modulation"})
    elseif synthTypes.isFM then
      local lfoToOsc1OpBLevelKnob = lfoTargetPanel1:Knob("LfoToOsc1OpBLevel", 0, 0, 1)
      lfoToOsc1OpBLevelKnob.unit = Unit.PercentNormalized
      lfoToOsc1OpBLevelKnob.displayName = "Op B Level"
      lfoToOsc1OpBLevelKnob.fillColour = knobColour
      lfoToOsc1OpBLevelKnob.outlineColour = lfoColour
      lfoToOsc1OpBLevelKnob.changed = function(self)
        FMMacros["lfoToOsc1OpBLevel"]:setParameter("Value", self.value)
      end
      lfoToOsc1OpBLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1OpBLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc1OpCLevelKnob = lfoTargetPanel1:Knob("LfoToOsc1OpCLevel", 0, 0, 1)
      lfoToOsc1OpCLevelKnob.unit = Unit.PercentNormalized
      lfoToOsc1OpCLevelKnob.displayName = "Op C Level"
      lfoToOsc1OpCLevelKnob.fillColour = knobColour
      lfoToOsc1OpCLevelKnob.outlineColour = lfoColour
      lfoToOsc1OpCLevelKnob.changed = function(self)
        FMMacros["lfoToOsc1OpCLevel"]:setParameter("Value", self.value)
      end
      lfoToOsc1OpCLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1OpCLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc1OpDLevelKnob = lfoTargetPanel1:Knob("LfoToOsc1OpDLevel", 0, 0, 1)
      lfoToOsc1OpDLevelKnob.unit = Unit.PercentNormalized
      lfoToOsc1OpDLevelKnob.displayName = "Op D Level"
      lfoToOsc1OpDLevelKnob.fillColour = knobColour
      lfoToOsc1OpDLevelKnob.outlineColour = lfoColour
      lfoToOsc1OpDLevelKnob.changed = function(self)
        FMMacros["lfoToOsc1OpDLevel"]:setParameter("Value", self.value)
      end
      lfoToOsc1OpDLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1OpDLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc1FeedbackKnob = lfoTargetPanel1:Knob("LfoToOsc1Feedback", 0, 0, 1)
      lfoToOsc1FeedbackKnob.unit = Unit.PercentNormalized
      lfoToOsc1FeedbackKnob.displayName = "Feedback"
      lfoToOsc1FeedbackKnob.fillColour = knobColour
      lfoToOsc1FeedbackKnob.outlineColour = lfoColour
      lfoToOsc1FeedbackKnob.changed = function(self)
        FMMacros["lfoToOsc1Feedback"]:setParameter("Value", self.value)
      end
      lfoToOsc1FeedbackKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc1FeedbackKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})
    end

    if synthTypes.isAnalog or synthTypes.isAdditive or synthTypes.isWavetable or synthTypes.isFM then
      local lfoToPitchOsc1Knob = lfoTargetPanel1:Knob("LfoToPitchOsc1", 0, 0, 48)
      lfoToPitchOsc1Knob.displayName = "Pitch"
      lfoToPitchOsc1Knob.mapper = Mapper.Quadratic
      lfoToPitchOsc1Knob.fillColour = knobColour
      lfoToPitchOsc1Knob.outlineColour = lfoColour
      lfoToPitchOsc1Knob.changed = function(self)
        local factor = 1 / 48
        local value = (self.value * factor)
        commonMacros.lfoToPitchOsc1:setParameter("Value", value)
      end
      lfoToPitchOsc1Knob:changed()
      table.insert(tweakables, {widget=lfoToPitchOsc1Knob,ceiling=0.1,probability=75,default=75,zero=50,useDuration=true,category="modulation"})
    end
  end

  return lfoTargetPanel1
end

local lfoTargetPanel1 = panelCreators.createLfoTargetPanel1()

--------------------------------------------------------------------------------
-- LFO Targets Osc 2
--------------------------------------------------------------------------------

panelCreators.createLfoTargetPanel2 = function()
  local lfoTargetPanel2 = Panel("LfoTargetPanel2")

  if synthTypes.isAnalog3Osc then
    lfoTargetPanel2:Label("LFO -> Osc ->")

    local lfoToPitchOsc1Knob = lfoTargetPanel2:Knob("LfoToPitchOsc1", 0, 0, 48)
    lfoToPitchOsc1Knob.displayName = "Pitch 1"
    lfoToPitchOsc1Knob.mapper = Mapper.Quadratic
    lfoToPitchOsc1Knob.fillColour = knobColour
    lfoToPitchOsc1Knob.outlineColour = lfoColour
    lfoToPitchOsc1Knob.changed = function(self)
      local factor = 1 / 48
      local value = (self.value * factor)
      commonMacros.lfoToPitchOsc1:setParameter("Value", value)
    end
    lfoToPitchOsc1Knob:changed()
    table.insert(tweakables, {widget=lfoToPitchOsc1Knob,ceiling=0.1,probability=80,default=80,zero=50,useDuration=true,category="modulation"})

    -- TODO Validate pitch modulation - if hard sync is enabled, ceiling can be higher
    local lfoToPitchOsc2Knob = lfoTargetPanel2:Knob("LfoToPitchOsc2", 0, 0, 48)
    lfoToPitchOsc2Knob.displayName = "Pitch 2"
    lfoToPitchOsc2Knob.mapper = Mapper.Quadratic
    lfoToPitchOsc2Knob.fillColour = knobColour
    lfoToPitchOsc2Knob.outlineColour = lfoColour
    lfoToPitchOsc2Knob.changed = function(self)
      local factor = 1 / 48
      local value = (self.value * factor)
      commonMacros.lfoToPitchOsc2:setParameter("Value", value)
    end
    lfoToPitchOsc2Knob:changed()
    table.insert(tweakables, {widget=lfoToPitchOsc2Knob,ceiling=0.1,probability=75,default=80,zero=30,useDuration=true,category="modulation"})

    -- TODO Validate pitch modulation - if hard sync is enabled, ceiling can be higher
    local lfoToPitchOsc3Knob = lfoTargetPanel2:Knob("LfoToPitchOsc3", 0, 0, 48)
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

    if synthTypes.isAnalog or synthTypes.isAdditive or synthTypes.isWavetable or synthTypes.isAnalogStack then
      local osc2LfoToPWMKnob = lfoTargetPanel2:Knob("LfoToOscPWM2", 0, 0, 0.5)
      osc2LfoToPWMKnob.unit = Unit.PercentNormalized
      osc2LfoToPWMKnob.displayName = "PWM"
      osc2LfoToPWMKnob.mapper = Mapper.Quadratic
      osc2LfoToPWMKnob.fillColour = knobColour
      osc2LfoToPWMKnob.outlineColour = lfoColour
      osc2LfoToPWMKnob.changed = function(self)
        commonMacros.osc2LfoToPWM:setParameter("Value", self.value)
      end
      osc2LfoToPWMKnob:changed()
      table.insert(tweakables, {widget=osc2LfoToPWMKnob,ceiling=0.25,probability=90,default=50,useDuration=true,category="modulation"})
    end

    if synthTypes.isAnalog then
      local lfoToHardsync2Knob = lfoTargetPanel2:Knob("LfoToHardsync2", 0, 0, 1)
      lfoToHardsync2Knob.unit = Unit.PercentNormalized
      lfoToHardsync2Knob.displayName = "Hardsync"
      lfoToHardsync2Knob.fillColour = knobColour
      lfoToHardsync2Knob.outlineColour = lfoColour
      lfoToHardsync2Knob.changed = function(self)
        analogMacros["lfoToHardsync2"]:setParameter("Value", self.value)
      end
      lfoToHardsync2Knob:changed()
      table.insert(tweakables, {widget=lfoToHardsync2Knob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=20,useDuration=true,category="modulation"})
    elseif synthTypes.isDrum then
      local lfoToOsc2ModDepthKnob = lfoTargetPanel2:Knob("LfoToOsc2ModDepth", 0, -1, 1)
      lfoToOsc2ModDepthKnob.unit = Unit.PercentNormalized
      lfoToOsc2ModDepthKnob.displayName = "Mod Depth"
      lfoToOsc2ModDepthKnob.fillColour = knobColour
      lfoToOsc2ModDepthKnob.outlineColour = lfoColour
      lfoToOsc2ModDepthKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["lfoToOsc2ModDepth"]:setParameter("Value", value)
      end
      lfoToOsc2ModDepthKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2ModDepthKnob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,biploar=15,useDuration=true,category="modulation"})

      local lfoToNoise2MixKnob = lfoTargetPanel2:Knob("LfoToNoiseMix2", 0, -1, 1)
      lfoToNoise2MixKnob.unit = Unit.PercentNormalized
      lfoToNoise2MixKnob.displayName = "Noise Mix"
      lfoToNoise2MixKnob.fillColour = knobColour
      lfoToNoise2MixKnob.outlineColour = lfoColour
      lfoToNoise2MixKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["lfoToNoise2Mix"]:setParameter("Value", value)
      end
      lfoToNoise2MixKnob:changed()
      table.insert(tweakables, {widget=lfoToNoise2MixKnob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,biploar=15,useDuration=true,category="modulation"})

      local lfoToNoise2CutoffKnob = lfoTargetPanel2:Knob("LfoToNoise2Cutoff", 0, -1, 1)
      lfoToNoise2CutoffKnob.unit = Unit.PercentNormalized
      lfoToNoise2CutoffKnob.displayName = "Noise Cutoff"
      lfoToNoise2CutoffKnob.fillColour = knobColour
      lfoToNoise2CutoffKnob.outlineColour = lfoColour
      lfoToNoise2CutoffKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["lfoToNoise2Cutoff"]:setParameter("Value", value)
      end
      lfoToNoise2CutoffKnob:changed()
      table.insert(tweakables, {widget=lfoToNoise2CutoffKnob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,bipolar=15,useDuration=true,category="modulation"})

      local lfoToOsc2FreqKnob = lfoTargetPanel2:Knob("LfoToOscFreq2", 0, -1, 1)
      lfoToOsc2FreqKnob.unit = Unit.PercentNormalized
      lfoToOsc2FreqKnob.displayName = "Frequency"
      lfoToOsc2FreqKnob.fillColour = knobColour
      lfoToOsc2FreqKnob.outlineColour = lfoColour
      lfoToOsc2FreqKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        drumMacros["lfoToOsc2Freq"]:setParameter("Value", value)
      end
      lfoToOsc2FreqKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2FreqKnob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,bipolar=15,useDuration=true,category="modulation"})

      local lfoToDistortion2Knob = lfoTargetPanel2:Knob("LfoToDistortion2", 0, 0, 1)
      lfoToDistortion2Knob.unit = Unit.PercentNormalized
      lfoToDistortion2Knob.displayName = "Distortion"
      lfoToDistortion2Knob.fillColour = knobColour
      lfoToDistortion2Knob.outlineColour = lfoColour
      lfoToDistortion2Knob.changed = function(self)
        drumMacros["lfoToDistortion2"]:setParameter("Value", self.value)
      end
      lfoToDistortion2Knob:changed()
      table.insert(tweakables, {widget=lfoToDistortion2Knob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=80,useDuration=true,category="modulation"})
    elseif synthTypes.isAdditive then
      local lfoToEvenOdd2Knob = lfoTargetPanel2:Knob("LfoToEvenOdd2", 0, 0, 1)
      lfoToEvenOdd2Knob.unit = Unit.PercentNormalized
      lfoToEvenOdd2Knob.displayName = "Even/Odd"
      lfoToEvenOdd2Knob.fillColour = knobColour
      lfoToEvenOdd2Knob.outlineColour = lfoColour
      lfoToEvenOdd2Knob.changed = function(self)
        additiveMacros["lfoToEvenOdd2"]:setParameter("Value", self.value)
      end
      lfoToEvenOdd2Knob:changed()
      table.insert(tweakables, {widget=lfoToEvenOdd2Knob,zero=50,default=70,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToCutoffKnob = lfoTargetPanel2:Knob("LfoToOsc2Cutoff", 0, -1, 1)
      lfoToCutoffKnob.unit = Unit.PercentNormalized
      lfoToCutoffKnob.displayName = "Cutoff"
      lfoToCutoffKnob.fillColour = knobColour
      lfoToCutoffKnob.outlineColour = lfoColour
      lfoToCutoffKnob.changed = function(self)
        local value = (self.value + 1) * 0.5
        additiveMacros["lfoToOsc2Cutoff"]:setParameter("Value", value)
      end
      lfoToCutoffKnob:changed()
      table.insert(tweakables, {widget=lfoToCutoffKnob,bipolar=25,default=30,floor=0.1,ceiling=0.6,probability=20,useDuration=true,category="modulation"})
    elseif synthTypes.isWavetable then
      local lfoToWT2Knob = lfoTargetPanel2:Knob("LfoToWaveIndex2", 0, -1, 1)
      lfoToWT2Knob.unit = Unit.PercentNormalized
      lfoToWT2Knob.displayName = "Waveindex"
      lfoToWT2Knob.fillColour = knobColour
      lfoToWT2Knob.outlineColour = lfoColour
      lfoToWT2Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["lfoToWT2"]:setParameter("Value", value)
      end
      lfoToWT2Knob:changed()
      table.insert(tweakables, {widget=lfoToWT2Knob,bipolar=25,default=25,floor=0.1,ceiling=0.9,probability=30,useDuration=true,category="modulation"})

      local lfoToWaveSpread2Knob = lfoTargetPanel2:Knob("LfoToWaveSpreadOsc2", 0, -1, 1)
      lfoToWaveSpread2Knob.unit = Unit.PercentNormalized
      lfoToWaveSpread2Knob.displayName = "WaveSpread"
      lfoToWaveSpread2Knob.fillColour = knobColour
      lfoToWaveSpread2Knob.outlineColour = lfoColour
      lfoToWaveSpread2Knob.changed = function(self)
        local value = (self.value + 1) * 0.5
        wavetableMacros["lfoToWaveSpread2"]:setParameter("Value", value)
      end
      lfoToWaveSpread2Knob:changed()
      table.insert(tweakables, {widget=lfoToWaveSpread2Knob,bipolar=80,default=50,floor=0.3,ceiling=0.7,probability=25,useDuration=true,category="modulation"})
    elseif synthTypes.isFM then
      local lfoToOsc2OpBLevelKnob = lfoTargetPanel2:Knob("LfoToOsc2OpBLevel", 0, 0, 1)
      lfoToOsc2OpBLevelKnob.unit = Unit.PercentNormalized
      lfoToOsc2OpBLevelKnob.displayName = "Op B Level"
      lfoToOsc2OpBLevelKnob.fillColour = knobColour
      lfoToOsc2OpBLevelKnob.outlineColour = lfoColour
      lfoToOsc2OpBLevelKnob.changed = function(self)
        FMMacros["lfoToOsc2OpBLevel"]:setParameter("Value", self.value)
      end
      lfoToOsc2OpBLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2OpBLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc2OpCLevelKnob = lfoTargetPanel2:Knob("LfoToOsc2OpCLevel", 0, 0, 1)
      lfoToOsc2OpCLevelKnob.unit = Unit.PercentNormalized
      lfoToOsc2OpCLevelKnob.displayName = "Op C Level"
      lfoToOsc2OpCLevelKnob.fillColour = knobColour
      lfoToOsc2OpCLevelKnob.outlineColour = lfoColour
      lfoToOsc2OpCLevelKnob.changed = function(self)
        FMMacros["lfoToOsc2OpCLevel"]:setParameter("Value", self.value)
      end
      lfoToOsc2OpCLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2OpCLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc2OpDLevelKnob = lfoTargetPanel2:Knob("LfoToOsc2OpDLevel", 0, 0, 1)
      lfoToOsc2OpDLevelKnob.unit = Unit.PercentNormalized
      lfoToOsc2OpDLevelKnob.displayName = "Op D Level"
      lfoToOsc2OpDLevelKnob.fillColour = knobColour
      lfoToOsc2OpDLevelKnob.outlineColour = lfoColour
      lfoToOsc2OpDLevelKnob.changed = function(self)
        FMMacros["lfoToOsc2OpDLevel"]:setParameter("Value", self.value)
      end
      lfoToOsc2OpDLevelKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2OpDLevelKnob,default=50,floor=0.1,ceiling=0.6,probability=20,category="modulation"})

      local lfoToOsc2FeedbackKnob = lfoTargetPanel2:Knob("LfoToOsc2Feedback", 0, 0, 1)
      lfoToOsc2FeedbackKnob.unit = Unit.PercentNormalized
      lfoToOsc2FeedbackKnob.displayName = "Feedback"
      lfoToOsc2FeedbackKnob.fillColour = knobColour
      lfoToOsc2FeedbackKnob.outlineColour = lfoColour
      lfoToOsc2FeedbackKnob.changed = function(self)
        FMMacros["lfoToOsc2Feedback"]:setParameter("Value", self.value)
      end
      lfoToOsc2FeedbackKnob:changed()
      table.insert(tweakables, {widget=lfoToOsc2FeedbackKnob,default=50,floor=0.1,ceiling=0.3,probability=50,category="modulation"})
    end

    if synthTypes.isAnalog or synthTypes.isAdditive or synthTypes.isWavetable or synthTypes.isFM then
      local lfoToPitchOsc2Knob = lfoTargetPanel2:Knob("LfoToPitchOsc2", 0, 0, 48)
      lfoToPitchOsc2Knob.displayName = "Pitch"
      lfoToPitchOsc2Knob.mapper = Mapper.Quadratic
      lfoToPitchOsc2Knob.fillColour = knobColour
      lfoToPitchOsc2Knob.outlineColour = lfoColour
      lfoToPitchOsc2Knob.changed = function(self)
        local factor = 1 / 48
        local value = (self.value * factor)
        commonMacros.lfoToPitchOsc2:setParameter("Value", value)
      end
      lfoToPitchOsc2Knob:changed()
      table.insert(tweakables, {widget=lfoToPitchOsc2Knob,ceiling=0.1,probability=75,default=80,zero=30,useDuration=true,category="modulation"})
    end
  end

  return lfoTargetPanel2
end

local lfoTargetPanel2 = panelCreators.createLfoTargetPanel2()

--------------------------------------------------------------------------------
-- Vibrato/Drum
--------------------------------------------------------------------------------

panelCreators.createDrumPanel = function()
  local drumPanel = Panel("DrumPanel")
  drumPanel:Label("Osc 1 Amp")

  local osc1AttackKnob = drumPanel:Knob("Osc1Attack", 0., 0., 10.)
  osc1AttackKnob.displayName = "Tone Attack"
  osc1AttackKnob.fillColour = knobColour
  osc1AttackKnob.outlineColour = ampEnvColour
  osc1AttackKnob.mapper = Mapper.Quartic
  osc1AttackKnob.changed = function(self)
    synthOscillators[1]:setParameter("OscAttack", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  osc1AttackKnob:changed()
  table.insert(tweakables, {widget=osc1AttackKnob,attack=true,floor=0.,ceiling=0.15,probability=75,default=25,zero=25,useDuration=false,category="mixer"})

  local osc1DecayKnob = drumPanel:Knob("Osc1Decay", 0.1, 0.01, 10.)
  osc1DecayKnob.displayName = "Tone Decay"
  osc1DecayKnob.fillColour = knobColour
  osc1DecayKnob.outlineColour = ampEnvColour
  osc1DecayKnob.mapper = Mapper.Quartic
  osc1DecayKnob.changed = function(self)
    synthOscillators[1]:setParameter("OscDecay", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  osc1DecayKnob:changed()
  table.insert(tweakables, {widget=osc1DecayKnob,decay=true,floor=0.01,ceiling=0.5,probability=50,default=25,useDuration=false,category="mixer"})

  local noise1AttackKnob = drumPanel:Knob("Noise1Attack", 0., 0., 10.)
  noise1AttackKnob.displayName = "Noise Attack"
  noise1AttackKnob.fillColour = knobColour
  noise1AttackKnob.outlineColour = ampEnvColour
  noise1AttackKnob.mapper = Mapper.Quartic
  noise1AttackKnob.changed = function(self)
    synthOscillators[1]:setParameter("NoiseAttack", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  noise1AttackKnob:changed()
  table.insert(tweakables, {widget=noise1AttackKnob,attack=true,floor=0.,ceiling=0.15,probability=75,default=25,zero=25,useDuration=false,category="mixer"})

  local noise1DecayKnob = drumPanel:Knob("Noise1Decay", 0.1, 0.01, 10.)
  noise1DecayKnob.displayName = "Noise Decay"
  noise1DecayKnob.fillColour = knobColour
  noise1DecayKnob.outlineColour = ampEnvColour
  noise1DecayKnob.mapper = Mapper.Quartic
  noise1DecayKnob.changed = function(self)
    synthOscillators[1]:setParameter("NoiseDecay", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  noise1DecayKnob:changed()
  table.insert(tweakables, {widget=noise1DecayKnob,decay=true,floor=0.01,ceiling=0.5,probability=50,default=25,useDuration=false,category="mixer"})

  return drumPanel
end

panelCreators.createVibratoPanel = function(vibratoPanel)
  if type(vibratoPanel) == "nil" then
    vibratoPanel = Panel("VibratoPanel")
  end

  local vibratoLabel = vibratoPanel:Label("Vibrato")
  if synthTypes.isDrum then
    vibratoLabel.x = vibratoLabel.x + 30
    vibratoLabel.width = 60
  end

  local vibratoKnob = vibratoPanel:Knob("VibratoDepth", 0, 0, 1)
  vibratoKnob.unit = Unit.PercentNormalized
  vibratoKnob.displayName="Depth"
  vibratoKnob.x = vibratoLabel.x + vibratoLabel.width
  vibratoKnob.fillColour = knobColour
  vibratoKnob.outlineColour = vibratoColour
  vibratoKnob.changed = function(self)
    commonMacros.vibratoAmount:setParameter("Value", self.value)
  end
  vibratoKnob:changed()
  table.insert(tweakables, {widget=vibratoKnob,ceiling=0.5,probability=70,zero=40,default=20,useDuration=true,category="mixer"})

  local vibratoRateKnob = vibratoPanel:Knob("VibratoRate", 0.7, 0, 1)
  vibratoRateKnob.displayName="Rate"
  vibratoRateKnob.x = vibratoKnob.x + vibratoKnob.width
  vibratoRateKnob.fillColour = knobColour
  vibratoRateKnob.outlineColour = vibratoColour
  vibratoRateKnob.changed = function(self)
    commonMacros.vibratoRate:setParameter("Value", self.value)
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
  table.insert(tweakables, {widget=vibratoRateKnob,default=50,floor=0.5,ceiling=0.8,probability=50,useDuration=true,category="mixer"})

  local vibratoRiseKnob = vibratoPanel:Knob("VibratoRiseTime", 0, 0, 10)
  vibratoRiseKnob.displayName="Rise Time"
  vibratoRiseKnob.x = vibratoRateKnob.x + vibratoRateKnob.width
  vibratoRiseKnob.fillColour = knobColour
  vibratoRiseKnob.outlineColour = vibratoColour
  vibratoRiseKnob.mapper = Mapper.Quartic
  vibratoRiseKnob.changed = function(self)
    synthModulators.vibratoLfo:setParameter("RiseTime", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  vibratoRiseKnob:changed()
  table.insert(tweakables, {widget=vibratoRiseKnob,factor=5,floor=0.5,ceiling=3.5,probability=50,default=50,category="mixer"})

  if synthTypes.isDrum == false then
    local wheelToVibratoKnob = vibratoPanel:Knob("WheelToVibrato", 0, 0, 1)
    wheelToVibratoKnob.unit = Unit.PercentNormalized
    wheelToVibratoKnob.displayName="Modwheel"
    wheelToVibratoKnob.fillColour = knobColour
    wheelToVibratoKnob.outlineColour = vibratoColour
    wheelToVibratoKnob.changed = function(self)
      commonMacros.wheelToVibrato:setParameter("Value", self.value)
    end
    wheelToVibratoKnob:changed()
    table.insert(tweakables, {widget=wheelToVibratoKnob,default=50,floor=0.6,ceiling=0.85,probability=60,excludeWhenTweaking=true,category="mixer"})

    local atToVibratoKnob = vibratoPanel:Knob("AftertouchToVibrato", 0, 0, 1)
    atToVibratoKnob.unit = Unit.PercentNormalized
    atToVibratoKnob.displayName="Aftertouch"
    atToVibratoKnob.fillColour = knobColour
    atToVibratoKnob.outlineColour = vibratoColour
    atToVibratoKnob.changed = function(self)
      commonMacros.atToVibrato:setParameter("Value", self.value)
    end
    atToVibratoKnob:changed()
    table.insert(tweakables, {widget=atToVibratoKnob,default=50,floor=0.7,ceiling=0.9,probability=70,excludeWhenTweaking=true,category="mixer"})
  end

  return vibratoPanel
end

local vibratoPanel
if synthTypes.isDrum then
  vibratoPanel = panelCreators.createDrumPanel()
else
  vibratoPanel = panelCreators.createVibratoPanel()
end

--------------------------------------------------------------------------------
-- Amp Env
--------------------------------------------------------------------------------

panelCreators.createDrumEnvPanel = function()
  local ampEnvPanel = Panel("ampEnv1")

  ampEnvPanel:Label("Osc 2 Amp")

  local osc2AttackKnob = ampEnvPanel:Knob("Osc2Attack", 0., 0., 10.)
  osc2AttackKnob.displayName = "Tone Attack"
  osc2AttackKnob.fillColour = knobColour
  osc2AttackKnob.outlineColour = ampEnvColour
  osc2AttackKnob.mapper = Mapper.Quartic
  osc2AttackKnob.changed = function(self)
    synthOscillators[2]:setParameter("OscAttack", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  osc2AttackKnob:changed()
  table.insert(tweakables, {widget=osc2AttackKnob,attack=true,floor=0.,ceiling=0.15,probability=75,default=25,zero=25,useDuration=false,category="mixer"})

  local osc2DecayKnob = ampEnvPanel:Knob("Osc2Decay", 0.1, 0.01, 10.)
  osc2DecayKnob.displayName = "Tone Decay"
  osc2DecayKnob.fillColour = knobColour
  osc2DecayKnob.outlineColour = ampEnvColour
  osc2DecayKnob.mapper = Mapper.Quartic
  osc2DecayKnob.changed = function(self)
    synthOscillators[2]:setParameter("OscDecay", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  osc2DecayKnob:changed()
  table.insert(tweakables, {widget=osc2DecayKnob,decay=true,floor=0.01,ceiling=0.5,probability=50,default=25,useDuration=false,category="mixer"})

  local noise2AttackKnob = ampEnvPanel:Knob("Noise2Attack", 0., 0., 10.)
  noise2AttackKnob.displayName = "Noise Attack"
  noise2AttackKnob.fillColour = knobColour
  noise2AttackKnob.outlineColour = ampEnvColour
  noise2AttackKnob.mapper = Mapper.Quartic
  noise2AttackKnob.changed = function(self)
    synthOscillators[2]:setParameter("NoiseAttack", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  noise2AttackKnob:changed()
  table.insert(tweakables, {widget=noise2AttackKnob,attack=true,floor=0.,ceiling=0.15,probability=75,default=25,zero=25,useDuration=false,category="mixer"})

  local noise2DecayKnob = ampEnvPanel:Knob("Noise2Decay", 0.1, 0.01, 10.)
  noise2DecayKnob.displayName = "Noise Decay"
  noise2DecayKnob.fillColour = knobColour
  noise2DecayKnob.outlineColour = ampEnvColour
  noise2DecayKnob.mapper = Mapper.Quartic
  noise2DecayKnob.changed = function(self)
    synthOscillators[2]:setParameter("NoiseDecay", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  noise2DecayKnob:changed()
  table.insert(tweakables, {widget=noise2DecayKnob,decay=true,floor=0.01,ceiling=0.5,probability=50,default=25,useDuration=false,category="mixer"})

  return ampEnvPanel
end

panelCreators.createAmpEnvPanel = function()
  local ampEnvPanel = Panel("ampEnv1")

  local activeAmpEnvOsc = 1
  local ampEnvMenu
  if synthTypes.isAnalog3Osc == true then
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
      synthModulators.ampEnv1:setParameter("AttackTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      synthModulators.ampEnv2:setParameter("AttackTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      synthModulators.ampEnvNoise:setParameter("AttackTime", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  ampAttackKnob:changed()
  table.insert(tweakables, {widget=ampAttackKnob,attack=true,floor=0.001,ceiling=0.01,probability=85,default=20,defaultTweakRange=0.1,useDuration=false,category="synthesis"})

  local ampDecayKnob = ampEnvPanel:Knob("Decay", 0.050, 0, 10)
  ampDecayKnob.fillColour = knobColour
  ampDecayKnob.outlineColour = ampEnvColour
  ampDecayKnob.mapper = Mapper.Quartic
  ampDecayKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      synthModulators.ampEnv1:setParameter("DecayTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      synthModulators.ampEnv2:setParameter("DecayTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      synthModulators.ampEnvNoise:setParameter("DecayTime", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  ampDecayKnob:changed()
  table.insert(tweakables, {widget=ampDecayKnob,decay=true,floor=0.01,ceiling=0.5,probability=50,default=25,useDuration=false,category="synthesis"})

  local ampSustainKnob = ampEnvPanel:Knob("Sustain", 1, 0, 1)
  ampSustainKnob.unit = Unit.PercentNormalized
  ampSustainKnob.fillColour = knobColour
  ampSustainKnob.outlineColour = ampEnvColour
  ampSustainKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      synthModulators.ampEnv1:setParameter("SustainLevel", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      synthModulators.ampEnv2:setParameter("SustainLevel", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      synthModulators.ampEnvNoise:setParameter("SustainLevel", self.value)
    end
  end
  ampSustainKnob:changed()
  table.insert(tweakables, {widget=ampSustainKnob,floor=0.3,ceil=0.9,probability=80,default=60,zero=2,useDuration=false,category="synthesis"})

  local ampReleaseKnob = ampEnvPanel:Knob("Release", 0.010, 0, 10)
  ampReleaseKnob.fillColour = knobColour
  ampReleaseKnob.outlineColour = ampEnvColour
  ampReleaseKnob.mapper = Mapper.Quartic
  ampReleaseKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      synthModulators.ampEnv1:setParameter("ReleaseTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      synthModulators.ampEnv2:setParameter("ReleaseTime", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      synthModulators.ampEnvNoise:setParameter("ReleaseTime", self.value)
    end
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  ampReleaseKnob:changed()
  table.insert(tweakables, {widget=ampReleaseKnob,release=true,floor=0.01,ceiling=0.5,probability=90,default=30,defaultTweakRange=1,useDuration=false,category="synthesis"})

  local ampVelocityKnob = ampEnvPanel:Knob("VelocityToAmpEnv", 10, 0, 40)
  ampVelocityKnob.displayName="Velocity"
  ampVelocityKnob.fillColour = knobColour
  ampVelocityKnob.outlineColour = ampEnvColour
  ampVelocityKnob.changed = function(self)
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 2 then
      synthModulators.ampEnv1:setParameter("DynamicRange", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 3 then
      synthModulators.ampEnv2:setParameter("DynamicRange", self.value)
    end
    if activeAmpEnvOsc == 1 or activeAmpEnvOsc == 4 then
      synthModulators.ampEnvNoise:setParameter("DynamicRange", self.value)
    end
  end
  ampVelocityKnob:changed()
  table.insert(tweakables, {widget=ampVelocityKnob,min=40,floor=5,ceiling=25,probability=80,default=70,useDuration=true,category="synthesis"})

  function setAmpEnvKnob(knob, param)
    if activeAmpEnvOsc == 1 then
      knob.enabled = helpers.isEqual(synthModulators.ampEnv1:getParameter(param), synthModulators.ampEnv2:getParameter(param)) and helpers.isEqual(synthModulators.ampEnv2:getParameter(param), synthModulators.ampEnvNoise:getParameter(param))
      return
    end
    local value
    if activeAmpEnvOsc == 2 then
      value = synthModulators.ampEnv1:getParameter(param)
    elseif activeAmpEnvOsc == 3 then
      value = synthModulators.ampEnv2:getParameter(param)
    elseif activeAmpEnvOsc == 4 then
      value = synthModulators.ampEnvNoise:getParameter(param)
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

local ampEnvPanel
if synthTypes.isDrum then
  ampEnvPanel = panelCreators.createDrumEnvPanel()
else
  ampEnvPanel = panelCreators.createAmpEnvPanel()
end

--------------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------------

panelCreators.createEffectsPanel = function()
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
  reverbKnob.unit = Unit.PercentNormalized
  reverbKnob.x = 100
  reverbKnob.y = 50
  reverbKnob.size = knobSize
  reverbKnob.mapper = Mapper.Quadratic
  reverbKnob.fillColour = knobColour
  reverbKnob.outlineColour = filterEffectsColour
  reverbKnob.changed = function(self)
    commonMacros.reverbMix:setParameter("Value", self.value)
  end
  reverbKnob:changed()
  table.insert(tweakables, {widget=reverbKnob,floor=0.1,ceiling=0.6,probability=100,useDuration=true,category="effects"})

  local delayKnob = effectsPanel:Knob("Delay", 0, 0, 1)
  delayKnob.unit = Unit.PercentNormalized
  delayKnob.size = knobSize
  delayKnob.x = 300
  delayKnob.y = reverbKnob.y
  delayKnob.mapper = Mapper.Quadratic
  delayKnob.fillColour = knobColour
  delayKnob.outlineColour = filterEffectsColour
  delayKnob.changed = function(self)
    commonMacros.delayMix:setParameter("Value", self.value)
  end
  delayKnob:changed()
  table.insert(tweakables, {widget=delayKnob,floor=0.01,ceiling=0.6,probability=100,useDuration=true,category="effects"})

  local phasorMixKnob = effectsPanel:Knob("Phasor", 0, 0, 1)
  phasorMixKnob.unit = Unit.PercentNormalized
  phasorMixKnob.size = knobSize
  phasorMixKnob.x = 500
  phasorMixKnob.y = reverbKnob.y
  phasorMixKnob.mapper = Mapper.Quadratic
  phasorMixKnob.fillColour = knobColour
  phasorMixKnob.outlineColour = filterEffectsColour
  phasorMixKnob.changed = function(self)
    commonMacros.phasorMix:setParameter("Value", self.value)
  end
  phasorMixKnob:changed()
  table.insert(tweakables, {widget=phasorMixKnob,default=80,zero=50,ceiling=0.75,probability=20,useDuration=true,category="effects"})

  local chorusKnob = effectsPanel:Knob("Chorus", 0, 0, 1)
  chorusKnob.unit = Unit.PercentNormalized
  chorusKnob.size = knobSize
  chorusKnob.x = reverbKnob.x
  chorusKnob.y = delayKnob.y + delayKnob.height + 20
  chorusKnob.mapper = Mapper.Quadratic
  chorusKnob.fillColour = knobColour
  chorusKnob.outlineColour = filterEffectsColour
  chorusKnob.changed = function(self)
    commonMacros.chorusMix:setParameter("Value", self.value)
  end
  chorusKnob:changed()
  table.insert(tweakables, {widget=chorusKnob,floor=0.01,ceiling=0.5,probability=60,default=50,useDuration=true,category="effects"})

  local driveKnob = effectsPanel:Knob("Drive", 0, 0, 1)
  driveKnob.unit = Unit.PercentNormalized
  driveKnob.size = knobSize
  driveKnob.x = delayKnob.x
  driveKnob.y = chorusKnob.y
  driveKnob.mapper = Mapper.Quadratic
  driveKnob.fillColour = knobColour
  driveKnob.outlineColour = filterEffectsColour
  driveKnob.changed = function(self)
    commonMacros.driveAmount:setParameter("Value", self.value)
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
    commonMacros.maximizer:setParameter("Value", value)
  end
  maximizerButton:changed()
  table.insert(tweakables, {widget=maximizerButton,func=getRandomBoolean,probability=10,excludeWhenTweaking=true,category="effects"})

  return effectsPanel
end

local effectsPanel = panelCreators.createEffectsPanel()

--------------------------------------------------------------------------------
-- Mixer
--------------------------------------------------------------------------------

local arpeggiatorButton

panelCreators.createMixerPanel = function()
  local function setStackVoices(numVoices, unisonDetune, stereoSpread, phaseSpread)
    for i=1,8 do
      synthOscillators[1]:setParameter("Bypass"..i, (numVoices<i))
      synthOscillators[1]:setParameter("Gain"..i, 1 - ((numVoices/10) / 2))
      synthOscillators[2]:setParameter("Bypass"..i, (numVoices<i))
      synthOscillators[2]:setParameter("Gain"..i, 1 - ((numVoices/10) / 2))
    end
  
    -- DETUNE
    if numVoices == 1 then
      synthOscillators[1]:setParameter("FineTune1", 0)
      synthOscillators[2]:setParameter("FineTune1", 0)
    else
      local spreadPerOscillator = (unisonDetune * 100) / numVoices
      local currentSpread = spreadPerOscillator
      for i=1,numVoices do
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
        synthOscillators[1]:setParameter("FineTune"..i, spreadValueOsc1)
        synthOscillators[2]:setParameter("FineTune"..i, spreadValueOsc2)
      end
    end
  
    -- STEREO SPREAD
    if numVoices == 1 then
      synthOscillators[1]:setParameter("Pan1", 0)
      synthOscillators[2]:setParameter("Pan1", 0)
    else
      local spreadPerOscillator = stereoSpread / numVoices
      local currentSpread = spreadPerOscillator
      for i=1,numVoices do
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
        synthOscillators[1]:setParameter("Pan"..i, spreadValueOsc1)
        synthOscillators[2]:setParameter("Pan"..i, spreadValueOsc2)
      end
    end
  
    -- PHASE SPREAD
    if numVoices == 1 then
      synthOscillators[1]:setParameter("StartPhase1", 0)
      synthOscillators[2]:setParameter("StartPhase1", 0)
    else
      local spreadPerOscillator = phaseSpread / numVoices
      local currentSpread = spreadPerOscillator
      for i=1,numVoices do
        --print("currentSpread:", currentSpread, i)
        synthOscillators[1]:setParameter("StartPhase1"..i, spreadValue)
        synthOscillators[2]:setParameter("StartPhase1"..i, spreadValue)
        currentSpread = currentSpread + spreadPerOscillator
      end
    end
  end
  
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

  if synthTypes.isAnalog3Osc then
    mixerLabel.width = 60
    marginRight = 1
    knobSize = {95,40}
  elseif synthTypes.isAdditive then
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
    commonMacros.osc1Mix:setParameter("Value", self.value)
    self.displayText = helpers.formatGainInDb(self.value)
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
    commonMacros.osc2Mix:setParameter("Value", self.value)
    self.displayText = helpers.formatGainInDb(self.value)
  end
  osc2MixKnob:changed()
  table.insert(tweakables, {widget=osc2MixKnob,floor=0.5,ceiling=0.75,probability=100,absoluteLimit=0.8,zero=10,default=5,useDuration=true,category="mixer"})

  local subOscWaveformKnob
  if synthTypes.isAnalog3Osc then
    local osc3MixKnob = mixerPanel:Knob("Osc3Mix", 0, 0, 1)
    osc3MixKnob.displayName = "Osc 3"
    osc3MixKnob.y = mixerLabel.y
    osc3MixKnob.x = osc2MixKnob.x + osc2MixKnob.width + marginRight
    osc3MixKnob.size = knobSize
    osc3MixKnob.fillColour = knobColour
    osc3MixKnob.outlineColour = osc2Colour
    osc3MixKnob.changed = function(self)
      synthOscillators[1]:setParameter("Gain3", self.value)
      self.displayText = helpers.formatGainInDb(self.value)
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
      self.displayText = helpers.formatGainInDb(self.value)
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
      synthOscillators[2]:setParameter("Waveform", self.value)
      self.displayText = waveforms[self.value]
     end
    subOscWaveformKnob:changed()
    table.insert(tweakables, {widget=subOscWaveformKnob,min=4,default=75,category="synthesis"})
  end

  local noiseTypeMenu
  local noiseMixKnob = mixerPanel:Knob("NoiseMix", 0, 0, 1)
  noiseMixKnob.displayName = "Noise"
  if synthTypes.isAnalog3Osc then
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
    commonMacros.noiseMix:setParameter("Value", self.value)
    self.displayText = helpers.formatGainInDb(self.value)
  end
  noiseMixKnob:changed()
  table.insert(tweakables, {widget=noiseMixKnob,floor=0.3,ceiling=0.75,probability=100,default=5,zero=10,absoluteLimit=0.8,useDuration=true,category="mixer"})
  
  if synthTypes.isAnalog or synthTypes.isDrum or synthTypes.isAnalogStack or synthTypes.isWavetable or synthTypes.isAdditive or synthTypes.isFM then
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
      synthOscillators[3]:setParameter("NoiseType", value)
    end
    noiseTypeMenu:changed()
    table.insert(tweakables, {widget=noiseTypeMenu,min=#noiseTypes,default=75,valueFilter={5,6,7,8,9},category="synthesis"})
  end

  local panSpreadKnob = mixerPanel:Knob("PanSpread", 0, 0, 1)
  panSpreadKnob.unit = Unit.PercentNormalized
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
    commonMacros.panSpread:setParameter("Value", self.value)
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
    commonMacros.arpeggiator:setParameter("Value", value)
  end
  arpeggiatorButton:changed()

  local randomPhaseStartKnob
  if synthTypes.isAnalog or synthTypes.isAnalogStack or synthTypes.isAnalog3Osc then
    randomPhaseStartKnob = mixerPanel:Knob("RandomPhaseStart", 0, 0, 1)
    randomPhaseStartKnob.unit = Unit.PercentNormalized
    randomPhaseStartKnob.displayName = "Rand Phase"
    randomPhaseStartKnob.y = 50
    randomPhaseStartKnob.x = mixerLabel.x
    randomPhaseStartKnob.size = knobSize
    randomPhaseStartKnob.fillColour = knobColour
    randomPhaseStartKnob.outlineColour = unisonColour
    randomPhaseStartKnob.changed = function(self)
      if synthTypes.isAnalogStack then
        for i=1,8 do
          synthOscillators[1]:setParameter("StartPhase"..i, (gem.getRandom()*self.value))
          synthOscillators[2]:setParameter("StartPhase"..i, (gem.getRandom()*self.value))
        end
      else
        analogMacros["randomPhaseStart"]:setParameter("Value", self.value)
      end
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
    Program.layers[1]:setParameter("PlayMode", value)
    Program.layers[2]:setParameter("PlayMode", value)
    Program.layers[3]:setParameter("PlayMode", value)
  end
  playModeMenu:changed()
  table.insert(tweakables, {widget=playModeMenu,min=#playModes,default=75,excludeWhenTweaking=true,category="synthesis"})

  local portamentoTimeKnob = mixerPanel:Knob("PortamentoTime", 0.03, 0, 10)
  portamentoTimeKnob.displayName = "Glide Time"
  portamentoTimeKnob.y = playModeMenu.y
  portamentoTimeKnob.x = playModeMenu.x + playModeMenu.width + marginRight
  portamentoTimeKnob.size = knobSize
  portamentoTimeKnob.fillColour = knobColour
  portamentoTimeKnob.outlineColour = osc2Colour
  portamentoTimeKnob.mapper = Mapper.Quartic
  portamentoTimeKnob.changed = function(self)
    Program.layers[1]:setParameter("PortamentoTime", self.value)
    Program.layers[2]:setParameter("PortamentoTime", self.value)
    Program.layers[3]:setParameter("PortamentoTime", self.value)
    self.displayText = helpers.formatTimeInSeconds(self.value)
  end
  portamentoTimeKnob:changed()
  table.insert(tweakables, {widget=portamentoTimeKnob,floor=0.03,ceiling=0.15,probability=95,default=50,excludeWhenTweaking=true,category="synthesis"})

  if synthTypes.isDrum then
    mixerPanel = panelCreators.createVibratoPanel(mixerPanel)
  else
    local unisonVoicesMax = 8
    if synthTypes.isAdditive then
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

    unisonDetuneKnob.unit = Unit.PercentNormalized
    unisonDetuneKnob.displayName = "Detune"
    unisonDetuneKnob.y = playModeMenu.y
    unisonDetuneKnob.x = unisonVoicesKnob.x + unisonVoicesKnob.width + marginRight
    unisonDetuneKnob.size = knobSize
    unisonDetuneKnob.fillColour = knobColour
    unisonDetuneKnob.outlineColour = unisonColour
    unisonDetuneKnob.changed = function(self)
      if synthTypes.isAnalogStack then
        setStackVoices(unisonVoicesKnob.value, self.value, stereoSpreadKnob.value, randomPhaseStartKnob.value)
      else
        commonMacros.unisonDetune:setParameter("Value", self.value)
      end
    end
    unisonDetuneKnob:changed()
    table.insert(tweakables, {widget=unisonDetuneKnob,ceiling=0.3,absoluteLimit=0.6,probability=90,default=80,tweakRange=0.2,useDuration=true,excludeWhenTweaking=true,category="synthesis"})

    if synthTypes.isAdditive then
      stereoSpreadKnob.displayName = "Beating"
    else
      stereoSpreadKnob.displayName = "Stereo Spread"
    end
    stereoSpreadKnob.unit = Unit.PercentNormalized
    stereoSpreadKnob.y = playModeMenu.y
    stereoSpreadKnob.x = unisonDetuneKnob.x + unisonDetuneKnob.width + marginRight
    stereoSpreadKnob.size = knobSize
    stereoSpreadKnob.width = 120
    stereoSpreadKnob.fillColour = knobColour
    stereoSpreadKnob.outlineColour = unisonColour
    stereoSpreadKnob.changed = function(self)
      if synthTypes.isAnalogStack then
        setStackVoices(unisonVoicesKnob.value, unisonDetuneKnob.value, self.value, randomPhaseStartKnob.value)
      else
        commonMacros.stereoSpread:setParameter("Value", self.value)
      end
    end
    stereoSpreadKnob:changed()
    table.insert(tweakables, {widget=stereoSpreadKnob,ceiling=0.5,probability=40,default=40,useDuration=true,excludeWhenTweaking=true,category="synthesis"})

    local waveSpreadKnob
    if synthTypes.isWavetable then
      waveSpreadKnob = mixerPanel:Knob("WaveSpread", 0, 0, 1)
      waveSpreadKnob.unit = Unit.PercentNormalized
      waveSpreadKnob.displayName = "Wave Spread"
      waveSpreadKnob.y = playModeMenu.y
      waveSpreadKnob.x = stereoSpreadKnob.x + stereoSpreadKnob.width + marginRight
      waveSpreadKnob.size = knobSize
      waveSpreadKnob.fillColour = knobColour
      waveSpreadKnob.outlineColour = unisonColour
      waveSpreadKnob.changed = function(self)
        wavetableMacros["waveSpread"]:setParameter("Value", self.value)
      end
      waveSpreadKnob:changed()
      table.insert(tweakables, {widget=waveSpreadKnob,ceiling=0.5,probability=30,default=30,useDuration=true,excludeWhenTweaking=true,category="synthesis"})
    end

    unisonVoicesKnob.changed = function(self)
      local unisonActive = false
      if synthTypes.isAnalog then
        synthOscillators[1]:setParameter("NumOscillators", self.value)
        synthOscillators[2]:setParameter("NumOscillators", self.value)
      elseif synthTypes.isAnalogStack then
        setStackVoices(self.value, unisonDetuneKnob.value, stereoSpreadKnob.value, randomPhaseStartKnob.value)
      elseif synthTypes.isWavetable or synthTypes.isAdditive then
        local factor = 1 / (unisonVoicesMax + 1)
        local value = factor * self.value
        wavetableMacros["unisonVoices"]:setParameter("Value", value)
      elseif synthTypes.isAnalog3Osc then
        Program.layers[1]:setParameter("NumVoicesPerNote", self.value)
        synthOscillators[2]:setParameter("NumOscillators", self.value)  
      elseif synthTypes.isFM then
        Program.layers[1]:setParameter("NumVoicesPerNote", self.value)
        Program.layers[2]:setParameter("NumVoicesPerNote", self.value)
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
      synthOscillators[3]:setParameter("Stereo", unisonActive)
    end
    unisonVoicesKnob:changed()
    table.insert(tweakables, {widget=unisonVoicesKnob,min=unisonVoicesMax,default=25,excludeWhenTweaking=true,category="synthesis"})
  end

  return mixerPanel
end

local mixerPanel = panelCreators.createMixerPanel()

--------------------------------------------------------------------------------
-- Tweak Panel
--------------------------------------------------------------------------------

local twequencerParameters = {
  liveTweakButton = nil,
  tweakLevelKnob = nil,
}

local patchmakerParameters = {
  tweakButton = nil,
  tweakLevelKnob = nil,
}

local function storeNewSnapshot()
  print("Storing patch tweaks...")
  local patch = {}
  for i,v in ipairs(tweakables) do
    table.insert(patch, {index=i,widget=v.widget.name,value=v.widget.value})
  end
  table.insert(storedPatches, patch)
  print("Storing patch")
  patchesMenu:clear()
  helpers.populatePatchesMenu()
  print("Adding to patchesMenu", index)
  patchesMenu:setValue(#storedPatches)
end

panelCreators.createPatchMakerPanel = function()
  local function clearStoredPatches()
    print("Clearing stored snapshots...")
    storedPatches = {}
    patchesMenu:clear()
  end

  local function updateSelectedSnapshot()
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
    print("Updating patch:", selected)
  end

  local function removeSelectedSnapshot()
    local selected = patchesMenu.value
    if #storedPatches == 0 or selected == 1 then
      return
    end
    table.remove(storedPatches, selected)
    patchesMenu:clear()
    helpers.populatePatchesMenu()
    print("Remove patch:", selected)
    patchesMenu:setValue(#storedPatches)
  end

  local tweakPanel = Panel("Tweaks")
  tweakPanel.backgroundColour = bgColor
  tweakPanel.x = marginX
  tweakPanel.y = 10
  tweakPanel.width = width
  tweakPanel.height = 320

  local tweakLevelKnob = tweakPanel:Knob("TweakLevel", 50, 0, 100, true)
  tweakLevelKnob.fillColour = knobColour
  tweakLevelKnob.outlineColour = outlineColour
  tweakLevelKnob.displayName = "Tweak Level"
  tweakLevelKnob.bounds = {70,10,300,150}
  patchmakerParameters.tweakLevelKnob = tweakLevelKnob

  local tweakButton = tweakPanel:Button("Tweak")
  tweakButton.persistent = false
  tweakButton.alpha = buttonAlpha
  tweakButton.backgroundColourOff = buttonBackgroundColourOff
  tweakButton.backgroundColourOn = buttonBackgroundColourOn
  tweakButton.textColourOff = buttonTextColourOff
  tweakButton.textColourOn = buttonTextColourOn
  tweakButton.displayName = "Tweak Patch"
  tweakButton.bounds = {width/2,10,345,tweakLevelKnob.height}
  patchmakerParameters.tweakButton = tweakButton

  patchesMenu = tweakPanel:Menu("PatchesMenu")
  patchesMenu.persistent = false
  patchesMenu.backgroundColour = menuBackgroundColour
  patchesMenu.textColour = menuTextColour
  patchesMenu.arrowColour = menuArrowColour
  patchesMenu.outlineColour = menuOutlineColour
  patchesMenu.x = 10
  patchesMenu.y = 200
  patchesMenu.displayName = "Stored Patches"
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
      helpers.setWidgetValue(v.index, v.widget, v.value)
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

  local actions = {"Choose...", "Add to patches", "Update selected patch", "Recall saved patch", "Initialize patch", "--- DANGERZONE ---", "Remove selected patch", "Remove all patches"}
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
      helpers.recallStoredPatch()
    elseif self.value == 5 then
      helpers.initPatch()
    elseif self.value == 7 then
      removeSelectedSnapshot()
    elseif self.value == 8 then
      clearStoredPatches()
    end
    self.selected = 1
  end

  local modStyleMenu = tweakPanel:Menu("ModulationStyle", {"Automatic", "Very fast", "Fast", "Medium fast", "Medium", "Medium slow", "Slow", "Very slow"})
  modStyleMenu.backgroundColour = menuBackgroundColour
  modStyleMenu.textColour = menuTextColour
  modStyleMenu.arrowColour = menuArrowColour
  modStyleMenu.outlineColour = menuOutlineColour
  modStyleMenu.displayName = "Modulation Style"
  modStyleMenu.x = width/2
  modStyleMenu.y = patchesMenu.y
  modStyleMenu.width = width/6-10

  local envStyleMenu = tweakPanel:Menu("EnvStyle", {"Automatic", "Very short", "Short", "Medium short", "Medium", "Medium long", "Long", "Very long"})
  if synthTypes.isDrum then
    envStyleMenu.selected = 2
  end
  envStyleMenu.backgroundColour = menuBackgroundColour
  envStyleMenu.textColour = menuTextColour
  envStyleMenu.arrowColour = menuArrowColour
  envStyleMenu.outlineColour = menuOutlineColour
  envStyleMenu.displayName = "Envelope Style"
  envStyleMenu.width = modStyleMenu.width
  envStyleMenu.x = modStyleMenu.width + modStyleMenu.x + 10
  envStyleMenu.y = modStyleMenu.y

  local scopeMenu = tweakPanel:Menu("TweakScope", {"All", "Settings", "Random"})
  scopeMenu.backgroundColour = menuBackgroundColour
  scopeMenu.textColour = menuTextColour
  scopeMenu.arrowColour = menuArrowColour
  scopeMenu.outlineColour = menuOutlineColour
  scopeMenu.displayName = "Include Params"
  scopeMenu.tooltip = "Set what params to include when tweaking the patch. All=all in the activated categories, Settings=params in activated categories that are active in settings, Random=random from activated categories."
  scopeMenu.width = envStyleMenu.width
  scopeMenu.x = envStyleMenu.width + envStyleMenu.x + 10
  scopeMenu.y = envStyleMenu.y

  local scopeLabel = tweakPanel:Label("Tweak Categories")
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

  tweakButton.changed = function(self)
    print("Find widgets to tweak")
    local widgetsForTweaking = helpers.getTweakables(tweakLevelKnob.value, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton, scopeMenu.value)
    -- Get the tweak suggestions
    for _,v in ipairs(widgetsForTweaking) do
      v.targetValue = helpers.getTweakSuggestion(v, tweakLevelKnob.value, envStyleMenu.value, modStyleMenu.value)
    end
    helpers.verifySettings(tweakLevelKnob.value, widgetsForTweaking, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton)
    -- Perform the suggested tweaks
    print("Start tweaking!")
    for _,v in ipairs(widgetsForTweaking) do
      helpers.tweakWidget(v)
    end
    print("Tweaking complete!")
  end

  return tweakPanel
end

--------------------------------------------------------------------------------
-- Twequencer Panel
--------------------------------------------------------------------------------

local playButton
local autoplayButton
local holdButton
local heldNotes = {}

panelCreators.createTwequencerPanel = function()
  local maxSnapshots = 500
  local numSteps = 16

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
  tweakLevelKnob.x = 300
  tweakLevelKnob.y = 100
  twequencerParameters.tweakLevelKnob = tweakLevelKnob

  local envStyleMenu = tweqPanel:Menu("SeqEnvStyle", {"Automatic", "Very short", "Short", "Medium short", "Medium", "Medium long", "Long", "Very long"})
  if synthTypes.isDrum then
    envStyleMenu.selected = 2
  end
  envStyleMenu.backgroundColour = menuBackgroundColour
  envStyleMenu.textColour = menuTextColour
  envStyleMenu.arrowColour = menuArrowColour
  envStyleMenu.outlineColour = menuOutlineColour
  envStyleMenu.displayName = "Envelope Style"
  envStyleMenu.x = 10
  envStyleMenu.y = tweakLevelKnob.y
  envStyleMenu.width = tweakLevelKnob.width

  local modStyleMenu = tweqPanel:Menu("ModStyle", {"Automatic", "Very fast", "Fast", "Medium fast", "Medium", "Medium slow", "Slow", "Very slow"})
  modStyleMenu.backgroundColour = menuBackgroundColour
  modStyleMenu.textColour = menuTextColour
  modStyleMenu.arrowColour = menuArrowColour
  modStyleMenu.outlineColour = menuOutlineColour
  modStyleMenu.displayName = "Modulation Style"
  modStyleMenu.x = envStyleMenu.x
  modStyleMenu.y = envStyleMenu.y + envStyleMenu.height + 10
  modStyleMenu.width = envStyleMenu.width

  local scopeMenu = tweqPanel:Menu("SeqTweakScope", {"All", "Settings", "Random"})
  scopeMenu.selected = 2
  scopeMenu.backgroundColour = menuBackgroundColour
  scopeMenu.textColour = menuTextColour
  scopeMenu.arrowColour = menuArrowColour
  scopeMenu.outlineColour = menuOutlineColour
  scopeMenu.displayName = "Include Params"
  scopeMenu.tooltip = "Set what params to include when tweaking the patch. All=all in the activated categories, Settings=params in activated categories that are active in settings, Random=random from activated categories."
  scopeMenu.x = modStyleMenu.x
  scopeMenu.y = modStyleMenu.y + modStyleMenu.height + 10
  scopeMenu.width = modStyleMenu.width

  local waveformMenu
  if synthTypes.isAnalog or synthTypes.isAnalog3Osc or synthTypes.isAnalogStack then
    local allowed = {"All", "Saw/Square", "Triangle/Sine", "Square/Triangle", "Saw/Sq/Tri/Sine", "Sine/Noise/Pulse", "Triangle/Sine/Pulse"}
    waveformMenu = tweqPanel:Menu("AllowedWaveforms", allowed)
    waveformMenu.backgroundColour = menuBackgroundColour
    waveformMenu.textColour = menuTextColour
    waveformMenu.arrowColour = menuArrowColour
    waveformMenu.outlineColour = menuOutlineColour
    waveformMenu.displayName = "Allowed Waveforms"
    waveformMenu.x = scopeMenu.x
    waveformMenu.y = scopeMenu.y + scopeMenu.height + 10
    waveformMenu.width = scopeMenu.width
  end

  local partsTable = tweqPanel:Table("Parts", 1, 0, 0, 1, true)
  partsTable.enabled = false
  partsTable.persistent = false
  partsTable.fillStyle = "solid"
  partsTable.backgroundColour = menuArrowColour
  partsTable.sliderColour = outlineColour
  partsTable.width = 700
  partsTable.height = 10
  partsTable.x = 5
  partsTable.y = 0

  local positionTable = tweqPanel:Table("Position", numSteps, 0, 0, 1, true)
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

  snapshotsMenu = tweqPanel:Menu("SnapshotsMenu")
  snapshotsMenu.backgroundColour = menuBackgroundColour
  snapshotsMenu.textColour = menuTextColour
  snapshotsMenu.arrowColour = menuArrowColour
  snapshotsMenu.outlineColour = menuOutlineColour
  snapshotsMenu.x = rightMenuX
  snapshotsMenu.y = tweakLevelKnob.y
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

  local function storeSnapshot(index)
    if #snapshots == 0 then
      print("No snapshots")
      return
    end
    if index > #snapshots then
      print("No snapshot at index")
      return
    end
    local patch = {}
    for i,v in ipairs(snapshots[index]) do
      table.insert(patch, {index=i,widget=v.widget.name,value=v.widget.value})
    end
    table.insert(storedPatches, patch)
    print("Storing patch")
    patchesMenu:clear()
    helpers.populatePatchesMenu()
    print("Tweaks stored from snapshot at index:", index)
  end

  local function clearSnapshots()
    snapshots = {}
    snapshotsMenu:clear()
    snapshotPosition = 1
  end

  local actions = {"Choose...", "Store selected snapshot", "Recall saved patch", "Initialize patch", "Clear snapshots"}
  local manageSnapshotsMenu = tweqPanel:Menu("ManageSnapshotsMenu", actions)
  manageSnapshotsMenu.persistent = false
  manageSnapshotsMenu.backgroundColour = menuBackgroundColour
  manageSnapshotsMenu.textColour = menuTextColour
  manageSnapshotsMenu.arrowColour = menuArrowColour
  manageSnapshotsMenu.outlineColour = menuOutlineColour
  manageSnapshotsMenu.x = rightMenuX
  manageSnapshotsMenu.y = snapshotsMenu.y + snapshotsMenu.height + 10
  manageSnapshotsMenu.displayName = "Actions"
  manageSnapshotsMenu.width = rightMenuWidth
  manageSnapshotsMenu.changed = function(self)
    if self.value == 1 then
      return
    end
    if self.value == 2 then
      storeSnapshot(snapshotsMenu.value)
    elseif self.value == 3 then
      helpers.recallStoredPatch()
    elseif self.value == 4 then
      helpers.initPatch()
    elseif self.value == 5 then
      clearSnapshots()
    end
    self.selected = 1
  end

  function releaseHeldNotes()
    for _,e in ipairs(heldNotes) do
      e.type = Event.NoteOff
      postEvent(e)
    end
    heldNotes = {}
  end

  function clearPosition()
    for i = 1, numSteps do
      positionTable:setValue(i, 0)
    end
    partsTable:setValue(1, 0)
  end

  local roundResolution = tweqPanel:Menu("RoundDuration", resolutions.getResolutionNames({}, 17))
  roundResolution.displayName = "Tweak Duration"
  roundResolution.tooltip = "Set the duration that the tweak should take for each round"
  roundResolution.selected = 9
  roundResolution.x = rightMenuX
  roundResolution.y = manageSnapshotsMenu.y + manageSnapshotsMenu.height + 10
  roundResolution.width = rightMenuWidth
  roundResolution.backgroundColour = menuBackgroundColour
  roundResolution.textColour = menuTextColour
  roundResolution.arrowColour = menuArrowColour
  roundResolution.outlineColour = menuOutlineColour
  roundResolution.changed = function(self)
    if self.value == 1 then
      numSteps = 64
    elseif self.value == 2 then
      numSteps = 32
    elseif self.value < 10 then
      numSteps = 16
    elseif self.value < 12 then
      numSteps = 8
    elseif self.value == 14 then
      numSteps = 4
    elseif self.value == 12 or self.value == 13 then
      numSteps = 3
    else
      numSteps = 2
    end
    positionTable.length = numSteps
  end

  local tweakOnOffButton = tweqPanel:OnOffButton("TweakOnOff", false)
  tweakOnOffButton.backgroundColourOff = "#ff084486"
  tweakOnOffButton.backgroundColourOn = "#ff02ACFE"
  tweakOnOffButton.textColourOff = "#ff22FFFF"
  tweakOnOffButton.textColourOn = "#efFFFFFF"
  tweakOnOffButton.fillColour = "#dd000061"
  tweakOnOffButton.displayName = "Live Tweaking"
  tweakOnOffButton.tooltip = "Activate live tweaking - updated each round"
  tweakOnOffButton.size = {rightMenuWidth,30}
  tweakOnOffButton.x = 200
  tweakOnOffButton.y = 160
  twequencerParameters.liveTweakButton = tweakOnOffButton

  local tweakDurationOnOffButton = tweqPanel:OnOffButton("TweakDurationOnOff", false)
  tweakDurationOnOffButton.backgroundColourOff = "#ff084486"
  tweakDurationOnOffButton.backgroundColourOn = "#ff02ACFE"
  tweakDurationOnOffButton.textColourOff = "#ff22FFFF"
  tweakDurationOnOffButton.textColourOn = "#efFFFFFF"
  tweakDurationOnOffButton.fillColour = "#dd000061"
  tweakDurationOnOffButton.displayName = "Tweak Over Time"
  tweakDurationOnOffButton.tooltip = "Tweak supported parameters over time"
  tweakDurationOnOffButton.size = {rightMenuWidth,30}
  tweakDurationOnOffButton.x = tweakOnOffButton.x + tweakOnOffButton.width + 25
  tweakDurationOnOffButton.y = tweakOnOffButton.y

  autoplayButton = tweqPanel:OnOffButton("AutoPlay", false)
  autoplayButton.backgroundColourOff = "#ff084486"
  autoplayButton.backgroundColourOn = "#ff02ACFE"
  autoplayButton.textColourOff = "#ff22FFFF"
  autoplayButton.textColourOn = "#efFFFFFF"
  autoplayButton.fillColour = "#dd000061"
  autoplayButton.displayName = "Auto Play"
  autoplayButton.tooltip = "Play automatically on transport"
  autoplayButton.size = {rightMenuWidth,30}
  autoplayButton.x = 200
  autoplayButton.y = tweakOnOffButton.y + tweakOnOffButton.height + 25

  playButton = tweqPanel:OnOffButton("Play", false)
  playButton.persistent = false
  playButton.backgroundColourOff = "#ff084486"
  playButton.backgroundColourOn = "#ff02ACFE"
  playButton.textColourOff = "#ff22FFFF"
  playButton.textColourOn = "#efFFFFFF"
  playButton.fillColour = "#dd000061"
  playButton.displayName = "Play"
  playButton.size = autoplayButton.size
  playButton.x = autoplayButton.x + autoplayButton.width + 25
  playButton.y = autoplayButton.y
  playButton.changed = function(self)
    if isPlaying == self.value then
      return
    end
    isPlaying = self.value
    if isPlaying then
      seqIndex = gem.inc(seqIndex)
      run(arpeg, seqIndex)
    else
      clearPosition()
    end
  end

  holdButton = tweqPanel:OnOffButton("HoldOnOff", false)
  holdButton.alpha = buttonAlpha
  holdButton.backgroundColourOff = buttonBackgroundColourOff
  holdButton.backgroundColourOn = buttonBackgroundColourOn
  holdButton.textColourOff = buttonTextColourOff
  holdButton.textColourOn = buttonTextColourOn
  holdButton.displayName = "Hold"
  holdButton.fillColour = knobColour
  holdButton.size = {rightMenuWidth,30}
  holdButton.x = 280
  holdButton.y = autoplayButton.y + autoplayButton.height + 25
  holdButton.changed = function(self)
    if self.value == false then
      releaseHeldNotes()
      clearPosition()
      isPlaying = false
      playButton:setValue(isPlaying, false)
    end
  end

  local scopeLabel = tweqPanel:Label("Tweak Categories")
  scopeLabel.x = positionTable.x
  scopeLabel.y = positionTable.y + positionTable.height + 5

  -- synthesis, modulation, filter, mixer, effects
  local synthesisButton = tweqPanel:OnOffButton("SeqSynthesis", true)
  synthesisButton.alpha = buttonAlpha
  synthesisButton.backgroundColourOff = buttonBackgroundColourOff
  synthesisButton.backgroundColourOn = buttonBackgroundColourOn
  synthesisButton.textColourOff = buttonTextColourOff
  synthesisButton.textColourOn = buttonTextColourOn
  synthesisButton.displayName = "Synthesis"
  synthesisButton.fillColour = knobColour
  synthesisButton.size = {138,30}
  synthesisButton.x = scopeLabel.x
  synthesisButton.y = scopeLabel.y + scopeLabel.height + 5

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

  function arpeg(uniqueId)
    local index = 0
    -- START ARP LOOP
    while isPlaying and seqIndex == uniqueId do
      -- SET VALUES
      local roundDuration = resolutions.getResolution(roundResolution.value)
      local stepDuration = roundDuration / numSteps
      local useDuration = tweakDurationOnOffButton.value
      local envelopeStyle = envStyleMenu.value
      local modulationStyle = modStyleMenu.value
      local currentPosition = (index % numSteps) + 1 -- 11 % 4 = 3
      local tweakablesForTwequencer = {}

      print("Current index:", index)
      print("Steps:", numSteps)
      print("Current step pos:", currentPosition)
      print("Snapshot pos:", snapshotPosition)
      print("Step duration:", stepDuration)
      print("Round duration:", roundDuration)

      -- ACTIONS FOR POSITION 1
      if index == 1 then
        -- CHECK FOR TWEAKLEVEL
        if tweakLevelKnob.value > 0 and tweakOnOffButton.value then
          tweakablesForTwequencer = helpers.getTweakables(tweakLevelKnob.value, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton, scopeMenu.value)
          if #tweakablesForTwequencer > 0 then
            -- Update snapshots menu
            snapshotsMenu.enabled = true
            prevSnapshotButton.enabled = true
            nextSnapshotButton.enabled = true
            --snapshotsMenu:setValue(snapshotPosition, false)
            
            -- Check for allowed waveforms
            -- local allowed = {"All", "Saw/Square", "Triangle/Sine", "Square/Triangle", "Saw/Sq/Tri/Sine", "Sine/Noise/Pulse", "Triangle/Sine/Pulse"}
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
              elseif allowedWaveforms == 6 then
                valueFilter = {4,5,6}
              elseif allowedWaveforms == 7 then
                valueFilter = {3,4,6}
              end
            end

            -- Tweak
            print("Tweaking tweakLevel/#tweakablesForTwequencer", tweakLevelKnob.value, #tweakablesForTwequencer)
            -- Get tweak suggestions
            for _,v in ipairs(tweakablesForTwequencer) do
              if string.match(v.widget.name, 'Osc%dWave') or v.widget.name == "SubOscWaveform" then
                v.valueFilter = valueFilter
              end
              v.targetValue = helpers.getTweakSuggestion(v, tweakLevelKnob.value, envelopeStyle, modulationStyle, stepDuration)
            end
            -- Verify tweak suggestions
            helpers.verifySettings(tweakLevelKnob.value, tweakablesForTwequencer, synthesisButton, modulationButton, filterButton, mixerButton, effectsButton)
            -- Store the tweaks
            storeRoundTweaks()
            -- Do the tweaking
            for _,v in ipairs(tweakablesForTwequencer) do
              spawn(helpers.tweakWidget, v, roundDuration, (useDuration == true and type(v.useDuration) == "boolean" and v.useDuration == true), tweakLevelKnob.value)
            end
          end
        end
      elseif tweakLevelKnob.value > 0 and tweakOnOffButton.value and useDuration and #heldNotes > 0 then
        storeRoundTweaks(true) -- Store live tweaks at each step when using duration
      end

      clearPosition()
      -- UPDATE POSITION TABLE
      positionTable:setValue(currentPosition, 1)
      -- UPDATE PART TABLE
      partsTable:setValue(1, 1)
      -- INCREMENT POSITION
      index = (index + 1) % numSteps -- increment position

      -- WAIT FOR NEXT BEAT
      waitBeat(stepDuration)
    end
  end

  function storeRoundTweaks(live)
    if type(live) == "nil" then
      live = false
    end
    if maxSnapshots > 0 then
      local snapshot = {}
      for _,v in ipairs(tweakables) do
        local value = v.targetValue
        if live then
          value = v.widget.value
        end
        table.insert(snapshot, {widget=v.widget,value=value})
      end
      table.remove(snapshots, snapshotPosition)
      table.insert(snapshots, snapshotPosition, snapshot)
      print("Updated snapshot at index:", snapshotPosition)
      if #snapshotsMenu.items < snapshotPosition then
        snapshotsMenu:addItem("Snapshot " .. snapshotPosition)
      else
        snapshotsMenu:setItem(snapshotPosition, "Snapshot " .. snapshotPosition)
      end
      snapshotsMenu:setValue(snapshotPosition, false)
      snapshotPosition = snapshotPosition + 1 -- increment snapshot position
      if snapshotPosition > maxSnapshots then
        snapshotPosition = 1
      end
    end
  end

  return tweqPanel
end

--------------------------------------------------------------------------------
-- Settings Panel
--------------------------------------------------------------------------------

local settingsPanel = Panel("Settings")
local settingsPageMenu = settingsPanel:Menu("SettingsPageMenu", {"synthesis", "filter", "modulation", "effects+mixer"})

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
        value = gem.getRandomBoolean()
      end
      btn.value = value
    end
  end

  local label = settingsPanel:Label("SettingsLabel")
  label.displayName = "TweakSynth Settings" -- Just used for holding the default text - not displayed directly
  label.text = label.displayName
  label.x = 0
  label.y = 0
  label.height = 25
  label.width = 240

  settingsPageMenu.width = 100
  settingsPageMenu.height = 25
  settingsPageMenu.x = 270
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
        v.button:setValue(gem.getRandomBoolean())
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
  closeButton.visible = false
  closeButton.persistent = false
  closeButton.displayName = "Close"
  closeButton.width = allOffButton.width
  closeButton.height = 25
  closeButton.y = label.y
  closeButton.x = settingsPanel.width - closeButton.width - 15
  closeButton.changed = function()
    selectedTweakable = nil
    settingsPageMenu:changed()
  end

  function getWidgetDisplayText(v, value)
    if type(value) == "nil" then
      value = v.widget.value
    end
    if v.widget.displayName == "Cutoff" then
      value = helpers.filterMapValue(value)
      if value < 1000 then
          return string.format("%0.1f Hz", value)
      else
          return string.format("%0.1f kHz", value/1000.)
      end
    elseif v.widget.name:sub(-3) == "Mix" then
      return helpers.formatGainInDb(value)
    elseif v.attack == true or v.release == true or v.decay == true then
      return helpers.formatTimeInSeconds(value)
    end
    return value
  end

  -- Options:
    -- widget = the widget to tweak - the only non-optional parameter
    -- func = the function to execute for getting the value - default is getRandom
    -- factor = a factor to multiply the random value with
    -- floor = the lowest value
    -- ceiling = the highest value
    -- probability = the probability (affected by tweak level) that value is within limits (floor/ceiling) - probability is passed to any custom func
    -- zero = the probability that the value is set to 0
    -- excludeWhenTweaking = this widget is skipped when tweaking
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
    
    -- Show closebutton
    closeButton.visible = true
    
    -- Show edit widgets
    selectedWidget.probabilityKnob.visible = true
    selectedWidget.floorKnob.visible = true
    selectedWidget.ceilKnob.visible = true
    selectedWidget.defaultKnob.visible = true
    selectedWidget.zeroKnob.visible = true
    selectedWidget.bipolarKnob.visible = true
    
    -- Set page label
    local currentValue = getWidgetDisplayText(selectedTweakable)
    label.text = selectedTweakable.widget.displayName .. " (" .. selectedTweakable.widget.name .. ") - Current value: " .. currentValue
    label.width = 600

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

    -- Toggle duration button
    selectedWidget.durationButton.visible = true
    selectedWidget.durationButton.x = selectedWidget.knob1.x + selectedWidget.knob1.width + 10
    selectedWidget.durationButton.y = selectedWidget.button.y
    selectedWidget.durationButton.size = {120,60}

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
    closeButton.visible = false
    settingsPageMenu.visible = true
    allOffButton.visible = true
    allOnButton.visible = true
    allRandButton.visible = true
    skipSetter.visible = true
    label.text = label.displayName
    label.width = 240
  end

  for i,v in ipairs(tweakables) do
    if type(v.skipProbability) ~= "number" then
      v.skipProbability = 0
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

    local exclude = type(v.excludeWhenTweaking) == "boolean" and v.excludeWhenTweaking == true
    local btn = settingsPanel:OnOffButton(v.widget.name .. 'Btn' .. i, (exclude == false))
    btn.displayName = v.widget.name
    btn.tooltip = "Activate/deactivate " .. v.widget.name .. " for tweaking"
    btn.alpha = buttonAlpha
    btn.visible = false
    btn.backgroundColourOff = buttonBackgroundColourOff
    btn.backgroundColourOn = buttonBackgroundColourOn
    btn.textColourOff = buttonTextColourOff
    btn.textColourOn = buttonTextColourOn
    btn.changed = function(self)
      v.excludeWhenTweaking = self.value == false
    end
    btn:changed()

    local useDuration = type(v.useDuration) == "boolean" and v.useDuration == true
    local durationButton = settingsPanel:OnOffButton(v.widget.name .. 'UseDuration' .. i, useDuration)
    durationButton.displayName = "Use duration"
    durationButton.tooltip = "Activate/deactivate tweak over time in twequencer"
    durationButton.alpha = buttonAlpha
    durationButton.visible = false
    durationButton.enabled = type(v.widget.default) == "number"
    durationButton.backgroundColourOff = buttonBackgroundColourOff
    durationButton.backgroundColourOn = buttonBackgroundColourOn
    durationButton.textColourOff = buttonTextColourOff
    durationButton.textColourOn = buttonTextColourOn
    durationButton.changed = function(self)
      v.useDuration = self.value
    end
    durationButton:changed()

    -- Widgets for details view
    local probabilityKnob = settingsPanel:Knob('ProbabilityKnob' .. i, 0, 0, 100, true)
    probabilityKnob.unit = Unit.Percent
    probabilityKnob.visible = false
    probabilityKnob.displayName = "Probability"
    probabilityKnob.fillColour = knobColour
    probabilityKnob.size = {200,60}

    local defaultKnob = settingsPanel:Knob('DefaultKnob' .. i, 0, 0, 100, true)
    defaultKnob.unit = Unit.Percent
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
      v.default = self.value
    end
    defaultKnob:changed()

    local zeroKnob = settingsPanel:Knob('ZeroKnob' .. i, 0, 0, 100, true)
    zeroKnob.unit = Unit.Percent
    zeroKnob.visible = false
    zeroKnob.displayName = "Probability of zero"
    zeroKnob.tooltip = "Probability of zero (0) being set"
    zeroKnob.fillColour = knobColour
    zeroKnob.size = probabilityKnob.size
    if type(v.zero) == "number" then
      --print("zero", v.zero)
      zeroKnob.value = v.zero
      zeroKnob.changed = function(self)
        v.zero = self.value
      end
      zeroKnob:changed()
    else
      zeroKnob.enabled = false
    end

    local bipolarKnob = settingsPanel:Knob('BipolarKnob' .. i, 0, 0, 100, true)
    bipolarKnob.unit = Unit.Percent
    bipolarKnob.visible = false
    bipolarKnob.displayName = "Bipolar probability"
    bipolarKnob.tooltip = "Probability of value being changed to negative for bipolar controllers"
    bipolarKnob.fillColour = knobColour
    bipolarKnob.size = probabilityKnob.size
    if type(v.bipolar) == "number" then
      --print("bipolar", v.bipolar)
      bipolarKnob.value = v.bipolar
      bipolarKnob.changed = function(self)
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
      probabilityKnob.tooltip = "Probability that value is within limits (floor/ceiling)"
      probabilityKnob.value = v.probability
      probabilityKnob.changed = function(self)
        v.probability = self.value
      end
      probabilityKnob:changed()
    end

    local isInteger = v.integer == true

    local floorKnob = settingsPanel:Knob('FloorKnob' .. i, default, min, max, isInteger)
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
      floorKnob.unit = v.widget.unit
      floorKnob.changed = function(self)
        v.floor = self.value
        local displayText = getWidgetDisplayText(v, self.value)
        if type(displayText) == "string" then
          self.displayText = displayText
        end
      end
      floorKnob:changed()
    end

    local ceilKnob = settingsPanel:Knob('CeilKnob' .. i, max, min, max, isInteger)
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
      ceilKnob.unit = v.widget.unit
      ceilKnob.changed = function(self)
        v.ceiling = self.value
        local displayText = getWidgetDisplayText(v, self.value)
        if type(displayText) == "string" then
          self.displayText = displayText
        end
      end
      ceilKnob:changed()
    end

    table.insert(widgets, {
      button=btn,
      durationButton=durationButton,
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
      v.durationButton.visible = false
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
  end

  settingsPageMenu:changed()
end

createSettingsPanel()

--------------------------------------------------------------------------------
-- Set up pages
--------------------------------------------------------------------------------

local pageSetupFn = {}

pageSetupFn.setupSynthesisPage = function()
  local synthesisHeight = height * 1.25

  if osc3Panel then
    synthesisHeight = height
  elseif synthTypes.isDrum then
    synthesisHeight = height * 1.5
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

  if synthTypes.isDrum then
    synthesisHeight = height
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

pageSetupFn.setupFilterPage = function()
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

pageSetupFn.setupModulationPage = function()
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

pageSetupFn.setupEffectsPage = function()
  effectsPanel.backgroundColour = bgColor
  effectsPanel.x = marginX
  effectsPanel.y = marginY
  effectsPanel.width = width
  effectsPanel.height = 310
end

for _,v in pairs(pageSetupFn) do
  v()
end

local tweqPanel = panelCreators.createTwequencerPanel()
local tweakPanel = panelCreators.createPatchMakerPanel()

--------------------------------------------------------------------------------
-- Map Midi CC for HW (Minilogue)
--------------------------------------------------------------------------------

local function mapMinilogueCC()
  local activeLfoTarget = {cutoff = true, pwm = false, hardsync = false}
  local activeLfoTargetValue = 64

  function controllerValueToWidgetValue(controllerValue, bipolar, factor, env)
    local max = 127
    if env == true then
      return 10 * ((controllerValue / max) ^ 4)
    end
    if bipolar == 1 then
      max = max / 2
    else
      bipolar = 0
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
    if synthTypes.isFM or synthTypes.isAnalog3Osc or synthTypes.isAnalogStack then
      return
    end

    local bipolar = 1
    local factor = 1

    if activeLfoTarget.cutoff == true then
      helpers.getWidget("LfoToCutoff").value = controllerValueToWidgetValue(activeLfoTargetValue, bipolar, factor)
    else
      helpers.getWidget("LfoToCutoff").value = 0
    end
    
    local pwmKey = "OscPWM"
    if synthTypes.isDrum then
      pwmKey = "NoiseMix"
      bipolar = 1
    else
      bipolar = 0
      factor = 0.5
    end
    if activeLfoTarget.pwm == true then
      helpers.getWidget("LfoTo" .. pwmKey .. "1").value = controllerValueToWidgetValue(activeLfoTargetValue, bipolar, factor)
      helpers.getWidget("LfoTo" .. pwmKey .. "2").value = controllerValueToWidgetValue(activeLfoTargetValue, bipolar, factor)
    else
      helpers.getWidget("LfoTo" .. pwmKey .. "1").value = 0
      helpers.getWidget("LfoTo" .. pwmKey .. "2").value = 0
    end

    local hardsyncKey = "Hardsync"
    bipolar = 0
    factor = 1
    if synthTypes.isAdditive then
      hardsyncKey = "EvenOdd"
    elseif synthTypes.isWavetable then
      hardsyncKey = "WaveIndex"
      bipolar = 1
    elseif synthTypes.isDrum then
      hardsyncKey = "OscFreq"
      bipolar = 1
    end
    if activeLfoTarget.hardsync == true then
      helpers.getWidget("LfoTo" .. hardsyncKey .. "1").value = controllerValueToWidgetValue(activeLfoTargetValue, bipolar, factor)
      helpers.getWidget("LfoTo" .. hardsyncKey .. "2").value = controllerValueToWidgetValue(activeLfoTargetValue, bipolar, factor)
    else
      helpers.getWidget("LfoTo" .. hardsyncKey .. "1").value = 0
      helpers.getWidget("LfoTo" .. hardsyncKey .. "2").value = 0
    end
  end

  function onController(e)
    -- TODO Add option for using patchemaker or twequencer when setting tweak level/tweak on/off
    print(e)
    local controllerToWidgetMap = {
      CC16 = {name = "Attack", env=true, page = synthesisPageButton},
      CC17 = {name = "Decay", env=true, page = synthesisPageButton},
      CC18 = {name = "Sustain", page = synthesisPageButton},
      CC19 = {name = "Release", env=true, page = synthesisPageButton},
      CC20 = {name = "FAttack", env=true, page = filterPageButton},
      CC21 = {name = "FDecay", env=true, page = filterPageButton},
      CC22 = {name = "FSustain", page = filterPageButton},
      CC23 = {name = "FRelease", env=true, page = filterPageButton},
      CC24 = {name = "LfoFreq", page = modulationPageButton, factor = 20}, -- LFO RATE
      CC26 = {name = "LfoToTarget", page = modulationPageButton}, -- LFO INT
      CC27 = {name = "Drive", page = effectsPageButton}, -- Voice Mode Depth > Drive
      CC29 = {name = "HpfCutoff", page = filterPageButton}, -- HI PASS CUTOFF
      CC30 = {name = "HpfEnvelopeAmt", bipolar = 1, page = filterPageButton}, -- TIME
      CC31 = {name = "TweakLevel", factor = 100}, -- FEEDBACK > Tweak level
      CC33 = {name = "NoiseMix"}, -- NOISE
      CC34 = {name = "Osc1StartPhase", page = synthesisPageButton}, -- VCO 1 PITCH > Start Phase 1
      CC35 = {name = "Osc2FinePitch", page = synthesisPageButton}, -- VCO 2 PITCH > Fine pitch
      CC36 = {name = "HardsyncOsc1", page = synthesisPageButton, factor = 36}, -- VCO1 SHAPE > Hardsync 1
      CC37 = {name = "HardsyncOsc2", page = synthesisPageButton, factor = 36}, -- VCO2 SHAPE > Hardsync 2
      CC39 = {name = "Osc1Mix"}, -- VCO1
      CC40 = {name = "Osc2Mix"}, -- VCO2
      CC41 = {name = "FilterEnvToHardsync1", page = filterPageButton}, -- CROSS MOD DEPTH > Osc 1 Hardsync FEnv Amt
      CC42 = {name = "FilterEnvToHardsync2", page = filterPageButton}, -- PITCH EG INT > Osc 2 Hardsync FEnv Amt
      CC43 = {name = "Cutoff", page = filterPageButton}, -- CUTOFF > Cutoff
      CC44 = {name = "Resonance", page = filterPageButton}, -- RESONANCE > Resonance
      CC45 = {name = "EnvelopeAmt", bipolar = 1, page = filterPageButton}, -- EG INT > Cutoff filter env amount
      CC48 = {name = "Osc1Pitch", page = synthesisPageButton}, -- VCO 1 OCTAVE
      CC49 = {name = "Osc2Pitch", page = synthesisPageButton}, -- VCO 2 OCTAVE
      CC50 = {name = "Osc1Wave", page = synthesisPageButton}, -- VCO 1 WAVE
      CC51 = {name = "Osc2Wave", page = synthesisPageButton}, -- VCO 2 WAVE
      CC56 = {name = "ActiveLfoTargetSelector", page = modulationPageButton}, -- TARGET
      CC57 = {name = "LfoRetrigger", page = modulationPageButton}, -- EG MOD > LFO Retrigger/Sync
      CC58 = {name = "WaveFormTypeMenu", page = modulationPageButton}, -- LFO WAVE
      CC80 = {name = "VibratoDepth", page = synthesisPageButton}, -- RING
      CC81 = {name = "Arp"}, -- SYNC > Arp on/off
      CC82 = {name = "VelocityToFilterEnv", page = filterPageButton, factor = 20}, -- VELOCITY
      CC83 = {name = "KeyTracking", page = filterPageButton}, -- KEY TRACK
      CC84 = {name = "FilterDb", page = filterPageButton}, -- 2/4-POLE
      CC88 = {name = "Tweak"} -- OUTPUT ROUTING > Tweak button
    }

    if isPlaying then
      controllerToWidgetMap.CC31.page = twequencerPageButton
      controllerToWidgetMap.CC88.page = twequencerPageButton
    else
      controllerToWidgetMap.CC31.page = patchmakerPageButton
      controllerToWidgetMap.CC88.page = patchmakerPageButton
    end

    if synthTypes.isWavetable then
      controllerToWidgetMap.CC36 = {name = "Osc1WaveIndex", page = synthesisPageButton} -- VCO1 SHAPE -> Osc 1 Wave Index
      controllerToWidgetMap.CC37 = {name = "Osc2WaveIndex", page = synthesisPageButton} -- VCO2 SHAPE -> Osc 2 Wave Index
      controllerToWidgetMap.CC41 = {name = "Osc1FilterEnvToIndex", bipolar = 1, page = filterPageButton} -- CROSS MOD DEPTH > Osc 1 Hardsync FEnv Amt
      controllerToWidgetMap.CC42 = {name = "Osc2FilterEnvToIndex", bipolar = 1, page = filterPageButton} -- PITCH EG INT > Osc 2 Hardsync FEnv Amt
      controllerToWidgetMap.CC50 = {name = "Reverb", factor = 0.3, page = effectsPageButton} -- VCO 1 WAVE
      controllerToWidgetMap.CC51 = {name = "Delay", factor = 0.3, page = effectsPageButton} -- VCO 2 WAVE
    elseif synthTypes.isAdditive then
      controllerToWidgetMap.CC34 = {name = "HarmShift1", factor=48, page = synthesisPageButton} -- VCO 1 PITCH > HarmShift1
      controllerToWidgetMap.CC36 = {name = "Osc1Partials", factor=256, page = synthesisPageButton} -- VCO1 SHAPE -> Osc 1 Partials
      controllerToWidgetMap.CC37 = {name = "Osc2Partials", factor=256, page = synthesisPageButton} -- VCO2 SHAPE -> Osc 2 Partials
      controllerToWidgetMap.CC41 = {name = "Osc1Cutoff", bipolar=1, page = synthesisPageButton} -- CROSS MOD DEPTH > Osc 1 Even/Odd
      controllerToWidgetMap.CC42 = {name = "Osc2Cutoff", bipolar=1, page = synthesisPageButton}-- PITCH EG INT > Osc 2 Even/Odd
      controllerToWidgetMap.CC50 = {name = "Osc1EvenOdd", bipolar=1, page = synthesisPageButton} -- VCO 1 WAVE > Osc 1 Even/Odd
      controllerToWidgetMap.CC51 = {name = "Osc2EvenOdd", bipolar=1, page = synthesisPageButton}-- VCO 2 WAVE > Osc 2 Even/Odd
    elseif synthTypes.isDrum then
      controllerToWidgetMap.CC16 = {name = "Osc1Attack", env=true, page = synthesisPageButton}
      controllerToWidgetMap.CC17 = {name = "Osc1Decay", env=true, page = synthesisPageButton}
      controllerToWidgetMap.CC18 = {name = "Osc2Attack", env=true, page = synthesisPageButton}
      controllerToWidgetMap.CC19 = {name = "Osc2Decay", env=true, page = synthesisPageButton}
      controllerToWidgetMap.CC34 = {name = "Osc1PitchModRate", page = synthesisPageButton} -- VCO 1 PITCH > Osc 1 Mod Rate
      controllerToWidgetMap.CC35 = {name = "Osc2PitchModRate", page = synthesisPageButton} -- VCO 2 PITCH > Osc 2 Mod Rate
      controllerToWidgetMap.CC36 = {name = "Osc1PitchModAmount", bipolar=1, factor=96, page = synthesisPageButton} -- VCO1 SHAPE -> Osc 1 Mod Amt
      controllerToWidgetMap.CC37 = {name = "Osc2PitchModAmount", bipolar=1, factor=96, page = synthesisPageButton} -- VCO2 SHAPE -> Osc 2 Mod Amt
      controllerToWidgetMap.CC41 = {name = "Osc1Distortion", page = synthesisPageButton} -- CROSS MOD DEPTH > Osc 1 Distortion
      controllerToWidgetMap.CC42 = {name = "Osc2Distortion", page = synthesisPageButton}-- PITCH EG INT > Osc 2 Distortion
    end

    local key = "CC" .. e.controller
    local cc = controllerToWidgetMap[key]

    if cc then
      if cc.page then
        cc.page:setValue(true)
      end
      local value = controllerValueToWidgetValue(e.value, cc.bipolar, cc.factor, (cc.env==true))
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
      if cc.name == "LfoToTarget" then
        activeLfoTargetValue = e.value
        setLfoTargetValue()
        return
      end
      if cc.name == "TweakLevel" then
        if isPlaying then
          twequencerParameters.tweakLevelKnob.value = value
        else
          storeNewSnapshot()
          patchmakerParameters.tweakLevelKnob.value = value
        end
        return
      end
      if cc.name == "Tweak" then
        if value == 1 then
          helpers.initPatch()
        else
          if isPlaying then
            twequencerParameters.liveTweakButton:setValue(value == .5)
          else
            storeNewSnapshot()
            patchmakerParameters.tweakButton:push(true)
          end
        end
        return
      end
      if cc.name == "LfoRetrigger" then
        local retrigger = helpers.getWidget("Lfo2Trigger")
        local sync = helpers.getWidget("Lfo2Sync")
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
        if synthTypes.isDrum then
          if value == 0 then
            value = 4
          elseif value < 1 then
            value = 2
          else
            value = 3
          end
        else
          if value == 0 then
            value = 2
          elseif value < 1 then
            value = 3
          end
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
      local widget = helpers.getWidget(cc.name)
      print("Widget type:", type(widget))
      if type(widget) == "userdata" then
        widget.value = value
      end
      return
    end

    postEvent(e)
  end
end

-- TODO Add a button in settings for disabling mapping
mapMinilogueCC()

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
  end
end

synthesisPageButton.changed = function(self)
  self:setValue(true, false)
  filterPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(1)
end

filterPageButton.changed = function(self)
  self:setValue(true, false)
  synthesisPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(2)
end

modulationPageButton.changed = function(self)
  self:setValue(true, false)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(3)
end

twequencerPageButton.changed = function(self)
  self:setValue(true, false)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(4)
end

patchmakerPageButton.changed = function(self)
  self:setValue(true, false)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  effectsPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(5)
end

effectsPageButton.changed = function(self)
  self:setValue(true, false)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  settingsPageButton:setValue(false, false)
  setPage(6)
end

settingsPageButton.changed = function(self)
  self:setValue(true, false)
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

setSize(720, 480)

setBackgroundColour("#000066")
setBackground("../resources/bluesquares.png")

makePerformanceView()

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
end

function onNote(e)
  if holdButton.value == true then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        if #heldNotes > 1 then
          table.remove(heldNotes, i)
        end
        break
      end
    end
  end
  table.insert(heldNotes, e)
  postEvent(e)
end

function onRelease(e)
  if holdButton.value == false then
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        table.remove(heldNotes, i)
      end
    end
    postEvent(e)
  end
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- STORE / RECALL
--------------------------------------------------------------------------------

function onSave()
  local data = {}

  -- Store patch tweaks
  storedPatch = {}
  for i,v in ipairs(tweakables) do
    table.insert(storedPatch, {index=i,widget=v.widget.name,value=v.widget.value})
    print("Saved: ", v.widget.name, v.widget.value)
  end
  table.insert(data, storedPatch)

  -- Stored patches
  table.insert(data, storedPatches)

  -- Twequencer snapshots
  table.insert(data, snapshots)

  return data
end

function onLoad(data)
  -- Load stored patch
  storedPatch = data[1]
  helpers.recallStoredPatch()

  -- Load stored patches
  if type(data[2]) ~= "nil" then
    storedPatches = data[2]
    if #storedPatches > 0 then
      helpers.populatePatchesMenu()
      print("Loaded stored patches: ", #storedPatches)
    end
  end

  -- Load snapshots
  if type(data[3]) ~= "nil" then
    snapshots = data[3]
    if #snapshots > 0 then
      for i,v in ipairs(snapshots) do
        snapshotsMenu:addItem("Snapshot " .. i)
      end
      snapshotPosition = #snapshots + 1 -- set snapshot position
      snapshotsMenu.enabled = true
      print("Loaded snapshots: ", #snapshots)
    end
  end
end
