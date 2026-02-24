<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'

interface BreadcrumbItem {
  title: string
  path?: string
}

const route = useRoute()
const router = useRouter()

const breadcrumbs = computed<BreadcrumbItem[]>(() => {
  const items: BreadcrumbItem[] = [{ title: '首页', path: '/dashboard' }]

  const matched = route.matched.filter(
    (r) => r.meta.title && r.path !== '/' && r.path !== '/dashboard',
  )

  for (const r of matched) {
    items.push({
      title: r.meta.title as string,
      path: r.path,
    })
  }

  return items
})

function handleClick(item: BreadcrumbItem): void {
  if (item.path && item.path !== route.path) {
    router.push(item.path)
  }
}
</script>

<template>
  <el-breadcrumb class="breadcrumb-container" separator="/">
    <el-breadcrumb-item
      v-for="(item, index) in breadcrumbs"
      :key="item.path ?? index"
    >
      <span
        v-if="index < breadcrumbs.length - 1 && item.path"
        class="breadcrumb-link"
        @click="handleClick(item)"
      >
        {{ item.title }}
      </span>
      <span v-else class="breadcrumb-current">{{ item.title }}</span>
    </el-breadcrumb-item>
  </el-breadcrumb>
</template>

<style scoped lang="scss">
.breadcrumb-container {
  display: flex;
  align-items: center;
  font-size: 14px;
}

.breadcrumb-link {
  cursor: pointer;
  color: var(--el-text-color-regular);
  transition: color 0.2s;

  &:hover {
    color: var(--el-color-primary);
  }
}

.breadcrumb-current {
  color: var(--el-text-color-primary);
  font-weight: 500;
}
</style>
