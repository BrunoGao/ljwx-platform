<script setup lang="ts">
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type {
  MsgUserInboxVO,
  MsgUserInboxQueryDTO,
} from '@/api/system/message'
import { listUserInbox, markInboxAsRead, deleteInboxMessage } from '@/api/system/message'
import type { PageResult } from '@ljwx/shared'

// ─── 列表状态 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<MsgUserInboxVO[]>([])
const total = ref(0)

const query = reactive<MsgUserInboxQueryDTO>({
  pageNum: 1,
  pageSize: 10,
  isRead: undefined,
  startTime: undefined,
  endTime: undefined,
})

async function loadData(): Promise<void> {
  loading.value = true
  try {
    const res: PageResult<MsgUserInboxVO> = await listUserInbox(query)
    tableData.value = res.rows
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function handleSearch(): void {
  query.pageNum = 1
  loadData()
}

function handleReset(): void {
  query.isRead = undefined
  query.startTime = undefined
  query.endTime = undefined
  query.pageNum = 1
  loadData()
}

function handleSizeChange(size: number): void {
  query.pageSize = size
  query.pageNum = 1
  loadData()
}

function handleCurrentChange(page: number): void {
  query.pageNum = page
  loadData()
}

// ─── 标记已读 ────────────────────────────────────────────────
async function handleMarkAsRead(row: MsgUserInboxVO): Promise<void> {
  if (row.isRead) {
    ElMessage.info('该消息已读')
    return
  }
  try {
    await markInboxAsRead(row.id)
    ElMessage.success('标记已读成功')
    loadData()
  } catch {
    // error handled by interceptor
  }
}

// ─── 删除消息 ────────────────────────────────────────────────
async function handleDelete(row: MsgUserInboxVO): Promise<void> {
  try {
    await ElMessageBox.confirm('确认删除该消息吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    })
    await deleteInboxMessage(row.id)
    ElMessage.success('删除成功')
    loadData()
  } catch (error: unknown) {
    if (error === 'cancel') {
      return
    }
    // error handled by interceptor
  }
}

// ─── 查看详情 ────────────────────────────────────────────────
const detailDialogVisible = ref(false)
const detailData = ref<MsgUserInboxVO | null>(null)

async function handleViewDetail(row: MsgUserInboxVO): Promise<void> {
  detailData.value = row
  detailDialogVisible.value = true
  // 如果未读，自动标记为已读
  if (!row.isRead) {
    try {
      await markInboxAsRead(row.id)
      loadData()
    } catch {
      // error handled by interceptor
    }
  }
}

// ─── 未读消息数 ────────────────────────────────────────────────
const unreadCount = computed(() => {
  return tableData.value.filter(item => !item.isRead).length
})

onMounted(() => {
  loadData()
})
</script>

<template>
  <div class="page-container">
    <!-- 搜索栏 -->
    <el-card class="search-card" shadow="never">
      <el-form :model="query" inline>
        <el-form-item label="阅读状态">
          <el-select v-model="query.isRead" placeholder="请选择阅读状态" clearable style="width: 120px">
            <el-option label="未读" :value="false" />
            <el-option label="已读" :value="true" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleSearch">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>
            我的收件箱
            <el-badge v-if="unreadCount > 0" :value="unreadCount" class="unread-badge" />
          </span>
        </div>
      </template>

      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column label="状态" width="80" align="center">
          <template #default="{ row }">
            <el-tag :type="row.isRead ? 'info' : 'success'" size="small">
              {{ row.isRead ? '已读' : '未读' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="title" label="消息标题" min-width="250" show-overflow-tooltip>
          <template #default="{ row }">
            <span :class="{ 'unread-title': !row.isRead }">{{ row.title }}</span>
          </template>
        </el-table-column>
        <el-table-column prop="content" label="消息内容" min-width="300" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="接收时间" width="160" />
        <el-table-column prop="readTime" label="阅读时间" width="160">
          <template #default="{ row }">
            {{ row.readTime || '-' }}
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="handleViewDetail(row)">查看</el-button>
            <el-button
              v-if="!row.isRead"
              type="success"
              link
              size="small"
              @click="handleMarkAsRead(row)"
            >
              标记已读
            </el-button>
            <el-button type="danger" link size="small" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <div class="pagination-wrapper">
        <el-pagination
          v-model:current-page="query.pageNum"
          v-model:page-size="query.pageSize"
          :total="total"
          :page-sizes="[10, 20, 50, 100]"
          layout="total, sizes, prev, pager, next, jumper"
          @size-change="handleSizeChange"
          @current-change="handleCurrentChange"
        />
      </div>
    </el-card>

    <!-- 详情弹窗 -->
    <el-dialog v-model="detailDialogVisible" title="消息详情" width="700px" destroy-on-close>
      <el-descriptions v-if="detailData" :column="1" border>
        <el-descriptions-item label="消息标题">
          <span :class="{ 'unread-title': !detailData.isRead }">{{ detailData.title }}</span>
        </el-descriptions-item>
        <el-descriptions-item label="消息内容">
          <div class="content-text">{{ detailData.content }}</div>
        </el-descriptions-item>
        <el-descriptions-item label="阅读状态">
          <el-tag :type="detailData.isRead ? 'info' : 'success'" size="small">
            {{ detailData.isRead ? '已读' : '未读' }}
          </el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="接收时间">{{ detailData.createdTime }}</el-descriptions-item>
        <el-descriptions-item label="阅读时间">{{ detailData.readTime || '-' }}</el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="detailDialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.page-container {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.search-card {
  :deep(.el-card__body) {
    padding-bottom: 0;
  }
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;

  .unread-badge {
    margin-left: 8px;
  }
}

.pagination-wrapper {
  margin-top: 16px;
  display: flex;
  justify-content: flex-end;
}

.unread-title {
  font-weight: 600;
  color: var(--el-color-primary);
}

.content-text {
  white-space: pre-wrap;
  word-break: break-word;
  max-height: 300px;
  overflow-y: auto;
  line-height: 1.6;
}
</style>
