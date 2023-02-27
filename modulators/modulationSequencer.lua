--------------------------------------------------------------------------------
-- A sequencer sending script event modulation in broadcast mode
--------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local resolutions = require "includes.resolutions"
local modseq = require "includes.modseq"

local isAutoPlayActive = false
local heldNotes = {}

modseq.setTitle("Modulation Sequencer")
modseq.setTitleTooltip("A sequencer sending script event modulation in broadcast mode")

setBackgroundColour(pageBackgoundColour)

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local sourceIndex = modseq.headerPanel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.displayName = "Event Id"
sourceIndex.backgroundColour = menuBackgroundColour
sourceIndex.textColour = menuTextColour
sourceIndex.size = {102,22}
sourceIndex.x = modseq.autoplayButton.x - modseq.autoplayButton.width - 5
sourceIndex.y = modseq.autoplayButton.y

-- Add params that are to be editable per page / part
for page=1,maxPages do
  local tableX = 0
  local tableY = 0
  local tableWidth = 700
  local tableHeight = 64
  local buttonRowHeight = 36
  local buttonSpacing = 9
  local inputWidgetSize = {90,20}
  local defaultSteps = 16

  if numParts == 1 then
    tableHeight = tableHeight * 2
  end

  local sequencerPanel = Panel("SequencerPage" .. page)
  sequencerPanel.visible = page == 1
  sequencerPanel.backgroundColour = menuOutlineColour
  sequencerPanel.x = 10
  sequencerPanel.y = modseq.headerPanel.height + 15
  sequencerPanel.width = 700
  sequencerPanel.height = numParts * (tableHeight + 30 + buttonRowHeight)

  for part=1,numParts do
    local isVisible = true
    local i = modseq.getPartIndex(part, page)
    --print("Set paramsPerPart, page/part", page, i)

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
    
    local smoothStepTable = sequencerPanel:Table("SmoothStep" .. i, defaultSteps, 0, 0, 100, true)
    smoothStepTable.visible = isVisible
    smoothStepTable.tooltip = "Smooth transition to next step (overrides global smoothing for this step)"
    smoothStepTable.fillStyle = "solid"
    if i % 2 == 0 then
      smoothStepTable.backgroundColour = "#3f606060"
    else
      smoothStepTable.backgroundColour = "#3f606060"
    end
    smoothStepTable.showLabel = false
    smoothStepTable.sliderColour = "#3f339900"
    smoothStepTable.width = tableWidth
    smoothStepTable.height = 30
    smoothStepTable.x = tableX
    smoothStepTable.y = seqValueTable.y + seqValueTable.height + 2

    local inputWidgetY = smoothStepTable.y + smoothStepTable.height + 5

    -- Inputs

    local stepButton = sequencerPanel:OnOffButton("Step" .. i, false)
    stepButton.displayName = "Step"
    stepButton.tooltip = "The selected resolution applies to each step, not the whole round"
    stepButton.visible = isVisible
    stepButton.backgroundColourOff = "#ff084486"
    stepButton.backgroundColourOn = "#ff02ACFE"
    stepButton.textColourOff = "#ff22FFFF"
    stepButton.textColourOn = "#efFFFFFF"
    stepButton.size = {53,20}
    stepButton.x = 0
    stepButton.y = inputWidgetY
    stepButton.changed = function(self)
      modseq.setPageDuration(page)
    end

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())
    stepResolution.tooltip = "Set the round (or step) resolution"
    stepResolution.showLabel = false
    stepResolution.visible = isVisible
    stepResolution.selected = 11
    stepResolution.x = stepButton.x + stepButton.width + buttonSpacing
    stepResolution.y = inputWidgetY
    stepResolution.size = {60,20}
    stepResolution.backgroundColour = menuBackgroundColour
    stepResolution.textColour = menuTextColour
    stepResolution.arrowColour = menuArrowColour
    stepResolution.outlineColour = menuOutlineColour
    stepResolution.changed = function(self)
      modseq.setPageDuration(page)
    end

    local numStepsBox = sequencerPanel:NumBox("Steps" .. i, defaultSteps, 1, 128, true)
    numStepsBox.displayName = "Steps"
    numStepsBox.tooltip = "The Number of steps in the part"
    numStepsBox.visible = isVisible
    numStepsBox.backgroundColour = menuBackgroundColour
    numStepsBox.textColour = menuTextColour
    numStepsBox.arrowColour = menuArrowColour
    numStepsBox.outlineColour = menuOutlineColour
    numStepsBox.size = {80,20}
    numStepsBox.x = stepResolution.x + stepResolution.width + buttonSpacing
    numStepsBox.y = inputWidgetY
    numStepsBox.changed = function(self)
      --print("numStepsBox.changed index/value", i, self.value)
      modseq.setNumSteps(i, self.value)
    end

    local valueRandomization = sequencerPanel:NumBox("ValueRandomization" .. i, 0, 0, 100, true)
    valueRandomization.displayName = "Value Rand"
    valueRandomization.tooltip = "Level of randomization applied to the control value"
    valueRandomization.unit = Unit.Percent
    valueRandomization.visible = isVisible
    valueRandomization.backgroundColour = menuBackgroundColour
    valueRandomization.textColour = menuTextColour
    valueRandomization.arrowColour = menuArrowColour
    valueRandomization.outlineColour = menuOutlineColour
    valueRandomization.size = {150,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    local smoothRandomization = sequencerPanel:NumBox("SmoothRandomization" .. i, 0, 0, 100, true)
    smoothRandomization.displayName = "Smooth Rand"
    smoothRandomization.tooltip = "Level of randomization applied to smooth level"
    smoothRandomization.unit = Unit.Percent
    smoothRandomization.visible = isVisible
    smoothRandomization.backgroundColour = menuBackgroundColour
    smoothRandomization.textColour = menuTextColour
    smoothRandomization.arrowColour = menuArrowColour
    smoothRandomization.outlineColour = menuOutlineColour
    smoothRandomization.size = {150,20}
    smoothRandomization.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    smoothRandomization.y = inputWidgetY

    local smoothInput = sequencerPanel:NumBox("GlobalSmooth" .. i, 0, 0, 100, true)
    smoothInput.displayName = "Smooth"
    smoothInput.tooltip = "Use smoothing (non destructive) to even out the transition between value changes"
    smoothInput.unit = Unit.Percent
    smoothInput.visible = isVisible
    smoothInput.backgroundColour = menuBackgroundColour
    smoothInput.textColour = menuTextColour
    smoothInput.arrowColour = menuArrowColour
    smoothInput.outlineColour = menuOutlineColour
    smoothInput.size = {100,20}
    smoothInput.x = smoothRandomization.x + smoothRandomization.width + buttonSpacing
    smoothInput.y = inputWidgetY

    local bipolarButton = sequencerPanel:OnOffButton("Bipolar" .. i, true)
    bipolarButton.displayName = "Bipolar"
    bipolarButton.visible = isVisible
    bipolarButton.backgroundColourOff = "#ff084486"
    bipolarButton.backgroundColourOn = "#ff02ACFE"
    bipolarButton.textColourOff = "#ff22FFFF"
    bipolarButton.textColourOn = "#efFFFFFF"
    bipolarButton.size = {53,20}
    bipolarButton.x = smoothInput.x + smoothInput.width + buttonSpacing
    bipolarButton.y = inputWidgetY
    bipolarButton.changed = function(self)
      if self.value then
        seqValueTable:setRange(-100,100)
      else
        seqValueTable:setRange(0,100)
      end
    end
    bipolarButton:changed()

    table.insert(paramsPerPart, {stepButton=stepButton,smoothStepTable=smoothStepTable,smoothInput=smoothInput,valueRandomization=valueRandomization,smoothRandomization=smoothRandomization,seqValueTable=seqValueTable,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox})

    tableY = tableY + tableHeight + buttonRowHeight
  end

  local minRepeats = modseq.footerPanel:NumBox("MinRepeats" .. page, 1, 1, 128, true)
  minRepeats.displayName = "Repeats"
  minRepeats.tooltip = "The minimum number of repeats before page will be changed (only relevant when multiple pages are activated)"
  minRepeats.visible = page == 1
  minRepeats.enabled = false
  minRepeats.backgroundColour = menuBackgroundColour
  minRepeats.textColour = menuTextColour
  minRepeats.arrowColour = menuArrowColour
  minRepeats.outlineColour = menuOutlineColour
  minRepeats.size = {100,20}
  minRepeats.x = modseq.actionMenu.x + modseq.actionMenu.width + 9
  minRepeats.y = modseq.actionMenu.y

  table.insert(paramsPerPage, {sequencerPanel=sequencerPanel,minRepeats=minRepeats,pageDuration=nil,active=(page==1)})
  modseq.setPageDuration(page)
end

modseq.footerPanel.y = paramsPerPage[1].sequencerPanel.y + paramsPerPage[1].sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function arpeg(part)
  local index = 0
  while isPlaying do
    local partIndex = modseq.getPartIndex(part)
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local smooth = paramsPerPart[partIndex].smoothInput.value
    local step = paramsPerPart[partIndex].stepButton.value
    local duration = resolutions.getResolution(paramsPerPart[partIndex].stepResolution.value)
    local seqValueTable = paramsPerPart[partIndex].seqValueTable
    local smoothStepTable = paramsPerPart[partIndex].smoothStepTable
    local valueRandomizationAmount = paramsPerPart[partIndex].valueRandomization.value
    local smoothRandomizationAmount = paramsPerPart[partIndex].smoothRandomization.value

    -- Set position
    for i=1, numStepsInPart do
      local isActiveStep = i >= currentPosition and i < currentPosition + 1
      if isActiveStep then
        paramsPerPart[partIndex].positionTable:setValue(i, 1)
      else
        paramsPerPart[partIndex].positionTable:setValue(i, 0)
      end
    end

    if step == false then
      duration = duration / numStepsInPart
    end

    -- Send modulation
    local smoothStepValue = smoothStepTable:getValue(currentPosition)
    if smoothStepValue > 0 then
      smooth = smoothStepValue
    end
    smooth = gem.randomizeValue(smooth, smoothStepTable.min, smoothStepTable.max, smoothRandomizationAmount)
    local rampTime = 20
    if smooth > 0 then
      rampTime = beat2ms(duration) * (smooth / 100)
    end
    local value = seqValueTable:getValue(currentPosition)
    value = gem.randomizeValue(value, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    sendScriptModulation(sourceIndex.value, (value/100), rampTime)

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
  local voiceId = postEvent(e)
  table.insert(heldNotes, voiceId)
  if #heldNotes == 1 then
    modseq.playButton:setValue(true)
  end
end

function onRelease(e)
  local voiceId = postEvent(e)
  remove(voiceId)
  -- Make sure we do not stop the modulation sequencer when transport is playing
  if #heldNotes == 0 and isAutoPlayActive == false then
    modseq.playButton:setValue(false)
  end
end

function onTransport(start)
  if modseq.autoplayButton.value == true then
    isAutoPlayActive = start
    modseq.playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqValueTableData = {}
  local smoothStepTableData = {}

  for _,v in ipairs(paramsPerPart) do
    table.insert(numStepsData, v.numStepsBox.value)
    for j=1, v.numStepsBox.value do
      table.insert(seqValueTableData, v.seqValueTable:getValue(j))
      table.insert(smoothStepTableData, v.smoothStepTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqValueTableData)
  table.insert(data, smoothStepTableData)
  table.insert(data, modseq.labelInput.text)
  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqValueTableData = data[2]
  local smoothStepTableData = data[3]
  modseq.labelInput.text = data[4]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].seqValueTable.length = v
    paramsPerPart[i].smoothStepTable.length = v
    for j=1, v do
      paramsPerPart[i].seqValueTable:setValue(j, seqValueTableData[dataCounter])
      paramsPerPart[i].smoothStepTable:setValue(j, smoothStepTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,numPages do
    modseq.setPageDuration(page)
  end
end
