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

