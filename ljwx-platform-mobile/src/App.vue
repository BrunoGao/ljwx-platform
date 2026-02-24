<script setup lang="ts">
// App root — uni-app lifecycle hooks
onLaunch(() => {
  console.log('App launched')
})

onShow(() => {
  console.log('App shown')
})

onHide(() => {
  console.log('App hidden')
})
</script>

<template>
  <div />
</template>

<style lang="scss">
* {
  box-sizing: border-box;
}

page {
  background-color: #f5f5f5;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}
</style>
