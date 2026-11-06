<script setup lang="ts">
const stats=[{label:'待收费患者',value:'18',tone:'orange'},{label:'今日收费',value:'¥ 12,680',tone:'blue'},{label:'可退费项目',value:'6',tone:'cyan'},{label:'今日退费',value:'¥ 320',tone:'green'}]
const columns=[{label:'收费单号',prop:'orderNo',width:170},{label:'患者姓名',prop:'name'},{label:'项目数',prop:'items'},{label:'应收金额',prop:'amount'},{label:'结算方式',prop:'method'},{label:'状态',prop:'status'}]
const rows=[{orderNo:'CHG202611020036',name:'王晓梅',items:'3 项',amount:'¥ 126.00',method:'自费',status:'待收费'},{orderNo:'CHG202611020035',name:'陈志强',items:'2 项',amount:'¥ 98.50',method:'医保',status:'已完成'}]
</script><template><ModulePlaceholder title="收费退费" description="集中处理门诊待缴费项目、收费凭据以及符合条件的退费业务。" icon="Wallet" :stats="stats" :columns="columns" :rows="rows" /></template>
