<script setup>
import { StarIcon as StarIconOutline } from "@heroicons/vue/24/outline";
import { StarIcon as StarIconSolid } from "@heroicons/vue/24/solid";
const props = defineProps({
  modelValue: { type: Number, default: 0 },
  count: { type: Number, default: 5 },
});

const emit = defineEmits({
  "update:modelValue": (value) => {
    return typeof value === "number";
  },
});

function handleKeyboardShortcuts(e) {
  const supportedKeys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"];
  if (supportedKeys.includes(e.key)) {
    emit("update:modelValue", Number(e.key));
  }
  if (
    ["ArrowRight", "ArrowUp"].includes(e.key) &&
    props.modelValue < props.count
  ) {
    emit("update:modelValue", props.modelValue + 1);
  }
  if (["ArrowLeft", "ArrowDown"].includes(e.key) && props.modelValue > 0) {
    emit("update:modelValue", props.modelValue - 1);
  }
}
</script>
<template>
  <div
    autofocus
    tabindex="0"
    @keydown="handleKeyboardShortcuts"
    class="rating-wrapper"
    data-test="rating-wrapper"
    :class="{
      'perfect-rating': modelValue === count,
    }"
  >
    <button
      v-for="i in count"
      tabindex="-1"
      :key="i"
      @click="() => $emit('update:modelValue', i)"
      data-test="rating-button"
    >
      <StarIconSolid
        v-if="i <= modelValue"
        data-test="solid-star"
        class="solid-star"
      />
      <StarIconOutline v-else data-test="outline-star" class="outline-star" />
    </button>
  </div>
</template>
