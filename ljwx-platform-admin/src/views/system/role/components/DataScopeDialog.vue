<script setup lang="ts">
import { ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import type { RoleDataScopeVO, RoleDataScopeUpdateDTO } from '@ljwx/shared'
import type { DeptTreeVO } from '@/api/dept'
import { getRoleDataScope, updateRoleDataScope } from '@/api/role'
import { getDeptTree } from '@/api/dept'

interface Props {
  visible: boolean
  roleId: number | null
  roleName: string
}

const props = defineProps<Props>()
const emit = defineEmits<{
  'update:visible': [value: boolean]
  success: []
}>()

const loading = ref(false)
const deptTree = ref<DeptTreeVO[]>([])
const selectedDeptIds = ref<number[]>([])
const dataScopeInfo = ref<RoleDataScopeVO | null>(null)

watch(
  () => props.visible,
  async (newVal) => {
    if (newVal && props.roleId) {
      await loadData()
    }
  },
)

async function loadData(): Promise<void> {
  if (!props.roleId) return

  loading.value = true
  try {
    const [dataScope, tree] = await Promise.all([
      getRoleDataScope(props.roleId),
      getDeptTree(),
    ])
    dataScopeInfo.value = dataScope
    deptTree.value = tree
    selectedDeptIds.value = dataScope.deptIds
  } catch {
    // error handled by interceptor
  } finally {
    loading.value = false
  }
}

async function handleSubmit(): Promise<void> {
  if (!props.roleId) return

  loading.value = true
  try {
    const updateData: RoleDataScopeUpdateDTO = {
      deptIds: selectedDeptIds.value,
    }
    await updateRoleDataScope(props.roleId, updateData)
    ElMessage.success('数据范围更新成功')
    emit('success')
    handleClose()
  } catch {
    // error handled by interceptor
  } finally {
    loading.value = false
  }
}

function handleClose(): void {
  emit('update:visible', false)
  selectedDeptIds.value = []
  dataScopeInfo.value = null
}
</script>

<template>
  <el-dialog
    :model-value="visible"
    :title="`设置数据范围 - ${roleName}`"
    width="600px"
    destroy-on-close
    @close="handleClose"
  >
    <div v-loading="loading" class="dialog-content">
      <el-alert
        title="提示"
        type="info"
        :closable="false"
        show-icon
        style="margin-bottom: 16px"
      >
        <template #default>
          <div>选择该角色可访问的部门数据范围。</div>
          <div>当前已选择 <strong>{{ selectedDeptIds.length }}</strong> 个部门。</div>
        </template>
      </el-alert>

      <el-tree
        v-model="selectedDeptIds"
        :data="deptTree"
        :props="{ label: 'name', children: 'children' }"
        node-key="id"
        show-checkbox
        default-expand-all
        :check-strictly="false"
      />
    </div>

    <template #footer>
      <el-button @click="handleClose">取消</el-button>
      <el-button type="primary" :loading="loading" @click="handleSubmit">确定</el-button>
    </template>
  </el-dialog>
</template>

<style scoped lang="scss">
.dialog-content {
  min-height: 300px;
  max-height: 500px;
  overflow-y: auto;
}
</style>
