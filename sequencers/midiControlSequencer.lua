--------------------------------------------------------------------------------
-- A sequencer sending midi control change values
--------------------------------------------------------------------------------

local gem = require "includes.common"
local shapes = require "includes.shapes"
local widgets = require "includes.widgets"
local resolutions = require "includes.resolutions"
local modseq = require "includes.modseq"

local shapeNames = shapes.getShapeNames()
local shapeMenuItems = {"Select shape..."}
for _,v in ipairs(shapeNames) do
  table.insert(shapeMenuItems, v)
end
local preInit = true -- Used to avoid sending midi cc on startup

modseq.setTitle("Midi CC Sequencer")

setBackgroundColour(modseq.colours.backgroundColour)

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

-- Add params that are to be editable per page / part
for page=1,modseq.getMaxPages() do
  local tableX = 0
  local tableY = 0
  local tableWidth = 640
  local tableHeight = 63
  local buttonRowHeight = 60
  local buttonSpacing = 10
  local defaultSteps = 16
  local midiControlNumber
  local channelBox

  if modseq.getNumParts() == 1 then
    tableHeight = tableHeight * 1.5
  end

  local sequencerPanel = widgets.panel({name="SequencerPage" .. page})
  sequencerPanel.visible = page == 1
  sequencerPanel.backgroundColour = modseq.colours.menuOutlineColour
  sequencerPanel.x = 10
  sequencerPanel.y = modseq.headerPanel.height + 15
  sequencerPanel.width = 700
  sequencerPanel.height = modseq.getNumParts() * (tableHeight + buttonRowHeight)

  for part=1,modseq.getNumParts() do
    local isVisible = true
    local i = modseq.getPartIndex(part, page)
    print("Set paramsPerPart, page/part", page, i)

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

    local seqValueTable = sequencerPanel:Table("ControlValue" .. i, defaultSteps, 0, 0, 127, true)
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
    seqValueTable.changed = function(self, index)
      if preInit == false then
        local controlChangeNumber = midiControlNumber.value
        local channel = channelBox.value
        controlChange(controlChangeNumber, self:getValue(index), channel)
      end
    end

    local inputWidgetY = seqValueTable.y + seqValueTable.height + 5

    -- Inputs
    local partLabelInput = sequencerPanel:Label("Label")
    partLabelInput.text = "CC " .. (part+101)
    partLabelInput.editable = true
    partLabelInput.backgroundColour = modseq.colours.backgroundColour
    partLabelInput.textColour = "808080"
    partLabelInput.backgroundColourWhenEditing = "white"
    partLabelInput.textColourWhenEditing = "black"
    partLabelInput.fontSize = 16
    partLabelInput.width = 81
    partLabelInput.height = 20
    partLabelInput.x = 0
    partLabelInput.y = inputWidgetY

    local stepButton = sequencerPanel:OnOffButton("Step" .. i, false)
    stepButton.displayName = "Step"
    stepButton.tooltip = "The selected resolution applies to each step, not the whole round"
    stepButton.visible = isVisible
    stepButton.backgroundColourOff = "#ff084486"
    stepButton.backgroundColourOn = "#ff02ACFE"
    stepButton.textColourOff = "#ff22FFFF"
    stepButton.textColourOn = "#efFFFFFF"
    stepButton.size = {60,20}
    stepButton.x = partLabelInput.x + partLabelInput.width + buttonSpacing
    stepButton.y = inputWidgetY
    stepButton.changed = function(self)
      modseq.setPageDuration(page)
    end

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, resolutions.getResolutionNames())
    stepResolution.tooltip = "Set the resolution for each round (or step, if selected)"
    stepResolution.showLabel = false
    stepResolution.visible = isVisible
    stepResolution.selected = 11
    stepResolution.x = stepButton.x + stepButton.width + buttonSpacing
    stepResolution.y = inputWidgetY
    stepResolution.size = {66,20}
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
    numStepsBox.size = {90,20}
    numStepsBox.x = stepResolution.x + stepResolution.width + buttonSpacing
    numStepsBox.y = inputWidgetY
    numStepsBox.changed = function(self)
      print("numStepsBox.changed index/value", i, self.value)
      modseq.setNumSteps(i, self.value)
      modseq.loadShape(i)
    end

    local valueRandomization = sequencerPanel:NumBox("ValueRandomization" .. i, 0, 0, 100, true)
    valueRandomization.displayName = "Randomize"
    valueRandomization.tooltip = "Level of randomization applied to the control value"
    valueRandomization.unit = Unit.Percent
    valueRandomization.visible = isVisible
    valueRandomization.backgroundColour = modseq.colours.menuBackgroundColour
    valueRandomization.textColour = modseq.colours.menuTextColour
    valueRandomization.arrowColour = modseq.colours.menuArrowColour
    valueRandomization.outlineColour = modseq.colours.menuOutlineColour
    valueRandomization.size = {114,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    midiControlNumber = sequencerPanel:NumBox("MidiControlNumber" .. i, (part+101), 0, 127, true)
    midiControlNumber.displayName = "CC"
    midiControlNumber.tooltip = "The midi control number to send the value to"
    midiControlNumber.visible = isVisible
    midiControlNumber.backgroundColour = modseq.colours.menuBackgroundColour
    midiControlNumber.textColour = modseq.colours.menuTextColour
    midiControlNumber.size = valueRandomization.size
    midiControlNumber.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    midiControlNumber.y = inputWidgetY

    channelBox = sequencerPanel:NumBox("Channel" .. i, 0, 0, 16, true)
    channelBox.displayName = "Channel"
    channelBox.tooltip = "Midi channel that receives CC from this part. 0 = omni"
    channelBox.visible = isVisible
    channelBox.backgroundColour = modseq.colours.menuBackgroundColour
    channelBox.textColour = modseq.colours.menuTextColour
    channelBox.arrowColour = modseq.colours.menuArrowColour
    channelBox.outlineColour = modseq.colours.menuOutlineColour
    channelBox.size = valueRandomization.size
    channelBox.x = midiControlNumber.x + midiControlNumber.width + buttonSpacing
    channelBox.y = inputWidgetY

    widgets.setSection({
      x = 0,
      y = widgets.posUnder(partLabelInput) + 6,
      xSpacing = buttonSpacing,
    })

    local shapeMenu = widgets.menu("Shape", shapeMenuItems, {
      name = "shape" .. i,
      showLabel = false,
      width = 131,
      changed = function(self)
        modseq.loadShape(i, true)
      end
    })

    local widgetOptions = {width=115, showLabel=true}
    local shapeWidgets = shapes.getWidgets(widgetOptions, i)
    shapeWidgets.amount = shapes.getAmountWidget(widgetOptions, i)

    local smoothButton = widgets.button("Smooth", false, {
      name = "Smooth" .. i,
      tooltip = "Use smoothing (non destructive) to even out the transition between value changes",
      width = 58,
    })

    shapeWidgets.phase.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.factor.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.z.changed = function(self) modseq.loadShape(i) end
    shapeWidgets.amount.changed = function(self) modseq.loadShape(i) end

    local xyShapeMorph = widgets.getPanel():XY('ShapePhase' .. i, 'ShapeMorph' .. i)
    xyShapeMorph.x = widgets.posSide(seqValueTable) - 8
    xyShapeMorph.y = seqValueTable.y
    xyShapeMorph.width = 58
    xyShapeMorph.height = seqValueTable.height

    modseq.addPartParams({shapeWidgets=shapeWidgets,shapeMenu=shapeMenu,stepButton=stepButton,smoothButton=smoothButton,valueRandomization=valueRandomization,midiControlNumber=midiControlNumber,seqValueTable=seqValueTable,channelBox=channelBox,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox,partLabelInput=partLabelInput})

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
  minRepeats.x = modseq.actionMenu.x + modseq.actionMenu.width + 8
  minRepeats.y = modseq.actionMenu.y

  modseq.addPageParams({sequencerPanel=sequencerPanel,minRepeats=minRepeats,pageDuration=4,active=(page==1)})
  modseq.setPageDuration(page)
end

modseq.footerPanel.y = modseq.getPageParams(1).sequencerPanel.y + modseq.getPageParams(1).sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

local function sendControlChange(duration, startValue, targetValue, controlChangeNumber, channel)
  local durationInMs = beat2ms(duration)
  local numberOfIterations = math.max(startValue, targetValue) - math.min(startValue, targetValue)
  local durationPerIteration = math.ceil(durationInMs / numberOfIterations)
  local value = startValue
  local increment = 1
  if targetValue < startValue then
    increment = -1
  end
  print("numberOfIterations, durationPerIteration", numberOfIterations, durationPerIteration)
  local i = 0
  repeat
    value = value + increment -- Increment value
    i = i + 1 -- Increment counter
    controlChange(controlChangeNumber, gem.round(value), channel)
    --print("Over time controlChangeNumber, value, channel", controlChangeNumber, value, channel)
    wait(durationPerIteration)
  until value == targetValue or i >= numberOfIterations
  print("value == targetValue or i >= numberOfIterations", value, targetValue, i, numberOfIterations)
end

local function getNextValue(seqValueTable, currentPosition, numStepsInPart)
  local nextPosition = currentPosition + 1
  if nextPosition > numStepsInPart then
    nextPosition = 1
  end
  return seqValueTable:getValue(nextPosition)
end

modseq.setArpFunc(function(part, uniqueId)
  local index = 0
  local startValue = nil
  local targetValue = nil
  while modseq.isPartPlaying(part, uniqueId) do
    local partIndex = modseq.getPartIndex(part)
    local numStepsInPart = modseq.getPartParams(partIndex).numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local smooth = modseq.getPartParams(partIndex).smoothButton.value
    local step = modseq.getPartParams(partIndex).stepButton.value
    local duration = resolutions.getResolution(modseq.getPartParams(partIndex).stepResolution.value)
    local seqValueTable = modseq.getPartParams(partIndex).seqValueTable
    local controlChangeNumber = modseq.getPartParams(partIndex).midiControlNumber.value
    local channel = modseq.getPartParams(partIndex).channelBox.value
    local valueRandomizationAmount = modseq.getPartParams(partIndex).valueRandomization.value

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

    -- Send cc
    if type(startValue) == "nil" then
      startValue = seqValueTable:getValue(currentPosition)
      startValue = gem.randomizeValue(startValue, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    end
    targetValue = getNextValue(seqValueTable, currentPosition, numStepsInPart) -- Get next value
    targetValue = gem.randomizeValue(targetValue, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    if channel == 0 then
      channel = nil -- Send on all channels
    end
    if smooth == false then
      controlChange(controlChangeNumber, gem.round(startValue), channel)
      --print("Send controlChangeNumber, startValue, channel", controlChangeNumber, gem.round(startValue), channel)
    else
      -- Send cc over time
      spawn(sendControlChange, duration, startValue, targetValue, controlChangeNumber, channel)
    end
    startValue = targetValue

    -- Increment position
    index = (index + 1) % numStepsInPart

    -- Wait for next beat
    waitBeat(duration)
  end
end)

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

function onNote(e)
  if modseq.autoplayButton.value == true then
    postEvent(e)
  else
    modseq.playButton:setValue(true)
  end
end

function onRelease(e)
  if modseq.autoplayButton.value == true then
    postEvent(e)
  else
    modseq.playButton:setValue(false)
  end
end

function onTransport(start)
  if modseq.autoplayButton.value == true then
    modseq.playButton:setValue(start)
  end
end

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onInit()
  preInit = false
end

function onSave()
  local numStepsData = {}
  local seqValueTableData = {}
  local partLabelInputData = {}

  for _,v in ipairs(modseq.getPartParams()) do
    table.insert(numStepsData, v.numStepsBox.value)
    table.insert(partLabelInputData, v.partLabelInput.text)
    for j=1, v.numStepsBox.value do
      table.insert(seqValueTableData, v.seqValueTable:getValue(j))
    end
  end

  local data = {}
  table.insert(data, numStepsData)
  table.insert(data, seqValueTableData)
  table.insert(data, partLabelInputData)
  table.insert(data, modseq.labelInput.text)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqValueTableData = data[2]
  local partLabelInputData = data[3]
  modseq.labelInput.text = data[4]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    modseq.getPartParams(i).numStepsBox:setValue(v)
    modseq.getPartParams(i).partLabelInput.text = partLabelInputData[i]
    modseq.getPartParams(i).seqValueTable.length = v
    for j=1, v do
      modseq.getPartParams(i).seqValueTable:setValue(j, seqValueTableData[dataCounter])
      dataCounter = dataCounter + 1
    end
  end
  for page=1,modseq.getNumPages() do
    modseq.setPageDuration(page)
  end
end
