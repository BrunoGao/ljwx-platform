import request from '@/api/request'

export interface AiChatDTO {
  sessionId?: string
  message: string
}

export interface ToolCallSummary {
  toolName: string
  parameters: Record<string, unknown>
}

export interface AiChatVO {
  sessionId: string
  answer: string
  toolCalls: ToolCallSummary[]
  tokensUsed: number
  durationMs: number
}

export interface AiConversationLogQueryDTO {
  sessionId?: string
  startTime?: string
  endTime?: string
  pageNum?: number
  pageSize?: number
}

export interface AiConversationLogVO {
  id: number
  sessionId: string
  question: string
  answer: string
  toolCallSummary: string[]
  tokensUsed: number
  durationMs: number
  modelName: string
  createdTime: string
}

export interface PageResult<T> {
  rows: T[]
  total: number
}

export function chat(data: AiChatDTO): Promise<AiChatVO> {
  return request.post<AiChatVO>('/api/v1/ai/chat', data)
}

export function getConversations(params: AiConversationLogQueryDTO): Promise<PageResult<AiConversationLogVO>> {
  return request.get<PageResult<AiConversationLogVO>>('/api/v1/ai/conversations', { params })
}
