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
  modular/gridSequencerInput
  modular/motionSequencerInput
  modular/probabilityTrigger
  modular/randomNoteInput
  modular/rythmicFragmentsTrigger
  modular/rythmicMotionsTrigger
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
  sequencers/stochasticDrumSequencer
  sequencers/stochasticSequencer
  sequencers/strategySequencer
  synths/tweaksynth
  util/arpRandomizer
  util/humanizer
  util/noteLimiter
  util/noteVelocity
  util/randomGate
  util/randomOctave
  util/sieve
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
echo

##########

input_program="../Programs/Tweak Synth/Tweak Synth Analog.uvip"
output_program="./compiled/synths/programs/Tweak Synth Analog.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"
echo

##########

input_program="../Programs/Tweak Synth/Tweak Synth Analog 3 Osc.uvip"
output_program="./compiled/synths/programs/Tweak Synth Analog 3 Osc.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"
echo

##########

input_program="../Programs/Tweak Synth/Tweak Synth FM.uvip"
output_program="./compiled/synths/programs/Tweak Synth FM.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"
echo

##########

input_program="../Programs/Tweak Synth/Tweak Synth Wavetable.uvip"
output_program="./compiled/synths/programs/Tweak Synth Wavetable.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"
echo

##########

input_program="../Programs/Tweak Synth/HW Synths/Korg Minilogue.uvip"
output_program="./compiled/synths/programs/Korg Minilogue.uvip"

cp "$input_program" "$output_program"
echo "Copied $input_program to $output_program"
echo

for luaScript in "${luaScripts[@]}"; do 
  # Set the input and output files
  input_file=./"$luaScript".lua
  output_file=./compiled/"$luaScript"Compiled.lua

  echo

  echo "Compiling $input_file to $output_file"

  # NOTE: Set the correct includes for the script here
  if [ $luaScript == 'modular/rythmicFragmentsTrigger' ] || [ $luaScript == 'generators/beatbox' ] || [ $luaScript == 'sequencers/fragmentSequencer' ]; then
    includes=(common resolutions rythmicFragments)
  elif [ $luaScript == 'generators/drunkenSequencer' ] || [ $luaScript == 'generators/generativeStrategySequencer' ]; then
    includes=(common notes scales resolutions noteSelector rythmicFragments)
  elif [ $luaScript == 'generators/generativeChorder' ]; then
    includes=(common notes scales resolutions noteSelector)
  elif [ $luaScript == 'modular/randomNoteInput' ]; then
    includes=(common widgets notes scales modular noteSelector)
  elif [ $luaScript == 'modulators/randomEnveloper' ]; then
    includes=(common resolutions resolutionSelector)
  elif [ $luaScript == 'modulators/randomGateModulator' ]; then
    includes=(common resolutions subdivision)
  elif [ $luaScript == 'sequencers/strategySequencer' ]; then
    includes=(common notes scales resolutions subdivision)
  elif [ $luaScript == 'util/noteLimiter' ]; then
    includes=(common notes)
  elif [ $luaScript == 'modular/gridSequencerInput' ]; then
    includes=(common widgets scales notes modular resolutions)
  elif [ $luaScript == 'modular/motionSequencerInput' ]; then
    includes=(common widgets scales resolutions modular tableMotion)
  elif [ $luaScript == 'modular/bounceTrigger' ] || [ $luaScript == 'modular/probabilityTrigger' ] || [ $luaScript == 'modular/swarmTrigger' ] || [ $luaScript == 'synths/tweaksynth' ] || [ $luaScript == 'sequencers/jumpingSequencer' ] || [ $luaScript == 'sequencers/polyphonicSequencer' ] || [ $luaScript == 'sequencers/stochasticDrumSequencer' ] || [ $luaScript == 'sequencers/stochasticSequencer' ] || [ $luaScript == 'util/randomGate' ] || [ $luaScript == 'modulators/bouncer' ] || [ $luaScript == 'modulators/randomChange' ] || [ $luaScript == 'effects/noteBouncer' ]; then
    includes=(common widgets resolutions)
  elif [ $luaScript == 'modular/rythmicMotionsTrigger' ] ; then
    includes=(common widgets resolutions tableMotion)
  elif [ $luaScript == 'sequencers/midiControlSequencer' ] || [ $luaScript == 'modulators/modulationSequencer' ]; then
    includes=(common resolutions modseq)
  elif [ $luaScript == 'generators/motionSequencer' ]; then
    includes=(common scales resolutions rythmicFragments)
  elif [ $luaScript == 'generators/noteFragmentGenerator' ] || [ $luaScript == 'generators/gridSequencer' ]; then
    includes=(common notes scales resolutions rythmicFragments)
  else
    includes=(common)
  fi

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

  # Write the main lua script file to the output file
  input_file=$(cat "$input_file")
  input_file=$(echo "$input_file" | sed 's/local \(.*\) = require "includes.\(.*\)"//g')
  echo "$input_file" >> $output_file
  echo "Adding $luaScript"

  # Remove multiple newlines from the output file
  echo "$(cat -s "$output_file")" > $output_file

  echo "Done!"

  # Create note trigger util from stochasticDrumSequencer
  if [ $luaScript == 'sequencers/stochasticDrumSequencer' ]; then
    input_file=$(cat "$output_file")
    input_file=$(echo "$input_file" | sed 's/local numParts = 4/local numParts = 1/g')
    input_file=$(echo "$input_file" | sed 's/local maxPages = 8/local maxPages = 1/g')
    input_file=$(echo "$input_file" | sed 's/local title = "Stochastic Drum Sequencer"/local title = "Note Trigger"/g')
    input_file=$(echo "$input_file" | sed 's/Stochastic Drum Sequencer/Note Trigger/g')
    output_file=./compiled/util/noteTriggerCompiled.lua
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
