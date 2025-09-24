<template>
  <b-button
      class="position-fixed"
      style="top: 70px; right: 20px;"
      @click="nextPage()"
  >
    Next
  </b-button>
  <template v-if="currentPage > 1">
    <b-button
        class="position-fixed"
        style="top: 70px; left: 20px;"
        @click="previousPage()"
    >
      Previous
    </b-button>
  </template>
  <div class="container mt-6">
    <b-card>
      <h1>Patient Search</h1>
    </b-card>
    <b-card v-for="patient in patients" :key="patient.id" class="hover-shadow" @click="openPatient(patient.id)">
      <b-row class="fw-bold border-bottom pb-2 mb-2">
        <b-col cols="4">Name</b-col>
        <b-col cols="4">Birthdate</b-col>
        <b-col cols="4">Gender</b-col>
      </b-row>
      <b-row class="px-3 py-2">
        <b-col cols="4">{{ patient.name.join(', ') || 'not provided' }}</b-col>
        <b-col cols="4">{{ patient.birthdate || 'not provided' }}</b-col>
        <b-col cols="4">{{ patient.gender || 'not provided' }}</b-col>
      </b-row>
    </b-card>

    <b-navbar fixed="bottom" type="light" variant="light" toggleable="lg" class="bg-light">
      <b-navbar-nav class="justify-content-center">
        <b-nav-item><label for="search-name">Name:</label>
          <b-form-input id="search-name" v-model="nameSearch"></b-form-input>
        </b-nav-item>
      </b-navbar-nav>
      <b-navbar-nav class="justify-content-center">
        <b-nav-item><label for="birthdate-from">Birth Date From:</label>
          <b-form-input id="birthdate-from" v-model="birthdateFrom"></b-form-input>
        </b-nav-item>
      </b-navbar-nav>
      <b-navbar-nav class="justify-content-center">
        <b-nav-item><label for="birthdate-until">Birth Date Until:</label>
          <b-form-input id="birthdate-until" v-model="birthdateUntil"></b-form-input>
        </b-nav-item>
      </b-navbar-nav>
      <b-navbar-nav class="justify-content-center">
        <b-nav-item><label for="gender-search">Gender:</label>
          <b-form-select id="gender-search" v-model="searchGender" :options="genderOptions"/>
        </b-nav-item>
      </b-navbar-nav>
      <b-navbar-nav class="justify-content-center">
        <b-nav-item><label for="search-operator">Search Operator:</label>
          <b-form-select id="search-operator" v-model="searchOperator" :options="operatorOptions"/>
        </b-nav-item>
      </b-navbar-nav>
      <b-navbar-nav class="justify-content-center">
        <b-nav-item><label for="patient-count">Patients per page:</label>
          <b-form-select id="patient-count" v-model="patientCount" :options="countOptions"/>
        </b-nav-item>
      </b-navbar-nav>

      <b-navbar-nav class="justify-content-center">
        <b-button id="search-button" @click="search()">Search</b-button>
      </b-navbar-nav>
    </b-navbar>
  </div>
</template>
<script setup lang="ts">
import {onMounted, ref} from "vue";
import client from '../clients/server-client.js'
import {
  BButton,
  BCard,
  BCol,
  BFormInput,
  BFormSelect,
  BNavbar,
  BNavbarNav,
  BNavItem,
  BRow,
  useToast
} from "bootstrap-vue-next";
import {Gender, type PatientStub, type SearchParams} from "@/models/fhir.ts";
import router from "@/router";
import {SearchOperator} from "@/models/search-operator.ts";

const {create} = useToast()

const patients = ref<PatientStub[]>([]);
const pages = ref<PatientStub[][]>([]);
const nameSearch = ref<string | null>(null);
const birthdateFrom = ref<string | null>(null);
const birthdateUntil = ref<string | null>(null);
const searchGender = ref<Gender | null>(null);
const currentPage = ref(1);
const searchOperator = ref(SearchOperator.and);
const currentSearch = ref<SearchParams>({
  gender: null,
  name: null,
  birthdateFrom: null,
  birthdateUntil: null,
  operator: SearchOperator.and,
  count: 30,
  iterationKey: null,
  lastId: null,
});

const genderOptions = [
  {value: null, text: 'UNSET'},
  {value: Gender.female, text: 'Female'},
  {value: Gender.male, text: 'Male'},
  {value: Gender.other, text: 'Other'},
  {value: Gender.unknown, text: 'Unknown'}
]

const operatorOptions = [
  {value: SearchOperator.or, text: 'or'},
  {value: SearchOperator.and, text: 'and'},
]
const patientCount = ref<number>(30);
const countOptions = [
  {value: 1, text: '1'},
  {value: 2, text: '2'},
  {value: 3, text: '3'},
  {value: 5, text: '5'},
  {value: 10, text: '10'},
  {value: 20, text: '20'},
  {value: 30, text: '30'},
  {value: 50, text: '50'},
  {value: 100, text: '100'},
]

onMounted(async function () {
  const page1 = await client.getPatients();
  patients.value = page1;
  pages.value.push(page1);
});

function openPatient(id: string) {
  router.push(`/patient/${id}`);
}

async function nextPage() {
  let page = pages.value[currentPage.value];
  if (pages.value[currentPage.value]) {
    if (page && page.length > 0) {
      currentPage.value = currentPage.value + 1;
      patients.value = page;
      return
    }
  }
  const lastPatient = patients.value[patients.value.length - 1];
  currentSearch.value.iterationKey = lastPatient.iterationKey;
  currentSearch.value.lastId = lastPatient.id;
  page = await client.searchPatients(currentSearch.value);
  if (page && page.length > 0) {
    currentPage.value = currentPage.value + 1;
    patients.value = page;
    pages.value.push(page);
  } else {
    create({
      body: 'You have reached the last page.',
      variant: 'info',
      pos: 'top-end',
      modelValue: 10000,
    });
  }
}

async function previousPage() {
  if (currentPage.value <= 1) {
    return;
  }
  let page = pages.value[currentPage.value - 2];
  if (page && page.length > 0) {
    currentPage.value = currentPage.value - 1;
    patients.value = page;
  } else {
    console.error("Could not find page");
  }
}

async function search() {
  if (!nameSearch.value) {
    nameSearch.value = null;
  }
  if (!birthdateFrom.value) {
    birthdateFrom.value = null;
  }
  if (!birthdateUntil.value) {
    birthdateUntil.value = null;
  }
  const search = {
    gender: searchGender.value,
    name: nameSearch.value,
    birthdateFrom: birthdateFrom.value,
    birthdateUntil: birthdateUntil.value,
    operator: searchOperator.value,
    count: patientCount.value,
    iterationKey: null,
    lastId: null,
  }
  currentSearch.value = search;
  const ps = await client.searchPatients(search);
  pages.value.splice(0, pages.value.length);
  pages.value.push(ps);
  patients.value = ps;
}
</script>
