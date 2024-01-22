<script setup>
import { ref } from "vue";
import { files } from "@/assets/dataSource";

const selected = ref();
</script>

<template>
  <div class="wrapper">
    <div class="file-system">
      <h1 class="app-title">File Tree Challenge</h1>
      <p class="selected-file">
        Selected file:
        <code class="selected-file">{{ selected || "No file selected" }}</code>
      </p>

      <!-- 
        This is the component you're creating 
        Head over to src/components/FileTree.vue to get started
      -->
      <FileTree
        :files="files"
        @select="selected = $event"
        :selected="selected"
      />
    </div>
  </div>
</template>
