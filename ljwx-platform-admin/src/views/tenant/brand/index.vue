<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useTenantBrandStore } from '@/stores/tenantBrand'
import type { TenantBrandUpdateDTO, FooterLink } from '@/api/tenantBrand'
import { ElMessage } from 'element-plus'

const brandStore = useTenantBrandStore()

// 表单数据
const formData = ref<TenantBrandUpdateDTO>({
  brandName: '',
  logoUrl: '',
  faviconUrl: '',
  primaryColor: '#1890ff',
  secondaryColor: '',
  backgroundColor: '',
  loginBgUrl: '',
  loginSlogan: '',
  copyrightText: '',
  icpNumber: '',
  footerLinks: [],
  mobileIconUrl: '',
  mobileSplashUrl: '',
  customCss: '',
})

// 页脚链接表单
const footerLinkForm = ref<FooterLink>({
  text: '',
  url: '',
})

// 表单验证规则
const rules = {
  brandName: [{ required: true, message: '请输入品牌名称', trigger: 'blur' }],
  primaryColor: [
    { required: true, message: '请输入主色', trigger: 'blur' },
    { pattern: /^#[0-9A-Fa-f]{6}$/, message: '颜色格式必须为 #RRGGBB', trigger: 'blur' },
  ],
  secondaryColor: [
    { pattern: /^#[0-9A-Fa-f]{6}$/, message: '颜色格式必须为 #RRGGBB', trigger: 'blur' },
  ],
  backgroundColor: [
    { pattern: /^#[0-9A-Fa-f]{6}$/, message: '颜色格式必须为 #RRGGBB', trigger: 'blur' },
  ],
  logoUrl: [{ type: 'url', message: '请输入有效的 URL', trigger: 'blur' }],
  faviconUrl: [{ type: 'url', message: '请输入有效的 URL', trigger: 'blur' }],
  loginBgUrl: [{ type: 'url', message: '请输入有效的 URL', trigger: 'blur' }],
  mobileIconUrl: [{ type: 'url', message: '请输入有效的 URL', trigger: 'blur' }],
  mobileSplashUrl: [{ type: 'url', message: '请输入有效的 URL', trigger: 'blur' }],
}

const formRef = ref()
const loading = ref(false)
const activeTab = ref('basic')

// 加载品牌配置
async function loadBrandConfig(): Promise<void> {
  loading.value = true
  try {
    await brandStore.loadBrand()
    if (brandStore.brand) {
      formData.value = {
        brandName: brandStore.brand.brandName,
        logoUrl: brandStore.brand.logoUrl || '',
        faviconUrl: brandStore.brand.faviconUrl || '',
        primaryColor: brandStore.brand.primaryColor,
        secondaryColor: brandStore.brand.secondaryColor || '',
        backgroundColor: brandStore.brand.backgroundColor || '',
        loginBgUrl: brandStore.brand.loginBgUrl || '',
        loginSlogan: brandStore.brand.loginSlogan || '',
        copyrightText: brandStore.brand.copyrightText || '',
        icpNumber: brandStore.brand.icpNumber || '',
        footerLinks: brandStore.brand.footerLinks || [],
        mobileIconUrl: brandStore.brand.mobileIconUrl || '',
        mobileSplashUrl: brandStore.brand.mobileSplashUrl || '',
        customCss: brandStore.brand.customCss || '',
      }
    }
  } catch (error) {
    ElMessage.error('加载品牌配置失败')
  } finally {
    loading.value = false
  }
}

// 提交表单
async function handleSubmit(): Promise<void> {
  if (!formRef.value) return

  try {
    await formRef.value.validate()
    loading.value = true
    await brandStore.updateBrand(formData.value)
  } catch (error) {
    if (error instanceof Error) {
      ElMessage.error(error.message)
    }
  } finally {
    loading.value = false
  }
}

// 添加页脚链接
function addFooterLink(): void {
  if (!footerLinkForm.value.text || !footerLinkForm.value.url) {
    ElMessage.warning('请填写链接文本和地址')
    return
  }

  if (!formData.value.footerLinks) {
    formData.value.footerLinks = []
  }

  if (formData.value.footerLinks.length >= 10) {
    ElMessage.warning('页脚链接最多 10 个')
    return
  }

  formData.value.footerLinks.push({ ...footerLinkForm.value })
  footerLinkForm.value = { text: '', url: '' }
}

// 删除页脚链接
function removeFooterLink(index: number): void {
  if (formData.value.footerLinks) {
    formData.value.footerLinks.splice(index, 1)
  }
}

// 重置表单
function handleReset(): void {
  formRef.value?.resetFields()
  loadBrandConfig()
}

onMounted(() => {
  loadBrandConfig()
})
</script>

<template>
  <div class="tenant-brand-container">
    <el-card>
      <template #header>
        <div class="card-header">
          <span>租户品牌配置</span>
        </div>
      </template>

      <el-form
        ref="formRef"
        :model="formData"
        :rules="rules"
        label-width="120px"
        v-loading="loading"
      >
        <el-tabs v-model="activeTab">
          <!-- 基础信息 -->
          <el-tab-pane label="基础信息" name="basic">
            <el-form-item label="品牌名称" prop="brandName">
              <el-input v-model="formData.brandName" placeholder="请输入品牌名称" />
            </el-form-item>

            <el-form-item label="Logo URL" prop="logoUrl">
              <el-input v-model="formData.logoUrl" placeholder="请输入 Logo URL" />
            </el-form-item>

            <el-form-item label="Favicon URL" prop="faviconUrl">
              <el-input v-model="formData.faviconUrl" placeholder="请输入 Favicon URL" />
            </el-form-item>
          </el-tab-pane>

          <!-- 主题配色 -->
          <el-tab-pane label="主题配色" name="theme">
            <el-form-item label="主色" prop="primaryColor">
              <el-color-picker v-model="formData.primaryColor" />
              <el-input
                v-model="formData.primaryColor"
                placeholder="#1890ff"
                style="width: 200px; margin-left: 10px"
              />
            </el-form-item>

            <el-form-item label="辅助色" prop="secondaryColor">
              <el-color-picker v-model="formData.secondaryColor" />
              <el-input
                v-model="formData.secondaryColor"
                placeholder="#52c41a"
                style="width: 200px; margin-left: 10px"
              />
            </el-form-item>

            <el-form-item label="背景色" prop="backgroundColor">
              <el-color-picker v-model="formData.backgroundColor" />
              <el-input
                v-model="formData.backgroundColor"
                placeholder="#f0f2f5"
                style="width: 200px; margin-left: 10px"
              />
            </el-form-item>
          </el-tab-pane>

          <!-- 登录页配置 -->
          <el-tab-pane label="登录页配置" name="login">
            <el-form-item label="背景图 URL" prop="loginBgUrl">
              <el-input v-model="formData.loginBgUrl" placeholder="请输入登录页背景图 URL" />
            </el-form-item>

            <el-form-item label="登录页标语" prop="loginSlogan">
              <el-input
                v-model="formData.loginSlogan"
                type="textarea"
                :rows="3"
                placeholder="请输入登录页标语"
                maxlength="200"
                show-word-limit
              />
            </el-form-item>
          </el-tab-pane>

          <!-- 页脚配置 -->
          <el-tab-pane label="页脚配置" name="footer">
            <el-form-item label="版权信息" prop="copyrightText">
              <el-input
                v-model="formData.copyrightText"
                placeholder="请输入版权信息"
                maxlength="200"
                show-word-limit
              />
            </el-form-item>

            <el-form-item label="备案号" prop="icpNumber">
              <el-input v-model="formData.icpNumber" placeholder="请输入备案号" maxlength="50" />
            </el-form-item>

            <el-form-item label="页脚链接">
              <div class="footer-links-container">
                <div class="footer-link-input">
                  <el-input
                    v-model="footerLinkForm.text"
                    placeholder="链接文本"
                    style="width: 200px; margin-right: 10px"
                  />
                  <el-input
                    v-model="footerLinkForm.url"
                    placeholder="链接地址"
                    style="width: 300px; margin-right: 10px"
                  />
                  <el-button type="primary" @click="addFooterLink">添加</el-button>
                </div>

                <el-table
                  :data="formData.footerLinks"
                  style="width: 100%; margin-top: 10px"
                  v-if="formData.footerLinks && formData.footerLinks.length > 0"
                >
                  <el-table-column prop="text" label="链接文本" width="200" />
                  <el-table-column prop="url" label="链接地址" />
                  <el-table-column label="操作" width="100">
                    <template #default="{ $index }">
                      <el-button type="danger" size="small" @click="removeFooterLink($index)">
                        删除
                      </el-button>
                    </template>
                  </el-table-column>
                </el-table>
              </div>
            </el-form-item>
          </el-tab-pane>

          <!-- 移动端配置 -->
          <el-tab-pane label="移动端配置" name="mobile">
            <el-form-item label="App 图标 URL" prop="mobileIconUrl">
              <el-input v-model="formData.mobileIconUrl" placeholder="请输入移动端图标 URL" />
            </el-form-item>

            <el-form-item label="启动页 URL" prop="mobileSplashUrl">
              <el-input v-model="formData.mobileSplashUrl" placeholder="请输入移动端启动页 URL" />
            </el-form-item>
          </el-tab-pane>

          <!-- 自定义 CSS -->
          <el-tab-pane label="自定义 CSS" name="css">
            <el-form-item label="自定义 CSS" prop="customCss">
              <el-input
                v-model="formData.customCss"
                type="textarea"
                :rows="15"
                placeholder="请输入自定义 CSS（仅支持安全属性）"
                maxlength="10000"
                show-word-limit
              />
              <div class="css-warning">
                <el-alert
                  title="安全提示"
                  type="warning"
                  :closable="false"
                  description="自定义 CSS 将被过滤，禁止使用 <script>、javascript:、expression()、@import、url() 等危险代码"
                />
              </div>
            </el-form-item>
          </el-tab-pane>
        </el-tabs>

        <el-form-item>
          <el-button type="primary" @click="handleSubmit" :loading="loading">保存配置</el-button>
          <el-button @click="handleReset">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<style scoped lang="scss">
.tenant-brand-container {
  padding: 20px;

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    font-size: 16px;
    font-weight: 600;
  }

  .footer-links-container {
    width: 100%;

    .footer-link-input {
      display: flex;
      align-items: center;
    }
  }

  .css-warning {
    margin-top: 10px;
  }
}
</style>
