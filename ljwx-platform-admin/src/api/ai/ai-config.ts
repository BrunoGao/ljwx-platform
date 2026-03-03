import request from '@/api/request'

export interface AiConfigUpdateDTO {
  provider: string
  modelName: string
  apiKey: string
  baseUrl?: string
  temperature: number
  maxTokens: number
}

export interface AiConfigVO {
  provider: string
  modelName: string
  apiKeyMasked: string
  baseUrl: string
  temperature: number
  maxTokens: number
  enabled: boolean
}

export function getConfig(): Promise<AiConfigVO> {
  return request.get<AiConfigVO>('/api/v1/ai/config')
}

export function updateConfig(data: AiConfigUpdateDTO): Promise<void> {
  return request.put<void>('/api/v1/ai/config', data)
}
