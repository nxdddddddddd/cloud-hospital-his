<script setup lang="ts">
const stats=[{label:'今日挂号',value:'128',tone:'blue'},{label:'当前待诊',value:'23',tone:'cyan'},{label:'剩余号源',value:'46',tone:'green'},{label:'今日退号',value:'3',tone:'orange'}]
const columns=[{label:'病历号',prop:'caseNo',width:160},{label:'患者姓名',prop:'name'},{label:'挂号科室',prop:'department'},{label:'出诊医生',prop:'doctor'},{label:'挂号时间',prop:'time',width:150},{label:'状态',prop:'status'}]
const rows=[{caseNo:'MR20261102018',name:'张文杰',department:'内科门诊',doctor:'李医生',time:'2026-11-02 08:35',status:'待接诊'},{caseNo:'MR20261102017',name:'王晓梅',department:'内科门诊',doctor:'李医生',time:'2026-11-02 08:28',status:'接诊中'}]
</script><template><ModulePlaceholder title="窗口挂号" description="登记患者信息、选择科室与医生，并实时校验当日剩余号源。" icon="Tickets" :stats="stats" :columns="columns" :rows="rows" /></template>
