<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete } from '@element-plus/icons-vue'
import {
  getCustomFieldList,
  createCustomField,
  updateCustomField,
  deleteCustomField,
  type CustomFieldDefVO,
  type CustomFieldDefCreateDTO,
  type CustomFieldDefUpdateDTO
} from '@/api/form/custom-field'

const loading = ref(false)
const tableData = ref<CustomFieldDefVO[]>([])
const entityTypeFilter = ref<string>('USER')

const dialogVisible = ref(false)
const dialogTitle = ref('')
const isEdit = ref(false)
const currentId = ref<number>()

const formData = reactive<CustomFieldDefCreateDTO | CustomFieldDefUpdateDTO>({
  entityType: 'USER',
  fieldKey: '',
  fieldLabel: '',
  fieldType: 'TEXT',
  required: false,
  sortOrder: 0,
  options: []
})

const entityTypes = [
  { label: '用户', value: 'USER' },
  { label: '部门', value: 'DEPT' }
]

const fieldTypes = [
  { label: '单行文本', value: 'TEXT' },
  { label: '数字', value: 'NUMBER' },
  { label: '日期', value: 'DATE' },
  { label: '下拉选择', value: 'SELECT' },
  { label: '复选框', value: 'CHECKBOX' }
]

const optionInput = ref('')

async function fetchList() {
  loading.value = true
  try {
    tableData.value = await getCustomFieldList(entityTypeFilter.value)
  } finally {
    loading.value = false
  }
}

function handleQuery() {
  fetchList()
}

function handleReset() {
  entityTypeFilter.value = 'USER'
  fetchList()
}

function handleAdd() {
  dialogTitle.value = '新增自定义字段'
  isEdit.value = false
  currentId.value = undefined
  Object.assign(formData, {
    entityType: 'USER',
    fieldKey: '',
    fieldLabel: '',
    fieldType: 'TEXT',
    required: false,
    sortOrder: 0,
    options: []
  })
  optionInput.value = ''
  dialogVisible.value = true
}

function handleEdit(row: CustomFieldDefVO) {
  dialogTitle.value = '编辑自定义字段'
  isEdit.value = true
  currentId.value = row.id
  Object.assign(formData, {
    entityType: row.entityType,
    fieldLabel: row.fieldLabel,
    required: row.required,
    sortOrder: row.sortOrder,
    options: row.options || []
  })
  optionInput.value = ''
  dialogVisible.value = true
}

async function handleDelete(row: CustomFieldDefVO) {
  try {
    await ElMessageBox.confirm('确认删除该自定义字段吗？', '提示', {
      type: 'warning'
    })
    await deleteCustomField(row.id)
    ElMessage.success('删除成功')
    fetchList()
  } catch (error) {
    if (error !== 'cancel') {
      ElMessage.error('删除失败')
    }
  }
}

function addOption() {
  if (!optionInput.value.trim()) {
    ElMessage.warning('请输入选项内容')
    return
  }
  if (!formData.options) {
    formData.options = []
  }
  formData.options.push(optionInput.value.trim())
  optionInput.value = ''
}

function removeOption(index: number) {
  if (formData.options) {
    formData.options.splice(index, 1)
  }
}

async function handleSubmit() {
  try {
    if (isEdit.value && currentId.value) {
      await updateCustomField(currentId.value, formData as CustomFieldDefUpdateDTO)
      ElMessage.success('更新成功')
    } else {
      await createCustomField(formData as CustomFieldDefCreateDTO)
      ElMessage.success('创建成功')
    }
    dialogVisible.value = false
    fetchList()
  } catch (error) {
    ElMessage.error(isEdit.value ? '更新失败' : '创建失败')
  }
}

onMounted(() => {
  fetchList()
})
</script>

<template>
  <div class="custom-field-container">
    <el-card class="search-card">
      <el-form inline>
        <el-form-item label="实体类型">
          <el-select v-model="entityTypeFilter" placeholder="请选择实体类型">
            <el-option
              v-for="type in entityTypes"
              :key="type.value"
              :label="type.label"
              :value="type.value"
            />
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
        <el-table-column prop="entityType" label="实体类型" width="100">
          <template #default="{ row }">
            {{ entityTypes.find(t => t.value === row.entityType)?.label }}
          </template>
        </el-table-column>
        <el-table-column prop="fieldKey" label="字段Key" />
        <el-table-column prop="fieldLabel" label="字段名称" />
        <el-table-column prop="fieldType" label="字段类型" width="120">
          <template #default="{ row }">
            {{ fieldTypes.find(t => t.value === row.fieldType)?.label }}
          </template>
        </el-table-column>
        <el-table-column prop="required" label="是否必填" width="100">
          <template #default="{ row }">
            <el-tag :type="row.required ? 'danger' : 'info'">
              {{ row.required ? '必填' : '非必填' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="sortOrder" label="排序" width="80" />
        <el-table-column prop="createdTime" label="创建时间" width="180" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button type="primary" :icon="Edit" link @click="handleEdit(row)">编辑</el-button>
            <el-button type="danger" :icon="Delete" link @click="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px">
      <el-form :model="formData" label-width="100px">
        <el-form-item v-if="!isEdit" label="实体类型" required>
          <el-select v-model="(formData as CustomFieldDefCreateDTO).entityType" placeholder="请选择实体类型">
            <el-option
              v-for="type in entityTypes"
              :key="type.value"
              :label="type.label"
              :value="type.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item v-if="!isEdit" label="字段Key" required>
          <el-input v-model="(formData as CustomFieldDefCreateDTO).fieldKey" placeholder="小写字母+数字+下划线" />
        </el-form-item>
        <el-form-item v-if="!isEdit" label="字段类型" required>
          <el-select v-model="(formData as CustomFieldDefCreateDTO).fieldType" placeholder="请选择字段类型">
            <el-option
              v-for="type in fieldTypes"
              :key="type.value"
              :label="type.label"
              :value="type.value"
            />
          </el-select>
        </el-form-item>
        <el-form-item label="字段名称" required>
          <el-input v-model="formData.fieldLabel" placeholder="请输入字段名称" />
        </el-form-item>
        <el-form-item label="是否必填" required>
          <el-switch v-model="formData.required" />
        </el-form-item>
        <el-form-item label="排序">
          <el-input-number v-model="formData.sortOrder" :min="0" />
        </el-form-item>
        <el-form-item
          v-if="!isEdit && ((formData as CustomFieldDefCreateDTO).fieldType === 'SELECT' || (formData as CustomFieldDefCreateDTO).fieldType === 'CHECKBOX')"
          label="选项配置"
        >
          <div class="options-config">
            <div class="option-input">
              <el-input v-model="optionInput" placeholder="输入选项内容" />
              <el-button type="primary" @click="addOption">添加</el-button>
            </div>
            <div class="option-list">
              <el-tag
                v-for="(option, index) in formData.options"
                :key="index"
                closable
                @close="removeOption(index)"
              >
                {{ option }}
              </el-tag>
            </div>
          </div>
        </el-form-item>
        <el-form-item
          v-if="isEdit && formData.options && formData.options.length > 0"
          label="选项配置"
        >
          <div class="options-config">
            <div class="option-input">
              <el-input v-model="optionInput" placeholder="输入选项内容" />
              <el-button type="primary" @click="addOption">添加</el-button>
            </div>
            <div class="option-list">
              <el-tag
                v-for="(option, index) in formData.options"
                :key="index"
                closable
                @close="removeOption(index)"
              >
                {{ option }}
              </el-tag>
            </div>
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
.custom-field-container {
  padding: 20px;

  .search-card {
    margin-bottom: 20px;
  }

  .options-config {
    width: 100%;

    .option-input {
      display: flex;
      gap: 10px;
      margin-bottom: 10px;
    }

    .option-list {
      display: flex;
      flex-wrap: wrap;
      gap: 10px;
    }
  }
}
</style>
