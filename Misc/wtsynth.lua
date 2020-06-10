--------------------------------------------------------------------------------
-- Wave Table Synth
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
local vibratoLfo = Program.modulations["LFO 1"] -- Vibrato
local lfo1 = osc1Keygroup.modulations["LFO 1"] -- Modulation
local lfo2 = osc2Keygroup.modulations["LFO 1"] -- Modulation
local lfo3 = noiseKeygroup.modulations["LFO 1"] -- Modulation
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
local osc1LfoToPD = Program.modulations["Macro 27"]
local osc2LfoToPD = Program.modulations["Macro 28"]
local wheelToVibrato = Program.modulations["Macro 29"]
local filterKeyTracking = Program.modulations["Macro 30"]
local lfoToCutoff = Program.modulations["Macro 31"]
local unisonDetune = Program.modulations["Macro 32"]
local vibratoRate = Program.modulations["Macro 33"]
local unisonVoices = Program.modulations["Macro 34"]
local maximizer = Program.modulations["Macro 35"]
local noiseMix = Program.modulations["Macro 36"]
local lfoToAmp = Program.modulations["Macro 37"]
local lfoToWT1 = Program.modulations["Macro 38"]
local lfoToWT2 = Program.modulations["Macro 39"]
local filterEnvToWT1 = Program.modulations["Macro 40"]
local filterEnvToWT2 = Program.modulations["Macro 41"]
local lfoKeyFollow = Program.modulations["Macro 42"]
local panSpread = Program.modulations["Macro 43"]
local stereoSpread = Program.modulations["Macro 44"]

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
local vibratoColour = "lightblue"

--------------------------------------------------------------------------------
-- Helper functions and params
--------------------------------------------------------------------------------

function percent(value)
  return string.format("%0.1f %%", (value * 100))
end

--------------------------------------------------------------------------------
-- Osc 1
--------------------------------------------------------------------------------

local osc1Panel = Panel("Osc1Panel")

local osc1ShapeKnob = osc1Panel:Knob("Osc1", 0, 0, 1)
osc1ShapeKnob.displayName = "Osc 1 Pos"
osc1ShapeKnob.fillColour = knobColour
osc1ShapeKnob.outlineColour = osc1Colour
osc1ShapeKnob.changed = function(self)
  osc1Shape:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
osc1ShapeKnob:changed()

local filterEnvToWT1Knob = osc1Panel:Knob("Osc1FilterEnvToIndex", 0, -1, 1)
filterEnvToWT1Knob.displayName = "ENV->INDEX"
filterEnvToWT1Knob.fillColour = knobColour
filterEnvToWT1Knob.outlineColour = lfoColour
filterEnvToWT1Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  filterEnvToWT1:setParameter("Value", value)
  self.displayText = percent(self.value)
end
filterEnvToWT1Knob:changed()

local lfoToWT1Knob = osc1Panel:Knob("Osc1LfoToWaveIndex", 0, -1, 1)
lfoToWT1Knob.displayName = "LFO->INDEX"
lfoToWT1Knob.fillColour = knobColour
lfoToWT1Knob.outlineColour = lfoColour
lfoToWT1Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToWT1:setParameter("Value", value)
  self.displayText = percent(self.value)
end
lfoToWT1Knob:changed()

--------------------------------------------------------------------------------
-- Osc 2
--------------------------------------------------------------------------------

local osc2Panel = Panel("Osc2Panel")

local osc2ShapeKnob = osc2Panel:Knob("Osc2", 0, 0, 1)
osc2ShapeKnob.displayName = "Osc 2 Pos"
osc2ShapeKnob.fillColour = knobColour
osc2ShapeKnob.outlineColour = osc2Colour
osc2ShapeKnob.changed = function(self)
  osc2Shape:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
osc2ShapeKnob:changed()

local filterEnvToWT2Knob = osc2Panel:Knob("Osc2FilterEnvToIndex", 0, -1, 1)
filterEnvToWT2Knob.displayName = "ENV->INDEX"
filterEnvToWT2Knob.fillColour = knobColour
filterEnvToWT2Knob.outlineColour = lfoColour
filterEnvToWT2Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  filterEnvToWT2:setParameter("Value", value)
  self.displayText = percent(self.value)
end
filterEnvToWT2Knob:changed()

local lfoToWT2Knob = osc2Panel:Knob("Osc2LfoToWaveIndex", 0, -1, 1)
lfoToWT2Knob.displayName = "LFO->INDEX"
lfoToWT2Knob.fillColour = knobColour
lfoToWT2Knob.outlineColour = lfoColour
lfoToWT2Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToWT2:setParameter("Value", value)
  self.displayText = percent(self.value)
end
lfoToWT2Knob:changed()

local osc2PitchPanel = Panel("Osc2PitchPanel")

local osc2PitchKnob = osc2PitchPanel:Knob("Osc2Pitch", 0, -24, 24, true)
osc2PitchKnob.displayName = "Osc 2 Pitch"
osc2PitchKnob.fillColour = knobColour
osc2PitchKnob.outlineColour = osc2Colour
osc2PitchKnob.changed = function(self)
  local factor = 1 / 48;
  local value = (self.value * factor) + 0.5;
  osc2Pitch:setParameter("Value", value)
end
osc2PitchKnob:changed()

local osc2DetuneKnob = osc2PitchPanel:Knob("Osc2FinePitch", 0, 0, 1)
osc2DetuneKnob.displayName = "Osc 2 Fine"
osc2DetuneKnob.fillColour = knobColour
osc2DetuneKnob.outlineColour = osc2Colour
osc2DetuneKnob.changed = function(self)
  osc2Detune:setParameter("Value", self.value)
end
osc2DetuneKnob:changed()

--------------------------------------------------------------------------------
-- Stereo
--------------------------------------------------------------------------------

local stereoPanel = Panel("stereo")

local panSpreadKnob = stereoPanel:Knob("PanSpread", 0, 0, 1)
panSpreadKnob.displayName = "Pan Spread"
panSpreadKnob.fillColour = knobColour
panSpreadKnob.outlineColour = unisonColour
panSpreadKnob.changed = function(self)
  panSpread:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
panSpreadKnob:changed()

--------------------------------------------------------------------------------
-- Unison
--------------------------------------------------------------------------------

local unisonPanel = Panel("UnisonPanel")

--local unisonLabel = unisonPanel:Label("Unison")

local unisonDetuneKnob = unisonPanel:Knob("UnisonDetune", 0.1, 0, 1)
unisonDetuneKnob.x = 8
unisonDetuneKnob.y = 54
unisonDetuneKnob.displayName = "Detune"
unisonDetuneKnob.fillColour = knobColour
unisonDetuneKnob.outlineColour = unisonColour
unisonDetuneKnob.changed = function(self)
  unisonDetune:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
unisonDetuneKnob:changed()

local stereoSpreadKnob = unisonPanel:Knob("StereoSpread", 0.1, 0, 1)
stereoSpreadKnob.x = 8
stereoSpreadKnob.y = unisonDetuneKnob.y + unisonDetuneKnob.height + 4
stereoSpreadKnob.displayName = "Stereo Spread"
stereoSpreadKnob.fillColour = knobColour
stereoSpreadKnob.outlineColour = unisonColour
stereoSpreadKnob.changed = function(self)
  stereoSpread:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
stereoSpreadKnob:changed()

local unisonVoicesKnob = unisonPanel:Knob("UnisonVoices", 1, 1, 8, true)
unisonVoicesKnob.x = 8
unisonVoicesKnob.y = 5
unisonVoicesKnob.displayName = "Unison"
unisonVoicesKnob.fillColour = knobColour
unisonVoicesKnob.outlineColour = unisonColour
unisonVoicesKnob.changed = function(self)
  local factor = 1 / 8
  local value = factor * self.value
  local unisonActive = false
  unisonVoices:setParameter("Value", value)
  if self.value == 1 then
    self.displayText = "Off"
    unisonActive = false
  else
    self.displayText = tostring(self.value)
    unisonActive = true
  end
  unisonDetuneKnob.enabled = unisonActive
  stereoSpreadKnob.enabled = unisonActive
  noiseOsc:setParameter("Stereo", unisonActive)
end
unisonVoicesKnob:changed()

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

--local mixerLabel = mixerPanel:Label("Mixer")

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
end
noiseTypeMenu:changed()

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
  self.displayText = percent(self.value)
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
  self.displayText = percent(self.value)
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
  self.displayText = percent(self.value)
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
  self.displayText = percent(self.value)
end
envAmtKnob:changed()

--------------------------------------------------------------------------------
-- LFO
--------------------------------------------------------------------------------

local lfoPanel = Panel("Lfo")
local lfoLabel = lfoPanel:Label("LFO")

local waveFormTypes = {"Sinus", "Square", "Triangle", "Ramp Up", "Ramp Down", "Analog Square", "S&H", "Chaos Lorenz", "Chaos Rossler"}
local waveFormTypeMenu = lfoPanel:Menu("WaveFormTypeMenu", waveFormTypes)
waveFormTypeMenu.displayName = "LFO"
waveFormTypeMenu.selected = 3
waveFormTypeMenu.changed = function(self)
  local value = self.value - 1
  lfo1:setParameter("WaveFormType", value)
  lfo2:setParameter("WaveFormType", value)
  lfo3:setParameter("WaveFormType", value)
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
  lfo1:setParameter("SyncToHost", self.value)
  lfo2:setParameter("SyncToHost", self.value)
  lfo3:setParameter("SyncToHost", self.value)
  if self.value == false then
    lfoFreqKnob.default = 4.5
    lfoFreqKnob.mapper = Mapper.Quadratic
    lfoFreqKnob.changed = function(self)
      lfo1:setParameter("Freq", self.value)
      lfo2:setParameter("Freq", self.value)
      lfo3:setParameter("Freq", self.value)
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
      lfo1:setParameter("Freq", resolutions[index])
      lfo2:setParameter("Freq", resolutions[index])
      lfo3:setParameter("Freq", resolutions[index])
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
lfo2TriggerButton.position = {lfo2SyncButton.x,25}
lfo2TriggerButton.displayName = "Retrigger"
lfo2TriggerButton.changed = function(self)
  local mode = 1
  if (self.value == false) then
    mode = 3
  end
  lfo1:setParameter("Retrigger", mode)
  lfo2:setParameter("Retrigger", mode)
  lfo3:setParameter("Retrigger", mode)
end
lfo2TriggerButton:changed()

local lfoKeyFollowKnob = lfoPanel:Knob("LfoFreqKeyFollow", 0, 0, 1)
lfoKeyFollowKnob.displayName = "Key Track"
lfoKeyFollowKnob.fillColour = knobColour
lfoKeyFollowKnob.outlineColour = lfoColour
lfoKeyFollowKnob.changed = function(self)
  lfoKeyFollow:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
lfoKeyFollowKnob:changed()

local lfoTargetPanel = Panel("LfoTargetPanel")
local lfoTargetLabel = lfoTargetPanel:Label("LFO Targets")

local lfoToCutoffKnob = lfoTargetPanel:Knob("LfoToCutoff", 0, -1, 1)
lfoToCutoffKnob.displayName = "LFO->Filter"
lfoToCutoffKnob.fillColour = knobColour
lfoToCutoffKnob.outlineColour = lfoColour
lfoToCutoffKnob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToCutoff:setParameter("Value", value)
  --print("Value set:", value)
  self.displayText = percent(self.value)
end
lfoToCutoffKnob:changed()

local lfoToAmpKnob = lfoTargetPanel:Knob("LfoToAmplitude", 0, -1, 1)
lfoToAmpKnob.displayName = "LFO->Amp"
lfoToAmpKnob.fillColour = knobColour
lfoToAmpKnob.outlineColour = lfoColour
lfoToAmpKnob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToAmp:setParameter("Value", value)
  --print("Value set:", value)
  self.displayText = percent(self.value)
end
lfoToAmpKnob:changed()

local osc1LfoToPhaseDistortionKnob = lfoTargetPanel:Knob("LfoToOsc1PhaseDistortion", 0, 0, 0.5)
osc1LfoToPhaseDistortionKnob.displayName = "LFO->PD1"
osc1LfoToPhaseDistortionKnob.mapper = Mapper.Quartic
osc1LfoToPhaseDistortionKnob.fillColour = knobColour
osc1LfoToPhaseDistortionKnob.outlineColour = lfoColour
osc1LfoToPhaseDistortionKnob.changed = function(self)
  osc1LfoToPD:setParameter("Value", self.value)
  --osc2LfoToPD:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
osc1LfoToPhaseDistortionKnob:changed()

local osc2LfoToPhaseDistortionKnob = lfoTargetPanel:Knob("LfoToOsc2PhaseDistortion", 0, 0, 0.5)
osc2LfoToPhaseDistortionKnob.displayName = "LFO->PD2"
osc2LfoToPhaseDistortionKnob.mapper = Mapper.Quartic
osc2LfoToPhaseDistortionKnob.fillColour = knobColour
osc2LfoToPhaseDistortionKnob.outlineColour = lfoColour
osc2LfoToPhaseDistortionKnob.changed = function(self)
  --osc1LfoToPD:setParameter("Value", self.value)
  osc2LfoToPD:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
osc2LfoToPhaseDistortionKnob:changed()

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

--local effectsLabel = effectsPanel:Label("Effects")

local maximizerButton = effectsPanel:OnOffButton("Maximizer", false)
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
-- Vibrato
--------------------------------------------------------------------------------

local vibratoPanel = Panel("VibratoPanel")

local vibratoKnob = vibratoPanel:Knob("Vibrato", 0, 0, 1)
vibratoKnob.fillColour = knobColour
vibratoKnob.outlineColour = vibratoColour
vibratoKnob.changed = function(self)
  vibratoAmount:setParameter("Value", self.value)
end
vibratoKnob:changed()

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

--local vibratoModLabel = vibratoPanel:Label("Vibrato Modulation")

local wheelToVibratoKnob = vibratoPanel:Knob("WheelToVibrato", 0, 0, 1)
wheelToVibratoKnob.displayName="Modwheel"
wheelToVibratoKnob.fillColour = knobColour
wheelToVibratoKnob.outlineColour = vibratoColour
wheelToVibratoKnob.changed = function(self)
  wheelToVibrato:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
wheelToVibratoKnob:changed()

local atToVibratoKnob = vibratoPanel:Knob("AftertouchToVibrato", 0, 0, 1)
atToVibratoKnob.displayName="Aftertouch"
atToVibratoKnob.fillColour = knobColour
atToVibratoKnob.outlineColour = vibratoColour
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

local marginX = 3 -- left/right
local marginY = 2 -- top/bottom
local height = 51
local width = 713

osc1Panel.backgroundColour = "#33AAFECD"
osc1Panel.x = marginX
osc1Panel.y = marginY
osc1Panel.width = 356
osc1Panel.height = height

osc2Panel.backgroundColour = "#3300FECD"
osc2Panel.x = osc1Panel.width + marginX + marginY
osc2Panel.y = marginY
osc2Panel.width = 356
osc2Panel.height = height

mixerPanel.backgroundColour = "#3399AA00"
mixerPanel.x = marginX
mixerPanel.y = osc1Panel.y + height + marginY
mixerPanel.width = 477
mixerPanel.height = height

osc2PitchPanel.backgroundColour = "#3300FECD"
osc2PitchPanel.x = mixerPanel.width + marginX + marginY
osc2PitchPanel.y = mixerPanel.y
osc2PitchPanel.width = 235
osc2PitchPanel.height = height

vibratoPanel.backgroundColour = "#3399DD00"
vibratoPanel.x = marginX
vibratoPanel.y = mixerPanel.y + height + marginY
vibratoPanel.width = 477
vibratoPanel.height = height

stereoPanel.backgroundColour = "#3399FECD"
stereoPanel.x = vibratoPanel.width + marginX + marginY
stereoPanel.y = vibratoPanel.y
stereoPanel.width = 116
stereoPanel.height = height

unisonPanel.backgroundColour = "#3399FECD"
unisonPanel.x = vibratoPanel.width + stereoPanel.width + marginX + (marginY * 2)
unisonPanel.y = vibratoPanel.y
unisonPanel.width = 118
unisonPanel.height = (height * 3) + (marginY * 2)

lfoPanel.backgroundColour = "#330000DD"
lfoPanel.x = marginX
lfoPanel.y = unisonPanel.y + height + marginY
lfoPanel.width = 593
lfoPanel.height = height

lfoTargetPanel.backgroundColour = "#330000DD"
lfoTargetPanel.x = marginX
lfoTargetPanel.y = lfoPanel.y + height + marginY
lfoTargetPanel.width = 593
lfoTargetPanel.height = height

filterPanel.backgroundColour = "#33AA00DD"
filterPanel.x = marginX
filterPanel.y = lfoTargetPanel.y + height + marginY
filterPanel.width = width
filterPanel.height = height

ampEnvPanel.backgroundColour = "#444444"
ampEnvPanel.x = marginX
ampEnvPanel.y = filterPanel.y + height + marginY
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

setSize(720, 480)

makePerformanceView()
