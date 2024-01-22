import { nextTick } from "vue";
import { mount } from "@vue/test-utils";
import { beforeAll, describe, expect, it } from "vitest";
import { files } from "@/assets/dataSource";
import App from "@/App.vue";
import FileTree from "@/components/FileTree.vue";

describe("FileTree", () => {
  let wrapper = null;

  beforeAll(() => {
    wrapper = mount(App, {
      components: {
        FileTree,
      },
    });
  });

  it("assigns props correctly", async () => {
    const wrapper = mount(FileTree, {
      components: {
        FileTree,
      },
      props: {
        files,
      },
    });
    expect(JSON.stringify(wrapper.props("files"))).toBe(JSON.stringify(files));
    expect(wrapper.props("path")).toBe("");
    expect(wrapper.props("selected")).toBe(null);
  });

  it("Emit `select` event when a file is clicked", async () => {
    const wrapper = mount(FileTree, {
      components: {
        FileTree,
      },
      props: {
        files,
      },
    });
    const folder = wrapper.findAll('[data-test="folder-btn"]');
    folder.at(0).trigger("click");
    await nextTick();
    const file = wrapper.findAll('[data-test="file-btn"]');
    file.at(0).trigger("click");
    expect(wrapper.emitted()["select"]).toBeTruthy();
    const emittedParams = wrapper.emitted()["select"][0][0];
    expect(emittedParams).toBe("/projectA/App.vue");
  });

  it("display file tree format and handle selecting files", async () => {
    const folders = wrapper.findAll('[data-test="folder-btn"]');
    const firstFolder = folders.at(0);

    // Display the `IconFolderCollapsed` component to the left of the folder name for folders that are NOT expanded
    expect(firstFolder.html()).toContain('data-test="icon-folder-collapsed"');
    firstFolder.trigger("click");
    await nextTick();

    // Display the `IconFolderExpanded` component to the left of the folder name for folders that ARE expanded
    expect(firstFolder.html()).toContain('data-test="icon-folder-expanded"');
    const file = wrapper.findAll('[data-test="file-btn"]');
    const firstFile = file.at(0);

    //  Display the `IconFile` component to the left of the file name
    expect(firstFile.html()).toContain('data-test="icon-file"');

    expect(firstFile.classes()).not.toContain("selected");

    firstFile.trigger("click");
    await wrapper.vm.$nextTick();

    // When a file is clicked, add the `selected` class
    expect(firstFile.classes()).toContain("selected");
  });
});
