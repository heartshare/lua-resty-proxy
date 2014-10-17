package = "resty-proxy"
version = "scm-1"
source = {
    url = "git://github.com/mah0x211/lua-resty-proxy.git"
}
description = {
    summary = "proxy handling module for openresty",
    homepage = "https://github.com/mah0x211/lua-resty-proxy", 
    license = "MIT/X11",
    maintainer = "Masatoshi Teruya"
}
dependencies = {
    "lua >= 5.1",
    "halo >= 1.0",
    "lua-cjson >= 2.1.0",
}
build = {
    type = "builtin",
    modules = {
        ["resty.proxy"] = "proxy.lua",
    }
}

