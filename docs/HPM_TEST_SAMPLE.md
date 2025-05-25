# 测试

在 RISC-V 架构下进行 IOMMU (Input-Output Memory Management Unit) 和 HPM (Hardware Performance Monitoring) 的全面测试，需要结合硬件特性、内核驱动和用户态工具。补充 `iommu-selftests` 的不足，以下是分步骤的测试方案：

---

### **1. 验证硬件和内核支持**
#### **检查 IOMMU 和 HPM 驱动**
```bash
# 查看内核是否启用 IOMMU
dmesg | grep -i iommu
cat /proc/cmdline | grep iommu  # 检查内核参数

# 确认 HPM 支持
ls /sys/bus/event_source/devices/ | grep hpm  # 或 pmu
perf list | grep -i hpm
```

#### **验证设备拓扑**
```bash
lspci -tv           # PCI 设备树
ls /sys/kernel/iommu_groups/  # IOMMU 分组
```

---

### **2. 基础功能测试**
#### **IOMMU 基本测试**
1. **DMA 隔离测试**  
   
   - 使用 `dd` 和 `dma_map` 测试不同设备的内存隔离
   - 通过 `iommu-selftests` 运行基础用例
   
2. **设备透传测试**  
   
   - 将设备绑定到 VFIO 驱动并验证透传：
     ```bash
     echo 0000:01:00.0 > /sys/bus/pci/devices/0000:01:00.0/driver/unbind
     echo vfio-pci > /sys/bus/pci/devices/0000:01:00.0/driver_override
     echo 0000:01:00.0 > /sys/bus/pci/drivers/vfio-pci/bind
     ```

#### **HPM 性能监控**
1. **Perf 事件采集**  
   - 监控 IOMMU 相关事件（如 TLB 命中/缺失）：
     ```bash
     perf stat -e iommu/tlb_read_hit/,iommu/tlb_read_miss/ -a sleep 5
     ```
   - 自定义 HPM 事件（需硬件支持）：
     ```bash
     perf stat -e rXXXX -a sleep 5  # XXXX 为硬件事件编码
     ```

---

### **3. 高级测试（补充 iommu-selftests 不足）**
#### **压力测试**
1. **IOMMU 内存压力测试**  
   - 使用 `stress-ng` 模拟高负载 DMA：
     ```bash
     stress-ng --dma 4 --timeout 60
     dmesg | grep -i iommu  # 检查错误日志
     ```

2. **多设备并发 DMA**  
   - 并行触发多个设备的 DMA 操作，验证 IOMMU 隔离性：
     ```bash
     for i in $(seq 1 4); do
         dd if=/dev/zero of=/dev/dma_device$i bs=1M count=100 &
     done
     wait
     ```

#### **延迟和吞吐量测试**
1. **IOMMU 映射延迟**  
   - 使用 `perf` 测量 `iommu_map`/`iommu_unmap` 内核函数延迟：
     ```bash
     perf probe -a iommu_map
     perf stat -e probe:iommu_map -a sleep 5
     ```

2. **DMA 带宽测试**  
   - 通过 `dd` 或专用工具（如 `iperf` 结合 RDMA）测量带宽：
     ```bash
     dd if=/dev/zero of=/dev/dma_device bs=1G count=10 oflag=direct
     ```

---

### **4. 故障注入测试**
#### **模拟错误场景**
1. **注入 IOMMU 错误**  
   
   - 使用 `echo` 手动触发错误（需内核支持）：
     ```bash
     echo 1 > /sys/kernel/debug/iommu/fault_inject
     dmesg | grep -i fault
     ```
   
2. **内存不足测试**  
   - 限制 IOMMU 内存池并触发 DMA：
     ```bash
     echo 1M > /sys/kernel/iommu_groups/0/limit
     dd if=/dev/zero of=/dev/dma_device bs=2M count=1  # 应失败
     ```

---

### **5. 自动化测试框架**
#### **扩展 iommu-selftests**
1. **添加自定义测试用例**  
   - 在 `tools/testing/selftests/iommu/` 中新增脚本，例如：
     ```bash
     #!/bin/bash
     # 测试 IOMMU 映射泄漏
     for i in $(seq 1 1000); do
         echo "Test $i" > /dev/dma_device
     done
     grep "iommu leak" /var/log/kern.log
     ```

2. **集成到内核 CI**  
   - 修改 `tools/testing/selftests/iommu/Makefile` 包含新测试。

---

### **6. 性能调优与监控**
#### **实时监控工具**
1. **动态跟踪**  
   
   - 使用 `ftrace` 跟踪 IOMMU 函数调用：
     ```bash
     echo 1 > /sys/kernel/debug/tracing/events/iommu/enable
     cat /sys/kernel/debug/tracing/trace_pipe
     ```
   
2. **Perf 火焰图**  
   - 生成 IOMMU 相关调用的火焰图：
     ```bash
     perf record -e iommu:* -ag -- sleep 10
     perf script | flamegraph.pl > iommu.svg
     ```

---

### **7. 参考测试工具清单**
| 工具/方法         | 用途             | 示例命令                       |
| ----------------- | ---------------- | ------------------------------ |
| `iommu-selftests` | 内核自带基础测试 | `./iommu.sh`                   |
| `perf`            | 性能事件监控     | `perf stat -e iommu/* -a`      |
| `stress-ng`       | 压力测试         | `stress-ng --dma 4`            |
| `ftrace`          | 函数调用跟踪     | `echo 1 > events/iommu/enable` |
| `vfio-pci`        | 设备透传验证     | 绑定设备到 VFIO 驱动           |

