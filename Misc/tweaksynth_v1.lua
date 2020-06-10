--------------------------------------------------------------------------------
-- Tweakable Synth
--------------------------------------------------------------------------------

-- KEYGROUPS
local osc1Keygroup = Program.layers[1].keygroups[1]
local osc2Keygroup = Program.layers[2].keygroups[1]
local noiseKeygroup = Program.layers[3].keygroups[1]

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

-- MACROS
local osc1Shape = Program.modulations["Macro 1"]
local filterCutoff = Program.modulations["Macro 2"]
local filterEnvAmount = Program.modulations["Macro 3"]
local lfoFreqKeyFollow2 = Program.modulations["Macro 4"]
local lfoFreqKeyFollow3 = Program.modulations["Macro 5"]
local lfoToDetune = Program.modulations["Macro 6"]
local lfoToWaveSpread1 = Program.modulations["Macro 7"]
local osc1Mix = Program.modulations["Macro 8"]
local osc2Shape = Program.modulations["Macro 9"]
local osc2Mix = Program.modulations["Macro 10"]
local osc2Detune = Program.modulations["Macro 11"]
local osc2Pitch = Program.modulations["Macro 12"]
local filterResonance = Program.modulations["Macro 13"]
local delayMix = Program.modulations["Macro 14"]
local reverbMix = Program.modulations["Macro 15"]
local arpeggiator = Program.modulations["Macro 16"]
local lfoToWaveSpread2 = Program.modulations["Macro 17"]
local lfoToNoiseLpf = Program.modulations["Macro 18"]
local lfoToNoiseHpf = Program.modulations["Macro 19"]
local lfoToNoiseAmp = Program.modulations["Macro 20"]
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
local lfoFreqKeyFollow1 = Program.modulations["Macro 42"]
local panSpread = Program.modulations["Macro 43"]
local stereoSpread = Program.modulations["Macro 44"]
local osc1Pitch = Program.modulations["Macro 45"]
local lfoToPitchOsc1 = Program.modulations["Macro 46"]
local lfoToPitchOsc2 = Program.modulations["Macro 47"]
local filterEnvToPitchOsc1 = Program.modulations["Macro 48"]
local filterEnvToPitchOsc2 = Program.modulations["Macro 49"]
local hpfCutoff = Program.modulations["Macro 50"]
local hpfResonance = Program.modulations["Macro 51"]
local hpfKeyTracking = Program.modulations["Macro 52"]
local hpfEnvAmount = Program.modulations["Macro 53"]
local wheelToHpf = Program.modulations["Macro 54"]
local atToHpf = Program.modulations["Macro 55"]
local lfoToHpf = Program.modulations["Macro 56"]
local waveSpread = Program.modulations["Macro 57"]

--------------------------------------------------------------------------------
-- Colours and margins
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

local marginX = 3 -- left/right
local marginY = 2 -- top/bottom
local height = 60
local width = 713

--------------------------------------------------------------------------------
-- Helper functions and params
--------------------------------------------------------------------------------

function getDotted(value)
  return value + (value / 2)
end

function getTriplet(value)
  return value  / 3
end

local resolutions =     { 32,   24,   16,  12,    8,     6,         4,      3,       2, getTriplet(4), getDotted(1), 1, getTriplet(2), getDotted(0.5), 0.5, getTriplet(1), getDotted(0.25), 0.25,  getTriplet(0.5), getDotted(0.125), 0.125}
local resolutionNames = {"8x", "6x", "4x", "3x", "2x", "1/1 dot", "1/1", "1/2 dot", "1/2", "1/2 tri", "1/4 dot",   "1/4", "1/4 tri",   "1/8 dot",     "1/8", "1/8 tri",    "1/16 dot",      "1/16", "1/16 tri",     "1/32 dot",      "1/32"}

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
-- Osc 1
--------------------------------------------------------------------------------

function createOsc1Panel()
  local osc1Panel = Panel("Osc1Panel")

  osc1Panel:Label("Osc 1")
  
  local osc1ShapeKnob = osc1Panel:Knob("Osc1", 0, 0, 1)
  osc1ShapeKnob.displayName = "Wave"
  osc1ShapeKnob.fillColour = knobColour
  osc1ShapeKnob.outlineColour = osc1Colour
  osc1ShapeKnob.changed = function(self)
    osc1Shape:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  osc1ShapeKnob:changed()
  
  local osc1PhaseKnob = osc1Panel:Knob("Osc1StartPhase", 0, 0, 1)
  osc1PhaseKnob.displayName = "Start Phase"
  osc1PhaseKnob.fillColour = knobColour
  osc1PhaseKnob.outlineColour = osc1Colour
  osc1PhaseKnob.changed = function(self)
    osc1:setParameter("StartPhase", self.value)
    self.displayText = percent(self.value)
  end
  osc1PhaseKnob:changed()
  
  local osc1PitchKnob = osc1Panel:Knob("Osc1Pitch", 0, -2, 2, true)
  osc1PitchKnob.displayName = "Octave"
  osc1PitchKnob.fillColour = knobColour
  osc1PitchKnob.outlineColour = osc1Colour
  osc1PitchKnob.changed = function(self)
    local factor = 1 / 4;
    local value = (self.value * factor) + 0.5;
    osc1Pitch:setParameter("Value", value)
  end
  osc1PitchKnob:changed()

  return osc1Panel
end

local osc1Panel = createOsc1Panel()

--------------------------------------------------------------------------------
-- Osc 2
--------------------------------------------------------------------------------

function createOsc2Panel()
  local osc2Panel = Panel("Osc2Panel")

  osc2Panel:Label("Osc 2")

  local osc2ShapeKnob = osc2Panel:Knob("Osc2", 0, 0, 1)
  osc2ShapeKnob.displayName = "Wave"
  osc2ShapeKnob.fillColour = knobColour
  osc2ShapeKnob.outlineColour = osc2Colour
  osc2ShapeKnob.changed = function(self)
    osc2Shape:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  osc2ShapeKnob:changed()

  local osc2PhaseKnob = osc2Panel:Knob("Osc2StartPhase", 0, 0, 1)
  osc2PhaseKnob.displayName = "Start Phase"
  osc2PhaseKnob.fillColour = knobColour
  osc2PhaseKnob.outlineColour = osc2Colour
  osc2PhaseKnob.changed = function(self)
    osc2:setParameter("StartPhase", self.value)
    self.displayText = percent(self.value)
  end
  osc2PhaseKnob:changed()

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

  local osc2DetuneKnob = osc2Panel:Knob("Osc2FinePitch", 0, 0, 1)
  osc2DetuneKnob.displayName = "Fine Pitch"
  osc2DetuneKnob.fillColour = knobColour
  osc2DetuneKnob.outlineColour = osc2Colour
  osc2DetuneKnob.changed = function(self)
    osc2Detune:setParameter("Value", self.value)
  end
  osc2DetuneKnob:changed()

  return osc2Panel
end

local osc2Panel = createOsc2Panel()

--------------------------------------------------------------------------------
-- Stereo/Unison
--------------------------------------------------------------------------------

function createUnisonPanel()
  local unisonPanel = Panel("UnisonPanel")

  unisonPanel:Label("Stereo/Unison")

  local panSpreadKnob = unisonPanel:Knob("PanSpread", 0, 0, 1)
  panSpreadKnob.displayName = "Pan Spread"
  panSpreadKnob.fillColour = knobColour
  panSpreadKnob.outlineColour = unisonColour
  panSpreadKnob.changed = function(self)
    panSpread:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  panSpreadKnob:changed()

  local unisonVoicesKnob = unisonPanel:Knob("UnisonVoices", 1, 1, 8, true)
  unisonVoicesKnob.displayName = "Unison"
  unisonVoicesKnob.fillColour = knobColour
  unisonVoicesKnob.outlineColour = unisonColour

  local unisonDetuneKnob = unisonPanel:Knob("UnisonDetune", 0.1, 0, 1)
  unisonDetuneKnob.displayName = "Detune"
  unisonDetuneKnob.fillColour = knobColour
  unisonDetuneKnob.outlineColour = unisonColour
  unisonDetuneKnob.changed = function(self)
    unisonDetune:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  unisonDetuneKnob:changed()

  local stereoSpreadKnob = unisonPanel:Knob("StereoSpread", 0.1, 0, 1)
  stereoSpreadKnob.displayName = "Stereo Spread"
  stereoSpreadKnob.fillColour = knobColour
  stereoSpreadKnob.outlineColour = unisonColour
  stereoSpreadKnob.changed = function(self)
    stereoSpread:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  stereoSpreadKnob:changed()

  local waveSpreadKnob = unisonPanel:Knob("WaveSpread", 0, 0, 1)
  waveSpreadKnob.displayName = "Wave Spread"
  waveSpreadKnob.fillColour = knobColour
  waveSpreadKnob.outlineColour = unisonColour
  waveSpreadKnob.changed = function(self)
    waveSpread:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  waveSpreadKnob:changed()

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
    waveSpreadKnob.enabled = unisonActive
    noiseOsc:setParameter("Stereo", unisonActive)
  end
  unisonVoicesKnob:changed()

  return unisonPanel
end

local unisonPanel = createUnisonPanel()

--------------------------------------------------------------------------------
-- Mixer
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

  return mixerPanel
end

local mixerPanel = createMixerPanel()

--------------------------------------------------------------------------------
-- Low-pass Filter
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
    self.displayText = percent(self.value)
  end
  atToCutoffKnob:changed()

  return filterPanel
end

local filterPanel = createFilterPanel()

--------------------------------------------------------------------------------
-- High-pass Filter
--------------------------------------------------------------------------------

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

  local hpfResonanceKnob = hpFilterPanel:Knob("HPFResonance", 0, 0, 1)
  hpfResonanceKnob.displayName = "Resonance"
  hpfResonanceKnob.fillColour = knobColour
  hpfResonanceKnob.outlineColour = filterColour
  hpfResonanceKnob.changed = function(self)
    hpfResonance:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  hpfResonanceKnob:changed()

  local hpfKeyTrackingKnob = hpFilterPanel:Knob("HPFKeyTracking", 0, 0, 1)
  hpfKeyTrackingKnob.displayName = "Key Track"
  hpfKeyTrackingKnob.fillColour = knobColour
  hpfKeyTrackingKnob.outlineColour = filterColour
  hpfKeyTrackingKnob.changed = function(self)
    hpfKeyTracking:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  hpfKeyTrackingKnob:changed()

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

  return hpFilterPanel
end

local hpFilterPanel = createHpFilterPanel()

--------------------------------------------------------------------------------
-- LFO
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
        print("lfoFreqKnob - index / resolution / activeOsc", index, resolutions[index], activeLfoOsc)
        if activeLfoOsc == 1 or activeLfoOsc == 2 then
          lfo1:setParameter("Freq", resolutions[index])
        end
        if activeLfoOsc == 1 or activeLfoOsc == 3 then
          lfo2:setParameter("Freq", resolutions[index])
        end
        if activeLfoOsc == 1 or activeLfoOsc == 4 then
          lfo3:setParameter("Freq", resolutions[index])
        end
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

  local lfoSmoothKnob = lfoPanel:Knob("LfoSmooth", 0, 0, 1)
  lfoSmoothKnob.displayName="Smooth"
  lfoSmoothKnob.fillColour = knobColour
  lfoSmoothKnob.outlineColour = lfoColour
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
    -- SET THE SELECTED OSCILLATOR
    activeLfoOsc = self.value -- 1 = all oscillators
    print("LFO - Active oscillator changed:", activeLfoOsc, self.selectedText)
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

local lfoPanel = createLfoPanel()

--------------------------------------------------------------------------------
-- LFO Targets Noise Osc
--------------------------------------------------------------------------------

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

  return lfoTargetPanel3
end

local lfoTargetPanel3 = createLfoTargetPanel3()

--------------------------------------------------------------------------------
-- LFO Targets
--------------------------------------------------------------------------------

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

  return lfoTargetPanel
end

local lfoTargetPanel = createLfoTargetPanel()

--------------------------------------------------------------------------------
-- LFO Targets Osc 1
--------------------------------------------------------------------------------

local lfoTargetPanel1 = Panel("LfoTargetPanel1")
lfoTargetPanel1:Label("Osc 1")

local osc1LfoToPhaseDistortionKnob = lfoTargetPanel1:Knob("LfoToOsc1PhaseDistortion", 0, 0, 0.5)
osc1LfoToPhaseDistortionKnob.displayName = "Osc 1 PWM"
osc1LfoToPhaseDistortionKnob.mapper = Mapper.Quartic
osc1LfoToPhaseDistortionKnob.fillColour = knobColour
osc1LfoToPhaseDistortionKnob.outlineColour = lfoColour
osc1LfoToPhaseDistortionKnob.changed = function(self)
  osc1LfoToPD:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
osc1LfoToPhaseDistortionKnob:changed()

local lfoToWT1Knob = lfoTargetPanel1:Knob("Osc1LfoToWaveIndex", 0, -1, 1)
lfoToWT1Knob.displayName = "Osc 1 Wave"
lfoToWT1Knob.fillColour = knobColour
lfoToWT1Knob.outlineColour = lfoColour
lfoToWT1Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToWT1:setParameter("Value", value)
  self.displayText = percent(self.value)
end
lfoToWT1Knob:changed()

local lfoToPitchOsc1Knob = lfoTargetPanel1:Knob("LfoToPitchOsc1Knob", 0, 0, 48)
lfoToPitchOsc1Knob.displayName = "Osc 1 Pitch"
lfoToPitchOsc1Knob.mapper = Mapper.Quartic
lfoToPitchOsc1Knob.fillColour = knobColour
lfoToPitchOsc1Knob.outlineColour = lfoColour
lfoToPitchOsc1Knob.changed = function(self)
  local factor = 1 / 48;
  local value = (self.value * factor)
  lfoToPitchOsc1:setParameter("Value", value)
  --print("Value set (lfoToPitchOsc1Knob):", value)
end
lfoToPitchOsc1Knob:changed()

local lfoToWaveSpread1Knob = lfoTargetPanel1:Knob("LfoToWaveSpreadOsc1", 0, -1, 1)
lfoToWaveSpread1Knob.displayName = "WaveSpread"
lfoToWaveSpread1Knob.fillColour = knobColour
lfoToWaveSpread1Knob.outlineColour = lfoColour
lfoToWaveSpread1Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToWaveSpread1:setParameter("Value", value)
  self.displayText = percent(self.value)
end
lfoToWaveSpread1Knob:changed()

--------------------------------------------------------------------------------
-- LFO Targets Osc 2
--------------------------------------------------------------------------------

local lfoTargetPanel2 = Panel("LfoTargetPanel2")
lfoTargetPanel2:Label("Osc 2")

local osc2LfoToPhaseDistortionKnob = lfoTargetPanel2:Knob("LfoToOsc2PhaseDistortion", 0, 0, 0.5)
osc2LfoToPhaseDistortionKnob.displayName = "Osc 2 PWM"
osc2LfoToPhaseDistortionKnob.mapper = Mapper.Quartic
osc2LfoToPhaseDistortionKnob.fillColour = knobColour
osc2LfoToPhaseDistortionKnob.outlineColour = lfoColour
osc2LfoToPhaseDistortionKnob.changed = function(self)
  osc2LfoToPD:setParameter("Value", self.value)
  self.displayText = percent(self.value)
end
osc2LfoToPhaseDistortionKnob:changed()

local lfoToWT2Knob = lfoTargetPanel2:Knob("Osc2LfoToWaveIndex", 0, -1, 1)
lfoToWT2Knob.displayName = "Osc 2 Wave"
lfoToWT2Knob.fillColour = knobColour
lfoToWT2Knob.outlineColour = lfoColour
lfoToWT2Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToWT2:setParameter("Value", value)
  self.displayText = percent(self.value)
end
lfoToWT2Knob:changed()

local lfoToPitchOsc2Knob = lfoTargetPanel2:Knob("LfoToPitchOsc2Knob", 0, 0, 48)
lfoToPitchOsc2Knob.displayName = "Osc 2 Pitch"
lfoToPitchOsc2Knob.mapper = Mapper.Quartic
lfoToPitchOsc2Knob.fillColour = knobColour
lfoToPitchOsc2Knob.outlineColour = lfoColour
lfoToPitchOsc2Knob.changed = function(self)
  local factor = 1 / 48;
  local value = (self.value * factor)
  lfoToPitchOsc2:setParameter("Value", value)
  --print("Value set (lfoToPitchOsc2Knob):", value)
end
lfoToPitchOsc2Knob:changed()

local lfoToWaveSpread2Knob = lfoTargetPanel2:Knob("LfoToWaveSpreadOsc2", 0, -1, 1)
lfoToWaveSpread2Knob.displayName = "WaveSpread"
lfoToWaveSpread2Knob.fillColour = knobColour
lfoToWaveSpread2Knob.outlineColour = lfoColour
lfoToWaveSpread2Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  lfoToWaveSpread2:setParameter("Value", value)
  self.displayText = percent(self.value)
end
lfoToWaveSpread2Knob:changed()

--------------------------------------------------------------------------------
-- Amp Env
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

local ampEnvPanel = createAmpEnvPanel()

--------------------------------------------------------------------------------
-- Filter Env
--------------------------------------------------------------------------------

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

  local filterVelocityKnob = filterEnvPanel:Knob("VelocityToFilterEnv", 10, 0, 40)
  filterVelocityKnob.displayName="Velocity"
  filterVelocityKnob.fillColour = knobColour
  filterVelocityKnob.outlineColour = ampEnvColour
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

local filterEnvPanel = createFilterEnvPanel()

--------------------------------------------------------------------------------
-- Filter Env Targets
--------------------------------------------------------------------------------

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

local filterEnvTargets1Panel = Panel("FilterEnvTargets1")
filterEnvTargets1Panel:Label("Osc 1")

local filterEnvToWT1Knob = filterEnvTargets1Panel:Knob("Osc1FilterEnvToIndex", 0, -1, 1)
filterEnvToWT1Knob.displayName = "Osc 1 Wave"
filterEnvToWT1Knob.fillColour = knobColour
filterEnvToWT1Knob.outlineColour = lfoColour
filterEnvToWT1Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  filterEnvToWT1:setParameter("Value", value)
  self.displayText = percent(self.value)
end
filterEnvToWT1Knob:changed()

local filterEnvToPitchOsc1Knob = filterEnvTargets1Panel:Knob("FilterEnvToPitchOsc1", 0, 0, 48)
filterEnvToPitchOsc1Knob.displayName = "Osc 1 Pitch"
filterEnvToPitchOsc1Knob.fillColour = knobColour
filterEnvToPitchOsc1Knob.outlineColour = lfoColour
filterEnvToPitchOsc1Knob.changed = function(self)
  local factor = 1 / 48;
  local value = self.value * factor
  filterEnvToPitchOsc1:setParameter("Value", value)
end
filterEnvToPitchOsc1Knob:changed()

local filterEnvTargets2Panel = Panel("FilterEnvTargets2")
filterEnvTargets2Panel:Label("Osc 2")

local filterEnvToWT2Knob = filterEnvTargets2Panel:Knob("Osc2FilterEnvToIndex", 0, -1, 1)
filterEnvToWT2Knob.displayName = "Osc 2 Wave"
filterEnvToWT2Knob.fillColour = knobColour
filterEnvToWT2Knob.outlineColour = lfoColour
filterEnvToWT2Knob.changed = function(self)
  local value = (self.value + 1) * 0.5
  filterEnvToWT2:setParameter("Value", value)
  self.displayText = percent(self.value)
end
filterEnvToWT2Knob:changed()

local filterEnvToPitchOsc2Knob = filterEnvTargets2Panel:Knob("FilterEnvToPitchOsc2", 0, 0, 48)
filterEnvToPitchOsc2Knob.displayName = "Osc 2 Pitch"
filterEnvToPitchOsc2Knob.fillColour = knobColour
filterEnvToPitchOsc2Knob.outlineColour = lfoColour
filterEnvToPitchOsc2Knob.changed = function(self)
  local factor = 1 / 48;
  local value = self.value * factor
  filterEnvToPitchOsc2:setParameter("Value", value)
end
filterEnvToPitchOsc2Knob:changed()

--------------------------------------------------------------------------------
-- Effects
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

  return vibratoPanel
end

local vibratoPanel = createVibratoPanel()

--------------------------------------------------------------------------------
-- Pages
--------------------------------------------------------------------------------

local pagePanel = Panel("PagePanel")
pagePanel.x = marginX
pagePanel.y = marginY
pagePanel.width = 713
pagePanel.height = 30

local pageAButton = pagePanel:Button("Synthesis")
local pageBButton = pagePanel:Button("Filters")
local pageCButton = pagePanel:Button("Modulation")
local pageDButton = pagePanel:Button("Sequencer")

mixerPanel.x = marginX
mixerPanel.y = pagePanel.height + marginY * 2
mixerPanel.width = width
mixerPanel.height = height

--------------------------------------------------------------------------------
-- Arp
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Page A
--------------------------------------------------------------------------------

osc1Panel.backgroundColour = "#33AAAA00"
osc1Panel.x = marginX
osc1Panel.y = mixerPanel.y + height + marginY
osc1Panel.width = width
osc1Panel.height = height

osc2Panel.backgroundColour = "#44AAAA00"
osc2Panel.x = marginX
osc2Panel.y = osc1Panel.y + height + marginY
osc2Panel.width = width
osc2Panel.height = height

unisonPanel.backgroundColour = "#55AAAA00"
unisonPanel.x = marginX
unisonPanel.y = osc2Panel.y + height + marginY
unisonPanel.width = width
unisonPanel.height = height

vibratoPanel.backgroundColour = "#66AAAA00"
vibratoPanel.x = marginX
vibratoPanel.y = unisonPanel.y + height + marginY
vibratoPanel.width = width
vibratoPanel.height = height

ampEnvPanel.backgroundColour = "#77AAAA00"
ampEnvPanel.x = marginX
ampEnvPanel.y = vibratoPanel.y + height + marginY
ampEnvPanel.width = width
ampEnvPanel.height = height

effectsPanel.backgroundColour = "#88AAAA00"
effectsPanel.x = marginX
effectsPanel.y = ampEnvPanel.y + height + marginY
effectsPanel.width = width
effectsPanel.height = height

--------------------------------------------------------------------------------
-- Page B
--------------------------------------------------------------------------------

filterPanel.backgroundColour = "#33AA00DD"
filterPanel.x = marginX
filterPanel.y = mixerPanel.y + height + marginY
filterPanel.width = width
filterPanel.height = height

hpFilterPanel.backgroundColour = "#44AA00DD"
hpFilterPanel.x = marginX
hpFilterPanel.y = filterPanel.y + height + marginY
hpFilterPanel.width = width
hpFilterPanel.height = height

filterEnvPanel.backgroundColour = "#55AA00DD"
filterEnvPanel.x = marginX
filterEnvPanel.y = hpFilterPanel.y + height + marginY
filterEnvPanel.width = width
filterEnvPanel.height = height

filterEnvTargetsPanel.backgroundColour = "#66AA00DD"
filterEnvTargetsPanel.x = marginX
filterEnvTargetsPanel.y = filterEnvPanel.y + height + marginY
filterEnvTargetsPanel.width = width
filterEnvTargetsPanel.height = height

filterEnvTargets1Panel.backgroundColour = "#66AA00DD"
filterEnvTargets1Panel.x = marginX
filterEnvTargets1Panel.y = filterEnvTargetsPanel.y + height
filterEnvTargets1Panel.width = width
filterEnvTargets1Panel.height = height

filterEnvTargets2Panel.backgroundColour = "#66AA00DD"
filterEnvTargets2Panel.x = marginX
filterEnvTargets2Panel.y = filterEnvTargets1Panel.y + height
filterEnvTargets2Panel.width = width
filterEnvTargets2Panel.height = height

--------------------------------------------------------------------------------
-- Page C
--------------------------------------------------------------------------------

lfoPanel.backgroundColour = "#330000DD"
lfoPanel.x = marginX
lfoPanel.y = mixerPanel.y + height + marginY
lfoPanel.width = width
lfoPanel.height = height * 2

lfoTargetPanel.backgroundColour = "#440000DD"
lfoTargetPanel.x = marginX
lfoTargetPanel.y = lfoPanel.y + lfoPanel.height + marginY
lfoTargetPanel.width = width
lfoTargetPanel.height = height

lfoTargetPanel1.backgroundColour = "#440000DD"
lfoTargetPanel1.x = marginX
lfoTargetPanel1.y = lfoTargetPanel.y + height
lfoTargetPanel1.width = width
lfoTargetPanel1.height = height

lfoTargetPanel2.backgroundColour = "#440000DD"
lfoTargetPanel2.x = marginX
lfoTargetPanel2.y = lfoTargetPanel1.y + height
lfoTargetPanel2.width = width
lfoTargetPanel2.height = height

lfoTargetPanel3.backgroundColour = "#440000DD"
lfoTargetPanel3.x = marginX
lfoTargetPanel3.y = lfoTargetPanel2.y + height
lfoTargetPanel3.width = width
lfoTargetPanel3.height = height

--------------------------------------------------------------------------------
-- Page D - Sequencer
--------------------------------------------------------------------------------

function createSequencerPanel()
  local seqPanel = Panel("Sequencer")
  seqPanel.backgroundColour = "#330000DD"
  seqPanel.x = marginX
  seqPanel.y = mixerPanel.y + height + marginY
  seqPanel.width = width
  seqPanel.height = height * 3

  local sequencerPlayMenu = seqPanel:Menu("SequencerPlay", {"Off", "Mono", "As played", "Random"})
  sequencerPlayMenu.displayName = "Play Mode"
  sequencerPlayMenu.width = 80

  local numStepsBox = seqPanel:NumBox("Steps", 8, 2, 32, true)
  numStepsBox.backgroundColour = "black"
  numStepsBox.textColour = "cyan"
  numStepsBox.arrowColour = "grey"
  numStepsBox.outlineColour = "#1fFFFFFF" -- transparent white

  local seqPitchTable = seqPanel:Table("Pitch", numStepsBox.value, 0, -12, 12, true)
  seqPitchTable.showPopupDisplay = true
  seqPitchTable.width = 450
  seqPitchTable.x = sequencerPlayMenu.width * 1.2

  local seqVelTable = seqPanel:Table("Velocity", numStepsBox.value, 100, 1, 127, true)
  seqVelTable.showPopupDisplay = true
  seqVelTable.width = seqPitchTable.width
  seqVelTable.x = seqPitchTable.x
  seqVelTable.y = seqPitchTable.y + seqPitchTable.height + marginY

  local resolution = seqPanel:Menu{"Resolution", resolutionNames, selected=18}
  resolution.x = seqPitchTable.x + seqPitchTable.width + 30
  resolution.backgroundColour = "black"
  resolution.textColour = "cyan"
  resolution.arrowColour = "grey"
  resolution.outlineColour = "#1fFFFFFF" -- transparent white

  local positionTable = seqPanel:Table("Position", numStepsBox.value, 0, 0, 1, true)
  positionTable.enabled = false
  positionTable.persistent = false
  positionTable.width = seqPitchTable.width
  positionTable.x = seqPitchTable.x
  positionTable.y = seqVelTable.y + seqVelTable.height + marginY

  numStepsBox.x = resolution.x
  numStepsBox.y = resolution.y + resolution.height + marginY
  numStepsBox.changed = function (self)
    seqPitchTable.length = self.value
    seqVelTable.length = self.value
    positionTable.length = self.value
  end

  local gate = seqPanel:Knob("Gate", 0.8, 0, 1)
  gate.x = resolution.x
  gate.y = numStepsBox.y + numStepsBox.height + 12
  gate.changed = function(self)
      self.displayText = percent(self.value)
  end
  gate:changed() -- force update

  local arpId = 0
  local heldNotes = {}

  sequencerPlayMenu.changed = function (self)
    -- Stop sequencer if turned off
    if self.value == 1 then
      heldNotes = {}
      clearPosition()
      arpId = arpId + 1
    end
  end

  function clearPosition()
    for i = 1, numStepsBox.value do
      positionTable:setValue(i, 0)
    end
  end

  function arpeg(arpId_)
    local index = 0
    local heldNoteIndex = 0
    --print("arpId_ / arpId:", arpId_, arpId)
    while arpId_ == arpId do
      --print("Pos", index)
      if sequencerPlayMenu.value == 2 then -- MONO
        heldNoteIndex = #heldNotes
      elseif sequencerPlayMenu.value == 3 then -- AS PLAYED
        heldNoteIndex = heldNoteIndex + 1 -- Increment
        if heldNoteIndex > #heldNotes then
          heldNoteIndex = 1
        end
      elseif sequencerPlayMenu.value == 4 then -- RANDOM
        heldNoteIndex = math.random(1, #heldNotes)
      end
      local e = heldNotes[heldNoteIndex]
      local p = resolutions[resolution.value]
      local note = e.note + seqPitchTable:getValue(index+1)
      local vel = seqVelTable:getValue(index+1)
      local numSteps = numStepsBox.value
      playNote(note, vel, beat2ms(gate.value*p))
      positionTable:setValue((index - 1 + numSteps) % numSteps + 1, 0)
      positionTable:setValue((index % numSteps)+1, 1)
      index = (index+1) % numSteps
      waitBeat(p)
    end
  end

  function onNote(e)
    print("Note:", e.note, "Velocity:", e.velocity)
    table.insert(heldNotes, e)
    if sequencerPlayMenu.value > 1 then
      if #heldNotes == 1 then
          arpeg(arpId)
      end
    else
      playNote(e.note, e.velocity)
    end
  end

  function onRelease(e)
    for i,v in ipairs(heldNotes) do
      if v.note == e.note then
        table.remove(heldNotes, i)
        if #heldNotes == 0 then
          clearPosition()
          arpId = arpId + 1
        end
        break
      end
    end
  end

  return seqPanel
end

local seqPanel = createSequencerPanel()

--------------------------------------------------------------------------------
-- Set pages
--------------------------------------------------------------------------------

function setPage(pageA, pageB, pageC, pageD)
  osc1Panel.visible = pageA
  osc2Panel.visible = pageA
  unisonPanel.visible = pageA
  vibratoPanel.visible = pageA
  ampEnvPanel.visible = pageA
  effectsPanel.visible = pageA

  filterPanel.visible = pageB
  hpFilterPanel.visible = pageB
  filterEnvPanel.visible = pageB
  filterEnvTargetsPanel.visible = pageB
  filterEnvTargets1Panel.visible = pageB
  filterEnvTargets2Panel.visible = pageB
  
  lfoPanel.visible = pageC
  lfoTargetPanel.visible = pageC
  lfoTargetPanel1.visible = pageC
  lfoTargetPanel2.visible = pageC
  lfoTargetPanel3.visible = pageC

  seqPanel.visible = pageD
end

pageAButton.changed = function(self)
  setPage(true, false, false, false)
end

pageBButton.changed = function(self)
  setPage(false, true, false, false)
end

pageCButton.changed = function(self)
  setPage(false, false, true, false)
end

pageDButton.changed = function(self)
  setPage(false, false, false, true)
end

-- Set start page
pageAButton.changed()

setSize(720, 480)

makePerformanceView()
