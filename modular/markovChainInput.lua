-----------------------------------------------------------------------------------------------------------------
-- Markov Chain Input - Generates notes by walking through the selected note pool using weighted scale-step moves
-----------------------------------------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local modular = require "includes.modular"
local notes = require "includes.notes"
local scales = require "includes.scales"
local noteSelector = require "includes.noteSelector"

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

-- The seven possible scale-step moves applied to the current index in the
-- selected note pool. Index 4 is "repeat note" (delta 0).
local moveDeltas = {-3, -2, -1, 0, 1, 2, 3}
local moveLabels = {"-3", "-2", "-1", "0", "+1", "+2", "+3"}
local defaultWeights = {10, 30, 50, 5, 50, 30, 10}

local currentIndex = 1
local edgeMode = 1 -- 1 = Wrap, 2 = Bounce, 3 = Clamp
local edgeDirection = 1 -- used by Bounce mode

local weightsTable = nil
local lastMoveTable = nil
local positionLabel = nil

--------------------------------------------------------------------------------
-- Markov logic
--------------------------------------------------------------------------------

local function pickMoveIndex()
  local total = 0
  for i = 1, #moveDeltas do
    total = total + weightsTable:getValue(i)
  end
  if total <= 0 then return 4 end -- Fallback to repeat
  local roll = gem.getRandom(total)
  local accum = 0
  for i = 1, #moveDeltas do
    accum = accum + weightsTable:getValue(i)
    if roll <= accum then return i end
  end
  return 4
end

local function applyMove(moveIndex, poolSize)
  local delta = moveDeltas[moveIndex]
  if edgeMode == 2 then -- Bounce
    delta = delta * edgeDirection
  end
  local nextIndex = currentIndex + delta
  if edgeMode == 1 then -- Wrap
    nextIndex = ((nextIndex - 1) % poolSize) + 1
  elseif edgeMode == 2 then -- Bounce
    if nextIndex < 1 or nextIndex > poolSize then
      edgeDirection = -edgeDirection
      nextIndex = currentIndex - delta
      nextIndex = math.max(1, math.min(poolSize, nextIndex))
    end
  else -- Clamp
    nextIndex = math.max(1, math.min(poolSize, nextIndex))
  end
  currentIndex = nextIndex
end

local function flashLastMove(moveIndex)
  for i = 1, #moveDeltas do
    lastMoveTable:setValue(i, i == moveIndex and 1 or 0)
  end
end

local function getNote()
  local pool = noteSelector.getSelectedNotes(true)
  if #pool == 0 then return nil end
  if currentIndex > #pool then currentIndex = math.ceil(#pool / 2) end
  local moveIndex = pickMoveIndex()
  applyMove(moveIndex, #pool)
  flashLastMove(moveIndex)
  if positionLabel then
    positionLabel.text = "Step " .. currentIndex .. " / " .. #pool
  end
  return pool[currentIndex]
end

local function resetPosition()
  local pool = noteSelector.getSelectedNotes(true)
  if #pool == 0 then
    currentIndex = 1
  else
    currentIndex = math.ceil(#pool / 2)
  end
  edgeDirection = 1
  if positionLabel then
    positionLabel.text = "Step " .. currentIndex .. " / " .. #pool
  end
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

widgets.setColours({
  labelBackgroundColour = "F5E9CF",
  backgroundColour = "4D455D",
})

local sequencerPanel = widgets.panel({
  width = 720,
  height = 30,
})

widgets.label("Markov Chain Input", {
  tooltip = "Listens to pulses (note 0) and walks through the selected note pool using weighted scale-step moves",
  width = sequencerPanel.width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 90,
  xOffset = 433,
  yOffset = 5,
  xSpacing = 5,
  ySpacing = 5,
})

local inputButton = widgets.button(" ", false, {
  tooltip = "Shows when notes are triggered",
  persistent = false,
  enabled = false,
  backgroundColourOff = "202020"
})

modular.getForwardWidget()
modular.getChannelWidget()

--------------------------------------------------------------------------------
-- Weights Panel
--------------------------------------------------------------------------------

widgets.setSection({
  xOffset = 0, yOffset = 0, xSpacing = 0, ySpacing = 0,
})

local weightsPanel = widgets.panel({
  x = sequencerPanel.x,
  y = widgets.posUnder(sequencerPanel),
  width = sequencerPanel.width,
  height = 110,
})

widgets.label("Move Weights", {
  tooltip = "Relative weight of each scale-step move from the current note. Move 0 means repeat.",
  alpha = 0.75,
  width = sequencerPanel.width,
  height = 22,
})

-- Interval labels above the weights table
widgets.setSection({
  width = 96,
  height = 16,
  xOffset = 5,
  yOffset = 26,
  xSpacing = 5,
  ySpacing = 0,
  cols = 7,
  labelBackgroundColour = "transparent",
})

for i = 1, #moveLabels do
  widgets.label(moveLabels[i], {
    tooltip = "Weight for move " .. moveLabels[i] .. " scale steps",
    alpha = 0.6,
    fontSize = 14,
  })
end

-- Last-move indicator (lights up the move that was just used)
widgets.setSection({
  width = 710,
  x = 5,
  y = 46,
  cols = 1,
})

lastMoveTable = widgets.table("LastMove", 0, #moveDeltas, {
  enabled = false,
  persistent = false,
  fillStyle = "solid",
  backgroundColour = "404040",
  sliderColour = "eeeeee",
  height = 4,
})

-- Editable weights as a slider table
widgets.setSection({
  width = 710,
  x = 5,
  y = widgets.posUnder(lastMoveTable) + 2,
  cols = 1,
})

weightsTable = widgets.table("Weights", 50, #moveDeltas, {
  tooltip = "Drag each bar to set the relative weight for that move",
  showPopupDisplay = true,
  backgroundColour = "191E25",
  sliderColour = "66FF99",
  min = 0, max = 100,
  integer = true,
  height = 32,
})

for i = 1, #defaultWeights do
  weightsTable:setValue(i, defaultWeights[i])
end

--------------------------------------------------------------------------------
-- Controls Panel
--------------------------------------------------------------------------------

local controlsPanel = widgets.panel({
  x = sequencerPanel.x,
  y = widgets.posUnder(weightsPanel),
  width = sequencerPanel.width,
  height = 34,
})

widgets.setSection({
  width = 100,
  height = 22,
  xOffset = 5,
  yOffset = 6,
  xSpacing = 5,
  ySpacing = 0,
})

widgets.menu("Edge Mode", edgeMode, {"Wrap", "Bounce", "Clamp"}, {
  tooltip = "How to behave at the edges of the note pool",
  showLabel = false,
  changed = function(self)
    edgeMode = self.value
    edgeDirection = 1
  end
})

widgets.button("Reset", false, {
  tooltip = "Reset the walker to the middle of the note pool",
  persistent = false,
  changed = function(self) if self.value then resetPosition() end end
})

positionLabel = widgets.label("Step 1 / 0", {
  tooltip = "Current position in the note pool",
  alpha = 0.5,
  width = 200,
})

--------------------------------------------------------------------------------
-- Notes Panel
--------------------------------------------------------------------------------

widgets.setSection({
  xOffset = 0, yOffset = 0, xSpacing = 0, ySpacing = 0,
})

local notePanel = widgets.panel({
  x = sequencerPanel.x,
  y = widgets.posUnder(controlsPanel),
  width = sequencerPanel.width,
  height = 160,
})

local noteLabel = widgets.label("Notes", {
  tooltip = "Select notes manually, or by selecting a scale",
  alpha = 0.75,
  width = sequencerPanel.width,
  height = 22,
})

noteSelector.createNoteAndOctaveSelector(notePanel, widgets.getColours(), noteLabel, 18, 12, {x = 500, y = noteLabel.y + 2.5, height = 18})

--------------------------------------------------------------------------------
-- Handle Events
--------------------------------------------------------------------------------

local function flashInput()
  inputButton.backgroundColourOff = "606060"
  waitBeat(.125)
  inputButton.backgroundColourOff = "202020"
end

function onNote(e)
  if modular.isTrigger(e) then
    local note = getNote()
    if modular.handleTrigger(e, note) then
      spawn(flashInput)
    end
  else
    postEvent(e)
  end
end

function onRelease(e)
  if modular.isTrigger(e) then
    modular.handleReleaseTrigger(e)
  else
    postEvent(e)
  end
end

function onTransport(start)
  if start == false then
    modular.releaseVoices()
  end
end
