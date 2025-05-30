#!/bin/bash
CONFIGS=(
	"CONFIG_RISCV_PMU=y 		 "
	"CONFIG_IOMMU=y                  "
	"CONFIG_HW_PAGETABLE=y           "
	"CONFIG_IOMMU_DMA_SUPPORT=y      "
	"CONFIG_DMAR=y                   "
	"CONFIG_IOMMU_API=y              "
	"CONFIG_PERF_EVENTS=y            "
	"CONFIG_PERF_EVENTS_DEBUG=y      "
	"CONFIG_RISCV_IOMMU_HPM=y        "
	"CONFIG_IOMMU_PERFMON=y          "
	"CONFIG_PERF_COUNT_SW_EVENT=y    "
	"CONFIG_PERF_COUNT_HW_EVENT=y    "
	"CONFIG_PERF_SAMPLE_IP=y         "
	"CONFIG_NESTED_IOMMU=y           "
	"CONFIG_IOMMU_NESTED=y           "
	"CONFIG_IOMMU_STAGE1_SUPPORT=y   "
	"CONFIG_IOMMU_STAGE2_SUPPORT=y   "
	"CONFIG_IOMMU_IOTLB_SYNC=y       "
	"CONFIG_IOMMU_GSTAGE_FLUSH=y     "
	"CONFIG_DEBUG_IOMMU=y            "
	"CONFIG_DEBUG_HW_PAGETABLE=y     "
	"CONFIG_IOMMU_CACHE=y            "
	"CONFIG_IOMMU_PASID=y            "
	"CONFIG_IOMMU_SELFTEST=y         "
	"CONFIG_EXPERIMENTAL=y     	 "
)

for config in "${CONFIGS[@]}"; do
    grep -q "^$config" .config || echo "$config" >> .config
done

make ARCH=riscv CROSS_COMPILE=riscv64-linux-gnu- olddefconfig
