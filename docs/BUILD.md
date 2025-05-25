>  基于ubuntu，x86_64(thinkpad x230t), 对ubuntu-riscv有依赖
>
>  



---

## 依赖

1. **apt包**

```
sudo apt update && sudo apt install -y gcc-riscv64-linux-gnu debootstrap qemu-system-riscv64 \
     libssl-dev device-tree-compiler python3-pip flex bison bc \
     linux-tools-common libelf-dev libdw-dev zlib1g-dev
```


2. **环境声明（可选）**

```
export WORKSPACE=/<path-to-workspace>
export ROOTFS=$WORKSPACE/rootfs
export LINUX=$WORKSPACE/linux
export QEMU=$WORKSPACE/qemu
export SYSROOT=$ROOTFS/temp-rootfs
cd $WORKSPACE
```



## 工具构建和制定

1. **qemu-riscv**

```
git clone --depth=1 -b ctr_upstream --recurse-submodules -j8 https://github.com/rajnesh-kanwal/qemu.git $QEMU
cd $QEMU
mkdir build && cd ./build
../configure --target-list="riscv64-softmmu" --enable-plugins
make -j$(nproc)
cd ../roms/
make opensbi64-generic
```

2. **linux kernel**


```
git clone --depth=1 -b ctr_upstream -j8 https://github.com/rajnesh-kanwal/linux.git $LINUX
cd $LINUX
export ARCH=riscv
export CROSS_COMPILE=riscv64-unknown-linux-gnu-
mkdir build
make O=./build defconfig
make O=./build -j$(nproc)
cd ..
```

3. **rootfs**
   - 预备rootfs

```
mkdir $ROOTFS && cd $ROOTFS
wget https://raw.githubusercontent.com/rajnesh-kanwal/common_work/main/rootfs_related/create_rootfs.sh
chmod +x ./create_rootfs.sh
./create_rootfs.sh

```

4. **crossing-compile perf**
   - 这是重点的步骤，因为参考是无法完全在这使用的

```
cd $LINUX/tools/perf
sudo -E PKG_CONFIG_LIBDIR="$SYSROOT/usr/lib/riscv64-linux-gnu/pkgconfig/"   VF=1 make EXTRA_CFLAGS="--sysroot=$SYSROOT"   ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu-   NO_LIBBPF=1 prefix='$(SYSROOT)/usr' NO_LIBAUDIT=1 NO_LIBBPF=1 ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu-  install
```

5. **run**
   - 制作镜像文件和启动


```
cd $ROOTFS
dd if=/dev/zero of=rootfs.ext4 bs=1G count=4
mkfs.ext4 rootfs.ext4
mkdir ./tmp
sudo mount rootfs.ext4 ./tmp
sudo cp -rp ./temp-rootfs/* ./tmp/
sudo umount ./tmp
$QEMU/build/qemu-system-riscv64 -M virt,aia=aplic-imsic,aia-guests=5 -cpu rv64,smaia=true,ssaia=true,smcdeleg=true,ssccfg=true,smcntrpmf=true,sscofpmf=true,sscsrind=true,smcsrind=true,smctr=true,ssctr=true  -icount auto -m 8192 -nographic -kernel $LINUX/build/arch/riscv/boot/Image -append "root=/dev/vda  rw console=ttyS0 earlycon=sbi" -drive file=$ROOTFS/rootfs.ext4,format=raw,if=none,id=rootfs -device virtio-blk-pci,drive=rootfs  -netdev user,id=usernet,hostfwd=tcp:127.0.0.1:7722-0.0.0.0:22 -device e1000e,netdev=usernet
```

自此可以开始测试工作

![](../images/1.png)

## 测试
详见文件夹下的另外两个文件，HPM_TEST_REPORT.md和HPM_TEST_SAMPLE.md
1. [运行](./HPM_TEST_REPORT.md)
2. [测试](./HPM_TEST_SAMPLE.md)

