--------------------------------------------------------------------------------
-- Game of Life Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local shapes = require "includes.shapes"
local resolutions = require "includes.resolutions"

local backgroundColour = "404040"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local title = "Game of Life Trigger"
local description = "A sequencer that use the rules from game of life to trigger events"
local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local legato = false
local voiceId
local eventTrigger = 0 -- Holds the event trigger, if any
local resolutionNames = resolutions.getResolutionNames()
local resolution = 20 -- The default resolution
local velocity = 64
local evolutionSpeed = 500 -- Milliseconds
local rows = 12 -- Number of rows in the board
local cols = rows -- Number of columns in the board
local minTriggers = math.ceil((rows + cols) / 2) -- Number of required triggers before sending event
local equalRounds = math.ceil(minTriggers / 2) -- Number of stale rounds before shape is regenerated
local cells = {} -- Holds the cell widgets
local generationCounter = 0
local maxGenerations = 1000 -- Max generations before reset is forced
local shapeIndex
local fillProbability = 50
local generationLabel
local triggerLabel
local shapeMenu
local speedInput
local speedRandomization = 0
local triggerInput
local triggerRandomization = 0
local shapeNames = shapes.getShapeNames()
local shapeMenuItems = {"Random Shape"}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

local shapeWidgets = {}
local shapeOptions = shapes.getShapeOptions()

local triggerMode = 1 -- Holds the strategy for when events are triggered
local triggerModes = {
  "Rebirth (Three Neighbors)",
  "Stay Alive (Two Neighbors)",
  "Stay Alive (Three Neighbors)",
  "Die",
}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function clearCells()
  for i = 1, rows do
    for j = 1, cols do
      cells[i][j].value = false
    end
  end
end

local function isFilled(row, value)
  return row == value or (row < value and gem.getRandomBoolean(fillProbability))
end

local function loadShape(options)
  local shape = shapeIndex
  local values
  if type(shape) == "nil" then
    shape = gem.getRandom(#shapeNames)
  end
  clearCells() -- Deactivate all cells
  print("--- NEW SHAPE ---", shape)
  local bounds = {
    min = 1,
    max = rows,
    length = cols,
  }
  values, shapeOptions = shapes.get(shape, bounds, options)
  for col = 1, cols do
    local value = math.ceil(values[col])
    for row = 1, rows do
      cells[row][col].value = isFilled(row, value)
    end
  end
end

local changeCount = 0
local previousChangeCount = 0
local equalCount = 0
local function updateBoard()
  -- Create a new board to hold the next generation
  local newGeneration = {}

  generationCounter = gem.inc(generationCounter)
  generationLabel.text = "Gen " .. generationCounter
  --triggerMode = gem.getRandom(#triggerModes) -- Use a random triggermode
  print("--- NEXT GENERATION! ---", generationCounter)

  -- Iterate through each cell on the board
  for i = 1, rows do
    newGeneration[i] = {}
    for j = 1, cols do
      local count = 0

      -- Count the number of live neighbors
      for x = -1, 1 do
        for y = -1, 1 do
          if x ~= 0 or y ~= 0 then
            local row = i + x
            local col = j + y

            -- Check if the cell is on the board
            if row >= 1 and row <= rows and col >= 1 and col <= cols then
              local val = 0
              if cells[row][col].value == true then
                val = 1
              end
              count = count + val
            end
          end
        end
      end

      -- Alive rules:
      ---- Cell stays alive (count == 2)
      ---- Cell stays alive (count == 3)
      ---- Cell becomes alive (count == 3)

      -- Dead cells go back to the base resolution
      -- Live cells are evolving according to the setting for the given rule

      -- The rules are very simple. In the next generation, the next click of the clock, the squares are going to change statuses in some way or another:
      ---- Any live cell with fewer than two live neighbours dies, as if by underpopulation.
      ---- Any live cell with two or three live neighbours lives on to the next generation.
      ---- Any live cell with more than three live neighbours dies, as if by overpopulation.
      ---- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
      
      -- These rules, which compare the behaviour of the automaton to real life, can be condensed into the following:
      ---- Any live cell with two or three live neighbours survives.
      ---- Any dead cell with three live neighbours becomes a live cell.
      ---- All other live cells die in the next generation. Similarly, all other dead cells stay dead.

      -- Apply the rules of the game
      if cells[i][j].value == false and count == 3 then
        -- Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
        newGeneration[i][j] = 1
      elseif cells[i][j].value == true and count == 2 then
        -- Any live cell with two live neighbours lives on to the next generation.
        newGeneration[i][j] = 2
      elseif cells[i][j].value == true and count == 3 then
        -- Any live cell with three live neighbours lives on to the next generation.
        newGeneration[i][j] = 3
      elseif cells[i][j].value == true then
        -- All other live cells die in the next generation.
        newGeneration[i][j] = 4
      else
        -- All other dead cells stay dead.
        newGeneration[i][j] = 5
      end
    end
  end

  -- Update the cells for the next generation
  changeCount = 0
  for i,v in ipairs(newGeneration) do
    for j,rule in ipairs(v) do
      local alive = rule < #triggerModes

      if cells[i][j].value ~= alive then
        changeCount = gem.inc(changeCount)
      end

      cells[i][j].value = alive
      -- Add trigger if selected rule is found
      if triggerMode == rule then
        --print("Found trigger: rule, i, j", rule, i, j)
        eventTrigger = gem.inc(eventTrigger)
        triggerLabel.text = "Trig " .. eventTrigger
        if alive then
          cells[i][j].backgroundColourOn = "orange"
        else
          cells[i][j].backgroundColourOff = "gray"
        end
      else
        cells[i][j].backgroundColourOn = widgets.getColours().backgroundColourOn
        cells[i][j].backgroundColourOff = widgets.getColours().backgroundColourOff
        end
    end
  end

  if changeCount == previousChangeCount then
    equalCount = gem.inc(equalCount)
  end
  previousChangeCount = changeCount

  -- Reset if stale board
  if changeCount == 0 or equalCount > equalRounds or generationCounter > maxGenerations then
    print("Stale board...")
     -- Reset counters
    equalCount = 0
    generationCounter = 0
    -- Set speed for the next round
    evolutionSpeed = gem.randomizeValue(speedInput.value, speedInput.min, speedInput.max, speedRandomization)
    -- Set min triggers for the next round
    minTriggers = gem.randomizeValue(triggerInput.value, triggerInput.min, triggerInput.max, triggerRandomization)
    loadShape()
  end
end

local function release()
  -- Release voice if still active
  if type(voiceId) == "userdata" then
    releaseVoice(voiceId)
    voiceId = nil
  end
end

local function evolution(uniqueId)
  while isPlaying and seqIndex == uniqueId do
    updateBoard()
    wait(evolutionSpeed)
  end
end

local function seq(uniqueId)
  while isPlaying and seqIndex == uniqueId do
    local duration = resolutions.getResolution(resolution)
    print("eventTrigger", eventTrigger)
    if eventTrigger >= minTriggers then
      print("Play trigger!")
      release() -- Release voice if still active
      voiceId = playNote(0, velocity, -1, nil, channel)
      eventTrigger = 0
    end
    waitBeat(duration)
    if legato == false then
      -- Release if legato is off
      release()
    end
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(evolution, seqIndex)
  run(seq, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  release()
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

widgets.panel({
  width = 720,
  height = 30,
})

widgets.setSection({
  xSpacing = 5,
  ySpacing = 5,
})

widgets.label(title, {
  tooltip = description,
  width = widgets.getPanel().width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 120,
  height = 22,
  x = 186,
  y = 5,
  cols = 10
})

generationLabel = widgets.label("Gen " .. generationCounter, {
  tooltip = "Shows the current generation",
  backgroundColour = "transparent",
  textColour = "606060",
  width = 75,
})

triggerLabel = widgets.label("Trig " .. eventTrigger, {
  tooltip = "Shows the current trigger count",
  backgroundColour = "transparent",
  textColour = "606060",
  width = 75,
})

widgets.numBox('Channel', channel, {
  tooltip = "Send note events starting on this channel",
  min = 1,
  max = 16,
  integer = true,
  changed = function(self) channel = self.value end
})

local autoplayButton = widgets.button('Auto Play', true, {
  tooltip = "Play automatically on transport",
})

local playButton = widgets.button('Play', false, {
  changed = function(self)
    if self.value then
      startPlaying()
    else
      stopPlaying()
    end
  end
})

--------------------------------------------------------------------------------
-- Board
--------------------------------------------------------------------------------

widgets.setSection({
  xSpacing = 0,
  ySpacing = 0,
})

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x + 5,
  y = widgets.posUnder(widgets.getPanel()) + 5,
  width = 240,
  height = 192,
})

local spacing = 2
widgets.setSection({
  width = (widgets.getPanel().width - ((cols+1) * spacing)) / cols,
  height = (widgets.getPanel().height - ((rows+1) * spacing)) / rows,
  x = 2,
  y = 0,
  xSpacing = spacing,
  ySpacing = spacing,
  rowDirection = -1,
  row = rows - 1,
  cols = cols,
})

-- Create the cells
for i = 1, rows do
  cells[i] = {}
  for j = 1, cols do
    cells[i][j] = widgets.button(" ")
  end
end

--------------------------------------------------------------------------------
-- Shape Panel
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = "303030",
  x = widgets.posSide(widgets.getPanel()) + 5,
  y = widgets.getPanel().y + 3,
  width = 220,
  height = widgets.getPanel().height - 5,
})

widgets.setSection({
  x = 10,
  y = 6,
  width = 192,
  height = 20,
  xSpacing = 5,
  ySpacing = 5,
  cols = 1,
})

shapeMenu = widgets.menu("Start Shape", shapeMenuItems, {
  tooltip = "If the board is empty or stale, the selected shape will be used for starting a new board",
  changed = function(self)
    clearCells()
    shapeIndex = self.value - 1
    if shapeIndex == 0 then
      shapeIndex = nil
    else
      loadShape()
    end
  end
})

widgets.numBox('Fill', fillProbability, {
  tooltip = "Set a fill probability for the selected shape. If fill is 0, the shape is drawn as a line, if fill is 100 it will be drawn solid.",
  unit = Unit.Percent,
  width = function(w, o) return w * 0.55 end,
  increment = false,
  changed = function(self)
    fillProbability = self.value
    shapeMenu:changed()
  end
})

widgets.button("Reset Shape", {
  tooltip = "Reset board with the selected shape. If 'Random Shape' is selected, a different shape will be loaded every time.",
  width = function(w, o) return (w * 0.45) - o.xSpacing end,
  changed = function()
    if shapeIndex == 0 then
      loadShape()
    else
      loadShape(shapeOptions)
    end
  end
})

shapeWidgets = shapes.getWidgets()
shapeWidgets.amount = shapes.getAmountWidget()

for k,v in pairs(shapeWidgets) do
  v.changed = function(self)
    shapeOptions[k] = self.value
    if type(shapeIndex) == "number" then
      loadShape(shapeOptions)
    end
  end
end

--------------------------------------------------------------------------------
-- Quantize Panel
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = "505050",
  x = widgets.posSide(widgets.getPanel()) + 5,
  y = widgets.getPanel().y,
  width = 230,
  height = widgets.getPanel().height,
})

widgets.setSection({
  x = 10,
  y = 6,
  width = 210,
  height = 20,
  xSpacing = 5,
  ySpacing = 5,
  cols = 2,
})

local quantizeMenu = widgets.menu("Quantize", resolution, resolutionNames, {
  tooltip = "Quantize the outputted triggers to the selected resolution",
  width = function(w, o) return (w * 0.5) end,
  changed = function(self)
    resolution = self.value
    clearCells()
    loadShape()
  end
})

widgets.row()
widgets.col()

widgets.button("Legato", legato, {
  tooltip = "In legato mode notes are held until the next note is played",
  width = function(w, o) return (w * 0.5) - o.xSpacing end,
  x = widgets.posSide(quantizeMenu),
  changed = function(self) legato = self.value end
})

widgets.menu("Trigger On", triggerMode, triggerModes, {
  tooltip = "Select the rule that triggers events - marked with orange (or gray for dead cells) colour on the board",
  changed = function(self) triggerMode = self.value end
})

widgets.row(2)

triggerInput = widgets.numBox('Min Triggers', minTriggers, {
  tooltip = "Set the required number of rule occurences before an event is sent. Low numbers means more events, high number means fewer.",
  min = 1,
  max = rows * cols,
  integer = true,
  width = function(w, o) return w * 0.75 end,
  changed = function(self)
    minTriggers = self.value
  end
})

widgets.numBox('MinTrigRand', triggerRandomization, {
  tooltip = "Set the randomization amount for this parameter",
  showLabel = false,
  unit = Unit.Percent,
  width = function(w, o) return (w * 0.25) - o.xSpacing end,
  changed = function(self)
    triggerRandomization = self.value
  end
})

speedInput = widgets.numBox('Speed', evolutionSpeed, {
  tooltip = "Set the speed between generations",
  unit = Unit.MilliSeconds,
  mapper = Mapper.Quartic,
  min = evolutionSpeed / 10,
  max = evolutionSpeed * 10,
  integer = true,
  width = function(w, o) return w * 0.75 end,
  changed = function(self)
    evolutionSpeed = self.value
  end
})

widgets.numBox('SpeedRand', speedRandomization, {
  tooltip = "Set the randomization amount for this parameter",
  showLabel = false,
  unit = Unit.Percent,
  width = function(w, o) return (w * 0.25) - o.xSpacing end,
  changed = function(self)
    speedRandomization = self.value
  end
})

widgets.numBox('Max Stale', equalRounds, {
  tooltip = "Set the number of stale rounds that are allowed before regenerating the shape",
  min = 1,
  max = (rows * cols) / 2,
  integer = true,
  width = function(w, o) return w * 0.4 - o.xSpacing end,
  changed = function(self)
    equalRounds = self.value
  end
})

widgets.numBox('Max Gen', maxGenerations, {
  tooltip = "Set the maximum number of generations before regenerating the shape is forced",
  min = 500,
  max = 5000,
  integer = true,
  width = function(w, o) return (w * 0.6) end,
  changed = function(self)
    maxGenerations = self.value
  end
})

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
  clearCells()
end

function onNote(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    velocity = e.velocity
    playButton:setValue(true)
  end
end

function onRelease(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
    playButton:setValue(false)
  end
end

function onTransport(start)
  if autoplayButton.value == true then
    playButton:setValue(start)
  end
end
