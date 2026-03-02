import request from '@/api/request'
import type { Result, PageResult, PageQuery } from '@ljwx/shared'

// ============================================================
// Message Record Types
// ============================================================

export interface MsgRecordVO {
  id: number
  templateId: number
  messageType: 'INBOX' | 'EMAIL' | 'SMS'
  receiverId: number
  receiverAddress?: string
  subject: string
  content: string
  sendStatus: 'PENDING' | 'SUCCESS' | 'FAILURE'
  sendTime?: string
  errorMessage?: string
  createdTime: string
}

export interface MsgRecordQueryDTO extends PageQuery {
  messageType?: string
  sendStatus?: string
  receiverId?: number
  startTime?: string
  endTime?: string
}

export interface MessageSendDTO {
  templateId: number
  messageType: 'INBOX' | 'EMAIL' | 'SMS'
  receiverId: number
  receiverAddress?: string
  subject: string
  content: string
  params?: Record<string, unknown>
}

// ============================================================
// User Inbox Types
// ============================================================

export interface MsgUserInboxVO {
  id: number
  userId: number
  messageId: number
  title: string
  content: string
  isRead: boolean
  readTime?: string
  createdTime: string
}

export interface MsgUserInboxQueryDTO extends PageQuery {
  isRead?: boolean
  startTime?: string
  endTime?: string
}

// ============================================================
// API Functions
// ============================================================

export function sendMessage(data: MessageSendDTO): Promise<Result<number>> {
  return request.post('/api/v1/messages/send', data)
}

export function listMessageRecords(params?: MsgRecordQueryDTO): Promise<Result<PageResult<MsgRecordVO>>> {
  return request.get('/api/v1/messages/records', { params })
}

export function getMessageRecord(id: number): Promise<Result<MsgRecordVO>> {
  return request.get(`/api/v1/messages/records/${id}`)
}

export function listUserInbox(params?: MsgUserInboxQueryDTO): Promise<Result<PageResult<MsgUserInboxVO>>> {
  return request.get('/api/v1/messages/inbox', { params })
}

export function markInboxAsRead(id: number): Promise<Result<void>> {
  return request.put(`/api/v1/messages/inbox/${id}/read`)
}

export function deleteInboxMessage(id: number): Promise<Result<void>> {
  return request.delete(`/api/v1/messages/inbox/${id}`)
}
