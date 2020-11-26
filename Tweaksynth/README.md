# Tweak Synth

## Why Tweak Synth?

Tweak Synth was created to spark new ideas, and to trigger creativity. We can all be stuck sometimes, finding our selves following the same patterns over and over again. Tweak Synth wants to help you create something new, and it wants to help you find the best version of the sound you are trying to create.

## Different flavors

Tweak Synth comes in different flavors - wavetable, analog and additive. They are all similar, but there are different modulation options, and of course, the oscillators differ. But the tweaking algorithm is shared between all synths.

## Synth overview

Tweak Synth is built in UVI Falcon, using subtractive synthesis typical of classic analog synths. The synths have two oscillators, and a noise generator.
The synth is divided into six pages: Patchmaker, Twequencer, Synthesis, Filter, Modulation and Effects. Switching between pages is done using the buttons above the mixer. 

### Mixer

The mixer section is always visible for easy access to global parameters. Here you find levels for the oscillators, unison settings, play mode (poly/mono/glide) and noise type. It also features an on/off button for the Falcon arpeggiator for easy access.

### Synthesis section

The synthesis section contains the oscillators for editing waveform, pitch, vibrato and amplitude envelope.

### Filter section

The filter section contains two filters, a lowpass, and a highpass filter. The filter envelope has a few different modulation targets, in addition to both filters. There are some variations here depending on whether the wavetable, analog or additive version of the synth is used.

### Modulation section

The modulation section contains an LFO that can be assigned to a number of different targets. It is possible to override filter modulation for the noise oscillator, if this should be treated separatly. By default, the settings for the LFO is shared by all oscillators, but it is possible to use different settings for each oscillator. This option can be selected directly to the left of the waveform select menu. If a widget has different settings for each oscillator, the widget will be locked when "All" oscillators are selected, to avoid unintended changes.

### Effects section

Here you find a selection of useful effects for easy access. These are standard Falcon effects, so effects can easily be added, replaced, or edited in Falcon. Effects can easily be bypassed if you want to listen to the dry sound.

### Envelopes

By default, the settings for the envelopes are shared by all oscillators, but it is possible to use different settings for each oscillator. This option can be selected directly to the left of the attack knob. If a widget has different settings for each oscillator, the widget will be locked when "All" oscillators are selected, to avoid unintended changes.

## Tweak Synth

The two sections that make Tweak Synth different is Patchmaker and Twequencer. This is where you can create new presets from presets you made yourself, or from scratch. The two sections use the same alogithms to create new patches, but they differ in approach.

### Patchmaker

Patchmaker is where you create new patches instantly, with the click of a button. This is also where any snapshots you add are stored.

#### Snapshots

A snapshot contains the settings that were present in the current editing state when the snapshot was added. Snapshots can be added from manually created pathces as well as the ones created in twequencer and patchmaker. Most of the times you will want to do some manual changes to created patches, to make them sound the way you want, and then add them to you snapshots. Snapshots are stored with the program when it is saved. You can switch between snapshots using the menu, or the buttons. Remember that you current edit will be replaced with the settings from the selected snapshot, so remember to add or update the current edit to snaphots if you want to keep it.

#### Tweak level

When creating a new patch, the tweak level is your way of telling the synth how far from the original tweak source you want to change the sound. At tweak level 0 there will be virtually no changes made. As the tweak level rises, more changes will be introduced. At 100 the sound will be something completely new, and totally different than the original. This is an extreme setting, and will in most cases not produce any usable sounds. But it is fun to test! At sensible levels, usable sounds may be created. They will need a human touch, but can sound quite interesting right away. If you are not satisfied, just click the "Tweak patch" button again!

#### Tweak source

Selecting a tweak source will tell the synth where to get it's ideas from. If you have created some good snapshots, they can be used to create new sounds. The automatic option will use ideas from all the different sources. When "Current edit" is selected, remember that the current edit will change every time a new patch is created. So this can be a great way to introduce small changes for each iteration. Works well with the Twequencer, and at low tweak levels.

#### Envelope style

Envelope styles are a way to control the envelope times of the sounds being created. If you are looking for a pad type sound, use one of the long styles, and for snappier sounds, select one of the shorter versions. When set to automatic, the synth will make different envelopes every time, but in the twequencer, they will be affected by the selected resolution.

#### Tweak Scope

There are five scope buttons. Each button represents a section of the synth. When a button is selected, that section will be included when creating the patch. If no buttons are selected, no changes are made. This is useful if you only want to change parts of the sound. If you are happy with the mix, effects and modulation, you can deselect them, and changes will only be made to the synthesis and filter sections.

#### Actions menu

Snapshots can be added, updated or removed using the actions menu.

The actions menu has an option to set the current editing state to the sound that was stored when you save the program last (Recall saved patch).

The actions menu has an option to set current editing state to only default values (Initialize patch).

When you add the first snapshot, an initial snapshot containing the last saved state will be added automatically. So you first added snapshot will be called "Snapshot 2". The initial snapshot can be updated, but it cannot be removed, unless you remove all snapshots.

### Twequencer

The Twequencer is a simple sequencer that tweaks your sound as you play. Set a tweak level, select a play mode, and start playing! You can hear the changes to your sound being made for each round. A round consist of the number of steps that are set. By default 8 steps are selected, but if you set it to 2, the sound will change every second step.

**Note: When you start playing the twequencer and the tweak level is above 0, the current settings will be changed. Remeber to store it in the patchmaker, if you want to keep it! If tweak level is 0 no changes are made, but the sequencer still runs, if a play mode is selected.**

As you play, the Twequencer will store a snapshot for each round. If you hear something you like, just stop playing and select the snapshot from the round that sounded best. When you stop playing, the tweak level is set to 0 to avoid further changes. The last 100 rounds are remembered, but they are not stored with the program. You can store a snapshot you like from the "Actions" menu, and you will find it again in the Patchmaker. All stored snapshots are saved with the UVI program, so you will get it back when you open it later.

Envelopes will be tweaked according to the envelope style you choose. When automatic is selected, a fast resolution will give shorter envelope times than if a slow resolution is selected. Short envelope times can occur for slow resolutions, but long envelope times will not occur for fast resolutions. If one of the other envelope styles are selected, that will control the envelope times.

## Hmmm?

### How does Tweak Synth work?

Tweak Synth creates patches by combining randomization with rules that are set for each parameter to get sensible values. Since it is programmed to be experimental, sometimes it misses the mark. In a future version it might be possible to adjust these rules, but for the time being, they are hard coded into the synth.

### Is Tweak Synth smart?

No. It is not smart, nor is it an AI. But if you give it patches to work with, it can create some quite interesting, and sometimes good, patches, inspired by your input. Or it can create entirely on its own.

## Conclusion

That's it! Start creating, and hopefully you will discover some new sounds that you didn't know existed.