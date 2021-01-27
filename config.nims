
if defined(emscripten):
  echo "Compiling to wasm with emscripten"
  # This path will only run if -d:emscripten is passed to nim.

  --nimcache:tmp # Store intermediate files close by in the ./tmp dir.

  --os:linux # Emscripten pretends to be linux.
  --cpu:i386 # Emscripten is 32bits.
  --cc:clang # Emscripten is very close to clang, so we will replace it.
  switch("clang.exe", "emcc")# Replace C
  switch("clang.linkerexe", "emcc")# Replace C linker
  switch("clang.cpp.exe", "emcc")# Replace C++
  switch("clang.cpp.linkerexe", "emcc")# Replace C++ linker.
  --listCmd # List what commands we are running so that we can debug them.

  --gc:arc # GC:arc is friendlier with crazy platforms.
  --exceptions:goto # Goto exceptions are friendlier with crazy platforms.

  # Pass this to Emscripten linker to generate html file scaffold for us.
  switch("passL", "./wasm-canvas/src/canvas.c -o basic.html --shell-file index.html")
