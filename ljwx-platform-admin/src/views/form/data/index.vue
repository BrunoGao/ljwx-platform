<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { View, Edit } from '@element-plus/icons-vue'
import {
  getFormDataList,
  getFormDataById,
  updateFormData,
  type FormDataVO,
  type FormDataQueryDTO,
  type FormDataUpdateDTO
} from '@/api/form/form-data'
import { getFormDefList, type FormDefVO } from '@/api/form/form-def'

const loading = ref(false)
const tableData = ref<FormDataVO[]>([])
const total = ref(0)
const formDefOptions = ref<FormDefVO[]>([])

const queryForm = reactive<FormDataQueryDTO>({
  formDefId: 0,
  creatorId: undefined,
  startTime: undefined,
  endTime: undefined,
  pageNum: 1,
  pageSize: 10
})

const dialogVisible = ref(false)
const dialogTitle = ref('')
const currentId = ref<number>()
const currentFormData = ref<FormDataVO>()

async function fetchFormDefs() {
  try {
    const res = await getFormDefList({ pageNum: 1, pageSize: 100, status: 1 })
    formDefOptions.value = res.data.rows
  } catch (error) {
    ElMessage.error('获取表单定义失败')
  }
}

async function fetchList() {
  if (!queryForm.formDefId) {
    ElMessage.warning('请先选择表单定义')
    return
  }

  loading.value = true
  try {
    const res = await getFormDataList(queryForm)
    tableData.value = res.data.rows
    total.value = res.data.total
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryForm.pageNum = 1
  fetchList()
}

function handleReset() {
  queryForm.formDefId = 0
  queryForm.creatorId = undefined
  queryForm.startTime = undefined
  queryForm.endTime = undefined
  queryForm.pageNum = 1
  tableData.value = []
  total.value = 0
}

async function handleView(row: FormDataVO) {
  dialogTitle.value = '查看表单数据'
  currentId.value = row.id
  try {
    const res = await getFormDataById(row.id)
    currentFormData.value = res.data
    dialogVisible.value = true
  } catch (error) {
    ElMessage.error('获取详情失败')
  }
}

function handlePageChange(page: number) {
  queryForm.pageNum = page
  fetchList()
}

onMounted(() => {
  fetchFormDefs()
})
</script>

<template>
  <div class="form-data-container">
    <el-card class="search-card">
      <el-form :model="queryForm" inline>
        <el-form-item label="表单定义" required>
          <el-select v-model="queryForm.formDefId" placeholder="请选择表单定义" clearable style="width: 200px">
            <el-option
              v-for="form in formDefOptions"
              :key="form.id"
              :label="form.formName"
              :value="form.id"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="填写人ID">
          <el-input v-model.number="queryForm.creatorId" placeholder="请输入填写人ID" clearable />
        </el-form-item>
        <el-form-item label="创建时间">
          <el-date-picker
            v-model="queryForm.startTime"
            type="datetime"
            placeholder="开始时间"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
          <span style="margin: 0 10px">至</span>
          <el-date-picker
            v-model="queryForm.endTime"
            type="datetime"
            placeholder="结束时间"
            value-format="YYYY-MM-DD HH:mm:ss"
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <el-table v-loading="loading" :data="tableData" border>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="formDefId" label="表单定义ID" width="120" />
        <el-table-column prop="creatorId" label="填写人ID" width="120" />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column prop="updatedTime" label="更新时间" width="180" />
        <el-table-column label="操作" width="120" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" :icon="View" link @click="handleView(row)">查看</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="queryForm.pageNum"
        v-model:page-size="queryForm.pageSize"
        :total="total"
        layout="total, prev, pager, next, jumper"
        @current-change="handlePageChange"
      />
    </el-card>

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px">
      <el-descriptions v-if="currentFormData" :column="1" border>
        <el-descriptions-item label="ID">{{ currentFormData.id }}</el-descriptions-item>
        <el-descriptions-item label="表单定义ID">{{ currentFormData.formDefId }}</el-descriptions-item>
        <el-descriptions-item label="填写人ID">{{ currentFormData.creatorId }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ currentFormData.createdTime }}</el-descriptions-item>
        <el-descriptions-item label="更新时间">{{ currentFormData.updatedTime }}</el-descriptions-item>
        <el-descriptions-item label="表单数据">
          <pre>{{ JSON.stringify(currentFormData.fieldValues, null, 2) }}</pre>
        </el-descriptions-item>
      </el-descriptions>
      <template #footer>
        <el-button @click="dialogVisible = false">关闭</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.form-data-container {
  padding: 20px;

  .search-card {
    margin-bottom: 20px;
  }

  .table-card {
    .el-pagination {
      margin-top: 20px;
      justify-content: flex-end;
    }
  }

  pre {
    background-color: #f5f5f5;
    padding: 10px;
    border-radius: 4px;
    max-height: 400px;
    overflow: auto;
  }
}
</style>
