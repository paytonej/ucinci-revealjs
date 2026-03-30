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
