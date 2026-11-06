<script setup lang="ts">
const stats=[{label:'待发药处方',value:'11',tone:'orange'},{label:'今日已发药',value:'83',tone:'blue'},{label:'可退药处方',value:'4',tone:'cyan'},{label:'库存预警',value:'2',tone:'green'}]
const columns=[{label:'处方号',prop:'orderNo',width:170},{label:'患者姓名',prop:'name'},{label:'药品明细',prop:'item'},{label:'开方医生',prop:'doctor'},{label:'处方金额',prop:'amount'},{label:'状态',prop:'status'}]
const rows=[{orderNo:'RX202611020028',name:'张文杰',item:'阿莫西林等 2 项',doctor:'李医生',amount:'¥ 52.50',status:'待发药'},{orderNo:'RX202611020027',name:'陈志强',item:'布洛芬缓释胶囊',doctor:'周医生',amount:'¥ 22.00',status:'已完成'}]
</script><template><ModulePlaceholder title="发药退药" description="核对已缴费处方、完成发退药操作并同步展示药品库存。" icon="Box" :stats="stats" :columns="columns" :rows="rows" /></template>
