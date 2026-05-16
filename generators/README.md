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

### gridSeqencer.lua (Grid Sequencer)
This generator lets you arrange notes in a grid, and play them back as single notes or chords/clusters.

### cellularAutomatonDrums.lua (Cellular Automaton Drums)
A drum machine where eight drum tracks are derived mathematically from a single 16-step seed row using an [elementary cellular automaton](https://en.wikipedia.org/wiki/Elementary_cellular_automaton) rule. Because every track is a descendant of the same seed, the patterns share rhythmic structure while remaining distinct — kicks, snares, hats and percussion are all related but never identical.

#### How it works
An elementary CA operates on a row of binary cells. Each cell's next state is determined by itself and its two neighbours, giving eight possible 3-cell neighbourhoods. A rule number (0–255) encodes one output bit for each neighbourhood, fully defining how the row evolves. Track 1 is the seed itself; each subsequent track is computed by stepping the CA forward by *Gen Gap* generations from the previous track's row.

#### Settings

| Parameter | Description |
|-----------|-------------|
| **Rule** (0–255) | The elementary CA rule number. Changing the rule rewrites all eight tracks immediately. |
| **Preset** | Quick-pick menu for well-known rules: *30* (chaotic/noise), *90* (Sierpinski triangle), *110* (universal computation), *150* (XOR), *184* (traffic flow), *18*, *54*, *60*, *126*, *22*. |
| **Evolution** | How the seed changes between bars: *Static* — seed loops forever; *Evolve* — the last drum row becomes the new seed each bar, continuously drifting the patterns; *Mutate* — small random bit-flips are applied to the seed each bar. |
| **Mutation %** | Probability (per cell) of a random flip when Evolution is set to *Mutate*. Higher values create faster drift. |
| **Gen Gap** (1–8) | How many CA generations separate adjacent drum tracks. Low values make neighbouring tracks nearly identical; high values make them more independent. |
| **Random Seed** | Randomise all 16 seed cells at once. Momentary button — does not stay pressed. |
| **Clear Seed** | Set all 16 seed cells to off. Momentary button — does not stay pressed. |

#### Seed row
Sixteen toggle buttons showing the generation-0 pattern. Click any cell to flip it on or off. All eight drum tracks update live as you edit.

#### Per-track controls (one row per drum)

| Control | Description |
|---------|-------------|
| **Label** | Editable track name (click to rename). Colour-coded per track for easy reading. |
| **Pattern display** | Read-only bar chart showing the 16-step pattern for this track. Colour matches the track label. |
| **Note** | MIDI note number sent when this track fires (default: General MIDI drum map). |
| **L** (Learn) | Note learn. Press the button, then play any MIDI note — the track note is set automatically and the button turns off. |
| **Mute** | Silence this track without removing it from the grid display. |
| **Vel** | Fixed velocity for all hits on this track (1–127). |

#### Footer

| Control | Description |
|---------|-------------|
| **Resolution** | Step length (default 1/8 — sixteen steps equals two bars). |
| **Gate** | Note length as a percentage of the step duration. 100 % = held until the next step; lower values give a more staccato feel. |
| **Multichannel** | When enabled, each drum track is sent on a separate MIDI channel (base channel + track index − 1), allowing per-drum instrument routing in Falcon. |
| **Channel** | Base MIDI channel (1–16). |
| **Step** | Live display of the current playback position within the 16-step cycle. |

### noteFragmentGenerator.lua (Note Fragment Generator)
This generator lets you pick the exact notes that you want to include. The notes are selected by random when playing.

This generator uses the rythmic fragments from the beatbox.