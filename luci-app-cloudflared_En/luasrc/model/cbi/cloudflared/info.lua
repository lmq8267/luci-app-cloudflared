local fs = require "nixio.fs"
local http = require "luci.http"
local conffile = "/tmp/cloudflared.info"

local m = SimpleForm("logview", "")
m.reset = false
m.submit = false

-- Clear log button
local clear_btn = m:field(Button, "_clear", "")
clear_btn.inputtitle = "Clear log"
clear_btn.inputstyle = "remove"
function clear_btn.write()
	fs.writefile(conffile, "")
end

-- Log content box
local log = m:field(TextValue, "logcontent", "")
log.rows = 30
log.readonly = true
log.wrap = "off"
function log.cfgvalue()
	return fs.readfile(conffile) or ""
end

function m.render(self, ...)
	SimpleForm.render(self, ...)
	http.write([[
<script type="text/javascript">
	window.addEventListener("load", function(){
		var ta = document.querySelector("textarea[name='cbid.logview.1.logcontent']");
		if (ta) {
			setTimeout(function() {
				ta.scrollTop = ta.scrollHeight;
			}, 100); 
		}
	});
</script>
]])
end

local refresh_btn = m:field(Button, "_refresh", "")
refresh_btn.inputtitle = "Refresh log"
refresh_btn.inputstyle = "apply"
function refresh_btn.write()
end

return m
