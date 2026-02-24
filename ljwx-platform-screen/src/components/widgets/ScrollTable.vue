<script setup lang="ts">
import { ref, onMounted, onUnmounted, watch } from 'vue'

interface TableColumn {
  key: string
  label: string
  width?: string
}

interface ScrollTableProps {
  columns: TableColumn[]
  data: Record<string, string | number>[]
  rowHeight?: number
  visibleRows?: number
  interval?: number
}

const props = withDefaults(defineProps<ScrollTableProps>(), {
  rowHeight: 40,
  visibleRows: 5,
  interval: 2000,
})

const scrollOffset = ref(0)
const currentIndex = ref(0)
let timer: ReturnType<typeof setInterval> | null = null

function startScroll() {
  if (props.data.length <= props.visibleRows) return
  timer = setInterval(() => {
    currentIndex.value = (currentIndex.value + 1) % props.data.length
    scrollOffset.value = currentIndex.value * props.rowHeight
  }, props.interval)
}

function stopScroll() {
  if (timer !== null) {
    clearInterval(timer)
    timer = null
  }
}

watch(
  () => props.data,
  () => {
    stopScroll()
    currentIndex.value = 0
    scrollOffset.value = 0
    startScroll()
  },
)

onMounted(() => {
  startScroll()
})

onUnmounted(() => {
  stopScroll()
})
</script>

<template>
  <div class="scroll-table">
    <div class="scroll-table__header">
      <div
        v-for="col in props.columns"
        :key="col.key"
        class="scroll-table__cell scroll-table__cell--header"
        :style="{ width: col.width ?? 'auto', flex: col.width ? 'none' : '1' }"
      >
        {{ col.label }}
      </div>
    </div>
    <div
      class="scroll-table__body"
      :style="{ height: `${props.rowHeight * props.visibleRows}px`, overflow: 'hidden' }"
    >
      <div
        class="scroll-table__inner"
        :style="{ transform: `translateY(-${scrollOffset}px)`, transition: 'transform 0.5s ease' }"
      >
        <div
          v-for="(row, idx) in props.data"
          :key="idx"
          class="scroll-table__row"
          :class="{ 'scroll-table__row--odd': idx % 2 === 1 }"
          :style="{ height: `${props.rowHeight}px` }"
        >
          <div
            v-for="col in props.columns"
            :key="col.key"
            class="scroll-table__cell"
            :style="{ width: col.width ?? 'auto', flex: col.width ? 'none' : '1' }"
          >
            {{ row[col.key] }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.scroll-table {
  width: 100%;
  font-size: 13px;
  color: #c0caf5;

  &__header {
    display: flex;
    background: rgba(0, 212, 255, 0.1);
    border-bottom: 1px solid rgba(0, 212, 255, 0.2);
  }

  &__body {
    position: relative;
  }

  &__inner {
    will-change: transform;
  }

  &__row {
    display: flex;
    align-items: center;
    border-bottom: 1px solid rgba(255, 255, 255, 0.04);

    &--odd {
      background: rgba(255, 255, 255, 0.02);
    }

    &:hover {
      background: rgba(0, 212, 255, 0.05);
    }
  }

  &__cell {
    padding: 0 12px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;

    &--header {
      padding: 8px 12px;
      font-size: 12px;
      color: #7a8ab8;
      font-weight: 600;
    }
  }
}
</style>
