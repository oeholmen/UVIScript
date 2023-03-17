--------------------------------------------------------------------------------
-- A sequencer sending script event modulation in broadcast mode
--------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"
local modseq = require "includes.modseq"

local isAutoPlayActive = false
local heldNotes = {}
local shapeNames = shapes.getShapeNames()
local shapeMenuItems = {"Select shape..."}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end

modseq.setTitle("Modulation Sequencer")
modseq.setTitleTooltip("A sequencer sending script event modulation in broadcast mode")

setBackgroundColour(modseq.colours.backgroundColour)

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local sourceIndex = modseq.headerPanel:NumBox("SourceIndex", 0, 0, 127, true)
sourceIndex.displayName = "Event Id"
sourceIndex.backgroundColour = modseq.colours.menuBackgroundColour
sourceIndex.textColour = modseq.colours.menuTextColour
sourceIndex.size = {102,22}
sourceIndex.x = modseq.autoplayButton.x - modseq.autoplayButton.width - 5
sourceIndex.y = modseq.autoplayButton.y

-- Add params that are to be editable per page / part
for page=1,modseq.getMaxPages() do
  local tableX = 0
  local tableY = 0
  local tableWidth = 640
  local tableHeight = 64
  local buttonRowHeight = 36
  local buttonSpacing = 9
  local defaultSteps = 16

  if modseq.getNumParts() == 1 then
    tableHeight = tableHeight * 2
  end

  local sequencerPanel = widgets.panel({name="SequencerPage" .. page})
  sequencerPanel.visible = page == 1
  sequencerPanel.backgroundColour = modseq.colours.menuOutlineColour
  sequencerPanel.x = 10
  sequencerPanel.y = modseq.headerPanel.height + 15
  sequencerPanel.width = 700
  sequencerPanel.height = modseq.getNumParts() * (tableHeight + 60 + buttonRowHeight)

  for part=1,modseq.getNumParts() do
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
    positionTable.sliderColour = "#FFB5FF"
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
    smoothStepTable.showPopupDisplay = true
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
    stepButton.size = {60,20}
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
    stepResolution.size = {75,20}
    stepResolution.backgroundColour = modseq.colours.menuBackgroundColour
    stepResolution.textColour = modseq.colours.menuTextColour
    stepResolution.arrowColour = modseq.colours.menuArrowColour
    stepResolution.outlineColour = modseq.colours.menuOutlineColour
    stepResolution.changed = function(self)
      modseq.setPageDuration(page)
    end

    local numStepsBox = sequencerPanel:NumBox("Steps" .. i, defaultSteps, 1, 128, true)
    numStepsBox.displayName = "Steps"
    numStepsBox.tooltip = "The Number of steps in the part"
    numStepsBox.visible = isVisible
    numStepsBox.backgroundColour = modseq.colours.menuBackgroundColour
    numStepsBox.textColour = modseq.colours.menuTextColour
    numStepsBox.arrowColour = modseq.colours.menuArrowColour
    numStepsBox.outlineColour = modseq.colours.menuOutlineColour
    numStepsBox.size = {100,20}
    numStepsBox.x = stepResolution.x + stepResolution.width + buttonSpacing
    numStepsBox.y = inputWidgetY
    numStepsBox.changed = function(self)
      modseq.setNumSteps(i, self.value)
      modseq.loadShape(i)
    end

    local valueRandomization = sequencerPanel:NumBox("ValueRandomization" .. i, 0, 0, 100, true)
    valueRandomization.displayName = "Value Rand"
    valueRandomization.tooltip = "Level of randomization applied to the control value"
    valueRandomization.unit = Unit.Percent
    valueRandomization.visible = isVisible
    valueRandomization.backgroundColour = modseq.colours.menuBackgroundColour
    valueRandomization.textColour = modseq.colours.menuTextColour
    valueRandomization.arrowColour = modseq.colours.menuArrowColour
    valueRandomization.outlineColour = modseq.colours.menuOutlineColour
    valueRandomization.size = {140,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    local smoothRandomization = sequencerPanel:NumBox("SmoothRandomization" .. i, 0, 0, 100, true)
    smoothRandomization.displayName = "Smooth Rand"
    smoothRandomization.tooltip = "Level of randomization applied to smooth level"
    smoothRandomization.unit = Unit.Percent
    smoothRandomization.visible = isVisible
    smoothRandomization.backgroundColour = modseq.colours.menuBackgroundColour
    smoothRandomization.textColour = modseq.colours.menuTextColour
    smoothRandomization.arrowColour = modseq.colours.menuArrowColour
    smoothRandomization.outlineColour = modseq.colours.menuOutlineColour
    smoothRandomization.size = valueRandomization.size
    smoothRandomization.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    smoothRandomization.y = inputWidgetY

    local smoothInput = sequencerPanel:NumBox("GlobalSmooth" .. i, 0, 0, 100, true)
    smoothInput.displayName = "Smooth"
    smoothInput.tooltip = "Use smoothing (non destructive) to even out the transition between value changes"
    smoothInput.unit = Unit.Percent
    smoothInput.visible = isVisible
    smoothInput.backgroundColour = modseq.colours.menuBackgroundColour
    smoothInput.textColour = modseq.colours.menuTextColour
    smoothInput.arrowColour = modseq.colours.menuArrowColour
    smoothInput.outlineColour = modseq.colours.menuOutlineColour
    smoothInput.size = valueRandomization.size
    smoothInput.x = smoothRandomization.x + smoothRandomization.width + buttonSpacing
    smoothInput.y = inputWidgetY

    widgets.setSection({
      x = 0,
      y = widgets.posUnder(stepButton) + 10,
      xSpacing = buttonSpacing,
    })

    local shapeMenu = widgets.menu("Shape", shapeMenuItems, {
      name = "shape" .. i,
      showLabel = false,
      width = 140,
      changed = function(self) modseq.loadShape(i, true) end
    })

    local widgetOptions = {width=114, showLabel=true}
    local shapeWidgets = shapes.getWidgets(widgetOptions, i)
    shapeWidgets.amount = shapes.getAmountWidget(widgetOptions, i)
    shapeWidgets.phase.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.factor.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.z.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.amount.changed = function(self) modseq.loadShape(i) end

    local bipolarButton = widgets.button("Bipolar", true, {
      name = "Bipolar" .. i,
      width = 59,
    })
    bipolarButton.changed = function(self)
      if self.value then
        seqValueTable:setRange(-100,100)
      else
        seqValueTable:setRange(0,100)
      end
    end
    bipolarButton:changed()

    local xyShapeMorph = widgets.getPanel():XY('ShapePhase' .. i, 'ShapeMorph' .. i)
    xyShapeMorph.x = widgets.posSide(seqValueTable)
    xyShapeMorph.y = seqValueTable.y
    xyShapeMorph.width = 51
    xyShapeMorph.height = seqValueTable.height

    modseq.addPartParams({shapeWidgets=shapeWidgets,shapeMenu=shapeMenu,bipolarButton=bipolarButton,stepButton=stepButton,smoothStepTable=smoothStepTable,smoothInput=smoothInput,valueRandomization=valueRandomization,smoothRandomization=smoothRandomization,seqValueTable=seqValueTable,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox})

    tableY = tableY + tableHeight + buttonRowHeight
  end

  local minRepeats = modseq.footerPanel:NumBox("MinRepeats" .. page, 1, 1, 128, true)
  minRepeats.displayName = "Repeats"
  minRepeats.tooltip = "The minimum number of repeats before page will be changed (only relevant when multiple pages are activated)"
  minRepeats.visible = page == 1
  minRepeats.enabled = false
  minRepeats.backgroundColour = modseq.colours.menuBackgroundColour
  minRepeats.textColour = modseq.colours.menuTextColour
  minRepeats.arrowColour = modseq.colours.menuArrowColour
  minRepeats.outlineColour = modseq.colours.menuOutlineColour
  minRepeats.size = {100,20}
  minRepeats.x = modseq.actionMenu.x + modseq.actionMenu.width + 9
  minRepeats.y = modseq.actionMenu.y

  modseq.addPageParams({sequencerPanel=sequencerPanel,minRepeats=minRepeats,pageDuration=nil,active=(page==1)})
  modseq.setPageDuration(page)
end

modseq.footerPanel.y = modseq.getPageParams(1).sequencerPanel.y + modseq.getPageParams(1).sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

modseq.setArpFunc(function(part, uniqueId)
  local index = 0
  while modseq.isPartPlaying(part, uniqueId) do
    local partIndex = modseq.getPartIndex(part)
    local numStepsInPart = modseq.getPartParams(partIndex).numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local smooth = modseq.getPartParams(partIndex).smoothInput.value
    local step = modseq.getPartParams(partIndex).stepButton.value
    local duration = resolutions.getResolution(modseq.getPartParams(partIndex).stepResolution.value)
    local seqValueTable = modseq.getPartParams(partIndex).seqValueTable
    local smoothStepTable = modseq.getPartParams(partIndex).smoothStepTable
    local valueRandomizationAmount = modseq.getPartParams(partIndex).valueRandomization.value
    local smoothRandomizationAmount = modseq.getPartParams(partIndex).smoothRandomization.value

    -- Set position
    for i=1, numStepsInPart do
      local isActiveStep = i >= currentPosition and i < currentPosition + 1
      if isActiveStep then
        modseq.getPartParams(partIndex).positionTable:setValue(i, 1)
      else
        modseq.getPartParams(partIndex).positionTable:setValue(i, 0)
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
end)

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

local function remove(voiceId)
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

  for _,v in ipairs(modseq.getPartParams()) do
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
    modseq.getPartParams(i).numStepsBox:setValue(v)
    modseq.getPartParams(i).seqValueTable.length = v
    modseq.getPartParams(i).smoothStepTable.length = v
    for j=1, v do
      modseq.getPartParams(i).seqValueTable:setValue(j, seqValueTableData[dataCounter])
      modseq.getPartParams(i).smoothStepTable:setValue(j, smoothStepTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,modseq.getNumPages() do
    modseq.setPageDuration(page)
  end
end
