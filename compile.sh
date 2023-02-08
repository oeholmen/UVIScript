#!/bin/bash

# Make standalone versions of lua scripts

# Add the lua scripts to compile (NOTE: The includes are set in the loop below)
luaScripts=(
  effects/noteBouncer
  generators/beatbox
  generators/drunkenSequencer
  generators/generativeChorder
  generators/generativeStrategySequencer
  generators/gridSequencer
  generators/noteFragmentGenerator
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
)

for luaScript in "${luaScripts[@]}"; do 
  # Set the input and output files
  input_file=./"$luaScript".lua
  output_file=./compiled/"$luaScript".lua

  echo
  echo "Compiling $input_file to $output_file"

  # Remove the output file if it already exists
  if [ -f $output_file ]; then
    rm $output_file
  fi

  # NOTE: Set the correct includes for the script here
  if [ $luaScript == 'generators/beatbox' ] || [ $luaScript == 'sequencers/fragmentSequencer' ]; then
    includes=(common resolutions rythmicFragments)
  elif [ $luaScript == 'generators/drunkenSequencer' ] || [ $luaScript == 'generators/generativeStrategySequencer' ]; then
    includes=(common scales notes resolutions noteSelector rythmicFragments)
  elif [ $luaScript == 'generators/generativeChorder' ]; then
    includes=(common scales notes resolutions noteSelector)
  elif [ $luaScript == 'modulators/randomEnveloper' ]; then
    includes=(common resolutions resolutionSelector)
  elif [ $luaScript == 'modulators/randomGateModulator' ]; then
    includes=(common resolutions subdivision)
  elif [ $luaScript == 'sequencers/strategySequencer' ]; then
    includes=(common scales notes resolutions subdivision)
  elif [ $luaScript == 'util/noteLimiter' ]; then
    includes=(common notes)
  elif [ $luaScript == 'synths/tweaksynth' ] || [ $luaScript == 'sequencers/jumpingSequencer' ] || [ $luaScript == 'sequencers/polyphonicSequencer' ] || [ $luaScript == 'sequencers/stochasticDrumSequencer' ] || [ $luaScript == 'sequencers/stochasticSequencer' ] || [ $luaScript == 'util/randomGate' ] || [ $luaScript == 'modulators/bouncer' ] || [ $luaScript == 'modulators/modulationSequencer' ] || [ $luaScript == 'modulators/randomChange' ] || [ $luaScript == 'effects/noteBouncer' ]; then
    includes=(common resolutions)
  elif [ $luaScript == 'sequencers/midiControlSequencer' ]; then
    includes=(common resolutions modseq)
  elif [ $luaScript == 'generators/noteFragmentGenerator' ] || [ $luaScript == 'generators/gridSequencer' ]; then
    includes=(common scales notes resolutions rythmicFragments)
  else
    includes=(common)
  fi

  # Write all the includes to the compiled file
  for include in "${includes[@]}"; do
    echo "include $include"
    file_contents=$(cat ./includes/"$include".lua)
    file_contents=$(echo "$file_contents" | sed 's/local \(.*\) = require "includes.\(.*\)"//g')
    file_contents=$(echo "$file_contents" | sed 's/return {--\(.*\)--/local \1 = {/g')
    echo "$file_contents" >> $output_file
    echo "" >> $output_file
  done

  # Write the lua script file to the output file
  input_file=$(cat "$input_file")
  input_file=$(echo "$input_file" | sed 's/local \(.*\) = require "includes.\(.*\)"//g')

  echo "$input_file" >> $output_file
  echo "Including $luaScript"
  echo "Done!"

  if [ $luaScript == 'sequencers/stochasticDrumSequencer' ]; then
    # Create note trigger util
    input_file=$(echo "$input_file" | sed 's/local numParts = 4/local numParts = 1/g')
    input_file=$(echo "$input_file" | sed 's/local maxPages = 8/local maxPages = 1/g')
    input_file=$(echo "$input_file" | sed 's/local title = "Stochastic Drum Sequencer"/local title = "Note Trigger"/g')
    input_file=$(echo "$input_file" | sed 's/Stochastic Drum Sequencer/Note Trigger/g')
    output_file=./compiled/util/noteTrigger.lua
    echo "$input_file" > $output_file
    echo
    echo "Including $output_file"
    echo "Done!"
  fi

  echo
  echo "******"
done
