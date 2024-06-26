---
difficulty: 1
tags: Code Challenge, Exercise Challenge, Vue 3
---

# Rating Input Feature Challenge

# Challenge Description

In this challenge you are tasked with creating a star rating input component.

The challenge will require that you work in `RatingInput.vue` and reference `App.vue`.

## Requirements

### the Rating Input should:

1. Accept the following props:

   - `modelValue` - this represents the rating the user has picked and allows the component to work with v-model
   - `count` - this is the total number of stars the rating should display (default is 5)

2. Emit the following events:

   - update:modelValue - emit when a star is clicked on. The payload is the rating (1, 2, 3, etc)
   - You should also validate the event payload to ensure that it is a number

3. Display a button for each star based on the provided count

4. Display solid yellow stars for stars less than or equal to the `modelValue`

5. Display outlined gray stars for stars greater than the `modelValue`

6. Support the following keyboard shortcuts when the rating wrapper is focused

   - Pressing keyboard numbers 0-9 should set the rating accordingly
   - Pressing the `ArrowUp` or `ArrowRight` key should increment the rating by 1
   - Pressing the `ArrowDown` or `ArrowLeft` key should decrement the rating by 1

7. Apply the class `perfect-rating` to the `rating-wrapper` div when a perfect rating is selected

> 💡 HINT: The stars will turn orange when the perfect-rating class is applied to the `rating-wrapper`

By the end of the exercise you should have something that looks like this:
![screenshot of completed](https://images.certificates.dev/ratings-screenshot.gif)

## Other Considerations

- If you see the `data-test` attribute in the boilerplate don't remove it. If you remove it, your code may be invalid for the certificate.
