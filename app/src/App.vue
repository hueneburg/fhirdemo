<script setup lang="ts">
import {BApp, BNavbar, BNavbarBrand, BNavbarNav, BNavItem} from "bootstrap-vue-next";
</script>

<template>
  <b-app>
    <b-navbar type="light" variant="light" class="bg-light" toggleable="lg">
      <BNavbarBrand href="#">Fhir DEMO</BNavbarBrand>
      <b-navbar-nav>
        <b-nav-item href="/">Patient Search</b-nav-item>
        <b-nav-item href="/patient">Create new Patient</b-nav-item>
      </b-navbar-nav>
    </b-navbar>

    <router-view></router-view>
  </b-app>
</template>

<style lang="css">
.hover-shadow {
  transition: all 0.2s ease-in-out;
}

.hover-shadow:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 15px rgba(0,0,0,0.2);
}
</style>
