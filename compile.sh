#!/bin/bash

# Make standalone versions of lua scripts

# Add the lua scripts to compile (NOTE: The includes are set in the loop below)
luaScripts=(
  generators/beatbox
  generators/drunkenSequencer
  generators/generativeChorder
  generators/generativeStrategySequencer
  generators/gridSequencer
  generators/noteFragmentGenerator
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
  if [ $luaScript == 'generators/beatbox' ]; then
    includes=(common resolutions rythmicFragments)
  elif [ $luaScript == 'generators/drunkenSequencer' ] || [ $luaScript == 'generators/generativeStrategySequencer' ]; then
    includes=(common scales notes resolutions noteSelector rythmicFragments)
  elif [ $luaScript == 'generators/generativeChorder' ]; then
    includes=(common scales notes resolutions noteSelector)
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
  echo
  echo "******"
done
