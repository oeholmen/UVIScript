--------------------------------------------------------------------------------
-- A sequencer sending script event modulation in broadcast mode
--------------------------------------------------------------------------------

require "common"

local outlineColour = "#FFB5FF"
local menuBackgroundColour = "#bf01011F"
local menuTextColour = "#9f02ACFE"
local menuArrowColour = "#9f09A3F4"
local menuOutlineColour = "#00000000"
local pageBackgoundColour = "222222"
local defaultActions = {"Actions...", "Randomize", "Ramp Up", "Ramp Down", "Triangle", "Even", "Odd"}
local activePage = 1
local nextUp = 1
local pageButtons = {}
local paramsPerPart = {}
local paramsPerPage = {}
local isPlaying = false
local isAutoPlayActive = false
local numPages = 1
local heldNotes = {}

if type(numParts) == "nil" then
  numParts = 1
end

if type(maxPages) == "nil" then
  maxPages = 8
end

if type(title) == "nil" then
  title = "Modulation Sequencer"
end

setBackgroundColour(pageBackgoundColour)

--------------------------------------------------------------------------------
-- Functions
--------------------------------------------------------------------------------

-- Get the index for this part in paramsPerPart, given page and part number
function getPartIndex(part, page)
  if type(page) == "nil" then
    page = activePage -- Default is the active page
  end
  --print("getPartIndex page/part/numParts", page, part, numParts)
  return (page * numParts) + (part - numParts)
end

-- Get page from part index
function getPageFromPartIndex(partIndex)
  --print("getPageFromPartIndex partIndex", partIndex)
  return math.ceil(partIndex / maxPages)
end

function advancePage()
  local next = activePage + 1
  if next > numPages then
    next = 1
  end
  pageButtons[next]:setValue(true)
end

function gotoNextPage()
  -- Check that there is actually a a change
  if activePage == nextUp then
    return
  end
  activePage = nextUp
  for page,params in ipairs(paramsPerPage) do
    local isVisible = page == activePage
    params.sequencerPanel.visible = isVisible
    pageButtons[page]:setValue(isVisible, false)
  end
end

function clearPosition()
  for _,v in ipairs(paramsPerPart) do
    for i=1,v.numStepsBox.value do
      v.positionTable:setValue(i, 0)
    end
  end
end

function setNumSteps(partIndex, numSteps)
  print("setNumSteps for partIndex/numSteps", partIndex, numSteps)
  paramsPerPart[partIndex].positionTable.length = numSteps
  paramsPerPart[partIndex].seqValueTable.length = numSteps
  local page = getPageFromPartIndex(partIndex)
  setPageDuration(page)
end

function setPageDuration(page)
  print("setPageDuration for page", page)
  local pageResolutions = {}
  for part=1,numParts do
    local partIndex = getPartIndex(part, page)
    print("getResolution for partIndex", partIndex)
    local partResolution = getResolution(paramsPerPart[partIndex].stepResolution.value) * paramsPerPart[partIndex].numStepsBox.value
    table.insert(pageResolutions, partResolution)
    print("Added resolution/part/page", partResolution, part, page)
  end
  table.sort(pageResolutions)
  paramsPerPage[page].pageDuration = pageResolutions[#pageResolutions]
end

function startPlaying()
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

function stopPlaying()
  if isPlaying == false then
    return
  end
  print("Stop playing")
  isPlaying = false
  clearPosition()
  gotoNextPage()
end

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local headerPanel = Panel("Header")
headerPanel.backgroundColour = menuOutlineColour
headerPanel.x = 10
headerPanel.y = 10
headerPanel.width = 700
headerPanel.height = 30

local label = headerPanel:Label("Label")
label.text = title
label.align = "left"
label.backgroundColour = "808080"
label.textColour = pageBackgoundColour
label.fontSize = 22
label.position = {0,0}
label.size = {200,25}

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

local footerPanel = Panel("Footer")
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
local changePageProbability = footerPanel:NumBox("ChangePageProbability", 0, 0, 100, true)
changePageProbability.displayName = "Random"
changePageProbability.tooltip = "Probability of random page change"
changePageProbability.enabled = false
changePageProbability.unit = Unit.Percent
changePageProbability.size = {110,22}
changePageProbability.x = (33 * maxPages) + 102

local actionMenu = footerPanel:Menu("ActionMenu", defaultActions)
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
        paramsPerPart[partIndex].seqValueTable:setValue(i, getRandom(paramsPerPart[partIndex].seqValueTable.min, paramsPerPart[partIndex].seqValueTable.max))
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
      local maxValue = paramsPerPart[partIndex].seqValueTable.max
      local numSteps = paramsPerPart[partIndex].numStepsBox.value
      local numStepsUpDown = round(numSteps / 2)
      local changePerStep = maxValue / numStepsUpDown
      local startValue = 0
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
        local val = maxValue
        if i % 2 == 0 then
          val = minValue
        end
        paramsPerPart[partIndex].seqValueTable:setValue(i, val)
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
        end
        -- Copy Settings
        target.stepResolution:setValue(source.stepResolution.value)
        target.muteButton:setValue(source.muteButton.value)
        target.sourceIndex:setValue(source.sourceIndex.value)
        target.valueRandomization:setValue(source.valueRandomization.value)
        end  
    end
  end
  self.selected = 1
end

local pageTrigger = footerPanel:NumBox("PageTrigger", 96, 0, 127, true)
pageTrigger.enabled = false
pageTrigger.displayName = "Change"
pageTrigger.tooltip = "Go to next page by triggering this note. Notes immediately above, trigger pages directly."
pageTrigger.unit = Unit.MidiKey
pageTrigger.height = actionMenu.height
pageTrigger.width = 100

local nextPageButton = footerPanel:Button("NextPageButton")
nextPageButton.persistent = false
nextPageButton.enabled = numPages > 1
nextPageButton.displayName = ">"
nextPageButton.size = {25,22}
nextPageButton.changed = function(self)
  advancePage()
end

local cyclePagesButton = footerPanel:OnOffButton("CyclePagesButton")
cyclePagesButton.enabled = numPages > 1
cyclePagesButton.displayName = ">>"
cyclePagesButton.tooltip = "Play pages in cycle"
cyclePagesButton.backgroundColourOff = "#6600cc44"
cyclePagesButton.backgroundColourOn = "#aa00cc44"
cyclePagesButton.textColourOff = "#cc22FFFF"
cyclePagesButton.textColourOn = "#ccFFFFFF"
cyclePagesButton.size = {25,22}

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
  pageTrigger.enabled = self.value > 1
  for page=1,self.max do
    setPageDuration(page)
    pageButtons[page].enabled = page <= numPages
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
  pageButton.size = {25,22}
  pageButton.x = ((pageButton.width + xPadding) * page) + 76
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

pageTrigger.x = actionMenu.x + actionMenu.width + 9
pageTrigger.y = actionMenu.y

-- Add params that are to be editable per page / part
for page=1,maxPages do
  local tableX = 0
  local tableY = 0
  local tableWidth = 700
  local tableHeight = 64
  local buttonRowHeight = 36
  local buttonSpacing = 10
  local inputWidgetSize = {90,20}
  local defaultSteps = 16

  if numParts == 1 then
    tableHeight = tableHeight * 2
  end

  local sequencerPanel = Panel("SequencerPage" .. page)
  sequencerPanel.visible = page == 1
  sequencerPanel.backgroundColour = menuOutlineColour
  sequencerPanel.x = 10
  sequencerPanel.y = headerPanel.height + 15
  sequencerPanel.width = 700
  sequencerPanel.height = numParts * (tableHeight + buttonRowHeight)

  for part=1,numParts do
    local isVisible = true
    local i = getPartIndex(part, page)
    print("Set paramsPerPart, page/part", page, i)

    -- Tables

    local positionTable = sequencerPanel:Table("Position" .. i, defaultSteps, 0, 0, 1, true)
    positionTable.visible = isVisible
    positionTable.enabled = false
    positionTable.persistent = false
    positionTable.fillStyle = "solid"
    positionTable.backgroundColour = "#9f02ACFE"
    positionTable.sliderColour = outlineColour
    positionTable.width = tableWidth
    positionTable.height = 3
    positionTable.x = tableX
    positionTable.y = tableY

    local seqValueTable = sequencerPanel:Table("ModulationValue" .. i, defaultSteps, 0, 0, 100)
    seqValueTable.visible = isVisible
    seqValueTable.displayName = "Velocity"
    seqValueTable.tooltip = "Velocity for this step"
    seqValueTable.showPopupDisplay = true
    seqValueTable.showLabel = false
    seqValueTable.fillStyle = "solid"
    seqValueTable.sliderColour = "#9f09A3F4"
    if i % 2 == 0 then
      seqValueTable.backgroundColour = "#3f000000"
    else
      seqValueTable.backgroundColour = "#3f000000"
    end
    seqValueTable.width = tableWidth
    seqValueTable.height = tableHeight
    seqValueTable.x = tableX
    seqValueTable.y = positionTable.y + positionTable.height + 2
    
    local inputWidgetY = seqValueTable.y + seqValueTable.height + 5

    -- Inputs

    local sourceIndex = sequencerPanel:NumBox("SourceIndex" .. i, 0, 0, 127, true)
    sourceIndex.displayName = "Event Id"
    sourceIndex.visible = isVisible
    sourceIndex.backgroundColour = menuBackgroundColour
    sourceIndex.textColour = menuTextColour
    sourceIndex.size = inputWidgetSize
    sourceIndex.x = 0
    sourceIndex.y = inputWidgetY

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())
    stepResolution.tooltip = "Set the step resolution"
    stepResolution.showLabel = false
    stepResolution.visible = isVisible
    stepResolution.selected = 20
    stepResolution.x = sourceIndex.x + sourceIndex.width + buttonSpacing
    stepResolution.y = inputWidgetY
    stepResolution.size = inputWidgetSize
    stepResolution.backgroundColour = menuBackgroundColour
    stepResolution.textColour = menuTextColour
    stepResolution.arrowColour = menuArrowColour
    stepResolution.outlineColour = menuOutlineColour
    stepResolution.changed = function(self)
      setPageDuration(page)
    end

    local numStepsBox = sequencerPanel:NumBox("Steps" .. i, defaultSteps, 1, 128, true)
    numStepsBox.displayName = "Steps"
    numStepsBox.tooltip = "The Number of steps in the part"
    numStepsBox.visible = isVisible
    numStepsBox.backgroundColour = menuBackgroundColour
    numStepsBox.textColour = menuTextColour
    numStepsBox.arrowColour = menuArrowColour
    numStepsBox.outlineColour = menuOutlineColour
    numStepsBox.size = inputWidgetSize
    numStepsBox.x = stepResolution.x + stepResolution.width + buttonSpacing
    numStepsBox.y = inputWidgetY
    numStepsBox.changed = function(self)
      print("numStepsBox.changed index/value", i, self.value)
      setNumSteps(i, self.value)
    end

    local valueRandomization = sequencerPanel:NumBox("ValueRandomization" .. i, 0, 0, 100, true)
    valueRandomization.displayName = "Randomize"
    valueRandomization.tooltip = "Level of randomization applied to the control value"
    valueRandomization.unit = Unit.Percent
    valueRandomization.visible = isVisible
    valueRandomization.backgroundColour = menuBackgroundColour
    valueRandomization.textColour = menuTextColour
    valueRandomization.arrowColour = menuArrowColour
    valueRandomization.outlineColour = menuOutlineColour
    valueRandomization.size = {140,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    local smoothButton = sequencerPanel:OnOffButton("Smooth" .. i, false)
    smoothButton.displayName = "Smooth"
    smoothButton.tooltip = "Use smoothing (non destructive) to even out the transition between value changes"
    smoothButton.visible = isVisible
    smoothButton.backgroundColourOff = "#ff084486"
    smoothButton.backgroundColourOn = "#ff02ACFE"
    smoothButton.textColourOff = "#ff22FFFF"
    smoothButton.textColourOn = "#efFFFFFF"
    smoothButton.size = {77,20}
    smoothButton.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    smoothButton.y = inputWidgetY

    local bipolarButton = sequencerPanel:OnOffButton("Bipolar" .. i, false)
    bipolarButton.displayName = "Bipolar"
    bipolarButton.visible = isVisible
    bipolarButton.backgroundColourOff = "#ff084486"
    bipolarButton.backgroundColourOn = "#ff02ACFE"
    bipolarButton.textColourOff = "#ff22FFFF"
    bipolarButton.textColourOn = "#efFFFFFF"
    bipolarButton.size = smoothButton.size
    bipolarButton.x = smoothButton.x + smoothButton.width + buttonSpacing
    bipolarButton.y = inputWidgetY
    bipolarButton.changed = function(self)
      if self.value then
        seqValueTable:setRange(-100,100)
      else
        seqValueTable:setRange(0,100)
      end
    end

    local muteButton = sequencerPanel:OnOffButton("MutePart" .. i, false)
    muteButton.visible = isVisible
    muteButton.backgroundColourOff = "#ff084486"
    muteButton.backgroundColourOn = "#ff02ACFE"
    muteButton.textColourOff = "#ff22FFFF"
    muteButton.textColourOn = "#efFFFFFF"
    muteButton.displayName = "Mute"
    muteButton.tooltip = "Mute part"
    muteButton.size = smoothButton.size
    muteButton.x = bipolarButton.x + bipolarButton.width + buttonSpacing
    muteButton.y = inputWidgetY

    table.insert(paramsPerPart, {muteButton=muteButton,smoothButton=smoothButton,valueRandomization=valueRandomization,sourceIndex=sourceIndex,seqValueTable=seqValueTable,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox})

    tableY = tableY + tableHeight + buttonRowHeight
  end
  table.insert(paramsPerPage, {sequencerPanel=sequencerPanel,pageDuration=4,active=(page==1)})
  setPageDuration(page)
end

footerPanel.y = paramsPerPage[1].sequencerPanel.y + paramsPerPage[1].sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function pageRunner()
  local rounds = 0
  while isPlaying do
    rounds = rounds + 1
    if rounds > 1 and nextUp == activePage then
      if getRandomBoolean(changePageProbability.value) then
        nextUp = getRandom(numPages)
      elseif cyclePagesButton.value == true then
        nextUp = activePage + 1
        if nextUp > numPages then
          nextUp = 1
        end
      end
    end

    gotoNextPage()

    print("New round on page/duration/round", activePage, paramsPerPage[activePage].pageDuration, rounds)
    waitBeat(paramsPerPage[activePage].pageDuration)
  end
end

function arpeg(part)
  local index = 0
  while isPlaying do
    local partIndex = getPartIndex(part)
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local isPartActive = paramsPerPart[partIndex].muteButton.value == false
    local smooth = paramsPerPart[partIndex].smoothButton.value
    local duration = getResolution(paramsPerPart[partIndex].stepResolution.value)
    local seqValueTable = paramsPerPart[partIndex].seqValueTable
    local sourceIndex = paramsPerPart[partIndex].sourceIndex.value
    local valueRandomizationAmount = paramsPerPart[partIndex].valueRandomization.value

    -- Set position
    for i=1, numStepsInPart do
      local isActiveStep = i >= currentPosition and i < currentPosition + 1
      if isPartActive and isActiveStep then
        paramsPerPart[partIndex].positionTable:setValue(i, 1)
      else
        paramsPerPart[partIndex].positionTable:setValue(i, 0)
      end
    end

    -- Play note if trigger probability hits (and part is not turned off)
    if isPartActive then
      local rampTime = 20
      if smooth then
        rampTime = beat2ms(duration)
      end
      local value = seqValueTable:getValue(currentPosition)
      value = randomizeValue(value, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
      sendScriptModulation(sourceIndex, (value/100), rampTime)
    end

    -- Increment position
    index = (index + 1) % numStepsInPart

    -- Wait for next beat
    waitBeat(duration)
  end
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function remove(voiceId)
  for i,v in ipairs(heldNotes) do
    if v == voiceId then
      table.remove(heldNotes, i)
    end
  end
end

function onNote(e)
  if pageTrigger.enabled == true then
    for page=1, numPages do
      if pageTrigger.value == e.note then
        advancePage()
        break
      elseif (pageTrigger.value + page) == e.note then
        pageButtons[page]:setValue(true)
        break
      end
    end
  end
  local voiceId = postEvent(e)
  table.insert(heldNotes, voiceId)
  if #heldNotes == 1 then
    playButton:setValue(true)
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  remove(voiceId)
  -- Make sure we do not stop the modulation sequencer when transport is playing
  if #heldNotes == 0 and isAutoPlayActive == false then
    playButton:setValue(false)
  end
end

function onTransport(start)
  if autoplayButton.value == true then
    isAutoPlayActive = start
    playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqValueTableData = {}

  for _,v in ipairs(paramsPerPart) do
    table.insert(numStepsData, v.numStepsBox.value)
    for j=1, v.numStepsBox.value do
      table.insert(seqValueTableData, v.seqValueTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqValueTableData)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqValueTableData = data[2]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqValueTable.length = v
    for j=1, v do
      paramsPerPart[i].seqValueTable:setValue(j, seqValueTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,numPages do
    setPageDuration(page)
  end
end
