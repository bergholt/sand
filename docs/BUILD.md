# Build and regeneration status

This is a preservation package, not a verified reproducible build.

## Supplied evidence

`SAND.NFO` describes Turbo Pascal 7 sources built using Free Pascal 3.2.2 for the `i8086-msdos` target. `SRC/SAND.PAS` gives the historical command `TPC SAND.PAS` and describes a `SIM` conditional build with Free Pascal in Turbo Pascal mode. These are author-supplied instructions, not build results obtained while packaging.

The source imports `SCOREDAT`, `FONT8`, `VGA`, `SND` and `ENDSCR`. They are all included. Keep original filenames and encodings. On case-sensitive hosts, unit discovery may require explicit unit compilation or temporary filename normalisation in a separate build directory.

A maintainer with the correct DOS cross compiler can start by testing its Turbo Pascal compatibility mode against `SRC/SAND.PAS`. The archive does not identify the compiler's memory-model options or exact cross-compiler invocation. The short `TPC` comment should not be taken as proof that the supplied source compiles unchanged under Turbo Pascal 7.

The documented host-side simulation entry point is:

```sh
cd SRC
fpc -Mtp -dSIM SAND.PAS
```

This is an unverified starting point. Inspect the conditional code in `VGA.PAS` and `SND.PAS` before relying on it. The SIM program accepts numeric sample times to write PGM frames and a `RAW` mode to write a full frame stream. It does not exercise the actual DOS sound hardware path.

## APL material

`TEXTS.APL` defines the text data. `SCORE.APL` defines score construction, event generation and score printing. `SYNTH.APL` defines audio-bus generation, at 48,000 samples/s in ten-second chunks. The files use Unicode APL notation; no interpreter or dialect is pinned by the archive.

The archive does not include a complete orchestration command, the converter from printed APL score data to `SCOREDAT.PAS`, or the documented final room/reverberation, silence, mix, resampling and unsigned 8-bit stereo export pipeline that would recreate `SAND.SND`. The functions and comments reveal much of the method, but a byte-identical rebuild cannot be promised.

Until these steps are recovered or reconstructed and compared, use the supplied `SAND.EXE`, `SAND.SND` and `SCOREDAT.PAS` as preservation artefacts. Any reconstruction should be labelled and compared against them rather than silently replacing them.

## Validation performed for this package

- Checked ZIP integrity and archive path safety.
- Compared SHA-256 hashes of all 16 supplied files against their archive entries.
- Checked the executable's MZ signature.
- Checked soundtrack size against its documented PCM format and score duration.
- Read the score constants and the letter-to-partial rules in both Pascal and APL.
- Rendered and visually inspected the ANSI preview.
- Checked local Markdown links and the final ZIP contents.

No compilation, executable playback, hardware test or APL regeneration was performed.
