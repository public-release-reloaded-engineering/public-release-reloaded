# n_ary

- `src/n_ary.ml`: trimmed the generated module index to only the modules that actually
  exist in this release (`Enum3`, `Tuple3`, `Variant3`, `List3`).  The file was
  auto-generated listing `Enum2`–`Enum16`, `Tuple2`–`Tuple16`, `Variant2`–`Variant16`,
  `List2`–`List16`, but only the `*3` source files are present; all others are missing,
  causing warning 49 ("no cmi file found") errors for every absent module.
