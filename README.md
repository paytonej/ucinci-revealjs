# ucinci-revealjs extension for Quarto

This extension provides an *unofficial* custom `revealjs` theme for the University of Cincinnati (UC) branded presentations.  It incorporates UC colors, logos, and typographic styles to create professional slide decks following the typography and color palette of the University of Cincinnati brand guidelines. 

The package includes a branding yaml, images, and logos for creating presentations based on the official College of Engineering and Applied Science PowerPoint template as of Spring 2025.

## Installing

Install the extension by running the following command:

```bash
quarto add paytonej/ucinci-revealjs
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

To use the ucinci-revealjs theme in your Quarto presentation, specify it as a format in your document YAML header:

```yaml
format: ucinci-revealjs
```

## What's included

- **Slide backgrounds:** `.official-uc-red-gradient`, `.beyond-black-gradient`, `.white-gradient`, `.uc-red-flat`, `.uc-black-flat`, `.black-and-white`, and the CEAS background images.
- **Content classes:** `.bang-box`, `.two-col` / `.three-col`, `.label-teal` / `.label-amber` / `.label-red`, `.center-text`, `{.diagram}` images, `.caption-match-image`, `.source-citation`, and `.font-tiny` … `.font-HUGE`.
- **Learning objectives:** `.objectives-box`, Bloom's-level badges (`.bloom-R` … `.bloom-C`), `.learning-objective-number`, and `.module-M1` … `.module-M5`.
- **Behavior:**
  - `.scroll-box`: a box that scrolls as you click forward.
  - `.collapse-out` fragments: steps that fade out and give up their space.
  - Slide classes `{.hide-logo}` and `{.nonincremental}`.
  - `{.before-title}`: a slide that comes before the title slide, such as an instructor's setup checklist.
- **Math and notes:**
  - Math renders with KaTeX, and `\ce{}` chemistry works inside it.
  - `::: {.instructor-notes}`: notes that appear only in an instructor PDF, never in the slides.
- **Live polls:** `::: {.poll}` blocks that students answer on their phones, using the `poll` plugin and `poll.lua`. They need the small PHP server in [poll-server/](poll-server/README.md). The secret key stays in your project's `_secrets.json` and is added only when you render.
- **Classroom-activity partials** in `resources/partials/`: a countdown timer, a think–pair–share timer that draws names, team draws for 2–6 teams, and a three-week due-date calendar. Add one with `{{< include _extensions/paytonej/ucinci/resources/partials/countdown.qmd >}}`. Most of them read a class roster or schedule spreadsheet with Python.
- **Course-project helpers** in `resources/scripts/`: PDF accessibility and font repair, Canvas page export, PDF image sizing, and more.

## Examples


- Documentation of the capabilities can be found in this example: <https://paytonej.github.io/ucinci-revealjs/template-demo.html>
   - The source code for the example can be found here: [template-demo.qmd](template-demo.qmd)
- A minimal example can be viewed at <https://paytonej.github.io/ucinci-revealjs/minimal-example.html>
  - Here is the source code for a minimal example: [minimal-example.qmd](minimal-example.qmd).

## References

* <https://github.com/mcanouil/quarto-revealjs-coeos>
* <https://github.com/Data-Wise/unm-revealjs/>
* <https://github.com/coatless-quarto/illinois-revealjs>
* <https://github.com/cct-datascience/uaz-revealjs>

## See also

* <https://github.com/paytonej/teleprompt-revealjs>

## License

This project is licensed under the terms of the [MIT License](LICENSE).

## Contributing

Contributions, issues, and feature requests are welcome! Feel free to open an issue or submit a pull request.
