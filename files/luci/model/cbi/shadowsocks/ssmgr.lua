local m, s, o

m = Map("shadowsocks", translate("shadowsocks"))

s = m:section(TypedSection, "ssmgr", translate("General Setting"))
s.anonymous   = true

o = s:option(Flag, "enable", translate("Enable"))
o.rmempty     = false

o = s:option(Value, "site", translate("Site"))
o.placeholder = "website"
o.default     = "https://wall.gyteng.com/"
o.datatype    = "string"
o.rmempty     = false

o = s:option(Value, "mac", translate("MAC address"))
o.placeholder = "mac"
o.default     = luci.sys.exec("ifconfig | grep 'eth0' | awk '{print $5}' | sed 's/\://g'")
o.datatype    = "string"
o.rmempty     = false
o.readonly    = true

button = s:option(Button, "_button", "refresh")
button.inputtitle = translate("Refresh")
button.inputstyle = "apply"

function button.write(self, section, value)
  luci.sys.call("sh /usr/bin/ssmgr")
end

buttonSsmgr = s:option(Button, "_buttonSsmgr", "ssmgr")
buttonSsmgr.inputtitle = translate("Ssmgr")
buttonSsmgr.inputstyle = "apply"

function buttonSsmgr.write(self, section, value)
  uci = luci.model.uci.cursor()
  uci:foreach("shadowsocks", "ssmgr", function(s)
    address = s.site
  end)
  mac = luci.sys.exec("ifconfig | grep 'eth0' | awk '{print $5}' | sed 's/\://g'")
  url = address .. "home/login/" .. mac
  luci.http.redirect(url)
end

return m
