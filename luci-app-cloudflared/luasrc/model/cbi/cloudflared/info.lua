local fs = require "nixio.fs"
local http = require "luci.http"
local conffile = "/tmp/cloudflared.info"

-- 清空日志
if http.formvalue("_clear") then
	fs.writefile(conffile, "")
end

-- 刷新日志
if http.formvalue("_refresh") then
end

local m = SimpleForm("logview", "")
m.reset = false
m.submit = false

function m.render(self, ...)

	SimpleForm.render(self, ...)

	local raw = fs.readfile(conffile) or ""
	local lines = {}
	for line in raw:gmatch("[^\r\n]+") do
		table.insert(lines, line)
	end

	local log_table = {}
	for _, line in ipairs(lines) do
		local ok, obj = pcall(function() return luci.jsonc.parse(line) end)
		if ok and obj then table.insert(log_table, obj) end
	end

	local function reverse(t)
		local res = {}
		for i = #t, 1, -1 do
			table.insert(res, t[i])
		end
		return res
	end
	log_table = reverse(log_table)

	local function humanTime(iso)
		local y, m, d, h, min, s = iso:match("(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z")
		if y then
			return string.format("%s-%s-%s %s:%s:%s", y, m, d, h, min, s)
		else
			return iso
		end
	end

	http.write([[

<style>
.controls { display: flex; align-items: center; margin-bottom: 10px; gap: 10px; flex-wrap: wrap; }
.controls .log-count { margin-left: auto; font-weight: bold; }
.controls .btn { padding: 6px 12px; border-radius: 6px; border: none; cursor: pointer; transition: all 0.2s ease; color: #fff; }
.btn-clear { background-color: #e74c3c; }
.btn-clear:hover { background-color: #ff4d4f; }
.btn-refresh { background-color: #2563eb; }
.btn-refresh:hover { background-color: #3b82f6; }

.log-container { border: 1px solid #ccc; padding: 10px; margin: 10px 0; border-radius: 6px; background: #f9f9f9; word-wrap: break-word; }
.log-field { margin: 2px 0; }
.log-level-error { color: red; font-weight: bold; }
.log-level-warn { color: orange; font-weight: bold; }
.log-level-info { color: green; font-weight: bold; }
.log-button { cursor: pointer; color: blue; text-decoration: underline; border: none; background: none; padding: 0; }

.modal { display: none; position: fixed; z-index: 999; left: 0; top: 0; width: 100%; height: 100%; overflow: auto; background-color: rgba(0,0,0,0.5); }
.modal-content { background-color: #fff; margin: 10% auto; padding: 20px; border-radius: 6px; width: 80%; max-width: 700px; word-wrap: break-word; overflow-wrap: break-word; white-space: pre-wrap; max-height: 70vh; position: relative; color: #000; }
.modal-close { position: absolute; top: 10px; right: 10px; padding: 6px 10px; border-radius: 6px; background-color: #f59e0b; color: #fff; cursor: pointer; border: none; transition: background 0.2s ease; }
.modal-close:hover { background-color: #fbbf24; }

#topBtn { display: none; position: fixed; bottom: 100px; right: 20px; z-index: 1000; font-size: 14px; padding: 8px 12px; border: none; border-radius: 6px; background-color: #007aff; color: #fff; cursor: pointer; }

@media (prefers-color-scheme: dark) {
	body { background-color: #0f1115; color: #e5e7eb; }
	.log-container { background: #1b1e24; border-color: #333; color: #e5e7eb; border-radius: 6px; }
	.log-level-error { color: #ff6b6b; }
	.log-level-warn { color: #f3c623; }
	.log-level-info { color: #4ade80; }
	.log-button { color: #60a5fa; }
	.modal-content { background-color: #1b1e24; color: #e5e7eb; border-radius: 6px; }
	#topBtn { background-color: #2563eb; color: #fff; border-radius: 6px; }

	.controls .btn-clear { background-color: #b91c1c; }
	.controls .btn-clear:hover { background-color: #dc2626; }
	.controls .btn-refresh { background-color: #2563eb; }
	.controls .btn-refresh:hover { background-color: #3b82f6; }

	.modal-close { background-color: #f59e0b; color: #000; }
	.modal-close:hover { background-color: #fbbf24; color: #000; }
}
</style>

<div class="controls">
  <button onclick="clearLogs()" class="btn btn-clear">清空日志</button>
  <button onclick="refreshLogs()" class="btn btn-refresh">刷新日志</button>
  <div class="log-count">共 ]] .. #log_table .. [[ 条日志</div>
</div>
]])

	for i, logobj in ipairs(log_table) do
		local level_cn = logobj.level == "error" and "错误" or (logobj.level == "warn" and "警告" or "信息")
		local level_class = logobj.level == "error" and "log-level-error" or (logobj.level == "warn" and "log-level-warn" or "log-level-info")
		local time = humanTime(logobj.time or "")
		local ip = logobj.ip or ""
		local connIndex = logobj.connIndex or ""
		local event = logobj.event or ""
		local typ = logobj.type or ""
		local dest = logobj.dest or ""
		local error_msg = logobj.error or ""
		local message = logobj.message or ""
		local json_str = luci.jsonc.stringify(logobj)

		http.write("<div class='log-container'>")
		http.write("<div class='log-field'><strong>日志时间：</strong>" .. time .. "</div>")
		http.write("<div class='log-field'><strong>日志等级：</strong><span class='" .. level_class .. "'>" .. level_cn .. "</span></div>")
		if ip ~= "" then http.write("<div class='log-field'><strong>IP 地址：</strong>" .. ip .. "</div>") end
		if connIndex ~= "" then http.write("<div class='log-field'><strong>连接索引：</strong>" .. connIndex .. "</div>") end
		if event ~= "" then http.write("<div class='log-field'><strong>事件编号：</strong>" .. event .. "</div>") end
		if typ ~= "" then http.write("<div class='log-field'><strong>日志类型：</strong>" .. typ .. "</div>") end
		if dest ~= "" then http.write("<div class='log-field'><strong>目标地址：</strong>" .. dest .. "</div>") end
		if error_msg ~= "" then http.write("<div class='log-field'><strong>错误信息：</strong>" .. error_msg .. "</div>") end
		if message ~= "" then http.write("<div class='log-field'><strong>消息内容：</strong>" .. message .. "</div>") end
		http.write("<div class='log-field'><button class='log-button' onclick='openModal(" .. i .. ")'>查看原始 JSON 日志</button></div>")
		http.write("</div>")

		http.write("<div id='modal_" .. i .. "' class='modal'><div class='modal-content'><button class='modal-close' onclick='closeModal(" .. i .. ")'>关闭</button><pre style='overflow-x: hidden; white-space: pre-wrap; word-wrap: break-word;'>" .. json_str .. "</pre></div></div>")
	end

	http.write([[

<button id="topBtn" onclick="topFunction()">返回顶部</button>

<script>
function openModal(id) { document.getElementById("modal_" + id).style.display = "block"; }
function closeModal(id) { document.getElementById("modal_" + id).style.display = "none"; }
window.onclick = function(event) {
	var modals = document.getElementsByClassName('modal');
	for(var i=0;i<modals.length;i++){
		if(event.target == modals[i]) modals[i].style.display = "none";
	}
}
function topFunction() { document.documentElement.scrollTop = 0; document.body.scrollTop = 0; }
window.onscroll = function() {
	var btn = document.getElementById("topBtn");
	btn.style.display = (document.body.scrollTop > 200 || document.documentElement.scrollTop > 200) ? "block" : "none";
}

function clearLogs(){ window.location.href = "?form=logview&_clear=1"; }
function refreshLogs(){ window.location.href = "?form=logview&_refresh=1"; }
</script>

]])
end

return m
