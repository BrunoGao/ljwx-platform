<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import type { FormInstance, FormRules } from 'element-plus'
import type { ProfileVO, ProfileUpdateDTO, PasswordUpdateDTO } from '@/api/profile'
import { getProfile, updateProfile, updatePassword } from '@/api/profile'

// ─── 个人信息 ────────────────────────────────────────────────
const loading = ref(false)
const profileData = ref<ProfileVO | null>(null)

async function loadProfile(): Promise<void> {
  loading.value = true
  try {
    profileData.value = await getProfile()
  } finally {
    loading.value = false
  }
}

// ─── 基本信息表单 ────────────────────────────────────────────
const infoFormRef = ref<FormInstance>()

interface InfoForm {
  nickname: string
  email: string
  phone: string
}

const infoForm = reactive<InfoForm>({
  nickname: '',
  email: '',
  phone: '',
})

const infoRules: FormRules<InfoForm> = {
  nickname: [{ required: true, message: '请输入昵称', trigger: 'blur' }],
  email: [{ type: 'email', message: '请输入正确的邮箱格式', trigger: 'blur' }],
}

function fillInfoForm(data: ProfileVO): void {
  infoForm.nickname = data.nickname
  infoForm.email = data.email
  infoForm.phone = data.phone
}

async function handleUpdateInfo(): Promise<void> {
  try {
    await infoFormRef.value?.validate()
  } catch {
    return
  }
  try {
    const dto: ProfileUpdateDTO = {
      nickname: infoForm.nickname,
      email: infoForm.email || undefined,
      phone: infoForm.phone || undefined,
    }
    await updateProfile(dto)
    ElMessage.success('信息更新成功')
    loadProfile()
  } catch {
    // error handled by interceptor
  }
}

// ─── 修改密码表单 ────────────────────────────────────────────
const pwdFormRef = ref<FormInstance>()

interface PwdForm {
  oldPassword: string
  newPassword: string
  confirmPassword: string
}

const pwdForm = reactive<PwdForm>({
  oldPassword: '',
  newPassword: '',
  confirmPassword: '',
})

function validateConfirm(_rule: unknown, value: string, callback: (err?: Error) => void): void {
  if (value !== pwdForm.newPassword) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const pwdRules: FormRules<PwdForm> = {
  oldPassword: [{ required: true, message: '请输入原密码', trigger: 'blur' }],
  newPassword: [
    { required: true, message: '请输入新密码', trigger: 'blur' },
    { min: 6, message: '密码长度不少于6位', trigger: 'blur' },
  ],
  confirmPassword: [
    { required: true, message: '请确认新密码', trigger: 'blur' },
    { validator: validateConfirm, trigger: 'blur' },
  ],
}

async function handleUpdatePassword(): Promise<void> {
  try {
    await pwdFormRef.value?.validate()
  } catch {
    return
  }
  try {
    const dto: PasswordUpdateDTO = {
      oldPassword: pwdForm.oldPassword,
      newPassword: pwdForm.newPassword,
    }
    await updatePassword(dto)
    ElMessage.success('密码修改成功，请重新登录')
    pwdForm.oldPassword = ''
    pwdForm.newPassword = ''
    pwdForm.confirmPassword = ''
  } catch {
    // error handled by interceptor
  }
}

onMounted(async () => {
  await loadProfile()
  if (profileData.value) {
    fillInfoForm(profileData.value)
  }
})
</script>

<template>
  <div class="page-container">
    <el-row :gutter="16">
      <!-- 左侧：头像 + 基本信息展示 -->
      <el-col :span="8">
        <el-card v-loading="loading" shadow="never">
          <div class="profile-left">
            <el-avatar :size="80" class="avatar">
              {{ profileData?.nickname?.charAt(0) ?? 'U' }}
            </el-avatar>
            <div class="username">{{ profileData?.username }}</div>
            <el-descriptions :column="1" border class="info-desc">
              <el-descriptions-item label="昵称">{{ profileData?.nickname }}</el-descriptions-item>
              <el-descriptions-item label="邮箱">{{ profileData?.email }}</el-descriptions-item>
              <el-descriptions-item label="手机号">{{ profileData?.phone }}</el-descriptions-item>
              <el-descriptions-item label="注册时间">{{ profileData?.createdTime }}</el-descriptions-item>
            </el-descriptions>
          </div>
        </el-card>
      </el-col>

      <!-- 右侧：Tabs -->
      <el-col :span="16">
        <el-card shadow="never">
          <el-tabs>
            <!-- 基本信息修改 -->
            <el-tab-pane label="基本信息">
              <el-form
                ref="infoFormRef"
                :model="infoForm"
                :rules="infoRules"
                label-width="80px"
                style="max-width: 480px"
              >
                <el-form-item label="昵称" prop="nickname">
                  <el-input v-model="infoForm.nickname" placeholder="请输入昵称" />
                </el-form-item>
                <el-form-item label="邮箱" prop="email">
                  <el-input v-model="infoForm.email" placeholder="请输入邮箱" />
                </el-form-item>
                <el-form-item label="手机号" prop="phone">
                  <el-input v-model="infoForm.phone" placeholder="请输入手机号" />
                </el-form-item>
                <el-form-item>
                  <el-button type="primary" @click="handleUpdateInfo">保存修改</el-button>
                </el-form-item>
              </el-form>
            </el-tab-pane>

            <!-- 修改密码 -->
            <el-tab-pane label="修改密码">
              <el-form
                ref="pwdFormRef"
                :model="pwdForm"
                :rules="pwdRules"
                label-width="90px"
                style="max-width: 480px"
              >
                <el-form-item label="原密码" prop="oldPassword">
                  <el-input v-model="pwdForm.oldPassword" type="password" placeholder="请输入原密码" show-password />
                </el-form-item>
                <el-form-item label="新密码" prop="newPassword">
                  <el-input v-model="pwdForm.newPassword" type="password" placeholder="请输入新密码" show-password />
                </el-form-item>
                <el-form-item label="确认密码" prop="confirmPassword">
                  <el-input v-model="pwdForm.confirmPassword" type="password" placeholder="请再次输入新密码" show-password />
                </el-form-item>
                <el-form-item>
                  <el-button type="primary" @click="handleUpdatePassword">修改密码</el-button>
                </el-form-item>
              </el-form>
            </el-tab-pane>
          </el-tabs>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<style scoped lang="scss">
.page-container {
  padding: 0;
}

.profile-left {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

.avatar {
  background-color: var(--el-color-primary);
  color: #fff;
  font-size: 28px;
}

.username {
  font-size: 18px;
  font-weight: 600;
  color: var(--el-text-color-primary);
}

.info-desc {
  width: 100%;
  margin-top: 8px;
}
</style>
