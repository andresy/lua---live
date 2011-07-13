
package = "keynote"
version = "1.0-1"

source = {
   url = "keynote-1.0-1.tgz"
}

description = {
   summary = "Provides a simple class to create interactive keynote/presentations.",
   detailed = [[
            A really cool package to generate simple yet interactive
            slides.
   ]],
   homepage = "",
   license = "MIT/X11"
}

dependencies = {
   "lua >= 5.1",
   "xlua",
   "torch"
}

build = {
   type = "builtin",
   modules = {
      keynote = "keynote.lua"
   }
}
