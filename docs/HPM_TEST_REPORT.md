以这段为模板进行测试，使用perf获取结果

```
#include <linux/perf_event.h>
#include <sys/syscall.h>
#include <unistd.h>
#include <stdio.h>

static long perf_event_open(struct perf_event_attr *attr, pid_t pid,
                           int cpu, int group_fd, unsigned long flags) {
    return syscall(__NR_perf_event_open, attr, pid, cpu, group_fd, flags);
}

int main() {
    struct perf_event_attr attr = {
        .type = PERF_TYPE_HARDWARE,  // 定义类型
        .config = 0x1,               // 事件 ID
        .size = sizeof(attr),
        .disabled = 1,
        .exclude_kernel = 0,
    };

    int fd = perf_event_open(&attr, 0, -1, -1, 0);
    if (fd < 0) {
        perror("perf_event_open failed");
        return -1;
    }

    ioctl(fd, PERF_EVENT_IOC_RESET, 0);
    ioctl(fd, PERF_EVENT_IOC_ENABLE, 0);

    // 运行待测试的 IOMMU 操作（如 DMA 请求）
    run_iommu_operations();

    ioctl(fd, PERF_EVENT_IOC_DISABLE, 0);

    uint64_t count;
    read(fd, &count, sizeof(count));
    printf("IOMMU events counted: %lu\n", count);

    close(fd);
    return 0;
}
```



### 其他测试

**DMA 系统调用分析**

`root@Ubuntu-riscv64:~# perf stat -e cycles,instructions,cache-misses -a -- dd if=/dev/zero of=/dev/dma0perf stat -e cycles,instructions,cache-misses -a -- dd if=/dev/zero of=/dev/dma0 bs=1M count=100`

```
100+0 records in
100+0 records out
104857600 bytes (105 MB, 100 MiB) copied, 1.53881 s, 68.1 MB/s

 Performance counter stats for 'system wide':

        1989599136      cycles
         311198431      instructions
                 0      cache-misses

       1.999547308 seconds time elapsed
```

**自定义CSR事件**

根据我的环境状况假设8001是tlb事件

`root@Ubuntu-riscv64:~# perf stat -e r8001 -a sleep 5`

```
 Performance counter stats for 'system wide':

                 0      r8001

       5.723377930 seconds time elapsed
```

**异常事件监控**

`root@Ubuntu-riscv64:~# perf stat -e fw_misaligned_load,fw_misaligned_store -a sleep 10`

```

 Performance counter stats for 'system wide':

                 0      fw_misaligned_load
                 0      fw_misaligned_store

      10.202607953 seconds time elapsed
```

**故障注入**

`echo “随便一个数” > /sys/kernel/debug/fail_make_request`来触发DMA操作

使用`perf stat -e faults,emulation-faults -a`监控

```
 Performance counter stats for 'system wide':

                 0      faults
                 0      emulation-faults

      57.098484839 seconds time elapsed
```