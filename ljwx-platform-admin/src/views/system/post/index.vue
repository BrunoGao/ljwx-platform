<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type { PostVO, PostCreateDTO, PostUpdateDTO, PostQueryDTO } from '@/api/post'
import { getPostList, createPost, updatePost, deletePost } from '@/api/post'

// ─── 查询表单 ────────────────────────────────────────────────
const queryForm = reactive<PostQueryDTO>({
  postCode: '',
  postName: '',
  status: '',
})

function handleQuery(): void {
  loadList()
}

function handleReset(): void {
  queryForm.postCode = ''
  queryForm.postName = ''
  queryForm.status = ''
  loadList()
}

// ─── 表格数据 ────────────────────────────────────────────────
const loading = ref(false)
const tableData = ref<PostVO[]>([])
const total = ref(0)
const pageNum = ref(1)
const pageSize = ref(10)

async function loadList(): Promise<void> {
  loading.value = true
  try {
    const params: PostQueryDTO = {
      ...queryForm,
      pageNum: pageNum.value,
      pageSize: pageSize.value,
    }
    const result = await getPostList(params)
    tableData.value = result.rows
    total.value = result.total
  } finally {
    loading.value = false
  }
}

function handlePageChange(page: number): void {
  pageNum.value = page
  loadList()
}

function handleSizeChange(size: number): void {
  pageSize.value = size
  pageNum.value = 1
  loadList()
}

// ─── 弹窗状态 ────────────────────────────────────────────────
const dialogVisible = ref(false)
const dialogTitle = ref('新增岗位')
const editingId = ref<number | null>(null)
const formRef = ref<FormInstance>()

interface PostForm {
  postCode: string
  postName: string
  postSort: number
  status: string
  remark: string
}

const formData = reactive<PostForm>({
  postCode: '',
  postName: '',
  postSort: 0,
  status: 'ENABLED',
  remark: '',
})

const rules: FormRules<PostForm> = {
  postCode: [{ required: true, message: '请输入岗位编码', trigger: 'blur' }],
  postName: [{ required: true, message: '请输入岗位名称', trigger: 'blur' }],
  postSort: [{ required: true, message: '请输入显示顺序', trigger: 'blur' }],
  status: [{ required: true, message: '请选择状态', trigger: 'change' }],
}

function openCreate(): void {
  editingId.value = null
  dialogTitle.value = '新增岗位'
  formData.postCode = ''
  formData.postName = ''
  formData.postSort = 0
  formData.status = 'ENABLED'
  formData.remark = ''
  dialogVisible.value = true
}

function openEdit(row: PostVO): void {
  editingId.value = row.id
  dialogTitle.value = '编辑岗位'
  formData.postCode = row.postCode
  formData.postName = row.postName
  formData.postSort = row.postSort
  formData.status = row.status
  formData.remark = row.remark
  dialogVisible.value = true
}

async function handleSubmit(): Promise<void> {
  try {
    await formRef.value?.validate()
  } catch {
    return
  }
  try {
    if (editingId.value === null) {
      const createData: PostCreateDTO = {
        postCode: formData.postCode,
        postName: formData.postName,
        postSort: formData.postSort,
        status: formData.status,
        remark: formData.remark || undefined,
      }
      await createPost(createData)
      ElMessage.success('创建成功')
    } else {
      const updateData: PostUpdateDTO = {
        postCode: formData.postCode,
        postName: formData.postName,
        postSort: formData.postSort,
        status: formData.status,
        remark: formData.remark || undefined,
      }
      await updatePost(editingId.value, updateData)
      ElMessage.success('更新成功')
    }
    dialogVisible.value = false
    loadList()
  } catch {
    // error handled by interceptor
  }
}

async function handleDelete(row: PostVO): Promise<void> {
  try {
    await ElMessageBox.confirm(`确定删除岗位 "${row.postName}" 吗？`, '删除确认', { type: 'warning' })
    await deletePost(row.id)
    ElMessage.success('删除成功')
    loadList()
  } catch {
    // cancelled or error
  }
}

onMounted(() => {
  loadList()
})
</script>

<template>
  <div class="page-container">
    <!-- 查询表单 -->
    <el-card shadow="never" class="search-card">
      <el-form :model="queryForm" inline>
        <el-form-item label="岗位编码">
          <el-input v-model="queryForm.postCode" placeholder="请输入岗位编码" clearable />
        </el-form-item>
        <el-form-item label="岗位名称">
          <el-input v-model="queryForm.postName" placeholder="请输入岗位名称" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryForm.status" placeholder="请选择状态" clearable>
            <el-option label="启用" value="ENABLED" />
            <el-option label="禁用" value="DISABLED" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 表格 -->
    <el-card shadow="never" class="table-card">
      <template #header>
        <div class="card-header">
          <span>岗位列表</span>
          <el-button type="primary" @click="openCreate">新增岗位</el-button>
        </div>
      </template>
      <el-table v-loading="loading" :data="tableData" border stripe>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="postCode" label="岗位编码" width="150" />
        <el-table-column prop="postName" label="岗位名称" width="150" />
        <el-table-column prop="postSort" label="显示顺序" width="100" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag :type="row.status === 'ENABLED' ? 'success' : 'danger'" size="small">
              {{ row.status === 'ENABLED' ? '启用' : '禁用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" link size="small" @click="openEdit(row)">编辑</el-button>
            <el-button type="danger" link size="small" @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        v-model:current-page="pageNum"
        v-model:page-size="pageSize"
        :total="total"
        :page-sizes="[10, 20, 50, 100]"
        layout="total, sizes, prev, pager, next, jumper"
        @current-change="handlePageChange"
        @size-change="handleSizeChange"
      />
    </el-card>

    <!-- 新增/编辑弹窗 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="480px" destroy-on-close>
      <el-form ref="formRef" :model="formData" :rules="rules" label-width="90px">
        <el-form-item label="岗位编码" prop="postCode">
          <el-input v-model="formData.postCode" placeholder="请输入岗位编码" />
        </el-form-item>
        <el-form-item label="岗位名称" prop="postName">
          <el-input v-model="formData.postName" placeholder="请输入岗位名称" />
        </el-form-item>
        <el-form-item label="显示顺序" prop="postSort">
          <el-input-number v-model="formData.postSort" :min="0" style="width: 100%" />
        </el-form-item>
        <el-form-item label="状态" prop="status">
          <el-select v-model="formData.status" style="width: 100%">
            <el-option label="启用" value="ENABLED" />
            <el-option label="禁用" value="DISABLED" />
          </el-select>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="3" placeholder="请输入备注" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSubmit">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.page-container {
  padding: 0;
}

.search-card {
  margin-bottom: 16px;
}

.table-card {
  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .el-pagination {
    margin-top: 16px;
    justify-content: flex-end;
  }
}
</style>
