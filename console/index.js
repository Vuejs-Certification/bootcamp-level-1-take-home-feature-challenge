import VConsole from "vconsole";
import { initPlugin } from "vue-vconsole-devtools";
const vConsole = new VConsole({
  theme: "dark",
  defaultPlugins: ["element", "storage"],
});
let plugin = new VConsole.VConsolePlugin("vuecert", "Vue Cert");
import "./styles.css";

plugin.on("showConsole", () => {
  document.getElementById("app").classList.add("console-shown");
});

plugin.on("hideConsole", () => {
  document.getElementById("app").classList.remove("console-shown");
});

const openConsole = () => {
  vConsole.show();
};
window.openConsole = openConsole;
vConsole.hideSwitch();
initPlugin(vConsole);
vConsole.addPlugin(plugin);
// vConsole.show();

let button = document.createElement("button");
button.classList.add("vc-console-trigger-button");
button.innerText = "Open Console";
button.addEventListener("click", openConsole);

let spacerInnerDiv = document.createElement("div");
spacerInnerDiv.classList.add("vc-inner-spacer");

let consoleDiv = document.createElement("div");
consoleDiv.classList.add("vc-console-placeholder");
consoleDiv.appendChild(button);
consoleDiv.appendChild(spacerInnerDiv);
document.body.appendChild(consoleDiv);

let spacerDiv = document.createElement("div");
spacerDiv.classList.add("vc-spacer");
document.body.appendChild(spacerDiv);
