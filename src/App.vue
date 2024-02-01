<script setup>
import { ref } from "vue";
import RatingInput from "./components/RatingInput.vue";

const rating = ref();
</script>

<template>
  <h1>Rating Input Feature Challenge</h1>
  <RatingInput v-model="rating" :count="10" />
  <p>You Selected Rating: {{ rating || "NA" }}</p>
</template>
