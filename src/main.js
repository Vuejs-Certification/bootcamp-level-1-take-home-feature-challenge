import { createApp } from "vue";
import App from "./App.vue";
import "@/assets/main.css";
import FileTree from "./components/FileTree.vue";

createApp(App).component("FileTree", FileTree).mount("#app");
