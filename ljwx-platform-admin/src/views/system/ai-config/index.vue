<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { getConfig, updateConfig } from '@/api/ai/ai-config'
import type { AiConfigVO, AiConfigUpdateDTO } from '@/api/ai/ai-config'
import type { FormInstance, FormRules } from 'element-plus'

const loading = ref(false)
const configForm = ref<AiConfigUpdateDTO>({
  provider: 'OPENAI',
  modelName: 'gpt-4o',
  apiKey: '',
  baseUrl: '',
  temperature: 0.7,
  maxTokens: 2048
})

const currentConfig = ref<AiConfigVO | null>(null)
const formRef = ref<FormInstance>()

const providerOptions = [
  { label: 'OpenAI', value: 'OPENAI' },
  { label: '通义千问', value: 'TONGYI' },
  { label: 'DeepSeek', value: 'DEEPSEEK' }
]

const rules: FormRules = {
  provider: [
    { required: true, message: '请选择模型提供商', trigger: 'change' }
  ],
  modelName: [
    { required: true, message: '请输入模型名称', trigger: 'blur' },
    { max: 100, message: '模型名称不能超过100个字符', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9._-]+$/, message: '模型名称只能包含字母、数字、点、下划线和短横线', trigger: 'blur' }
  ],
  apiKey: [
    { required: true, message: '请输入 API Key', trigger: 'blur' },
    { min: 20, max: 500, message: 'API Key 长度必须在 20-500 个字符之间', trigger: 'blur' }
  ],
  baseUrl: [
    { pattern: /^https?:\/\/.*/, message: 'Base URL 必须以 http:// 或 https:// 开头', trigger: 'blur' },
    { max: 500, message: 'Base URL 不能超过500个字符', trigger: 'blur' }
  ],
  temperature: [
    { required: true, message: '请输入温度参数', trigger: 'blur' },
    { type: 'number', min: 0, max: 1, message: '温度参数必须在 0-1 之间', trigger: 'blur' }
  ],
  maxTokens: [
    { required: true, message: '请输入最大 Token 数', trigger: 'blur' },
    { type: 'number', min: 256, max: 8192, message: '最大 Token 数必须在 256-8192 之间', trigger: 'blur' }
  ]
}

async function loadConfig() {
  loading.value = true
  try {
    const config = await getConfig()
    currentConfig.value = config
    configForm.value = {
      provider: config.provider,
      modelName: config.modelName,
      apiKey: '',
      baseUrl: config.baseUrl || '',
      temperature: config.temperature,
      maxTokens: config.maxTokens
    }
  } catch (error) {
    ElMessage.error('加载配置失败')
  } finally {
    loading.value = false
  }
}

async function handleSubmit() {
  if (!formRef.value) return

  await formRef.value.validate(async (valid) => {
    if (!valid) return

    loading.value = true
    try {
      await updateConfig(configForm.value)
      ElMessage.success('配置更新成功')
      await loadConfig()
    } catch (error) {
      ElMessage.error('配置更新失败')
    } finally {
      loading.value = false
    }
  })
}

function handleReset() {
  if (currentConfig.value) {
    configForm.value = {
      provider: currentConfig.value.provider,
      modelName: currentConfig.value.modelName,
      apiKey: '',
      baseUrl: currentConfig.value.baseUrl || '',
      temperature: currentConfig.value.temperature,
      maxTokens: currentConfig.value.maxTokens
    }
  }
  formRef.value?.clearValidate()
}

onMounted(() => {
  loadConfig()
})
</script>

<template>
  <div class="ai-config-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>AI 模型配置</span>
          <el-tag v-if="currentConfig" :type="currentConfig.enabled ? 'success' : 'danger'">
            {{ currentConfig.enabled ? '已启用' : '未启用' }}
          </el-tag>
        </div>
      </template>

      <el-alert
        type="info"
        :closable="false"
        style="margin-bottom: 20px"
      >
        <template #title>
          配置说明
        </template>
        <div>
          <p>1. API Key 将加密存储，查询时仅显示脱敏版本</p>
          <p>2. 更新配置后，新的对话将使用新配置</p>
          <p>3. 温度参数控制回答的随机性，0 表示确定性，1 表示最大随机性</p>
          <p>4. 当前 API Key（脱敏）：{{ currentConfig?.apiKeyMasked || '未配置' }}</p>
        </div>
      </el-alert>

      <el-form
        ref="formRef"
        v-loading="loading"
        :model="configForm"
        :rules="rules"
        label-width="120px"
      >
        <el-form-item label="模型提供商" prop="provider">
          <el-select v-model="configForm.provider" placeholder="请选择模型提供商">
            <el-option
              v-for="item in providerOptions"
              :key="item.value"
              :label="item.label"
              :value="item.value"
            />
          </el-select>
        </el-form-item>

        <el-form-item label="模型名称" prop="modelName">
          <el-input
            v-model="configForm.modelName"
            placeholder="例如：gpt-4o, qwen-max, deepseek-chat"
          />
        </el-form-item>

        <el-form-item label="API Key" prop="apiKey">
          <el-input
            v-model="configForm.apiKey"
            type="password"
            placeholder="输入新的 API Key（留空则保持不变）"
            show-password
          />
        </el-form-item>

        <el-form-item label="Base URL" prop="baseUrl">
          <el-input
            v-model="configForm.baseUrl"
            placeholder="自定义 API Base URL（可选）"
          />
        </el-form-item>

        <el-form-item label="温度参数" prop="temperature">
          <el-slider
            v-model="configForm.temperature"
            :min="0"
            :max="1"
            :step="0.1"
            show-input
            :input-size="'small'"
          />
        </el-form-item>

        <el-form-item label="最大 Token 数" prop="maxTokens">
          <el-input-number
            v-model="configForm.maxTokens"
            :min="256"
            :max="8192"
            :step="256"
          />
        </el-form-item>

        <el-form-item>
          <el-button type="primary" @click="handleSubmit">保存配置</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.ai-config-container {
  padding: 20px;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .el-alert {
    p {
      margin: 4px 0;
      font-size: 14px;
      line-height: 1.6;
    }
  }

  .el-form {
    max-width: 600px;
  }
}
</style>
