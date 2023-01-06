--------------------------------------------------------------------------------
-- Common functions and widgets that are shared for the modulation sequencers
--------------------------------------------------------------------------------

local gem = require "includes.common"
local r = require "includes.resolutions"

defaultActions = {"Actions...", "Randomize", "Ramp Up", "Ramp Down", "Triangle", "Even", "Odd", "Reduce 50%"}
numPages = 1
activePage = 1
nextUp = 1
pageButtons = {}
paramsPerPart = {}
paramsPerPage = {}
isPlaying = false

--------------------------------------------------------------------------------
-- Define widgets
--------------------------------------------------------------------------------

local headerPanel = Panel("Header")
local footerPanel = Panel("Footer")

local actionMenu = footerPanel:Menu("ActionMenu", defaultActions)
local cyclePagesButton = footerPanel:OnOffButton("CyclePagesButton")
local changePageProbability = footerPanel:NumBox("ChangePageProbability", 0, 0, 100, true)

--------------------------------------------------------------------------------
-- Common Functions
--------------------------------------------------------------------------------

-- Get the index for this part in paramsPerPart, given page and part number
local function getPartIndex(part, page)
  if type(page) == "nil" then
    page = activePage -- Default is the active page
  end
  --print("getPartIndex page/part/numParts", page, part, numParts)
  return (page * numParts) + (part - numParts)
end

-- Get page from part index
local function getPageFromPartIndex(partIndex)
  --print("getPageFromPartIndex partIndex", partIndex)
  return math.ceil(partIndex / maxPages)
end

local function advancePage()
  local next = activePage + 1
  if next > numPages then
    next = 1
  end
  pageButtons[next]:setValue(true)
end

local function gotoNextPage()
  -- Check that there is actually a a change
  if activePage == nextUp then
    return
  end
  activePage = nextUp
  for page,params in ipairs(paramsPerPage) do
    local isVisible = page == activePage
    params.sequencerPanel.visible = isVisible
    params.minRepeats.visible = isVisible
    pageButtons[page]:setValue(isVisible, false)
  end
end

local function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
  end
end

local function setPageDuration(page)
  print("setPageDuration for page", page)
  local pageResolutions = {}
  for part=1,numParts do
    local partIndex = getPartIndex(part, page)
    print("getResolution for partIndex", partIndex)
    local partResolution = r.getResolution(paramsPerPart[partIndex].stepResolution.value)
    if paramsPerPart[partIndex].stepButton.value then
      partResolution = partResolution * paramsPerPart[partIndex].numStepsBox.value
    end
    table.insert(pageResolutions, partResolution)
    print("Added resolution/part/page", partResolution, part, page)
  end
  table.sort(pageResolutions)
  paramsPerPage[page].pageDuration = pageResolutions[#pageResolutions]
end

local function setNumSteps(partIndex, numSteps)
  print("setNumSteps for partIndex/numSteps", partIndex, numSteps)
  paramsPerPart[partIndex].positionTable.length = numSteps
  paramsPerPart[partIndex].seqValueTable.length = numSteps
  if type(paramsPerPart[partIndex].smoothStepTable) ~= "nil" then
    paramsPerPart[partIndex].smoothStepTable.length = numSteps
  end
  local page = getPageFromPartIndex(partIndex)
  setPageDuration(page)
end

local function pageRunner()
  local repeatCounter = -1
  while isPlaying do
    repeatCounter = repeatCounter + 1
    local repeats = paramsPerPage[activePage].minRepeats.value
    print("New round on page/duration/repeats/repeatCounter", activePage, paramsPerPage[activePage].pageDuration, repeats, repeatCounter)
    if repeatCounter >= repeats and nextUp == activePage then
      if gem.getRandomBoolean(changePageProbability.value) then
        nextUp = gem.getRandom(numPages)
      elseif cyclePagesButton.value == true then
        nextUp = activePage + 1
        if nextUp > numPages then
          nextUp = 1
        end
      end
      repeatCounter = 0 -- Reset repeat counter
    end

    gotoNextPage()

    waitBeat(paramsPerPage[activePage].pageDuration)
  end
end

local function startPlaying()
  if isPlaying == true then
    return
  end
  spawn(pageRunner)
  for i=1,numParts do
    print("Start playing", i)
    spawn(arpeg, i)
  end
  isPlaying = true
end

local function stopPlaying()
  if isPlaying == false then
    return
  end
  print("Stop playing")
  isPlaying = false
  clearPosition()
  gotoNextPage()
end

--------------------------------------------------------------------------------
-- Common Widgets
--------------------------------------------------------------------------------

headerPanel.backgroundColour = menuOutlineColour
headerPanel.x = 10
headerPanel.y = 10
headerPanel.width = 700
headerPanel.height = 30

local label = headerPanel:Label("Label")
label.text = title
if type(tooltip) == "string" then
  label.tooltip = tooltip
end
label.backgroundColour = "808080"
label.textColour = pageBackgoundColour
label.fontSize = 22
label.position = {0,0}
label.size = {190,25}

local labelInput = headerPanel:Label("Label")
labelInput.text = ""
labelInput.editable = true
labelInput.backgroundColour = pageBackgoundColour
labelInput.textColour = "808080"
labelInput.backgroundColourWhenEditing = "white"
labelInput.textColourWhenEditing = "black"
labelInput.fontSize = 16
labelInput.width = 180
labelInput.x = label.x + label.width + 10
labelInput.y = 3

local playButton = headerPanel:OnOffButton("Play", false)
playButton.persistent = false
playButton.backgroundColourOff = "#ff084486"
playButton.backgroundColourOn = "#ff02ACFE"
playButton.textColourOff = "#ff22FFFF"
playButton.textColourOn = "#efFFFFFF"
playButton.displayName = "Play"
playButton.size = {102,22}
playButton.x = headerPanel.width - playButton.width
playButton.y = 2
playButton.changed = function(self)
  if self.value == true then
    startPlaying()
  else
    stopPlaying()
  end
end

local autoplayButton = headerPanel:OnOffButton("AutoPlay", true)
autoplayButton.backgroundColourOff = "#ff084486"
autoplayButton.backgroundColourOn = "#ff02ACFE"
autoplayButton.textColourOff = "#ff22FFFF"
autoplayButton.textColourOn = "#efFFFFFF"
autoplayButton.displayName = "Auto Play"
autoplayButton.tooltip = "Play automatically on transport"
autoplayButton.size = {102,22}
autoplayButton.x = playButton.x - playButton.width - 5
autoplayButton.y = playButton.y

footerPanel.backgroundColour = menuOutlineColour
footerPanel.x = 10
footerPanel.width = 700
if maxPages == 1 then
  footerPanel.enabled = false
  footerPanel.visible = false
  footerPanel.height = 10
else
  footerPanel.height = 30
end

changePageProbability.displayName = "Random"
changePageProbability.tooltip = "Probability of random page change"
changePageProbability.enabled = false
changePageProbability.unit = Unit.Percent
changePageProbability.size = {110,22}
changePageProbability.x = (33 * maxPages) + 102

local pageButtonSize = {25,22}

local nextPageButton = footerPanel:Button("NextPageButton")
nextPageButton.persistent = false
nextPageButton.enabled = numPages > 1
nextPageButton.displayName = ">"
nextPageButton.tooltip = "Go to next page in the cycle"
nextPageButton.size = pageButtonSize
nextPageButton.changed = function(self)
  advancePage()
end

cyclePagesButton.enabled = numPages > 1
cyclePagesButton.displayName = ">>"
cyclePagesButton.tooltip = "Play pages in cycle"
cyclePagesButton.backgroundColourOff = "#6600cc44"
cyclePagesButton.backgroundColourOn = "#aa00cc44"
cyclePagesButton.textColourOff = "#cc22FFFF"
cyclePagesButton.textColourOn = "#ccFFFFFF"
cyclePagesButton.size = pageButtonSize

local numPagesBox = footerPanel:NumBox("Pages", numPages, 1, maxPages, true)
numPagesBox.tooltip = "Number of active pages"
numPagesBox.backgroundColour = menuBackgroundColour
numPagesBox.textColour = menuTextColour
numPagesBox.size = {90,22}
numPagesBox.x = 0
numPagesBox.changed = function(self)
  numPages = self.value
  changePageProbability.enabled = self.value > 1
  nextPageButton.enabled = self.value > 1
  cyclePagesButton.enabled = self.value > 1
  for page=1,self.max do
    setPageDuration(page)
    pageButtons[page].enabled = page <= numPages
    paramsPerPage[page].minRepeats.enabled = numPages > 1
  end
  -- Update action menu
  local actionMenuItems = {}
  for i=1,#defaultActions do
    table.insert(actionMenuItems, defaultActions[i])
  end
  if numPages > 1 then
    for i=1,numPages do
      table.insert(actionMenuItems, "Copy settings from page " .. i)
    end
  end
  actionMenu.items = actionMenuItems
end

-- Add page buttons
local xPadding = 1
for page=1,maxPages do
  local pageButton = footerPanel:OnOffButton("PageButton" .. page, (page==1))
  pageButton.persistent = false
  pageButton.enabled = page <= numPages
  pageButton.displayName = "" .. page
  pageButton.backgroundColourOff = "#ff084486"
  pageButton.backgroundColourOn = "#ff02ACFE"
  pageButton.textColourOff = "#ff22FFFF"
  pageButton.textColourOn = "#efFFFFFF"
  pageButton.size = pageButtonSize
  pageButton.x = numPagesBox.width + ((pageButton.width + xPadding) * page) - 17
  pageButton.changed = function(self)
    if self.value == true then
      nextUp = page -- register next up
      if isPlaying == false then
        gotoNextPage()
      end
    end
    self:setValue(true, false) -- The clicked button should stay active
  end
  table.insert(pageButtons, pageButton)
end

cyclePagesButton.x = pageButtons[#pageButtons].x + pageButtons[#pageButtons].width + xPadding
nextPageButton.x = cyclePagesButton.x + cyclePagesButton.width + xPadding

actionMenu.persistent = false
actionMenu.tooltip = "Select an action. NOTE: This changes data in the affected tables"
actionMenu.backgroundColour = menuBackgroundColour
actionMenu.textColour = menuTextColour
actionMenu.arrowColour = menuArrowColour
actionMenu.outlineColour = menuOutlineColour
actionMenu.showLabel = false
actionMenu.x = changePageProbability.x + changePageProbability.width + 5
actionMenu.size = {110,22}
actionMenu.changed = function(self)
  -- 1 is the menu label...
  if self.value == 1 then
    return
  end
  if self.value == 2 then
    -- Randomize value table
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      for i=1,paramsPerPart[partIndex].numStepsBox.value do
        paramsPerPart[partIndex].seqValueTable:setValue(i, gem.getRandom(paramsPerPart[partIndex].seqValueTable.min, paramsPerPart[partIndex].seqValueTable.max))
      end
    end
  elseif self.value == 3 then
    -- Ramp Up
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      local valueRange = maxValue - minValue
      local changePerStep = valueRange / (numSteps - 1)
      local startValue = minValue
      for i=1,numSteps do
        paramsPerPart[partIndex].seqValueTable:setValue(i, startValue)
        startValue = startValue + changePerStep
      end
    end
  elseif self.value == 4 then
    -- Ramp Down
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      local valueRange = maxValue - minValue
      local changePerStep = valueRange / (numSteps - 1)
      local startValue = maxValue
      for i=1,numSteps do
        paramsPerPart[partIndex].seqValueTable:setValue(i, startValue)
        startValue = startValue - changePerStep
      end
    end
  elseif self.value == 5 then
    -- Triangle
    for part=1,numParts do
      local rising = true
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      local numStepsUpDown = gem.round(numSteps / 2)
      local valueRange = maxValue - minValue
      local changePerStep = valueRange / numStepsUpDown
      local startValue = minValue
      for i=1,numSteps do
        paramsPerPart[partIndex].seqValueTable:setValue(i, startValue)
        if rising then
          startValue = startValue + changePerStep
          if startValue >= maxValue then
            rising = false
          end
        else
          startValue = startValue - changePerStep
        end
      end
    end
  elseif self.value == 6 then
    -- Even
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i=1,numSteps do
        local val = minValue
        if i % 2 == 0 then
          val = maxValue
        end
        paramsPerPart[partIndex].seqValueTable:setValue(i, val)
      end
    end
  elseif self.value == 7 then
    -- Odd
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local minValue = paramsPerPart[partIndex].seqValueTable.min
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i=1,numSteps do
        --local val = math.min(2+2*i, math.abs((i-0.5)*2)-1)
        local val = maxValue
        if i % 2 == 0 then
          val = minValue
        end
        paramsPerPart[partIndex].seqValueTable:setValue(i, val)
      end
    end
  elseif self.value == 8 then
    -- Reduce 50%
    for part=1,numParts do
      local partIndex = getPartIndex(part)
      local seqValueTable = paramsPerPart[partIndex].seqValueTable
      local minValue = seqValueTable.min
      local maxValue = seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      for i=1,numSteps do
        local val = seqValueTable:getValue(i) / 2
        seqValueTable:setValue(i, val)
      end
    end
  else
    -- Copy settings from another page
    local sourcePage = self.value - #defaultActions
    local targetPage = activePage
    for part=1,numParts do
      local sourcePartIndex = getPartIndex(part, sourcePage)
      local targetPartIndex = getPartIndex(part, targetPage)
      if sourcePartIndex ~= targetPartIndex then
        local source = paramsPerPart[sourcePartIndex]
        local target = paramsPerPart[targetPartIndex]
        target.numStepsBox:setValue(source.numStepsBox.value)
        for i=1, target.numStepsBox.value do
          target.seqValueTable:setValue(i, source.seqValueTable:getValue(i))
          target.smoothStepTable:setValue(i, source.smoothStepTable:getValue(i))
        end
        -- Copy Settings
        target.stepResolution:setValue(source.stepResolution.value)
        target.smoothInput:setValue(source.smoothInput.value)
        target.valueRandomization:setValue(source.valueRandomization.value)
        target.smoothRandomization:setValue(source.smoothRandomization.value)
        target.stepButton:setValue(source.stepButton.value)
        target.bipolarButton:setValue(source.bipolarButton.value)
      end
    end
  end
  self.selected = 1
end

--------------------------------------------------------------------------------
-- Return Module
--------------------------------------------------------------------------------

return {
  headerPanel = headerPanel,
  footerPanel = footerPanel,
  actionMenu = actionMenu,
  labelInput = labelInput,
  playButton = playButton,
  autoplayButton = autoplayButton,
  getPartIndex = getPartIndex,
  setPageDuration = setPageDuration,
  setNumSteps = setNumSteps,
}
