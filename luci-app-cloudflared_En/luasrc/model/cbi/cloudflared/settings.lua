
a=Map("cloudflared",translate("Cloudflared"),translate("Cloudflare's tunnel client - formerly known as Argo Tunnel, free intranet penetration, enabling external network access to intranet services"))
a:section(SimpleSection).template  = "cloudflared/cloudflared_status"

t=a:section(NamedSection,"config","cloudflared")
t.anonymous=true
t.addremove=false

e=t:option(Flag,"enabled",translate("Enable"))
e.default=0
e.rmempty=false

e=t:option(Flag,"cmdenabled",translate("Custom CMD"),
	translate("Use custom commands. If you don't understand, don't enable it."))
e.default=0
e.rmempty=false

cfbin = t:option(Value, "cfbin", translate("cloudflared program path"),
	translate("Customize the cloudflared storage path and make sure to fill in the complete path and cloudflared name"))
cfbin.placeholder = "/usr/bin/cloudflared"
cfbin.rmempty=false

e=t:option(DynamicList,"token",translate('Token'),
	translate("You need to go to the official website to create a tunnel first, <br>and then copy a long string of token values ​​starting with eyJh.<br> Be careful to copy correctly, otherwise the startup will fail.<br>You can also create a tunnel using the following command ：<a href='https://blog.outv.im/2021/cloudflared-tunnel/' target='_blank'>Tutorial-1</a>&nbsp;&nbsp;&nbsp;<a href='https://zhuanlan.zhihu.com/p/621870045' target='_blank'>Tutorial-2</a>"))
e.placeholder = "eyJhIjoiMzQ3NTNhNDBlZTg4NTYzMDU5YmUzN2U2ZDY4YjEzY2QiLCJ0IjoiNTJkMjkwYTktNmFiNy00NDM5LThlODYtMzhmYTI0NTBhZjNhIiwicyI6IlptRXlOekl4TURZdFpUa3dPUzAwTnprM0xUbGlaR1l0TWpNNVpUUTBNV0k0TTJNMSJ9"
e:depends("cmdenabled", 0)

custom_cmd = t:option(DynamicList, "custom_cmd", translate("Custom startup parameters"),
                       translate("There is no need to add the program path here, just add the startup parameters normally. <br>Detailed command startup parameters:<a href='https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/configure-tunnels/tunnel-run-parameters/' target='_blank'>cloudflared doc</a><br>Note: Each parameter must be added separately, for example, add the first parameter:tunnel <br> Second parameter:--no-autoupdate The third parameter--logfile /tmp/cloudflared.info The fourth parameter:run <br>You cannot add two parameters in one box, you can only click + input in multiple input boxes<br>If you need to output the log path, please set it: --logfile /tmp/cloudflared.info"))
custom_cmd.placeholder = "--logfile /tmp/cloudflared.info"
custom_cmd:depends("cmdenabled", 1)

loglevel = t:option(ListValue, "loglevel", translate("Log level"),
	translate("Specifies the verbosity of logging. The default info level doesn't produce much output, <br>but you may want to issue a warning when using this level in production.<br>Level from low to high：debug < info < warn < Error < Fatal"))
loglevel:value("info")
loglevel:value("debug")
loglevel:value("warn")
loglevel:value("error")
loglevel:value("fatal")
loglevel:depends("cmdenabled", 0)


e=t:option(DummyValue,"opennewwindow" , 
	translate("<input type=\"button\" class=\"cbi-button cbi-button-apply\" value=\"cloudflare.com\" onclick=\"window.open('https://one.dash.cloudflare.com')\" />"))
e.description = translate("Go to the official Zero Trust website to create or manage your cloudflared tunnel")

return a
