package = "vindinlua"
version = "1.0-0"
source = {
  url = "git://github.com/mtdowling/vindinlua",
  tag = "1.0.0"
}
description = {
   summary = "A Vindinium starter kit for Lua",
   homepage = "https://github.com/mtdowling/vindinlua",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "dkjson >= 2.4"
}
build = {
   type = "builtin",
   modules = {
      vindinlua = "lib/vindinlua.lua"
   }
}