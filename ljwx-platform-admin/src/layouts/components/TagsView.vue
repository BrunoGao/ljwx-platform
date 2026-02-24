<script setup lang="ts">
import { ref, watch, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { Close } from '@element-plus/icons-vue'

interface TagItem {
  path: string
  name: string
  title: string
  closable: boolean
}

const route = useRoute()
const router = useRouter()

const tags = ref<TagItem[]>([
  { path: '/dashboard', name: 'Dashboard', title: '仪表盘', closable: false },
])

const activeTag = computed(() => route.path)

watch(
  () => route.path,
  () => {
    const title = (route.meta.title as string | undefined) ?? route.path
    const name = (route.name as string | undefined) ?? route.path
    const exists = tags.value.some((t) => t.path === route.path)
    if (!exists && route.meta.requiresAuth) {
      tags.value.push({
        path: route.path,
        name,
        title,
        closable: route.path !== '/dashboard',
      })
    }
  },
  { immediate: true },
)

function handleTagClick(tag: TagItem): void {
  if (tag.path !== route.path) {
    router.push(tag.path)
  }
}

function handleClose(tag: TagItem): void {
  const idx = tags.value.findIndex((t) => t.path === tag.path)
  if (idx === -1) return
  tags.value.splice(idx, 1)

  // Navigate to adjacent tag if closing the active one
  if (tag.path === route.path) {
    const next = tags.value[idx] ?? tags.value[idx - 1]
    if (next) {
      router.push(next.path)
    }
  }
}

function handleContextClose(tag: TagItem): void {
  handleClose(tag)
}
</script>

<template>
  <div class="tags-view-container">
    <div class="tags-scroll">
      <div
        v-for="tag in tags"
        :key="tag.path"
        class="tag-item"
        :class="{ 'tag-active': tag.path === activeTag }"
        @click="handleTagClick(tag)"
      >
        <span class="tag-title">{{ tag.title }}</span>
        <el-icon
          v-if="tag.closable"
          class="tag-close"
          :size="12"
          @click.stop="handleContextClose(tag)"
        >
          <Close />
        </el-icon>
      </div>
    </div>
  </div>
</template>

<style scoped lang="scss">
.tags-view-container {
  height: 34px;
  background-color: #fff;
  border-bottom: 1px solid #e8e8e8;
  padding: 0 8px;
  display: flex;
  align-items: center;
  overflow: hidden;
}

.tags-scroll {
  display: flex;
  align-items: center;
  gap: 4px;
  overflow-x: auto;
  overflow-y: hidden;
  flex: 1;

  &::-webkit-scrollbar {
    height: 2px;
  }

  &::-webkit-scrollbar-thumb {
    background-color: #d9d9d9;
    border-radius: 1px;
  }
}

.tag-item {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 2px 8px;
  border: 1px solid #e8e8e8;
  border-radius: 3px;
  font-size: 12px;
  color: #595959;
  cursor: pointer;
  white-space: nowrap;
  flex-shrink: 0;
  transition: all 0.2s;
  background-color: #fff;

  &:hover {
    color: var(--el-color-primary);
    border-color: var(--el-color-primary-light-5);
  }

  &.tag-active {
    background-color: var(--el-color-primary);
    border-color: var(--el-color-primary);
    color: #fff;

    .tag-close {
      color: #fff;
    }
  }
}

.tag-title {
  line-height: 1;
}

.tag-close {
  color: #bfbfbf;
  border-radius: 50%;
  transition: all 0.2s;

  &:hover {
    background-color: rgba(0, 0, 0, 0.15);
    color: #fff;
  }
}
</style>
