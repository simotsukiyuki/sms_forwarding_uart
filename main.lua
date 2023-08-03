-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "sms_forwarding"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

--缓存消息
local buff = {}

-- 引入必要的库文件(lua编写), 内部库不需要require
sys = require("sys")

if wdt then
    --添加硬狗防止程序卡死，在支持的设备上启用这个功能
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end
log.info("main", "sms demo")

uartid = uart.VUART_0 -- 根据实际设备选取不同的uartid

--检查一下固件版本，防止用户乱刷
do
    local fw = rtos.firmware():lower()--全转成小写
    local ver,bsp = fw:match("luatos%-soc_v(%d-)_(.+)")
    ver = ver and tonumber(ver) or nil
    local r
    if ver and bsp then
        if ver >= 1003 and bsp == "ec618" then
            r = true
        end
    end
    if not r then
        sys.timerLoopStart(function ()
            wdt.feed()
            log.info("警告","固件类型或版本不满足要求，请使用air780(ec618)v1003及以上版本固件。当前："..rtos.firmware())
        end,500)
    end

    --初始化
    local result = uart.setup(
        uartid,--串口id
        115200,--波特率
        8,--数据位
        1--停止位
    )
    log.info("notify","Init UART:"..result)
end


--订阅短信消息
sys.subscribe("SMS_INC",function(phone,data)
    --来新消息了
    --log.info("notify","sms received:",phone,data)
    table.insert(buff,{phone,data})
    sys.publish("SMS_ADD")--推个事件
end)

sys.taskInit(function()
    while true do
        print("New Msg...",collectgarbage("count"))
        while #buff > 0 do--把消息读完
            collectgarbage("collect")--防止内存不足
            local sms = table.remove(buff,1)
            local code,h, body
            local data = sms[2]
            --改动到这里（2023-7-27）
            log.info(sms[1],data)
            --输出为json，但替换json的正确格式，需要上位机进行后续处理
            uart.write(uartid,'@$from$:$'..sms[1]..'$,$data$:$'..data..'$@')
        end
        log.info("notify","Waiting for new sms~")
        print("Sleep...",collectgarbage("count"))
        sys.waitUntil("SMS_ADD")
    end
end)

uart.on(uartid, "receive", function(id, len)
    local data = json.decode(uart.read(id, len))
    if data then
        if data.type and data.to and data.content then
            if data.type=="sms" then
                log.info("notify","Sending sms to "..data.to)
                sms.send(data.to,data.content)            
            else
                log.info("warning","Not support!")
            end
        else
        log.info("warning","Not sms!")
        end
    else
        log.info("warning","Wrong json!")
    end
    
end)


-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!