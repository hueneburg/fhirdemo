import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'patientListView',
      component: () => import('../views/PatientListView.vue'),
    },
    {
      path: '/patient',
      name: 'patientCreateView',
      component: () => import('../views/PatientView.vue'),
    },
    {
      path: '/patient/:id',
      name: 'patientEditView',
      component: () => import('../views/PatientView.vue'),
    }
  ],
})

export default router
