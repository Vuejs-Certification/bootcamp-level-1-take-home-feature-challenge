<script setup>
import IconFile from "./icons/IconFile.vue";
import IconFolderExpanded from "./icons/IconFolderExpanded.vue";
import IconFolderCollapsed from "./icons/IconFolderCollapsed.vue";
</script>

<template>
  <!-- 
    This HTML displays static data
    but yours should function according to the requirements.
 -->
  <ul class="folder">
    <li>
      <button data-test="folder-btn">
        <IconFolderCollapsed /> My Collapsed folder
      </button>
    </li>
    <li>
      <button data-test="folder-btn">
        <IconFolderExpanded /> My Expanded folder
      </button>
      <ul class="folder">
        <!-- File 1 -->
        <li>
          <button data-test="file-btn"><IconFile /> My File 1</button>
        </li>
        <!-- File 2 -->
        <li class="file selected">
          <button data-test="file-btn"><IconFile /> My File 2</button>
        </li>
      </ul>
    </li>
  </ul>
</template>

<style scoped>
.selected {
  color: #4242bc;
}

.folder {
  margin-left: 15px;
}
</style>
