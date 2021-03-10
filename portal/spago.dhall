{-
Welcome to a Spago project!
You can edit this file as you like.
-}
{ name = "accessibility"
, dependencies =
  [ "aff-coroutines"
  , "affjax"
  , "argonaut"
  , "bigints"
  , "console"
  , "coroutines"
  , "datetime-iso"
  , "effect"
  , "filterable"
  , "generics-rep"
  , "halogen"
  , "http-methods"
  , "newtype"
  , "numbers"
  , "openlayers"
  , "psci-support"
  , "routing"
  , "routing-duplex"
  , "uuid"
  ]
, packages = ./packages.dhall
, sources = [ "src/**/*.purs", "test/**/*.purs" ]
}
