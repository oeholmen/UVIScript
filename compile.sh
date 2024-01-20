#!/bin/bash

# Make standalone versions of lua scripts and copy the necessary assets to the compiled folder

# Add the lua scripts to compile (NOTE: The includes are set in the loop below)
luaScripts=(
  effects/noteBouncer
  generators/beatbox
  generators/drunkenSequencer
  generators/generativeChorder
  generators/generativeStrategySequencer
  generators/gridSequencer
  generators/motionSequencer
  generators/noteFragmentGenerator
  modular/bounceTrigger
  modular/chorderInput
  modular/gameOfLifeInput
  modular/gameOfLifeTrigger
  modular/gridSequencerInput
  modular/horizontalMotionSequencerInput
  modular/lifeTrigger
  modular/motionSequencerInput
  modular/noteSelectInput
  modular/probabilityTrigger
  modular/pulseTrigger
  modular/randomNoteInput
  modular/rythmicFragmentsTrigger
  modular/rythmicMotionsTrigger
  modular/sequencerInput
  modular/shapeTrigger
  modular/strategyInput
  modular/swarmTrigger
  modulators/bouncer
  modulators/modulationSequencer
  modulators/randomChange
  modulators/randomEnveloper
  modulators/randomGateModulator
  sequencers/fragmentSequencer
  sequencers/jumpingSequencer
  sequencers/midiControlSequencer
  sequencers/polyphonicSequencer
  sequencers/polyphonicRecordingSequencer
  sequencers/rythmicMotionsSequencer
  sequencers/stochasticDrumSequencer
  sequencers/stochasticSequencer
  sequencers/strategySequencer
  sequencers/swarmSequencer
  synths/tweaksynth
  util/arpRandomizer
  util/blockNotes
  util/cointoss
  util/humanizer
  util/midiControl
  util/midiControlRouter
  util/noteLimiter
  util/noteVelocity
  util/pitchOffset
  util/quantizedTrigger
  util/randomGate
  util/randomOctave
  util/resolutionQuantizer
  util/scaleQuantizer
  util/simpleRecordingSequencer
  util/stripChannel
  util/sieve
  util/tempo
  util/velocityLimiter
  util/velocityRandomization
  util/velocitySequencer
)

# Copy resources
input_folder=./resources
output_folder=./compiled/resources

# Remove the resources
if [ -d $output_folder ]; then
  rm -rf $output_folder
fi

cp -r $input_folder $output_folder
echo "Copied $input_folder to $output_folder"
echo

# Copy program files

input_program="../Programs/Tweak Synth/Tweak Synth Additive.uvip"
output_program="./compiled/synths/programs/Tweak Synth Additive.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"

##########

input_program="../Programs/Tweak Synth/Tweak Synth Analog.uvip"
output_program="./compiled/synths/programs/Tweak Synth Analog.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"

##########

input_program="../Programs/Tweak Synth/Tweak Synth Analog 3 Osc.uvip"
output_program="./compiled/synths/programs/Tweak Synth Analog 3 Osc.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"

##########

input_program="../Programs/Tweak Synth/Tweak Synth Drum.uvip"
output_program="./compiled/synths/programs/Tweak Synth Drum.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"

##########

input_program="../Programs/Tweak Synth/Tweak Synth FM.uvip"
output_program="./compiled/synths/programs/Tweak Synth FM.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"

##########

input_program="../Programs/Tweak Synth/Tweak Synth Wavetable.uvip"
output_program="./compiled/synths/programs/Tweak Synth Wavetable.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"

##########

input_program="../Programs/Tweak Synth/HW Synths/Korg Minilogue.uvip"
output_program="./compiled/synths/programs/Korg Minilogue.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"

for luaScript in "${luaScripts[@]}"; do 
  # Set the input and output files
  input_file=./"$luaScript".lua
  output_file=./compiled/"$luaScript"Compiled.lua

  echo

  echo "Compiling $input_file to $output_file"

  # Read input file content
  input_file=$(cat "$input_file")

  # Find the required includes - common is always included
  includes=(common)

  availableIncludes=(widgets modular scales notes shapes noteSelector resolutions modseq tableMotion rythmicFragments subdivision resolutionSelector)

  # Search for includes in the script
  for include in "${availableIncludes[@]}"; do
    search_include="local $include = require \"includes.$include\""
    if [[ "$input_file" == *"$search_include"* ]]; then
      includes+=($include)
    fi
  done

  # Write all the includes to the compiled file
  echo "-- $luaScript -- " > $output_file
  for include in "${includes[@]}"; do
    echo "Adding includes/$include"
    file_contents=$(cat ./includes/"$include".lua)
    file_contents=$(echo "$file_contents" | sed 's/local \(.*\) = require "includes.\(.*\)"//g')
    file_contents=$(echo "$file_contents" | sed 's/return {--\(.*\)--/local \1 = {/g')
    echo "$file_contents" >> $output_file
    echo "" >> $output_file
  done

  # Remove includes and write the main lua script file to the output file
  input_file=$(echo "$input_file" | sed 's/local \(.*\) = require "includes.\(.*\)"//g')
  echo "$input_file" >> $output_file
  echo "Adding $luaScript"

  # Remove multiple newlines from the output file
  echo "$(cat -s "$output_file")" > $output_file

  echo "Done!"

  if [ $luaScript == 'sequencers/stochasticDrumSequencer' ]; then
    # Create note trigger util from stochasticDrumSequencer
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local numParts = 4/local numParts = 1/g')
    input_file=$(echo "$input_file" | sed 's/local maxPages = 8/local maxPages = 1/g')
    input_file=$(echo "$input_file" | sed 's/local title = "Stochastic Drum Sequencer"/local title = "Note Trigger"/g')
    input_file=$(echo "$input_file" | sed 's/Stochastic Drum Sequencer/Note Trigger/g')
    trigger_file=./compiled/util/noteTriggerCompiled.lua
    echo "$input_file" > $trigger_file
    echo
    echo "Compiling $luaScript to $trigger_file"
    echo "Done!"

    # Create modular trigger from stochasticDrumSequencer
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local numParts = 4/local numParts = 1/g')
    input_file=$(echo "$input_file" | sed 's/local isModularTrigger = false/local isModularTrigger = true/g')
    input_file=$(echo "$input_file" | sed 's/Stochastic Drum Sequencer/Sequence Trigger/g')
    trigger_file=./compiled/modular/sequenceTriggerCompiled.lua
    echo "$input_file" > $trigger_file
    echo
    echo "Compiling $luaScript to $trigger_file"
    echo "Done!"

    # Create multipart modular trigger from stochasticDrumSequencer
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local isModularTrigger = false/local isModularTrigger = true/g')
    input_file=$(echo "$input_file" | sed 's/Stochastic Drum Sequencer/Multipart Sequence Trigger/g')
    trigger_file=./compiled/modular/multiSequenceTriggerCompiled.lua
    echo "$input_file" > $trigger_file
    echo
    echo "Compiling $luaScript to $trigger_file"
    echo "Done!"
  fi

  # Create monophonic sequencer from polyphonicRecordingSequencer
  if [ $luaScript == 'sequencers/polyphonicRecordingSequencer' ]; then
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local numParts = 4/local numParts = 1/g')
    output_file=./compiled/sequencers/monophonicRecordingSequencerCompiled.lua
    echo "$input_file" > $output_file
    echo
    echo "Compiling $luaScript to $output_file"
    echo "Done!"
  fi

  # Create eight part from rythmicFragmentsTrigger
  if [ $luaScript == 'modular/rythmicFragmentsTrigger' ]; then
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local maxVoices = 4/local maxVoices = 8/g')
    output_file=./compiled/modular/rythmicFragmentsTriggerEightPartCompiled.lua
    echo "$input_file" > $output_file
    echo
    echo "Compiling $luaScript to $output_file"
    echo "Done!"
  fi

  # Create eight and sixteen part from midiControlRouter
  if [ $luaScript == 'util/midiControlRouter' ]; then
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local numRouters = 1/local numRouters = 8/g')
    output_file=./compiled/util/midiControlRouterEightPartCompiled.lua
    echo "$input_file" > $output_file
    echo
    echo "Compiling $luaScript to $output_file"
    echo "Done!"

    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local numRouters = 8/local numRouters = 16/g')
    output_file=./compiled/util/midiControlRouterSixteenPartCompiled.lua
    echo "$input_file" > $output_file
    echo
    echo "Compiling $luaScript to $output_file"
    echo "Done!"
  fi

  # Create eight and sixteen part from midiControl
  if [ $luaScript == 'util/midiControl' ]; then
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local numControls = 1/local numControls = 8/g')
    output_file=./compiled/util/midiControlEightPartCompiled.lua
    echo "$input_file" > $output_file
    echo
    echo "Compiling $luaScript to $output_file"
    echo "Done!"

    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local numControls = 8/local numControls = 16/g')
    output_file=./compiled/util/midiControlSixteenPartCompiled.lua
    echo "$input_file" > $output_file
    echo
    echo "Compiling $luaScript to $output_file"
    echo "Done!"
  fi

  # Create multipart midi cc sequencer file from midiControlSequencer
  if [ $luaScript == 'sequencers/midiControlSequencer' ]; then
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/numParts = 1/numParts = 4/g')
    input_file=$(echo "$input_file" | sed 's/modseq.setTitle("Midi CC Sequencer")/modseq.setTitle("Multi Midi CC Sequencer")/g')
    output_file=./compiled/sequencers/midiControlSequencerMultipartCompiled.lua
    echo "$input_file" > $output_file
    echo
    echo "Compiling $luaScript to $output_file"
    echo "Done!"
  fi

  echo
  echo "******"
done
