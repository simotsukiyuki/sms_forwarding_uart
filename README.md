# sms_forwarding_uart

基于https://github.com/chenxuuu/sms_forwarding 修改。
此固件会将短信直接输出到USB用户虚拟串口里，以便上位机（如PC、树莓派、Android设备等）进行后续处理。
Release固件不含RNDIS库，如上位机还有联网需求，请自行修改脚本。

# 接收短信格式

接收到的短信会被输出为以下格式

<code>@$from$:$发件号码$,$data$:$短信的内容$@</code>

是的没错，你需要自己在上位机上处理一下它才会变成真正的JSON。
没看懂的话——
你只需要知道把最左右两边的<code>@</code>替换成<code>{和}</code>，把所有的<code>$</code>替换成<code>"</code>，它就是一个正常的json了....

# 发送短信的格式

按照下面这个json发送到串口即可。
注意需要把UTF-8格式转换为bytes[]数组，才能避免乱码。

<code>{"type":"sms","to":"收件人号码","content":"短信内容"}</code>

# 默认端口速率


> 串口波特率：115200
> 
> 数据位：8
> 
> 停止位：1
> 
> 校验位：无校验
