
package = "present"
version = "1.0-1"

source = {
   url = "present-1.0-1.tgz"
}

description = {
   summary = "Provides a simple class to create interactive presentations.",
   detailed = [[
            A really cool package to generate simple yet interactive
            slides.
   ]],
   homepage = "",
   license = "MIT/X11"
}

dependencies = {
   "lua >= 5.1",
   "torch"
}

build = {
   type = "builtin",
   modules = {
      present = "present.lua"
   }
}
