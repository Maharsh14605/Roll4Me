# Roll 4 Me


### Authors:
- Maharsh Patel
- Advait Modh
- Andy Tran

## Description:
Roll 4 Me is an iOS and watchOS app designed to help users make quick, everyday decisions through
a collection of simple and engaging randomization tools. At its core, the app offers several features
based on random number generation, including a dice roll, coin flip, color spinner, team generator,
person chooser, and order shuffler. These tools are useful for settling small, trivial choices such as
deciding what to order from a menu, choosing who goes first in a game, or figuring out how to divide
a group into teams.

## Building & Running

1. Open the project in Xcode.
2. Select the target (Roll4Me iOS or Roll4Me watchOS).
3. Press the Run button to build and launch the app.

## Roll 4 Me iOS Features:

### Home Screen:
From the homescreen, select the feature you want to interact with by pressing the icon.

### Coin Flip:
When you tap the Flip button or tilt your device upward the app triggers an animated 3D coin flip. After a brief rotation, the result is determined using weighted randomness, based on the custom weights you assign to each side. Haptic feedback confirms both the flip and the final result, and the app keeps track of how many times the coin has been flipped.

- Weighted randomness
- Customizable side names
- 3D flip animation
- Tilt-to-flip (motion activated)
- Haptics
- Flip counter
- On-screen customization bubble


### Dice Roll
When you tap a die or shake your device the app triggers a quick 3D tumble animation for each active die. There are two types of die, fair dice use standard uniform randomness, and there's a second die uses a weighted probability distribution that you can fully customize. After the animation completes, each die lands on its final value, and the app updates the total roll at the top. The "+" options panel lets you enable a weighted die and adjust the weight of each face, with live percentage feedback as you change the values.

- Roll one or two dice with smooth 3D tumble animations
- Tap a die to roll it individually
- Shake the device to roll all dice at once
- Displays the total result at the top

- Fast, responsive haptic feedback
- Custom "+" panel for:
  - Adding/removing the weighted die
  - Adjusting weights for each face
  - Viewing real-time normalized probabilities
  - Resetting to a fair die

### Random Order Shuffler
When you type something into the field and press enter or tap the plus button, it gets added as a chip in the list. You can tap any chip to remove it instantly, or long press it to bring up an edit sheet where you can rename it. When you're ready to randomize, you can press the Sort button at the bottom or shake your device, and after a brief delay with optional haptic and sound feedback, the final shuffled order appears in the results card. The handle button on the bottom bar opens a small settings panel where you can toggle haptics, toggle sound, and adjust the volume if sound is enabled. Adding items, editing items, removing items, and sorting all update the displayed order right away, keeping the interface simple and easy to use.

- Add items quickly using the text field or plus button
- Remove items with a tap, or edit them with a long press
- Shuffle the list using the Sort button or by shaking the device
- Optional haptic and sound feedback during shuffle
- Results displayed in a clear, ordered list

### Person Chooser
Place one or more fingers on the panel and each touch appears as a colored circle that tracks your finger in real time. You can choose how many winners you want by opening the small choose popover, then tap the Pick button to randomly select from the fingers on the screen. The chosen circles light up, and the final winner gets a pulsing highlight along with optional sound and haptic feedback. If you lift all fingers, the screen resets automatically. The handle button at the bottom opens the settings panel where you can adjust the volume, toggle sound, and toggle haptics.

- Live finger tracking with multiple simultaneous touches
- Pick one or several winners at once
- Pulsing highlight animation for the final chosen finger
- Optional sound and haptic feedback

### Spinner 
Swipe the wheel left or right to spin it, or tap the Spin button to start a random rotation. The pointer at the top indicates the selected segment when the wheel stops. You can add options by opening the editor, typing them in bulk, or dictating them with speech. Each option can be weighted to increase its chance of being selected, and you can also choose to eliminate options after they are picked. The small handle button opens the settings panel where you can adjust sound, volume, and haptic feedback. While spinning, subtle haptic ticks and sound provide tactile and audio feedback.

- Swipe or tap to spin the wheel
- Weighted segments and elimination after hit
- Add options manually or via speech dictation
- Bulk input with live probability calculation
- Animated wheel with color-coded slices and labels
- Optional haptic and sound feedback
- Small bottom settings panel for quick adjustments

### Team generator
This Team Generator app provides a simple and interactive way to create balanced teams from a list of names or by using touch input. To interact with it, start by entering player names into the text field at the top and tapping the plus button to add them. You can edit a name by long-pressing a name chip, or remove it by tapping the chip. Adjust the number of teams using the plus and minus buttons. Once your list is ready, tap Sort in the bottom bar to generate teams, which appear as cards showing each player. You can also assign bias weights to favor certain players being placed in specific teams. If no names are added, the app lets you use finger mode to place team members by touch, where each finger represents a team. The settings panel at the bottom allows you to control sound, haptics, and volume.

- Add, edit, and remove player names
- Choose the number of teams
- Sort players into balanced teams with optional bias weights
- Finger mode for touch-based team assignment
- Settings panel for sound, haptics, and volume
- Animated, color-coded team cards for easy visualization
- Supports dynamic inline editing and long-press interactions

## Roll 4 Me watchOS features

### Coin Flip
This Coin Flip Watch app lets you simulate flipping a coin directly on your Apple Watch. To interact with it, simply tap the coin in the center or press the Flip button at the bottom. The coin performs a smooth 3D rotation animation and randomly lands on Heads or Tails, providing haptic feedback for both the start and the result of the flip.

- Tap the coin or press the Flip button to flip.
- 3D rotation animation for a realistic flipping effect.
- Random outcome: Heads or Tails.
- Haptic feedback on flip start and result.

### Dice Roll
This Dice Roll Watch app allows you to roll one or two dice directly on your Apple Watch with animations and optional weighted mechanics. You can tap a die to roll it individually, or roll all dice at once using the Roll button. The app visually animates each die tumbling and provides a total sum of the rolled values. For advanced interactions, you can configure a weighted die, adjusting the probability of each face using the settings panel.

- Tap individual dice to roll them with 3D tumble animation.
- Roll all dice at once with animated effects.
- Displays the total sum of all dice.
- Supports weighted dice: customize face probabilities.
- Configurable dice panel with live preview of probabilities.

### Random Person Chooser
This Random Finger / Person Watch app is a fun little tool for picking one or more winners from a group. Each finger is represented by a circle, and the selection process is animated with hopping highlights and red final selections. You can customize both the number of fingers and how many winners to pick via the chooser bubble.

- Tap Choose to start a random selection animation.
- Circles hop in order before settling on the winners.
- Winners are highlighted in red and produce haptic feedback.
- Configurable number of fingers (1–10).
- Configurable number of winners (up to the number of fingers).

