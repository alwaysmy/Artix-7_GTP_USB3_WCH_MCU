# 硬件

基于Xilinx XC7A35TCSG325-2

四层板设计

提供20+30对差分对，共100个引出引脚，板上包含2.5V电压，可用于LVDS外设。

引出从串加载引脚，通过拨码开关切换可以使用从串加载模式。

JTAG引脚通过板对线连接器引出，同时连接到单片机，

使用单片机模拟FT2232H可以实现一线通调试，见项目：[alwaysmy/CH32V30x_FT2232H_XilinxJtagCable](https://github.com/alwaysmy/CH32V30x_FT2232H_XilinxJtagCable)

提供到单片机CH32V305G的UART/IIC/SPI/GPIO连接。

USB-C接口连接到单片机的USBHS和FPGA的GTP.

板载125M GT时钟。

板载50M单端时钟。

FPGA引出两个LED，独占一个按键，和单片机共用一个按键BT1，

单片机引出一个LED，和FPGA共用一个按键BT1.

单片机的SWD接口和FPGA JTAG接口共用一个连接器。

板卡总功率超过1.5W最好添加散热器或空气流动。

## 单片机

8M晶振。

## 功耗

使用这个项目，[hdlguy/heater: An FPGA "heater" design to use LFSR data to toggle logic for the purpose of stressing the power supply.](https://github.com/hdlguy/heater)测试的最大逻辑功耗是3W,如果有更多的IO使用以及GTP使用，功耗会更高。3W下风冷无散热器情况下温升45℃大概(内部传感器读取).







GTP直连USB设计。可以自行开发，也可以参考Xillybus的实现，注意，Xillyusb免费授权仅限于于非商业评估应用，商业授权请自行联系。

