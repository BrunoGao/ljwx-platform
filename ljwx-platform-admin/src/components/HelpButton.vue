<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { getHelpDocByRoute, type HelpDocVO } from '@/api/help/help-doc'
import { marked } from 'marked'
import DOMPurify from 'dompurify'
import { QuestionFilled } from '@element-plus/icons-vue'

const { t } = useI18n()
const route = useRoute()
const visible = ref(false)
const doc = ref<HelpDocVO | null>(null)
const loading = ref(false)

const openHelp = async () => {
  loading.value = true
  try {
    doc.value = await getHelpDocByRoute(route.path)
    visible.value = true
  } catch (error) {
    console.error('Failed to load help doc:', error)
  } finally {
    loading.value = false
  }
}

const renderedContent = computed(() => {
  if (!doc.value) return ''
  const html = marked(doc.value.content) as string
  return DOMPurify.sanitize(html)
})
</script>

<template>
  <el-tooltip :content="t('common.help')" placement="left">
    <el-button
      class="help-btn"
      :icon="QuestionFilled"
      circle
      :loading="loading"
      @click="openHelp"
    />
  </el-tooltip>

  <el-drawer v-model="visible" :title="doc?.title" size="40%">
    <div v-if="doc" v-html="renderedContent" class="help-content" />
    <el-empty v-else :description="t('help.noDoc')" />
  </el-drawer>
</template>

<style scoped lang="scss">
.help-btn {
  position: fixed;
  right: 24px;
  bottom: 80px;
  z-index: 999;
  box-shadow: 0 2px 12px 0 rgba(0, 0, 0, 0.1);
}

.help-content {
  line-height: 1.8;

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
</style>
