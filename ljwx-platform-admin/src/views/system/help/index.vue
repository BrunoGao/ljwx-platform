<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import {
  getHelpDocList,
  createHelpDoc,
  updateHelpDoc,
  deleteHelpDoc,
  type HelpDocVO,
  type HelpDocCreateDTO,
  type HelpDocUpdateDTO
} from '@/api/help/help-doc'
import { useI18n } from 'vue-i18n'
import { ElMessage, ElMessageBox } from 'element-plus'
import { marked } from 'marked'
import DOMPurify from 'dompurify'
import { Plus, Edit, Delete, View } from '@element-plus/icons-vue'

const { t } = useI18n()
const loading = ref(false)
const helpDocs = ref<HelpDocVO[]>([])
const dialogVisible = ref(false)
const dialogTitle = ref('')
const isEdit = ref(false)
const currentId = ref<number | null>(null)
const previewVisible = ref(false)
const previewContent = ref('')

const formData = reactive<HelpDocCreateDTO | HelpDocUpdateDTO>({
  docKey: '',
  title: '',
  content: '',
  category: '',
  routeMatch: '',
  sortOrder: 0,
  status: 1
})

const formRules = {
  docKey: [
    { required: true, message: t('help.docKeyRequired'), trigger: 'blur' },
    { pattern: /^[a-z][a-z0-9_-]*$/, message: t('help.docKeyPattern'), trigger: 'blur' }
  ],
  title: [
    { required: true, message: t('help.titleRequired'), trigger: 'blur' },
    { min: 1, max: 200, message: t('help.titleLength'), trigger: 'blur' }
  ],
  content: [
    { required: true, message: t('help.contentRequired'), trigger: 'blur' },
    { min: 1, max: 50000, message: t('help.contentLength'), trigger: 'blur' }
  ],
  category: [
    { required: true, message: t('help.categoryRequired'), trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_-]+$/, message: t('help.categoryPattern'), trigger: 'blur' }
  ],
  routeMatch: [
    { pattern: /^\/.*/, message: t('help.routeMatchPattern'), trigger: 'blur' }
  ]
}

const loadHelpDocs = async () => {
  loading.value = true
  try {
    helpDocs.value = await getHelpDocList()
  } catch (error) {
    console.error('Failed to load help docs:', error)
  } finally {
    loading.value = false
  }
}

const handleAdd = () => {
  isEdit.value = false
  dialogTitle.value = t('help.addDoc')
  resetForm()
  dialogVisible.value = true
}

const handleEdit = (row: HelpDocVO) => {
  isEdit.value = true
  currentId.value = row.id
  dialogTitle.value = t('help.editDoc')
  Object.assign(formData, {
    title: row.title,
    content: row.content,
    category: row.category,
    routeMatch: row.routeMatch || '',
    sortOrder: row.sortOrder,
    status: row.status
  })
  if (!isEdit.value) {
    (formData as HelpDocCreateDTO).docKey = row.docKey
  }
  dialogVisible.value = true
}

const handleDelete = async (row: HelpDocVO) => {
  try {
    await ElMessageBox.confirm(
      t('help.deleteConfirm', { title: row.title }),
      t('common.warning'),
      {
        confirmButtonText: t('common.confirm'),
        cancelButtonText: t('common.cancel'),
        type: 'warning'
      }
    )
    await deleteHelpDoc(row.id)
    ElMessage.success(t('common.deleteSuccess'))
    loadHelpDocs()
  } catch (error) {
    if (error !== 'cancel') {
      console.error('Failed to delete help doc:', error)
    }
  }
}

const handlePreview = (row: HelpDocVO) => {
  const html = marked(row.content) as string
  previewContent.value = DOMPurify.sanitize(html)
  previewVisible.value = true
}

const handleSubmit = async () => {
  try {
    if (isEdit.value && currentId.value) {
      await updateHelpDoc(currentId.value, formData as HelpDocUpdateDTO)
      ElMessage.success(t('common.updateSuccess'))
    } else {
      await createHelpDoc(formData as HelpDocCreateDTO)
      ElMessage.success(t('common.createSuccess'))
    }
    dialogVisible.value = false
    loadHelpDocs()
  } catch (error) {
    console.error('Failed to save help doc:', error)
  }
}

const resetForm = () => {
  Object.assign(formData, {
    docKey: '',
    title: '',
    content: '',
    category: '',
    routeMatch: '',
    sortOrder: 0,
    status: 1
  })
}

onMounted(() => {
  loadHelpDocs()
})
</script>

<template>
  <div class="help-doc-management">
    <el-card shadow="never">
      <template #header>
        <div class="card-header">
          <span>{{ t('help.docList') }}</span>
          <el-button type="primary" :icon="Plus" @click="handleAdd">
            {{ t('common.add') }}
          </el-button>
        </div>
      </template>

      <el-table v-loading="loading" :data="helpDocs" border stripe>
        <el-table-column prop="docKey" :label="t('help.docKey')" width="150" />
        <el-table-column prop="title" :label="t('help.title')" min-width="200" />
        <el-table-column prop="category" :label="t('help.category')" width="120" />
        <el-table-column prop="routeMatch" :label="t('help.routeMatch')" width="180" />
        <el-table-column prop="sortOrder" :label="t('help.sortOrder')" width="100" align="center" />
        <el-table-column prop="status" :label="t('common.status')" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 1 ? 'success' : 'info'">
              {{ row.status === 1 ? t('common.enabled') : t('common.disabled') }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column :label="t('common.actions')" width="200" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" :icon="View" @click="handlePreview(row)">
              {{ t('common.preview') }}
            </el-button>
            <el-button link type="primary" :icon="Edit" @click="handleEdit(row)">
              {{ t('common.edit') }}
            </el-button>
            <el-button link type="danger" :icon="Delete" @click="handleDelete(row)">
              {{ t('common.delete') }}
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="800px">
      <el-form :model="formData" :rules="formRules" label-width="120px">
        <el-form-item v-if="!isEdit" :label="t('help.docKey')" prop="docKey">
          <el-input v-model="(formData as HelpDocCreateDTO).docKey" :placeholder="t('help.docKeyPlaceholder')" />
        </el-form-item>
        <el-form-item :label="t('help.title')" prop="title">
          <el-input v-model="formData.title" :placeholder="t('help.titlePlaceholder')" />
        </el-form-item>
        <el-form-item :label="t('help.category')" prop="category">
          <el-input v-model="formData.category" :placeholder="t('help.categoryPlaceholder')" />
        </el-form-item>
        <el-form-item :label="t('help.routeMatch')" prop="routeMatch">
          <el-input v-model="formData.routeMatch" :placeholder="t('help.routeMatchPlaceholder')" />
        </el-form-item>
        <el-form-item :label="t('help.sortOrder')" prop="sortOrder">
          <el-input-number v-model="formData.sortOrder" :min="0" />
        </el-form-item>
        <el-form-item v-if="isEdit" :label="t('common.status')" prop="status">
          <el-radio-group v-model="(formData as HelpDocUpdateDTO).status">
            <el-radio :value="1">{{ t('common.enabled') }}</el-radio>
            <el-radio :value="0">{{ t('common.disabled') }}</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item :label="t('help.content')" prop="content">
          <el-input
            v-model="formData.content"
            type="textarea"
            :rows="12"
            :placeholder="t('help.contentPlaceholder')"
          />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">{{ t('common.cancel') }}</el-button>
        <el-button type="primary" @click="handleSubmit">{{ t('common.confirm') }}</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="previewVisible" :title="t('common.preview')" width="800px">
      <div v-html="previewContent" class="preview-content" />
    </el-dialog>
  </div>
</template>

<style scoped lang="scss">
.help-doc-management {
  padding: 20px;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .preview-content {
    line-height: 1.8;
    max-height: 600px;
    overflow-y: auto;

    :deep(h1) {
      font-size: 24px;
      margin: 20px 0 16px;
      font-weight: 600;
    }

    :deep(h2) {
      font-size: 20px;
      margin: 18px 0 14px;
      font-weight: 600;
    }

    :deep(h3) {
      font-size: 18px;
      margin: 16px 0 12px;
      font-weight: 600;
    }

    :deep(p) {
      margin: 12px 0;
    }

    :deep(code) {
      background-color: #f5f7fa;
      padding: 2px 6px;
      border-radius: 4px;
      font-family: 'Courier New', monospace;
    }

    :deep(pre) {
      background-color: #f5f7fa;
      padding: 12px;
      border-radius: 4px;
      overflow-x: auto;

      code {
        background-color: transparent;
        padding: 0;
      }
    }

    :deep(ul), :deep(ol) {
      padding-left: 24px;
      margin: 12px 0;
    }

    :deep(li) {
      margin: 6px 0;
    }

    :deep(blockquote) {
      border-left: 4px solid #409eff;
      padding-left: 16px;
      margin: 16px 0;
      color: #606266;
    }

    :deep(table) {
      width: 100%;
      border-collapse: collapse;
      margin: 16px 0;

      th, td {
        border: 1px solid #dcdfe6;
        padding: 8px 12px;
        text-align: left;
      }

      th {
        background-color: #f5f7fa;
        font-weight: 600;
      }
    }
  }
}
</style>
