# Synths, sequencers, modulators and more for UVI Falcon

This repo contains lua scripts for UVI Falcon.
There are several categories represented by the different folders.

Common for a lot of the scripts are that they use chance and probaility.

There are a few scripts for creating generative music. Check out the "generators" folder.

The sequencers are a lot of fun! I recommend checking them out.
## Usage
To use these scripts, download the code (Code->Download Zip), and load the script you want to use with the default script processor in UVI Falcon.

*NOTE:* It is recommended to use the scripts in the "compiled" folder, as they do not depend on any other files.
To use scripts that are _not_ in the "compiled" folder, you must place the "includes" folder in your "Falcon/UVIScripts" folder for the includes to load correctly.
### Effects
Effects for incoming note events.
### Generators
Generators are scripts that send note events. They do not require input, but the output can be controlled by parameters in the script.
### Includes
These are scripts that contain common code, and are not meant to be used directly. They are however required for the other scripts to run.
### Misc
Just ignore. Old stuff.
### Modular
The modular event processors are similar to the generators in that they do not require input. But where the generators create both rythm and tone in one script,
the modular processors have separated rythm and note generation in separate scripts. This means that modular triggers and inputs can be combined in any way you want.
### Modulators
This folder contains scripts that can be used with the "Script event modulation" source in UVI Falcon.
### Resources
Images and other common resources for the scripts.
### Sequencers
Sequencers are scripts that receive note events, and arpeggiates and/or sequences the incoming notes. They can be put after a generator, to respond to events created by the generator, or be used as any old arpeggiator/sequencer by playing notes on the keyboard.
### Synths
There is actually just one synth that comes in differen flavors, depending on the patch it is used with. See docs in the folder. Note that this requires a program patch to work. They are included in the "compiled/synths/programs" subfolder. As a bonus, if you own a Korg Minilogue, there is hardware integration, so you can control the softsynth from the minilogue.
