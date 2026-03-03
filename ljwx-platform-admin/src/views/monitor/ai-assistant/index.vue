<script setup lang="ts">
import { ref, computed, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { chat, getConversations } from '@/api/ai/ai-chat'
import type { AiChatVO, AiConversationLogVO } from '@/api/ai/ai-chat'

interface Message {
  role: 'user' | 'assistant'
  content: string
  toolCalls?: string[]
  tokensUsed?: number
  durationMs?: number
  timestamp: string
}

const loading = ref(false)
const inputMessage = ref('')
const sessionId = ref('')
const messages = ref<Message[]>([])
const chatContainer = ref<HTMLElement>()

const historyVisible = ref(false)
const historyLoading = ref(false)
const historyList = ref<AiConversationLogVO[]>([])
const historyTotal = ref(0)
const historyQuery = ref({
  pageNum: 1,
  pageSize: 20
})

const canSend = computed(() => {
  return inputMessage.value.trim().length > 0 && !loading.value
})

async function sendMessage() {
  if (!canSend.value) return

  const userMessage = inputMessage.value.trim()
  inputMessage.value = ''

  messages.value.push({
    role: 'user',
    content: userMessage,
    timestamp: new Date().toLocaleTimeString()
  })

  scrollToBottom()

  loading.value = true
  try {
    const response = await chat({
      sessionId: sessionId.value || undefined,
      message: userMessage
    })

    if (!sessionId.value) {
      sessionId.value = response.sessionId
    }

    messages.value.push({
      role: 'assistant',
      content: response.answer,
      toolCalls: response.toolCalls.map(t => t.toolName),
      tokensUsed: response.tokensUsed,
      durationMs: response.durationMs,
      timestamp: new Date().toLocaleTimeString()
    })

    scrollToBottom()
  } catch (error) {
    ElMessage.error('发送消息失败')
  } finally {
    loading.value = false
  }
}

function scrollToBottom() {
  nextTick(() => {
    if (chatContainer.value) {
      chatContainer.value.scrollTop = chatContainer.value.scrollHeight
    }
  })
}

function clearChat() {
  messages.value = []
  sessionId.value = ''
  inputMessage.value = ''
}

async function loadHistory() {
  historyVisible.value = true
  historyLoading.value = true
  try {
    const res = await getConversations(historyQuery.value)
    historyList.value = res.rows
    historyTotal.value = res.total
  } catch (error) {
    ElMessage.error('加载历史记录失败')
  } finally {
    historyLoading.value = false
  }
}

function handleHistoryPageChange(page: number) {
  historyQuery.value.pageNum = page
  loadHistory()
}

function loadSession(log: AiConversationLogVO) {
  sessionId.value = log.sessionId
  messages.value = [
    {
      role: 'user',
      content: log.question,
      timestamp: new Date(log.createdTime).toLocaleTimeString()
    },
    {
      role: 'assistant',
      content: log.answer,
      toolCalls: log.toolCallSummary,
      tokensUsed: log.tokensUsed,
      durationMs: log.durationMs,
      timestamp: new Date(log.createdTime).toLocaleTimeString()
    }
  ]
  historyVisible.value = false
  scrollToBottom()
}
</script>

<template>
  <div class="ai-assistant-container">
    <el-card class="chat-card">
      <template #header>
        <div class="card-header">
          <span>AI 智能运维助手</span>
          <div class="header-actions">
            <el-button size="small" @click="loadHistory">历史记录</el-button>
            <el-button size="small" @click="clearChat">清空对话</el-button>
          </div>
        </div>
      </template>

      <div ref="chatContainer" class="chat-messages">
        <div v-if="messages.length === 0" class="empty-state">
          <el-empty description="开始与 AI 助手对话，查询系统运维信息" />
        </div>

        <div
          v-for="(msg, index) in messages"
          :key="index"
          :class="['message-item', msg.role]"
        >
          <div class="message-content">
            <div class="message-text">{{ msg.content }}</div>
            <div v-if="msg.toolCalls && msg.toolCalls.length > 0" class="tool-calls">
              <el-tag
                v-for="(tool, idx) in msg.toolCalls"
                :key="idx"
                size="small"
                type="info"
              >
                {{ tool }}
              </el-tag>
            </div>
            <div class="message-meta">
              <span>{{ msg.timestamp }}</span>
              <span v-if="msg.tokensUsed">{{ msg.tokensUsed }} tokens</span>
              <span v-if="msg.durationMs">{{ msg.durationMs }}ms</span>
            </div>
          </div>
        </div>

        <div v-if="loading" class="message-item assistant">
          <div class="message-content">
            <el-icon class="is-loading"><Loading /></el-icon>
            <span class="loading-text">AI 正在思考...</span>
          </div>
        </div>
      </div>

      <div class="chat-input">
        <el-input
          v-model="inputMessage"
          type="textarea"
          :rows="3"
          placeholder="输入运维问题，例如：查看最近的错误日志、当前在线用户数、服务器状态等"
          :disabled="loading"
          @keydown.ctrl.enter="sendMessage"
        />
        <div class="input-actions">
          <span class="input-tip">Ctrl + Enter 发送</span>
          <el-button type="primary" :disabled="!canSend" @click="sendMessage">
            发送
          </el-button>
        </div>
      </div>
    </el-card>

    <el-drawer
      v-model="historyVisible"
      title="对话历史"
      size="50%"
      direction="rtl"
    >
      <el-table
        v-loading="historyLoading"
        :data="historyList"
        style="width: 100%"
      >
        <el-table-column prop="question" label="问题" width="200" show-overflow-tooltip />
        <el-table-column prop="answer" label="回答" show-overflow-tooltip />
        <el-table-column prop="modelName" label="模型" width="120" />
        <el-table-column prop="tokensUsed" label="Tokens" width="80" />
        <el-table-column prop="createdTime" label="时间" width="160" />
        <el-table-column label="操作" width="100" fixed="right">
          <template #default="{ row }">
            <el-button link type="primary" size="small" @click="loadSession(row)">
              加载
            </el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        v-model:current-page="historyQuery.pageNum"
        :page-size="historyQuery.pageSize"
        :total="historyTotal"
        layout="total, prev, pager, next"
        @current-change="handleHistoryPageChange"
      />
    </el-drawer>
  </div>
</template>

<style scoped lang="scss">
.ai-assistant-container {
  height: calc(100vh - 120px);
  padding: 20px;

  .chat-card {
    height: 100%;
    display: flex;
    flex-direction: column;

    :deep(.el-card__body) {
      flex: 1;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;

    .header-actions {
      display: flex;
      gap: 8px;
    }
  }

  .chat-messages {
    flex: 1;
    overflow-y: auto;
    padding: 20px;
    background: #f5f7fa;
    border-radius: 4px;
    margin-bottom: 16px;

    .empty-state {
      display: flex;
      align-items: center;
      justify-content: center;
      height: 100%;
    }

    .message-item {
      display: flex;
      margin-bottom: 16px;

      &.user {
        justify-content: flex-end;

        .message-content {
          background: #409eff;
          color: white;
        }
      }

      &.assistant {
        justify-content: flex-start;

        .message-content {
          background: white;
          color: #303133;
        }
      }

      .message-content {
        max-width: 70%;
        padding: 12px 16px;
        border-radius: 8px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);

        .message-text {
          white-space: pre-wrap;
          word-break: break-word;
          line-height: 1.6;
        }

        .tool-calls {
          margin-top: 8px;
          display: flex;
          flex-wrap: wrap;
          gap: 4px;
        }

        .message-meta {
          margin-top: 8px;
          font-size: 12px;
          opacity: 0.7;
          display: flex;
          gap: 12px;
        }

        .loading-text {
          margin-left: 8px;
        }
      }
    }
  }

  .chat-input {
    .input-actions {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: 8px;

      .input-tip {
        font-size: 12px;
        color: #909399;
      }
    }
  }
}
</style>
