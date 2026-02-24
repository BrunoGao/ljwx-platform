/**
 * LJWX 数据大屏 ECharts 暗色主题
 * 基于 ECharts 官方暗色主题定制
 */
const darkTheme = {
  color: [
    '#00d4ff',
    '#00ff88',
    '#ffaa00',
    '#ff4466',
    '#aa44ff',
    '#44aaff',
    '#ff8844',
    '#44ffaa',
  ],
  backgroundColor: 'transparent',
  textStyle: {
    color: '#c0caf5',
  },
  title: {
    textStyle: {
      color: '#e0e8ff',
      fontSize: 16,
    },
    subtextStyle: {
      color: '#7a8ab8',
    },
  },
  line: {
    itemStyle: {
      borderWidth: 2,
    },
    lineStyle: {
      width: 2,
    },
    symbolSize: 6,
    symbol: 'circle',
    smooth: true,
  },
  radar: {
    itemStyle: {
      borderWidth: 2,
    },
    lineStyle: {
      width: 2,
    },
    symbolSize: 6,
    symbol: 'circle',
    smooth: true,
  },
  bar: {
    itemStyle: {
      barBorderWidth: 0,
      barBorderColor: '#204051',
    },
  },
  pie: {
    itemStyle: {
      borderWidth: 0,
      borderColor: '#204051',
    },
  },
  scatter: {
    itemStyle: {
      borderWidth: 0,
      borderColor: '#204051',
    },
  },
  boxplot: {
    itemStyle: {
      borderWidth: 0,
      borderColor: '#204051',
    },
  },
  parallel: {
    itemStyle: {
      borderWidth: 0,
      borderColor: '#204051',
    },
  },
  sankey: {
    itemStyle: {
      borderWidth: 0,
      borderColor: '#204051',
    },
  },
  funnel: {
    itemStyle: {
      borderWidth: 0,
      borderColor: '#204051',
    },
  },
  gauge: {
    itemStyle: {
      borderWidth: 0,
      borderColor: '#204051',
    },
  },
  candlestick: {
    itemStyle: {
      color: '#ff4466',
      color0: '#00ff88',
      borderColor: '#ff4466',
      borderColor0: '#00ff88',
      borderWidth: 1,
    },
  },
  graph: {
    itemStyle: {
      borderWidth: 0,
      borderColor: '#204051',
    },
    lineStyle: {
      width: 1,
      color: '#aaaaaa',
    },
    symbolSize: 6,
    symbol: 'circle',
    smooth: true,
    color: [
      '#00d4ff',
      '#00ff88',
      '#ffaa00',
      '#ff4466',
      '#aa44ff',
      '#44aaff',
      '#ff8844',
      '#44ffaa',
    ],
    label: {
      color: '#c0caf5',
    },
  },
  map: {
    itemStyle: {
      areaColor: '#132c3e',
      borderColor: '#1a4060',
      borderWidth: 0.5,
    },
    label: {
      color: '#c0caf5',
    },
    emphasis: {
      itemStyle: {
        areaColor: '#1a4060',
        borderColor: '#00d4ff',
        borderWidth: 1,
      },
      label: {
        color: '#00d4ff',
      },
    },
  },
  geo: {
    itemStyle: {
      areaColor: '#132c3e',
      borderColor: '#1a4060',
      borderWidth: 0.5,
    },
    label: {
      color: '#c0caf5',
    },
    emphasis: {
      itemStyle: {
        areaColor: '#1a4060',
        borderColor: '#00d4ff',
        borderWidth: 1,
      },
      label: {
        color: '#00d4ff',
      },
    },
  },
  categoryAxis: {
    axisLine: {
      show: true,
      lineStyle: {
        color: '#1e3a5f',
      },
    },
    axisTick: {
      show: false,
      lineStyle: {
        color: '#1e3a5f',
      },
    },
    axisLabel: {
      show: true,
      color: '#7a8ab8',
    },
    splitLine: {
      show: false,
      lineStyle: {
        color: ['#1e3a5f'],
      },
    },
    splitArea: {
      show: false,
      areaStyle: {
        color: ['rgba(255,255,255,0.02)', 'rgba(0,0,0,0)'],
      },
    },
  },
  valueAxis: {
    axisLine: {
      show: false,
      lineStyle: {
        color: '#1e3a5f',
      },
    },
    axisTick: {
      show: false,
      lineStyle: {
        color: '#1e3a5f',
      },
    },
    axisLabel: {
      show: true,
      color: '#7a8ab8',
    },
    splitLine: {
      show: true,
      lineStyle: {
        color: ['#1e3a5f'],
      },
    },
    splitArea: {
      show: false,
      areaStyle: {
        color: ['rgba(255,255,255,0.02)', 'rgba(0,0,0,0)'],
      },
    },
  },
  logAxis: {
    axisLine: {
      show: false,
      lineStyle: {
        color: '#1e3a5f',
      },
    },
    axisTick: {
      show: false,
      lineStyle: {
        color: '#1e3a5f',
      },
    },
    axisLabel: {
      show: true,
      color: '#7a8ab8',
    },
    splitLine: {
      show: true,
      lineStyle: {
        color: ['#1e3a5f'],
      },
    },
    splitArea: {
      show: false,
      areaStyle: {
        color: ['rgba(255,255,255,0.02)', 'rgba(0,0,0,0)'],
      },
    },
  },
  timeAxis: {
    axisLine: {
      show: true,
      lineStyle: {
        color: '#1e3a5f',
      },
    },
    axisTick: {
      show: false,
      lineStyle: {
        color: '#1e3a5f',
      },
    },
    axisLabel: {
      show: true,
      color: '#7a8ab8',
    },
    splitLine: {
      show: false,
      lineStyle: {
        color: ['#1e3a5f'],
      },
    },
    splitArea: {
      show: false,
      areaStyle: {
        color: ['rgba(255,255,255,0.02)', 'rgba(0,0,0,0)'],
      },
    },
  },
  toolbox: {
    iconStyle: {
      borderColor: '#7a8ab8',
    },
    emphasis: {
      iconStyle: {
        borderColor: '#00d4ff',
      },
    },
  },
  legend: {
    textStyle: {
      color: '#7a8ab8',
    },
  },
  tooltip: {
    axisPointer: {
      lineStyle: {
        color: '#1e3a5f',
        width: 1,
      },
      crossStyle: {
        color: '#1e3a5f',
        width: 1,
      },
    },
  },
  timeline: {
    lineStyle: {
      color: '#1e3a5f',
      width: 1,
    },
    itemStyle: {
      color: '#00d4ff',
      borderWidth: 1,
    },
    controlStyle: {
      color: '#00d4ff',
      borderColor: '#00d4ff',
      borderWidth: 0.5,
    },
    checkpointStyle: {
      color: '#00d4ff',
      borderColor: '#00d4ff',
    },
    label: {
      color: '#7a8ab8',
    },
    emphasis: {
      itemStyle: {
        color: '#00d4ff',
      },
      controlStyle: {
        color: '#00d4ff',
        borderColor: '#00d4ff',
        borderWidth: 0.5,
      },
      label: {
        color: '#7a8ab8',
      },
    },
  },
  visualMap: {
    color: ['#00d4ff', '#1e3a5f'],
  },
  dataZoom: {
    handleSize: 'undefined%',
    textStyle: {},
  },
  markPoint: {
    label: {
      color: '#c0caf5',
    },
    emphasis: {
      label: {
        color: '#c0caf5',
      },
    },
  },
}

export default darkTheme
