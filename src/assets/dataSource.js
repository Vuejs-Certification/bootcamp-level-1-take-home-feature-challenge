export const files = [
  {
    name: "projectA",
    children: [
      {
        name: "App.vue",
      },
      {
        name: "main.js",
      },
    ],
  },
  {
    name: "projectB",
    children: [
      {
        name: "components",
        children: [
          {
            name: "FileItem.vue",
          },
          {
            name: "FileSelect.vue",
          },
          {
            name: "FileTree.vue",
          },
        ],
      },
      {
        name: "App.vue",
      },
      {
        name: "main.js",
      },
    ],
  },
  {
    name: "projectC",
    children: [
      {
        name: "composables",
        children: [
          {
            name: "fileTree.js",
          },
        ],
      },
      {
        name: "App.vue",
      },
      {
        name: "main.js",
      },
    ],
  },
];
