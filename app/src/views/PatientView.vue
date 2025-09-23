<template>
  <div class="container mt-4">
    <b-card>
      <h1>Patient View</h1>
    </b-card>
    <b-card>
      <b-row class="fw-bold border-bottom pb-2 mb-2">
        <b-col>Name</b-col>
      </b-row>
      <b-row v-for="name in patient?.name">
        <b-col>
          <b-form-input v-model="name.text"></b-form-input>
        </b-col>
      </b-row>
    </b-card>
  </div>
</template>

<script setup lang="ts">
import {BCard, BCol, BFormInput, BRow} from "bootstrap-vue-next";
import {useRoute} from "vue-router";
import {onMounted, ref} from "vue";
import type {Patient} from "@/models/fhir.ts";
import client from '@/clients/server-client.ts'

const route = useRoute();

const patient = ref<Patient>();

onMounted(async function () {
  const param = route.params.id;
  const id = Array.isArray(param) ? param[0] : param
  patient.value = await client.getPatient(id);
})
</script>
