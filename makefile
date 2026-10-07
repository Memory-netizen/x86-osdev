# 默认目标
all: write

# 创建磁盘镜像（16MB 平坦模式）
master.img:
	bximage -q -hd=16 -func=create -sectsize=512 -imgmode=flat $@

# 从 src/*.asm 编译出 build/*.bin
build/%.bin: src/%.asm
	@mkdir -p build
	nasm -f bin $< -o $@

# 把引导扇区写入第 1 个扇区，第二阶段写入第 2 个扇区
write: master.img build/boot.bin build/app.bin
	dd if=build/boot.bin of=master.img bs=512 count=1 conv=notrunc
	dd if=build/app.bin of=master.img bs=512 seek=1 count=4 conv=notrunc

# Bochs GUI 调试器
runb: write
	bochs -f bochsrc -q -unlock

# Bochs GUI 调试器
dbg: write
	bochs -f bochsrc -q -dbg_gui -unlock

# QEMU 正常运行
run: write
	qemu-system-i386 -rtc base=localtime -drive format=raw,file=master.img

# QEMU + GDB 调试（暂停等待连接）
dbgq: write
	qemu-system-i386 -rtc base=localtime -s -S -drive format=raw,file=master.img

# QEMU + 串口日志
runq_log: write
	qemu-system-i386 -rtc base=localtime -serial file:serial.log -drive format=raw,file=master.img

# 清理
clean:
	rm -f master.img master.img.lock serial.log
	rm -rf build

.PHONY: all write run dbg dbgq runq_log clean
