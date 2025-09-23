import axios from "axios";
import type {SearchOperator} from "@/models/search-operator.ts";
import type {Gender, Patient, PatientStub, SearchParams} from "@/models/fhir.ts";

const client = axios.create({
    baseURL: 'http://server:8080/fhir/',
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

    async getPatient(id: string): Promise<Patient> {
        console.log("Sending request");
        return (await client.get(`/patient/${id}`)).data;
    }
}
