<script setup>
import { StarIcon as StarIconOutline } from "@heroicons/vue/24/outline";
import { StarIcon as StarIconSolid } from "@heroicons/vue/24/solid";
</script>
<template>
  <div autofocus tabindex="0" data-test="rating-wrapper">
    <button tabindex="-1" data-test="rating-button">
      <StarIconSolid data-test="solid-star" class="solid-star" />
    </button>
    <button tabindex="-1" data-test="rating-button">
      <StarIconSolid data-test="solid-star" class="solid-star" />
    </button>
    <button tabindex="-1" data-test="rating-button">
      <StarIconSolid data-test="solid-star" class="solid-star" />
    </button>
    <button tabindex="-1" data-test="rating-button">
      <StarIconOutline data-test="outline-star" class="outline-star" />
    </button>
    <button tabindex="-1" data-test="rating-button">
      <StarIconOutline data-test="outline-star" class="outline-star" />
    </button>
  </div>
</template>
