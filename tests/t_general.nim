import denim_ui
import unittest
import denim_ui_canvas
import dom

suite "general tests":
  echo "General test setup"

  test "sdf":
    proc render(): Element =
      panel()

    startApp(
      render,
      "rootCanvas",
      "nativeContainer"
    )
    check(render of Element)

