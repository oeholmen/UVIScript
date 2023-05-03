--------------------------------------------------------------------------------
-- Arp Randomizer
--------------------------------------------------------------------------------
-- Randomize the settings of the Falcon arpeggiator
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local buttonAlpha = 0.9
local buttonBackgroundColourOff = "#ff084486"
local buttonBackgroundColourOn = "#ff02ACFE"
local buttonTextColourOff = "#ff22FFFF"
local buttonTextColourOn = "#efFFFFFF"
local backgroundColour = "202020" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "F0FF42" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

--------------------------------------------------------------------------------
-- Arp Randomization Functions
--------------------------------------------------------------------------------

--{"Auto", "+/-1", "+/-2", "+/-4", "+/-5", "+/-6", "Off"}
local function getArpOctave(octaveOption)
  if octaveOption == 1 then
    octaveOption = gem.getRandom(6) + 1
  end
  octaveOption = octaveOption - 1
  return gem.getRandom(-octaveOption,octaveOption)
end

local function getArpNumStrike()
  if gem.getRandomBoolean(25) then
    return gem.getRandom(4)
  end
  return 1 -- default
end

local function getArpStepLength()
  if gem.getRandomBoolean(75) then
    return 1.0 -- default
  end

  local min = 60
  local max = 110

  if gem.getRandomBoolean() then
    min = 75
  end

  if gem.getRandomBoolean() then
    max = 100
  end

  return gem.getRandom(min, max) / 100
end

-- {"Auto", "Up, Down, Up & Down, Down & Up", "Off"}
local function getArpMode(modeOption)
  if modeOption == 1 and gem.getRandomBoolean() then
    return gem.getRandom(0,26)
  end
  
  if modeOption == 2 then
    return gem.getRandom(0,3)
  end
  
  return 0 -- default
end

-- {"Auto", "Even", "Odd", "2, 4, 8, 16", "3, 6, 12, 24", "Off"}
local function getArpNumSteps(lengthOption)
  if lengthOption == 1 then -- Auto
    return gem.getRandom(128)
  end
  if lengthOption == 2 then -- Even
    local steps = gem.getRandom(128)
    while steps % 2 ~= 0 do
      steps = gem.getRandom(128)
    end
    return steps
  end
  if lengthOption == 3 then -- Odd
    local steps = gem.getRandom(128)
    while steps % 2 == 0 do
      steps = gem.getRandom(128)
    end
    return steps
  end
  if lengthOption == 4 then
    return gem.getRandomFromTable({2, 4, 8, 16})
  end
  if lengthOption == 5 then
    return gem.getRandomFromTable({3, 6, 12, 24})
  end
end

----------------
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
local function getArpResolution(resolutionOption)
  if resolutionOption == 1 then
    if gem.getRandomBoolean(25) then
      return gem.getRandom(28)
    else
      resolutionOption = 2
    end
  end
  local position = resolutionOption + 14 -- resolutionOption will be 2 = even, 3 = dot, 4 = tri, so default starts at 16 (1/4)
  local resMax = 25 -- Max 1/32
  local resOptions = {}
  if gem.getRandomBoolean(25) then
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
  local index = gem.getRandom(#resOptions)
  print("Selected arp res options index", index)
  return resOptions[index]
end

local function getArp()
  local arp -- Holds the arpeggiator if found
  local pos = 1 -- Start pos
  local maxPos = 100 -- Max pos search
  repeat
    arp = this.parent.eventProcessors[pos] -- get the event processor at the current position
    pos = pos + 1 -- increment pos
  until type(arp) == "nil" or arp.type == "Arpeggiator" or pos > maxPos
  return arp
end

local function doArpTweaks(resolutionOption, lengthOption, octaveOption, modeOption, pitchOffsetProbability)
  local arp = getArp()

  -- No arp found, just return
  if type(arp) == "nil" or arp.type ~= "Arpeggiator" then
    print("No arp found")
    return
  end

  local arpNumSteps = getArpNumSteps(lengthOption) -- get the number of steps to set for the arpeggiator
  if type(arpNumSteps) == "number" then
    arp:setParameter("NumSteps", arpNumSteps)
  else
    arpNumSteps = arp:getParameter("NumSteps")
  end
  if resolutionOption < 5 then -- 5 = lock - no change
    arp:setParameter("Resolution", getArpResolution(resolutionOption))
  end
  if modeOption < 3 then
    arp:setParameter("Mode", getArpMode(modeOption))
  end
  arp:setParameter("NumStrike", getArpNumStrike())
  arp:setParameter("StepLength", getArpStepLength())
  if octaveOption < 7 then
    arp:setParameter("Octave", getArpOctave(octaveOption))
  end
  arp:setParameter("ArpVelocityBlend", gem.getRandom())
  for i=0,arpNumSteps do
    if i > 0 and gem.getRandomBoolean(30) then
      arp:setParameter("Step"..i.."State", gem.getRandom(0,3)) -- 0-3 def 0
    else
      arp:setParameter("Step"..i.."State", 1) -- 0-3 def 0
    end
    if gem.getRandomBoolean() then
      arp:setParameter("Step"..i.."Size", gem.getRandom()) -- 0-1 def 1
    else
      arp:setParameter("Step"..i.."Size", 1) -- 0-1 def 1
    end
    if gem.getRandomBoolean(30) then
      arp:setParameter("Step"..i.."Level", gem.getRandom()) -- 0-1 def 1
    else
      arp:setParameter("Step"..i.."Level", gem.getRandom(60,100) / 100) -- 0-1 def 1
    end
    if pitchOffsetProbability > 0 then
      if gem.getRandomBoolean(pitchOffsetProbability) then
        if gem.getRandomBoolean(75) then
          arp:setParameter("Step"..i.."Offset", gem.getRandom(-12,12)) -- Random offset within octave
        else
          arp:setParameter("Step"..i.."Offset", gem.getRandom(-48,48)) -- Random offset full range
        end
      else
        arp:setParameter("Step"..i.."Offset", 0) -- No offset
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Widgets
--------------------------------------------------------------------------------

setBackgroundColour(backgroundColour)

local spacing = 20

local panel = widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 60,
})

local label = panel:Label("Label")
label.text = "Arp Randomizer"
label.tooltip = "Randomizes the settings of the first arpeggiator found at the same level as this script"
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.fontSize = 22
label.position = {0,0}
label.size = {140,25}

local tweakArpResMenu = panel:Menu("TweakArpResolution", {"Auto", "Even", "Dot", "Tri", "Off"})
tweakArpResMenu.selected = 2
tweakArpResMenu.backgroundColour = menuBackgroundColour
tweakArpResMenu.textColour = menuTextColour
tweakArpResMenu.arrowColour = menuArrowColour
tweakArpResMenu.outlineColour = menuOutlineColour
tweakArpResMenu.displayName = "Resolution"
tweakArpResMenu.tooltip = "Set resolution randomization - Use Off to leave the resolution unchanged"
tweakArpResMenu.width = 69
tweakArpResMenu.x = label.x + label.width + spacing

local tweakArpLengthMenu = panel:Menu("TweakArpLength", {"Auto", "Even", "Odd", "2, 4, 8, 16", "3, 6, 12, 24", "Off"})
tweakArpLengthMenu.selected = 4
tweakArpLengthMenu.backgroundColour = menuBackgroundColour
tweakArpLengthMenu.textColour = menuTextColour
tweakArpLengthMenu.arrowColour = menuArrowColour
tweakArpLengthMenu.outlineColour = menuOutlineColour
tweakArpLengthMenu.displayName = "Steps"
tweakArpLengthMenu.tooltip = "Set step randomization - Use Off to leave the step setting unchanged"
tweakArpLengthMenu.width = tweakArpResMenu.width
tweakArpLengthMenu.x = tweakArpResMenu.x + tweakArpResMenu.width + spacing

local tweakArpOctaveMenu = panel:Menu("TweakArpOctave", {"Auto", "+/-1", "+/-2", "+/-4", "+/-5", "+/-6", "Off"})
tweakArpOctaveMenu.selected = 2
tweakArpOctaveMenu.backgroundColour = menuBackgroundColour
tweakArpOctaveMenu.textColour = menuTextColour
tweakArpOctaveMenu.arrowColour = menuArrowColour
tweakArpOctaveMenu.outlineColour = menuOutlineColour
tweakArpOctaveMenu.displayName = "Octave"
tweakArpOctaveMenu.tooltip = "Set max octave randomization - Use Off to leave the octave setting unchanged"
tweakArpOctaveMenu.width = tweakArpResMenu.width
tweakArpOctaveMenu.x = tweakArpLengthMenu.x + tweakArpLengthMenu.width + spacing

local tweakArpModeMenu = panel:Menu("TweakArpModeMenu", {"Auto", "Up/Down", "Off"})
tweakArpModeMenu.backgroundColour = menuBackgroundColour
tweakArpModeMenu.textColour = menuTextColour
tweakArpModeMenu.arrowColour = menuArrowColour
tweakArpModeMenu.outlineColour = menuOutlineColour
tweakArpModeMenu.displayName = "Mode"
tweakArpModeMenu.tooltip = "Set mode randomization - Use Off to leave the mode setting unchanged"
tweakArpModeMenu.width = tweakArpResMenu.width
tweakArpModeMenu.x = tweakArpOctaveMenu.x + tweakArpOctaveMenu.width + spacing

local pitchOffsetProbabilityLabel = panel:Label("PitchOffsetProbabilityLabel")
pitchOffsetProbabilityLabel.text = "Pitch offset"
pitchOffsetProbabilityLabel.tooltip = "Probability that the pitch offset is randomized - zero leaves the pitch offset unchanged"
pitchOffsetProbabilityLabel.width = tweakArpResMenu.width
pitchOffsetProbabilityLabel.x = tweakArpModeMenu.x + tweakArpModeMenu.width + spacing

local pitchOffsetProbability = panel:NumBox("PitchOffsetProbability", 0, 0, 100, true)
pitchOffsetProbability.unit = Unit.Percent
pitchOffsetProbability.showLabel = false
pitchOffsetProbability.displayName = pitchOffsetProbabilityLabel.text
pitchOffsetProbability.tooltip = pitchOffsetProbabilityLabel.tooltip
pitchOffsetProbability.backgroundColour = menuBackgroundColour
pitchOffsetProbability.textColour = menuTextColour
pitchOffsetProbability.width = tweakArpResMenu.width
pitchOffsetProbability.x = pitchOffsetProbabilityLabel.x
pitchOffsetProbability.y = pitchOffsetProbabilityLabel.y + pitchOffsetProbabilityLabel.height + 5

local tweakArpeggiatorButton = panel:OnOffButton("TweakArp")
tweakArpeggiatorButton.persistent = false
tweakArpeggiatorButton.alpha = buttonAlpha
tweakArpeggiatorButton.backgroundColourOff = buttonBackgroundColourOff
tweakArpeggiatorButton.backgroundColourOn = buttonBackgroundColourOn
tweakArpeggiatorButton.textColourOff = buttonTextColourOff
tweakArpeggiatorButton.textColourOn = buttonTextColourOn
tweakArpeggiatorButton.displayName = "Randomize"
tweakArpeggiatorButton.tooltip = "Randomize arpeggiator settings - NOTE: this changes the settings of the arpeggiator"
tweakArpeggiatorButton.size = {90,45}
tweakArpeggiatorButton.x = pitchOffsetProbability.x + pitchOffsetProbability.width + spacing
tweakArpeggiatorButton.changed = function(self)
  doArpTweaks(tweakArpResMenu.value, tweakArpLengthMenu.value, tweakArpOctaveMenu.value, tweakArpModeMenu.value, pitchOffsetProbability.value)
  self.value = false
end
