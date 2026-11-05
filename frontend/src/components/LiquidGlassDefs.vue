<template>
  <svg class="liquid-glass-defs" aria-hidden="true" focusable="false">
    <defs>
      <filter
        id="his-liquid-edge"
        x="-8%"
        y="-12%"
        width="116%"
        height="124%"
        color-interpolation-filters="sRGB"
      >
        <feTurbulence
          type="fractalNoise"
          baseFrequency="0.012 0.018"
          numOctaves="2"
          seed="19"
          result="noise"
        />
        <feGaussianBlur in="noise" stdDeviation="2.2" result="softNoise" />
        <feDisplacementMap
          in="SourceGraphic"
          in2="softNoise"
          scale="2.4"
          xChannelSelector="R"
          yChannelSelector="G"
        />
      </filter>
    </defs>
  </svg>
</template>

<style scoped>
.liquid-glass-defs {
  position: fixed;
  width: 0;
  height: 0;
  overflow: hidden;
  pointer-events: none;
}
</style>
