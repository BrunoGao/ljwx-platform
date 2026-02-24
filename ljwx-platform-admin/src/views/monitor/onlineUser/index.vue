<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { OnlineUserVO } from '@/api/onlineUser'
import { getOnlineUserList, forceLogout } from '@/api/onlineUser'

const loading = ref(false)
const tableData = ref<OnlineUserVO[]>([])

async function loadData(): Promise<void> {
  loading.value = true
  try {
    tableData.value = await getOnlineUserList()
  } finally {
    loading.value = false
  }
}

async function handleForceLogout(row: OnlineUserVO): Promise<void> {
  try {
    await ElMessageBox.confirm(
      `确定强制下线用户 "${row.username}" 吗？`,
      '强制下线确认',
      { type: 'warning' },
    )
    await forceLogout(row.tokenId)
    ElMessage.success('已强制下线')
    loadData()
  } catch {
    // cancelled or error
  }
}

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="page-container">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>在线用户</span>
          <el-button @click="loadData">刷新</el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="username" label="用户名" width="120" />
        <el-table-column prop="nickname" label="昵称" width="120" />
        <el-table-column prop="ip" label="IP地址" width="140" />
        <el-table-column prop="loginTime" label="登录时间" width="160" />
        <el-table-column prop="tokenId" label="Token ID" min-width="200" show-overflow-tooltip />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button type="danger" link size="small" @click="handleForceLogout(row)">
              强制下线
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.page-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
</style>
