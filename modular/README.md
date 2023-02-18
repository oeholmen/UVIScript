# Modular

## Intro

Modular event processors are scripts that require at least one other script to function as intended. There are two types of scripts in this category:

1. Scripts that send events (triggers)
2. Scripts that recieve events (inputs)

Since there are no custom events in Falcon, the scripts use the note event to communicate. The triggers send standard note events where the note is set to 0. Channels are used for filtering what events are listened to in the inputs.

## Usage

Add a trigger first, then an input. The trigger will send rythmic pulses (using note event with note=0), and the input will respond with a note that is sent to the synth.

Some triggers can be multi-voice and send several voices on different channels.