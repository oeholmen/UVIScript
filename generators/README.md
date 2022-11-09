# Generators

## Intro

Common for the generators are that they do not require input. They can be triggered by pressing play on the transport, or by any incoming note. The notes and durations are created in different ways for each generator, but all of them have several ways to affect the output. A generator can be placed at the master, part, program or layer level in Falcon.

### beatbox.lua (Fragmented Beats)
The beatbox is primarily meant for use with percussive instruments to create evolving and changing rythmic patterns. But it can also be used with tonal instruments.

The beatbox has two "modes":
1. Standard mode - all eight parts (notes) play at once
1. Single note mode - only on note is played at a time, selected by chance from the note inputs

***The beatbox works by combining notes and rythmic fragments.***

A rythmic fragment is nothing more than a sequence of resolutions. The rythmic fragments can be edited by selecting resolutions from a menu, typing directly into the input, or by loading a preset. There are eight "slots" for rythmic fragments, and each slot has a number of parameters that lets you affect how the fragment is played.

Notes can be edited by note learn, or typing a note directly into the input. Each note has an editable label that is useful to name the sound it triggers (like kick, snare, hihat...). There are eight slots for selecting notes, and each note has an edit page for detailed control.

### drunkenSequencer.lua (Drunken Sequencer)
The drunken sequencer is inspired in part by the "Drunk" modulator in Falcon. The principle for selecting notes is following a "random" walk up and down the scale. There are settings for controlling how far the notes will move for every step (short distance or long distance), and settings for directional bias (more up, or more down). The sequencer can be set to play with up to 16 voices, and has a multichannel option. It can be put at the master-level of Falcon, and parts can listen on the corresponding channel.

Note selection can be controlled by on/off for each note in the cromatic scale, and probability for each. Octave selection are done in the same manner (on/off+probability for each octave).

This generator uses the rythmic fragments from the beatbox.

### generativeChorder.lua (Generative Chorder)
The generative chorder is used for generating chords with up to 16 voices. Scales are created by selecting the notes to include (same note selector as the drunken sequencer). Chord definitions are then loaded from presets, or edited directly in the input. The generator can make "standard" chords, or you can define any chord you want, including clusters, fourths, seconds or any other intervals. Chord definitions can be saved to eight different slots for random selection.

The chorder also has a multichannel option, so each voice in the chord can be sent to separate channels.

### generativeStrategySeqencer.lua (Generative Strategy Sequencer)
This generator lets you define tonal "strategies", short sequences, that are played at different pitches.

### noteFragmentGenerator.lua (Note Fragment Generator)
This generator lets you pick the exact notes that you want to include. The notes are selected by random when playing.

This generator uses the rythmic fragments from the beatbox.