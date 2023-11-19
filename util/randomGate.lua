----------------------------------------------
-- A random gate for incoming note events
----------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local isRunning = false

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "3EC1D3" -- Light
local knobFillColour = "E6D5B8" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local panel = widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 60,
})

local label = panel:Label("Label")
label.text = "Note Event Gate"
label.tooltip = "When the gate is closed, all note on events are stopped."
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.width = 140
label.fontSize = 22

local waitResolutionOpen = panel:Menu("WaitResolution", resolutions.getResolutionNames())
waitResolutionOpen.displayName = "Open"
waitResolutionOpen.tooltip = "The duration of open gate"
waitResolutionOpen.selected = 11
waitResolutionOpen.width = 66
waitResolutionOpen.x = label.x + label.width + 30
waitResolutionOpen.backgroundColour = menuBackgroundColour
waitResolutionOpen.textColour = widgetTextColour
waitResolutionOpen.arrowColour = menuArrowColour
waitResolutionOpen.outlineColour = menuOutlineColour

local probabilityOpen = panel:Knob("Probability", 50, 0, 100, true)
probabilityOpen.unit = Unit.Percent
probabilityOpen.displayName = "Probability"
probabilityOpen.tooltip = "Set the probability that the gate will open"
probabilityOpen.backgroundColour = widgetBackgroundColour
probabilityOpen.fillColour = knobFillColour
probabilityOpen.outlineColour = labelBackgoundColour
probabilityOpen.x = waitResolutionOpen.x + waitResolutionOpen.width + 10
probabilityOpen.width = 120

local waitResolutionClosed = panel:Menu("WaitResolutionClosed", resolutions.getResolutionNames())
waitResolutionClosed.displayName = "Close"
waitResolutionClosed.tooltip = "The duration closed gate"
waitResolutionClosed.selected = 11
waitResolutionClosed.width = 66
waitResolutionClosed.x = probabilityOpen.x + probabilityOpen.width + 30
waitResolutionClosed.backgroundColour = menuBackgroundColour
waitResolutionClosed.textColour = widgetTextColour
waitResolutionClosed.arrowColour = menuArrowColour
waitResolutionClosed.outlineColour = menuOutlineColour

local probabilityClose = panel:Knob("ProbabilityClose", 50, 0, 100, true)
probabilityClose.unit = Unit.Percent
probabilityClose.displayName = "Probability"
probabilityClose.tooltip = "Set the probability that the gate will close"
probabilityClose.backgroundColour = widgetBackgroundColour
probabilityClose.fillColour = knobFillColour
probabilityClose.outlineColour = labelBackgoundColour
probabilityClose.x = waitResolutionClosed.x + waitResolutionClosed.width + 30
probabilityClose.width = 120

local gateButton = panel:OnOffButton("GateButton", true)
gateButton.displayName = "On"
gateButton.persistent = false
gateButton.tooltip = "Shows the current state of the gate"
gateButton.backgroundColourOn = "green"
gateButton.backgroundColourOff = "303030"
gateButton.textColourOn = "white"
gateButton.textColourOff = "gray"
gateButton.size = {30,20}
gateButton.x = panel.width - 40
gateButton.y = 30
gateButton.changed = function(self)
  if self.value == true then
    gateButton.displayName = "On"
  else
    gateButton.displayName = "Off"
  end
end

function arpeg()
  local round = 0
  local waitTime = 0
  while isRunning do
    round = round + 1 -- Increment round
    if gateButton.value == true then
      if gem.getRandomBoolean(probabilityClose.value) then
        gateButton:setValue(gateButton.value == false)
      end
      waitTime = beat2ms(resolutions.getResolution(waitResolutionOpen.value))
    else
      if gem.getRandomBoolean(probabilityOpen.value) then
        gateButton:setValue(gateButton.value == false)
      end
      waitTime = beat2ms(resolutions.getResolution(waitResolutionClosed.value))
    end
    if round == 1 then
      waitTime = waitTime - 50
    end
    wait(waitTime)
  end
end

function onNote(e)
  if gateButton.value == true then
    postEvent(e)
  end
end

function onTransport(start)
  isRunning = start
  if isRunning then
    arpeg()
  elseif probabilityOpen.value > 0 then
    gateButton:setValue(true)
  end
end
