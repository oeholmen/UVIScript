--------------------------------------------------------------------------------
-- Life Trigger - Sends note events using note 0 as trigger
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"

local backgroundColour = "404040"
setBackgroundColour(backgroundColour)

--------------------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------------------

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local gate = 90
local resolutionNames = resolutions.getResolutionNames()
local resolution = 17 -- Time between generations
local velocity = 64
local rows = 10 -- Number of rows in the board
local cols = 15 -- Number of columns in the board
local cells = {}
local startProbability = 30 -- TODO Param? -- Probablity that a cell will be active at the start
local evolve = false -- TODO Param? Every generation changes the base resolution to the resolution that was selected by chance
local locked = false -- Board is locked to move through all live cells before next gen
local currentCellIndex = 1
local liveCells = {} -- Holds the current live cells until next iteration

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

-- Update the board for the next generation
local function updateBoard()
  print("updateBoard")
  -- Create a new board to hold the next generation
  local newGeneration = {}

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

      -- Apply the rules of the game
      if cells[i][j].value == true and count < 2 then
        --newGeneration[i][j] = false
        newGeneration[i][j] = -1
      elseif cells[i][j].value == true and (count == 2 or count == 3) then
        --newGeneration[i][j] = true
        newGeneration[i][j] = 60
      elseif cells[i][j].value == true and count > 3 then
        --newGeneration[i][j] = false
        newGeneration[i][j] = -1
      elseif cells[i][j].value == false and count == 3 then
        --newGeneration[i][j] = true
        newGeneration[i][j] = 40
      else
        if cells[i][j].value then
          newGeneration[i][j] = 50
        else
          newGeneration[i][j] = -1
        end
      end
    end
  end

  locked = false
  currentCellIndex = 1
  liveCells = {} -- Reset

  -- Update the cells for the next generation
  --local liveCount = 0
  local changeCount = 0
  for i,v in ipairs(newGeneration) do
    for j,adjustBias in ipairs(v) do
      local isAlive = adjustBias >= 0
      --if cells[i][j].value ~= w then
      if cells[i][j].value ~= isAlive then
        changeCount = gem.inc(changeCount)
      end
      cells[i][j].value = isAlive
      cells[i][j].backgroundColourOn = widgets.getColours().backgroundColourOn
      if isAlive then
        --print("updateBoard resolution", resolution)
        local beatValue = resolutions.getResolutionVariation(resolutions.getResolution(resolution), adjustBias, 75)
        --print("updateBoard beatValue", beatValue)
        local resIndex = gem.getIndexFromValue(beatValue, resolutions.getResolutions()) -- Static resolution
        --resolution = gem.getIndexFromValue(beatValue, resolutions.getResolutions()) -- Evolves the resolution
        --print("updateBoard, beatValue, resIndex, resName", beatValue, resolution, resolutionNames[resIndex])
        cells[i][j].displayName = resolutionNames[resIndex]
        cells[i][j].tooltip = beatValue .. ""
        --liveCount = gem.inc(liveCount)
        table.insert(liveCells, cells[i][j])
        if evolve then
          resolution = resIndex
        end
        --print("updateBoard liveCount", liveCount)
      else
        cells[i][j].displayName = resolutionNames[resolution]
        cells[i][j].tooltip = resolutions.getResolution(resolution) .. ""
      end
    end
  end

  -- Reset if stale
  print("#liveCells", #liveCells)
  if #liveCells > 0 and changeCount == 0 then
    resetCells()
  else
    locked = #liveCells > 0 -- Set locked
  end
end

local function resetCells(allOff)
  print("resetCells")
  locked = false
  currentCellIndex = 1
  liveCells = {} -- Reset
  local alive = false
  local aliveChanged = false
  local aliveProbaility = startProbability
  local decay = 3 -- TODO Param?
  for i = 1, rows do
    for j = 1, cols do
      if alive then
        if aliveChanged then
          aliveProbaility = 100 -- Set to max
        end
        local reduceAmount = (aliveProbaility * (decay / 100))
        --print("Before decay aliveProbaility, reduceAmount", aliveProbaility, reduceAmount)
        aliveProbaility = aliveProbaility - reduceAmount
        --print("After decay aliveProbaility", aliveProbaility)
      elseif allOff ~= true then
        if aliveChanged then
          aliveProbaility = decay -- Set to min
        end
        --aliveProbaility = startProbability
        --print("Reset aliveProbaility", aliveProbaility)
        local increaseAmount = (aliveProbaility * (decay / 100))
        --print("Before decay aliveProbaility, increaseAmount", aliveProbaility, increaseAmount)
        aliveProbaility = aliveProbaility + increaseAmount
        --print("After decay aliveProbaility", aliveProbaility)
      end
      local newState = gem.getRandomBoolean(aliveProbaility)
      aliveChanged = newState ~= alive
      alive = newState and allOff ~= true
      if alive then
        table.insert(liveCells, cells[i][j])
      end
      cells[i][j].value = alive
      cells[i][j].displayName = resolutionNames[resolution]
      cells[i][j].tooltip = resolutions.getResolution(resolution) .. ""
      cells[i][j].backgroundColourOn = widgets.getColours().backgroundColourOn
    end
  end
  if allOff ~= true then
    updateBoard()
  end
end

-- Returns a random resolution from the live cells
local function getDuration()
  print("getDuration currentCellIndex", currentCellIndex)
  local cell = liveCells[currentCellIndex]
  if type(cell) == "nil" then
    return -- Nothing found!
  end

  currentCellIndex = gem.inc(currentCellIndex)

  if currentCellIndex > #liveCells then
    -- Round complete!
    print("getDuration Round complete!, #liveCells, currentCellIndex", #liveCells, currentCellIndex)
    locked = false
    currentCellIndex = 1
    liveCells = {} -- Reset
  end

  cell.backgroundColourOn = "orange"
  return tonumber(cell.tooltip)
end

local function seq(uniqueId)
  local note = 0
  local isFirstRound = true
  while isPlaying and seqIndex == uniqueId do
    if locked == false and isFirstRound == false then
      updateBoard()
    end
    local duration = getDuration()
    --print("Duration", duration)
    if type(duration) == "number" then
      playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, gate)), nil, channel)
    else
      duration = resolutions.getResolution(resolution)
      print("Fallback to using default duration", duration)
    end
    waitBeat(duration)
    isFirstRound = false
  end
end

local function startPlaying()
  if isPlaying then
    return
  end
  isPlaying = true
  seqIndex = gem.inc(seqIndex)
  run(seq, seqIndex)
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  isPlaying = false
  --resetCells()
end

--------------------------------------------------------------------------------
-- Header Panel
--------------------------------------------------------------------------------

local resolutionMenu

widgets.panel({
  width = 720,
  height = 30,
})

widgets.setSection({
  xSpacing = 5,
  ySpacing = 5,
  cols = cols,
})

widgets.label("Life Trigger", {
  tooltip = "A sequencer that triggers rythmic pulses (using note 0) that note inputs can listen to",
  width = widgets.getPanel().width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 100,
  height = 22,
  x = 150,
  y = 5,
})

widgets.button('Clear', {
  width = 45,
  tooltip = "Clear all cells",
  changed = function()
    resetCells(true)
  end
})

widgets.button('Reset', {
  width = 45,
  tooltip = "Reset cells to a random state",
  changed = function()
    resetCells()
  end
})

widgets.button('Evolve', evolve, {
  width = 45,
  tooltip = "Activate evolve",
  changed = function(self)
    evolve = self.value
    resolutionMenu:changed()
  end
})

resolutionMenu = widgets.menu("Duration", resolution, resolutionNames, {
  tooltip = "Set the base resolution",
  showLabel = false,
  changed = function(self)
    resolution = self.value
    resetCells()
  end
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
    if self.value == true then
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
  x = widgets.getPanel().x,
  y = widgets.posUnder(widgets.getPanel()),
  width = widgets.getPanel().width,
  height = 360,
})

widgets.setSection({
  width = 42,
  height = 30,
  x = 10,
  y = 10,
  xSpacing = 5,
  ySpacing = 5,
})

-- TODO Each cell holds a resolution?
-- Create the cells
for i = 1, rows do
  cells[i] = {}
  for j = 1, cols do
    cells[i][j] = widgets.button()
    --[[ cells[i][j].changed = function(self)
      if self.value then
        table.insert(liveCells, self)
      end
    end ]]
  end
end

--------------------------------------------------------------------------------
-- Handle events
--------------------------------------------------------------------------------

function onInit()
  seqIndex = 0
  resetCells()
end

function onNote(e)
  if autoplayButton.value == true then
    postEvent(e)
  else
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
