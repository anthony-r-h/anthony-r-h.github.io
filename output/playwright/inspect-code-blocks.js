async (page) => {
  await page.setViewportSize({ width: 1280, height: 900 });
  const inspect = async (text) => page.evaluate((needle) => {
    const code = Array.from(document.querySelectorAll('code')).find((element) =>
      element.textContent.includes(needle)
    );
    const wrapper = code.closest('.highlighter-rouge');
    const outerHighlight = wrapper.querySelector(':scope > .highlight');
    const pre = wrapper.querySelector('pre');
    const listItem = wrapper.closest('li');
    const list = wrapper.closest('ol, ul');
    const postContent = wrapper.closest('.post-content');

    const details = (element) => {
      if (!element) return null;
      const style = getComputedStyle(element);
      const rect = element.getBoundingClientRect();
      return {
        tag: element.tagName,
        className: element.className,
        x: rect.x,
        width: rect.width,
        background: style.backgroundColor,
        border: style.border,
        padding: style.padding,
        margin: style.margin
      };
    };

    return {
      wrapper: details(wrapper),
      outerHighlight: details(outerHighlight),
      pre: details(pre),
      code: details(code),
      listItem: details(listItem),
      list: details(list),
      postContent: details(postContent)
    };
  }, text);

  return {
    topLevel: await inspect('twelve field values'),
    listNested: await inspect('UTF-16 hexadecimal')
  };
}
