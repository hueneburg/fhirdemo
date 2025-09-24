<template>
  <b-card>
    <b-row class="align-items-center">
      <b-col>
        <h2 class="card-title">Names</h2>
      </b-col>
      <b-col cols="auto">
        <b-button @click="emitDelete();">
          <img src="@/assets/delete.svg" alt="Delete Name" class="icon">
        </b-button>
      </b-col>
    </b-row>
    <b-form-input disabled v-model="fullName"></b-form-input>
    <b-card>
      <h4 class="card-title">Name Usage</h4>
      <b-form-select id="name-use" v-model="nameUse" :options="nameUseOptions"/>
    </b-card>
    <TextArrayComponent title="Prefixes" v-model:data="prefix"></TextArrayComponent>
    <TextArrayComponent title="Given Name" v-model:data="givenName"></TextArrayComponent>
    <b-card>
      <h4 class="card-title">Family Name</h4>
      <b-form-input v-model="familyName"></b-form-input>
    </b-card>
    <TextArrayComponent title="Suffixes" v-model:data="suffix"></TextArrayComponent>
    <b-card>
      <h4 class="card-title">Valid Period</h4>
      <b-row class="align-items-center">
        <b-col>
          <b-form-input id="period-start" type="datetime-local" v-model="periodStart"></b-form-input>
        </b-col>
        <b-col cols="auto">~</b-col>
        <b-col>
          <b-form-input id="period-end" type="datetime-local" v-model="periodEnd"></b-form-input>
        </b-col>
      </b-row>
    </b-card>
  </b-card>
</template>
<script setup lang="ts">
import {BButton, BCard, BCol, BFormInput, BFormSelect, BRow} from "bootstrap-vue-next";
import TextArrayComponent from "@/components/TextArrayComponent.vue";
import {computed, type PropType, ref, watch} from "vue";
import {HumanNameUse} from "@/models/fhir.ts";

const props = defineProps({
  nameUse: {type: String as PropType<HumanNameUse>, default: null},
  givenName: {type: Array<string>, default: () => []},
  prefix: {type: Array<string>, default: () => []},
  suffix: {type: Array<string>, default: () => []},
  familyName: {type: String, default: ''},
  periodStart: {type: String, default: null},
  periodEnd: {type: String, default: null}
});
const emit = defineEmits([
  'update:nameUse',
  'update:givenName',
  'update:prefix',
  'update:suffix',
  'update:familyName',
  'update:periodStart',
  'update:periodEnd',
  'name-delete'
]);

const nameUse = ref<HumanNameUse | null>(props.nameUse || null);
const givenName = ref<string[]>(props.givenName || []);
const prefix = ref<string[]>(props.prefix || []);
const suffix = ref<string[]>(props.suffix || []);
const familyName = ref<string>(props.familyName || '');
const periodStart = ref<string | null>(props.periodStart || null);
const periodEnd = ref<string | null>(props.periodEnd || null);

watch(nameUse, (val) => {
  emit('update:nameUse', val);
});

watch(givenName, (val) => {
  emit('update:givenName', val);
});

watch(prefix, (val) => {
  emit('update:prefix', val);
});

watch(suffix, (val) => {
  emit('update:suffix', val);
});

watch(familyName, (val) => {
  emit('update:familyName', val);
});

watch(periodStart, (val) => {
  emit('update:periodStart', val);
});

watch(periodEnd, (val) => {
  emit('update:periodEnd', val);
});

const nameUseOptions = [
  {value: null, text: 'UNSET'},
  {value: HumanNameUse.usual, text: 'Usual'},
  {value: HumanNameUse.official, text: 'Official'},
  {value: HumanNameUse.temp, text: 'Temporary'},
  {value: HumanNameUse.nickname, text: 'Nickname'},
  {value: HumanNameUse.anonymous, text: 'Anonymous'},
  {value: HumanNameUse.old, text: 'Old'},
  {value: HumanNameUse.maiden, text: 'Maiden'}
]

const fullName = computed(function () {
  return givenName.value.join(' ') + ' ' + familyName.value;
});

async function emitDelete() {
  emit('name-delete', null);
}
</script>
