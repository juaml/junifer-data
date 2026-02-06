# junifer data

This repository provides a [datalad](https://github.com/datalad/datalad) dataset
of data (coordinates, parcellations and masks) used by
[junifer](https://github.com/juaml/junifer) pipeline components.

## Maintaining

### Julich-Brain

To update, install [uv](https://docs.astral.sh/uv/getting-started/installation/) and
[just](https://just.systems/man/en/packages.html) and run:

```console
just julich-brain
```

## `pre-commit` hooks

Install by:

```console
prek install --install-hooks
```

Run by:

```console
prek run --all-files
```

For more information, check [here](https://github.com/juaml/junifer-data-hooks).
