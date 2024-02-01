import { nextTick } from "vue";
import { mount } from "@vue/test-utils";
import { beforeAll, describe, expect, it } from "vitest";
import RatingInput from "@/components/RatingInput.vue";

describe("Rating Input", () => {
  let wrapper = null;

  beforeAll(() => {
    wrapper = mount(RatingInput, {
      props: {
        modelValue: 0,
        count: 10,
      },
    });
  });

  //
  it("assigns props correctly", async () => {
    expect(wrapper.props("modelValue")).toBe(0);
    expect(wrapper.props("count")).toBe(10);
  });

  //
  it("Emits `update:modelValue` event when a star is clicked", async () => {
    const starButtons = wrapper.findAll('[data-test="rating-button"]');
    starButtons.at(3).trigger("click");
    await nextTick();
    expect(wrapper.emitted()["update:modelValue"]).toBeTruthy();
    const emittedParams = wrapper.emitted()["update:modelValue"][0][0];
    expect(emittedParams).toBe(4);
  });

  //
  it("Displays the proper number of stars based on the count prop", async () => {
    const starButtons = wrapper.findAll('[data-test="rating-button"]');
    expect(starButtons).toHaveLength(10);
  });

  //
  it("Displays outlined or solid stars properly based on the selected rating (`modelValue`)", async () => {
    const wrapper = mount(RatingInput, {
      props: {
        modelValue: 3,
        count: 5,
      },
    });

    const starButtons = wrapper.findAll('[data-test="rating-button"]');
    expect(starButtons.at(0).find(".solid-star").exists()).toBe(true);
    expect(starButtons.at(1).find(".solid-star").exists()).toBe(true);
    expect(starButtons.at(2).find(".solid-star").exists()).toBe(true);

    expect(starButtons.at(3).find(".outline-star").exists()).toBe(true);
    expect(starButtons.at(4).find(".outline-star").exists()).toBe(true);
  });

  //
  it("increments the rating when the right arrow key is pressed", async () => {
    const wrapper = mount(RatingInput, {
      props: {
        modelValue: 3,
        count: 5,
      },
    });

    const ratingWrapper = wrapper.find('[data-test="rating-wrapper"]');
    ratingWrapper.trigger("keydown", {
      key: "ArrowRight",
    });
    await nextTick();

    expect(wrapper.emitted()["update:modelValue"]).toBeTruthy();
    const emittedParams = wrapper.emitted()["update:modelValue"][0][0];
    expect(emittedParams).toBe(4);
  });

  //
  it("increments the rating when the up arrow key is pressed", async () => {
    const wrapper = mount(RatingInput, {
      props: {
        modelValue: 3,
        count: 5,
      },
    });

    const ratingWrapper = wrapper.find('[data-test="rating-wrapper"]');
    ratingWrapper.trigger("keydown", {
      key: "ArrowUp",
    });
    await nextTick();

    expect(wrapper.emitted()["update:modelValue"]).toBeTruthy();
    const emittedParams = wrapper.emitted()["update:modelValue"][0][0];
    expect(emittedParams).toBe(4);
  });

  //
  it("decrements the rating when the left arrow key is pressed", async () => {
    const wrapper = mount(RatingInput, {
      props: {
        modelValue: 3,
        count: 5,
      },
    });

    const ratingWrapper = wrapper.find('[data-test="rating-wrapper"]');
    ratingWrapper.trigger("keydown", {
      key: "ArrowLeft",
    });
    await nextTick();

    expect(wrapper.emitted()["update:modelValue"]).toBeTruthy();
    const emittedParams = wrapper.emitted()["update:modelValue"][0][0];
    expect(emittedParams).toBe(2);
  });
  //
  it("decrements the rating when the down arrow key is pressed", async () => {
    const wrapper = mount(RatingInput, {
      props: {
        modelValue: 3,
        count: 5,
      },
    });

    const ratingWrapper = wrapper.find('[data-test="rating-wrapper"]');
    ratingWrapper.trigger("keydown", {
      key: "ArrowLeft",
    });
    await nextTick();

    expect(wrapper.emitted()["update:modelValue"]).toBeTruthy();
    const emittedParams = wrapper.emitted()["update:modelValue"][0][0];
    expect(emittedParams).toBe(2);
  });

  //
  it("Displays the `perfect-rating` class when a perfect rating is given", async () => {
    const wrapper = mount(RatingInput, {
      props: {
        modelValue: 5,
        count: 5,
      },
    });

    const ratingWrapper = wrapper.find('[data-test="rating-wrapper"]');
    expect(ratingWrapper.classes()).toContain("perfect-rating");
  });
});
