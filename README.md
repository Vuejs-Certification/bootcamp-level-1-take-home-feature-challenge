---
difficulty: 1
tags: Code Challenge, Exercise Challenge, Vue 3
---

# File Tree Component

# Challenge Description

In this challenge, you are tasked with creating a `FileTree` component.

The challenge will require that you work in `FileTree.vue`.

## Requirements

### The FileTree component should:

1. Work with it's current usage in `App.vue`
2. Accept the following props:

   - files - an array of objects shaped like those in `@/src/assets/dataSource.js`
   - selected - the currently selected file (default is null)
   - path - a string indicating how deep in the file tree the component is (default is '/')

3. Emit the following events:

   - select - emit when a file is clicked on. The payload is the complete file path.

4. Display the provided files in a traditional file tree format

   - Display the `IconFile` component to the left of the file name
   - Display the `IconFolderCollapsed` component to the left of the folder name for folders that are NOT expanded
   - Display the `IconFolderExpanded` component to the left of the folder name for folders that ARE expanded
   - Expand and collapse files when the user clicks on the folder icon
   - Nest each level visually under the parent folder

> 💡 HINT: The FileTree component is already registered globally so you can use it anywhere you want (including in itself)

5. Handle selecting files

   - When a file is clicked, emit the `select` event with the complete file path
   - When a file is clicked, add the `selected` class to the file to give it a blue color
   - When a file is clicked, remove the `selected` class from the previously selected file
   - When implemented correctly the selected file path should display in `App.vue` inside the `code.selected-file` element

![Screenshot of the solution](./screenshot.gif)

## Other Considerations

- If you see the `data-test` attribute in the boilerplate don't remove it. If you remove it, your code may be invalid for the certificate.
