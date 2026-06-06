# Editor support for the Aria DSL family

Syntax-highlighting plugins for VS Code and Neovim covering four sibling
dialects all called "Aria":

| Variant       | Repo                  | Extension(s)   | Domain                          |
|---------------|-----------------------|----------------|---------------------------------|
| `aria-strat`  | gpu-backtest          | `.aria`        | Trading-strategy DSL            |
| `aria-quantum`| quantum               | `.aria`        | Quantum-circuit DSL             |
| `aria-hdl`    | fpga-meta-compiler    | `.ahdl`        | Hardware description / pipelines|
| `aria-fin`    | Sibelius              | `.aria`, `.fs` | Financial contract combinators  |

## Layout

```
editors/
├── samples/                     # one demo file per dialect
├── vscode/                      # VS Code extension (TextMate grammars)
│   ├── package.json
│   ├── language-configuration-default.json
│   ├── language-configuration-strat.json
│   └── syntaxes/
│       ├── aria-strat.tmLanguage.json
│       ├── aria-quantum.tmLanguage.json
│       ├── aria-hdl.tmLanguage.json
│       └── aria-fin.tmLanguage.json
└── nvim/                        # Vim/Neovim regex syntax (zero deps)
    ├── ftdetect/aria.vim        # 5-step routing waterfall
    ├── ftplugin/aria_*.vim      # one per dialect
    └── syntax/aria_*.vim        # one per dialect
```

## Install

### VS Code

```sh
ln -s "$(pwd)/editors/vscode" ~/.vscode/extensions/aria-multi-0.1.0
# Reload VS Code.
```

### Neovim / Vim

```sh
mkdir -p ~/.config/nvim/pack/aria/start
ln -s "$(pwd)/editors/nvim" ~/.config/nvim/pack/aria/start/aria-multi
```

Open any sample under `editors/samples/` and confirm `:echo &filetype`
returns one of `aria_strat`, `aria_quantum`, `aria_hdl`, `aria_fin`.

## Dialect routing

Three dialects share the `.aria` extension. Resolution precedence
(highest first):

1. **Modeline** — `-- aria: <variant>` on line 1 wins.
2. **Extension** — `.ahdl` → hdl; `.fs` → fin.
3. **Workspace path** (Vim only) — `/quantum/`, `/Sibelius/`,
   `/fpga-meta-compiler/`, `/gpu-backtest/` route to the corresponding
   dialect.
4. **Content sniff** (Vim only) — first 200 lines:
   `circuit`/`qreg` → quantum; `contract`/`cash_flow` → fin;
   `module`/`pipeline` → hdl; `signal`/`strategy` → strat.
5. **Fallback** — `aria_strat`.

VS Code does not natively support steps 3 & 4 (workspace path / content
sniff). For ambiguous `.aria` files there, use the modeline (step 1) or
pick the dialect from the language picker in the bottom-right.

### Modeline syntax (recommended override)

```
-- aria: strat
-- aria: quantum
-- aria: hdl
-- aria: fin
```

Place on the first line of the file. This works for both VS Code and
Vim and is unambiguous.

## Color palette

Both plugins map syntactic categories onto standard scope/group names so
highlighting inherits the user's chosen colorscheme:

| Category                    | Vim group     | TextMate scope                  |
|-----------------------------|---------------|---------------------------------|
| Comments (`-- …`, `// …`)   | `Comment`     | `comment.line.*`                |
| Annotations (`@assert`)     | `PreProc`     | `storage.type.annotation`       |
| Top-level decl              | `Structure`   | `keyword.declaration.*`         |
| Bindings (`let`/`var`)      | `Keyword`     | `storage.type.binding`          |
| Control flow                | `Repeat`      | `keyword.control.flow`          |
| Combinators / actions       | `Type`/`Statement` | `support.function.*` / `keyword.other.*` |
| Builtin functions           | `Function`    | `support.function.builtin`      |
| Constants (`pi`, `true`, …) | `Constant`    | `constant.language.*`           |
| Numbers                     | `Number`/`Float` | `constant.numeric.*`         |
| Bra/ket markers (quantum)   | `Special`     | `string.other.{ket,bra}`        |
| ISO dates (fin)             | `Special`     | `constant.other.date`           |
| Type names                  | `Type`        | `entity.name.type`              |
| Operators                   | `Operator`    | `keyword.operator.*`            |

## Co-existence with `quantum/editors/`

The `quantum` repo ships its own plugin using filetype `aria` and VS
Code language id `aria`. This plugin uses distinct names
(`aria_quantum`, language id `aria-quantum`) so the two can coexist
without clashing. We recommend installing only one — this multi-dialect
plugin is a strict superset for the quantum dialect.

## Notes

- Grammar repos (comment / string / number / identifier) are duplicated
  across the four TextMate files rather than shared via cross-file
  `include` (TextMate makes that fragile). Keep edits to common patterns
  in sync across all four `*.tmLanguage.json` files.
- The VS Code F# extension may pre-claim `.fs` files. If so, use the
  `-- aria: fin` modeline or right-click → "Configure file association".
- The `firstLine` regex in `package.json` lets VS Code switch language
  on a modeline match, but only for files VS Code already recognizes;
  the language picker is the dependable fallback.

## Verification

```sh
# JSON validity.
for f in editors/vscode/syntaxes/*.json \
         editors/vscode/package.json \
         editors/vscode/language-configuration-*.json; do
    python3 -m json.tool "$f" > /dev/null
done

# Vim syntax parse + filetype routing.
for f in editors/samples/*; do
    vim -Es \
        -c "set rtp+=$(pwd)/editors/nvim" \
        -c "edit $f" \
        -c "echo &filetype" \
        -c "qa"
done
```

Expected filetypes:
- `samples/strat_demo.aria` → `aria_strat`
- `samples/quantum_demo.aria` → `aria_quantum`
- `samples/hdl_demo.ahdl` → `aria_hdl`
- `samples/fin_demo.aria` → `aria_fin`
- `samples/fin_demo.fs` → `aria_fin`
