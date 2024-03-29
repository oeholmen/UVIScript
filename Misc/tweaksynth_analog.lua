--------------------------------------------------------------------------------
-- Tweakable Synth - Analog Oscillators
--------------------------------------------------------------------------------

require "tweaksynth_common"

--------------------------------------------------------------------------------
-- Set local macro names
--------------------------------------------------------------------------------

local osc2Detune = macros[11]
local osc2Pitch = macros[12]
local osc1LfoToPWM = macros[27]
local osc2LfoToPWM = macros[28]
local unisonDetune = macros[32]
local randomPhaseStart = macros[34]
local lfoToHardsync1 = macros[38]
local lfoToHardsync2 = macros[39]
local filterEnvToHardsync1 = macros[40]
local filterEnvToHardsync2 = macros[41]
local panSpread = macros[43]
local stereoSpread = macros[44]
local osc1Pitch = macros[45]
local lfoToPitchOsc1 = macros[46]
local lfoToPitchOsc2 = macros[47]
local filterEnvToPitchOsc1 = macros[48]
local filterEnvToPitchOsc2 = macros[49]
local atToHardsync1 = macros[58]

--------------------------------------------------------------------------------
-- Osc 1
--------------------------------------------------------------------------------

function createOsc1Panel()
  local osc1Panel = Panel("Osc1Panel")

  osc1Panel:Label("Osc 1")
  
  local osc1ShapeKnob = osc1Panel:Knob("Osc1Wave", 1, 1, 6, true)
  osc1ShapeKnob.displayName = "Waveform"
  osc1ShapeKnob.fillColour = knobColour
  osc1ShapeKnob.outlineColour = osc1Colour
  osc1ShapeKnob.changed = function(self)
    osc1:setParameter("Waveform", self.value)
    local waveforms = {"Saw", "Square", "Triangle", "Sine", "Noise", "Pulse"}
    self.displayText = waveforms[self.value]
  end
  osc1ShapeKnob:changed()
  table.insert(tweakables, {widget=osc1ShapeKnob,min=6,default=10,noDefaultTweak=true,category="synthesis"})
  
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

  local hardsyncKnob = osc1Panel:Knob("HardsyncOsc1", 0, 0, 36)
  hardsyncKnob.displayName = "Hardsync"
  hardsyncKnob.mapper = Mapper.Quadratic
  hardsyncKnob.fillColour = knobColour
  hardsyncKnob.outlineColour = osc1Colour
  hardsyncKnob.changed = function(self)
    osc1:setParameter("HardSyncShift", self.value)
  end
  hardsyncKnob:changed()
  table.insert(tweakables, {widget=hardsyncKnob,min=36,zero=50,default=50,noDefaultTweak=true,category="synthesis"})

  local atToHardsycKnob = osc1Panel:Knob("AtToHarsyncosc1", 0, 0, 1)
  atToHardsycKnob.displayName = "AT->Sync"
  atToHardsycKnob.fillColour = knobColour
  atToHardsycKnob.outlineColour = filterColour
  atToHardsycKnob.changed = function(self)
    atToHardsync1:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  atToHardsycKnob:changed()
  table.insert(tweakables, {widget=atToHardsycKnob,zero=25,default=25,category="synthesis"})

  return osc1Panel
end

local osc1Panel = createOsc1Panel()

--------------------------------------------------------------------------------
-- Osc 2
--------------------------------------------------------------------------------

function createOsc2Panel()
  local osc2Panel = Panel("Osc2Panel")

  osc2Panel:Label("Osc 2")

  local osc2ShapeKnob = osc2Panel:Knob("Osc2Wave", 1, 1, 6, true)
  osc2ShapeKnob.displayName = "Waveform"
  osc2ShapeKnob.fillColour = knobColour
  osc2ShapeKnob.outlineColour = osc2Colour
  osc2ShapeKnob.changed = function(self)
    osc2:setParameter("Waveform", self.value)
    local waveforms = {"Saw", "Square", "Triangle", "Sine", "Noise", "Pulse"}
    self.displayText = waveforms[self.value]
  end
  osc2ShapeKnob:changed()
  table.insert(tweakables, {widget=osc2ShapeKnob,min=6,default=10,noDefaultTweak=true,category="synthesis"})

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

  local hardsyncKnob = osc2Panel:Knob("HardsyncOsc2", 0, 0, 36)
  hardsyncKnob.displayName = "Hardsync"
  hardsyncKnob.mapper = Mapper.Quadratic
  hardsyncKnob.fillColour = knobColour
  hardsyncKnob.outlineColour = osc1Colour
  hardsyncKnob.changed = function(self)
    osc2:setParameter("HardSyncShift", self.value)
  end
  hardsyncKnob:changed()
  table.insert(tweakables, {widget=hardsyncKnob,min=36,zero=75,default=50,noDefaultTweak=true,category="synthesis"})

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

  local randomPhaseStartKnob = unisonPanel:Knob("RandomPhaseStart", 0, 0, 1)
  randomPhaseStartKnob.displayName = "Rand Phase"
  randomPhaseStartKnob.fillColour = knobColour
  randomPhaseStartKnob.outlineColour = unisonColour
  randomPhaseStartKnob.changed = function(self)
    randomPhaseStart:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  randomPhaseStartKnob:changed()
  table.insert(tweakables, {widget=randomPhaseStartKnob,ceiling=0.3,probability=70,default=30,zero=30,category="synthesis"})

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

  unisonVoicesKnob.changed = function(self)
    local factor = 1 / 8
    local value = factor * self.value
    local unisonActive = false
    osc1:setParameter("NumOscillators", self.value)
    osc2:setParameter("NumOscillators", self.value)
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

  local osc1LfoToPWMKnob = lfoTargetPanel1:Knob("LfoToOsc1PWM", 0, 0, 0.5)
  osc1LfoToPWMKnob.displayName = "PWM"
  osc1LfoToPWMKnob.mapper = Mapper.Quartic
  osc1LfoToPWMKnob.fillColour = knobColour
  osc1LfoToPWMKnob.outlineColour = lfoColour
  osc1LfoToPWMKnob.changed = function(self)
    osc1LfoToPWM:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  osc1LfoToPWMKnob:changed()

  local lfoToHardsync1Knob = lfoTargetPanel1:Knob("LfoToHardsync1", 0, 0, 1)
  lfoToHardsync1Knob.displayName = "Hardsync"
  lfoToHardsync1Knob.fillColour = knobColour
  lfoToHardsync1Knob.outlineColour = lfoColour
  lfoToHardsync1Knob.changed = function(self)
    lfoToHardsync1:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  lfoToHardsync1Knob:changed()

  local lfoToPitchOsc1Knob = lfoTargetPanel1:Knob("LfoToPitchOsc1Knob", 0, 0, 48)
  lfoToPitchOsc1Knob.displayName = "Pitch"
  lfoToPitchOsc1Knob.mapper = Mapper.Quartic
  lfoToPitchOsc1Knob.fillColour = knobColour
  lfoToPitchOsc1Knob.outlineColour = lfoColour
  lfoToPitchOsc1Knob.changed = function(self)
    local factor = 1 / 48;
    local value = (self.value * factor)
    lfoToPitchOsc1:setParameter("Value", value)
  end
  lfoToPitchOsc1Knob:changed()

  table.insert(tweakables, {widget=lfoToPitchOsc1Knob,ceiling=0.1,probability=75,default=50,noDefaultTweak=true,zero=50,category="modulation"})
  table.insert(tweakables, {widget=osc1LfoToPWMKnob,ceiling=0.25,probability=90,default=50,category="modulation"})
  table.insert(tweakables, {widget=lfoToHardsync1Knob,zero=50,default=50,noDefaultTweak=true,category="modulation"})

  return lfoTargetPanel1
end

local lfoTargetPanel1 = createLfoTargetPanel1()

--------------------------------------------------------------------------------
-- LFO Targets Osc 2
--------------------------------------------------------------------------------

function createLfoTargetPanel2()
  local lfoTargetPanel2 = Panel("LfoTargetPanel2")
  lfoTargetPanel2:Label("Osc 2")

  local osc2LfoToPWMKnob = lfoTargetPanel2:Knob("LfoToOsc2PWM", 0, 0, 0.5)
  osc2LfoToPWMKnob.displayName = "PWM"
  osc2LfoToPWMKnob.mapper = Mapper.Quartic
  osc2LfoToPWMKnob.fillColour = knobColour
  osc2LfoToPWMKnob.outlineColour = lfoColour
  osc2LfoToPWMKnob.changed = function(self)
    osc2LfoToPWM:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  osc2LfoToPWMKnob:changed()

  local lfoToHardsync2Knob = lfoTargetPanel2:Knob("LfoToHardsync2", 0, 0, 1)
  lfoToHardsync2Knob.displayName = "Hardsync"
  lfoToHardsync2Knob.fillColour = knobColour
  lfoToHardsync2Knob.outlineColour = lfoColour
  lfoToHardsync2Knob.changed = function(self)
    lfoToHardsync2:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  lfoToHardsync2Knob:changed()

  local lfoToPitchOsc2Knob = lfoTargetPanel2:Knob("LfoToPitchOsc2Knob", 0, 0, 48)
  lfoToPitchOsc2Knob.displayName = "Pitch"
  lfoToPitchOsc2Knob.mapper = Mapper.Quartic
  lfoToPitchOsc2Knob.fillColour = knobColour
  lfoToPitchOsc2Knob.outlineColour = lfoColour
  lfoToPitchOsc2Knob.changed = function(self)
    local factor = 1 / 48;
    local value = (self.value * factor)
    lfoToPitchOsc2:setParameter("Value", value)
  end
  lfoToPitchOsc2Knob:changed()

  table.insert(tweakables, {widget=lfoToPitchOsc2Knob,ceiling=0.1,probability=75,default=80,noDefaultTweak=true,zero=30,category="modulation"})
  table.insert(tweakables, {widget=osc2LfoToPWMKnob,ceiling=0.25,probability=90,default=50,category="modulation"})
  table.insert(tweakables, {widget=lfoToHardsync2Knob,zero=50,default=50,noDefaultTweak=true,category="modulation"})

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

  local filterEnvToHardsync1Knob = filterEnvTargets1Panel:Knob("FilterEnvToHardsync1Knob", 0, 0, 1)
  filterEnvToHardsync1Knob.displayName = "Hardsync"
  filterEnvToHardsync1Knob.fillColour = knobColour
  filterEnvToHardsync1Knob.outlineColour = filterEnvColour
  filterEnvToHardsync1Knob.changed = function(self)
    filterEnvToHardsync1:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  filterEnvToHardsync1Knob:changed()
  table.insert(tweakables, {widget=filterEnvToHardsync1Knob,zero=25,default=50,category="filter"})

  local filterEnvToPitchOsc1Knob = filterEnvTargets1Panel:Knob("FilterEnvToPitchOsc1", 0, 0, 48)
  filterEnvToPitchOsc1Knob.displayName = "Pitch"
  filterEnvToPitchOsc1Knob.mapper = Mapper.Quartic
  filterEnvToPitchOsc1Knob.fillColour = knobColour
  filterEnvToPitchOsc1Knob.outlineColour = filterEnvColour
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

  local filterEnvToHardsync2Knob = filterEnvTargets2Panel:Knob("FilterEnvToHardsync2Knob", 0, 0, 1)
  filterEnvToHardsync2Knob.displayName = "Hardsync"
  filterEnvToHardsync2Knob.fillColour = knobColour
  filterEnvToHardsync2Knob.outlineColour = filterEnvColour
  filterEnvToHardsync2Knob.changed = function(self)
    filterEnvToHardsync2:setParameter("Value", self.value)
    self.displayText = percent(self.value)
  end
  filterEnvToHardsync2Knob:changed()
  table.insert(tweakables, {widget=filterEnvToHardsync2Knob,zero=25,default=50,category="filter"})

  local filterEnvToPitchOsc2Knob = filterEnvTargets2Panel:Knob("FilterEnvToPitchOsc2", 0, 0, 48)
  filterEnvToPitchOsc2Knob.displayName = "Pitch"
  filterEnvToPitchOsc2Knob.mapper = Mapper.Quartic
  filterEnvToPitchOsc2Knob.fillColour = knobColour
  filterEnvToPitchOsc2Knob.outlineColour = filterEnvColour
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
pagePanel.backgroundColour = "#00000000"
pagePanel.x = marginX
pagePanel.y = marginY
pagePanel.width = 713
pagePanel.height = 30

local synthesisPageButton = pagePanel:OnOffButton("SynthesisPage", true)
synthesisPageButton.displayName = "Synthesis"
synthesisPageButton.persistent = false
local filterPageButton = pagePanel:OnOffButton("FilterPage", false)
filterPageButton.displayName = "Filters"
filterPageButton.persistent = false
local modulationPageButton = pagePanel:OnOffButton("ModulationPage", false)
modulationPageButton.displayName = "Modulation"
modulationPageButton.persistent = false
local twequencerPageButton = pagePanel:OnOffButton("TwequencerPage", false)
twequencerPageButton.displayName = "Twequencer"
twequencerPageButton.persistent = false
local patchmakerPageButton = pagePanel:OnOffButton("PatchmakerPage", false)
patchmakerPageButton.displayName = "Patchmaker"
patchmakerPageButton.persistent = false

mixerPanel.backgroundColour = "#3f000000"
mixerPanel.x = marginX
mixerPanel.y = pagePanel.height + marginY * 2
mixerPanel.width = width
mixerPanel.height = height

--------------------------------------------------------------------------------
-- Set up pages
--------------------------------------------------------------------------------

function setupSynthesisPage()
  --osc1Panel.backgroundColour = "#33AAAA11"
  osc1Panel.backgroundColour = bgColor
  osc1Panel.x = marginX
  osc1Panel.y = mixerPanel.y + height + marginY
  osc1Panel.width = width
  osc1Panel.height = height

  --osc2Panel.backgroundColour = "#44AAAA33"
  osc2Panel.backgroundColour = bgColor
  osc2Panel.x = marginX
  osc2Panel.y = osc1Panel.y + height + marginY
  osc2Panel.width = width
  osc2Panel.height = height

  --unisonPanel.backgroundColour = "#55AAAA44"
  unisonPanel.backgroundColour = bgColor
  unisonPanel.x = marginX
  unisonPanel.y = osc2Panel.y + height + marginY
  unisonPanel.width = width
  unisonPanel.height = height

  --vibratoPanel.backgroundColour = "#66AAAA66"
  vibratoPanel.backgroundColour = bgColor
  vibratoPanel.x = marginX
  vibratoPanel.y = unisonPanel.y + height + marginY
  vibratoPanel.width = width
  vibratoPanel.height = height

  --ampEnvPanel.backgroundColour = "#77AAAA77"
  ampEnvPanel.backgroundColour = bgColor
  ampEnvPanel.x = marginX
  ampEnvPanel.y = vibratoPanel.y + height + marginY
  ampEnvPanel.width = width
  ampEnvPanel.height = height

  --effectsPanel.backgroundColour = "#88AAAA99"
  effectsPanel.backgroundColour = bgColor
  effectsPanel.x = marginX
  effectsPanel.y = ampEnvPanel.y + height + marginY
  effectsPanel.width = width
  effectsPanel.height = height
end

function setupFilterPage()
  --filterPanel.backgroundColour = "#33AA0011"
  filterPanel.backgroundColour = bgColor
  filterPanel.x = marginX
  filterPanel.y = mixerPanel.y + height + marginY
  filterPanel.width = width
  filterPanel.height = height

  --hpFilterPanel.backgroundColour = "#44AA0022"
  hpFilterPanel.backgroundColour = bgColor
  hpFilterPanel.x = marginX
  hpFilterPanel.y = filterPanel.y + height + marginY
  hpFilterPanel.width = width
  hpFilterPanel.height = height

  --filterEnvPanel.backgroundColour = "#55AA0033"
  filterEnvPanel.backgroundColour = bgColor
  filterEnvPanel.x = marginX
  filterEnvPanel.y = hpFilterPanel.y + height + marginY
  filterEnvPanel.width = width
  filterEnvPanel.height = height

  --filterEnvTargetsPanel.backgroundColour = "#66AA0044"
  filterEnvTargetsPanel.backgroundColour = bgColor
  filterEnvTargetsPanel.x = marginX
  filterEnvTargetsPanel.y = filterEnvPanel.y + height + marginY
  filterEnvTargetsPanel.width = width
  filterEnvTargetsPanel.height = height

  --filterEnvTargets1Panel.backgroundColour = "#66AA0066"
  filterEnvTargets1Panel.backgroundColour = bgColor
  filterEnvTargets1Panel.x = marginX
  filterEnvTargets1Panel.y = filterEnvTargetsPanel.y + height
  filterEnvTargets1Panel.width = width
  filterEnvTargets1Panel.height = height

  --filterEnvTargets2Panel.backgroundColour = "#66AA0088"
  filterEnvTargets2Panel.backgroundColour = bgColor
  filterEnvTargets2Panel.x = marginX
  filterEnvTargets2Panel.y = filterEnvTargets1Panel.y + height
  filterEnvTargets2Panel.width = width
  filterEnvTargets2Panel.height = height
end

function setupModulationPage()
  --lfoPanel.backgroundColour = "#33000022"
  lfoPanel.backgroundColour = bgColor
  lfoPanel.x = marginX
  lfoPanel.y = mixerPanel.y + height + marginY
  lfoPanel.width = width
  lfoPanel.height = height * 2

  --lfoTargetPanel.backgroundColour = "#44000033"
  lfoTargetPanel.backgroundColour = bgColor
  lfoTargetPanel.x = marginX
  lfoTargetPanel.y = lfoPanel.y + lfoPanel.height + marginY
  lfoTargetPanel.width = width
  lfoTargetPanel.height = height

  --lfoTargetPanel1.backgroundColour = "#44000055"
  lfoTargetPanel1.backgroundColour = bgColor
  lfoTargetPanel1.x = marginX
  lfoTargetPanel1.y = lfoTargetPanel.y + height
  lfoTargetPanel1.width = width
  lfoTargetPanel1.height = height

  --lfoTargetPanel2.backgroundColour = "#44000077"
  lfoTargetPanel2.backgroundColour = bgColor
  lfoTargetPanel2.x = marginX
  lfoTargetPanel2.y = lfoTargetPanel1.y + height
  lfoTargetPanel2.width = width
  lfoTargetPanel2.height = height

  --lfoTargetPanel3.backgroundColour = "#44000099"
  lfoTargetPanel3.backgroundColour = bgColor
  lfoTargetPanel3.x = marginX
  lfoTargetPanel3.y = lfoTargetPanel2.y + height
  lfoTargetPanel3.width = width
  lfoTargetPanel3.height = height
end

setupSynthesisPage()
setupFilterPage()
setupModulationPage()

local tweqPanel = createTwequencerPanel()

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

synthesisPageButton.changed = function(self)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  setPage(1)
end

filterPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  setPage(2)
end

modulationPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  setPage(3)
end

twequencerPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  patchmakerPageButton:setValue(false, false)
  setPage(4)
end

patchmakerPageButton.changed = function(self)
  synthesisPageButton:setValue(false, false)
  filterPageButton:setValue(false, false)
  modulationPageButton:setValue(false, false)
  twequencerPageButton:setValue(false, false)
  setPage(5)
end

-- Set start page
synthesisPageButton.changed()

setSize(720, 480)

makePerformanceView()
