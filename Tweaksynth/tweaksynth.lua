--------------------------------------------------------------------------------
-- Tweakable Synth - Wavetable Oscillators
--------------------------------------------------------------------------------

require "tweaksynth_common"

--------------------------------------------------------------------------------
-- Set local macro names
--------------------------------------------------------------------------------

local osc1Shape = macros[1]
local lfoToWaveSpread1 = macros[7]
local osc2Shape = macros[9]
local osc2Detune = macros[11]
local osc2Pitch = macros[12]
local lfoToWaveSpread2 = macros[17]
local osc1LfoToPD = macros[27]
local osc2LfoToPD = macros[28]
local unisonDetune = macros[32]
local unisonVoices = macros[34]
local lfoToWT1 = macros[38]
local lfoToWT2 = macros[39]
local filterEnvToWT1 = macros[40]
local filterEnvToWT2 = macros[41]
local panSpread = macros[43]
local stereoSpread = macros[44]
local osc1Pitch = macros[45]
local lfoToPitchOsc1 = macros[46]
local lfoToPitchOsc2 = macros[47]
local filterEnvToPitchOsc1 = macros[48]
local filterEnvToPitchOsc2 = macros[49]
local waveSpread = macros[57]
local wheelToShape1 = macros[58]
local wheelToShape2 = macros[59]
local atToShape1 = macros[60]

--------------------------------------------------------------------------------
-- Osc 1
--------------------------------------------------------------------------------

function createOsc1Panel()
  local osc1Panel = Panel("Osc1Panel")

  osc1Panel:Label("Osc 1")
  
  local osc1ShapeKnob = osc1Panel:Knob("Osc1Wave", 0, 0, 1)
  osc1ShapeKnob.displayName = "Wave"
  osc1ShapeKnob.fillColour = knobColour
  osc1ShapeKnob.outlineColour = osc1Colour
  osc1ShapeKnob.changed = function(self)
    osc1Shape:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  osc1ShapeKnob:changed()
  table.insert(tweakables, {widget=osc1ShapeKnob,default=10,category="synthesis"})
  
  local osc1PhaseKnob = osc1Panel:Knob("Osc1StartPhase", 0, 0, 1)
  osc1PhaseKnob.displayName = "Start Phase"
  osc1PhaseKnob.fillColour = knobColour
  osc1PhaseKnob.outlineColour = osc1Colour
  osc1PhaseKnob.changed = function(self)
    osc1:setParameter("StartPhase", self.value)
    self.displayText = percent(self.value)
  end
  osc1PhaseKnob:changed()
  table.insert(tweakables, {widget=osc1PhaseKnob,default=50,category="synthesis"})
  
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
  table.insert(tweakables, {widget=osc1PitchKnob,min=-2,max=2,default=80,noDefaultTweak=true,zero=25,category="synthesis"})

  local aftertouchToWaveKnob = osc1Panel:Knob("AftertouchToWave1", 0, -1, 1)
  aftertouchToWaveKnob.displayName = "AT->Wave"
  aftertouchToWaveKnob.fillColour = knobColour
  aftertouchToWaveKnob.outlineColour = filterColour
  aftertouchToWaveKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    atToShape1:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  aftertouchToWaveKnob:changed()
  table.insert(tweakables, {widget=aftertouchToWaveKnob,bipolar=25,excludeWithDuration=true,category="synthesis"})

  local wheelToWaveKnob = osc1Panel:Knob("WheelToWave1", 0, -1, 1)
  wheelToWaveKnob.displayName = "Wheel->Wave"
  wheelToWaveKnob.fillColour = knobColour
  wheelToWaveKnob.outlineColour = filterColour
  wheelToWaveKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    wheelToShape1:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  wheelToWaveKnob:changed()
  table.insert(tweakables, {widget=wheelToWaveKnob,bipolar=25,excludeWithDuration=true,category="synthesis"})

  return osc1Panel
end

local osc1Panel = createOsc1Panel()

--------------------------------------------------------------------------------
-- Osc 2
--------------------------------------------------------------------------------

function createOsc2Panel()
  local osc2Panel = Panel("Osc2Panel")

  osc2Panel:Label("Osc 2")

  local osc2ShapeKnob = osc2Panel:Knob("Osc2Wave", 0, 0, 1)
  osc2ShapeKnob.displayName = "Wave"
  osc2ShapeKnob.fillColour = knobColour
  osc2ShapeKnob.outlineColour = osc2Colour
  osc2ShapeKnob.changed = function(self)
    osc2Shape:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  osc2ShapeKnob:changed()
  table.insert(tweakables, {widget=osc2ShapeKnob,default=10,category="synthesis"})

  local osc2PhaseKnob = osc2Panel:Knob("Osc2StartPhase", 0, 0, 1)
  osc2PhaseKnob.displayName = "Start Phase"
  osc2PhaseKnob.fillColour = knobColour
  osc2PhaseKnob.outlineColour = osc2Colour
  osc2PhaseKnob.changed = function(self)
    osc2:setParameter("StartPhase", self.value)
    self.displayText = percent(self.value)
  end
  osc2PhaseKnob:changed()
  table.insert(tweakables, {widget=osc2PhaseKnob,default=50,category="synthesis"})

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
  table.insert(tweakables, {widget=osc2PitchKnob,min=-24,max=24,floor=-12,ceiling=12,probability=50,default=70,noDefaultTweak=true,zero=20,category="synthesis"})

  local osc2DetuneKnob = osc2Panel:Knob("Osc2FinePitch", 0, 0, 1)
  osc2DetuneKnob.displayName = "Fine Pitch"
  osc2DetuneKnob.fillColour = knobColour
  osc2DetuneKnob.outlineColour = osc2Colour
  osc2DetuneKnob.changed = function(self)
    osc2Detune:setParameter("Value", self.value)
  end
  osc2DetuneKnob:changed()
  table.insert(tweakables, {widget=osc2DetuneKnob,ceiling=0.25,probability=80,default=30,category="synthesis"})

  local wheelToWaveKnob = osc2Panel:Knob("WheelToWave2", 0, -1, 1)
  wheelToWaveKnob.displayName = "Wheel->Wave"
  wheelToWaveKnob.fillColour = knobColour
  wheelToWaveKnob.outlineColour = filterColour
  wheelToWaveKnob.changed = function(self)
    local value = (self.value + 1) * 0.5
    wheelToShape2:setParameter("Value", value)
    self.displayText = percent(self.value)
  end
  wheelToWaveKnob:changed()
  table.insert(tweakables, {widget=wheelToWaveKnob,bipolar=25,excludeWithDuration=true,category="synthesis"})

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
  table.insert(tweakables, {widget=panSpreadKnob,ceiling=0.6,probability=70,default=30,category="synthesis"})

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
  table.insert(tweakables, {widget=unisonDetuneKnob,ceiling=0.3,probability=80,default=50,category="synthesis"})

  local stereoSpreadKnob = unisonPanel:Knob("StereoSpread", 0, 0, 1)
  stereoSpreadKnob.displayName = "Stereo Spread"
  stereoSpreadKnob.fillColour = knobColour
  stereoSpreadKnob.outlineColour = unisonColour
  stereoSpreadKnob.changed = function(self)
    stereoSpread:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  stereoSpreadKnob:changed()
  table.insert(tweakables, {widget=stereoSpreadKnob,ceiling=0.5,probability=40,default=40,category="synthesis"})

  local waveSpreadKnob = unisonPanel:Knob("WaveSpread", 0, 0, 1)
  waveSpreadKnob.displayName = "Wave Spread"
  waveSpreadKnob.fillColour = knobColour
  waveSpreadKnob.outlineColour = unisonColour
  waveSpreadKnob.changed = function(self)
    waveSpread:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  waveSpreadKnob:changed()
  table.insert(tweakables, {widget=waveSpreadKnob,ceiling=0.5,probability=30,default=30,category="synthesis"})

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
  table.insert(tweakables, {widget=unisonVoicesKnob,min=8,default=25,excludeWithDuration=true,category="synthesis"})

  return unisonPanel
end

local unisonPanel = createUnisonPanel()

--------------------------------------------------------------------------------
-- Mixer
--------------------------------------------------------------------------------

local mixerPanel = createMixerPanel()

--------------------------------------------------------------------------------
-- Low-pass Filter
--------------------------------------------------------------------------------

local filterPanel = createFilterPanel()

--------------------------------------------------------------------------------
-- High-pass Filter
--------------------------------------------------------------------------------

local hpFilterPanel = createHpFilterPanel()

--------------------------------------------------------------------------------
-- LFO
--------------------------------------------------------------------------------

local lfoPanel = createLfoPanel()

--------------------------------------------------------------------------------
-- LFO Targets Noise Osc
--------------------------------------------------------------------------------

local lfoTargetPanel3 = createLfoTargetPanel3()

--------------------------------------------------------------------------------
-- LFO Targets
--------------------------------------------------------------------------------

local lfoTargetPanel = createLfoTargetPanel()

--------------------------------------------------------------------------------
-- LFO Targets Osc 1
--------------------------------------------------------------------------------

function createLfoTargetPanel1()
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

  table.insert(tweakables, {widget=lfoToPitchOsc1Knob,ceiling=0.1,probability=75,default=50,noDefaultTweak=true,zero=50,category="modulation"})
  table.insert(tweakables, {widget=lfoToWaveSpread1Knob,bipolar=80,default=50,category="modulation"})
  table.insert(tweakables, {widget=osc1LfoToPhaseDistortionKnob,ceiling=0.25,probability=90,default=50,category="modulation"})
  table.insert(tweakables, {widget=lfoToWT1Knob,bipolar=25,default=25,category="modulation"})

  return lfoTargetPanel1
end

local lfoTargetPanel1 = createLfoTargetPanel1()

--------------------------------------------------------------------------------
-- LFO Targets Osc 2
--------------------------------------------------------------------------------

function createLfoTargetPanel2()
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

  table.insert(tweakables, {widget=lfoToPitchOsc2Knob,ceiling=0.1,probability=75,default=80,noDefaultTweak=true,zero=30,category="modulation"})
  table.insert(tweakables, {widget=lfoToWaveSpread2Knob,bipolar=80,default=50,category="modulation"})
  table.insert(tweakables, {widget=osc2LfoToPhaseDistortionKnob,ceiling=0.25,probability=90,default=50,category="modulation"})
  table.insert(tweakables, {widget=lfoToWT2Knob,bipolar=25,default=25,category="modulation"})

  return lfoTargetPanel2
end

local lfoTargetPanel2 = createLfoTargetPanel2()

--------------------------------------------------------------------------------
-- Amp Env
--------------------------------------------------------------------------------

local ampEnvPanel = createAmpEnvPanel()

--------------------------------------------------------------------------------
-- Filter Env
--------------------------------------------------------------------------------

local filterEnvPanel = createFilterEnvPanel()

--------------------------------------------------------------------------------
-- Filter Env Targets
--------------------------------------------------------------------------------

function createFilterEnvTargets1Panel()
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
  table.insert(tweakables, {widget=filterEnvToWT1Knob,bipolar=25,category="filter"})

  local filterEnvToPitchOsc1Knob = filterEnvTargets1Panel:Knob("FilterEnvToPitchOsc1", 0, 0, 48)
  filterEnvToPitchOsc1Knob.displayName = "Osc 1 Pitch"
  filterEnvToPitchOsc1Knob.mapper = Mapper.Quartic
  filterEnvToPitchOsc1Knob.fillColour = knobColour
  filterEnvToPitchOsc1Knob.outlineColour = lfoColour
  filterEnvToPitchOsc1Knob.changed = function(self)
    local factor = 1 / 48;
    local value = self.value * factor
    filterEnvToPitchOsc1:setParameter("Value", value)
  end
  filterEnvToPitchOsc1Knob:changed()
  table.insert(tweakables, {widget=filterEnvToPitchOsc1Knob,ceiling=0.1,probability=70,default=80,noDefaultTweak=true,zero=30,category="filter"})

  return filterEnvTargets1Panel
end

function createFilterEnvTargets2Panel()
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
  table.insert(tweakables, {widget=filterEnvToWT2Knob,bipolar=25,category="filter"})

  local filterEnvToPitchOsc2Knob = filterEnvTargets2Panel:Knob("FilterEnvToPitchOsc2", 0, 0, 48)
  filterEnvToPitchOsc2Knob.displayName = "Osc 2 Pitch"
  filterEnvToPitchOsc2Knob.mapper = Mapper.Quartic
  filterEnvToPitchOsc2Knob.fillColour = knobColour
  filterEnvToPitchOsc2Knob.outlineColour = lfoColour
  filterEnvToPitchOsc2Knob.changed = function(self)
    local factor = 1 / 48;
    local value = self.value * factor
    filterEnvToPitchOsc2:setParameter("Value", value)
  end
  filterEnvToPitchOsc2Knob:changed()
  table.insert(tweakables, {widget=filterEnvToPitchOsc2Knob,ceiling=0.1,probability=70,default=70,noDefaultTweak=true,zero=20,category="filter"})

  return filterEnvTargets2Panel
end

local filterEnvTargetsPanel = createFilterEnvTargetsPanel()
local filterEnvTargets1Panel = createFilterEnvTargets1Panel()
local filterEnvTargets2Panel = createFilterEnvTargets2Panel()

--------------------------------------------------------------------------------
-- Effects
--------------------------------------------------------------------------------

local effectsPanel = createEffectsPanel()

--------------------------------------------------------------------------------
-- Vibrato
--------------------------------------------------------------------------------

local vibratoPanel = createVibratoPanel()

--------------------------------------------------------------------------------
-- Pages
--------------------------------------------------------------------------------

local pagePanel = Panel("PagePanel")
pagePanel.x = marginX
pagePanel.y = marginY
pagePanel.width = 713
pagePanel.height = 30

local pageAButton = pagePanel:OnOffButton("PageA", true)
pageAButton.displayName = "Synthesis"
local pageBButton = pagePanel:OnOffButton("PageB", false)
pageBButton.displayName = "Filters"
local pageCButton = pagePanel:OnOffButton("PageC", false)
pageCButton.displayName = "Modulation"
local pageDButton = pagePanel:OnOffButton("PageD", false)
pageDButton.displayName = "Twequencer"
local pageEButton = pagePanel:OnOffButton("PageE", false)
pageEButton.displayName = "Patchmaker"

mixerPanel.x = marginX
mixerPanel.y = pagePanel.height + marginY * 2
mixerPanel.width = width
mixerPanel.height = height

--------------------------------------------------------------------------------
-- Page A
--------------------------------------------------------------------------------

function setupPageA()
  osc1Panel.backgroundColour = "#33AAAA11"
  osc1Panel.x = marginX
  osc1Panel.y = mixerPanel.y + height + marginY
  osc1Panel.width = width
  osc1Panel.height = height

  osc2Panel.backgroundColour = "#44AAAA33"
  osc2Panel.x = marginX
  osc2Panel.y = osc1Panel.y + height + marginY
  osc2Panel.width = width
  osc2Panel.height = height

  unisonPanel.backgroundColour = "#55AAAA44"
  unisonPanel.x = marginX
  unisonPanel.y = osc2Panel.y + height + marginY
  unisonPanel.width = width
  unisonPanel.height = height

  vibratoPanel.backgroundColour = "#66AAAA66"
  vibratoPanel.x = marginX
  vibratoPanel.y = unisonPanel.y + height + marginY
  vibratoPanel.width = width
  vibratoPanel.height = height

  ampEnvPanel.backgroundColour = "#77AAAA77"
  ampEnvPanel.x = marginX
  ampEnvPanel.y = vibratoPanel.y + height + marginY
  ampEnvPanel.width = width
  ampEnvPanel.height = height

  effectsPanel.backgroundColour = "#88AAAA99"
  effectsPanel.x = marginX
  effectsPanel.y = ampEnvPanel.y + height + marginY
  effectsPanel.width = width
  effectsPanel.height = height
end

setupPageA()

--------------------------------------------------------------------------------
-- Page B
--------------------------------------------------------------------------------

function setupPageB()
  filterPanel.backgroundColour = "#33AA0011"
  filterPanel.x = marginX
  filterPanel.y = mixerPanel.y + height + marginY
  filterPanel.width = width
  filterPanel.height = height

  hpFilterPanel.backgroundColour = "#44AA0022"
  hpFilterPanel.x = marginX
  hpFilterPanel.y = filterPanel.y + height + marginY
  hpFilterPanel.width = width
  hpFilterPanel.height = height

  filterEnvPanel.backgroundColour = "#55AA0033"
  filterEnvPanel.x = marginX
  filterEnvPanel.y = hpFilterPanel.y + height + marginY
  filterEnvPanel.width = width
  filterEnvPanel.height = height

  filterEnvTargetsPanel.backgroundColour = "#66AA0044"
  filterEnvTargetsPanel.x = marginX
  filterEnvTargetsPanel.y = filterEnvPanel.y + height + marginY
  filterEnvTargetsPanel.width = width
  filterEnvTargetsPanel.height = height

  filterEnvTargets1Panel.backgroundColour = "#66AA0066"
  filterEnvTargets1Panel.x = marginX
  filterEnvTargets1Panel.y = filterEnvTargetsPanel.y + height
  filterEnvTargets1Panel.width = width
  filterEnvTargets1Panel.height = height

  filterEnvTargets2Panel.backgroundColour = "#66AA0088"
  filterEnvTargets2Panel.x = marginX
  filterEnvTargets2Panel.y = filterEnvTargets1Panel.y + height
  filterEnvTargets2Panel.width = width
  filterEnvTargets2Panel.height = height
end

setupPageB()

--------------------------------------------------------------------------------
-- Page C
--------------------------------------------------------------------------------

function setupPageC()
  lfoPanel.backgroundColour = "#33000022"
  lfoPanel.x = marginX
  lfoPanel.y = mixerPanel.y + height + marginY
  lfoPanel.width = width
  lfoPanel.height = height * 2

  lfoTargetPanel.backgroundColour = "#44000033"
  lfoTargetPanel.x = marginX
  lfoTargetPanel.y = lfoPanel.y + lfoPanel.height + marginY
  lfoTargetPanel.width = width
  lfoTargetPanel.height = height

  lfoTargetPanel1.backgroundColour = "#44000055"
  lfoTargetPanel1.x = marginX
  lfoTargetPanel1.y = lfoTargetPanel.y + height
  lfoTargetPanel1.width = width
  lfoTargetPanel1.height = height

  lfoTargetPanel2.backgroundColour = "#44000077"
  lfoTargetPanel2.x = marginX
  lfoTargetPanel2.y = lfoTargetPanel1.y + height
  lfoTargetPanel2.width = width
  lfoTargetPanel2.height = height

  lfoTargetPanel3.backgroundColour = "#44000099"
  lfoTargetPanel3.x = marginX
  lfoTargetPanel3.y = lfoTargetPanel2.y + height
  lfoTargetPanel3.width = width
  lfoTargetPanel3.height = height
end

setupPageC()

--------------------------------------------------------------------------------
-- Page D - Twequencer
--------------------------------------------------------------------------------

local tweqPanel = createTwequencerPanel()

--------------------------------------------------------------------------------
-- Page E - Patch Maker
--------------------------------------------------------------------------------

local tweakPanel = createPatchMakerPanel()

--------------------------------------------------------------------------------
-- Set pages
--------------------------------------------------------------------------------

function setPage(page)
  osc1Panel.visible = page == 1
  osc2Panel.visible = page == 1
  unisonPanel.visible = page == 1
  vibratoPanel.visible = page == 1
  ampEnvPanel.visible = page == 1
  effectsPanel.visible = page == 1

  filterPanel.visible = page == 2
  hpFilterPanel.visible = page == 2
  filterEnvPanel.visible = page == 2
  filterEnvTargetsPanel.visible = page == 2
  filterEnvTargets1Panel.visible = page == 2
  filterEnvTargets2Panel.visible = page == 2
  
  lfoPanel.visible = page == 3
  lfoTargetPanel.visible = page == 3
  lfoTargetPanel1.visible = page == 3
  lfoTargetPanel2.visible = page == 3
  lfoTargetPanel3.visible = page == 3

  tweqPanel.visible = page == 4
  
  tweakPanel.visible = page == 5
end

pageAButton.changed = function(self)
  pageBButton:setValue(false, false)
  pageCButton:setValue(false, false)
  pageDButton:setValue(false, false)
  pageEButton:setValue(false, false)
  setPage(1)
end

pageBButton.changed = function(self)
  pageAButton:setValue(false, false)
  pageCButton:setValue(false, false)
  pageDButton:setValue(false, false)
  pageEButton:setValue(false, false)
  setPage(2)
end

pageCButton.changed = function(self)
  pageAButton:setValue(false, false)
  pageBButton:setValue(false, false)
  pageDButton:setValue(false, false)
  pageEButton:setValue(false, false)
  setPage(3)
end

pageDButton.changed = function(self)
  pageAButton:setValue(false, false)
  pageBButton:setValue(false, false)
  pageCButton:setValue(false, false)
  pageEButton:setValue(false, false)
  setPage(4)
end

pageEButton.changed = function(self)
  pageAButton:setValue(false, false)
  pageBButton:setValue(false, false)
  pageCButton:setValue(false, false)
  pageDButton:setValue(false, false)
  setPage(5)
end

-- Set start page
pageAButton.changed()

setSize(720, 480)

makePerformanceView()
