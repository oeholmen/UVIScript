--------------------------------------------------------------------------------
--! @example monoBassLine.lua
--! @brief This is a complete example showing how to create a custom instrument script.
--!
--! It shows how to control the engine and how to create a structured interface
--! with sub-panels and different kind of widgets.
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- init direct access to most used engine nodes
--------------------------------------------------------------------------------
local keygroup = Program.layers[1].keygroups[1]
local ampEnv = Program.layers[1].keygroups[1].modulations["Amp. Env"]
local oscillators = keygroup.oscillators
local filter = keygroup.inserts[1]

--------------------------------------------------------------------------------
-- Oscilllator
--------------------------------------------------------------------------------
local oscPanel = Panel("Oscs")

function formatGainInDb(value)
    if value == 0 then
        return "-inf"
    else
        local dB = 20 * math.log10(value)
        return string.format("%0.1f dB", dB)
    end
end

local oscVolume = oscPanel:Knob("Osc", 1, 0, 1)
oscVolume.fillColour = "lightgrey"
oscVolume.outlineColour = "orange"
oscVolume.mapper = Mapper.Cubic
oscVolume.changed = function(self)
    oscillators[1]:setParameter("Gain", self.value)
    self.displayText = formatGainInDb(self.value)
end
oscVolume:changed() -- force update

local subVolume = oscPanel:Knob("Sub", 0, 0, 1)
subVolume.fillColour = "lightgrey"
subVolume.outlineColour = "orange"
oscVolume.mapper = Mapper.Cubic
subVolume.changed = function(self)
    oscillators[2]:setParameter("Gain", self.value)
    self.displayText = formatGainInDb(self.value)
end
subVolume:changed() -- force update

local noiseVolume = oscPanel:Knob("Noise", 0, 0, 1)
noiseVolume.fillColour = "lightgrey"
noiseVolume.outlineColour = "orange"
oscVolume.mapper = Mapper.Cubic
noiseVolume.changed = function(self)
    oscillators[3]:setParameter("Gain", self.value)
    self.displayText = formatGainInDb(self.value)
end
noiseVolume:changed() -- force update


--------------------------------------------------------------------------------
-- Amplitude ADSR
--------------------------------------------------------------------------------

function formatTimeInSeconds(value)
    if value < 1 then
        return string.format("%0.1f ms", value*1000)
    else
        return string.format("%0.1f s", value)
    end
end

local adsrPanel = Panel("AmpEnv")

local attack = adsrPanel:Knob("Attack", 0.009, 0.009, 1.06)
attack.outlineColour = "magenta"
attack.changed = function(self)
    ampEnv:setParameter("AttackTime", self.value)
    self.displayText = formatTimeInSeconds(self.value)
end
attack:changed() -- force update

local decay = adsrPanel:Knob("Decay", 0.174, 0.174, 2.477)
decay.outlineColour = "magenta"
decay.changed = function(self)
    ampEnv:setParameter("DecayTime", self.value)
    self.displayText = formatTimeInSeconds(self.value)
end
decay:changed() -- force update

local sustain = adsrPanel:Knob("Sustain", 1, 0, 1)
sustain.outlineColour = "magenta"
sustain.changed = function(self)
    ampEnv:setParameter("SustainLevel", self.value)
    self.displayText = string.format("%0.1f %%", self.value*100.)
end
sustain:changed() -- force update

local release = adsrPanel:Knob("Release", 0.05, 0.05, 5.028)    
release.outlineColour = "magenta"
release.changed = function(self)
    ampEnv:setParameter("ReleaseTime", self.value)
    self.displayText = formatTimeInSeconds(self.value)
end
release:changed() -- force update

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

local cutoff = filterPanel:Knob("Cutoff", 1, 0, 1)
cutoff.fillColour = "lightgrey"
cutoff.outlineColour = "yellow"
cutoff.changed = function(self)
    local value = filterMapValue(self.value)
    filter:setParameter("Freq", value)
    if value < 1000 then
        self.displayText = string.format("%0.1f Hz", value)
    else
        self.displayText = string.format("%0.1f kHz", value/1000.)
    end
end
cutoff:changed() -- force update

local reso = filterPanel:Knob("Reso", 0, 0, 1)
reso.fillColour = "lightgrey"
reso.outlineColour = "yellow"
reso.changed = function(self)
    filter:setParameter("Q", self.value)
    self.displayText = string.format("%0.1f %%", self.value*100.)
end
reso:changed() -- force update


local lfoToCutoff = filterPanel:Knob("lfoToCutoff", 0, -1, 1)
lfoToCutoff.fillColour = "lightgrey"
lfoToCutoff.outlineColour = "yellow"
lfoToCutoff.changed = function(self)
    filter:getParameterConnections("Freq")[1]:setParameter("Ratio", self.value)
    self.displayText = string.format("%0.1f %%", self.value*100.)
end
lfoToCutoff:changed() -- force update


--------------------------------------------------------------------------------
-- Mini bass line Sequencer
--------------------------------------------------------------------------------
local seqPanel = Panel("Sequencer")

local resolutions = {0.5, 0.25, 0.125}
local resolutionNames = {"1/8", "1/16", "1/32"}

local numSteps = 8
local steps = seqPanel:Table("pitch", numSteps, 0, -12, 12, true)
local res = seqPanel:Menu{"Resolution", resolutionNames, selected=2}
local gate = seqPanel:Knob("Gate", 1, 0, 1)
gate.changed = function(self)
    self.displayText = string.format("%0.1f %%", self.value*100.)
end
gate:changed() -- force update

res.backgroundColour = "black"
res.textColour = "cyan"
res.arrowColour = "grey"
res.outlineColour = "#1fFFFFFF" -- transparent white

local positionTable = seqPanel:Table("steps"..tostring(i), numSteps, 0, 0, 1, true)
positionTable.enabled = false
positionTable.persistent = false

function clearPosition()
    for i = 1, numSteps do
        positionTable:setValue(i, 0)
    end
end

local arpId = 0
local heldNotes = {}

function arpeg(arpId_)
    local index = 0
    while arpId_ == arpId do
        local e = heldNotes[#heldNotes] 
        local p = resolutions[res.value]
        local note = e.note + steps:getValue(index+1)
        playNote(note, e.velocity, beat2ms(gate.value*p))
        positionTable:setValue((index - 1 + numSteps) % numSteps + 1, 0)
        positionTable:setValue((index % numSteps)+1, 1)
        index = (index+1) % numSteps
        waitBeat(p)
    end
end

--------------------------------------------------------------------------------
-- callbacks
--------------------------------------------------------------------------------
function onNote(e)   
    table.insert(heldNotes, e)
    if #heldNotes == 1 then
        arpeg(arpId)
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


--------------------------------------------------------------------------------
-- UI positioning
--------------------------------------------------------------------------------
local margin = 10

oscPanel.x = margin
oscPanel.y = margin
oscPanel.width = 400
oscPanel.height = 60

filterPanel.x = oscPanel.x
filterPanel.y = oscPanel.y + oscPanel.height + margin
filterPanel.width = 400
filterPanel.height = 60

adsrPanel.x = filterPanel.x
adsrPanel.y = filterPanel.y + filterPanel.height + margin
adsrPanel.width = 500
adsrPanel.height = 60

seqPanel.x = adsrPanel.x
seqPanel.y = adsrPanel.y + adsrPanel.height + margin
seqPanel.width = 630
seqPanel.height = 150
steps.y = steps.y + 10
steps.width = 500
steps.height = 130
positionTable.x = steps.x
positionTable.y = steps.y - 10
positionTable.width = steps.width
positionTable.height = 10
res.x = steps.x + steps.width + margin
res.y = steps.y
gate.x = steps.x + steps.width + margin
gate.y = steps.y + 70

setSize(650, 380)
makePerformanceView()
