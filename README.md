
# Day 1


 今天4点刚刚拿到开发板 ， 准备开始作手安装系统
 使用 BalenaEtcher 进行烧录



# Day 2

开发环境本机通过 zed remote 开发 ，  生成镜像后通过SCP 本机烧录到开发板

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


根据`Buildroot SDK V2` 文档添加 `Docker` 软件包编译， 速度感人

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

貌似是因为没有开启内核参数导致的。
继续排查， 发现是文件太大放不下来， 提示如下
执行 `make menuconfig` 调整到根分区为 1024M

继续执行发现还是报错



```
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



