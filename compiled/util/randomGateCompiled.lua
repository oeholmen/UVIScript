-- util/randomGate -- 
--------------------------------------------------------------------------------
-- Common methods
--------------------------------------------------------------------------------

local function getRandom(min, max, factor)
  if type(min) == "number" and type(max) == "number" and min < max then
    return math.random(min, max)
  elseif type(min) == "number" then
    return math.random(min)
  end
  local value = math.random()
  if type(factor) == "number" then
    value = value * factor
  end
  return value
end

local function getRandomBoolean(probability)
  -- Default probability of getting true is 50%
  if type(probability) ~= "number" then
    probability = 50
  end
  return getRandom(100) <= probability
end

local function getChangeMax(max, probabilityLevel)
  return math.ceil(max * (probabilityLevel / 100))
end

local function getIndexFromValue(value, selection)
  for i,v in ipairs(selection) do
    if v == value then
      return i
    end
  end
  return nil
end

local function randomizeValue(value, limitMin, limitMax, randomizationAmount)
  if randomizationAmount > 0 then
    local limitRange = limitMax - limitMin
    local changeMax = getChangeMax(limitRange, randomizationAmount)
    local min = math.max(limitMin, (value - changeMax))
    local max = math.min(limitMax, (value + changeMax))
    --print("Before randomize value", value)
    value = getRandom(min, max)
    --print("After randomize value/changeMax/min/max", value, changeMax, min, max)
  end
  return value
end

local function round(value)
  local int, frac = math.modf(value)
  --print("int/frac", int, frac)
  if math.abs(frac) < 0.5 then
    value = int
  elseif value < 0 then
    value = int - 1
  else
    value = int + 1
  end
  return value
end

local function tableIncludes(theTable, theItem)
  return type(getIndexFromValue(theItem, theTable)) == "number"
end

local function getRandomFromTable(theTable, except)
  if #theTable == 0 then
    return nil
  end
  if #theTable == 1 then
    return theTable[1]
  end
  local index = getRandom(#theTable)
  local value = theTable[index]
  --print("getRandomFromTable index, value", index, value)
  if type(except) ~= "nil" then
    local maxRounds = 10
    while value == except and maxRounds > 0 do
      value = theTable[getRandom(#theTable)]
      maxRounds = maxRounds - 1
      --print("getRandomFromTable except, maxRounds", except, maxRounds)
    end
  end
  return value
end

local function trimStartAndEnd(s)
  return s:match("^%s*(.-)%s*$")
end

local function getChangePerStep(valueRange, numSteps)
  return valueRange / (numSteps - 1)
end

local function inc(val, inc, resetAt, resetTo)
  if type(inc) ~= "number" then
    inc = 1
  end
  if type(resetTo) ~= "number" then
    resetTo = 1
  end
  val = val + inc
  if type(resetAt) == "number" then
    if (inc > 0 and val > resetAt) or (inc < 0 and val < resetAt) then
      val = resetTo
    end
  end
  return val
end

-- sign function: -1 if x<0; 1 if x>0
local function signA(x)
  if x < 0 then
    return -1
  end
  return 1
end

-- sign function oposite: 1 if x<0; -1 if x>0
local function signB(x)
  if x < 0 then
    return 1
  end
  return -1
end

-- z = current table number, from -1.0 to 1.0
-- w = x current time-value getting plotted, from 0.0 to 1.0 same as (x+1)/2
-- When a 'q' is preset in the formula, the function plots to the FFT bins instead of plotting the to the waveform display. q iterates from 1 to 512 for the respective harmonics/bins. **
local function testShape(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = x
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- 0.5*(cos(x*pi/2)*((sin((x)*pi)+(1-z)*(sin(z*((x*x)^z)*pi*32)))))
local function sweetSine(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = 0.5*(math.cos(x*math.pi/2)*((math.sin((x)*math.pi)+(1-z)*(math.sin(z*((x*x)^z)*math.pi*32)))))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- sin(w*pi*(2+(62*z*z*z)))*sin(w*pi)
local function softSine(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = -0
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- sin(w*pi*(2+(62*z*z*z)))*sin(w*pi)
local function drop(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 1
    local q = 1
    local x = (changePerStep * (i-1)) - 1
    local w = x
    local value = math.sin(w*math.pi*(2+(62*z*z*z)))*math.sin(w*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- cos(x*pi/2)*1.6*(.60*sin( ((z*16)+1)*3*x ) + .20*sin( ((z*16)+1)*9*x ) + .15*sin( ((z*16)+1)*15*x))
local function tripleSin(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local z = 0
    local x = (changePerStep * (i-1)) - 1
    local value = math.cos(x*math.pi/2)*1.6*(.60*math.sin( ((z*16)+1)*3*x ) + .20*math.sin( ((z*16)+1)*9*x ) + .15*math.sin( ((z*16)+1)*15*x))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- organish sin(x*pi)+(0.16*(sin(2*x*pi)+sin(3*x*pi)+sin(4*x*pi)))
local function organIsh(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.sin(x*math.pi)+(0.16*(math.sin(2*x*math.pi)+math.sin(3*x*math.pi)+math.sin(4*x*math.pi)))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- filtered sqr 1.2*sin(x*pi)+0.31*sin(x*pi*3)+0.11*sin(x*pi*5)+0.033*sin(x*pi*7)
local function filteredSquare(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = 1.2*math.sin(x*math.pi)+0.31*math.sin(x*math.pi*3)+0.11*math.sin(x*math.pi*5)+0.033*math.sin(x*math.pi*7)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- hpf saw x-(0.635*sin(x*pi))
local function hpfSaw(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = x-(0.635*math.sin(x*math.pi))
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- sin(x*pi)
local function shape(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1))
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end

local function shapeReverse(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end

local function shapeDouble(minValue, maxValue, numSteps, shapeFunc)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = 2 * (changePerStep * (i-1))
    local value = math[shapeFunc](x * math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  if shapeFunc == 'sin' or shapeFunc == 'tan' then
    shape[#shape] = shape[1]
  else
    shape[#shape] = maxValue
  end
  return shape
end

-- Saw in phase x < 0 ? -1-x : 1-x
local function sawInPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = signA(x)-x
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- SquareTri -1*(sign(x)*0.5)+(abs(x)-0.5)
local function squareTri(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = -1*(signA(x)*0.5)+(math.abs(x)-0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

-- rint = round to nearest integer
--(rint(16*abs(x))/8.0)-1
local function lofiTriangle(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = (round(16*math.abs(x))/8.0)-1
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function doubleSaw(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = (x*2)+signB(x)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function dome50(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = -1-1.275*math.sin(x*math.pi)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function sawAnalog(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1))
    local value = 2.001 * (math.sin(x * 0.7905) - 0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function dome(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - .0
    local value = 2 * (math.sin(x * 1.5705) - 0.5)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function triangleInPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.min(2+2*x, math.abs((x-0.5)*2)-1)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function triangleOffPhase(minValue, maxValue, numSteps)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(2, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) - 1
    local value = math.abs(x*2)-1
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function triangleOffPhaseReverse(minValue, maxValue, numSteps)
  local rising = true
  local numStepsUpDown = math.floor(numSteps / 2)
  local valueRange = maxValue - minValue
  local changePerStep = getChangePerStep(valueRange, numStepsUpDown)
  local startValue = minValue
  local shape = {}
  for i=1,numSteps do
    table.insert(shape, startValue)
    if rising then
      startValue = startValue + changePerStep
      if startValue >= maxValue then
        rising = false
      end
    else
      startValue = startValue - changePerStep
    end
  end
  shape[#shape] = minValue
  return shape
end

local function ramp(minValue, maxValue, numSteps, f)
  local unipolar = minValue == 0
  local changePerStep = getChangePerStep(1, numSteps)
  local shape = {}
  for i=1,numSteps do
    local x = (changePerStep * (i-1)) + f
    local value = math.min(2+2*x, math.abs((x-0.5)*2)-1)
    if unipolar then
      value = ((maxValue * value) + maxValue) / 2
    else
      value = maxValue * value
    end
    print("step, value", i, value)
    table.insert(shape, value)
  end
  return shape
end

local function rampUp(minValue, maxValue, numSteps)
  return ramp(minValue, maxValue, numSteps, .5)
end

local function rampDown(minValue, maxValue, numSteps)
  return ramp(minValue, maxValue, numSteps, -.5)
end

local gem = {
  inc = inc,
  round = round,
  shape = shape,
  shapeReverse = shapeReverse,
  shapeDouble = shapeDouble,
  dome = dome,
  dome50 = dome50,
  hpfSaw = hpfSaw,
  sawAnalog = sawAnalog,
  sawInPhase = sawInPhase,
  doubleSaw = doubleSaw,
  filteredSquare = filteredSquare,
  organIsh = organIsh,
  rampUp = rampUp,
  rampDown = rampDown,
  squareTri = squareTri,
  triangle = triangleOffPhaseReverse,
  lofiTriangle = lofiTriangle,
  triangleInPhase = triangleInPhase,
  triangleOffPhase = triangleOffPhase,
  triangleOffPhaseReverse = triangleOffPhaseReverse,
  testShape = testShape,
  sweetSine = sweetSine,
  softSine = softSine,
  drop = drop,
  tripleSin = tripleSin,
  getRandom = getRandom,
  getChangeMax = getChangeMax,
  tableIncludes = tableIncludes,
  randomizeValue = randomizeValue,
  trimStartAndEnd = trimStartAndEnd,
  getRandomBoolean = getRandomBoolean,
  getIndexFromValue = getIndexFromValue,
  getRandomFromTable = getRandomFromTable,
}

--------------------------------------------------------------------------------
-- Functions for creating an positioning widgets
--------------------------------------------------------------------------------

local panelNameIndex = 1
local widgetNameIndex = 1
local currentX = 0
local currentY = 0

local widgetDefaults = {
  panel = Panel("DefaultPanel"),
  width = 120,
  height = 20,
  menuHeight = 45,
  xOffset = 0,
  yOffset = 0,
  xSpacing = 0,
  ySpacing = 0,
  col = 0,
  row = 0,
  cols = 6
}

local widgetColours = {
  backgroundColour = "202020",
  widgetBackgroundColour = "01011F", -- Dark
  menuBackgroundColour = "01011F", -- widgetBackgroundColour
  widgetTextColour = "9f02ACFE", -- Light
  tableBackgroundColour = "191E25",
  sliderColour = "5FB5FF", -- Table slider colour
  labelTextColour = "black", -- Light
  labelBackgroundColour = "CFFFFE",
  menuArrowColour = "66AEFEFF", -- labelTextColour
  menuOutlineColour = "5f9f02ACFE", -- widgetTextColour
  menuTextColour = "9f02ACFE",
  backgroundColourOff = "ff084486",
  backgroundColourOn = "ff02ACFE",
  textColourOff = "ff22FFFF",
  textColourOn = "efFFFFFF",
}

local function getValueOrDefault(value, default)
  if type(value) == "nil" then
    return default
  end
  return value
end

local function setColours(colours)
  widgetColours.backgroundColour = getValueOrDefault(colours.backgroundColour, widgetColours.backgroundColour)
  widgetColours.widgetBackgroundColour = getValueOrDefault(colours.widgetBackgroundColour, widgetColours.widgetBackgroundColour)
  widgetColours.menuBackgroundColour = getValueOrDefault(colours.menuBackgroundColour, widgetColours.menuBackgroundColour)
  widgetColours.widgetTextColour = getValueOrDefault(colours.widgetTextColour, widgetColours.widgetTextColour)
  widgetColours.tableBackgroundColour = getValueOrDefault(colours.tableBackgroundColour, widgetColours.tableBackgroundColour)
  widgetColours.sliderColour = getValueOrDefault(colours.sliderColour, widgetColours.sliderColour)
  widgetColours.labelTextColour = getValueOrDefault(colours.labelTextColour, widgetColours.labelTextColour)
  widgetColours.labelBackgroundColour = getValueOrDefault(colours.labelBackgroundColour, widgetColours.labelBackgroundColour)
  widgetColours.menuArrowColour = getValueOrDefault(colours.menuArrowColour, widgetColours.menuArrowColour)
  widgetColours.menuOutlineColour = getValueOrDefault(colours.menuOutlineColour, widgetColours.menuOutlineColour)
  widgetColours.menuTextColour = getValueOrDefault(colours.menuTextColour, widgetColours.menuTextColour)
  widgetColours.backgroundColourOff = getValueOrDefault(colours.backgroundColourOff, widgetColours.backgroundColourOff)
  widgetColours.backgroundColourOn = getValueOrDefault(colours.backgroundColourOn, widgetColours.backgroundColourOn)
  widgetColours.textColourOff = getValueOrDefault(colours.textColourOff, widgetColours.textColourOff)
  widgetColours.textColourOn = getValueOrDefault(colours.textColourOn, widgetColours.textColourOn)
end

local function setSection(settings)
  if type(settings) ~= "table" then
    settings = {}
  end
  widgetDefaults.width = getValueOrDefault(settings.width, widgetDefaults.width)
  widgetDefaults.height = getValueOrDefault(settings.height, widgetDefaults.height)
  widgetDefaults.menuHeight = getValueOrDefault(settings.menuHeight, widgetDefaults.menuHeight)
  widgetDefaults.xOffset = getValueOrDefault(settings.xOffset, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.yOffset, widgetDefaults.yOffset)
  widgetDefaults.xOffset = getValueOrDefault(settings.x, widgetDefaults.xOffset)
  widgetDefaults.yOffset = getValueOrDefault(settings.y, widgetDefaults.yOffset)
  widgetDefaults.xSpacing = getValueOrDefault(settings.xSpacing, widgetDefaults.xSpacing)
  widgetDefaults.ySpacing = getValueOrDefault(settings.ySpacing, widgetDefaults.ySpacing)
  widgetDefaults.cols = getValueOrDefault(settings.cols, widgetDefaults.cols)
  widgetDefaults.col = getValueOrDefault(settings.col, 0)
  widgetDefaults.row = getValueOrDefault(settings.row, 0)
  setColours(settings)
  currentX = widgetDefaults.xOffset
  currentY = widgetDefaults.yOffset
end

local function getWidgetName(name, displayName, useDisplayNameAsWidgetName, panel)
  if panel then
    name = getValueOrDefault(name, "Panel" .. panelNameIndex)
    panelNameIndex = panelNameIndex + 1
  elseif type(name) == "nil" then
    name = ""
    if useDisplayNameAsWidgetName and type(displayName) == "string" then
      name = string.gsub(displayName, "[^a-zA-Z]+", "")
    end
    if string.len(name) == 0 then
      name = "Widget" .. widgetNameIndex
      widgetNameIndex = widgetNameIndex + 1
    end
  end
  print("Widget name", name)
  return name
end

local function incrementRow(row, h)
  if type(row) == "nil" then
    row = 1
  end
  if type(h) == "nil" then
    h = widgetDefaults.height
  end
  widgetDefaults.row = widgetDefaults.row + row
  widgetDefaults.col = 0
  currentX = widgetDefaults.xOffset

  local height = math.max(1, row) * h
  local ySpacing = math.max(1, row) * widgetDefaults.ySpacing
  currentY = currentY + height + ySpacing
end

local function incrementCol(col, w, h)
  if type(col) == "nil" then
    col = 1
  end
  if type(w) == "nil" then
    w = widgetDefaults.width
  end

  local width = math.max(1, col) * w
  local xSpacing = math.max(1, col) * widgetDefaults.xSpacing
  currentX = currentX + width + xSpacing

  widgetDefaults.col = widgetDefaults.col + col
  if widgetDefaults.col >= widgetDefaults.cols then
    incrementRow(1, h)
  end
end

local function getWidgetBounds(options, increment)
  local x = getValueOrDefault(options.x, currentX)
  local y = getValueOrDefault(options.y, currentY)
  local w = getValueOrDefault(options.width, widgetDefaults.width)
  local h = getValueOrDefault(options.height, widgetDefaults.height)

  if type(options.y) == "number" then
    print("options.y, y", options.y, y)
  end

  if type(options.x) == "number" then
    print("options.x, x", options.x, x)
  end

  -- Increment position
  if increment then
    if type(options.increment) == "boolean" then
      if options.increment then
        options.increment = 1
      else
        options.increment = 0
      end
    end
    local i = getValueOrDefault(options.increment, 1)
    incrementCol(i, w, h)
  end

  return {x, y, w, h}
end

local function getWidgetOptions(options, displayName, default, panel)
  if type(options) ~= "table" then
    options = {}
  end
  options.default = getValueOrDefault(default, options.default)
  options.name = getWidgetName(options.name, displayName, type(default) ~= "nil", panel)
  options.displayName = getValueOrDefault(displayName, options.name)
  options.tooltip = getValueOrDefault(options.tooltip, options.displayName)
  options.integer = getValueOrDefault(options.integer, (options.unit == Unit.Percent or options.unit == Unit.MidiKey))
  options.min = getValueOrDefault(options.min, 0)
  options.default = getValueOrDefault(options.default, options.min)
  if options.unit == Unit.MidiKey then
    options.max = getValueOrDefault(options.max, 127)
  elseif options.unit == Unit.Percent then
    options.max = getValueOrDefault(options.max, 100)
  else
    options.max = getValueOrDefault(options.max, 1)
  end
  return options
end

local function setOptional(widget, options)
  if type(options.changed) == "function" then
    widget.changed = options.changed
  end
  if type(options.alpha) == "number" then
    widget.alpha = options.alpha
  end
  if type(options.fontSize) == "number" then
    widget.fontSize = options.fontSize
  end
  if type(options.unit) == "number" then
    widget.unit = options.unit
  end
  if type(options.showLabel) == "boolean" then
    widget.showLabel = options.showLabel
  end
  if type(options.persistent) == "boolean" then
    widget.persistent = options.persistent
  end
  if type(options.enabled) == "boolean" then
    widget.enabled = options.enabled
  end
  if type(options.showPopupDisplay) == "boolean" then
    widget.showPopupDisplay = options.showPopupDisplay
  end
  if type(options.editable) == "boolean" then
    widget.editable = options.editable
  end
  if type(options.visible) == "boolean" then
    widget.visible = options.visible
  end
  if type(options.backgroundColour) == "string" then
    widget.backgroundColour = options.backgroundColour
  end
  if type(options.fillStyle) == "string" then
    widget.fillStyle = options.fillStyle
  end
  if type(options.sliderColour) == "string" then
    widget.sliderColour = options.sliderColour
  end
  if type(options.backgroundColourWhenEditing) == "string" then
    widget.backgroundColourWhenEditing = options.backgroundColourWhenEditing
  end
  if type(options.textColourWhenEditing) == "string" then
    widget.textColourWhenEditing = options.textColourWhenEditing
  end
  if type(options.textColour) == "string" then
    widget.textColour = options.textColour
  end
  if type(options.backgroundColourOff) == "string" then
    widget.backgroundColourOff = options.backgroundColourOff
  end
  if type(options.backgroundColourOn) == "string" then
    widget.backgroundColourOn = options.backgroundColourOn
  end
  if type(options.textColourOff) == "string" then
    widget.textColourOff = options.textColourOff
  end
  if type(options.textColourOn) == "string" then
    widget.textColourOn = options.textColourOn
  end
end

local widgets = {
  setColours = setColours,
  setSection = setSection,
  channels = function()
    local channels = {"Omni"}
    for j=1,16 do
      table.insert(channels, "" .. j)
    end
    return channels
  end,
  getColours = function() return widgetColours end,
  getPanel = function(options) return widgetDefaults.panel end,
  xOffset = function(val) widgetDefaults.xOffset = val end,
  yOffset = function(val) widgetDefaults.yOffset = val end,
  xSpacing = function(val) widgetDefaults.xSpacing = val end,
  ySpacing = function(val) widgetDefaults.ySpacing = val end,
  posSide = function(widget) return widget.x + widget.width + widgetDefaults.xSpacing end,
  posUnder = function(widget) return widget.y + widget.height + widgetDefaults.ySpacing end,
  width = function(val) widgetDefaults.width = val end,
  height = function(val) widgetDefaults.height = val end,
  col = function(i) incrementCol(i) end,
  row = function(i) incrementRow(i) end,
  panel = function(options)
    -- The first time, we use the default panel
    local create = panelNameIndex > 1
    if create == false then
      options.name = widgetDefaults.panel.name
    end
    options = getWidgetOptions(options, nil, nil, true)
    if create then
      widgetDefaults.panel = Panel(options.name)
      --print("Created panel", options.name)
    end
    widgetDefaults.panel.backgroundColour = widgetColours.backgroundColour
    widgetDefaults.panel.bounds = getWidgetBounds(options, false)
    setOptional(widgetDefaults.panel, options)
    return widgetDefaults.panel
  end,
  button = function(displayName, default, options)
    local isOnOff = true
    if type(default) == "table" then
      options = default
      default = nil
      isOnOff = false
    end
    options = getWidgetOptions(options, displayName, default)
    local widget
    if isOnOff then
      widget = widgetDefaults.panel:OnOffButton(options.name, (options.default == true))
    else
      widget = widgetDefaults.panel:Button(options.name)
    end
    widget.backgroundColourOff = widgetColours.backgroundColourOff
    widget.backgroundColourOn = widgetColours.backgroundColourOn
    widget.textColourOff = widgetColours.textColourOff
    widget.textColourOn = widgetColours.textColourOn
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  label = function(displayName, options)
    options = getWidgetOptions(options, displayName)
    local widget = widgetDefaults.panel:Label("Label")
    widget.text = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.labelBackgroundColour
    widget.textColour = widgetColours.labelTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  menu = function(displayName, default, items, options)
    if type(default) == "table" then
      options = items
      items = default
      default = 1
    end
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Menu(options.name, items)
    widget.selected = options.default
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.menuBackgroundColour
    widget.textColour = widgetColours.menuTextColour
    widget.arrowColour = widgetColours.menuArrowColour
    widget.outlineColour = widgetColours.menuOutlineColour
    setOptional(widget, options)
    if widget.showLabel == true then
      options.height = getValueOrDefault(options.height, widgetDefaults.menuHeight)
    end
    widget.bounds = getWidgetBounds(options, true)
    return widget
  end,
  numBox = function(displayName, default, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:NumBox(options.name, options.default, options.min, options.max, options.integer)
    widget.displayName = options.displayName
    widget.tooltip = options.tooltip
    widget.backgroundColour = widgetColours.widgetBackgroundColour
    widget.textColour = widgetColours.widgetTextColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
  table = function(displayName, default, size, options)
    options = getWidgetOptions(options, displayName, default)
    local widget = widgetDefaults.panel:Table(options.name, size, options.default, options.min, options.max, options.integer)
    widget.fillStyle = "solid"
    widget.backgroundColour = widgetColours.tableBackgroundColour
    widget.sliderColour = widgetColours.sliderColour
    widget.bounds = getWidgetBounds(options, true)
    setOptional(widget, options)
    return widget
  end,
}

--------------------------------------------------------------------------------
-- Common Resolutions
--------------------------------------------------------------------------------

local function getDotted(value)
  return value * 1.5
end

local function getTriplet(value)
  return value / 3
end

-- NOTE: Make sure resolutionValues and resolutionNames are in sync
local resolutionValues = {
  128, -- "32x" -- 1
  64, -- "16x" -- 2
  32, -- "8x" -- 3
  28, -- "7x" -- 4
  24, -- "6x" -- 5
  20, -- "5x" -- 6
  16, -- "4x" -- 7
  12, -- "3x" -- 8
  8, -- "2x" -- 9
  6, -- "1/1 dot" -- 10
  4, -- "1/1" -- 11
  3, -- "1/2 dot" -- 12
  getTriplet(8), -- "1/1 tri" -- 13
  2, -- "1/2" -- 14
  getDotted(1), -- "1/4 dot", -- 15
  getTriplet(4), -- "1/2 tri", -- 16
  1, -- "1/4", -- 17
  getDotted(0.5), -- "1/8 dot", -- 18
  getTriplet(2), -- "1/4 tri", -- 19
  0.5,  -- "1/8", -- 20
  getDotted(0.25), -- "1/16 dot", -- 21
  getTriplet(1), -- "1/8 tri", -- 22
  0.25, -- "1/16", -- 23
  getDotted(0.125), -- "1/32 dot", -- 24
  getTriplet(0.5), -- "1/16 tri", -- 25
  0.125, -- "1/32" -- 26
  getDotted(0.0625), -- "1/64 dot", -- 27
  getTriplet(0.25), -- "1/32 tri", -- 28
  0.0625, -- "1/64", -- 29
  getDotted(0.03125), -- "1/128 dot" -- 30
  getTriplet(0.125), -- "1/64 tri" -- 31
  0.03125 -- "1/128" -- 32
}

local resolutionNames = {
  "32x", -- 1
  "16x", -- 2
  "8x", -- 3
  "7x", -- 4
  "6x", -- 5
  "5x", -- 6
  "4x", -- 7
  "3x", -- 8
  "2x", -- 9
  "1/1 dot", -- 10
  "1/1", -- 11
  "1/2 dot", -- 12
  "1/1 tri", -- 13
  "1/2", -- 14
  "1/4 dot", -- 15
  "1/2 tri", -- 16
  "1/4", -- 17
  "1/8 dot", -- 18
  "1/4 tri", -- 19
  "1/8", -- 20
  "1/16 dot", -- 21
  "1/8 tri", -- 22
  "1/16", -- 23
  "1/32 dot", -- 24
  "1/16 tri", -- 25
  "1/32", -- 26
  "1/64 dot", -- 27
  "1/32 tri", -- 28
  "1/64", -- 29
  "1/128 dot", -- 30
  "1/64 tri", -- 31
  "1/128" -- 32
}

-- Quantize the given beat to the closest recognized resolution value
local function quantizeToClosest(beat)
  for i,v in ipairs(resolutionValues) do
    local currentValue = v
    local nextValue = resolutionValues[i+1]
    if beat == currentValue or type(nextValue) == "nil" then
      return currentValue
    end
    if beat < currentValue and beat > nextValue then
      local diffCurrent = currentValue - beat
      local diffNext = beat - nextValue
      if diffCurrent < diffNext then
        return currentValue
      else
        return nextValue
      end
    end
  end
  return resolutionValues[#resolutionValues]
end

local resolutions = {
  quantizeToClosest = quantizeToClosest,

  getDotted = getDotted,

  getTriplet = getTriplet,

  getEvenFromDotted = function(value)
    return value / 1.5
  end,
  
  getEvenFromTriplet = function(value)
    return value * 3
  end,
  
  getResolution = function(i)
    return resolutionValues[i]
  end,
  
  getResolutions = function()
    return resolutionValues
  end,
  
  getResolutionName = function(i)
    return resolutionNames[i]
  end,
  
  getResolutionNames = function(options, max)
    if type(max) ~= "number" then
      max = #resolutionNames
    end
  
    local res = {}
  
    for _,r in ipairs(resolutionNames) do
      table.insert(res, r)
      if i == max then
        break
      end
    end
  
    -- Add any options
    if type(options) == "table" then
      for _,o in ipairs(options) do
        table.insert(res, o)
      end
    end
  
    return res
  end,
  
  getResolutionsByType = function(maxResolutionIndex)
    if type(maxResolutionIndex) == "nil" then
      maxResolutionIndex = #resolutionValues
    end
    local startPosIndex = 11
    local resOptions = {}
    -- Create table of resolution indexes by type (1=even,2=dot,3=tri)
    for i=startPosIndex,startPosIndex+2 do
      local resolutionIndex = i
      local resolutionsOfType = {}
      while resolutionIndex <= maxResolutionIndex do
        table.insert(resolutionsOfType, resolutionIndex) -- insert current index in resolution options table
        --print("Insert resolutionIndex", resolutionIndex)
        resolutionIndex = resolutionIndex + 3 -- increment index
      end
      --print("#resolutionsOfType, i", #resolutionsOfType, i)
      table.insert(resOptions, resolutionsOfType)
    end
    -- Add the resolutions that are whole numbers (1,2,3,4...)
    local slowResolutions = {}
    for i,resolution in ipairs(resolutionValues) do
      if resolution % 1 == 0 then
        table.insert(slowResolutions, i)
        --print("getResolutionsByType - included slow resolution", resolution)
      end
    end
    --print("#slowResolutions", #slowResolutions)
    table.insert(resOptions, slowResolutions) -- Add the "slow" x resolutions
    --print("resOptions", #resOptions)
    return resOptions
  end,
  
  getPlayDuration = function(duration, gate)
    if type(gate) == "nil" then
      gate = 100
    end
    local maxResolution = resolutionValues[#resolutionValues]
    return math.max(maxResolution, duration * (gate / 100)) -- Never shorter than the system max resolution
  end  
}

----------------------------------------------
-- A random gate for incoming note events
----------------------------------------------

local isRunning = false

local backgroundColour = "595959" -- Light or Dark
local widgetBackgroundColour = "black" -- Dark
local widgetTextColour = "3EC1D3" -- Light
local knobFillColour = "E6D5B8" -- Light
local labelTextColour = widgetBackgroundColour
local labelBackgoundColour = widgetTextColour
local menuBackgroundColour = "01011F"
local menuArrowColour = "66" .. labelTextColour
local menuOutlineColour = "5f" .. widgetTextColour

setBackgroundColour(backgroundColour)

local panel = widgets.panel({
  backgroundColour = backgroundColour,
  x = 10,
  y = 10,
  width = 700,
  height = 60,
})

local label = panel:Label("Label")
label.text = "Note Event Gate"
label.tooltip = "When the gate is closed, all note on events are stopped."
label.alpha = 0.5
label.backgroundColour = labelBackgoundColour
label.textColour = labelTextColour
label.width = 140
label.fontSize = 22

local probability = panel:Knob("Probability", 50, 0, 100, true)
probability.unit = Unit.Percent
probability.displayName = "Probability"
probability.tooltip = "Set the probability that the gate will open or close"
probability.backgroundColour = widgetBackgroundColour
probability.fillColour = knobFillColour
probability.outlineColour = labelBackgoundColour
probability.x = label.x + label.width + 30
probability.width = 120

local waitResolution = panel:Menu("WaitResolution", resolutions.getResolutionNames())
waitResolution.displayName = "Open Duration"
waitResolution.tooltip = "The duration of open gate"
waitResolution.selected = 11
waitResolution.width = 120
waitResolution.x = probability.x + probability.width + 10
waitResolution.backgroundColour = menuBackgroundColour
waitResolution.textColour = widgetTextColour
waitResolution.arrowColour = menuArrowColour
waitResolution.outlineColour = menuOutlineColour

local waitResolutionClosed = panel:Menu("WaitResolutionClosed", resolutions.getResolutionNames())
waitResolutionClosed.displayName = "Closed Duration"
waitResolutionClosed.tooltip = "The duration closed gate"
waitResolutionClosed.selected = 11
waitResolutionClosed.width = 120
waitResolutionClosed.x = waitResolution.x + waitResolution.width + 10
waitResolutionClosed.backgroundColour = menuBackgroundColour
waitResolutionClosed.textColour = widgetTextColour
waitResolutionClosed.arrowColour = menuArrowColour
waitResolutionClosed.outlineColour = menuOutlineColour

local gateButton = panel:OnOffButton("GateButton", true)
gateButton.displayName = "On"
gateButton.persistent = false
gateButton.tooltip = "Shows the current state of the gate"
gateButton.backgroundColourOn = "green"
gateButton.backgroundColourOff = "303030"
gateButton.textColourOn = "white"
gateButton.textColourOff = "gray"
gateButton.size = {90,20}
gateButton.x = panel.width - 100
gateButton.y = 30
gateButton.changed = function(self)
  if self.value == true then
    gateButton.displayName = "On"
  else
    gateButton.displayName = "Off"
  end
end

function arpeg()
  local round = 0
  local waitTime = 0
  while isRunning do
    round = round + 1 -- Increment round
    if gem.getRandomBoolean(probability.value) then
      gateButton:setValue(gateButton.value == false)
    end
    if gateButton.value == true then
      waitTime = beat2ms(resolutions.getResolution(waitResolution.value))
    else
      waitTime = beat2ms(resolutions.getResolution(waitResolutionClosed.value))
    end
    if round == 1 then
      waitTime = waitTime - 50
    end
    wait(waitTime)
  end
end

function onNote(e)
  if gateButton.value == true then
    postEvent(e)
  end
end

function onTransport(start)
  isRunning = start
  if isRunning then
    arpeg()
  elseif probability.value > 0 then
    gateButton:setValue(true)
  end
end
