/*
 *  cpu/s3c2440/start.S
 *
 *  U-Boot - Startup Code for S3C2440
 *
 *  Board/mini2440
 *
 * @allenliu
 */
 
 .text
 .global _start
 _start:
	b	reset
	ldr	pc, _undefined_instruction
	ldr	pc, _software_interrupt
	ldr	pc, _prefetch_abort
	ldr	pc, _data_abort
	ldr	pc, _not_used
	ldr	pc, _irq
	ldr	pc, _fiq

_undefined_instruction:
	.word undefined_instruction
_software_interrupt:
	.word software_interrupt
_prefetch_abort:
	.word prefetch_abort
_data_abort:
	.word data_abort
_not_used:
	.word not_used
_irq:
	.word irq
_fiq:
	.word fiq
	
undefined_instruction:
	nop
software_interrupt:
	nop
prefetch_abort:
	nop
data_abort:
	nop
not_used:
	nop
irq:
	nop
fiq:
	nop
reset:
	bl set_svc
	@bl set_peri_port	@6410中的外围基地址初始化
	bl disable_watchdog
	bl disable_interrupt
	bl disable_mmu
	bl light_led

/*
*设置svc模式
*将cpsr模式选择位[4:0]设置为0b10011
*同时将中断位关闭
*cpsr后8位设置为0b11010011
*/

set_svc:
		mrs r0, cpsr		@将cpsr中数据保存到r0寄存器
		bic r0, r0, #0x1f	@第5位置0
		orr r0, r0, #0xd3	@设置0b11010011->svc下且屏蔽FIQ/IRQ
		msr cpsr, r0		@数据写入cpsr
		mov pc, lr		@返回reset

/*
*对6410，使用外设的前提之一是要对外围设备基地址初始化为70000000
*控制寄存器为CP15的寄存器
*只有6410，需要此操作
*
*/
		
set_peri_port:
	ldr r0, =0x70000000		@r0=0x70000000
	orr r0, r0, #0x13		@ro=0x70000013
	mcr p15,0,r0,c15,c2,4		@写入cp15
	mov pc, lr			@返回

/*
*关闭看门狗
*2440中，看门狗由寄存器WTCON控制
*寄存器地址为0x53000000
*第5位位看门狗关闭启动控制位
*/	
	
#define WTCON 0x53000000		@定义寄存器WTCON	
disable_watchdog:
		ldr r0, =WTCON		@r0=0x53000000
		mov r1, #0x0		@
		str r1, [r0]		@将r1值写入[0x53000000]，即置0
		mov pc, lr		@返回

/*
*关闭中断
*2440中，关闭中断需要两个操作
*一、设置cpsr对应位置
*二、设置中断屏蔽位置
*第一步已经在上面设置svc时操作过，因此，这里只操作第二步
*2440中，中断屏蔽由寄存器INTMSK控制
*寄存器地址为0X4A000008
*设置为1则屏蔽
*/

#define INTMSK 0x4a000008		@定义寄存器WTCON
disable_interrupt:
	mvn r1, #0x0			@全0取反，变为全1
	ldr r0, =INTMSK			@
	str r1, [r0]			@将r1值写入[0x4a000008]，即置1
	mov pc, lr			@返回
	
/*
*关闭I/D Cache MMU
*2440中，关闭I/D Cache MMU由协处理器操作指令来完成，分两步
*一、让I/D Cache失效
*二、关闭I/D Cache，MMU
*2440中，关闭I/D Cache MMU于协处理CP15的r1,r7有关
*
*/

disable_mmu:
	mcr p15,0,r0,c7,c7,0		@让I/D Cache失效
	mrc p15,0,r0,c1,c0,0		@读取CP15的r1寄存器
	bic r0, r0, #0x00000007		@设置为0b0111，DCach和MMU关闭，ICache未处理
	mcr p15,0,r0,c1,c0,0		@对CP15的r1寄存器写值
	mov pc, lr			@返回

/*
*点亮LED
*点亮LED分两步
*一、将电路图对应的GPIO口设置为输出模式
*二、根据电路图，将对应引脚输出设置为高或者低电平
*设置输出模式对应寄存器为GPXCON
*输出数据设置对应寄存器为GPCDAT
*mini2440使用的是GPB接口，寄存器地址对应为GPBCON 0x56000010/GPBDAT 0x56000014
*mini2440中，LED使用GPB5，6，7，8引脚
*/
	
#define GPBCON 0x56000010		@定义寄存器GPBCON
#define GPBDAT 0x56000014		@定义寄存器GPBDAT
light_led:
	ldr r0, =GPBCON			@
	ldr r1, =0x15400		@0b 0001 0101 0100 0000 0000
	str r1, [r0]			@设置GPB5,6,7,8为输出
	
	ldr r0, =GPBDAT
	ldr r1, =0x73f			@0b 110 1011 1111
	str r1, [r0]			@设置为5,7灭，6,8亮
	
	mov pc, lr			@返回
	
