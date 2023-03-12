--------------------------------------------------------------------------------
-- Life Trigger - Sends note events using note 0 as trigger
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

local isPlaying = false
local seqIndex = 0 -- Holds the unique id for the sequencer
local channel = 1
local gate = 90 -- TODO Param?
local ruleWidgets = {}
local ruleResolutions = resolutions.getResolutionNames({"Faster", "Dot/Tri", "Slower", "Base Resolution"})
local resolutionNames = resolutions.getResolutionNames()
local resolution = 20 -- The default resolution
local minResolution = 9 -- Slowest
local maxResolution = 26 -- Fastest
local maxDotResolution = 18 -- Fastest dotted resolution
local maxTriResolution = 25 -- Fastest triplet resolution
local velocity = 64
local rows = 6 -- Number of rows in the board
local cols = 6 -- Number of columns in the board
local cells = {} -- Holds the cell widgets
local evolve = false -- Every generation changes the base resolution to the resolution that was selected by chance
local dead = false -- Dead cells are played as pause - add an option for min live cells before accepting dead?
local locked = true -- Board is locked to move through all live cells before next gen - it starts locked to not kill the initial state
local currentRowIndex = 1
local currentColIndex = 1
local liveCells = 0 -- Holds the current live cells until next iteration
local resolutionMenu
local fillProbability = 50
local shapeMenu
local shapeNames = shapes.getShapeNames()
local shapeMenuItems = {"Empty Board"}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

local rules = {
  "Dead cells become alive when they have three alive neighbors",
  "Cells stay alive when they have two live neighbors",
  "Cells stay alive when they have three live neighbors",
  "Cells dies",
}

local ruleNames = {
  "Rebirth (Three Neighbors)",
  "Stay Alive (Two Neighbors)",
  "Stay Alive (Three Neighbors)",
  "Die",
}

--------------------------------------------------------------------------------
-- Sequencer Functions
--------------------------------------------------------------------------------

local function clearCells()
  --print("Clear cells")
  currentRowIndex = 1
  currentColIndex = 1 -- Reset
  liveCells = 0 -- Reset
  for i = 1, rows do
    for j = 1, cols do
      cells[i][j].value = false
      cells[i][j].backgroundColourOn = widgets.getColours().backgroundColourOn
      cells[i][j].backgroundColourOff = widgets.getColours().backgroundColourOff
      -- If evolve is active, and the sequencer is playing, cells preserve their resolution
      local preserve = isPlaying and evolve
      if preserve == false then
        cells[i][j].displayName = resolutionNames[resolution]
        cells[i][j].tooltip = resolutions.getResolution(resolution) .. ""
      end
    end
  end
end

local function applyRuleOnCell(cell, rule)
  local resIndex = nil
  local beatValue = nil
  local options = nil
  local baseResolutionIndex = resolution

  -- When evolve is active, we get the base resolution from the cell
  if evolve then
    baseResolutionIndex = gem.getIndexFromValue(tonumber(cell.tooltip), resolutions.getResolutions())
  end

  if type(ruleWidgets[rule]) ~= "nil" then
    if ruleWidgets[rule].selectedText == "Faster" then
      options = {adjustBias=100, doubleOrHalfProbaility=100, dotOrTriProbaility=0}
    elseif ruleWidgets[rule].selectedText == "Dot/Tri" then
      options = {adjustBias=50, doubleOrHalfProbaility=50, dotOrTriProbaility=100}
    elseif ruleWidgets[rule].selectedText == "Slower" then
      options = {adjustBias=0, doubleOrHalfProbaility=100, dotOrTriProbaility=0}
    elseif ruleWidgets[rule].selectedText == "Base Resolution" then
      resIndex = baseResolutionIndex
    elseif ruleWidgets[rule].value <= #resolutionNames then
      -- Fixed resolution
      resIndex = ruleWidgets[rule].value
    end
  end

  if type(resIndex) == "number" then
    beatValue = resolutions.getResolution(resIndex)
  elseif type(options) == "table" then
    options.minResolutionIndex = minResolution -- Slowest
    options.maxResolutionIndex = maxResolution -- Fastest
    options.maxDotResolutionIndex = maxDotResolution -- Fastest dotted
    options.maxTriResolutionIndex = maxTriResolution -- Fastest triplet
    beatValue = resolutions.getResolutionVariation(resolutions.getResolution(baseResolutionIndex), options)
    resIndex = gem.getIndexFromValue(beatValue, resolutions.getResolutions())
  else
    beatValue = tonumber(cell.tooltip)
    resIndex = gem.getIndexFromValue(beatValue, resolutions.getResolutions())
  end

  -- Update the cells
  cell.backgroundColourOn = widgets.getColours().backgroundColourOn
  cell.backgroundColourOff = widgets.getColours().backgroundColourOff
  cell.displayName = resolutionNames[resIndex]
  cell.tooltip = beatValue .. ""
end

local function isFilled(row, value)
  return row == value or (row < value and gem.getRandomBoolean(fillProbability))
end

local function loadShape(shapeIndex)
  if type(shapeIndex) == "nil" then
    shapeIndex = gem.getRandom(#shapeNames)
    shapeMenu:setValue(shapeIndex + 1, false) 
  end
  print("--- NEW SHAPE ---", shapeIndex)
  clearCells() -- Deactivate all cells
  local values = shapes.get(shapeIndex, {min=1,max=rows,length=cols})
  for col = 1, cols do
    local value = math.ceil(values[col])
    for row = 1, rows do
      cells[row][col].value = isFilled(row, value)
      --[[ if cells[row][col].value and gem.getRandomBoolean() then
        -- Apply rule 1 (rebirth)
        applyRuleOnCell(cells[row][col], 1)
      elseif cells[row][col].value == false then
        -- Apply rule 4 (cell dies)
        applyRuleOnCell(cells[row][col], 4)
      end ]]
    end
  end
  locked = true -- Lock to preserve the shape
end

local changeCount = 0
local previousChangeCount = 0
local equalCount = 0
local function updateBoard()
  -- Create a new board to hold the next generation
  local newGeneration = {}
  liveCells = 0 -- Clear live cells

  print("--- NEXT GENERATION! ---")

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
      local alive = rule < #rules

      if cells[i][j].value ~= alive then
        changeCount = gem.inc(changeCount)
      end

      cells[i][j].value = alive
      applyRuleOnCell(cells[i][j], rule)
    end
  end

  if changeCount == previousChangeCount then
    equalCount = gem.inc(equalCount)
  end
  previousChangeCount = changeCount

  -- Reset if stale board
  if changeCount == 0 or equalCount > rows then
    equalCount = 0 -- Reset
    --print("Stale board...")
    loadShape()
  end
end

-- Returns the next resolution from the live cells
local function getCell()
  local cell = cells[currentRowIndex][currentColIndex]

  if type(cell) == "nil" then
    locked = false
    print("No cell")
    return
  end

  print("Found cell.value @ currentRowIndex, currentColIndex", cell.value, currentRowIndex, currentColIndex)

  currentColIndex = gem.inc(currentColIndex)

  if currentColIndex > cols then
    currentColIndex = 1 -- Reset
    currentRowIndex = gem.inc(currentRowIndex)
    if currentRowIndex > rows then
      -- Round complete - unlock board!
      currentRowIndex = 1 -- Reset
      locked = false
    end
  end

  if cell.value then
    cell.backgroundColourOn = "orange" -- TODO Other colour for "dead" cells?
  elseif dead then
    cell.backgroundColourOff = "505050"
  end
  return cell--tonumber(cell.tooltip), cell.value
end

local function countLiveCells()
  for i = 1, rows do
    for j = 1, cols do
      if cells[i][j].value then
        --table.insert(liveCells, cells[i][j])
        liveCells = gem.inc(liveCells)
      end
    end
  end
  --print("Found liveCells", liveCells)
  currentRowIndex = 1 -- Reset row position
  currentColIndex = 1 -- Reset col position
  locked = liveCells > 0
end

local function seq(uniqueId)
  local note = 0
  locked = true -- Ensure the board is locked when starting to preserve the current state
  while isPlaying and seqIndex == uniqueId do
    -- When board has been unlocked, we can move one generation ahead
    if liveCells == 0 then
      countLiveCells()
    end
    if locked == false then
      updateBoard()
    end
    local cell = getCell() -- Get cell at current pos
    if type(cell) ~= "nil" then
      local duration = tonumber(cell.tooltip)
      if cell.value then
        playNote(note, velocity, beat2ms(resolutions.getPlayDuration(duration, gate)), nil, channel)
        print("playNote", duration)
      end
      if cell.value or (cell.value == false and dead) then
        print("waitBeat", duration)
        waitBeat(duration)
      end
    end
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

widgets.label("Life Trigger", {
  tooltip = "A sequencer that use the rules from game of life to evolve resolutions",
  width = widgets.getPanel().width,
  height = 30,
  alpha = 0.5,
  fontSize = 22,
})

widgets.setSection({
  width = 104,
  height = 22,
  x = 153,
  y = 5,
  cols = 10
})

shapeMenu = widgets.menu("Shape", shapeMenuItems, {
  tooltip = "If the board is empty or stale, a random shape will be selected",
  showLabel = false,
  width = 126,
  changed = function(self)
    clearCells()
    local shapeIndex = self.value - 1
    if shapeIndex > 0 then
      loadShape(shapeIndex)
    end
  end
})

widgets.numBox('Fill', fillProbability, {
  tooltip = "Set a fill probability for the selected shape. If fill is 0, the shape is drawn as a line, if fill is 100 it will be drawn solid.",
  unit = Unit.Percent,
  changed = function(self)
    fillProbability = self.value
    shapeMenu:changed()
  end
})

widgets.numBox('Ch', channel, {
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
  width = widgets.getPanel().width / 2,
  height = 219,
})

widgets.setSection({
  width = (widgets.getPanel().width - ((cols+1) * 5)) / cols,
  height = (widgets.getPanel().height - ((rows+1) * 5)) / rows,
  x = 5,
  y = 5,
  xSpacing = 5,
  ySpacing = 5,
  rowDirection = -1,
  row = rows - 1,
  cols = cols,
})

-- Create the cells
for i = 1, rows do
  cells[i] = {}
  for j = 1, cols do
    cells[i][j] = widgets.button(resolutionNames[resolution])
  end
end

--------------------------------------------------------------------------------
-- Rule Settings
--------------------------------------------------------------------------------

widgets.panel({
  backgroundColour = backgroundColour,
  x = widgets.getPanel().x + widgets.getPanel().width,
  y = widgets.getPanel().y + 5,
  width = 204,
  height = widgets.getPanel().height - 10,
})

widgets.setSection({
  width = 190,
  height = 20,
  xSpacing = 5,
  ySpacing = 5,
  x = 5,
  y = 5,
  cols = 1,
})

for i,rule in ipairs(rules) do
  table.insert(ruleWidgets, widgets.menu(ruleNames[i], #resolutionNames + i, ruleResolutions, {
    name = "AliveRule" .. i,
    tooltip = rule,
  }))
end

widgets.panel({
  backgroundColour = "505050",
  x = widgets.getPanel().x + widgets.getPanel().width + 5,
  y = widgets.getPanel().y,
  width = 147,
  height = widgets.getPanel().height,
})

widgets.setSection({
  x = 10,
  width = 130,
  cols = 1,
})

resolutionMenu = widgets.menu("Base Resolution", resolution, resolutionNames, {
  tooltip = "Set the base resolution",
  width = 130,
  changed = function(self)
    resolution = self.value
    clearCells()
    loadShape()
  end
})

widgets.setSection({
  y = widgets.posUnder(resolutionMenu),
  width = 63,
  cols = 2,
})

widgets.menu("Slowest", minResolution, resolutionNames, {
  tooltip = "Set the slowest allowed resolution for new generations",
  changed = function(self)
    minResolution = self.value
  end
})

widgets.menu("Fastest", maxResolution, resolutionNames, {
  tooltip = "Set the fastest allowed resolution for new generations",
  changed = function(self)
    maxResolution = self.value
  end
})

widgets.menu("Fastest Dot", maxDotResolution, resolutionNames, {
  tooltip = "Set the slowest allowed dotted resolution for new generations",
  changed = function(self)
    maxDotResolution = self.value
  end
})

widgets.menu("Fastest Tri", maxTriResolution, resolutionNames, {
  tooltip = "Set the fastest allowed triplet resolution for new generations",
  changed = function(self)
    maxTriResolution = self.value
  end
})

widgets.button('Evolve', evolve, {
  tooltip = "When evolve is active, the resolution for the next generation is taken from the cell, instead of from the base resolution",
  width = 130,
  changed = function(self)
    evolve = self.value
    resolution = resolutionMenu.value
  end
})

widgets.row()

widgets.button('Rest Dead', dead, {
  tooltip = "When this is active, dead cells are used as rests. Otherwise dead cells are skipped.",
  width = 130,
  changed = function(self)
    dead = self.value
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
