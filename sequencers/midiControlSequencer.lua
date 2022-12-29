--------------------------------------------------------------------------------
-- A sequencer sending midi control change values
--------------------------------------------------------------------------------

outlineColour = "#FFB5FF"
menuBackgroundColour = "#bf01011F"
menuTextColour = "#9f02ACFE"
menuArrowColour = "#9f09A3F4"
menuOutlineColour = "#00000000"
pageBackgoundColour = "222222"

if type(numParts) == "nil" then
  numParts = 1
end

if type(maxPages) == "nil" then
  maxPages = 8
end

if type(title) == "nil" then
  title = "Midi CC Sequencer"
end

setBackgroundColour(pageBackgoundColour)

--------------------------------------------------------------------------------
-- Include common functions and widgets
--------------------------------------------------------------------------------

require "includes.modseq"

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

-- Add params that are to be editable per page / part
for page=1,maxPages do
  local tableX = 0
  local tableY = 0
  local tableWidth = 700
  local tableHeight = 64
  local buttonRowHeight = 36
  local buttonSpacing = 10
  --local inputWidgetSize = {75,20}
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

    local seqValueTable = sequencerPanel:Table("ControlValue" .. i, defaultSteps, 0, 0, 127)
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
    local partLabelInput = sequencerPanel:Label("Label")
    partLabelInput.text = "CC " .. (part+101)
    partLabelInput.editable = true
    partLabelInput.backgroundColour = pageBackgoundColour
    partLabelInput.textColour = "808080"
    partLabelInput.backgroundColourWhenEditing = "white"
    partLabelInput.textColourWhenEditing = "black"
    partLabelInput.fontSize = 16
    partLabelInput.width = 75
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
      setPageDuration(page)
    end

    local stepResolution = sequencerPanel:Menu("StepResolution" .. i, getResolutionNames())
    stepResolution.tooltip = "Set the step resolution"
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
    numStepsBox.size = {90,20}
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
    valueRandomization.size = {115,20}
    valueRandomization.x = numStepsBox.x + numStepsBox.width + buttonSpacing
    valueRandomization.y = inputWidgetY

    local midiControlNumber = sequencerPanel:NumBox("MidiControlNumber" .. i, (part+101), 0, 127, true)
    midiControlNumber.displayName = "CC"
    midiControlNumber.tooltip = "The midi control number to send the value to"
    midiControlNumber.visible = isVisible
    midiControlNumber.backgroundColour = menuBackgroundColour
    midiControlNumber.textColour = menuTextColour
    midiControlNumber.size = {90,20}
    midiControlNumber.x = valueRandomization.x + valueRandomization.width + buttonSpacing
    midiControlNumber.y = inputWidgetY

    local channelBox = sequencerPanel:NumBox("Channel" .. i, 0, 0, 16, true)
    channelBox.displayName = "Ch"
    channelBox.tooltip = "Midi channel that receives CC from this part. 0 = omni"
    channelBox.visible = isVisible
    channelBox.backgroundColour = menuBackgroundColour
    channelBox.textColour = menuTextColour
    channelBox.arrowColour = menuArrowColour
    channelBox.outlineColour = menuOutlineColour
    channelBox.size = {75,20}
    channelBox.x = midiControlNumber.x + midiControlNumber.width + buttonSpacing
    channelBox.y = inputWidgetY

    local smoothButton = sequencerPanel:OnOffButton("Smooth" .. i, false)
    smoothButton.displayName = "Smooth"
    smoothButton.tooltip = "Use smoothing (non destructive) to even out the transition between value changes"
    smoothButton.visible = isVisible
    smoothButton.backgroundColourOff = "#ff084486"
    smoothButton.backgroundColourOn = "#ff02ACFE"
    smoothButton.textColourOff = "#ff22FFFF"
    smoothButton.textColourOn = "#efFFFFFF"
    smoothButton.size = {60,20}
    smoothButton.x = channelBox.x + channelBox.width + buttonSpacing
    smoothButton.y = inputWidgetY

    table.insert(paramsPerPart, {stepButton=stepButton,smoothButton=smoothButton,valueRandomization=valueRandomization,midiControlNumber=midiControlNumber,seqValueTable=seqValueTable,channelBox=channelBox,positionTable=positionTable,stepResolution=stepResolution,numStepsBox=numStepsBox,partLabelInput=partLabelInput})

    tableY = tableY + tableHeight + buttonRowHeight
  end

  local minRepeats = footerPanel:NumBox("MinRepeats" .. page, 1, 1, 128, true)
  minRepeats.displayName = "Repeats"
  minRepeats.tooltip = "The minimum number of repeats before page will be changed (only relevant when multiple pages are activated)"
  minRepeats.visible = page == 1
  minRepeats.enabled = false
  minRepeats.backgroundColour = menuBackgroundColour
  minRepeats.textColour = menuTextColour
  minRepeats.arrowColour = menuArrowColour
  minRepeats.outlineColour = menuOutlineColour
  minRepeats.size = {100,20}
  minRepeats.x = actionMenu.x + actionMenu.width + 9
  minRepeats.y = actionMenu.y

  table.insert(paramsPerPage, {sequencerPanel=sequencerPanel,minRepeats=minRepeats,pageDuration=4,active=(page==1)})
  setPageDuration(page)
end

footerPanel.y = paramsPerPage[1].sequencerPanel.y + paramsPerPage[1].sequencerPanel.height

--------------------------------------------------------------------------------
-- Sequencer
--------------------------------------------------------------------------------

function sendControlChange(duration, startValue, targetValue, controlChangeNumber, channel)
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
    controlChange(controlChangeNumber, round(value), channel)
    --print("Over time controlChangeNumber, value, channel", controlChangeNumber, value, channel)
    wait(durationPerIteration)
  until value == targetValue or i >= numberOfIterations
  print("value == targetValue or i >= numberOfIterations", value, targetValue, i, numberOfIterations)
end

function getNextValue(seqValueTable, currentPosition, numStepsInPart)
  local nextPosition = currentPosition + 1
  if nextPosition > numStepsInPart then
    nextPosition = 1
  end
  return seqValueTable:getValue(nextPosition)
end

function arpeg(part)
  local index = 0
  local startValue = nil
  local targetValue = nil
  while isPlaying do
    local partIndex = getPartIndex(part)
    local numStepsInPart = paramsPerPart[partIndex].numStepsBox.value
    local currentPosition = (index % numStepsInPart) + 1
    local smooth = paramsPerPart[partIndex].smoothButton.value
    local step = paramsPerPart[partIndex].stepButton.value
    local duration = getResolution(paramsPerPart[partIndex].stepResolution.value)
    local seqValueTable = paramsPerPart[partIndex].seqValueTable
    local controlChangeNumber = paramsPerPart[partIndex].midiControlNumber.value
    local channel = paramsPerPart[partIndex].channelBox.value
    local valueRandomizationAmount = paramsPerPart[partIndex].valueRandomization.value

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

    -- Send cc
    if type(startValue) == "nil" then
      startValue = seqValueTable:getValue(currentPosition)
      startValue = randomizeValue(startValue, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    end
    targetValue = getNextValue(seqValueTable, currentPosition, numStepsInPart) -- Get next value
    targetValue = randomizeValue(targetValue, seqValueTable.min, seqValueTable.max, valueRandomizationAmount)
    if channel == 0 then
      channel = nil -- Send on all channels
    end
    if smooth == false then
      controlChange(controlChangeNumber, round(startValue), channel)
      --print("Send controlChangeNumber, startValue, channel", controlChangeNumber, startValue, channel)
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
end

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Save / Load
--------------------------------------------------------------------------------

function onSave()
  local numStepsData = {}
  local seqValueTableData = {}
  local partLabelInputData = {}

  for _,v in ipairs(paramsPerPart) do
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
  table.insert(data, labelInput.text)

  return data
end

function onLoad(data)
  local numStepsData = data[1]
  local seqValueTableData = data[2]
  local partLabelInputData = data[3]
  labelInput.text = data[4]

  local dataCounter = 1
  for i,v in ipairs(numStepsData) do
    paramsPerPart[i].numStepsBox:setValue(v)
    paramsPerPart[i].partLabelInput.text = partLabelInputData[i]
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
