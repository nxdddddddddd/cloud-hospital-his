<script setup lang="ts">
const stats=[{label:'检查待执行',value:'8',tone:'blue'},{label:'检验待执行',value:'9',tone:'cyan'},{label:'处置待执行',value:'5',tone:'orange'},{label:'今日已完成',value:'76',tone:'green'}]
const columns=[{label:'申请单号',prop:'orderNo',width:170},{label:'患者姓名',prop:'name'},{label:'项目类别',prop:'type'},{label:'执行项目',prop:'item'},{label:'申请医生',prop:'doctor'},{label:'状态',prop:'status'}]
const rows=[{orderNo:'CHK202611020021',name:'张文杰',type:'检查',item:'胸部正位片',doctor:'李医生',status:'待执行'},{orderNo:'LAB202611020018',name:'王晓梅',type:'检验',item:'血常规',doctor:'李医生',status:'已完成'}]
</script><template><ModulePlaceholder title="检查检验处置" description="统一查看已缴费项目，登记执行人员并完成结果录入。" icon="Monitor" :stats="stats" :columns="columns" :rows="rows" /></template>
