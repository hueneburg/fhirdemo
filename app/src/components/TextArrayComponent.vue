<template>
  <b-card>
    <b-row>
      <b-col>
        <h4 class="card-title">{{ title }}</h4>
      </b-col>
      <b-col cols="auto">
        <b-button @click="addRow();">
          <img src="@/assets/plus.svg" alt="Add Row" class="icon">
        </b-button>
      </b-col>
    </b-row>
    <div v-for="(datum, index) in data" :key="index">
      <b-row>
        <b-col>
          <b-form-input v-model="data[index]"></b-form-input>
        </b-col>
        <b-col cols="auto">
          <b-button @click="deleteItem(index);">
            <img src="@/assets/delete.svg" :alt="'Remove item ' + datum" class="icon">
          </b-button>
        </b-col>
      </b-row>
    </div>
  </b-card>
</template>
<script setup lang="ts">
import {onMounted, ref, watch} from "vue";
import {BButton, BCard, BCol, BFormInput, BRow} from "bootstrap-vue-next";

const data = ref<string[]>([]);
const title = ref<string>('');

const props = defineProps({data: {type: Array<string>, default: () => []}, title: {type: String, default: ''}});
const emit = defineEmits(['update:data']);
watch(data, (val) => {
  emit('update:data', [...val])
}, {deep: true})

onMounted(async function () {
  data.value = [...props.data];
  title.value = props.title;
});

function deleteItem(index: number) {
  data.value.splice(index, 1);
}

function addRow() {
  data.value.push('');
}
</script>
<style scoped lang="css">

</style>