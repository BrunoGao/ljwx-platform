<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, View } from '@element-plus/icons-vue'
import {
  getFormDefList,
  createFormDef,
  updateFormDef,
  deleteFormDef,
  type FormDefVO,
  type FormDefQueryDTO,
  type FormDefCreateDTO,
  type FormDefUpdateDTO
} from '@/api/form/form-def'

const loading = ref(false)
const tableData = ref<FormDefVO[]>([])
const total = ref(0)

const queryForm = reactive<FormDefQueryDTO>({
  formName: '',
  formKey: '',
  status: undefined,
  pageNum: 1,
  pageSize: 10
})

const dialogVisible = ref(false)
const dialogTitle = ref('')
const isEdit = ref(false)
const currentId = ref<number>()

const formData = reactive<FormDefCreateDTO | FormDefUpdateDTO>({
  formName: '',
  formKey: '',
  schema: {},
  remark: ''
})

interface SchemaField {
  key: string
  label: string
  type: string
  required: boolean
  options?: string[]
}

interface FormSchema {
  fields?: SchemaField[]
}

const schemaFields = ref<SchemaField[]>([])

const fieldTypes = [
  { label: '单行文本', value: 'TEXT' },
  { label: '多行文本', value: 'TEXTAREA' },
  { label: '数字', value: 'NUMBER' },
  { label: '日期', value: 'DATE' },
  { label: '下拉选择', value: 'SELECT' },
  { label: '复选框', value: 'CHECKBOX' }
]

async function fetchList() {
  loading.value = true
  try {
    const res = await getFormDefList(queryForm)
    tableData.value = res.rows
    total.value = res.total
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  queryForm.pageNum = 1
  fetchList()
}

function handleReset() {
  queryForm.formName = ''
  queryForm.formKey = ''
  queryForm.status = undefined
  queryForm.pageNum = 1
  fetchList()
}

function handleAdd() {
  dialogTitle.value = '新增表单定义'
  isEdit.value = false
  currentId.value = undefined
  Object.assign(formData, {
    formName: '',
    formKey: '',
    schema: {},
    remark: ''
  })
  schemaFields.value = []
  dialogVisible.value = true
}

function handleEdit(row: FormDefVO) {
  dialogTitle.value = '编辑表单定义'
  isEdit.value = true
  currentId.value = row.id
  Object.assign(formData, {
    formName: row.formName,
    schema: row.schema,
    status: row.status,
    remark: row.remark
  })

  const schema = row.schema as FormSchema
  if (schema && Array.isArray(schema.fields)) {
    schemaFields.value = schema.fields
  } else {
    schemaFields.value = []
  }

  dialogVisible.value = true
}

async function handleDelete(row: FormDefVO) {
  try {
    await ElMessageBox.confirm('确认删除该表单定义吗？', '提示', {
      type: 'warning'
    })
    await deleteFormDef(row.id)
    ElMessage.success('删除成功')
    fetchList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

function addField() {
  schemaFields.value.push({
    key: '',
    label: '',
    type: 'TEXT',
    required: false,
    options: []
  })
}

function removeField(index: number) {
  schemaFields.value.splice(index, 1)
}

async function handleSubmit() {
  formData.schema = {
    fields: schemaFields.value
  }

  try {
    if (isEdit.value && currentId.value) {
      await updateFormDef(currentId.value, formData as FormDefUpdateDTO)
      ElMessage.success('更新成功')
    } else {
      await createFormDef(formData as FormDefCreateDTO)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchList()
  } catch (error) {
    ElMessage.error(isEdit.value ? '更新失败' : '创建失败')
  }
}

function handlePageChange(page: number) {
  queryForm.pageNum = page
  fetchList()
}

onMounted(() => {
  fetchList()
})
</script>

<template>
  <div class="form-designer-container">
    <el-card class="search-card">
      <el-form :model="queryForm" inline>
        <el-form-item label="表单名称">
          <el-input v-model="queryForm.formName" placeholder="请输入表单名称" clearable />
        </el-form-item>
        <el-form-item label="表单标识">
          <el-input v-model="queryForm.formKey" placeholder="请输入表单标识" clearable />
        </el-form-item>
        <el-form-item label="状态">
          <el-select v-model="queryForm.status" placeholder="请选择状态" clearable>
            <el-option label="启用" :value="1" />
            <el-option label="停用" :value="0" />
          </el-select>
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="handleQuery">查询</el-button>
          <el-button @click="handleReset">重置</el-button>
          <el-button type="primary" :icon="Plus" @click="handleAdd">新增</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <el-card class="table-card">
      <el-table v-loading="loading" :data="tableData" border>
        <el-table-column prop="id" label="ID" width="80" />
        <el-table-column prop="formName" label="表单名称" />
        <el-table-column prop="formKey" label="表单标识" />
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'danger'">
              {{ row.status === 1 ? '启用' : '停用' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="remark" label="备注" show-overflow-tooltip />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" :icon="Edit" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" :icon="Delete" link @click="handleDelete(row)">删除</el-button>
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

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="800px">
      <el-form :model="formData" label-width="100px">
        <el-form-item label="表单名称" required>
          <el-input v-model="formData.formName" placeholder="请输入表单名称" />
        </el-form-item>
        <el-form-item v-if="!isEdit" label="表单标识" required>
          <el-input v-model="(formData as FormDefCreateDTO).formKey" placeholder="小写字母+数字+下划线" />
        </el-form-item>
        <el-form-item v-if="isEdit" label="状态" required>
          <el-radio-group v-model="(formData as FormDefUpdateDTO).status">
            <el-radio :value="1">启用</el-radio>
            <el-radio :value="0">停用</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="formData.remark" type="textarea" :rows="2" />
        </el-form-item>
        <el-form-item label="表单字段">
          <div class="field-list">
            <div v-for="(field, index) in schemaFields" :key="index" class="field-item">
              <el-input v-model="field.key" placeholder="字段Key" style="width: 150px" />
              <el-input v-model="field.label" placeholder="字段名称" style="width: 150px" />
              <el-select v-model="field.type" placeholder="字段类型" style="width: 120px">
                <el-option v-for="type in fieldTypes" :key="type.value" :label="type.label" :value="type.value" />
              </el-select>
              <el-checkbox v-model="field.required">必填</el-checkbox>
              <el-button type="danger" :icon="Delete" link @click="removeField(index)">删除</el-button>
            </div>
            <el-button type="primary" :icon="Plus" @click="addField">添加字段</el-button>
          </div>
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
.form-designer-container {
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

  .field-list {
    width: 100%;

    .field-item {
      display: flex;
      gap: 10px;
      align-items: center;
      margin-bottom: 10px;
    }
  }
}
</style>
