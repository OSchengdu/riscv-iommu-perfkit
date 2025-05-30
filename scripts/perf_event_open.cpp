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
