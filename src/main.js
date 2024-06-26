import { createApp } from "vue";
import App from "./App.vue";
import "@/assets/main.css";
import terminal from "virtual:terminal";
// eslint-disable-next-line
globalThis.console = terminal;

createApp(App).mount("#app");
