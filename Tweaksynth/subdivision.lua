--------------------------------------------------------------------------------
-- Methods for subdivisions
--------------------------------------------------------------------------------

require "common"

function setNotesOnNodes(nodes, repeatProbability, generateNote)
  for i,node in ipairs(nodes) do
    -- This is where we add the notes to the node
    if i > 1 and getRandomBoolean(repeatProbability) then
      node.note = nodes[1].note -- Repeat first note
      print("Note repeated", node.note)
    else
      node.note = generateNote(i)
      print("Note generated", node.note)
    end
  end
  return nodes
end

-- Get the subdivision to use for building the struncture
function getSubdivision(stepDuration, steps, minResolution, subdivisionProbability, subdivisionButtons, stop, subdivisionDotProbability)
  -- Calculate depth decay
  -- TODO If decay, there should be a setting for it...
  --[[ if currentDepth > 1 then
    subdivisionProbability = math.ceil(subdivisionProbability / (currentDepth / 2)) -- TODO Adjust
    print("subdivisionProbability/currentDepth", subdivisionProbability, currentDepth)
  end ]]
  local subdivision = 1 -- Set default

  -- TODO Add a base-1 thresold resolution that tells what is the slowest resolution where subdivision can be 1 - until then, keep on subdividing

  -- Check what subdivisions can be used with the given duration
  local subdivisions = createSubdivisions(subdivisionButtons, stepDuration, minResolution, steps)
  local maxSubdivision = subdivisions[#subdivisions]
  print("Got maxSubdivision/#subdivisions/subdivisionProbability", maxSubdivision, #subdivisions, subdivisionProbability)
  if #subdivisions > 0 then
    subdivision = subdivisions[1] -- First is default
    if #subdivisions > 1 and getRandomBoolean(subdivisionProbability) then
      local i = 1
      while i < maxSubdivision do
        subdivision = subdivisions[getRandom(#subdivisions)]
        if subdivision > 1 then
          break
        end
        print("SET RANDOM subdivision/round", subdivision, i)
        i = i + 1
      end
    end
  end

  local dotted = false -- Set default
  local fullDuration = stepDuration * steps
  local subDivDuration = fullDuration / subdivision
  local remainderDuration = subDivDuration -- Default remainderDuration is the full subdivision duration
  if subDivDuration < minResolution or stop == true then
    subdivision = 1
    print("The minimum resolution or stop was reached - no further subdivisions are made subDivDuration/minResolution/stop", subDivDuration, minResolution, stop)
  end

  if subdivision > 1 then
    dotted = subdivision % 4 == 0 and getRandomBoolean(subdivisionDotProbability)
    print("Dotted is dotted/subdivision/subdivisionDotProbability", dotted, subdivision, subdivisionDotProbability)
    if dotted == true then
      stop = true -- TODO Param?
      subDivDuration = getDotted(subDivDuration)
      remainderDuration = fullDuration % subDivDuration -- Adjust remainder duration
      subdivision = math.ceil(fullDuration / subDivDuration) -- Adjust subdivision
      print("Dotted subdivision/duration/fullDuration/remainderDuration", subdivision, subDivDuration, fullDuration, remainderDuration)
      if remainderDuration < minResolution then
        remainderDuration = remainderDuration + subDivDuration
        subdivision = subdivision - 1 -- Adjust subdivision
        print("Adjust to avoid remainderDuration < minResolution subdivision/duration/fullDuration/remainderDuration", subdivision, subDivDuration, fullDuration, remainderDuration)
      end
    end
  end

  return subdivision, subDivDuration, remainderDuration, stop
end

function getSubdivisionSteps(subdivision, subDivPos, subdivisionTieProbability)
  local stop = false
  local subdivisionSteps = 1 -- Default
  local maxSteps = (subdivision - subDivPos) + 1
  if maxSteps == subdivision then
    maxSteps = maxSteps - 1 -- Avoid it lasting the whole subdivision
  end
  if maxSteps > 1 and getRandomBoolean(subdivisionTieProbability) then
    subdivisionSteps = getRandom(maxSteps)
    if subdivisionSteps > 1 then
      stop = subdivisionSteps % 2 > 0 -- Stop subdividing if not an even number -- TODO Param?
      print("subdivisionSteps % 2", (subdivisionSteps % 2))
    end
    print("Set subdivisionSteps by random subdivisionSteps/maxSteps/stop", subdivisionSteps, maxSteps, stop)
  end
  return subdivisionSteps, stop
end

function createSubdivisions(subdivisionButtons, mainBeatDuration, minResolution, steps)
  local subdivisions = {}
  for i=1,#subdivisionButtons do
    if subdivisionButtons[i].value == true then
      table.insert(subdivisions, i)
      print("Added subdivision", i)
    end
  end
  -- Add subdivisions from the active bases
  local numSubdivisions = #subdivisions
  for i=1,numSubdivisions do
    subdivision = subdivisions[i]
    local duration = mainBeatDuration
    while duration > minResolution do
      subdivision = subdivision * 2
      duration = (mainBeatDuration / subdivision) * steps
      print("Found subdivision/duration/minResolution", subdivision, duration, minResolution)
      if duration >= minResolution and tableIncludes(subdivisions, subdivision) == false then
        table.insert(subdivisions, subdivision)
        print("Added subdivision", subdivision)
      end
    end
  end
  table.sort(subdivisions)
  return subdivisions
end
