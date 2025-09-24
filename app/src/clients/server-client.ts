import axios from "axios";
import type {Patient, PatientStub, SearchParams} from "@/models/fhir.ts";

const client = axios.create({
    baseURL: 'http://127.0.0.1:8080/fhir/',
    headers: {
        'Content-Type': 'application/json',
        'Authorization': 'mywrite'
    }
});

export default {
    async getPatients() {
        return (await client.get('/patient')).data;
    },

    async searchPatients(searchParams: SearchParams): Promise<PatientStub[]> {
        return (await client.get('/patient', {
            params: searchParams
        })).data;
    },

    async getPatient(id: string | null): Promise<Patient> {
        return (await client.get(`/patient/${id}`)).data;
    },

    async upsertPatient(patient: Patient): Promise<string> {
        return (await client.put(`/patient`, patient)).data;
    }
}
