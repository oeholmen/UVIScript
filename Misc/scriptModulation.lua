function SetupKnobSizeDefalut( knob )
	knob.height = 32
end

local panelNoteCfg = Panel("NoteConfig")
panelNoteCfg.bounds = { 4, 4, 700, 40 }
local chkNoteNum_     = panelNoteCfg:OnOffButton("NoteNum", false)
local knobTargetNote_ = panelNoteCfg:Knob("Note", 36, 0, 127, true)
local knobAccentThr_  = panelNoteCfg:Knob("AccentThr", 100, 0, 127, true)

local panelModCfg     = Panel("ModulationConfig")
panelModCfg.bounds = { 4, 48, 700, 40 }
local knobEventID_    = panelModCfg:Knob("EventID", 1, 0, 127, true)
local knobNormalMod_  = panelModCfg:Knob("ModNml", 0.0, -1.0, 1.0, false)
local knobRampTimeN_  = panelModCfg:Knob("RampNml", 0.0, 0.0, 2000, false)
local knobAccentMod_  = panelModCfg:Knob("ModAct", 0.5, -1.0, 1.0, false)
local knobRampTimeA_  = panelModCfg:Knob("RampAct", 0.0, 0.0, 2000, false)

SetupKnobSizeDefalut( knobTargetNote_ )
SetupKnobSizeDefalut( knobAccentThr_ )
SetupKnobSizeDefalut( knobEventID_ )
SetupKnobSizeDefalut( knobNormalMod_ )
SetupKnobSizeDefalut( knobAccentMod_ )
SetupKnobSizeDefalut( knobRampTimeN_ )
SetupKnobSizeDefalut( knobRampTimeA_ )

function onNote(e)
	local voiceID = postEvent(e)
	-- Modulation Value
	local targetValue = 0
	local rampTime = 0
	if ( knobAccentThr_.value < e.velocity ) then
		targetValue = knobAccentMod_.value
		rampTime = knobRampTimeA_.value
	else
		targetValue = knobNormalMod_.value
		rampTime = knobRampTimeN_.value
	end
	-- Send Modulation Value
	if ( chkNoteNum_.value ) then
		if ( e.note ~= knobTargetNote_.value ) then
			return
		end
	end
	sendScriptModulation(knobEventID_.value, targetValue, rampTime, voiceID)
end
