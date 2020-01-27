## 1	概述


### 是什么？
**PODES**是**P**rocessor **O**ptmization for **D**eeply **E**mbedded **S**ystem的首字母缩写。包括传统的51指令集架构，SparcV8指令集架构，ARMv6-M指令集架构以及PIC-16指令集架构等一系列MCU Core。<br>
**PODES-M0O** 是兼容于ARMv6-M指令集架构的开源版本。**M0**指代Cortex-M0，**O**指代Open Source。
<br>
### 为什么？
做这个工作最开始的原因很简单，无聊和好玩。到后来觉得有趣，或许还有那么一点用处，所以就坚持做下来了。
<br>
### 有什么用？
O（Open Source）系列最基本的作用当然是学习和研究。稍微认真地搜索一下国内网络资源就会发现，很难找到有质量的IC设计开源项目。作者相信这个项目应该对开源社区会有助益。
<br>
### 是谁？
这不是一群人在战斗。这个项目是一个工程师在业余时间做的。
<br>
### 愿景？
使深嵌入式应用的MCU Core IP的License费用趋近于0。
<br>
### 能否达成愿景？
完全依赖于您的热心帮助！<br>
小额赞助、购买FPGA开发板、提供开发支持、甚至是一条建议或者评论，都是鼓舞PODES前行的动力。如果您有意赞助，请使用手机支付扫一扫下面的二维码：<br>
         支付宝扫一扫<br>
![](https://github.com/sunyata000/PODES-M0O/blob/master/images/alipay.jpg?raw=true"支付宝赞赏") <br>
         微信扫一扫 <br>
![](https://github.com/sunyata000/PODES-M0O/blob/master/images/wechat.jpg?raw=true"微信赞赏") <br>

<br><br>
<br>
## 2	对象和范围

PODES-M0O是一个经过专门精简优化的开源版本，定位于学习和研究。任何想研究ARMv6-M或者Cortex-M0的人或者机构都可以从PODES-M0O获得帮助和启发。

本手册是PODES-M0O IP的文档描述。内容包括：系统结构、指令集、功能模块、全部寄存器定义、以及应用接口指南。阅读本文档可以方便用户完整地理解PODES-M0O IP的设计思路和实现的功能。

PODES-M0O不做修改或者稍作改动，可以直接应用于FPGA产品。用于ASIC实现则需要一些额外的设计修改工作。
<br>
<br>
**PODES-M0O设计实现用户手册：（本文档）**<br>
   *PODES-M0O_Implementation_User_Manual_Vxx.doc*<br>
**PODES-M0O应用用户手册:**<br>
   *PODES-M0O_Application_User_Manual_Vxx.doc*<br>
**PODES-M0O评估板用户手册：**<br>
   *PODES_M0O_Evaluation_Board_User_Manual_Vxx.doc*

**Cortex-M0的相关资料，下面的文档可供参考：**<br>
   *DDI0432C_cortex_m0_r0p0_trm.pdf*<br>
   *DUI0497A_cortex_m0_r0p0_generic_ug.pdf*<br>
   *DDI0419B_arm_architecture_v6m_reference_manual_errata_markup_2_0.pdf*<br>
<br>
<br>
<br>
## 3	支持和服务

www.mcucore.club 是PODES开源项目的官方维护网站。

立足于保证PODES有用，作者会持续地维护这个项目。所有代码和文档资料的最新版本都可以从下面网站获得：
www.mcucore.club

所有的Issue Report或者优化建议，请投送到：www.mcucore.club 相关的页面，或者：podes.mcu@qq.com 。
 
