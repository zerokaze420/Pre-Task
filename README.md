# 最终能达到的效果

arm 可以编译出来 docker 并且可以运行（但是因为网络配置问题无法下载镜像）， riscv 不能编译出来 排查到了 musl 和 golang 的问题 ，但是 moby 本身并不官方支持 riscv 加上工具链缺失的原因无法确认



<img width="86" height="97" alt="图片" src="https://github.com/user-attachments/assets/1f1644dd-97a8-46dc-821f-fcb5c8727189" />



> 前3天用的是 milkv duo 255m + ssh ,因为 dos 和 USB-TTL 串口线不在手上\
> 编译使用的是 buildroot\
> 编译环境采用的一开始使用 Ubuntu 22.04.5 ， 后面使用 docker 避免环境造成的误差\
> 配置文件使用 `Buildroot SDK V2`


## 配置编译中参考了以下文档以及资料 

[mlikv 官方文档](https://milkv.io/zh/docs/duo/overview)

[[Buildroot] crucible: Build failure on riscv64/mips64el ](https://lists.buildroot.org/pipermail/buildroot/2024-September/763767.html)


[Statically compiled Go programs, always, even with cgo, using musl](https://honnef.co/articles/statically-compiled-go-programs-always-even-with-cgo-using-musl/)


[How to compile kernel modules](https://community.milkv.io/t/how-to-compile-kernel-modules/3212/1)

[Error runing Docker on Duo256](https://community.milkv.io/t/error-runing-docker-on-duo256/2632)


[Adding support for RISC-V](https://github.com/moby/moby/issues/44319)\


# Day 1


 今天4点刚刚拿到开发板 ， 准备开始作手安装系统
 使用 BalenaEtcher 进行烧录



# Day 2

开发环境本机通过 zed remote 开发 ，  使用官方的 buildroot 生成镜像后通过 SCP 本机烧录到开发板

```bash
OS: Ubuntu 22.04.5 LTS x86_64
Host: KVM/QEMU Standard PC (i440FX + PIIX, 1996) (pc-i440fx-8.1)
Kernel: Linux 6.8.0-65-generic
Uptime: 7 days, 2 hours, 31 mins
Packages: 2085 (dpkg), 60 (nix-default), 10 (snap)
Shell: fish 3.3.1
Display (QEMU Monitor): 1280x800 @ 75 Hz in 15"
Terminal: /dev/pts/7
CPU: QEMU Virtual version 2.5+ (16) @ 2.50 GHz
GPU: Unknown Device 1111 (VGA compatible)
Memory: 29.65 GiB / 47.04 GiB (63%)
Swap: 0 B / 2.00 GiB (0%)
Disk (/): 14.30 GiB / 59.97 GiB (24%) - zfs
Local IP (ens18): 192.168.3.103/24
Locale: en_US.UTF-8
```


根据 `Buildroot SDK V2` 文档添加 `Docker` 软件包编译， 速度感人一次耗时60分钟

>https://milkv.io/zh/docs/duo/getting-started/buildroot-sdk

编译错误

```bash
/home/bytedream/workspace/duo-buildroot-sdk-v2/buildroot/utils/brmake -j16 -C /home/bytedream/workspace/duo-buildroot-sdk-v2/buildroot
2025-08-15T15:47:25 >>> containerd 2.0.2 Building
2025-08-15T15:47:25 >>> docker-cli-buildx 0.16.1 Building
2025-08-15T15:47:25 >>> docker-compose 2.32.4 Patching
2025-08-15T15:47:25 >>> docker-engine 27.5.1 Building
2025-08-15T15:47:25 >>> docker-compose 2.32.4 Configuring
Done in 31s  (error code: 2)
make: *** [Makefile:621: br-rootfs-pack] Error 2
Error: Build board milkv-duo256m-musl-riscv64-sd failed!
```


> 这里排查错了 , 没看日志导致的
貌似是因为没有开启内核参数导致的。
继续排查， 发现是文件太大放不下来， 提示如下
执行 `make menuconfig` 调整到根分区为 1024M

继续执行发现还是报错



```bash
2025-08-15T19:27:48 github.com/containerd/nri/pkg/adaptation
2025-08-15T19:27:48 github.com/containerd/containerd/v2/internal/nri
2025-08-15T19:27:49 github.com/containerd/containerd/v2/plugins/nri
2025-08-15T19:27:49 github.com/containerd/containerd/v2/cmd/containerd/builtins
2025-08-15T19:27:49 github.com/containerd/containerd/v2/cmd/containerd
2025-08-15T19:27:53 # github.com/containerd/containerd/v2/cmd/containerd
2025-08-15T19:27:53 $WORK/b137/_pkg_.a(_x005.o): unknown relocation type 17; compiled without -fpic?
2025-08-15T19:27:53 make[2]: *** [package/pkg-generic.mk:273: /home/bytedream/workspace/duo-buildroot-sdk-v2/buildroot/output/milkv-duo256m-musl-riscv64-sd/build/containerd-2.0.2/.stamp_built] Error 1
2025-08-15T19:27:54 make[1]: *** [Makefile:87: _all] Error 2
2025-08-15T19:27:54 make[1]: Leaving directory '/home/bytedream/workspace/duo-buildroot-sdk-v2/buildroot'
```


在添加了编译参数，继续编译

```bash
CONTAINERD_EXTLDFLAGS += -Wl,--no-pie -Wl,-fPIC
```

继续编译， 仍然报错，问了一下 gemini


```bash
2025-08-16T09:47:04 # github.com/containerd/containerd/v2/cmd/containerd
2025-08-16T09:47:04 /home/bytedream/workspace/duo-buildroot-sdk-v2/buildroot/output/milkv-duo256m-musl-riscv64-sd/host/share/go-cache/44/44ca8e3e120cc646706961004a72d827dad202bf0f12ade40c201a1ca774da2d-d(_x005.o): unknown relocation type 17; compiled without -fpic?
2025-08-16T09:47:04 make[2]: *** [package/pkg-generic.mk:273: /home/bytedream/workspace/duo-buildroot-sdk-v2/buildroot/output/milkv-duo256m-musl-riscv64-sd/build/containerd-2.0.2/.stamp_built] Error 1
2025-08-16T09:47:04 make[1]: *** [Makefile:87: _all] Error 2
2025-08-16T09:47:04 make[1]: Leaving directory '/home/bytedream/workspace/duo-buildroot-sdk-v2/buildroot'
```


```bash
你提供的日志显示，go build 命令已经包含了 -fPIC 标志：
go build ... -ldflags "-X ... -extldflags '-Wl,--no-pie,-fPIC'"

这意味着问题并不是缺少 -fPIC 标志，而是尽管使用了该标志，编译器和链接器在处理某些代码时仍然失败了。

unknown relocation type 17 是一个非常底层、和 CGO（Go 和 C 代码的互操作性） 以及 目标架构 ABI（应用程序二进制接口） 相关的问题。它通常意味着 Go 编译器生成的代码与 C 编译器生成的对象文件（例如 _x005.o）在链接时存在某种不兼容性。这可能是因为 Go 语言版本、musl 工具链或 RISC-V 架构本身之间存在一个 Bug 或不兼容。
```






怀疑是 musl 的问题 ， 尝试使用 glic , 发现切换后还是 报错 ，缺少工具链支持 


```bash
Done in 1min 55s  (error code: 2)make: *** [Makefile:621: br-rootfs-pack] Error 2Error: Build board milkv-duo256m-musl-riscv64-sd failed!
```


# Day 3

继续针对 `make br-rootfs-pack` 排查

```bash
root@e458080c4150:/home/work# strace make br-rootfs-pack
execve("/usr/bin/make", ["make", "br-rootfs-pack"], 0x7fff013b7048 /* 83 vars */) = 0
brk(NULL)                               = 0x55bc60093000
arch_prctl(0x3001 /* ARCH_??? */, 0x7ffdc0893160) = -1 EINVAL (Invalid argument)
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f5cd9301000
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=14271, ...}, AT_EMPTY_PATH) = 0
mmap(NULL, 14271, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f5cd92fd000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P\237\2\0\0\0\0\0"..., 832) = 832
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0 \0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0"..., 48, 848) = 48
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0I\17\357\204\3$\f\221\2039x\324\224\323\236S"..., 68, 896) = 68
newfstatat(3, "", {st_mode=S_IFREG|0755, st_size=2220400, ...}, AT_EMPTY_PATH) = 0
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
mmap(NULL, 2264656, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f5cd90d4000
mprotect(0x7f5cd90fc000, 2023424, PROT_NONE) = 0
mmap(0x7f5cd90fc000, 1658880, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x28000) = 0x7f5cd90fc000
mmap(0x7f5cd9291000, 360448, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1bd000) = 0x7f5cd9291000
mmap(0x7f5cd92ea000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x215000) = 0x7f5cd92ea000
mmap(0x7f5cd92f0000, 52816, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f5cd92f0000
close(3)                                = 0
mmap(NULL, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f5cd90d1000
arch_prctl(ARCH_SET_FS, 0x7f5cd90d1740) = 0
set_tid_address(0x7f5cd90d1a10)         = 1656001
set_robust_list(0x7f5cd90d1a20, 24)     = 0
rseq(0x7f5cd90d20e0, 0x20, 0, 0x53053053) = 0
mprotect(0x7f5cd92ea000, 16384, PROT_READ) = 0
mprotect(0x55bc52557000, 8192, PROT_READ) = 0
mprotect(0x7f5cd9343000, 8192, PROT_READ) = 0
prlimit64(0, RLIMIT_STACK, NULL, {rlim_cur=8192*1024, rlim_max=RLIM64_INFINITY}) = 0
munmap(0x7f5cd92fd000, 14271)           = 0
getrandom("\xd7\x0b\x3c\x64\x6a\x13\x4b\x95", 8, GRND_NONBLOCK) = 8
brk(NULL)                               = 0x55bc60093000
brk(0x55bc600b4000)                     = 0x55bc600b4000
rt_sigaction(SIGHUP, {sa_handler=0x55bc5252ecd0, sa_mask=[HUP], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGQUIT, {sa_handler=0x55bc5252ecd0, sa_mask=[QUIT], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGINT, {sa_handler=0x55bc5252ecd0, sa_mask=[INT], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGTERM, {sa_handler=0x55bc5252ecd0, sa_mask=[TERM], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGXCPU, {sa_handler=0x55bc5252ecd0, sa_mask=[XCPU], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGXFSZ, {sa_handler=0x55bc5252ecd0, sa_mask=[XFSZ], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGCHLD, {sa_handler=SIG_DFL, sa_mask=[CHLD], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
fcntl(1, F_GETFL)                       = 0x8402 (flags O_RDWR|O_APPEND|O_LARGEFILE)
fcntl(1, F_SETFL, O_RDWR|O_APPEND|O_LARGEFILE) = 0
fcntl(2, F_GETFL)                       = 0x8402 (flags O_RDWR|O_APPEND|O_LARGEFILE)
fcntl(2, F_SETFL, O_RDWR|O_APPEND|O_LARGEFILE) = 0
fcntl(1, F_GETFD)                       = 0
getcwd("/home/work", 4096)              = 11
ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
newfstatat(1, "", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}, AT_EMPTY_PATH) = 0
readlink("/proc/self/fd/1", "/dev/pts/1", 4095) = 10
newfstatat(AT_FDCWD, "/dev/pts/1", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}, 0) = 0
ioctl(2, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(2, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(2, TCGETS, {B38400 opost isig icanon echo ...}) = 0
newfstatat(2, "", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}, AT_EMPTY_PATH) = 0
readlink("/proc/self/fd/2", "/dev/pts/1", 4095) = 10
newfstatat(AT_FDCWD, "/dev/pts/1", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}, 0) = 0
newfstatat(AT_FDCWD, "/usr/gnu/include", 0x7ffdc08918a0, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "/usr/local/include", {st_mode=S_IFDIR|0755, st_size=0, ...}, 0) = 0
newfstatat(AT_FDCWD, "/usr/include", {st_mode=S_IFDIR|0755, st_size=2084, ...}, 0) = 0
newfstatat(AT_FDCWD, "/usr/include", {st_mode=S_IFDIR|0755, st_size=2084, ...}, 0) = 0
rt_sigaction(SIGCHLD, {sa_handler=0x55bc52534dc0, sa_mask=[CHLD], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[CHLD], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, 8) = 0
rt_sigprocmask(SIG_SETMASK, [CHLD], NULL, 8) = 0
rt_sigaction(SIGUSR1, {sa_handler=0x55bc52534a90, sa_mask=[USR1], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f5cd9116520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
brk(0x55bc600d5000)                     = 0x55bc600d5000
newfstatat(AT_FDCWD, ".", {st_mode=S_IFDIR|0755, st_size=474, ...}, 0) = 0
openat(AT_FDCWD, ".", O_RDONLY|O_NONBLOCK|O_CLOEXEC|O_DIRECTORY) = 3
newfstatat(3, "", {st_mode=S_IFDIR|0755, st_size=474, ...}, AT_EMPTY_PATH) = 0
getdents64(3, 0x55bc600b7010 /* 34 entries */, 32768) = 1032
getdents64(3, 0x55bc600b7010 /* 0 entries */, 32768) = 0
close(3)                                = 0
newfstatat(AT_FDCWD, "RCS", 0x7ffdc0891830, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "SCCS", 0x7ffdc0891830, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "GNUmakefile", 0x7ffdc088f750, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "makefile", 0x7ffdc088f750, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "Makefile", 0x7ffdc088f750, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "br-rootfs-pack", 0x7ffdc088f640, 0) = -1 ENOENT (No such file or directory)
write(2, "make: *** No rule to make target"..., 58make: *** No rule to make target 'br-rootfs-pack'.  Stop.
) = 58
chdir("/home/work")                     = 0
close(1)                                = 0
exit_group(2)                           = ?
+++ exited with 2 +++
root@e458080c4150:/home/work# 
```

继续按搜索报错， 发现是文件打开错误 ， 切换了一个目录



```bash

root@e458080c4150:/home/work/buildroot/output/milkv-duo256m-musl-riscv64-sd# make br-rootfs-pack
make[1]: *** No rule to make target 'br-rootfs-pack'.  Stop.
make: *** [Makefile:23: _all] Error 2
root@e458080c4150:/home/work/buildroot/output/milkv-duo256m-musl-riscv64-sd# strace make br-rootfs-pack
execve("/usr/bin/make", ["make", "br-rootfs-pack"], 0x7ffe294cfe28 /* 83 vars */) = 0
brk(NULL)                               = 0x55e61fac3000
arch_prctl(0x3001 /* ARCH_??? */, 0x7ffe7c38d900) = -1 EINVAL (Invalid argument)
mmap(NULL, 8192, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f1218ffd000
access("/etc/ld.so.preload", R_OK)      = -1 ENOENT (No such file or directory)
openat(AT_FDCWD, "/etc/ld.so.cache", O_RDONLY|O_CLOEXEC) = 3
newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=14271, ...}, AT_EMPTY_PATH) = 0
mmap(NULL, 14271, PROT_READ, MAP_PRIVATE, 3, 0) = 0x7f1218ff9000
close(3)                                = 0
openat(AT_FDCWD, "/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
read(3, "\177ELF\2\1\1\3\0\0\0\0\0\0\0\0\3\0>\0\1\0\0\0P\237\2\0\0\0\0\0"..., 832) = 832
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
pread64(3, "\4\0\0\0 \0\0\0\5\0\0\0GNU\0\2\0\0\300\4\0\0\0\3\0\0\0\0\0\0\0"..., 48, 848) = 48
pread64(3, "\4\0\0\0\24\0\0\0\3\0\0\0GNU\0I\17\357\204\3$\f\221\2039x\324\224\323\236S"..., 68, 896) = 68
newfstatat(3, "", {st_mode=S_IFREG|0755, st_size=2220400, ...}, AT_EMPTY_PATH) = 0
pread64(3, "\6\0\0\0\4\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0@\0\0\0\0\0\0\0"..., 784, 64) = 784
mmap(NULL, 2264656, PROT_READ, MAP_PRIVATE|MAP_DENYWRITE, 3, 0) = 0x7f1218dd0000
mprotect(0x7f1218df8000, 2023424, PROT_NONE) = 0
mmap(0x7f1218df8000, 1658880, PROT_READ|PROT_EXEC, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x28000) = 0x7f1218df8000
mmap(0x7f1218f8d000, 360448, PROT_READ, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x1bd000) = 0x7f1218f8d000
mmap(0x7f1218fe6000, 24576, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_DENYWRITE, 3, 0x215000) = 0x7f1218fe6000
mmap(0x7f1218fec000, 52816, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_FIXED|MAP_ANONYMOUS, -1, 0) = 0x7f1218fec000
close(3)                                = 0
mmap(NULL, 12288, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0) = 0x7f1218dcd000
arch_prctl(ARCH_SET_FS, 0x7f1218dcd740) = 0
set_tid_address(0x7f1218dcda10)         = 1656559
set_robust_list(0x7f1218dcda20, 24)     = 0
rseq(0x7f1218dce0e0, 0x20, 0, 0x53053053) = 0
mprotect(0x7f1218fe6000, 16384, PROT_READ) = 0
mprotect(0x55e5e8539000, 8192, PROT_READ) = 0
mprotect(0x7f121903f000, 8192, PROT_READ) = 0
prlimit64(0, RLIMIT_STACK, NULL, {rlim_cur=8192*1024, rlim_max=RLIM64_INFINITY}) = 0
munmap(0x7f1218ff9000, 14271)           = 0
getrandom("\x75\x06\xbe\xcf\x38\xe6\x73\x07", 8, GRND_NONBLOCK) = 8
brk(NULL)                               = 0x55e61fac3000
brk(0x55e61fae4000)                     = 0x55e61fae4000
rt_sigaction(SIGHUP, {sa_handler=0x55e5e8510cd0, sa_mask=[HUP], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGQUIT, {sa_handler=0x55e5e8510cd0, sa_mask=[QUIT], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGINT, {sa_handler=0x55e5e8510cd0, sa_mask=[INT], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGTERM, {sa_handler=0x55e5e8510cd0, sa_mask=[TERM], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGXCPU, {sa_handler=0x55e5e8510cd0, sa_mask=[XCPU], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGXFSZ, {sa_handler=0x55e5e8510cd0, sa_mask=[XFSZ], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
rt_sigaction(SIGCHLD, {sa_handler=SIG_DFL, sa_mask=[CHLD], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
fcntl(1, F_GETFL)                       = 0x8402 (flags O_RDWR|O_APPEND|O_LARGEFILE)
fcntl(1, F_SETFL, O_RDWR|O_APPEND|O_LARGEFILE) = 0
fcntl(2, F_GETFL)                       = 0x8402 (flags O_RDWR|O_APPEND|O_LARGEFILE)
fcntl(2, F_SETFL, O_RDWR|O_APPEND|O_LARGEFILE) = 0
fcntl(1, F_GETFD)                       = 0
getcwd("/home/work/buildroot/output/milkv-duo256m-musl-riscv64-sd", 4096) = 58
ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(1, TCGETS, {B38400 opost isig icanon echo ...}) = 0
newfstatat(1, "", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}, AT_EMPTY_PATH) = 0
readlink("/proc/self/fd/1", "/dev/pts/1", 4095) = 10
newfstatat(AT_FDCWD, "/dev/pts/1", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}, 0) = 0
ioctl(2, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(2, TCGETS, {B38400 opost isig icanon echo ...}) = 0
ioctl(2, TCGETS, {B38400 opost isig icanon echo ...}) = 0
newfstatat(2, "", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}, AT_EMPTY_PATH) = 0
readlink("/proc/self/fd/2", "/dev/pts/1", 4095) = 10
newfstatat(AT_FDCWD, "/dev/pts/1", {st_mode=S_IFCHR|0620, st_rdev=makedev(0x88, 0x1), ...}, 0) = 0
newfstatat(AT_FDCWD, "/usr/gnu/include", 0x7ffe7c38c040, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "/usr/local/include", {st_mode=S_IFDIR|0755, st_size=0, ...}, 0) = 0
newfstatat(AT_FDCWD, "/usr/include", {st_mode=S_IFDIR|0755, st_size=2084, ...}, 0) = 0
newfstatat(AT_FDCWD, "/usr/include", {st_mode=S_IFDIR|0755, st_size=2084, ...}, 0) = 0
rt_sigaction(SIGCHLD, {sa_handler=0x55e5e8516dc0, sa_mask=[CHLD], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[CHLD], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, 8) = 0
rt_sigprocmask(SIG_SETMASK, [CHLD], NULL, 8) = 0
rt_sigaction(SIGUSR1, {sa_handler=0x55e5e8516a90, sa_mask=[USR1], sa_flags=SA_RESTORER|SA_RESTART, sa_restorer=0x7f1218e12520}, {sa_handler=SIG_DFL, sa_mask=[], sa_flags=0}, 8) = 0
brk(0x55e61fb05000)                     = 0x55e61fb05000
newfstatat(AT_FDCWD, ".", {st_mode=S_IFDIR|0755, st_size=518, ...}, 0) = 0
openat(AT_FDCWD, ".", O_RDONLY|O_NONBLOCK|O_CLOEXEC|O_DIRECTORY) = 3
newfstatat(3, "", {st_mode=S_IFDIR|0755, st_size=518, ...}, AT_EMPTY_PATH) = 0
getdents64(3, 0x55e61fae70b0 /* 19 entries */, 32768) = 720
getdents64(3, 0x55e61fae70b0 /* 0 entries */, 32768) = 0
close(3)                                = 0
openat(AT_FDCWD, "Makefile", O_RDONLY)  = 3
fcntl(3, F_GETFD)                       = 0
fcntl(3, F_SETFD, FD_CLOEXEC)           = 0
newfstatat(3, "", {st_mode=S_IFREG|0644, st_size=605, ...}, AT_EMPTY_PATH) = 0
read(3, "# Automatically generated by /ho"..., 4096) = 605
read(3, "", 4096)                       = 0
close(3)                                = 0
newfstatat(AT_FDCWD, "RCS", 0x7ffe7c38bfd0, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "SCCS", 0x7ffe7c38bfd0, 0) = -1 ENOENT (No such file or directory)
newfstatat(AT_FDCWD, "Makefile", {st_mode=S_IFREG|0644, st_size=605, ...}, 0) = 0
rt_sigprocmask(SIG_BLOCK, [HUP INT QUIT TERM XCPU XFSZ], NULL, 8) = 0
newfstatat(AT_FDCWD, "/bin/sh", {st_mode=S_IFREG|0755, st_size=1396520, ...}, 0) = 0
geteuid()                               = 0
getegid()                               = 0
getuid()                                = 0
getgid()                                = 0
access("/bin/sh", X_OK)                 = 0
mmap(NULL, 36864, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS|MAP_STACK, -1, 0) = 0x7f1218dc4000
rt_sigprocmask(SIG_BLOCK, ~[], [HUP INT QUIT TERM CHLD XCPU XFSZ], 8) = 0
clone3({flags=CLONE_VM|CLONE_VFORK, exit_signal=SIGCHLD, stack=0x7f1218dc4000, stack_size=0x9000}, 88) = 1656560
munmap(0x7f1218dc4000, 36864)           = 0
rt_sigprocmask(SIG_SETMASK, [HUP INT QUIT TERM CHLD XCPU XFSZ], NULL, 8) = 0
rt_sigprocmask(SIG_UNBLOCK, [HUP INT QUIT TERM XCPU XFSZ], NULL, 8) = 0
wait4(-1, 
make[1]: *** No rule to make target 'br-rootfs-pack'.  Stop.
[{WIFEXITED(s) && WEXITSTATUS(s) == 2}], 0, NULL) = 1656560
write(2, "make: *** [Makefile:23: _all] Er"..., 38make: *** [Makefile:23: _all] Error 2
) = 38
rt_sigprocmask(SIG_BLOCK, [HUP INT QUIT TERM XCPU XFSZ], NULL, 8) = 0
rt_sigprocmask(SIG_UNBLOCK, [HUP INT QUIT TERM XCPU XFSZ], NULL, 8) = 0
chdir("/home/work/buildroot/output/milkv-duo256m-musl-riscv64-sd") = 0
close(1)                                = 0
exit_group(2)                           = ?
+++ exited with 2 +++
```


没招了

发现 github issues 有类似的问题 ， 看不懂




>https://lists.buildroot.org/pipermail/buildroot/2024-September/763767.html
>https://honnef.co/articles/statically-compiled-go-programs-always-even-with-cgo-using-musl/

继续排查 ， 发现是工具链问题


```bash
2025-08-17T00:26:38 ln: failed to create symbolic link '/home/work/buildroot/output/milkv-duo256m-musl-riscv64-sd/host/riscv64-buildroot-linux-musl/sysroot/lib64/lp64d': No such file or directory
2025-08-17T00:26:38 ln: failed to create symbolic link '/home/work/buildroot/output/milkv-duo256m-musl-riscv64-sd/host/riscv64-buildroot-linux-musl/sysroot/usr/lib64/lp64d': No such file or directory
2025-08-17T00:26:38 make[1]: *** [package/pkg-generic.mk:312: /home/work/buildroot/output/milkv-duo256m-musl-riscv64-sd/build/toolchain-external-custom/.stamp_staging_installed] Error 1
```






# day 4



发现 arm glic 可以直接编译成功 。并且可以通过配置 kernel 可以成功运行 ， 更加确定了关键原因是 musl 


```bash
[root@milkv-duo]~# docker -v
Docker version 27.5.1, build 27.5.1
[root@milkv-duo]~# cat /etc/os-release 
NAME=Buildroot
VERSION=-ge7b0c7933-dirty
ID=buildroot
VERSION_ID=2025.02
PRETTY_NAME="Buildroot 2025.02"
[root@milkv-duo]~# 
```


查阅资料发现 musl 很难编译出来 docker ，于是准备去参考一下 alpine 和 gentoo 的 构建脚本

>https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/community/docker/APKBUILD
>https://gitweb.gentoo.org/repo/gentoo.git/tree/app-containers/docker/docker-28.2.2.ebuild

# day 5


整理了一下资料以及报错信息


