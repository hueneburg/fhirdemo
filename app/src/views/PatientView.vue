<template>
  <div class="container mt-4">
    <b-card>
      <b-row class="align-items-center">
        <b-col>
          <h1 class="card-title">Names</h1>
        </b-col>
        <b-col cols="auto">
          <b-button @click="save();">
            Save Patient
          </b-button>
        </b-col>
      </b-row>
      <b-card>
        <h2 class="card-title">Date of Birth</h2>
        <b-form-input v-model="dob"></b-form-input>
      </b-card>
      <b-card>
        <h2 class="card-title">Gender</h2>
        <b-form-select v-model="gender" :options="genderOptions"></b-form-select>
      </b-card>
      <b-card>
        <b-row class="align-items-center">
          <b-col>
            <h2 class="card-title">Names</h2>
          </b-col>
          <b-col cols="auto">
            <b-button @click="addName();">
              <img src="@/assets/plus.svg" alt="Add Name" class="icon">
            </b-button>
          </b-col>
        </b-row>
        <template v-for="(name, index) in names" :key="index">
          <HumanNameComponent
              v-model:name-use="names[index].use"
              v-model:family-name="names[index].family"
              v-model:given-name="names[index].given"
              v-model:prefix="names[index].prefix"
              v-model:suffix="names[index].suffix"
              v-model:period-start="namePeriods[index].start"
              v-model:period-end="namePeriods[index].end"
              @name-delete="deleteName(index)"
          />

        </template>
      </b-card>
    </b-card>
  </div>
</template>

<script setup lang="ts">
import {BButton, BCard, BCol, BFormInput, BFormSelect, BRow, useToast} from "bootstrap-vue-next";
import {useRoute} from "vue-router";
import {onMounted, ref} from "vue";
import {Gender, type HumanName, type Patient, type Period} from "@/models/fhir.ts";
import client from '@/clients/server-client.ts'
import HumanNameComponent from "@/components/HumanNameComponent.vue";
import router from "@/router";

const {create} = useToast()

const route = useRoute();

const patient = ref<Patient>();
const names = ref<HumanName[]>([]);
const namePeriods = ref<Period[]>([]);
const dob = ref<string | null>(null);
const gender = ref<Gender | null>(null);
const patientId = ref<string | null>(null);

const genderOptions = [
  {value: null, text: 'UNSET'},
  {value: Gender.female, text: 'Female'},
  {value: Gender.male, text: 'Male'},
  {value: Gender.other, text: 'Other'},
  {value: Gender.unknown, text: 'Unknown'}
]

onMounted(async function () {
  const param = route.params.id;
  const id = Array.isArray(param) ? param[0] : param
  if (id && id !== 'undefined') {
    const p = await client.getPatient(id);
    patientId.value = id;
    patient.value = p;
    names.value = p.name || [];
    namePeriods.value = names.value.map(n => n.period || {}) || [];
    dob.value = p.birthDate || null;
    gender.value = p.gender || null;
  } else {
    patientId.value = null;
  }
});

async function addName() {
  namePeriods.value.push({} as Period)
  names.value.push({} as HumanName);
}

async function deleteName(index: number) {
  names.value.splice(index, 1);
  namePeriods.value.splice(index, 1);
}

async function save() {
  const errors = new Set();
  const dateRegex = /^([0-9]([0-9]([0-9][1-9]|[1-9]0)|[1-9]00)|[1-9]000)(-(0[1-9]|1[0-2])(-(0[1-9]|[1-2][0-9]|3[0-1]))?)?$/;
  if (!dateRegex.test(dob.value || '')) {
    errors.add('Date of birth needs to be a valid Fhir date.');
  }
  let ns = [];
  for (let i = 0; i < names.value.length; i++) {
    const period = namePeriods.value[i];
    if (period && period.start && period.end && (!dateRegex.test(period.start) || dateRegex.test(period.end))) {
      errors.add(`Dates of Period of Name number ${i + 1} is invalid.`);
      continue;
    }

    const n = JSON.parse(JSON.stringify(names.value[i]));
    const fullName = [...(n.given || [])];
    fullName.push(n.family);
    n.text = fullName.join(' ');
    n.period = period;
    ns.push(n);
  }
  if (errors.size > 0) {
    create({
      title: 'Error',
      body: [...errors].join('<br>'),
      variant: 'danger',
      pos: 'middle-center',
      modelValue: 10000,
    });
    return;
  }
  const p: Patient = {
    name: ns,
    birthDate: dob.value || undefined,
    gender: gender.value || undefined,
    implicitRules: [],
    contained: [],
    extension: [],
    modifierExtension: [],
    identifier: [],
    telecom: [],
    photo: [],
    contact: [],
    communication: [],
    generalPractitioner: [],
    link: [],
  };
  try {
    if (patientId.value) {
      p.id = patientId.value;
    }
    const id = await client.upsertPatient(p);
    await router.push(`/patient/${id}`);
  } catch (err) {
    console.error(err);
  }
}
</script>
