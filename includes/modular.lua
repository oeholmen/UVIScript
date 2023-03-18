--------------------------------------------------------------------------------
-- Common functions for working with event processor that act as modular inputs
--------------------------------------------------------------------------------

local gem = require "includes.common"
local widgets = require "includes.widgets"

local activeVoices = {}
local channel = 0 -- 0 = Omni

local function isNoteInActiveVoices(note)
  for _,v in ipairs(activeVoices) do
    if v.note == note then
      return true
    end
  end
  return false
end

local function isTrigger(e)
  local isListeningForEvent = channel == 0 or channel == e.channel
  local isTrigger = e.note == 0 -- Note 0 is used as trigger
  print("isTrigger and isListeningForEvent, channel, e.channel", isTrigger, isListeningForEvent, channel, e.channel)
  return isTrigger and isListeningForEvent
end

local function handleTrigger(e, note, data)
  print("handleTrigger, note, isNoteInActiveVoices(note)", note, isNoteInActiveVoices(note))
  if type(note) == "number" and isNoteInActiveVoices(note) == false then
    local id = playNote(note, e.velocity, -1, nil, e.channel)
    table.insert(activeVoices, {id=id,note=note,channel=e.channel,data=data})
    return true
  end
  return false
end

local function handleReleaseTrigger(e)
  local keep = {} -- The notes to keep
  for i,v in ipairs(activeVoices) do
    if v.channel == e.channel then
      -- Release all voices on this channel
      releaseVoice(v.id)
    else
      -- Keep the voice
      table.insert(keep, v)
    end
  end
  local hasReleased = #activeVoices > #keep
  activeVoices = keep -- Update active voices
  return hasReleased
end

local function releaseActiveVoicesInModular()
  for i,v in ipairs(activeVoices) do
    releaseVoice(v.id)
  end
  activeVoices = {}
end

local function getChannelWidget(options)
  if type(options) == "nil" then
    options = {}
  end
  options.tooltip = gem.getValueOrDefault(options.tooltip, "Listen to triggers (note=0 events) on this channel - if a note event is not being listened to, it will be pass through")
  options.showLabel = gem.getValueOrDefault(options.showLabel, false)
  options.changed = gem.getValueOrDefault(options.changed, function(self)
    channel = self.value - 1
    releaseActiveVoicesInModular()
  end)

  return widgets.menu("Channel", widgets.channels(), options)
end

return {--modular--
  isTrigger = isTrigger,
  handleTrigger = handleTrigger,
  handleReleaseTrigger = handleReleaseTrigger,
  releaseVoices = releaseActiveVoicesInModular,
  getChannelWidget = getChannelWidget,
  setChannel = function(c) channel = c end,
  getChannel = function() return channel end,
  getNumVoices = function() return #activeVoices end,
  getActiveVoices = function() return activeVoices end,
}
