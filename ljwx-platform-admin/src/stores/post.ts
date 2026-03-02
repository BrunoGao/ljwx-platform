import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { PostVO } from '@/api/post'
import { getPostList } from '@/api/post'

export const usePostStore = defineStore('post', () => {
  const posts = ref<PostVO[]>([])
  const loading = ref(false)

  async function fetchPosts(): Promise<void> {
    loading.value = true
    try {
      const result = await getPostList()
      posts.value = result.rows
    } finally {
      loading.value = false
    }
  }

  return {
    posts,
    loading,
    fetchPosts,
  }
})
