--------------------------------------------------------------------------------
-- Simple Synth
--------------------------------------------------------------------------------

-- KEYGROUPS
local osc1Keygroup = Program.layers[1].keygroups[1]
local osc2Keygroup = Program.layers[2].keygroups[1]
local noiseKeygroup = Program.layers[3].keygroups[1]

-- OSCILLATORS
--local osc1 = osc1Keygroup.oscillators[1]
--local osc2 = osc2Keygroup.oscillators[1]
local noiseOsc = noiseKeygroup.oscillators[1]

-- MODULATORS
local lfo1 = Program.modulations["LFO 1"] -- Vibrato
local lfo2 = Program.modulations["LFO 2"] -- Modulation
local ampEnv1 = osc1Keygroup.modulations["Amp. Env"]
local ampEnv2 = osc2Keygroup.modulations["Amp. Env"]
local ampEnvNoise = noiseKeygroup.modulations["Amp. Env"]
local filterEnv1 = osc1Keygroup.modulations["Analog ADSR 1"]
local filterEnv2 = osc2Keygroup.modulations["Analog ADSR 1"]
local filterEnvNoise = noiseKeygroup.modulations["Analog ADSR 1"]

-- MACROS
local osc1Shape = Program.modulations["Macro 1"]
local filterCutoff = Program.modulations["Macro 2"]
local filterEnvAmount = Program.modulations["Macro 3"]
local filterAttack = Program.modulations["Macro 4"]
local filterDecay = Program.modulations["Macro 5"]
local filterSustain = Program.modulations["Macro 6"]
local filterRelease = Program.modulations["Macro 7"]
local osc1Mix = Program.modulations["Macro 8"]
local osc2Shape = Program.modulations["Macro 9"]
local osc2Mix = Program.modulations["Macro 10"]
local osc2Detune = Program.modulations["Macro 11"]
local osc2Pitch = Program.modulations["Macro 12"]
local filterResonance = Program.modulations["Macro 13"]
local delayMix = Program.modulations["Macro 14"]
local reverbMix = Program.modulations["Macro 15"]
local arpeggiator = Program.modulations["Macro 16"]
local ampAttack = Program.modulations["Macro 17"]
local ampDecay = Program.modulations["Macro 18"]
local ampSustain = Program.modulations["Macro 19"]
local ampRelease = Program.modulations["Macro 20"]
local chorusMix = Program.modulations["Macro 21"]
local wheelToCutoff = Program.modulations["Macro 22"]
local driveAmount = Program.modulations["Macro 23"]
local atToCutoff = Program.modulations["Macro 24"]
local vibratoAmount = Program.modulations["Macro 25"]
local atToVibrato = Program.modulations["Macro 26"]
local osc1LfoToPwm = Program.modulations["Macro 27"]
local osc2LfoToPwm = Program.modulations["Macro 28"]
local wheelToVibrato = Program.modulations["Macro 29"]
local filterKeyTracking = Program.modulations["Macro 30"]
local lfoToCutoff = Program.modulations["Macro 31"]
local unisonDetune = Program.modulations["Macro 32"]
local vibratoRate = Program.modulations["Macro 33"]
local unisonVoices = Program.modulations["Macro 34"]
local maximizer = Program.modulations["Macro 35"]
local noiseMix = Program.modulations["Macro 36"]
local lfoToAmp = Program.modulations["Macro 37"]

--------------------------------------------------------------------------------
-- Colours
--------------------------------------------------------------------------------

local knobColour = "#333333"
local osc1Colour = "orange"
local osc2Colour = "yellow"
local unisonColour = "magenta"
local filterColour = "green"
local lfoColour = "pink"
local filterEnvColour = "red"
local ampEnvColour = "teal"
local filterEffectsColour = "blue"
local pitchColour = "lightblue"

--------------------------------------------------------------------------------
-- Shape maps
--------------------------------------------------------------------------------

function basicShapes(value)
    -- Basic Shapes
    if value < 0.14 then
      return "Sine"
    elseif value < 0.28 then
      return "Saw"
    elseif value < 0.43 then
      return "Tri"
    elseif value < 0.57 then
      return "Square"
    elseif value < 0.72 then
      return "Pulse"
    elseif value < 0.86 then
      return "NarrowPulse"
    else
      return "Saw+Square"
    end  
end

function basicMini(value)
  -- Basic Mini
  if value < 0.25 then
    return "Saw"
  elseif value < 0.5 then
    return "Tri"
  elseif value < 0.75 then
    return "Square"
  else
    return "Pulse"
  end
end

function miniWaveforms(value)
  -- Mini Waveforms
  if value < 0.17 then
    return "Tri/Saw"
  elseif value < 0.34 then
    return "Tri"
  elseif value < 0.5 then
    return "Saw"
  elseif value < 0.67 then
    return "Square"
  elseif value < 0.83 then
    return "Pulse"
  else
    return "NarrowPulse"
  end
end

function sub37Waveforms(value)
  -- Sub 37 - Tri-Saw-Square
  if value < 0.3 then
    return "Tri"
  elseif value < 0.65 then
    return "Saw"
  else
    return "Square"
  end
end

function percent(value)
  return string.format("%0.1f %%", value*100)
end

--------------------------------------------------------------------------------
-- Osc 1
--------------------------------------------------------------------------------

local osc1Panel = Panel("Osc1Panel")

local osc1ShapeKnob = osc1Panel:Knob("Osc1", 0, 0, 1)
osc1ShapeKnob.displayName = "Osc 1"
osc1ShapeKnob.fillColour = knobColour
osc1ShapeKnob.outlineColour = osc1Colour
osc1ShapeKnob.changed = function(self)
  osc1Shape:setParameter("Value", self.value)
  self.displayText = basicMini(self.value)
  --self.displayText = basicShapes(self.value)
  --self.displayText = sub37Waveforms(self.value)
  --self.displayText = miniWaveforms(self.value)
  --self.displayText = percent(self.value)
end
osc1ShapeKnob:changed()

local osc1LfoToPwmKnob = osc1Panel:Knob("Osc1LfoToPwm", 0, 0, 0.5)
osc1LfoToPwmKnob.displayName = "LFO->PWM"
osc1LfoToPwmKnob.mapper = Mapper.Quartic
osc1LfoToPwmKnob.fillColour = knobColour
osc1LfoToPwmKnob.outlineColour = lfoColour
osc1LfoToPwmKnob.changed = function(self)
  osc1LfoToPwm:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
osc1LfoToPwmKnob:changed()

--------------------------------------------------------------------------------
-- Osc 2
--------------------------------------------------------------------------------

local osc2Panel = Panel("Osc2Panel")

local osc2ShapeKnob = osc2Panel:Knob("Osc2", 0, 0, 1)
osc2ShapeKnob.displayName = "Osc 2"
osc2ShapeKnob.fillColour = knobColour
osc2ShapeKnob.outlineColour = osc2Colour
osc2ShapeKnob.changed = function(self)
  osc2Shape:setParameter("Value", self.value)
  self.displayText = basicMini(self.value)
  --self.displayText = basicShapes(self.value)
  --self.displayText = sub37Waveforms(self.value)
  --self.displayText = miniWaveforms(self.value)
  --self.displayText = percent(self.value)
end
osc2ShapeKnob:changed()

local osc2LfoToPwmKnob = osc2Panel:Knob("Osc2LfoToPwm", 0, 0, 0.5)
osc2LfoToPwmKnob.displayName = "LFO->PWM"
osc2LfoToPwmKnob.mapper = Mapper.Quartic
osc2LfoToPwmKnob.fillColour = knobColour
osc2LfoToPwmKnob.outlineColour = lfoColour
osc2LfoToPwmKnob.changed = function(self)
  osc2LfoToPwm:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
osc2LfoToPwmKnob:changed()

local osc2DetuneKnob = osc2Panel:Knob("Osc2FinePitch", 0, 0, 1)
osc2DetuneKnob.displayName = "Fine Pitch"
osc2DetuneKnob.fillColour = knobColour
osc2DetuneKnob.outlineColour = osc2Colour
osc2DetuneKnob.changed = function(self)
  osc2Detune:setParameter("Value", self.value)
end
osc2DetuneKnob:changed()

local osc2PitchKnob = osc2Panel:Knob("Osc2Pitch", 0, -24, 24, true)
osc2PitchKnob.displayName = "Pitch"
osc2PitchKnob.fillColour = knobColour
osc2PitchKnob.outlineColour = osc2Colour
osc2PitchKnob.changed = function(self)
  local factor = 1 / 48;
  local value = (self.value * factor) + 0.5;
  osc2Pitch:setParameter("Value", value)
end
osc2PitchKnob:changed()

--------------------------------------------------------------------------------
-- Unison
--------------------------------------------------------------------------------

local unisonPanel = Panel("UnisonPanel")

--local unisonLabel = unisonPanel:Label("Unison")

local unisonVoicesKnob = unisonPanel:Knob("UnisonVoices", 1, 1, 8, true)
unisonVoicesKnob.displayName = "Unison"
unisonVoicesKnob.fillColour = knobColour
unisonVoicesKnob.outlineColour = unisonColour
unisonVoicesKnob.changed = function(self)
  local factor = 1 / 8
  local value = factor * self.value
  unisonVoices:setParameter("Value", value)
  if self.value == 1 then
    self.displayText = "Off"
    noiseOsc:setParameter("Stereo", false)
  else
    self.displayText = tostring(self.value)
    noiseOsc:setParameter("Stereo", true)
  end
end
unisonVoicesKnob:changed()

local unisonDetuneKnob = unisonPanel:Knob("UnisonDetune", 0.1, 0, 1)
unisonDetuneKnob.displayName = "Detune"
unisonDetuneKnob.fillColour = knobColour
unisonDetuneKnob.outlineColour = unisonColour
unisonDetuneKnob.changed = function(self)
  unisonDetune:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
unisonDetuneKnob:changed()

--------------------------------------------------------------------------------
-- Mixer
--------------------------------------------------------------------------------

function formatGainInDb(value)
  if value == 0 then
      return "-inf"
  else
      local dB = 20 * math.log10(value)
      return string.format("%0.1f dB", dB)
  end
end

local mixerPanel = Panel("Mixer")

local mixerLabel = mixerPanel:Label("Mixer")

local osc1MixKnob = mixerPanel:Knob("Osc1Mix", 0.75, 0, 1)
osc1MixKnob.displayName = "Osc 1"
osc1MixKnob.fillColour = knobColour
osc1MixKnob.outlineColour = osc1Colour
osc1MixKnob.changed = function(self)
  osc1Mix:setParameter("Value", self.value)
  self.displayText = formatGainInDb(self.value)
end
osc1MixKnob:changed()

local osc2MixKnob = mixerPanel:Knob("Osc2Mix", 0, 0, 1)
osc2MixKnob.displayName = "Osc 2"
osc2MixKnob.fillColour = knobColour
osc2MixKnob.outlineColour = osc2Colour
osc2MixKnob.changed = function(self)
  osc2Mix:setParameter("Value", self.value)
  self.displayText = formatGainInDb(self.value)
end
osc2MixKnob:changed()

local noiseMixKnob = mixerPanel:Knob("NoiseMix", 0, 0, 1)
noiseMixKnob.displayName = "Noise"
noiseMixKnob.fillColour = knobColour
noiseMixKnob.outlineColour = osc2Colour
noiseMixKnob.changed = function(self)
  noiseMix:setParameter("Value", self.value)
  self.displayText = formatGainInDb(self.value)
end
noiseMixKnob:changed()

local noiseTypes = {"Band", "S&H", "Static1", "Static2", "Violet", "Blue", "White", "Pink", "Brown", "Lorenz", "Rossler", "Crackle", "Logistic", "Dust", "Velvet"}
local noiseTypeMenu = mixerPanel:Menu("NoiseTypeMenu", noiseTypes)
noiseTypeMenu.displayName = "Noise Type"
noiseTypeMenu.selected = 7
noiseTypeMenu.changed = function(self)
  local value = self.value - 1
  noiseOsc:setParameter("NoiseType", value)
  --print("menu selection changed:", value, self.selectedText)
end
noiseTypeMenu:changed()

local maximizerButton = mixerPanel:OnOffButton("Maximizer", false)
maximizerButton.fillColour = knobColour
maximizerButton.outlineColour = filterEffectsColour
maximizerButton.width = 75
maximizerButton.changed = function(self)
  local value = -1
  if (self.value == true) then
    value = 1
  end
  maximizer:setParameter("Value", value)
end
maximizerButton:changed()

--------------------------------------------------------------------------------
-- Filter
--------------------------------------------------------------------------------

-- logarithmic mapping for filter cutoff
local filterMax = 20000.
local filterMin = 20.
local filterlogmax = math.log(filterMax)
local filterlogmin = math.log(filterMin)
local filterlogrange = filterlogmax-filterlogmin
function filterMapValue(value)
    local newValue = (value * filterlogrange) + filterlogmin
    value = math.exp(newValue)
    return value
end

local filterPanel = Panel("Filter")

--local filterLabel = filterPanel:Label("Lowpass Filter")

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

local filterResonanceKnob = filterPanel:Knob("Resonance", 0, 0, 1)
filterResonanceKnob.fillColour = knobColour
filterResonanceKnob.outlineColour = filterColour
filterResonanceKnob.changed = function(self)
  filterResonance:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
filterResonanceKnob:changed()

local filterKeyTrackingKnob = filterPanel:Knob("KeyTracking", 0, 0, 1)
filterKeyTrackingKnob.displayName = "Key Track"
filterKeyTrackingKnob.fillColour = knobColour
filterKeyTrackingKnob.outlineColour = filterColour
filterKeyTrackingKnob.changed = function(self)
  filterKeyTracking:setParameter("Value", self.value)
end
filterKeyTrackingKnob:changed()

local wheelToCutoffKnob = filterPanel:Knob("WheelToCutoff", 0, -1, 1)
wheelToCutoffKnob.displayName = "Modwheel"
wheelToCutoffKnob.fillColour = knobColour
wheelToCutoffKnob.outlineColour = filterColour
wheelToCutoffKnob.changed = function(self)
  local value = (self.value + 1) * 0.5
  wheelToCutoff:setParameter("Value", value)
  --print("Value set:", value)
  self.displayText = string.format("%0.1f %%", (self.value * 100))
end
wheelToCutoffKnob:changed()

local atToCutoffKnob = filterPanel:Knob("AftertouchToCutoff", 0, -1, 1)
atToCutoffKnob.displayName = "Aftertouch"
atToCutoffKnob.fillColour = knobColour
atToCutoffKnob.outlineColour = filterColour
atToCutoffKnob.changed = function(self)
  local value = (self.value + 1) * 0.5
  atToCutoff:setParameter("Value", value)
  --print("Value set:", value)
  self.displayText = string.format("%0.1f %%", (self.value * 100))
end
atToCutoffKnob:changed()

local envAmtKnob = filterPanel:Knob("EnvelopeAmt", 0, -1, 1)
envAmtKnob.displayName = "Envelope"
envAmtKnob.fillColour = knobColour
envAmtKnob.outlineColour = filterColour
envAmtKnob.changed = function(self)
  local value = (self.value + 1) * 0.5
  filterEnvAmount:setParameter("Value", value)
  --print("Value set:", value)
  self.displayText = string.format("%0.1f %%", (self.value * 100))
end
envAmtKnob:changed()

--------------------------------------------------------------------------------
-- LFO
--------------------------------------------------------------------------------

local lfoPanel = Panel("Lfo")
--local lfoLabel = lfoPanel:Label("LFO")

local waveFormTypes = {"Sinus", "Square", "Triangle", "Ramp Up", "Ramp Down", "Analog Square", "S&H", "Chaos Lorenz", "Chaos Rossler"}
local waveFormTypeMenu = lfoPanel:Menu("WaveFormTypeMenu", waveFormTypes)
waveFormTypeMenu.displayName = "LFO"
waveFormTypeMenu.selected = 3
waveFormTypeMenu.changed = function(self)
  local value = self.value - 1
  lfo2:setParameter("WaveFormType", value)
  --print("menu selection changed:", value, self.selectedText)
end
waveFormTypeMenu:changed()

local lfoFreqKnob = lfoPanel:Knob("LfoFreq", 4.5, 0.1, 20.)
lfoFreqKnob.displayName = "LFO Freq"
lfoFreqKnob.fillColour = knobColour
lfoFreqKnob.outlineColour = lfoColour

function getDotted(value)
  return value + (value / 2)
end

function getTriplet(value)
  return value  / 3
end

local lfo2SyncButton = lfoPanel:OnOffButton("Lfo2Sync", false)
lfo2SyncButton.displayName = "Sync"
lfo2SyncButton.fillColour = knobColour
lfo2SyncButton.outlineColour = lfoColour
lfo2SyncButton.width = 75
lfo2SyncButton.changed = function(self)
  lfo2:setParameter("SyncToHost", self.value)
  if self.value == false then
    lfoFreqKnob.default = 4.5
    lfoFreqKnob.mapper = Mapper.Quadratic
    lfoFreqKnob.changed = function(self)
      lfo2:setParameter("Freq", self.value)
      self.displayText = string.format("%0.2f Hz", self.value)
    end
    lfoFreqKnob:changed()
  else
    lfoFreqKnob.default = 11
    lfoFreqKnob.mapper = Mapper.Linear
    lfoFreqKnob.changed = function(self)
      local resolutions =     { 32,   24,   16,  12,    8,     6,         4,      3,       2, getTriplet(4), getDotted(1), 1, getTriplet(2), getDotted(0.5), 0.5, getTriplet(1), getDotted(0.25), 0.25,  getTriplet(0.5), getDotted(0.125), 0.125}
      local resolutionNames = {"8x", "6x", "4x", "3x", "2x", "1/1 dot", "1/1", "1/2 dot", "1/2", "1/2 tri", "1/4 dot",   "1/4", "1/4 tri",   "1/8 dot",     "1/8", "1/8 tri",    "1/16 dot",      "1/16", "1/16 tri",     "1/32 dot",      "1/32"}
      local index = math.floor(self.value) + 1
      lfo2:setParameter("Freq", resolutions[index])
      self.displayText = resolutionNames[index]
    end
    lfoFreqKnob:changed()
  end
end
lfo2SyncButton:changed()

local lfo2TriggerButton = lfoPanel:OnOffButton("Lfo2Trigger", true)
lfo2TriggerButton.fillColour = knobColour
lfo2TriggerButton.outlineColour = lfoColour
lfo2TriggerButton.width = 75
lfo2TriggerButton.position = {lfoFreqKnob.width+waveFormTypeMenu.width+25,25}
lfo2TriggerButton.displayName = "Retrigger"
lfo2TriggerButton.changed = function(self)
  local mode = 1
  if (self.value == false) then
    mode = 3
  end
  lfo2:setParameter("Retrigger", mode)
end
lfo2TriggerButton:changed()

local lfoToCutoffKnob = lfoPanel:Knob("LfoToCutoff", 0, -1, 1)
lfoToCutoffKnob.displayName = "LFO->Filter"
lfoToCutoffKnob.fillColour = knobColour
lfoToCutoffKnob.outlineColour = lfoColour
lfoToCutoffKnob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToCutoff:setParameter("Value", value)
  --print("Value set:", value)
  self.displayText = string.format("%0.1f %%", (self.value * 100))
end
lfoToCutoffKnob:changed()

local lfoToAmpKnob = lfoPanel:Knob("LfoToAmplitude", 0, -1, 1)
lfoToAmpKnob.displayName = "LFO->Amp"
lfoToAmpKnob.fillColour = knobColour
lfoToAmpKnob.outlineColour = lfoColour
lfoToAmpKnob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToAmp:setParameter("Value", value)
  --print("Value set:", value)
  self.displayText = string.format("%0.1f %%", (self.value * 100))
end
lfoToAmpKnob:changed()

--------------------------------------------------------------------------------
-- Amp Env
--------------------------------------------------------------------------------

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

local ampEnvPanel = Panel("ampEnv1")

local ampEnvLabel = ampEnvPanel:Label("Amp Envelope")

local ampAttackKnob = ampEnvPanel:Knob("Attack", 0.001, 0, 10)
ampAttackKnob.fillColour = knobColour
ampAttackKnob.outlineColour = ampEnvColour
ampAttackKnob.mapper = Mapper.Quartic
ampAttackKnob.changed = function(self)
  --ampAttack:setParameter("Value", self.value / 10)
  ampEnv1:setParameter("AttackTime", self.value)
  ampEnv2:setParameter("AttackTime", self.value)
  ampEnvNoise:setParameter("AttackTime", self.value)
  self.displayText = formatTimeInSeconds(self.value)
end
ampAttackKnob:changed()

local ampDecayKnob = ampEnvPanel:Knob("Decay", 0.050, 0, 10)
ampDecayKnob.fillColour = knobColour
ampDecayKnob.outlineColour = ampEnvColour
ampDecayKnob.mapper = Mapper.Quartic
ampDecayKnob.changed = function(self)
  --ampDecay:setParameter("Value", self.value)
  ampEnv1:setParameter("DecayTime", self.value)
  ampEnv2:setParameter("DecayTime", self.value)
  ampEnvNoise:setParameter("DecayTime", self.value)
  self.displayText = formatTimeInSeconds(self.value)
end
ampDecayKnob:changed()

local ampSustainKnob = ampEnvPanel:Knob("Sustain", 1, 0, 1)
ampSustainKnob.fillColour = knobColour
ampSustainKnob.outlineColour = ampEnvColour
ampSustainKnob.changed = function(self)
  ampSustain:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
ampSustainKnob:changed()

local ampReleaseKnob = ampEnvPanel:Knob("Release", 0.010, 0, 10)
ampReleaseKnob.fillColour = knobColour
ampReleaseKnob.outlineColour = ampEnvColour
ampReleaseKnob.mapper = Mapper.Quartic
ampReleaseKnob.changed = function(self)
  --ampRelease:setParameter("Value", self.value)
  ampEnv1:setParameter("ReleaseTime", self.value)
  ampEnv2:setParameter("ReleaseTime", self.value)
  ampEnvNoise:setParameter("ReleaseTime", self.value)
  self.displayText = formatTimeInSeconds(self.value)
end
ampReleaseKnob:changed()

local ampVelocityKnob = ampEnvPanel:Knob("VelocityToAmpEnv", 10, 0, 40)
ampVelocityKnob.displayName="Velocity"
ampVelocityKnob.fillColour = knobColour
ampVelocityKnob.outlineColour = ampEnvColour
ampVelocityKnob.changed = function(self)
  ampEnv1:setParameter("DynamicRange", self.value)
  ampEnv2:setParameter("DynamicRange", self.value)
  ampEnvNoise:setParameter("DynamicRange", self.value)
end
ampVelocityKnob:changed()

--------------------------------------------------------------------------------
-- Filter Env
--------------------------------------------------------------------------------

local filterEnvPanel = Panel("FilterEnv1")

local filterEnvLabel = filterEnvPanel:Label("Filter Envelope")

local filterAttackKnob = filterEnvPanel:Knob("FAttack", 0.001, 0, 10)
filterAttackKnob.displayName="Attack"
filterAttackKnob.fillColour = knobColour
filterAttackKnob.outlineColour = filterEnvColour
filterAttackKnob.mapper = Mapper.Quartic
filterAttackKnob.changed = function(self)
  --filterAttack:setParameter("Value", self.value)
  filterEnv1:setParameter("AttackTime", self.value)
  filterEnv2:setParameter("AttackTime", self.value)
  filterEnvNoise:setParameter("AttackTime", self.value)
  self.displayText = formatTimeInSeconds(self.value)
end
filterAttackKnob:changed()

local filterDecayKnob = filterEnvPanel:Knob("FDecay", 0.050, 0, 10)
filterDecayKnob.displayName="Decay"
filterDecayKnob.fillColour = knobColour
filterDecayKnob.outlineColour = filterEnvColour
filterDecayKnob.mapper = Mapper.Quartic
filterDecayKnob.changed = function(self)
  --filterDecay:setParameter("Value", self.value)
  filterEnv1:setParameter("DecayTime", self.value)
  filterEnv2:setParameter("DecayTime", self.value)
  filterEnvNoise:setParameter("DecayTime", self.value)
  self.displayText = formatTimeInSeconds(self.value)
end
filterDecayKnob:changed()

local filterSustainKnob = filterEnvPanel:Knob("FSustain", 1, 0, 1)
filterSustainKnob.displayName="Sustain"
filterSustainKnob.fillColour = knobColour
filterSustainKnob.outlineColour = filterEnvColour
filterSustainKnob.changed = function(self)
  filterSustain:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
filterSustainKnob:changed()

local filterReleaseKnob = filterEnvPanel:Knob("FRelease", 0.010, 0, 10)
filterReleaseKnob.displayName="Release"
filterReleaseKnob.fillColour = knobColour
filterReleaseKnob.outlineColour = filterEnvColour
filterReleaseKnob.mapper = Mapper.Quartic
filterReleaseKnob.changed = function(self)
  --filterRelease:setParameter("Value", self.value)
  filterEnv1:setParameter("ReleaseTime", self.value)
  filterEnv2:setParameter("ReleaseTime", self.value)
  filterEnvNoise:setParameter("ReleaseTime", self.value)
  self.displayText = formatTimeInSeconds(self.value)
end
filterReleaseKnob:changed()

local filterVelocityKnob = filterEnvPanel:Knob("VelocityToFilterEnv", 10, 0, 40)
filterVelocityKnob.displayName="Velocity"
filterVelocityKnob.fillColour = knobColour
filterVelocityKnob.outlineColour = ampEnvColour
filterVelocityKnob.changed = function(self)
  filterEnv1:setParameter("DynamicRange", self.value)
  filterEnv2:setParameter("DynamicRange", self.value)
  filterEnvNoise:setParameter("DynamicRange", self.value)
end
filterVelocityKnob:changed()

--------------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------------

local effectsPanel = Panel("EffectsPanel")

local effectsLabel = effectsPanel:Label("Effects")

local reverbKnob = effectsPanel:Knob("Reverb", 0, 0, 1)
reverbKnob.mapper = Mapper.Quadratic
reverbKnob.fillColour = knobColour
reverbKnob.outlineColour = filterEffectsColour
reverbKnob.changed = function(self)
  reverbMix:setParameter("Value", self.value)
end
reverbKnob:changed()

local delayKnob = effectsPanel:Knob("Delay", 0, 0, 1)
delayKnob.mapper = Mapper.Cubic
delayKnob.fillColour = knobColour
delayKnob.outlineColour = filterEffectsColour
delayKnob.changed = function(self)
  delayMix:setParameter("Value", self.value)
end
delayKnob:changed()

local chorusKnob = effectsPanel:Knob("Chorus", 0, 0, 1)
chorusKnob.mapper = Mapper.Linear
chorusKnob.fillColour = knobColour
chorusKnob.outlineColour = filterEffectsColour
chorusKnob.changed = function(self)
  chorusMix:setParameter("Value", self.value)
end
chorusKnob:changed()

local driveKnob = effectsPanel:Knob("Drive", 0, 0, 1)
driveKnob.mapper = Mapper.Cubic
driveKnob.fillColour = knobColour
driveKnob.outlineColour = filterEffectsColour
driveKnob.changed = function(self)
  driveAmount:setParameter("Value", self.value)
end
driveKnob:changed()

--------------------------------------------------------------------------------
-- Pitch
--------------------------------------------------------------------------------

local pitchPanel = Panel("PitchPanel")

local vibratoKnob = pitchPanel:Knob("Vibrato", 0, 0, 1)
vibratoKnob.fillColour = knobColour
vibratoKnob.outlineColour = pitchColour
vibratoKnob.changed = function(self)
  vibratoAmount:setParameter("Value", self.value)
end
vibratoKnob:changed()

local vibratoRateKnob = pitchPanel:Knob("VibratoRate", 0.7, 0, 1)
vibratoRateKnob.displayName="Rate"
vibratoRateKnob.fillColour = knobColour
vibratoRateKnob.outlineColour = pitchColour
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

--local vibratoModLabel = pitchPanel:Label("Vibrato Modulation")

local wheelToVibratoKnob = pitchPanel:Knob("WheelToVibrato", 0, 0, 1)
wheelToVibratoKnob.displayName="Modwheel"
wheelToVibratoKnob.fillColour = knobColour
wheelToVibratoKnob.outlineColour = pitchColour
wheelToVibratoKnob.changed = function(self)
  wheelToVibrato:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
wheelToVibratoKnob:changed()

local atToVibratoKnob = pitchPanel:Knob("AftertouchToVibrato", 0, 0, 1)
atToVibratoKnob.displayName="Aftertouch"
atToVibratoKnob.fillColour = knobColour
atToVibratoKnob.outlineColour = pitchColour
atToVibratoKnob.changed = function(self)
  atToVibrato:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
atToVibratoKnob:changed()

--------------------------------------------------------------------------------
-- Arp
--------------------------------------------------------------------------------

local arpeggiatorButton = effectsPanel:OnOffButton("Arp", false)
arpeggiatorButton.fillColour = knobColour
arpeggiatorButton.outlineColour = filterEfectsColour
arpeggiatorButton.width = 75
arpeggiatorButton.changed = function(self)
  local value = -1
  if (self.value == true) then
    value = 1
  end
  arpeggiator:setParameter("Value", value)
end
arpeggiatorButton:changed()

--------------------------------------------------------------------------------
-- Make view
--------------------------------------------------------------------------------

local marginX = 5 -- left/right
local marginYfirst = marginX -- top/bottom
local marginY = 2 -- top/bottom
local height = 54
local width = 710

osc1Panel.backgroundColour = "#33AAFECD"
osc1Panel.x = marginX
osc1Panel.y = marginYfirst
osc1Panel.width = 245
osc1Panel.height = height

osc2Panel.backgroundColour = "#3300FECD"
osc2Panel.x = osc1Panel.width + marginX + marginY
osc2Panel.y = marginYfirst
osc2Panel.width = 463
osc2Panel.height = height

mixerPanel.backgroundColour = "#3399AA00"
mixerPanel.x = marginX
mixerPanel.y = osc1Panel.y + height + marginY
mixerPanel.width = width
mixerPanel.height = height

pitchPanel.backgroundColour = "#3399DD00"
pitchPanel.x = marginX
pitchPanel.y = mixerPanel.y + height + marginY
pitchPanel.width = 475
pitchPanel.height = height

unisonPanel.backgroundColour = "#3399FECD"
unisonPanel.x = pitchPanel.width + marginX + marginY
unisonPanel.y = pitchPanel.y
unisonPanel.width = 233
unisonPanel.height = height

filterPanel.backgroundColour = "#33AA00DD"
filterPanel.x = marginX
filterPanel.y = pitchPanel.y + height + marginY
filterPanel.width = width
filterPanel.height = height

lfoPanel.backgroundColour = "#330000DD"
lfoPanel.x = marginX
lfoPanel.y = filterPanel.y + height + marginY
lfoPanel.width = width
lfoPanel.height = height

ampEnvPanel.backgroundColour = "#444444"
ampEnvPanel.x = marginX
ampEnvPanel.y = lfoPanel.y + height + marginY
ampEnvPanel.width = width
ampEnvPanel.height = height

filterEnvPanel.backgroundColour = "#333333"
filterEnvPanel.x = marginX
filterEnvPanel.y = ampEnvPanel.y + height + marginY
filterEnvPanel.width = width
filterEnvPanel.height = height

effectsPanel.backgroundColour = "#3300AADD"
effectsPanel.x = marginX
effectsPanel.y = filterEnvPanel.y + height + marginY
effectsPanel.width = width
effectsPanel.height = height

setSize(720, 460)

makePerformanceView()
