以下是使用 `perf` 工具测试 **IOMMU** 和 **HPM (Hardware Performance Monitoring)** 的详细测试项表格，包含具体的测试步骤和预期结果：

---

### **1. IOMMU & HPM 性能事件测试表**
| **测试项**               | **测试命令**                                                 | **测试步骤**                                                 | **预期结果/监控指标**                |
| ------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------ |
| **IOMMU TLB 命中率**     | `perf stat -e iommu/tlb_read_hit/,iommu/tlb_read_miss/ -a sleep 10` | 1. 运行命令监控10秒<br>2. 同时触发DMA操作（如`dd`）<br>3. 记录命中/缺失次数 | 命中率 > 90%，无异常错误             |
| **IOMMU 上下文缓存效率** | `perf stat -e iommu/context_cache_hit/,iommu/context_cache_miss/ -a sleep 5` | 1. 多设备并发DMA操作<br>2. 观察缓存命中情况                  | 缓存命中率稳定，无剧烈波动           |
| **DMA 映射延迟**         | `perf probe -a iommu_map`<br>`perf stat -e probe:iommu_map -a sleep 5` | 1. 动态追踪`iommu_map`函数<br>2. 运行DMA操作<br>3. 统计平均延迟 | 延迟 < 50μs（依赖硬件）              |
| **IOMMU 缺页异常**       | `perf stat -e iommu/io_page_fault/ -a sleep 5`               | 1. 故意访问未映射的DMA地址<br>2. 监控缺页异常次数            | 记录到预期异常，无内核崩溃           |
| **HPM 时钟周期统计**     | `perf stat -e cycles,riscv_hpm/cycles/ -a sleep 10`          | 1. 空载运行10秒<br>2. 高负载运行（如`stress-ng`）<br>3. 对比周期数 | 负载周期数显著高于空载               |
| **内存访问带宽**         | `perf stat -e mem/loads/,mem/stores/ -a -- dd if=/dev/zero of=/dev/null bs=1G count=1` | 1. 执行大内存操作<br>2. 统计加载/存储次数                    | 带宽与硬件理论值匹配（如 DDR4 带宽） |

---

### **2. 高级追踪与分析测试表**
| **测试项**           | **测试命令**                                                 | **测试步骤**                                                 | **预期结果/监控指标**          |
| -------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------ |
| **IOMMU 函数调用链** | `perf record -e probe:iommu* -ag -- sleep 10`<br>`perf report --stdio` | 1. 动态追踪所有`iommu_*`函数<br>2. 生成调用图<br>3. 分析热点路径 | 无异常递归或阻塞调用           |
| **中断延迟分析**     | `perf sched latency`                                         | 1. 运行实时任务<br>2. 监控调度延迟<br>3. 结合IOMMU中断日志（`dmesg`） | 中断延迟 < 100μs（实时性要求） |
| **多核竞争分析**     | `perf stat -e cache-misses -C 0,1 -- stress-ng --dma 2`      | 1. 绑定DMA到特定CPU核心<br>2. 监控缓存缺失<br>3. 检查IOMMU锁竞争 | 缓存缺失率无异常飙升           |
| **PMU 自定义事件**   | `perf stat -e rXXXX -a sleep 5` (XXXX为硬件事件编码)         | 1. 查阅芯片手册定义事件编码<br>2. 监控自定义事件（如TLB预取）<br>3. 验证功能 | 事件计数器正常递增             |

---

### **3. 压力测试与故障注入表**
| **测试项**             | **测试命令**                                                 | **测试步骤**                                                 | **预期结果/监控指标** |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | --------------------- |
| **高并发 DMA 压力**    | `perf stat -e iommu/* -a -- stress-ng --dma 8 --timeout 60`  | 1. 启动8个DMA线程<br>2. 监控IOMMU事件<br>3. 检查错误日志     | 无TLB崩溃或上下文泄漏 |
| **内存碎片化下的 DMA** | `perf stat -e iommu/* -a -- stress-ng --vm 4 --vm-bytes 2G & dd if=/dev/zero of=/dev/dma bs=1G` | 1. 碎片化内存后执行DMA<br>2. 观察IOMMU页表分配延迟           | 延迟波动在合理范围内  |
| **错误恢复时间测试**   | `perf probe -a iommu_fault`<br>`perf stat -e probe:iommu_fault -a` | 1. 注入IOMMU错误（`echo 1 > /sys/kernel/debug/iommu/fault_inject`）<br>2. 测量恢复时间 | 恢复时间 < 1s         |

---




