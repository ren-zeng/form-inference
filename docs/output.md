<style>

@layer components {
  .expressive-code {
    position: relative;
    font-family: var(
      --ec-uiFontFamily,
      ui-sans-serif,
      system-ui,
      -apple-system,
      BlinkMacSystemFont,
      "Segoe UI",
      sans-serif
    );
    font-size: var(--ec-uiFontSize, 0.9rem);
    font-weight: var(--ec-uiFontWeight, 400);
    line-height: var(--ec-uiLineHeight, 1.65);
    text-size-adjust: none;
    -webkit-text-size-adjust: none;
  }

  .expressive-code *:not(:is(svg, svg *)) {
    box-sizing: border-box;
  }

  .expressive-code::selection {
    background: var(--ec-uiSelBg, var(--ec-codeBg, #0d1117));
    color: var(--ec-uiSelFg, currentColor);
  }

  .expressive-code pre {
    display: flex;
    margin: 0;
    padding: 0;
    border: var(--ec-borderWd, 1.5px) solid
      var(--ec-borderCol, rgba(148, 163, 184, 0.25));
    border-radius: calc(
      var(--ec-borderRad, 0.3rem) + var(--ec-borderWd, 1.5px)
    );
    background: var(--ec-codeBg, #0d1117);
    color: var(--ec-codeFg, #c9d1d9);
    overflow-x: auto;
    position: relative;
    z-index: 1;
    container-type: inline-size;
  }

  .expressive-code pre:focus-visible {
    outline: 3px solid var(--ec-focusBorder, #3b82f6);
    outline-offset: -3px;
  }

  .expressive-code pre &gt; code {
    all: unset;
    display: block;
    flex: 1 0 100%;
    padding: var(--ec-codePadBlk, 0.5rem) 0;
    color: var(--ec-codeFg, #c9d1d9);
    font-family: var(
      --ec-codeFontFamily,
      ui-monospace,
      SFMono-Regular,
      Menlo,
      Monaco,
      Consolas,
      "Liberation Mono",
      "Courier New",
      monospace
    );
    font-size: var(--ec-codeFontSize, 0.85rem);
    font-weight: var(--ec-codeFontWeight, 400);
    line-height: var(--ec-codeLineHeight, 1.35);
  }

  .expressive-code pre &gt; code::selection {
    background: var(--ec-codeSelBg, rgba(56, 189, 248, 0.35));
    color: inherit;
  }

  .expressive-code pre.wrap .ec-line .code {
    white-space: pre-wrap;
    overflow-wrap: break-word;
    min-width: min(20ch, var(--ecMaxLine, 20ch));
  }

  /* When lines are allowed to wrap, the absolute overlay can overlap
     wrapped text. Disable the overlay in wrap mode and rely on per-slot
     borders for guides (these are handled by .indent-slot). */
  .expressive-code pre.wrap .ec-line .code .indent-overlay {
    display: none;
  }

  .expressive-code pre.wrap .ec-line .code::before {
    content: "";
    position: absolute;
    left: 0;
    top: 0;
    /* use the code line-height times the element font-size to match one line */
    height: calc(var(--ec-codeLineHeight, 1.65) * 1em);
    width: max(0px, calc(var(--ecIndent, 0) - 2px));
    pointer-events: none;
    background-image: repeating-linear-gradient(
      to right,
      transparent 0,
      transparent calc(var(--ec-indentStep, 4ch) - 1px),
      var(--ec-indentGuideCol, rgba(148, 163, 184, 0.35))
        calc(var(--ec-indentStep, 4ch) - 1px),
      var(--ec-indentGuideCol, rgba(148, 163, 184, 0.35))
        var(--ec-indentStep, 4ch)
    );
    background-repeat: no-repeat;
    background-size: 100% 100%;
    mix-blend-mode: multiply;
    opacity: 0.85;
    z-index: 0;
  }

  .expressive-code pre.wrap .ec-line .code span.indent {
    white-space: pre;
  }

  .expressive-code .ec-line .code .indent {
    display: inline-flex;
    white-space: pre;
  }

  .expressive-code .ec-line .code .indent-slot {
    display: inline-flex;
    white-space: pre;
    position: relative;
  }

  .expressive-code.has-indent-guides .ec-line .code .indent-slot {
    border-inline-end: 1px solid
      var(--ec-indentGuideCol, rgba(148, 163, 184, 0.35));
  }

  .expressive-code.has-indent-guides
    .ec-line
    .code
    .indent-slot.indent-slot-partial {
    border-inline-end: none;
  }

  .expressive-code pre::-webkit-scrollbar,
  .expressive-code pre::-webkit-scrollbar-track {
    background-color: inherit;
    border-radius: calc(
      var(--ec-borderRad, 0.3rem) + var(--ec-borderWd, 1.5px)
    );
    border-top-left-radius: 0;
    border-top-right-radius: 0;
  }

  .expressive-code pre::-webkit-scrollbar-thumb {
    background-color: var(--ec-scrollbarThumbCol, rgba(148, 163, 184, 0.4));
    border: 4px solid transparent;
    background-clip: content-box;
    border-radius: 10px;
  }

  .expressive-code pre::-webkit-scrollbar-thumb:hover {
    background-color: var(
      --ec-scrollbarThumbHoverCol,
      rgba(148, 163, 184, 0.55)
    );
  }

  .expressive-code .code-lang {
    position: absolute;
    top: 0.25rem;
    right: 0.6rem;
    padding: 0;
    display: inline-flex;
    align-items: baseline;
    gap: 0.25rem;
    background: none;
    color: var(--ec-langFg, var(--ec-codeFg, currentColor));
    font-size: 0.68em;
    pointer-events: none;
    opacity: 0.6;
    transition: opacity 160ms ease, color 160ms ease;
    z-index: 2;
  }

  .expressive-code:focus-within .code-lang,
  .expressive-code:hover .code-lang {
    opacity: 1;
    color: var(--ec-langFg, var(--ec-codeFg, currentColor));
  }

  .expressive-code .copy-button {
    position: absolute;
    top: 0.6rem;
    right: 0.6rem;
    display: inline-flex;
    align-items: center;
    justify-content: center;
    width: 2.3rem;
    height: 2.3rem;
    border-radius: 0.45rem;
    border: 1px solid rgba(148, 163, 184, 0.28);
    background-color: var(--ec-copyBg, rgba(15, 23, 42, 0.04));
    color: var(--ec-copyFg, rgba(15, 23, 42, 0.7));
    cursor: pointer;
    opacity: 0;
    pointer-events: auto;
    transition: opacity 160ms ease, transform 160ms ease,
      background-color 140ms ease, color 140ms ease;
    transform: translateY(-0.3rem);
    background-image: url("data:image/svg+xml,%3Csvg xmlns%3D%27http://www.w3.org/2000/svg%27 viewBox%3D%270 0 24 24%27 fill%3D%27none%27 stroke%3D%27currentColor%27 stroke-width%3D%271.75%27 stroke-linecap%3D%27round%27 stroke-linejoin%3D%27round%27%3E%3Cpath d%3D%27M3 19a2 2 0 0 1-1-2V3a2 2 0 0 1 1-1h13a2 2 0 0 1 2 1%27/%3E%3Crect x%3D%276%27 y%3D%275%27 width%3D%2716%27 height%3D%2718%27 rx%3D%271.6%27 ry%3D%271.6%27/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: center;
    background-size: 60%;
    z-index: 3;
  }

  .expressive-code .copy-button:is(:hover, :focus-visible, :active) {
    opacity: 1;
    transform: translateY(0);
  }

  .expressive-code .copy-button:focus-visible {
    outline: 2px solid rgba(148, 163, 184, 0.55);
    outline-offset: 2px;
    background-color: var(--ec-copyBgFocus, rgba(15, 23, 42, 0.16));
    color: var(--ec-copyFgFocus, rgba(15, 23, 42, 1));
  }

  .expressive-code .copy-button::before {
    content: "";
    width: 100%;
    height: 100%;
    border-radius: inherit;
    background: transparent;
    border: none;
    pointer-events: none;
  }

  .expressive-code .copy-button::after {
    content: none;
    pointer-events: none;
  }

  .expressive-code .copy-button .copy-label,
  .expressive-code .copy-button .copy-feedback {
    display: none;
  }

  .expressive-code .copy-button:hover {
    background-color: var(--ec-copyBgHover, rgba(15, 23, 42, 0.12));
    color: var(--ec-copyFgHover, rgba(15, 23, 42, 0.9));
  }

  .expressive-code .copy-button span[aria-hidden="true"] {
    font-family: var(--ec-uiFontFamily, inherit);
  }

  .expressive-code .ec-header,
  .expressive-code .ec-footer {
    display: block;
    padding: 0.35rem var(--ec-codePadInl, 1.35rem);
    color: var(--ec-uiFg, currentColor);
  }

  .expressive-code .ec-header.ec-ext,
  .expressive-code .ec-footer.ec-ext {
    padding: 0.25rem var(--ec-codePadInl, 1.35rem);
  }

  .expressive-code .ec-line {
    direction: ltr;
    unicode-bidi: isolate;
    display: grid;
    grid-template-areas: "gutter code";
    grid-template-columns: auto 1fr;
    column-gap: var(--ec-gutterGap, 0.25rem);
    position: relative;
    --lineBg: var(--ec-codeBg, #0d1117);
    background: var(--lineBg);
  }

  .expressive-code:not(.has-gutter) .ec-line {
    grid-template-columns: 1fr;
  }

  .expressive-code:not(.has-gutter) .ec-line .code {
    padding-inline: var(--ec-codePadInl, 1.35rem);
  }

  .expressive-code .ec-line .gutter {
    grid-area: gutter;
    color: var(--ec-gtrFg, rgba(148, 163, 184, 0.8));
    position: sticky;
    left: 0;
    z-index: 2;
    background: var(--lineBg, var(--ec-gutterBg, var(--ec-codeBg, #0d1117)));
    box-shadow: 1px 0 0 var(--ec-gtrBrdCol, rgba(148, 163, 184, 0.2));
  }

  .expressive-code .ec-line .gutter &gt; * {
    pointer-events: none;
    user-select: none;
    -webkit-user-select: none;
  }

  .expressive-code .ec-line .gutter ~ .code {
    --ecLineBrdCol: var(--ec-gtrBrdCol, rgba(148, 163, 184, 0.2));
  }

  .expressive-code .ec-line.highlight .gutter {
    color: var(--ec-gtrHighlightFg, rgba(226, 232, 240, 0.95));
  }

  .expressive-code .ec-line .gutter .ln {
    display: inline-flex;
    justify-content: flex-end;
    align-items: flex-start;
    box-sizing: content-box;
    min-width: var(--lnWidth, 2ch);
    padding-inline-start: var(--ec-gutterPadLeft, 0.5rem);
    padding-inline-end: var(--ec-codePadInl, 1.35rem);
    font-size: var(--ec-codeFontSize, 0.85rem);
    font-variant-numeric: tabular-nums;
    color: inherit;
  }

  .expressive-code .ec-line .gutter .ln &gt; span + span {
    margin-inline-start: 0.25em;
  }

  .expressive-code .ec-line .code {
    position: relative;
    z-index: 1;
  }

  .expressive-code .ec-line .code .indent-overlay {
    display: none;
  }

  .expressive-code.has-indent-guides .ec-line .code .indent-overlay {
    position: absolute;
    inset: 0 auto 0 0;
    display: block;
    /* Shrink overlay by 1px to avoid drawing a vertical guide at the very end of
       the inline area (prevents an extra line appearing at each row end).
       Use max(...) to avoid negative values when --ecIndent is small. */
    width: max(0px, calc(var(--ecIndent, 0) - 2px));
    pointer-events: none;
    background-image: repeating-linear-gradient(
      to right,
      transparent 0,
      transparent calc(var(--ec-indentStep, 4ch) - 1px),
      var(--ec-indentGuideCol, rgba(148, 163, 184, 0.35))
        calc(var(--ec-indentStep, 4ch) - 1px),
      var(--ec-indentGuideCol, rgba(148, 163, 184, 0.35))
        var(--ec-indentStep, 4ch)
    );
    background-repeat: no-repeat;
    background-size: 100% 100%;
    mix-blend-mode: multiply;
    opacity: 0.85;
    z-index: 0;
  }
  .expressive-code .ec-comment {
    grid-column: 1 / -1;
    padding: 0.55rem calc(var(--ec-codePadInl, 1.35rem) + 0.25rem);
    font-size: 0.85em;
    background: var(--ec-commentBg, rgba(56, 189, 248, 0.18));
    color: var(--ec-commentFg, currentColor);
    box-shadow: inset 0 1px 0 rgba(15, 23, 42, 0.08),
      inset 0 -1px 0 rgba(15, 23, 42, 0.06);
    position: sticky;
    left: 0;
    z-index: 2;
    width: 100cqw;
    box-sizing: border-box;
  }

  .expressive-code .sr-only {
    position: absolute;
    width: 1px;
    height: 1px;
    padding: 0;
    margin: -1px;
    overflow: hidden;
    clip: rect(0, 0, 0, 0);
    white-space: nowrap;
    border-width: 0;
  }

  code.expressive-code-inline {
    display: inline-block;
    padding: 0 var(--ec-inlinePadInl, 0.4rem);
    border-radius: calc(var(--ec-borderRad, 0.3rem) / 1.2);
    background: var(--ec-inlineBg, rgba(148, 163, 184, 0.2));
    color: var(--ec-inlineFg, inherit);
    font-family: var(
      --ec-codeFontFamily,
      ui-monospace,
      SFMono-Regular,
      Menlo,
      Monaco,
      Consolas,
      "Liberation Mono",
      "Courier New",
      monospace
    );
    font-size: 0.95em;
    line-height: 1.2;
    white-space: pre;
  }
}


</style><script>

const CODE_BLOCK_SELECTOR = ".expressive-code";
const COPY_BUTTON_SELECTOR = ".copy-button";

const selectCodeBlocks = () =&gt;
  Array.from(document.querySelectorAll(CODE_BLOCK_SELECTOR));

const extractCodeText = (codeBlock) =&gt;
  Array.from(codeBlock.querySelectorAll(".ec-line .code"))
    .map((line) =&gt; {
      const indent = line.dataset.indent ?? "";
      const content = line.textContent
        .replace(/\u00a0/g, " ")
        .replace(/\u200b/gi, "");
      return indent + content;
    })
    .join("\n");

const fallbackCopy = (text) =&gt; {
  const textarea = document.createElement("textarea");
  textarea.value = text;
  textarea.setAttribute("readonly", "true");
  textarea.style.position = "absolute";
  textarea.style.left = "-9999px";
  document.body.appendChild(textarea);
  textarea.select();
  /** @type {any} */ (document).execCommand("copy");
  document.body.removeChild(textarea);
};

const setStateWithTimeout = (button, state, delay = 1600) =&gt; {
  button.dataset.state = state;
  if (state === "copied") {
    setTimeout(() =&gt; {
      if (button.dataset.state === "copied") {
        button.dataset.state = "idle";
      }
    }, delay);
  }
};

const bindCopyButton = (codeBlock) =&gt; {
  if (!codeBlock || codeBlock.dataset.copyBound === "true") return;

  const copyButton = codeBlock.querySelector(COPY_BUTTON_SELECTOR);
  if (!copyButton) return;

  codeBlock.dataset.copyBound = "true";

  const copyHandler = async () =&gt; {
    const code = extractCodeText(codeBlock);

    try {
      if (navigator.clipboard?.writeText) {
        await navigator.clipboard.writeText(code);
      } else {
        fallbackCopy(code);
      }
      setStateWithTimeout(copyButton, "copied");
    } catch (error) {
      try {
        fallbackCopy(code);
        setStateWithTimeout(copyButton, "copied");
      } catch (fallbackError) {
        setStateWithTimeout(copyButton, "error", 2200);
      }
    }
  };

  const resetHandler = () =&gt; {
    if (copyButton.dataset.state === "copied") {
      copyButton.dataset.state = "idle";
    }
  };

  copyButton.addEventListener("click", copyHandler);
  copyButton.addEventListener("blur", resetHandler);
  copyButton.addEventListener("mouseleave", resetHandler);
};

selectCodeBlocks().forEach(bindCopyButton);

const observer = new MutationObserver((mutations) =&gt; {
  for (const mutation of mutations) {
    mutation.addedNodes.forEach((node) =&gt; {
      if (!(node instanceof HTMLElement)) return;
      if (node.matches?.(CODE_BLOCK_SELECTOR)) {
        bindCopyButton(node);
      } else {
        node
          .querySelectorAll?.(CODE_BLOCK_SELECTOR)
          .forEach((block) =&gt; bindCopyButton(block));
      }
    });
  }
});

observer.observe(document.documentElement, {
  childList: true,
  subtree: true,
});


</script>

### Musical examples

The musical examples, including scores and audios, links to the official [Analyzing Classical Form](https://acf.research.mcgill.ca/) website.

Among the [https://acf.research.mcgill.ca/supp\_list.php](https://acf.research.mcgill.ca/supp_list.php)complete list of example we look at how the form inference model perform on only a few of them.

### Model output

#### Identifying presentation

##### example 2-11

[![](assets/example2-11.png)](https://acf.research.mcgill.ca/example2-11.php) [🔊 **Click to Play**](https://acf.research.mcgill.ca/example2-11.mp3)

We distinguish between bindings for idea and bindings for formal unit binding. For the presentation, it is the idea that is repeats, while for the period the repeating thing is the formal unit (ABAC)

```
Input surface:
  [{a ⟦I None⟧}, {a ⟦IV None⟧}]




Output analysis:
  size=11
  Concatenate
    {"a" ⟦I None⟧}
    {"a" ⟦IV None⟧}
```

This example illustrates the basics of how variable binding leads to smaller size. By default, we assign a high cost of raw repetition markers from the input (as they are placeholders for the surface motivic ideas). On the other hand, calling a binding variable just cost 1.

##### example 2-12

[![](assets/example2-12.png)](https://acf.research.mcgill.ca/example2-12.php) [🔊 **Click to Play**](https://acf.research.mcgill.ca/example2-12.mp3)

This time we make the input a little bit harder in that the basic idea is not an atomic marker, but the concatenation of two. And the model need to identify the repetition of “a”+“b” as the basic idea, and correctly build up the phrase parameter for the concatenated phrases.

```
Input surface:
  [{a ⟦I-V None⟧}, {b ⟦I-III None⟧}, {a ⟦VI-II None⟧}, {b ⟦VI-III None⟧}]




Output analysis:
  size=27
  Concatenate
    {"a" ⟦I-V None⟧}
    Concatenate
      {"b" ⟦I-III None⟧}
      Concatenate
        {"a" ⟦VI-II None⟧}
        {"b" ⟦VI-III None⟧}



  size=27
  Concatenate
    Concatenate
      {"a" ⟦I-V None⟧}
      {"b" ⟦I-III None⟧}
    Concatenate
      {"a" ⟦VI-II None⟧}
      {"b" ⟦VI-III None⟧}
```

#### Identifying compound themes

##### example 6-1

[![](assets/example6-1.png)](https://acf.research.mcgill.ca/example6-1.php) [🔊 **Click to Play**](https://acf.research.mcgill.ca/example6-1.mp3)

```
Input surface:
  [ {a ⟦I-V None⟧}
  , {b ⟦I-V-I-V Weak⟧}
  , {c ⟦IV-V-I None⟧}
  , {d ⟦VI-VII-I-V Weak⟧}
  , {a ⟦I-V None⟧}
  , {b ⟦I-V-I-V Weak⟧}
  , {c ⟦V None⟧}
  , {e ⟦I Strong⟧} ]




Output analysis:
  size=44
  Concatenate
    Ternary
      Concatenate
        {"a" ⟦I-V None⟧}
        {"b" ⟦I-V-I-V Weak⟧}
      Concatenate
        {"c" ⟦IV-V-I None⟧}
        {"d" ⟦VI-VII-I-V Weak⟧}
    Concatenate
      {"c" ⟦V None⟧}
      {"e" ⟦I Strong⟧}



  size=44
  HybridAntCont
    Ternary
      Concatenate
        {"a" ⟦I-V None⟧}
        {"b" ⟦I-V-I-V Weak⟧}
      Concatenate
        {"c" ⟦IV-V-I None⟧}
        {"d" ⟦VI-VII-I-V Weak⟧}
    Concatenate
      {"c" ⟦V None⟧}
      {"e" ⟦I Strong⟧}
```

##### example 6-2

[![](assets/example6-2.png)](https://acf.research.mcgill.ca/example6-2.php) [🔊 **Click to Play**](https://acf.research.mcgill.ca/example6-2.mp3)

```
Input surface:
  [ {a ⟦I None⟧}
  , {b ⟦I None⟧}
  , {c ⟦I None⟧}
  , {a ⟦V None⟧}
  , {b ⟦V None⟧}
  , {c ⟦V None⟧}
  , {b ⟦I-VI None⟧}
  , {b ⟦IV-II None⟧}
  , {b ⟦V None⟧}
  , {d ⟦I-II-V-I Strong⟧} ]




Output analysis:
  size=62
  Sentence
    basicIdea= "a"+"b"+"c"
    presentation= Concatenate
                    UseIdeaWith   $0 ⟦I None⟧+⟦I None⟧+⟦I None⟧
                    UseIdeaWith   $0 ⟦V None⟧+⟦V None⟧+⟦V None⟧
    continuation= Sentence
                    basicIdea= "b"
                    presentation= Concatenate
                                    UseIdeaWith   $0 ⟦I-VI None⟧
                                    UseIdeaWith   $0 ⟦IV-II None⟧
                    continuation= Concatenate
                                    {$0 ⟦V None⟧}
                                    {"d" ⟦I-II-V-I Strong⟧}



  size=65
  Concatenate
    {"a" ⟦I None⟧}
    Concatenate
      {"b" ⟦I None⟧}
      Concatenate
        {"c" ⟦I None⟧}
        Concatenate
          {"a" ⟦V None⟧}
          Concatenate
            {"b" ⟦V None⟧}
            Concatenate
              {"c" ⟦V None⟧}
              Sentence
                basicIdea= "b"
                presentation= Concatenate
                                UseIdeaWith   $0 ⟦I-VI None⟧
                                UseIdeaWith   $0 ⟦IV-II None⟧
                continuation= Concatenate
                                {$0 ⟦V None⟧}
                                {"d" ⟦I-II-V-I Strong⟧}
```

##### example 6-5

[![](assets/example6-5.png)](https://acf.research.mcgill.ca/example6-5.php) [🔊 **Click to Play**](https://acf.research.mcgill.ca/example6-5.mp3)

```
Input surface:
  [ {a ⟦I-V None⟧}
  , {a ⟦V-I None⟧}
  , {b ⟦IV-I None⟧}
  , {b ⟦IV-I None⟧}
  , {c ⟦II None⟧}
  , {c ⟦I None⟧}
  , {d ⟦V Weak⟧} ]




Output analysis:
  size=40
  Sentence
    basicIdea= "a"
    presentation= Concatenate
                    UseIdeaWith   $0 ⟦I-V None⟧
                    UseIdeaWith   $0 ⟦V-I None⟧
    continuation= Concatenate
                    TwiceFormalUnit
                      {"b" ⟦IV-I None⟧}
                    Concatenate
                      {"c" ⟦II None⟧}
                      Concatenate
                        {"c" ⟦I None⟧}
                        {"d" ⟦V Weak⟧}



  size=39
  Concatenate
    {"a" ⟦I-V None⟧}
    Concatenate
      {"a" ⟦V-I None⟧}
      Concatenate
        TwiceFormalUnit
          {"b" ⟦IV-I None⟧}
        Concatenate
          {"c" ⟦II None⟧}
          Concatenate
            {"c" ⟦I None⟧}
            {"d" ⟦V Weak⟧}
```

#### Others

##### supp 6-1

[![](assets/supp6-1.png)](https://acf.research.mcgill.ca/supp6-1.php) [🔊 **Click to Play**](https://acf.research.mcgill.ca/supp6-1.mp3)

##### example 5-11

[![](assets/example5-11.png)](https://acf.research.mcgill.ca/example5-11.php) [🔊 **Click to Play**](https://acf.research.mcgill.ca/example5-11.mp3)
